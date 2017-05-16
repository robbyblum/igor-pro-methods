#pragma rtGlobals=1		// Use modern global access method.


// ----------- current use of this procedure with 'phase and save' macro, Jared Rovny 5/15/17
// -- First, use phase and save to import (phase, then export) your data from a .tnt file. ** this will create data with the format _[index2D][index3D].
// --    If you're only doing a 2D experiment, all your waves will look like '**_[*][1]'
// -- Second, choose your 'FunctionsForPeter' function. If you've got multiple index3D waves, use one of the "Composite**" functions, which will run over your 3D indices.
// -- Third, to FFT your data, I recommend using "GraphAnyFFTs" or its composite form, choosing your options (note that the 'phasewrapbool' is for centering the F/2 point)
// -- Finally, use the "waterfall manipulate" macro to manipulate a 3D visualization of 3D data. Pick a base wave name, provide the number of waves in each dimension, and use the 
// --    "flip indices" option to look at a slice of many 3D waves at a 2D index instead of many 2D waves at a particular 3D index.
// -------------------


// Changed to accommodate 3D naming: Wave_[2Dindex][3Dindex] instead of just Wave_[2Dindex]

// The most basic thing: take the real and imaginary waves from the data and turn them into a series 
//  of complex waves immediately for processing
Function MakeComplexWavesForFFT(Name, NI)
String Name
Variable NI

Variable i=0
Do
	Duplicate /O $(Name+" real["+num2str(i+1)+"][1]"), tempwaveR
	Duplicate /O $(Name+" imag["+num2str(i+1)+"][1]"), tempwaveI
	Make /O/C/D/N=(dimsize(tempwaveR,0)) finalWave
	finalWave[] = cmplx(tempwaveR[p], tempwaveI[p])
	SetScale /P x dimoffset(tempwaveR,0), dimdelta(tempWaveR,0), "s", finalWave
	Duplicate /O finalWave $"ComplexOutWave_["+num2str(i+1)+"][1]"
	i+=1
While(i<NI)


End


// ==================== //
//       NUTATION                         //
// ==================== //

Function PlotNutationCurve(Name, pntToTake, NI, timeStart, deltaT,index3D, complexBool)
	String Name
	Variable pntToTake
	Variable NI
	Variable timeStart
	Variable deltaT
	Variable index3D
	Variable complexBool
	
	Make/N=(NI)/D/O PulseTime1b
	PulseTime1b = timeStart + deltaT*p
	
	Make/N=(NI)/D/O NutationCurve1b
	
	variable i = 0
	Do
		Duplicate/O $(Name+" real["+num2istr(i+1)+"]["+num2istr(index3D)+"]"), tempWave
		NutationCurve1b[i] = tempWave[pntToTake]
		i = i +1
	While (i<NI)	
	
	KillWaves tempWave
	Duplicate /O NutationCurve1b $"NutationCurve_"+num2str(index3D)
	
	Display/K=1 $"NutationCurve_"+num2str(index3D) vs PulseTime1b
End


Function AvgPlotNutationCurve(Name, pntToTake, NI, timeStart, deltaT, numAvgPoints, index3D)
	String Name
	Variable pntToTake
	Variable NI
	Variable timeStart
	Variable deltaT
	Variable numAvgPoints
	Variable index3D
	
	Make/N=(NI)/D/O PulseTime1b
	PulseTime1b = timeStart + deltaT*p
	
	Make/N=(NI)/D/O NutationCurve1b
	
	variable i = 0
	Do
		Duplicate/O $(Name+" real["+num2istr(i+1)+"]["+num2istr(index3D)+"]"), tempWave
		NutationCurve1b[i] = mean(tempWave, pnt2x(tempwave,pntToTake), pnt2x(tempwave,pntToTake+numAvgPoints))
		i = i +1
	While (i<NI)
	KillWaves tempWave
	Display/K=1 NutationCurve1b vs PulseTime1b
End



Function AvgPlotNutationCurveFFT(Name, pntToTake, NI, timeStart, deltaT, numAvgPointsForward, index3D, lb)
	String Name
	Variable pntToTake
	Variable NI
	Variable timeStart
	Variable deltaT
	Variable numAvgPointsForward
	Variable index3D
	Variable lb
	
	GraphAnyFFTs(Name+" real", NI, 1, index3D, lb, 0, 0)
	
	String newName = (Name[0,10] + "FFT")
	
	Make/N=(NI)/D/O PulseTime1b
	PulseTime1b = timeStart + deltaT*p
	
	Make/N=(NI)/D/O NutationCurve1bFFT
	
	variable i = 0
	Do
		Duplicate/O $(newName+"["+num2istr(i+1)+"]["+num2istr(index3D)+"]"), tempWave
		Redimension /R tempwave
		NutationCurve1bFFT[i] = mean(tempWave, pnt2x(tempwave,pntToTake), pnt2x(tempwave,pntToTake+numAvgPointsForward))
		i = i +1
	While (i<NI)
	KillWaves tempWave
	Display/K=1 NutationCurve1bFFT vs PulseTime1b
End




// ==================== //
//     HAHN ECHO                         //
// ==================== //
// written for a sequence: 
// (T90) -- (timeStart + p*deltaT) -- (T180) -- (deadTime) -- (observe)
// with an echo expected at (timeStart + p*deltaT) after the T180, p indexing the indirect dimension.
// edited below on 4/18/17 to have the echo time at timeStart-deadTime+deltaT*i, incorporating the "dead time" after the T180 pulse.
//
// If the following timing works better with your particular experiment, incorporate the altTimingBool=1:
// (T90) -- (timeStart + p*deltaT) -- (T180) -- (timeStart + p*deltaT - deadTime) -- (observe)
// ==================== //


Function PlotHahnEchoCurve(Name, NI, timeStart, deltaT, deadTime, T180, index3D, altTimingBool)
	String Name
	Variable NI
	Variable timeStart
	Variable deltaT
	Variable deadTime
	Variable T180
	Variable index3D
	Variable altTimingBool

	
	Make/N=(NI)/D /O EchoTime
	Make/N=(NI)/D /O RealTime
	if(altTimingBool)
		EchoTime = deadTime
		RealTime = 2*(timeStart + p*deltaT) + T180
	else
		EchoTime = timeStart + deltaT*p - deadTime
		RealTime = 2*(timeStart + p*deltaT) + T180 + deadTime
	endif
		
	
	Make/N=(NI)/D /O HahnEchoCurve
	Variable startingPoint 
	
	variable i = 0
	if(altTimingBool)
		Do
			Duplicate/O $(Name+" real["+num2istr(i+1)+"]["+num2istr(index3D)+"]"), tempWave
			startingPoint = x2pnt(tempWave, deadTime)
			HahnEchoCurve[i] = tempWave[pnt2x(tempWave, startingPoint)]
			i = i +1
		While (i<NI)
	else
		Do
			Duplicate/O $(Name+" real["+num2istr(i+1)+"]["+num2istr(index3D)+"]"), tempWave
			startingPoint = x2pnt(tempWave, timeStart-deadTime+deltaT*i)
			HahnEchoCurve[i] = mean(tempWave, pnt2x(tempWave, startingPoint-2),pnt2x(tempWave, startingPoint+3))
			i = i +1
		While (i<NI)
	endif
	KillWaves tempWave
	// Display/K=1 HahnEchoCurve vs RealTime
End


Function CompositeHahnEchoCurve(Name, NI, NI3D, timeStart, deltaT, deadTime, T180, altTimingBool)
	String Name
	Variable NI
	Variable NI3D
	Variable timeStart
	Variable deltaT
	Variable deadTime
	Variable T180
	Variable altTimingBool
	
	Variable frac = floor(65280/(NI3D))
	
	Variable index3D = 1
	Do
		PlotHahnEchoCurve(Name, NI, timeStart, deltaT, deadTime, T180, index3D, altTimingBool)
		
		Wave HahnEchoCurve, RealTime
		
		Duplicate/O HahnEchoCurve $"HahnEchoCurve_["+num2str(index3D)+"][1]"
		Setscale /P x RealTime[0], (RealTime[1]-RealTime[0]), "s", $"HahnEchoCurve_["+num2str(index3D)+"][1]"
		
		if(index3D==1)
			Display /K=1 $"HahnEchoCurve_"+num2str(index3D)
		else
			AppendToGraph /C = (65280 - index3D*frac, 0, index3D*frac) $"HahnEchoCurve_["+num2str(index3D)+"][1]"
		endif
		
		index3D+=1
	While (index3D<=NI3D)	

End


// ===================== // 
//  Hahn Echo - type experiments (values are arrived at incrementally)
// ===================== // 
// written for a sequence: 
// (T90) -- (timeStart + p*deltaT) -- (T180) -- (deadTime) -- (observe)
// with an echo expected at (timeStart + p*deltaT) after the T180, p indexing the indirect dimension.
// edited below on 4/18/17 to have the echo time at timeStart-deadTime+deltaT*i, incorporating the "dead time" after the T180 pulse.
//
// If the following timing works better with your particular experiment, incorporate the altTimingBool=1:
// (T90) -- (timeStart + p*deltaT) -- (T180) -- (timeStart + p*deltaT - deadTime) -- (observe)
// ==================== //


Function PlotIncrementalCurve(Name, NI, timeStart, deltaT, index3D, pntToTake, outputName)
	String Name
	Variable NI
	Variable timeStart
	Variable deltaT
	Variable index3D
	Variable pntToTake
	String outputName

	Make/N=(NI)/D /O RealTime
	RealTime = (timeStart + p*deltaT)

	Make/N=(NI)/D /O/C IncrementCurve
	
	variable i = 0
	Do
		Duplicate/O $(Name+" real["+num2istr(i+1)+"]["+num2istr(index3D)+"]"), tempWaveR
		Duplicate/O $(Name+" imag["+num2istr(i+1)+"]["+num2istr(index3D)+"]"), tempWaveI
		IncrementCurve[i] = cmplx(tempwaveR[pntToTake], tempWaveI[pntToTake])
		i = i +1
	While (i<NI)
	
	SetScale /P x timeStart, deltaT, IncrementCurve
	Duplicate /O/C IncrementCurve $outputName

	KillWaves tempWaveR, tempWaveI, IncrementCurve
	// Display/K=1 HahnEchoCurve vs RealTime
End


//Function CompositeIncrementalCurve(Name, NI, NI3D, timeStart, deltaT, deadTime, T180, altTimingBool)
//	String Name
//	Variable NI
//	Variable NI3D
//	Variable timeStart
//	Variable deltaT
//	Variable deadTime
//	Variable T180
//	Variable altTimingBool
//	
//	Variable frac = floor(65280/(NI3D))
//	
//	Variable index3D = 1
//	Do
//		PlotHahnEchoCurve(Name, NI, timeStart, deltaT, deadTime, T180, index3D, altTimingBool)
//		
//		Wave HahnEchoCurve, RealTime
//		
//		Duplicate/O HahnEchoCurve $"HahnEchoCurve_"+num2str(index3D)
//		Setscale /P x RealTime[0], (RealTime[1]-RealTime[0]), "s", $"HahnEchoCurve_"+num2str(index3D)
//		
//		if(index3D==1)
//			Display /K=1 $"HahnEchoCurve_"+num2str(index3D)
//		else
//			AppendToGraph /C = (65280 - index3D*frac, 0, index3D*frac) $"HahnEchoCurve_"+num2str(index3D)
//		endif
//		
//		index3D+=1
//	While (index3D<=NI3D)	
//
//End





// ==================== //
//       CARR PURCELL                 //
// ==================== //

Function PlotCarrPurcellCurve(Name, NI, pntToStart, deltaPnt, tau, t90, acqTime, j, index3D, alternatingBool, ComplexBool)
	String Name
	Variable NI
	Variable pntToStart
	Variable deltaPnt
	Variable tau
	Variable t90
	Variable acqTime
	Variable j
	Variable index3D
	Variable alternatingBool
	Variable ComplexBool
	
	Variable t180 = 2*t90
	
	Variable timeStart, timeDelta
	timeStart = (tau - (2/pi)*t180) + t180 + (tau-acqTime/2) + pntToStart*0.000001 // this is if you're acquiring 1 point per 1us.
	timeDelta = 2*tau + t180
	
	if(alternatingBool)
		timeStart = (tau - (2/pi)*t180) + 2*t180 + 2*tau + (tau-acqTime/2) + pntToStart*0.000001 // this is if you're acquiring 1 point per 1us.
		timeDelta = 4*tau + 2*t180
	endif
	
	Variable numLoops=Nan
	
	if(ComplexBool)
		Duplicate/O $(Name+" real["+num2istr(j)+"]["+num2istr(index3D)+"]"), tempWaveR
		Duplicate/O $(Name+" imag["+num2istr(j)+"]["+num2istr(index3D)+"]"), tempWaveI
		numLoops = floor(dimsize(tempwaveR,0)/deltaPnt)
		Make/N=(numLoops)/D/O/C CarrPurcellCurveComplex
		CarrPurcellCurveComplex = cmplx(mean(tempWaveR,pnt2x(tempwaveR,pntToStart+deltaPnt*p-1),pnt2x(tempwaveR,pntToStart+deltaPnt*p+1)),   mean(tempWaveI,pnt2x(tempwaveI,pntToStart+deltaPnt*p-1),pnt2x(tempwaveI,pntToStart+deltaPnt*p+1)))
		Duplicate /O CarrPurcellCurveComplex CarrPurcellCurve
	else
		Duplicate/O $(Name+" real["+num2istr(j)+"]["+num2istr(index3D)+"]"), tempWaveR
		Duplicate/O tempWaveR tempWaveI // (but don't use tempwaveI here, will just be deleted)
		numLoops = floor(dimsize(tempwave,0)/deltaPnt)
		Make/N=(numLoops)/D/O CarrPurcellCurveReal
		CarrPurcellCurveReal = mean(tempWave,pnt2x(tempwaveR,pntToStart+deltaPnt*p-1),pnt2x(tempwaveR,pntToStart+deltaPnt*p+1))
		Duplicate /O CarrPurcellCurveReal CarrPurcellCurve
	endif
	
	Make/N=(numLoops)/D/O CPEchoTime
	CPEchoTime[] = timeStart + p*timeDelta
	
	KillWaves tempWaveR, tempWaveI
	
//	Display/K=1 CarrPurcellCurve vs CPEchoTime
End

// NOTE: added a 2*i*tauDelta because the timeStart and timeDelta each depend on 2*tau, for a single tau-t180-tau block (which is what we do experimentally)
Function CompositeCPCurve(Name, NI, pntToStart, deltaPnt, tau, t90, tauDelta, acqTime, index3D, alternatingBool, ComplexBool)
	String Name
	Variable NI
	Variable pntToStart
	Variable deltaPnt
	Variable tau
	Variable t90
	Variable tauDelta
	Variable acqTime
	Variable index3D
	Variable alternatingBool // are we only acquiring after 2 periods of tc, or one?
	Variable ComplexBool
	
	Variable t180 = 2*t90
	Variable timeStart, timeDelta, tau_i

	Variable i = 0
	Do	
		tau_i = tau+i*tauDelta
		
		if(alternatingBool)
			timeStart = (tau_i - (2/pi)*t180) + 2*t180 + 2*tau_i + (tau_i-acqTime/2) + pntToStart*0.000001 // this is if you're acquiring 1 point per 1us.
			timeDelta = 4*tau_i + 2*t180
		else
			timeStart = (tau_i - (2/pi)*t180) + t180 + (tau_i-acqTime/2) + pntToStart*0.000001 // this is if you're acquiring 1 point per 1us.
			timeDelta = 2*tau_i + t180
		endif

		PlotCarrPurcellCurve(Name, NI, pntToStart, deltaPnt, tau_i, t90, acqTime, i+1, index3D, alternatingBool, ComplexBool)
		SetScale /P x timeStart,timeDelta, "s", CarrPurcellCurve
		Duplicate /O CarrPurcellCurve $"CarrPurcellCurve_["+num2str(i+1)+"]["+num2istr(index3D)+"]"
		i+=1
	While(i<NI)
End





Function Composite3DCPCurve(Name, NI, pntToStart, deltaPnt, tau, t90, tauDelta, tauDelta3D, acqTime, Nindex3D, alternatingBool, ComplexBool)
	String Name
	Variable NI
	Variable pntToStart
	Variable deltaPnt
	Variable tau
	Variable t90
	Variable tauDelta, tauDelta3D
	Variable acqTime
	Variable Nindex3D
	Variable alternatingBool // are we only acquiring after 2 periods of tc, or one?
	Variable ComplexBool

	Variable index3D = 1
	Do	
		
		CompositeCPCurve(Name, NI, pntToStart, deltaPnt, tau, t90, tauDelta, acqTime, index3D, alternatingBool, ComplexBool)
		tau += tauDelta3D
		
		index3D+=1
	While(index3D<=Nindex3D)
End



Function AnalysisCPMGPeaksVsTau(Name,NI,tauStart,deltaTau,index3D)
String Name
Variable NI
Variable tauStart
Variable deltaTau
Variable index3D

Make /N=(NI)/O CPMGPeaksVsTau

Variable i=0
Do
	Wave tempwave = $Name+"["+num2str(i+1)+"]["+num2istr(index3D)+"]"
	CPMGPeaksVsTau[i]=tempwave[floor(dimsize(tempwave,0)/2)]
	i+=1
While(i<NI)

Setscale /P x tauStart, deltaTau, "s", CPMGPeaksVsTau
Display /K=1 CPMGPeaksVsTau

End


Function AnalysisAvgCPMGPeaksVsTau(Name,NI,tauStart,deltaTau,numAvgPoints,index3D)
String Name
Variable NI
Variable tauStart
Variable deltaTau
Variable numAvgPoints
Variable index3D

// make it odd so we're symmetric around the central frequency
if(mod(numAvgPoints,2)==0)
	numAvgPoints += 1
endif

numAvgPoints = (numAvgPoints-1)/2

Make /N=(NI)/O CPMGPeaksVsTau_Avg

Variable i=0
Do
	Wave tempwave = $Name+"["+num2str(i+1)+"]["+num2istr(index3D)+"]"
	CPMGPeaksVsTau_Avg[i]=real(mean(tempwave, pnt2x(tempwave, floor(dimsize(tempwave,0)/2 - numAvgPoints) ),pnt2x(tempwave, floor(dimsize(tempwave,0)/2 + numAvgPoints))))
	i+=1
While(i<NI)

Setscale /P x tauStart, deltaTau, "s", CPMGPeaksVsTau_Avg
//Display /K=1 CPMGPeaksVsTau_Avg
End




Function AnalysisAvgCPMG_CompareToMax(Name,NI,tauStart,deltaTau,index3D)
String Name
Variable NI
Variable tauStart
Variable deltaTau
Variable index3D

AnalysisAvgCPMGPeaksVsTau(Name,NI,tauStart,deltaTau,1,index3D)
Duplicate /O CPMGPeaksVsTau_Avg tempwave1

AnalysisAvgCPMGPeaksVsTau(Name,NI,tauStart,deltaTau, floor(dimsize($Name+"[1]["+num2istr(index3D)+"]",0)/2),index3D)
Duplicate /O CPMGPeaksVsTau_Avg tempwaveAll

Duplicate /O tempwave1 CPMGPeaksVsTau_ratio

CPMGPeaksVsTau_ratio[] = tempwave1[p] / (tempwaveAll[p] + 1e-10)

Setscale /p x tauStart, deltaTau, "s", CPMGPeaksVsTau_ratio


// this is just to restore "typical" results of the "vs. tau" analysis
AnalysisAvgCPMGPeaksVsTau(Name,NI,tauStart,deltaTau,1,index3D)

End


// ==================== //
//       QUADRATIC ECHO              //
// ==================== //


Function PlotQuadraticEchoCurve(Name, Ni, pntToStart, deltaPnt, t90,tau,nEchoes,Complex,index3D)
	String Name
	Variable Ni
	Variable pntToStart
	Variable deltaPnt
	Variable t90
	Variable tau
	Variable nEchoes
	Variable Complex
	Variable index3D
	
	Variable t180=2*t90
	
	Make/N=(nEchoes)/D/O QEEchoTime
	Variable timeCycle = 2*t180 + 4*tau
	Variable timeDelta = 2*timeCycle + 2*t90 + (2*timeCycle)/2
	Variable timeStart = timeDelta
	print timeDelta, timeStart
	
	QEEchoTime[] = timeStart + p*timeDelta
	
	if(Complex)
		Make/N=(nEchoes)/D/O/C QWaveComplex
		Duplicate/O $(Name+" real["+num2istr(Ni)+"]["+num2istr(index3D)+"]"), tempWaveR
		Duplicate/O $(Name+" imag["+num2istr(Ni)+"]["+num2istr(index3D)+"]"), tempWaveI
		QWaveComplex = cmplx(mean(tempWaveR,pnt2x(tempwaveR,pntToStart+deltaPnt*p-1),pnt2x(tempwaveR,pntToStart+deltaPnt*p+1)), mean(tempWaveI,pnt2x(tempwaveI,pntToStart+deltaPnt*p-1),pnt2x(tempwaveI,pntToStart+deltaPnt*p+1)))
		Duplicate /O QWaveComplex QuadraticEchoCurve
		KillWaves tempWaveR, tempWaveI, QWaveComplex
	else
		Make/N=(nEchoes)/D/O QWaveReal
		Duplicate/O $(Name+" real["+num2istr(Ni)+"]["+num2istr(index3D)+"]"), tempWave
		QWaveReal = mean(tempWave,pnt2x(tempwave,pntToStart+deltaPnt*p-1),pnt2x(tempwave,pntToStart+deltaPnt*p+1))
		Duplicate /O QWaveReal QuadraticEchoCurve
		KillWaves tempWave, QWaveReal
	endif
	
	SetScale /P x timeStart, timeDelta, "s", QuadraticEchoCurve
	
//	Display/K=1 QuadraticEchoCurve vs QEEchoTime
End


Function CompositeQECurves(Name,NI,pntToStart,deltaPnt,t90,tau,deltaTau,nEchoes,Complex,index3D)
	String Name
	Variable NI
	Variable pntToStart
	Variable deltaPnt
	Variable t90
	Variable tau
	Variable deltaTau
	Variable nEchoes
	Variable Complex
	Variable index3D
	
	Variable t180=2*t90
	Variable tc = 2*t180 + 4*tau

	Variable i=1
	Do
		PlotQuadraticEchoCurve(Name, i, pntToStart, deltaPnt, t90,tau+(i-1)*deltaTau,nEchoes,Complex,index3D)
		Duplicate /O QuadraticEchoCurve $"QuadraticEchoCurve_["+num2str(i)+"]["+num2istr(index3D)+"]"
		Display/K=1 $"QuadraticEchoCurve_["+num2str(i)+"]["+num2istr(index3D)+"]" vs QEEchoTime
		i+=1
	While(i<=NI)
	
End



// ==================== //
//       SAT. RECOV.                       //
// ==================== //


Function PlotSaturationRecovery(Name, timeWave, pntNum, NI,index3D)
	String Name
	Variable pntNum, NI,index3D
	Wave timeWave


Make/N=(NI)/D/O SatRecovd
	
	variable i = 0
	Do
		Duplicate/O $(Name+"["+num2istr(i+1)+"]["+num2istr(index3D)+"]"), tempWave
		SatRecovd[i] = real(tempWave[pntNum])
		i = i +1
	While (i<NI)
	KillWaves tempWave
	Display/K=1 SatRecovd vs timeWave
	
End


Function AvgPlotSaturationRecovery(Name, timeWave, pntNum, NI,NavgPoints,index3D)
	String Name
	Variable pntNum, NI,NavgPoints,index3D
	Wave timeWave

	Make/N=(NI)/D/O SatRecovd
	
	variable i = 0
	Do
		Duplicate/O $(Name+"["+num2istr(i+1)+"]["+num2istr(index3D)+"]"), tempWave
		tempWave = real(tempWave)
		SatRecovd[i] = mean(tempWave, pnt2x(tempWave, pntNum), pnt2x(tempWave, pntNum+NavgPoints))
		i = i +1
	While (i<NI)
	KillWaves tempWave
//	Display/K=1 SatRecovd vs timeWave
	
End



// ==================== //  ==================== //  ==================== //  ==================== //
//       FOURIER TRANSFORMS                         
// ==================== //  ==================== //  ==================== //  ==================== //


Function GraphFFTs(Name, NI,index3D)
	String Name
	variable NI
	variable index3D
	
	Duplicate/O $(Name+ " real[1]["+num2istr(index3D)+"]"), tempWave
	variable SW_h = 1/DimDelta(tempwave,0)
	KillWaves tempWave
	
	variable padfactor = 0 //# by which you want to pad by (eg. 6 if you want to zero-fill by 
	variable lb = 50 //line-broadening factor, if you need to smooth out noise
	variable ph0 = 0 //usually keep this at 0 unless you think you did initial phasing wrong
	variable startingIndex = 1  //only change this if you want to only do FT within certain range of 2D waves
	variable endingIndex = NI   //only change this if you want to only do FT within certain range of 2D waves
	
	FFTofRealTimeData(Name, startingIndex, SW_h,padfactor, lb, ph0,index3D)
	String baseWaveName = (Name[0,10] + "FFT")
	Display $(baseWaveName+"["+num2istr(startingIndex)+"]") //Displays first graph with default red color
	
	variable traceIndex = 0
	variable j=(startingIndex + 1)
	variable i = 1;
	variable frac = floor(65280/(endingIndex - startingIndex +1))

	do //This goes through the waves to graph giving them gradually bluer coloring
	
	If (j>endingIndex)
		break;
	endif
	
	Duplicate/O $(Name+ " real["+num2str(j)+"]["+num2istr(index3D)+"]"), tempWave
	SW_h = 1/DimDelta(tempwave,0)
	KillWaves tempWave
	
	FFTofRealTimeData(Name, j, SW_h, padfactor, lb, ph0,index3D)

	AppendToGraph /C = (65280 - i*frac, 0, i*frac), $(baseWaveName+"["+num2istr(j)+"]["+num2istr(index3D)+"]")
	
	traceIndex +=1
	i+=1
	j+=1
	while (1)
	
	ModifyGraph cmplxMode=1 //only shows the real part

End

Function FFTofRealTimeData(Name, imageNum, SW_h, padfactor, lb, ph0,index3D)
	String Name	//Base name of waves to be FFTed
	Variable imageNum	//which image (2D slice) to FFT
	Variable SW_h		//Need full sweep-width to get time scaling correct
	variable padfactor // how many multiples of original point number should padding use
	variable lb  //what the exponential line broadening FWHM should be, in Hz
	variable ph0 //phase0 rotation angle, in degrees
	Variable index3D // which wave in the 3D experiment we're doing

	Duplicate/O $(Name +" real["+num2istr(imageNum)+"]["+num2istr(index3D)+"]"), tempWaveReal
	Duplicate/O $(Name +" imag["+num2istr(imageNum)+"]["+num2istr(index3D)+"]"), tempWaveImag
	Variable TotalPnts=numpnts(tempWaveReal)  // Get the number of points right from the real acq time wave
	Variable deltaT = 1/SW_h	
	
	Make/C/N=(TotalPnts)/D/O SparseCmplxActualTime
	SetScale/P x 0,deltaT,"s", SparseCmplxActualTime 
	SparseCmplxActualTime = cmplx(tempWaveReal, tempWaveImag)

	//adding here the capability to artificially zero data from the right if there is a non-integer padfactor, (ex. padfactor = 6.5, will artificially zero half of real data from the right and then pad with padfactor 6)
	//"remainder" is 10*(fraction of data to artificially zero)
	Variable remainder = 10*(padfactor - floor(padfactor))
	
	if (remainder != 0)   //if remainder is not equal to zero, will artifically zero the correct fraction of data from the right
		Duplicate/O SparseCmplxActualTime, SparseCmplxActualTimeZeroed
		
		InsertPoints round(TotalPnts - TotalPnts*remainder/10), round(TotalPnts*remainder/10), SparseCmplxActualTimeZeroed
		
		DeletePoints TotalPnts, round(TotalPnts*remainder/10), SparseCmplxActualTimeZeroed 
		
		Duplicate/O SparseCmplxActualTimeZeroed, SparseCmplxActualPlusTime
	else
		Duplicate/O SparseCmplxActualTime, SparseCmplxActualPlusTime
	endif

	InsertPoints  TotalPnts, (floor(padfactor)*TotalPnts), SparseCmplxActualPlusTime
	
	Duplicate/O/C SparseCmplxActualPlusTime, SparseCmplxExpActualPlusTime
	
	variable apod = lb/((2/pi)*(ln(2)))
	
	SparseCmplxExpActualPlusTime=(exp(-((x*apod)^2))) * SparseCmplxActualPlusTime
	
	SparseCmplxExpActualPlusTime[0]/=2  //this divides the first 't=0' point by 2, which Kenny MacLean figured out years ago was important for getting the baseline right on the FFT
	
	FFT/OUT=1/DEST=SparseExpActualPlusTime_FFT SparseCmplxExpActualPlusTime
	
	Duplicate/O/C  SparseExpActualPlusTime_FFT, SparseExpPh0ActualPlusTime_FFT
	
	SparseExpPh0ActualPlusTime_FFT=exp(-(cmplx(0,((ph0*Pi)/180))))*SparseExpActualPlusTime_FFT

	Duplicate/O/C  SparseExpPh0ActualPlusTime_FFT, $(Name[0,10] +"FFT"+"["+num2istr(imageNum)+"]["+num2istr(index3D)+"]")
	
	KillWaves SparseCmplxActualTime
End

Function PlotFTNutationCurve(Name, pntToTake, NI, timeStart, deltaT,index3D)
	String Name
	Variable pntToTake
	Variable NI
	Variable timeStart
	Variable deltaT
	Variable index3D
	
	Make/N=(NI)/D/O PulseTime2b
	PulseTime2b = timeStart + deltaT*p
	
	Make/N=(NI)/D/O NutationCurve2b
	
	variable i = 0
	Do
		Duplicate/O $(Name+"["+num2istr(i+1)+"]["+num2istr(index3D)+"]"), tempWave
		NutationCurve2b[i] = real(tempWave[pntToTake])
		i = i +1
	While (i<NI)
	KillWaves tempWave
	Display/K=1 NutationCurve2b vs PulseTime2b
End

// ==================== //  ==================== //  ==================== //  ==================== //
//       WATERFALL PLOTS
// ==================== //  ==================== //  ==================== //  ==================== //

Function PrepareForWaterfallPlot(Name, NI,index3D)
	String Name
	Variable NI, index3D

	Wave tempDimWave = $(Name+"[1]["+num2istr(index3D)+"]")

	Make /C/N=(dimsize(tempDimWave,0),NI) Waterfall2D
	SetScale /P x dimoffset(tempDimWave,0), dimdelta(tempDimWave,0), "Hz", Waterfall2D
	
	Variable i=0
	Do
		Duplicate /O/C $(Name+"["+num2istr(i+1)+"]["+num2istr(index3D)+"]"), tempwave
		Waterfall2D[][i]=tempWave[p]
		i=i+1
	While(i<NI)

	Duplicate /O Waterfall2D $(Name+"2D")

	// make the plot pretty
	Make /O/N=(dimsize(Waterfall2D,1)) WaterfallColor
	WaterfallColor=p
	
	NewWaterfall /HIDE=3 $(Name+"2D")
	ModifyGraph mode=0, zColor($(Name+"2D"))={WaterfallColor,*,*,Rainbow,0}, cmplxMode=1
	ModifyWaterfall angle=70, axlen=0.5
	
	KillWaves Waterfall2D

End


// ==================== //  ==================== //  ==================== //  ==================== //
//       ADAPTIBLE FOURIER TRANSFORMS                         
// ==================== //  ==================== //  ==================== //  ==================== //

Function CompositeGraphAnyFFTs(Name, NI, NI3D, Complex,lb,phaseWrapBool, plotBool)
	String Name
	variable NI, NI3D
	Variable Complex
	Variable lb
	Variable phaseWrapBool
	Variable plotBool
	
	Variable index3D = 1
	Do
		GraphAnyFFTs(Name, NI, Complex,index3D,lb,phaseWrapBool, plotBool)
		index3D+=1
	While(index3D<=NI3D)

End

Function GraphAnyFFTs(Name, NI, Complex,index3D,lb,phaseWrapBool, plotBool)
	String Name
	variable NI
	Variable Complex
	Variable index3D
	Variable lb
	Variable phaseWrapBool
	Variable plotBool
	
	Duplicate/O $(Name+"[1]["+num2str(index3D)+"]"), tempWave
	variable SW_h = 1/DimDelta(tempwave,0)
	KillWaves tempWave
	
	variable padfactor = 0 //# by which you want to pad by (eg. 6 if you want to zero-fill by 
	// variable lb = 2 //line-broadening factor, if you need to smooth out noise
	variable ph0 = 0 //usually keep this at 0 unless you think you did initial phasing wrong
	variable startingIndex = 1  //only change this if you want to only do FT within certain range of 2D waves
	variable endingIndex = NI   //only change this if you want to only do FT within certain range of 2D waves
	

	if(Complex)
		FFTofAnyComplexTimeData(Name+"[1]["+num2istr(index3D)+"]", startingIndex, SW_h,padfactor, lb, ph0,index3D,phaseWrapBool)
	else
		FFTofAnyRealTimeData(Name+"[1]["+num2istr(index3D)+"]", startingIndex, SW_h,padfactor, lb, ph0,index3D,phaseWrapBool)
	endif

	
	String baseWaveName = (Name[0,10] + "FFT")
	
	if(plotBool)
		Display/K=1 $(baseWaveName+"["+num2istr(startingIndex)+"]["+num2istr(index3D)+"]") //Displays first graph with default red color
	endif
	
	variable traceIndex = 0
	variable j=(startingIndex + 1)
	variable i = 1;
	variable frac = floor(65280/(endingIndex - startingIndex +1))

	do //This goes through the waves to graph giving them gradually bluer coloring
	
	If (j>endingIndex)
		break;
	endif
	
	Duplicate/O $(Name+ "["+num2str(j)+"]["+num2istr(index3D)+"]"), tempWave
	SW_h = 1/DimDelta(tempwave,0)
	KillWaves tempWave
	
	if(Complex)
		FFTofAnyComplexTimeData(Name+"["+num2str(j)+"]["+num2istr(index3D)+"]", j, SW_h, padfactor, lb, ph0,index3D,phaseWrapBool)
	else
		FFTofAnyRealTimeData(Name+"["+num2str(j)+"]["+num2istr(index3D)+"]", j, SW_h, padfactor, lb, ph0,index3D,phaseWrapBool)
	endif

	if(plotBool)
		AppendToGraph /C = (65280 - i*frac, 0, i*frac), $(baseWaveName+"["+num2istr(j)+"]["+num2istr(index3D)+"]")
	endif
	
	traceIndex +=1
	i+=1
	j+=1
	while (1)
	
	if(plotBool)
		ModifyGraph cmplxMode=1 //only shows the real part
	endif

End

Function FFTofAnyRealTimeData(Name, imageNum, SW_h, padfactor, lb, ph0,index3D,phaseWrapBool)
	String Name	//Base name of waves to be FFTed
	Variable imageNum	//which image (2D slice) to FFT
	Variable SW_h		//Need full sweep-width to get time scaling correct
	variable padfactor // how many multiples of original point number should padding use
	variable lb  //what the exponential line broadening FWHM should be, in Hz
	variable ph0 //phase0 rotation angle, in degrees
	variable index3D
	variable phaseWrapBool

	Duplicate/O $(Name), tempWaveReal, tempWaveImag
	tempWaveImag=0
	Variable TotalPnts=numpnts(tempWaveReal)  // Get the number of points right from the real acq time wave
	Variable deltaT = 1/SW_h	
	
	Make/C/N=(TotalPnts)/D/O SparseCmplxActualTime
	SetScale/P x 0,deltaT,"s", SparseCmplxActualTime 
	SparseCmplxActualTime = cmplx(tempWaveReal,tempWaveImag)

	//adding here the capability to artificially zero data from the right if there is a non-integer padfactor, (ex. padfactor = 6.5, will artificially zero half of real data from the right and then pad with padfactor 6)
	//"remainder" is 10*(fraction of data to artificially zero)
	Variable remainder = 10*(padfactor - floor(padfactor))
	
	if (remainder != 0)   //if remainder is not equal to zero, will artifically zero the correct fraction of data from the right
		Duplicate/O SparseCmplxActualTime, SparseCmplxActualTimeZeroed
		
		InsertPoints round(TotalPnts - TotalPnts*remainder/10), round(TotalPnts*remainder/10), SparseCmplxActualTimeZeroed
		
		DeletePoints TotalPnts, round(TotalPnts*remainder/10), SparseCmplxActualTimeZeroed 
		
		Duplicate/O SparseCmplxActualTimeZeroed, SparseCmplxActualPlusTime
	else
		Duplicate/O SparseCmplxActualTime, SparseCmplxActualPlusTime
	endif

	InsertPoints  TotalPnts, (floor(padfactor)*TotalPnts), SparseCmplxActualPlusTime
	
	Duplicate/O/C SparseCmplxActualPlusTime, SparseCmplxExpActualPlusTime
	
	variable apod = lb/((2/pi)*(ln(2)))
	
	SparseCmplxExpActualPlusTime=(exp(-((x*apod)^2))) * SparseCmplxActualPlusTime
	
	SparseCmplxExpActualPlusTime[0]/=2  //this divides the first 't=0' point by 2, which Kenny MacLean figured out years ago was important for getting the baseline right on the FFT
	
	if(phaseWrapBool)
		FFT/Z/OUT=1/DEST=SparseExpActualPlusTime_FFT SparseCmplxExpActualPlusTime
	else
		FFT/OUT=1/DEST=SparseExpActualPlusTime_FFT SparseCmplxExpActualPlusTime
	endif
	
	Duplicate/O/C  SparseExpActualPlusTime_FFT, SparseExpPh0ActualPlusTime_FFT
	
	SparseExpPh0ActualPlusTime_FFT=exp(-(cmplx(0,((ph0*Pi)/180))))*SparseExpActualPlusTime_FFT

	Duplicate/O/C  SparseExpPh0ActualPlusTime_FFT, $(Name[0,10] +"FFT"+"["+num2istr(imageNum)+"]["+num2istr(index3D)+"]")
	
	KillWaves SparseCmplxActualTime
End



Function FFTofAnyComplexTimeData(Name, imageNum, SW_h, padfactor, lb, ph0,index3D,phaseWrapBool)
	String Name	//Base name of waves to be FFTed
	Variable imageNum	//which image (2D slice) to FFT
	Variable SW_h		//Need full sweep-width to get time scaling correct
	variable padfactor // how many multiples of original point number should padding use
	variable lb  //what the exponential line broadening FWHM should be, in Hz
	variable ph0 //phase0 rotation angle, in degrees
	variable index3D
	variable phaseWrapBool

	Duplicate/O $(Name), tempWave
	Variable TotalPnts=numpnts(tempWave)  // Get the number of points right from the real acq time wave
	Variable deltaT = 1/SW_h	
	
	Make/C/N=(TotalPnts)/D/O SparseCmplxActualTime
	SetScale/P x 0,deltaT,"s", SparseCmplxActualTime 
	SparseCmplxActualTime = tempWave

	//adding here the capability to artificially zero data from the right if there is a non-integer padfactor, (ex. padfactor = 6.5, will artificially zero half of real data from the right and then pad with padfactor 6)
	//"remainder" is 10*(fraction of data to artificially zero)
	Variable remainder = 10*(padfactor - floor(padfactor))
	
	if (remainder != 0)   //if remainder is not equal to zero, will artifically zero the correct fraction of data from the right
		Duplicate/O SparseCmplxActualTime, SparseCmplxActualTimeZeroed
		
		InsertPoints round(TotalPnts - TotalPnts*remainder/10), round(TotalPnts*remainder/10), SparseCmplxActualTimeZeroed
		
		DeletePoints TotalPnts, round(TotalPnts*remainder/10), SparseCmplxActualTimeZeroed 
		
		Duplicate/O SparseCmplxActualTimeZeroed, SparseCmplxActualPlusTime
	else
		Duplicate/O SparseCmplxActualTime, SparseCmplxActualPlusTime
	endif

	InsertPoints  TotalPnts, (floor(padfactor)*TotalPnts), SparseCmplxActualPlusTime
	
	Duplicate/O/C SparseCmplxActualPlusTime, SparseCmplxExpActualPlusTime
	
	variable apod = lb/((2/pi)*(ln(2)))
	
	SparseCmplxExpActualPlusTime=(exp(-((x*apod)^2))) * SparseCmplxActualPlusTime
	
	SparseCmplxExpActualPlusTime[0]/=2  //this divides the first 't=0' point by 2, which Kenny MacLean figured out years ago was important for getting the baseline right on the FFT
	
	if(phaseWrapBool)
		FFT/Z/OUT=1/DEST=SparseExpActualPlusTime_FFT SparseCmplxExpActualPlusTime
	else
		FFT/OUT=1/DEST=SparseExpActualPlusTime_FFT SparseCmplxExpActualPlusTime
	endif
	
	Duplicate/O/C  SparseExpActualPlusTime_FFT, SparseExpPh0ActualPlusTime_FFT
	
	SparseExpPh0ActualPlusTime_FFT=exp(-(cmplx(0,((ph0*Pi)/180))))*SparseExpActualPlusTime_FFT

	Duplicate/O/C  SparseExpPh0ActualPlusTime_FFT, $(Name[0,10] +"FFT"+"["+num2istr(imageNum)+"]["+num2istr(index3D)+"]")
	
	KillWaves SparseCmplxActualTime
End




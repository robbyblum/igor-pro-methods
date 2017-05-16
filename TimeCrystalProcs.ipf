#pragma rtGlobals=1		// Use modern global access method and strict wave access.

//
// JDR 5/17
// these functions were tossed together as I've been looking at the phenomenon of "time crystals" in bulk
// substances like ammonium dihydrogen phosphate. Not much guiding principle here except to look around
// and use whatever is useful as you go, specifically the functions that spot your peak locations using
// local maxima, or the "make relative scaled ffts" function which removes the absolute x-axis scaling of
// any FFT'd waves, so you can compare them together without it looking funny.


Function RunEverything(NI, NI3D, lb)
Variable NI, NI3D, lb

CompositeGraphAnyFFTs("CarrPurcellCurve_", NI, NI3D, 1, lb, 1, 0)
CompositeAnalyzeT2Peaks(NI, NI3D)

CompositeMakeRelativeScaledFFTs(NI, NI3D)
CompositeMaxLocs(NI, NI3D)
CompositeGetPeakLocDiffs(NI3D)

DuplicateWaveName("PeakLocDiffs", NI3D)

End




//===================//




Function AnalyzeT2Peak(NI, index3D)
Variable NI
Variable index3D

Variable i=0

String CPstr="CarrPurcellFFT["

Make /O/N=(NI) T2PeakHeights
Variable halfPoint = dimsize($"CarrPurcellFFT[1]["+num2str(index3D)+"]",0)/2
Variable totalPower = 0
Make /O/N=(NI) CrystalFraction, CrystalFractionNorm

Do
	Wave /C tempwave = $CPstr+num2str(i+1)+"]["+num2str(index3D)+"]"
	Make /O/N=(dimsize(tempwave,0)) tempwavesqr

	tempwavesqr = magsqr(tempwave)

	T2PeakHeights[i] = magsqr(tempwave[halfPoint])
	CrystalFraction[i] = (T2PeakHeights[i])/sum(tempwavesqr)

	i+=1
While(i<NI)

CrystalFractionNorm[] = CrystalFraction[p]/WaveMax(CrystalFraction)

Duplicate /O T2PeakHeights $"T2PeakHeights_"+num2str(index3D)
Duplicate /O CrystalFraction $"CrystalFraction_"+num2str(index3D)
Duplicate /O CrystalFractionNorm $"CrystalFractionNorm_"+num2str(index3D)

KillWaves T2PeakHeights, CrystalFraction, tempwavesqr, CrystalFractionNorm
End

Function CompositeAnalyzeT2Peaks(NI, NI3D)
Variable NI, NI3D

Variable index3D = 1
Do
	AnalyzeT2Peak(NI, index3D)
	index3D += 1
While(index3D<=NI3D)

End


Function GetCrystalPhaseBoundary(NI, NI3D, bound)
Variable NI, NI3D, bound

CompositeAnalyzeT2Peaks(NI, NI3D)

Make /O/N=(NI3D) CrystalPhaseBoundary = nan
SetScale /P x 18.3e-6, 19e-6, "s", CrystalPhaseBoundary

Variable startindex, endindex
Variable foundStart, foundEnd = 0

Variable index3D = 1
Do
	Wave heightwave = $"CrystalFractionNorm_"+num2str(index3D)

	startindex = 0; endindex = 0
	foundstart = 0; foundEnd = 0
	Variable index = 0
	Do
		if(foundStart==1 && foundEnd==1)
			break
		endif

		if(heightwave[index]<bound && foundEnd==0 && foundStart==1)
			endindex = index
			foundEnd=1
		endif
		if(heightwave[index]>=bound && foundStart==0)
			startindex = index
			foundStart=1
		endif
		index+=1

		if(index>dimsize(heightwave,0))
			if(foundStart==0)
				startindex = index
				foundStart=1
			endif
			endindex = index
			foundEnd=1
		endif
	While(1)

	CrystalPhaseBoundary[index3D-1] = endIndex - startindex

	index3D+=1
While(index3D<=NI3D)


End


//=========//


Function PlotMaxLocs(index3D, NI)
Variable index3D
Variable NI

Variable i=0

String CPstr="CarrPurcellFFT["

Make /O/N=(NI) PeakLocLeft, PeakLocRight
Variable halfPoint = dimsize($"CarrPurcellFFT[1]["+num2str(index3D)+"]",0)/2
Variable temploc1,temploc2=0

Do
	Wave tempwave = $CPstr+num2str(i+1)+"]["+num2str(index3D)+"]"

	WaveStats/W/Q/R=[10, halfPoint] tempwave
	Wave M_WaveStats
	temploc1 = M_WaveStats[11]
	WaveStats/W/Q/R=[halfPoint, 2*halfPoint-10] tempwave
	temploc2 = M_WaveStats[11]

	PeakLocLeft[i] = temploc1
	PeakLocRight[i]= temploc2
	i+=1
While(i<NI)

Duplicate /O PeakLocLeft $"PeakLocLeft_"+num2str(index3D)
Duplicate /O PeakLocRight $"PeakLocRight_"+num2str(index3D)

ScalePeakLoc(index3D, NI)

End

Function CompositeMaxLocs(NI, NI3D)
Variable NI, NI3D

Variable index3D = 1
Do
	PlotMaxLocs(index3D, NI)
	index3D += 1
While(index3D<=NI3D)

End



Function ScalePeakLoc(index3D, NI)
Variable index3D
Variable NI

Variable i=0

String CPstr="CarrPurcellFFT["

Wave PeakLocLeft = $"PeakLocLeft_"+num2str(index3D)
Wave PeakLocRight = $"PeakLocRight_"+num2str(index3D)

Duplicate /O PeakLocLeft PeakLocLeftScaled
Duplicate /O PeakLocRight PeakLocRightScaled

Variable halfPoint = dimsize($"CarrPurcellFFT[1]["+num2str(index3D)+"]",0)/2


Do
	Wave tempwave = $CPstr+num2str(i+1)+"]["+num2str(index3D)+"]"

	PeakLocLeftScaled[i] = PeakLocLeft[i]/(dimsize(tempwave,0)*dimdelta(tempwave,0))
	PeakLocRightScaled[i] = PeakLocRight[i]/(dimsize(tempwave,0)*dimdelta(tempwave,0))

	i+=1
While(i<NI)

Duplicate/O PeakLocLeftScaled $"PeakLocLeftScaled_"+num2str(index3d)
Duplicate/O PeakLocRightScaled $"PeakLocRightScaled_"+num2str(index3d)


End


//============//


Function MakeRelativeScaledFFTs(index3D, NI)
Variable index3D
Variable NI

Variable i=0

String CPstr="CarrPurcellFFT"

Make /O/N=(NI) PeakLocLeft, PeakLocRight
Variable NumPoints = dimsize($"CarrPurcellFFT[1]["+num2str(index3D)+"]",0)
Variable temploc1,temploc2=0

Do
	Duplicate /O/C $CPstr+"["+num2str(i+1)+"]["+num2str(index3D)+"]" $CPstr+"_REL_["+num2str(i+1)+"]["+num2str(index3D)+"]"
	SetScale /P x 0, (1/NumPoints), "", $CPstr+"_REL_["+num2str(i+1)+"]["+num2str(index3D)+"]"
	i+=1
While(i<NI)

End


Function CompositeMakeRelativeScaledFFTs(NI, NI3D)
Variable NI, NI3D

Variable index3D = 1
Do
	MakeRelativeScaledFFTs(index3D, NI)
	index3D += 1
While(index3D<=NI3D)

End


//===========//


Function GetPeakLocDiffs(index3D)
Variable index3D

Wave tempwave1 = $"PeakLocLeftScaled_"+num2str(index3d)
Wave tempwave2 = $"PeakLocRightScaled_"+num2str(index3d)

Duplicate /O tempwave1 tempwaveout

tempwaveout = abs(tempwave1-tempwave2)

Duplicate /O tempwaveout $"PeakLocDiffs_"+num2str(index3d)

killwaves tempwaveout


End

Function CompositeGetPeakLocDiffs(NI3D)
Variable NI3D

Variable index3D = 1
Do
	GetPeakLocDiffs(index3D)
	index3D += 1
While(index3D<=NI3D)

End

//==========//



Function PlotPeakLocsTogether(NI, num3D, lb)
Variable NI
Variable num3D
Variable lb

Variable index3D=0
//Do
//	Execute "KillWindow Graph"+num2str(index3D)
//	index3D+=1
//While(index3D<num3D)

Make /o/n=(NI) anglewave
anglewave = 0.6 + 0.02*p

Make /O/N=(NI) EpsilonWaveR, EpsilonWaveL
EpsilonWaveR = 0.5+ 0.5*(1-anglewave)
EpsilonWaveL = 0.5 -0.5*(1-anglewave)

Duplicate /O EpsilonWaveR NanWave
nanWave = nan

index3D = 1
Do

//	GraphAnyFFTs("CarrPurcellCurve_", NI, 1, index3D, lb, 1, 0)
//	MakeRelativeScaledFFTs(index3D, NI)

//	PlotMaxLocs(index3D, NI)
//	GetPeakLocDiffs(index3D)

//	AnalyzeT2Peak(NI, index3D)

	Display /K=1 $"PeakLocLeftScaled_"+num2str(index3D) vs anglewave
	AppendToGraph $"PeakLocRightScaled_"+num2str(index3D) vs anglewave

	AppendToGraph EpsilonWaveR vs anglewave
	AppendToGraph EpsilonWaveL vs anglewave

	AppendToGraph /r NanWave vs anglewave

	SetAxis right -1,1
	ModifyGraph zero(right)=1
	ModifyGraph tick(right)=3,nticks(right)=0

	ModifyGraph mode=4,marker=8,rgb($"PeakLocLeftScaled_"+num2str(index3D))=(0,0,65535)
	ModifyGraph mode(EpsilonWaveR)=0,rgb(EpsilonWaveR)=(3,52428,1)
	ModifyGraph mode(EpsilonWaveL)=0,rgb(EpsilonWaveL)=(3,52428,1)
	SetAxis left 0.2,0.8

	Label left "frequency / Bandwidth";DelayUpdate
	Label bottom "angle / �"

	Variable taunum = 18.3 + (index3D-1)*19
	TextBox/C/N=text0 "Tau = "+num2str(taunum)+" us"

	DoWindow/C $"Tau_"+num2str(index3D)

	index3D+=1
While(index3D<=num3D)

//Execute "TileWindows/P Graph0,Graph1,Graph2,Graph3,Graph4,Graph5,Graph6,Graph7,Graph8,Graph9,Graph10,Graph11,Graph12,Graph13,Graph14,Graph15,Graph16,Graph17,Graph18,Graph19,Graph20"

//Display /K=1 $"T2PeakHeights_1"
//index3D = 2
//Do
//	Appendtograph $"T2PeakHeights_"+num2str(index3D)
//	index3D+=1
//While(index3D<=num3D)

End



Function PlotPeakHeightsVsAngle(NI, num3D, AngleStart, deltaAngle)
Variable NI, num3D
Variable AngleStart, deltaAngle

Make /O/N=(num3D) AngleWave
setscale /p x AngleStart, deltaAngle, AngleWave

Variable timenum = 1

Do
	Variable index3D = 1
	Do
		Wave heightwave = $"T2PeakHeights_"+num2str(index3D)
		AngleWave[index3D-1] = heightwave[timenum-1]

		index3D+=1
	While(index3D<=num3D)

	Duplicate /O AngleWave $"PeakHeightsVsAngle_"+num2str(timenum)

	timenum += 1
While(timenum<=NI)

KillWaves AngleWave

End




// =========================== //
// ==== DISPLAY FUNCTIONS =======//
// =========================== //


Function DisplayT2PeakHeights(num3D)
Variable num3D

Display $"CrystalFraction_1"
variable frac = floor(65280/num3D)

Variable index3D = 2
	Do

	AppendToGraph /C = (65280 - index3D*frac, 0, index3D*frac), $"CrystalFraction_"+num2istr(index3D)

	index3D+=1
	While(index3D<=num3D)




Make /O/N=(num3D) GaussWidthWave
Display /K=1 $"CrystalFractionNorm_1"
CurveFit/NTHR=0/Q gauss  $"CrystalFractionNorm_1" /D
Wave W_coef
GaussWidthWave[0] = W_coef[3]

index3D = 2
	Do

	AppendToGraph /C = (65280 - index3D*frac, 0, index3D*frac), $"CrystalFractionNorm_"+num2istr(index3D)
	CurveFit/Q/NTHR=0 gauss  $"CrystalFractionNorm_"+num2istr(index3D) /D
	GaussWidthWave[index3D-1] = W_coef[3]

	index3D+=1
	While(index3D<=num3D)

End





Function DuplicateWaveName(Name, NI)
String Name
Variable NI

Variable i = 1
Do

Duplicate /O $Name+"_"+num2str(i) $Name+"["+num2str(i)+"][1]"

i+=1
While(i<=NI)


End



//===============//


Function Make2DMaps(Name, NI, NI3D, endpad)
String Name
Variable NI, NI3D, endpad

Wave CPwave = $Name+"[1][1]"
Variable size = dimsize(CPwave,0)

Make /O/N=(NI, size-2*endpad) CPmap2D
SetScale /P x 0.6, 0.02, CPmap2D
SetScale /P y  (dimoffset(CPwave,0)+endpad*dimdelta(CPwave,0)), dimdelta(CPwave,0), waveunits(CPwave,0), CPmap2D

Variable index3D = 1
Variable pj = 0
Do

	pj=1
	Do
		Wave sourcewave = $(Name+"["+num2str(pj)+"]["+num2str(index3D)+"]")
		CPmap2D[pj-1][] = sourcewave[q+endpad]
		pj+=1
	While(pj<=NI)

	Duplicate /O CPmap2D $"CPmap2D_"+num2str(index3D)
	index3D+=1
While(index3D<=NI3D)


End


Function Plot2DContours(NI3D)
Variable NI3D


Variable index3D=1
Do
	display /K=1; appendmatrixcontour $"CPmap2D_"+num2str(index3D)
	ModifyGraph width=216,height={Aspect,1}
	ModifyContour $"CPmap2D_"+num2str(index3D) autoLevels={*,*,11}, labels=0
	ModifyGraph width=0
	SetAxis left 0.2,0.8
	index3D+=1
While(index3D<=NI3D)

End



Function MakePartialFFTs(NI, NI3D, lb, Nstart, Nsize, keepChopWaveBool)
Variable NI, NI3D, lb, Nstart, Nsize, keepChopWaveBool

Variable index2D, index3D = 1
Make /C/N=(Nsize) ChopWave = nan

Do
	index2D=1
	Do
		Wave DataWave_T = $"CarrPurcellCurve_["+num2str(index2D)+"]["+num2str(index3D)+"]"
		ChopWave[] = DataWave_T[Nstart+p]
		Duplicate /O/C ChopWave $"CPchopWave_["+num2str(index2D)+"]["+num2str(index3D)+"]"

		index2D+=1
	While(index2D<=NI)

	index3D +=1
While(index3D<=NI3D)

CompositeGraphAnyFFTs("CPchopWave_", NI, NI3D, 1, lb, 1, 0)

// get rid of extra waves
KillWaves ChopWave
index3D=1
if(!keepChopWaveBool)
	Do
		index2D=1
		Do
			KillWaves $"CPchopWave_["+num2str(index2D)+"]["+num2str(index3D)+"]"
			index2D+=1
		While(index2D<=NI)
		index3D +=1
	While(index3D<=NI3D)
endif

End



//==============//

Function GetPeakDecayAtGivenE(NI, NI3D,DisplayBool, numEs)
Variable NI, NI3D, DisplayBool, numEs

Wave EpsilonWaveL, EpsilonWaveR
Make /O/N=(10) PeakHeight = nan
Make /O/N=(10) TwoTauWave = 2*(18.3e-6 + p*19e-6)

// get magnitudes
Wave/C CPWave = $"CarrPurcellFFT_REL_[1][1]"
Make /O/N=(dimsize(CPWave,0)) AmpWave = nan

variable frac = floor(65280/numEs)

Variable index3D=1, index2D=floor(NI/2)-floor(numEs/2)
Variable PeakHeightR=1, PeakHeightL = 1
Do
	print index2D

	index3D=1
	Do
		Wave/C CPWave = $"CarrPurcellFFT_REL_["+num2str(index2D)+"]["+num2str(index3D)+"]"
		AmpWave = cabs(CPWave)
		AmpWave[0,20]=0
		AmpWave[dimsize(AmpWave,0)-21,dimsize(AmpWave,0)-1] = 0

		Wave PeakLocationsL = $"PeakLocLeftScaled_4"
		Wave PeakLocationsR = $"PeakLocRightScaled_4"


		PeakHeightR = cabs(CPWave[x2pnt(CPWave, EpsilonWaveR[index2D])] )
		PeakHeightL = cabs(CPWave[x2pnt(CPWave, EpsilonWaveL[index2D])] )
		//PeakHeightR = cabs(CPWave[x2pnt(CPWave, PeakLocationsL[index2D])])
		//PeakHeightR = cabs(CPWave[x2pnt(CPWave, PeakLocationsR[index2D])])

		PeakHeight[index3D-1] = 0.5*( PeakHeightR + PeakHeightL ) / Sum(AmpWave)

		index3D+=1
	While(index3D<=NI3D)

	Duplicate /O PeakHeight $"PeakHeightsVsTime_"+num2str(index2D)

	if(index2D==(floor(NI/2)-floor(numEs/2)) && DisplayBool)
		Display /K=1 $"PeakHeightsVsTime_"+num2str(index2D) vs TwoTauWave
	elseif(DisplayBool)
		AppendToGraph /C = (65280 - index2D*frac, 0, index2D*frac) $"PeakHeightsVsTime_"+num2str(index2D) vs TwoTauWave
	endif

	index2D+=1
While(index2D<=(floor(NI/2)+floor(numEs/2)))


End


///======= NOTE: the below functions attempt to see how the effective epsilon term from the imperfect pulse is attenuated by the dipolar field
// ======== but none of these functions are working yet!
// note: this function doesn't really work yet
Function GetPeakDecayFromFits(NI, NI3D, DisplayBool, indexStart, indexStop, keepFitsBool)
Variable NI, NI3D, DisplayBool, indexStart, indexStop, keepFitsbool

// make a wave with every other time point
Wave/C CPWaveT = $"CarrPurcellCurve_[1][1]"
Make /O/N=(floor(dimsize(CPWaveT,0)/2)) CPWaveT2
SetScale /P x dimoffset(CPWaveT,0), 2*dimdelta(CPWaveT,0), waveunits(CPWaveT,0), CPWaveT2

// first, make a bunch of waves with the frequencies at half
Variable index3D=1, index2D=1
Do
	index3D=1
	Do
		Wave/C CPWaveT = $"CarrPurcellCurve_["+num2str(index2D)+"]["+num2str(index3D)+"]"
		CPWaveT2[] = Real(CPWaveT[2*p])

		Duplicate /O CPWaveT2 $"EveryOther_CPCurve_["+num2str(index2D)+"]["+num2str(index3D)+"]"

		index3D+=1
	While(index3D<=NI3D)
	index2D+=1
While(index2D<=NI)



// Now get fits

Make /O/N=(10) TwoTauWave = 2*(18.3e-6 + p*19e-6)
Variable frac = floor(65280/NI)

Make /O/N=(NI3D) FitFrequency

index3D=1
index2D=indexStart
Do
	index3D=1
	Do
		Wave FitWave = $"EveryOther_CPCurve_["+num2str(index2D)+"]["+num2str(index3D)+"]"

		Make/D/N=3/O W_coef
		W_coef[0] = {1.5*FitWave[0],2e-4,2e3}

		FuncFit/N/NTHR=0/Q DecayCos W_coef  FitWave[0,50] /D
		FitFrequency[index3D-1] = abs(W_coef[2])

		If(!KeepFitsBool)
			KillWaves $"fit_EveryOther_CPCurve_["+num2str(index2D)+"]["+num2str(index3D)+"]"
		endif

		index3D+=1
	While(index3D<=NI3D)

	Duplicate /O FitFrequency $"FitFrequency_"+num2str(index2D)

	if(index2D==indexStart && DisplayBool)
		Display /K=1 $"FitFrequency_"+num2str(index2D) vs TwoTauWave
		DoWindow/C FitWindow
	elseif(DisplayBool)
		AppendToGraph /W=FitWindow/C = (65280 - index2D*frac, 0, index2D*frac) $"FitFrequency_"+num2str(index2D) vs TwoTauWave
	endif

	index2D+=1
While(index2D<=indexStop)

KillWaves FitFrequency


End




// Looks like fitting is hard. Let's just get the location of the minimum and get frequency from there...
Function GetBeatFreqFromPhaseFlip(NI, NI3D, DisplayBool, indexStart, indexStop)
Variable NI, NI3D, DisplayBool, indexStart, indexStop

	// make a wave with every other time point
	Wave/C CPWaveT = $"CarrPurcellCurve_[1][1]"
	Make /O/N=(floor(dimsize(CPWaveT,0)/2)) CPWaveT2
	SetScale /P x dimoffset(CPWaveT,0), 2*dimdelta(CPWaveT,0), waveunits(CPWaveT,0), CPWaveT2

	// make a wave to hold the frequencies we find
	Make /O/N=(NI3D) FitFrequency = nan

	Make /O/N=(10) TwoTauWave = 2*(18.3e-6 + p*19e-6)
	Variable frac = floor(65280/NI)

	// first, make a bunch of waves with the frequencies at half
	Variable index3D=1, index2D=indexStart
	Do
		index3D=3
		Do
			Wave/C CPWaveT = $"CarrPurcellCurve_["+num2str(index2D)+"]["+num2str(index3D)+"]"
			CPWaveT2[] = Real(CPWaveT[2*p])

			WaveStats/W/Q/R=[0, 100] CPWaveT2
			Wave M_WaveStats

			FitFrequency[index3D-1] = 1/(2*M_WaveStats[9])

			index3D+=1
		While(index3D<=NI3D)

		Duplicate /O FitFrequency $"FitFrequency_"+num2str(index2D)

		if(index2D==indexStart && DisplayBool)
			Display /K=1 $"FitFrequency_"+num2str(index2D) vs TwoTauWave
			DoWindow/C FitWindow
		elseif(DisplayBool)
			AppendToGraph /W=FitWindow/C = (65280 - index2D*frac, 0, index2D*frac) $"FitFrequency_"+num2str(index2D) vs TwoTauWave
		endif

		index2D+=1
	While(index2D<=indexStop)

End



//================////================//
//================////================//

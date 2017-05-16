#pragma rtGlobals=1		// Use modern global access method.

//~~~~~~~~~~~~~~~~~~~~ P H A S E    A N D    S A V E   2D Files For MRI/Line Narrowing Expts ~~~~~~~~~~~~~~~~~~~~~~~~~~//

// Latest Mod by SEB on 5/21/09, starting by cutting pieces from Phase & Save v1.8
// This Program opens NTNMR files for quick phasing, binomial smoothing, and importing as
// waves.  Can use independent of Nick's "MacNMR" macro.   Dale.
// Added Wave Splicer for real time viewing of acquired echo trains.  DL
// Added FFT - KM
// Added NTNMR - YD, RR
// Added opening 2D experiments - KM
// Corrected glitch in FFT operation (divide first point by 2 before FFT) - KM
// added zero fill function for FFT 7/17/03
//Added real imaginary and magnitude checkboxes 7/18/03
//  1.) Changed Export to only save waves displayed in the graph.
// Added opening 3D experiments - JDR 01/2017





Function PhaseCtrl(ctrlName): ButtonControl					//This button activates the checked boxes and calculates the magnitude
	String ctrlName
	Variable/G phase0, smoothbool, scalebool, baselinebool, offsetreal, offsetimag, notphased, smoothfactor
	PauseUpdate

	//Get rid of dependencies on first phasing
	SetFormula source_wave_real, ""
	SetFormula source_wave_imag, ""

	if (notphased)										//Maintain phase0 angle (if you phased it already but want to baseline or smooth etc.)
		Duplicate/O source_wave_real, realref, source_wave_mag
		Duplicate/O source_wave_imag, imagref
		notphased=0
	endif

	if (numtype(Ph0of2Dtnt[(Fileselect-1)+filenumber*(Fileselect3D-1)])==2)  //If true, the 2D wave entry for this fileselect is still a Nan...can't use for Ph0! (fileselect3D) added by JDR 01/2017
		//keep the phase0 last used, stored in the global variable
	else
		Phase0=Ph0of2Dtnt[(Fileselect-1)+filenumber*(Fileselect3D-1)]  //in that case, a real Ph0 num has already been entered, either in program, or by hand. (fileselect3D) added by JDR 01/2017
											// so use this last saved Ph0 num for this wave as the 'current, Ph0 value'
	endif

	source_wave_real := realref * cos(phase0) + imagref * sin(phase0)		//Real part under rotation angle "phase0"
	source_wave_imag := imagref * cos(phase0) - realref * sin(phase0)			//Imaginary part under rotation angle "phase0"

	source_wave_mag = Sqrt(source_wave_real^2 + source_wave_imag^2)			//Magnitude (This needs to be updated after smoothing)
		RemovefromGraph/Z source_wave_mag
		CheckBox magcheckbox, value = 1
		AppendtoGraph source_wave_mag
		ModifyGraph rgb(source_wave_mag)=(0,0,65280)


	ResumeUpdate
End


Proc Record_Ph0_in_2D(ctrlName): ButtonControl  //This button will make sure that a table appears next to the window, and the 2D wave
	String ctrlName									//storing the right Ph0 for each slice of 2D.tnt will be displayed as the button is pressed to record it
														//as well as the magnitude of the second point of the slice

	PauseUpdate

	Ph0of2Dtnt[(Fileselect-1)+filenumber*(Fileselect3D-1)]=Phase0  // (fileselect3D-1) added by JDR 01/2017
	Magof2Dtnt[(Fileselect-1)+filenumber*(Fileselect3D-1)]=source_wave_mag[PntToSetPh0]  //use the global variable PntToSetPh0, determined in 'open file source' proc, to get proper magnitude point. (fileselect3D) added by JDR 01/2017


	DoWindow/F TableOf2DWaveOfPh0AndMag	//Bring the table window to the front (so we don't make a million copies)
	If (V_flag<1)			//Build Window if it doesn't already exist
		TableOf2DWaveOfPh0AndMag()
	endif

// BELOW IS FROM V4...combine two into one table up above
//	DoWindow/F TableOf2DWaveOfPh0		//Bring the table window to the front (so we don't make a million copies)
//	If (V_flag<1)			//Build Window if it doesn't already exist
//		TableOf2DWaveOfPh0()
//	endif
//
//	DoWindow/F TableOf2DWaveOfMag		//Bring the table window to the front (so we don't make a million copies)
//	If (V_flag<1)			//Build Window if it doesn't already exist
//		TableOf2DWaveOfMag()
//	endif

	DoWindow/F SaveThisData		//Bring the window to the front (so we don't make a million copies)

	ResumeUpdate

End


Proc Close_Window(ctrlName): ButtonControl
	String ctrlName
	//saving phase and magnitude information in a wave with name showing the file with which it belongs
	Duplicate/O Magof2Dtnt, $(source_file[0,15]+" Mag")
	Print "Wave '"+source_file[0,15]+" Mag" +"' was generated in root."
	Duplicate/O Ph0of2Dtnt, $(source_file[0,15]+" Ph0")
	Print "Wave '"+source_file[0,15]+" Ph0" +"' was generated in root."
	//killing things
	DoWindow/K SaveThisData
	//DoWindow/K TableOf2DWaveOfPh0
	//DoWindow/K TableOf2DWaveOfMag  //no longer used as of V5
	DoWindow/K TableOf2DWaveOfPh0AndMag
	KillWaves/Z source_wave_real, source_wave_imag, source_wave_mag, realref, imagref,
	KillWaves/Z source_wave_0, source_wave_1, source_wave_realmaster, source_wave_imagmaster
	KillWaves/Z tempsource_wave_real, tempsource_wave_imag, tempsource_wave_mag, ftsource_wave_cmplx, phaseonewave
	KillVariables/Z leftmin, leftmax, bottommin, bottommax
	KillVariables/Z smoothbool, scalebool, baselinebool, notphased, smoothfactor, usecursors, zerofillbool, spliced
	KillVariables/Z source_numpnts, source_nscans, source_SW, source_acqtime, source_fref
	KillVariables/Z filenumber, fileselect, masterstepsize, offsetreal, offsetimag
	KillVariables/Z source_numpnts3D, filenumber3D // added by JDR 01/2017
	KillVariables/Z gatetime, spacertime, acqtime, preacq, firstacq
	KillStrings/Z fnamereal, fnameimag, fnamemag
End

Proc Save_Waves_source(ctrlName): ButtonControl          //Export the waves shown on screen
	String ctrlName
	SetDataFolder root:  // In case other macros do something funny
	GetAxis/Q bottom

	//if(filenumber == 1) //changing v6 to let us process 1 2D point
	if(filenumber == 0) //if this is only < 1D experiment, don't bother writing file#1 as part of the exported wave's name

		if (StringMatch(WaveList("*", ",", "WIN:"),"*source_wave_real*"))
			String fnamereal=source_file[0,15]+"real"
			Cursor A, source_wave_real, V_min; Cursor B, source_wave_real, V_max;
			Execute "Duplicate/O/R=(xcsr(A),xcsr(B)) source_wave_real, '" + fnamereal+"'"
			Execute "'"+fnamereal+"'=source_wave_real(x)"
			print "Wave '"+fnamereal+"' was generated in  root."
		endif
		if (StringMatch(WaveList("*", ",", "WIN:"),"*source_wave_imag*"))
			String fnameimag=source_file[0,15]+"imag"
			Cursor A, source_wave_imag, V_min; Cursor B, source_wave_imag, V_max;
			Execute "Duplicate/O/R=(xcsr(A),xcsr(B)) source_wave_imag, '" + fnameimag+"'"
			Execute "'"+fnameimag+"'=source_wave_imag(x)"
			print "Wave '"+fnameimag+"' was generated in  root."
		endif
		if (StringMatch(WaveList("*", ",", "WIN:"),"*source_wave_mag*"))
			String fnamemag=source_file[0,15]+"mag"
			Cursor A, source_wave_mag, V_min; Cursor B, source_wave_mag, V_max;
			Execute "Duplicate/O/R=(xcsr(A),xcsr(B)) source_wave_mag, '" + fnamemag+"'"
			Execute "'"+fnamemag+"'=source_wave_mag(x)"
			print "Wave '"+fnamemag+"' was generated in  root."
		endif
//	elseif(source_numpnts3D==1)  // changed condition for "2D, not 3D" added by JDR 01/2017
//		if (StringMatch(WaveList("*", ",", "WIN:"),"*source_wave_real*"))
//			String fnamereal=source_file[0,15]+" real["+num2str(fileselect) +"]"
//			Cursor A, source_wave_real, V_min; Cursor B, source_wave_real, V_max;
//			Execute "Duplicate/O/R=(xcsr(A),xcsr(B)) source_wave_real, '" + fnamereal+"'"
//			Execute "'"+fnamereal+"'=source_wave_real(x)"
//			print "Wave '"+fnamereal+"' was generated in  root."
//		endif
//		if (StringMatch(WaveList("*", ",", "WIN:"),"*source_wave_imag*"))
//			String fnameimag=source_file[0,15]+" imag[" + num2str(fileselect) +"]"
//			Cursor A, source_wave_imag, V_min; Cursor B, source_wave_imag, V_max;
//			Execute "Duplicate/O/R=(xcsr(A),xcsr(B)) source_wave_imag, '" + fnameimag+"'"
//			Execute "'"+fnameimag+"'=source_wave_imag(x)"
//			print "Wave '"+fnameimag+"' was generated in  root."
//		endif
//		if (StringMatch(WaveList("*", ",", "WIN:"),"*source_wave_mag*"))
//			String fnamemag=source_file[0,15]+" mag[" + num2str(fileselect)	 +"]"
//			Cursor A, source_wave_mag, V_min; Cursor B, source_wave_mag, V_max;
//			Execute "Duplicate/O/R=(xcsr(A),xcsr(B)) source_wave_mag, '" + fnamemag+"'"
//			Execute "'"+fnamemag+"'=source_wave_mag(x)"
//			print "Wave '"+fnamemag+"' was generated in  root."
//		endif
	else   // whole section for 3D added by JDR 01/2017
		if (StringMatch(WaveList("*", ",", "WIN:"),"*source_wave_real*"))
			 fnamereal=source_file[0,15]+" real["+num2str(iFileselect) +"]["+num2str(iFileselect3D)+"]"
			Cursor A, source_wave_real, V_min; Cursor B, source_wave_real, V_max;
			Execute "Duplicate/O/R=(xcsr(A),xcsr(B)) source_wave_real, '" + fnamereal+"'"
			Execute "'"+fnamereal+"'=source_wave_real(x)"
			print "Wave '"+fnamereal+"' was generated in  root."
		endif
		if (StringMatch(WaveList("*", ",", "WIN:"),"*source_wave_imag*"))
			 fnameimag=source_file[0,15]+" imag[" + num2str(iFileselect) +"]["+num2str(iFileselect3D)+"]"
			Cursor A, source_wave_imag, V_min; Cursor B, source_wave_imag, V_max;
			Execute "Duplicate/O/R=(xcsr(A),xcsr(B)) source_wave_imag, '" + fnameimag+"'"
			Execute "'"+fnameimag+"'=source_wave_imag(x)"
			print "Wave '"+fnameimag+"' was generated in  root."
		endif
		if (StringMatch(WaveList("*", ",", "WIN:"),"*source_wave_mag*"))
			 fnamemag=source_file[0,15]+" mag[" + num2str(iFileselect)	 +"]["+num2str(iFileselect3D)+"]"
			Cursor A, source_wave_mag, V_min; Cursor B, source_wave_mag, V_max;
			Execute "Duplicate/O/R=(xcsr(A),xcsr(B)) source_wave_mag, '" + fnamemag+"'"
			Execute "'"+fnamemag+"'=source_wave_mag(x)"
			print "Wave '"+fnamemag+"' was generated in  root."
		endif
	endif
End


Proc Bulk_2D_Ph0_Save_Waves_source(ctrlName): ButtonControl          //After the full Ph0[i] wave has been loaded,
	String ctrlName													// use this to step through full 2D wave and export the full-length phased real&imag waves

	//saving phase and magnitude information in a wave with name showing the file with which it belongs
	Execute "Duplicate/O Magof2Dtnt, $(source_file[0,15]+\" Mag\")"
	print "Wave '"+ source_file[0,15] + " Mag"+"' was generated in root."
	Execute "Duplicate/O Ph0of2Dtnt, $(source_file[0,15]+\" Ph0\")"
	print "Wave '"+ source_file[0,15] + " Ph0"+"' was generated in root."

	SetDataFolder root:  // In case other macros do something funny
	GetAxis/Q bottom  //makes any axis queries 'quiet', so they don't print in history

	// The following Proc is a hybrid of a slightly modified 'upone', then the phasing step of phasecontrol, then the exporting step of save waves
	//  All of this is in a do-while loop that steps from 1 to filenum

	Variable iFileselect=1  //use this as the fileselect loop counter in the batch processing
	Variable iFileselect3D=1

	String fnamereal, fnameimag, fnamemag  //use this one call here, at the top of the do-while loop, and get rid of calls below, which gave trouble (local string not killed easily)

Do // loop through 3D

iFileselect=1 // added by JDR 01/2017

	Do // loop through 2D

		//PauseUpdate

		CheckBox realcheckbox, value = 1
		CheckBox imagcheckbox, value = 1
		CheckBox magcheckbox, value = 1

		//This record hasn't been phased yet
		notphased=1
		SetFormula source_wave_real, ""
		SetFormula source_wave_imag, ""
		Redimension/N = (source_numpnts) source_wave_real
		Redimension/N = (source_numpnts) source_wave_imag
		source_wave_real[0,(source_numpnts -1)] = source_wave_realmaster(x + masterstepsize*(iFileselect - 1)*source_numpnts + masterstepsize*(iFileselect3D-1)*source_numpnts*filenumber)
		source_wave_imag[0,(source_numpnts - 1)] = source_wave_imagmaster(x + masterstepsize*(iFileselect- 1)*source_numpnts + masterstepsize*(iFileselect3D-1)*source_numpnts*filenumber)
		RemoveFromGraph/z source_wave_mag
			FileSelect=iFileselect  //use this to update the select file num to show which wave is plotted
			FileSelect3D=iFileselect3D // added by JDR 01/2017

		// the above was from Proc "UpOne"...we use it to load the full, as recorded real & imag for the ifileselect wave slice

		if (notphased)										//Maintain phase0 angle (if you phased it already but want to baseline or smooth etc.)
			Duplicate/O source_wave_real, realref
			Duplicate/O source_wave_imag, imagref
			notphased=0
		endif

		if (numtype(Ph0of2Dtnt[(iFileselect-1)+filenumber*(Fileselect3D-1)])==2)  //If true, the 2D wave entry for this fileselect is still a Nan...can't use for Ph0!
			//keep the phase0 last used, stored in the global variable
		else
			Phase0=Ph0of2Dtnt[(iFileselect-1)+filenumber*(Fileselect3D-1)]  //in that case, a real Ph0 num has already been entered, either in program, or by hand
												// so use this last saved Ph0 num for this wave as the 'current, Ph0 value'
		endif

		source_wave_real := realref * cos(phase0) + imagref * sin(phase0)		//Real part under rotation angle "phase0"
		source_wave_imag := imagref * cos(phase0) - realref * sin(phase0)			//Imaginary part under rotation angle "phase0"

		// the displayed real and imag waves should now be phased....get ready to export them below

		//first save the zoomed-in axis settings...will restore after export
		GetAxis/Q left
		Variable/G leftmax = V_max
		Variable/G leftmin = V_min
		GetAxis/Q bottom
		Variable/G bottommax = V_max
		Variable/G bottommin = V_min
		//now use autoscale to show the full wave slice to be exported
		SetAxis/A
		GetAxis/Q bottom; Cursor A, source_wave_real, V_min; Cursor B, source_wave_real, V_max;



		// below comes from the Proc "Save_waves_source"
		//if(filenumber == 1) //if this is only a 1D experiment, don't bother writing file#1 as part of the exported wave's name
		if(filenumber == 0)
			if (StringMatch(WaveList("*", ",", "WIN:"),"*source_wave_real*"))
				KillStrings/Z fnamereal, fnameimag, fnamemag

				 fnamereal=source_file[0,15]+"real"
				Cursor A, source_wave_real, V_min; Cursor B, source_wave_real, V_max;
				Execute "Duplicate/O/R=(xcsr(A),xcsr(B)) source_wave_real, '" + fnamereal+"'"
				Execute "'"+fnamereal+"'=source_wave_real(x)"
				print "Wave '"+fnamereal+"' was generated in  root."
			endif
			if (StringMatch(WaveList("*", ",", "WIN:"),"*source_wave_imag*"))
				 fnameimag=source_file[0,15]+"imag"
				Cursor A, source_wave_imag, V_min; Cursor B, source_wave_imag, V_max;
				Execute "Duplicate/O/R=(xcsr(A),xcsr(B)) source_wave_imag, '" + fnameimag+"'"
				Execute "'"+fnameimag+"'=source_wave_imag(x)"
				print "Wave '"+fnameimag+"' was generated in  root."
			endif
			if (StringMatch(WaveList("*", ",", "WIN:"),"*source_wave_mag*"))
				 fnamemag=source_file[0,15]+"mag"
				Cursor A, source_wave_mag, V_min; Cursor B, source_wave_mag, V_max;
				Execute "Duplicate/O/R=(xcsr(A),xcsr(B)) source_wave_mag, '" + fnamemag+"'"
				Execute "'"+fnamemag+"'=source_wave_mag(x)"
				print "Wave '"+fnamemag+"' was generated in  root."
			endif
//		elseif(source_numpnts3D==1)  // changed condition for "2D, not 3D" added by JDR 01/2017
//			if (StringMatch(WaveList("*", ",", "WIN:"),"*source_wave_real*"))
//				 fnamereal=source_file[0,15]+" real["+num2str(iFileselect) +"]"
//				Cursor A, source_wave_real, V_min; Cursor B, source_wave_real, V_max;
//				Execute "Duplicate/O/R=(xcsr(A),xcsr(B)) source_wave_real, '" + fnamereal+"'"
//				Execute "'"+fnamereal+"'=source_wave_real(x)"
//				print "Wave '"+fnamereal+"' was generated in  root."
//			endif
//			if (StringMatch(WaveList("*", ",", "WIN:"),"*source_wave_imag*"))
//				 fnameimag=source_file[0,15]+" imag[" + num2str(iFileselect) +"]"
//				Cursor A, source_wave_imag, V_min; Cursor B, source_wave_imag, V_max;
//				Execute "Duplicate/O/R=(xcsr(A),xcsr(B)) source_wave_imag, '" + fnameimag+"'"
//				Execute "'"+fnameimag+"'=source_wave_imag(x)"
//				print "Wave '"+fnameimag+"' was generated in  root."
//			endif
//			if (StringMatch(WaveList("*", ",", "WIN:"),"*source_wave_mag*"))
//				 fnamemag=source_file[0,15]+" mag[" + num2str(iFileselect)	 +"]"
//				Cursor A, source_wave_mag, V_min; Cursor B, source_wave_mag, V_max;
//				Execute "Duplicate/O/R=(xcsr(A),xcsr(B)) source_wave_mag, '" + fnamemag+"'"
//				Execute "'"+fnamemag+"'=source_wave_mag(x)"
//				print "Wave '"+fnamemag+"' was generated in  root."
//			endif
		else   // whole section for 3D added by JDR 01/2017
			if (StringMatch(WaveList("*", ",", "WIN:"),"*source_wave_real*"))
				 fnamereal=source_file[0,15]+" real["+num2str(iFileselect) +"]["+num2str(iFileselect3D)+"]"
				Cursor A, source_wave_real, V_min; Cursor B, source_wave_real, V_max;
				Execute "Duplicate/O/R=(xcsr(A),xcsr(B)) source_wave_real, '" + fnamereal+"'"
				Execute "'"+fnamereal+"'=source_wave_real(x)"
				print "Wave '"+fnamereal+"' was generated in  root."
			endif
			if (StringMatch(WaveList("*", ",", "WIN:"),"*source_wave_imag*"))
				 fnameimag=source_file[0,15]+" imag[" + num2str(iFileselect) +"]["+num2str(iFileselect3D)+"]"
				Cursor A, source_wave_imag, V_min; Cursor B, source_wave_imag, V_max;
				Execute "Duplicate/O/R=(xcsr(A),xcsr(B)) source_wave_imag, '" + fnameimag+"'"
				Execute "'"+fnameimag+"'=source_wave_imag(x)"
				print "Wave '"+fnameimag+"' was generated in  root."
			endif
			if (StringMatch(WaveList("*", ",", "WIN:"),"*source_wave_mag*"))
				 fnamemag=source_file[0,15]+" mag[" + num2str(iFileselect)	 +"]["+num2str(iFileselect3D)+"]"
				Cursor A, source_wave_mag, V_min; Cursor B, source_wave_mag, V_max;
				Execute "Duplicate/O/R=(xcsr(A),xcsr(B)) source_wave_mag, '" + fnamemag+"'"
				Execute "'"+fnamemag+"'=source_wave_mag(x)"
				print "Wave '"+fnamemag+"' was generated in  root."
			endif
		endif

		//Now, restore zoomed-in view of wave for user
		If (Exists("leftmin")*Exists("leftmax")*Exists("bottommin")*Exists("Bottommax"))
			SetAxis left, leftmin, leftmax
			SetAxis bottom, bottommin, bottommax
		else
			SetAxis/A
		endif
			source_wave_mag = Sqrt(source_wave_real^2 + source_wave_imag^2)			//Magnitude (Calculated here for display purposes...as a check on ph0 value)
			RemovefromGraph/Z source_wave_mag
			CheckBox magcheckbox, value = 1
			AppendtoGraph source_wave_mag
			ModifyGraph rgb(source_wave_mag)=(0,0,65280)
		//report the Ph0 used in history window
		Print "The Ph0 angle used for this wave was",phase0
	iFileselect+=1

	While (iFileselect<(filenumber+1)) // go back and process the next slice in the 2D wave

iFileselect3D+=1   // added by JDR 01/2017
While(iFileselect3D<(source_numpnts3D+1))   // added by JDR 01/2017

End




Proc Bulk_2D_AUTO_FIND_Ph0(ctrlName): ButtonControl          //Use this button to attempt to load the Ph0[i] wave for a 2D set automatically...needs great S/N, and
	String ctrlName

	//Variable Acq=10, PntToSetPh0=4  // PntToSetPh0=Acq/2-1, the same as the SparseDwell t=0 pnt
//
//	Prompt Acq,"Enter Number of Points in each Acq Window"
//	Prompt PntToSetPh0,"I think the Ph0 should be determined at (Acq/2-1)=PntToSetPh0, the 't=0' sparse point.  Risky to Change!"

											// will step through full 2D wave and use Atan() to find Ph0 value to use

	SetDataFolder root:  // In case other macros do something funny
	GetAxis/Q bottom  //makes any axis queries 'quiet', so they don't print in history

	// The following Proc is a hybrid of a slightly modified 'upone', then the phasing step of phasecontrol, then the exporting step of save waves
	//  All of this is in a do-while loop that steps from 1 to filenum

	Variable iFileselect=1  //use this as the fileselect loop counter in the batch processing
	Variable iFileselect3D=1 // added by JDR 01/2017

	Variable AutoPh0  //use to get the Ph0 value 'automatically'
	String fnamereal, fnameimag, fnamemag  //use this one call here, at the top of the do-while loop, and get rid of calls below, which gave trouble (local string not killed easily)


Do // loop 3D, added by JDR 01/2017

	iFileselect=1

	Do // loop 2D

		//PauseUpdate

		CheckBox realcheckbox, value = 1
		CheckBox imagcheckbox, value = 1
		CheckBox magcheckbox, value = 1

		//This record hasn't been phased yet
		notphased=1
		SetFormula source_wave_real, ""
		SetFormula source_wave_imag, ""
		Redimension/N = (source_numpnts) source_wave_real
		Redimension/N = (source_numpnts) source_wave_imag
		source_wave_real[0,(source_numpnts -1)] = source_wave_realmaster(x + masterstepsize*(iFileselect - 1)*source_numpnts + masterstepsize*(fileselect3D-1)*source_numpnts*filenumber) // *(iFileselect3D-1) added by JDR 01/2017
		source_wave_imag[0,(source_numpnts - 1)] = source_wave_imagmaster(x + masterstepsize*(iFileselect- 1)*source_numpnts + masterstepsize*(fileselect3D-1)*source_numpnts*filenumber)// *(iFileselect3D-1) added by JDR 01/2017
		RemoveFromGraph/z source_wave_mag
			FileSelect=iFileselect  //use this to update the select file num to show which wave is plotted
			FileSelect3D=iFileselect3D // added by JDR 01/2017

		// the above was from Proc "UpOne"...we use it to load the full, as recorded real & imag for the ifileselect wave slice

		if (notphased)										//Maintain phase0 angle (if you phased it already but want to baseline or smooth etc.)
			Duplicate/O source_wave_real, realref
			Duplicate/O source_wave_imag, imagref
			notphased=0
		endif

		AutoPh0=atan2(imagref[PntToSetPh0], realref[PntToSetPh0] )

	//	if (numtype(Ph0of2Dtnt[(iFileselect-1)])==2)  //If true, the 2D wave entry for this fileselect is still a Nan...can't use for Ph0!
	//		//keep the phase0 last used, stored in the global variable
	//	else
	//		Phase0=Ph0of2Dtnt[(iFileselect-1)]  //in that case, a real Ph0 num has already been entered, either in program, or by hand
	//											// so use this last saved Ph0 num for this wave as the 'current, Ph0 value'
	//	endif

		phase0=+1*AutoPh0  //this looks to be the right convention

		source_wave_real := realref * cos(phase0) + imagref * sin(phase0)		//Real part under rotation angle "phase0"
		source_wave_imag := imagref * cos(phase0) - realref * sin(phase0)			//Imaginary part under rotation angle "phase0"

		// the displayed real and imag waves should now be phased....get ready to export them below

			source_wave_mag = Sqrt(source_wave_real^2 + source_wave_imag^2)			//Magnitude (Calculated here for display purposes...as a check on ph0 value)
			RemovefromGraph/Z source_wave_mag
			CheckBox magcheckbox, value = 1
			AppendtoGraph source_wave_mag
			ModifyGraph rgb(source_wave_mag)=(0,0,65280)
		Beep
		//report the Ph0 used in history window
		//debugging, worked, drop// Print "The Ph0 angle used for this slice#", iFileselect, "wave",phase0
		//Load in 2D wave table
		Ph0of2Dtnt[(iFileselect-1)+filenumber*(Fileselect3D-1)]=Phase0
		Magof2Dtnt[(iFileselect-1)+filenumber*(Fileselect3D-1)]=source_wave_mag[PntToSetPh0]  //use the global variable PntToSetPh0, determined in 'open file source' proc, to get proper magnitude point
	iFileselect+=1

	While (iFileselect<(filenumber+1)) // go back and process the next slice in the 2D wave

iFileselect3D+=1  // added by JDR 01/2017
While (iFileselect3D<(source_numpnts3D+1)) // added by JDR 01/2017

End






Proc Open_File_source(ctrlName): ButtonControl
	String ctrlName
	SetDataFolder root:  // In case other macros do something funny
	PauseUpdate

	CheckBox realcheckbox, value = 1
	CheckBox imagcheckbox, value = 1
	CheckBox magcheckbox, value = 1

	String/G source_dir, source_file
	Variable/G source_numpnts, source_numpnts3D, source_nscans, source_SW, source_acqtime, source_fref=0 // source_numpnts3D added by JDR 01/2017
	Variable ij,jk=-1
	Open/D/R/C="????"/T="????"/M=("Select file...") ij	 // Let user pick file....
	String/G savefilename = S_fileName

	Variable ipntnum=0, iAtEndOfFirstZeroBurst=Nan, InZeroBool=0  //use below to find and report the end of the first Zero point burst, to determine Acq and the Ph0 point


	do
		ij=jk
		jk=strsearch(S_fileName,":",ij+1)		// this cycle loop chops off the trailing file name from the full path stored in S_fileName
	while(jk>-0.5)

	String file_extension = S_fileName[(strlen(S_fileName) - 4), (strlen(S_fileName) - 1)]
	if(cmpstr(S_fileName,"")^2>0.5)				//  "Cancel" wasn't pressed.  Extract data from the file.
		source_dir=S_fileName[0,ij-1]; source_file=S_fileName[ij+1,strlen(S_fileName)-1]
		Open/R source_fref as source_dir+":"+source_file

		Variable/G notphased=1, spliced=0, realtimeitdone=0
		string stringtrial
		variable number

		variable/G filenumber
		variable/G fileselect
		fileselect = 1

		variable/G fileselect3D
		fileselect3D = 1


		if(stringmatch(file_extension,".tnt")==1) 		//Open an NTNMR file
			FSetPos source_fref,36; FBinRead/B=3/U/F=3 source_fref, source_numpnts		//NTNMR
			FSetPos source_fref,40; FBinRead/B=3/U/F=3 source_fref, filenumber                     //NTNMR
			FSetPos source_fref,44; FBinRead/B=3/U/F=3 source_fref, source_numpnts3D        //NTNMR , added by JDR 01/2017
			FSetPos source_fref,76; FBinRead/B=3/U/F=3 source_fref, source_nscans		//NTNMR
			FSetPos source_fref,260; FBinRead/B=3/F=5 source_fref, source_SW; source_SW/=1000		//NTNMR
			FSetPos source_fref,340; FBinRead/B=3/F=5 source_fref, source_acqtime; source_acqtime*=1000		//NTNMR
			Execute "GBLoadWave/O/Q/V/B/N=source_wave_/T={2,2}/S=1056/W=2/U="+num2str(filenumber*source_numpnts*source_numpnts3D)+" \""+source_dir+":"+source_file+"\""		//NTNMR
		else
			Print "NTNMR File type not recognized...should end in .tnt suffix...please fix!!"
		endif
		Close/A
		SetFormula source_wave_real, ""
		SetFormula source_wave_imag, ""
		Execute "RemoveFromGraph/Z " + WaveList("*", ",","WIN:")[0, strlen(WaveList("*", ",","WIN:"))-2]

		Duplicate/O source_wave_0, source_wave_real, source_wave_realmaster
		Duplicate/O source_wave_1, source_wave_imag, source_wave_imagmaster

		//Reset Graph

		Redimension/N = (source_numpnts) source_wave_real
		Redimension/N = (source_numpnts) source_wave_imag
		SetScale/P x 0,(0.0005/source_SW),"s", source_wave_real,source_wave_imag
		SetScale/P x 0,(0.0005/source_SW),"s", source_wave_realmaster, source_wave_imagmaster
		variable/G masterstepsize = .0005/source_SW

		//Individual records in 2D files are taken from realmaster and imagmaster
		source_wave_real[0,(source_numpnts - 1)] = source_wave_realmaster(x)
		source_wave_imag[0,(source_numpnts - 1)] = source_wave_imagmaster(x)

		AppendToGraph source_wave_real
		AppendToGraph source_wave_imag
		ModifyGraph rgb(source_wave_imag)=(0,52224,0)

		//Autoscale and set as default for "Recall Axis" button
		SetAxis/A

		ModifyGraph grid=1,gridRGB=(56576,56576,56576)
		DoWindow/T SaveThisData, source_file[0,15]
		Label left "NMR Signal (arb. units)"
		Label bottom "\\u#2Time (\\U)"
	endif

	//Now that source_wave_real & source_wave_imag for first slice are loaded, step through them from left to find the end of the first Zero burst

	ipntnum=0
	iAtEndOfFirstZeroBurst=Nan
	InZeroBool=0  //starting from p=0, so not in Zero at beginning
	Do
		if ((Abs(source_wave_real[ipntnum])<1e-9)&&(Abs(source_wave_imag[ipntnum])<1e-9))
			InZeroBool=1
			iAtEndOfFirstZeroBurst=ipntnum //use this to hold the current Zero value
		endif
		//debugging...worked...no longer needed//Print "ipntnum=", ipntnum,  "Re=", Abs(source_wave_real[ipntnum]), "Im=", Abs(source_wave_imag[ipntnum]), "InZeroBool=", InZeroBool
		ipntnum+=1
	While ((((Abs(source_wave_real[ipntnum])<1e-9)&&(Abs(source_wave_imag[ipntnum])<1e-9)) || (InZeroBool==0)) && (ipntnum<source_numpnts))

	if (ipntnum == source_numpnts)
		iAtEndOfFirstZeroBurst = ipntnum
	endif

	Variable/G Acq=(iAtEndOfFirstZeroBurst+1), PntToSetPh0=(Acq/2-1)

	if (exists(source_file[0,15]+" Ph0"))
	Duplicate/O $(source_file[0,15]+" Ph0"), Ph0of2Dtnt
	Duplicate/O $(source_file[0,15]+" Mag"), Magof2Dtnt
	Print "Previous phase and magnitude was imported for this file."
	else
	Make/O/N=(filenumber*source_numpnts3D) Ph0of2Dtnt=Nan  //this global wave will be recreated, and filled with Nan, each time a new *.tnt is opened. Added *source_numpnts3D, JDR 01/2017
	SetScale/P x 1,1,"", Ph0of2Dtnt  //the x-scaling will correspond to the fileselect variable (i.e., starts at 1)

	Make/O/N=(filenumber*source_numpnts3D) Magof2Dtnt=Nan  //  Added *source_numpnts3D, JDR 01/2017
	SetScale/P x 1,1,"", Magof2Dtnt
	endif

	ResumeUpdate
	if(usecursors == 1)
		GetAxis/Q bottom; Cursor A, source_wave_real, V_min; Cursor B, source_wave_real, V_max;
	endif
End




Proc UpOne(ctrlName): ButtonControl
	String ctrlName
	SetDataFolder root:  // In case other macros do something funny
	PauseUpdate

	CheckBox realcheckbox, value = 1
	CheckBox imagcheckbox, value = 1
	CheckBox magcheckbox, value = 1


	if(fileselect !=filenumber)


	//This record hasn't been phased yet
	notphased=1

	fileselect = fileselect + 1
	SetFormula source_wave_real, ""
	SetFormula source_wave_imag, ""
	Redimension/N = (source_numpnts) source_wave_real
	Redimension/N = (source_numpnts) source_wave_imag
	source_wave_real[0,(source_numpnts -1)] = source_wave_realmaster(x + masterstepsize*(fileselect - 1)*source_numpnts + masterstepsize*(fileselect3D-1)*source_numpnts*filenumber) // fileselect3d added by JDR 01/2017
	source_wave_imag[0,(source_numpnts - 1)] = source_wave_imagmaster(x + masterstepsize*(fileselect- 1)*source_numpnts + masterstepsize*(fileselect3D-1)*source_numpnts*filenumber) // added by JDR 01/2017
//	RemoveFromGraph/z source_wave_mag

	else //we were at the last one (i.e., (fileselect ==filenumber)...go back to first record)

	//This record hasn't been phased yet
	notphased=1
	fileselect = + 1  //wrap back to 1 effect
	SetFormula source_wave_real, ""
	SetFormula source_wave_imag, ""
	Redimension/N = (source_numpnts) source_wave_real
	Redimension/N = (source_numpnts) source_wave_imag
	source_wave_real[0,(source_numpnts -1)] = source_wave_realmaster(x + masterstepsize*(fileselect - 1)*source_numpnts + masterstepsize*(fileselect3D-1)*source_numpnts*filenumber) // fileselect3d added by JDR 01/2017
	source_wave_imag[0,(source_numpnts - 1)] = source_wave_imagmaster(x + masterstepsize*(fileselect- 1)*source_numpnts + masterstepsize*(fileselect3D-1)*source_numpnts*filenumber) // fileselect3d added by JDR 01/2017
//	RemoveFromGraph/z source_wave_mag

	endif
End


Proc DownOne(ctrlName): ButtonControl
	String ctrlName
	SetDataFolder root:  // In case other macros do something funny
	PauseUpdate

	CheckBox realcheckbox, value = 1
	CheckBox imagcheckbox, value = 1
	CheckBox magcheckbox, value = 1

	if(fileselect !=1)


	//This record hasn't been phased yet
	notphased=1

	fileselect = fileselect - 1
	SetFormula source_wave_real, ""
	SetFormula source_wave_imag, ""
	Redimension/N = (source_numpnts) source_wave_real
	Redimension/N = (source_numpnts) source_wave_imag
	source_wave_real[0,(source_numpnts- 1)] = source_wave_realmaster(x + masterstepsize*(fileselect - 1)*source_numpnts + masterstepsize*(fileselect3D-1)*source_numpnts*filenumber) // fileselect3d  added by JDR 01/2017
	source_wave_imag[0,(source_numpnts - 1)] = source_wave_imagmaster(x + masterstepsize*(fileselect - 1)*source_numpnts + masterstepsize*(fileselect3D-1)*source_numpnts*filenumber)// fileselect3d  added by JDR 01/2017
//	RemoveFromGraph/z source_wave_mag
	else //we went down from #1...wrap around to the end!

	//This record hasn't been phased yet
	notphased=1
	fileselect = filenumber  //wrap back to last one (filenumber) effect
	SetFormula source_wave_real, ""
	SetFormula source_wave_imag, ""
	Redimension/N = (source_numpnts) source_wave_real
	Redimension/N = (source_numpnts) source_wave_imag
	source_wave_real[0,(source_numpnts -1)] = source_wave_realmaster(x + masterstepsize*(fileselect - 1)*source_numpnts + masterstepsize*(fileselect3D-1)*source_numpnts*filenumber) // fileselect3d  added by JDR 01/2017
	source_wave_imag[0,(source_numpnts - 1)] = source_wave_imagmaster(x + masterstepsize*(fileselect- 1)*source_numpnts + masterstepsize*(fileselect3D-1)*source_numpnts*filenumber) // fileselect3d  added by JDR 01/2017
//	RemoveFromGraph/z source_wave_mag

	endif
End


// --
// UpOne for 3D, added by JDR 01/2017
// --
Proc UpOne3D(ctrlName): ButtonControl
	String ctrlName
	SetDataFolder root:  // In case other macros do something funny
	PauseUpdate

	CheckBox realcheckbox, value = 1
	CheckBox imagcheckbox, value = 1
	CheckBox magcheckbox, value = 1

	if(fileselect3D != source_numpnts3D)


	//This record hasn't been phased yet
	notphased=1

	fileselect3D = fileselect3D + 1
	SetFormula source_wave_real, ""
	SetFormula source_wave_imag, ""
	Redimension/N = (source_numpnts) source_wave_real
	Redimension/N = (source_numpnts) source_wave_imag
	source_wave_real[0,(source_numpnts -1)] = source_wave_realmaster(x + masterstepsize*(fileselect - 1)*source_numpnts + masterstepsize*(fileselect3D-1)*source_numpnts*filenumber)
	source_wave_imag[0,(source_numpnts - 1)] = source_wave_imagmaster(x + masterstepsize*(fileselect- 1)*source_numpnts + masterstepsize*(fileselect3D-1)*source_numpnts*filenumber)
//	RemoveFromGraph/z source_wave_mag
	else //we were at the last one (i.e., (fileselect ==filenumber)...go back to first record)

	//This record hasn't been phased yet
	notphased=1
	fileselect3d = + 1  //wrap back to 1 effect
	SetFormula source_wave_real, ""
	SetFormula source_wave_imag, ""
	Redimension/N = (source_numpnts) source_wave_real
	Redimension/N = (source_numpnts) source_wave_imag
	source_wave_real[0,(source_numpnts -1)] = source_wave_realmaster(x + masterstepsize*(fileselect - 1)*(fileselect3d)*source_numpnts + masterstepsize*(fileselect3D-1)*source_numpnts*filenumber)
	source_wave_imag[0,(source_numpnts - 1)] = source_wave_imagmaster(x + masterstepsize*(fileselect- 1)*(fileselect3d)*source_numpnts + masterstepsize*(fileselect3D-1)*source_numpnts*filenumber)
//	RemoveFromGraph/z source_wave_mag

	endif
End

// --
// DownOne for 3D, added by JDR 01/2017
// --
Proc DownOne3D(ctrlName): ButtonControl
	String ctrlName
	SetDataFolder root:  // In case other macros do something funny
	PauseUpdate

	CheckBox realcheckbox, value = 1
	CheckBox imagcheckbox, value = 1
	CheckBox magcheckbox, value = 1

	if(fileselect3d !=1)


	//This record hasn't been phased yet
	notphased=1

	fileselect3d = fileselect3d - 1
	SetFormula source_wave_real, ""
	SetFormula source_wave_imag, ""
	Redimension/N = (source_numpnts) source_wave_real
	Redimension/N = (source_numpnts) source_wave_imag
	source_wave_real[0,(source_numpnts- 1)] = source_wave_realmaster(x + masterstepsize*(fileselect - 1)*source_numpnts + masterstepsize*(fileselect3D-1)*source_numpnts*filenumber)
	source_wave_imag[0,(source_numpnts - 1)] = source_wave_imagmaster(x + masterstepsize*(fileselect - 1)*source_numpnts + masterstepsize*(fileselect3D-1)*source_numpnts*filenumber)
//	RemoveFromGraph/z source_wave_mag
	else //we went down from #1...wrap around to the end!

	//This record hasn't been phased yet
	notphased=1
	fileselect3d = source_numpnts3D  //wrap back to last one (source_numpnts3D) effect
	SetFormula source_wave_real, ""
	SetFormula source_wave_imag, ""
	Redimension/N = (source_numpnts) source_wave_real
	Redimension/N = (source_numpnts) source_wave_imag
	source_wave_real[0,(source_numpnts -1)] = source_wave_realmaster(x + masterstepsize*(fileselect - 1)*source_numpnts + masterstepsize*(fileselect3D-1)*source_numpnts*filenumber)
	source_wave_imag[0,(source_numpnts - 1)] = source_wave_imagmaster(x + masterstepsize*(fileselect- 1)*source_numpnts + masterstepsize*(fileselect3D-1)*source_numpnts*filenumber)
//	RemoveFromGraph/z source_wave_mag

	endif
End
// --


Window SaveThisData() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(33,99,1200,600) source_wave_real as "No Data File Loaded--Use Import"
	ModifyGraph mode=5
	ModifyGraph rgb=(47872,47872,47872)
	ModifyGraph hbFill=2
	ModifyGraph grid=1
	ModifyGraph gridRGB=(56576,56576,56576)
	Label left "NMR Signal (arb. units)"
	Label bottom "\\u#2Time (\\U)"
	SetAxis left -144.592251090116,281.201919437379
	SetAxis bottom 0.000773437367651729,0.00133382718849564
	ControlBar 75
	SetVariable cphase,pos={410,27},size={63,18},title="Medium",fSize=12,frame=0
	SetVariable cphase,limits={-3.2,3.2,0.05},value= phase0
	SetVariable fphase,pos={476,27},size={89,18},title="Fine",fSize=12,frame=0
	SetVariable fphase,limits={-3.2,3.2,0.01},value= phase0
	Slider sliderphase,pos={320,0},size={89,50},title="Coarse",fSize=12,frame=0
	Slider sliderphase,limits={-3.2,3.2,0.25},variable= phase0,side= 2,vert= 0
	SetVariable showAcq,pos={342,54},size={95,18},title="Acq",fSize=12,frame=0
	SetVariable showAcq,value= Acq
	SetVariable showPntToSetPh0,pos={435,54},size={133,18},title="PntToSetPh0"
	SetVariable showPntToSetPh0,fSize=12,frame=0,value= PntToSetPh0
	Button button0,pos={8,6},size={70,42},proc=Open_File_source,title="Import\rNew *.tnt"
	Button button1,pos={569,6},size={72,64},proc=Record_Ph0_in_2D,title="Record\rPh0[\\{fileselect}]\rin Ph02D"
	Button button2,pos={87,54},size={249,20},proc=Save_Waves_source,title="Export Checked of 1D Slice Wave[\\{fileselect}]"
	Button button7,pos={765,7},size={121,60},proc=Bulk_2D_Ph0_Save_Waves_source,title="Export Full Re&Im\rwith Ph0[*]\rFor ALL \\{filenumber} Slices"
	Button button8,pos={649,7},size={109,62},proc=Bulk_2D_AUTO_FIND_Ph0,title="Auto Set Ph0[*]\r For ALL \\{filenumber}\rSlices (Atan2)"
	Button button3,pos={892,8},size={60,59},proc=Close_Window,title="Close\rWindow"
	Button button4,pos={247,4},size={70,42},proc=PhaseCtrl,title="Adjust\rPh0[\\{fileselect}]"
	Button button5,pos={124,5},size={21,44},proc=UpOne,title="+"
	Button button6,pos={93,5},size={21,44},proc=DownOne,title="-"
	Button button9,pos={1000,28},size={21,44},proc=UpOne3D,title="+" // added by JDR 01/2017
	Button button10,pos={969,28},size={21,44},proc=DownOne3D,title="-" // added by JDR 01/2017
	ValDisplay valdisp2,pos={411,5},size={147,17},bodyWidth=62,title="Phase0 (rads)"
	ValDisplay valdisp2,fSize=12,frame=0,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp2,value= #"phase0"
	CheckBox realcheckbox,pos={3,75},size={34,14},proc=realar,title="real",value= 1
	CheckBox imagcheckbox,pos={3,95},size={39,14},proc=imagar,title="imag",value= 1
	CheckBox magcheckbox,pos={3,115},size={37,14},proc=magar,title="mag",value= 1
	PopupMenu FFTwave,pos={969,8},size={149,20},proc=PopupFFT,title="FFT[\\{fileselect}]"
	PopupMenu FFTwave,mode=1,popvalue="No Apodization",value= #"\"No GB/LB;Gaussian;Exponential\""
	SetVariable setvar0,pos={4,54},size={81,15},bodyWidth=36,title="Scans 1D"
	SetVariable setvar0,value= source_nscans
	ValDisplay valdisp0,pos={155,9},size={90,14},title="Select File #"
	ValDisplay valdisp0,limits={0,0,0},barmisc={0,1000},value= #"fileselect"
	ValDisplay valdisp1,pos={160,29},size={85,14},title="Total Files"
	ValDisplay valdisp1,limits={0,0,0},barmisc={0,1000},value= #"filenumber"

	ValDisplay valdisp3,pos={1031,31},size={90,14},title="Select File #"
	ValDisplay valdisp3,limits={0,0,0},barmisc={0,1000},value= #"fileselect3D"
	ValDisplay valdisp4,pos={1036,48},size={85,14},title="Total 3D\rFiles"
	ValDisplay valdisp4,limits={0,0,0},barmisc={0,1000},value= #"source_numpnts3D"
EndMacro


Window TableOf2DWaveOfPh0AndMag() : Table
	PauseUpdate; Silent 1		// building window...
	Edit/W=(1209,97,1436,912) Ph0of2Dtnt.xy,Magof2Dtnt.y as "Recorded Values of Ph0 AND Mag in 2D set"
	ModifyTable format(Point)=1,width(Point)=22,width(Magof2Dtnt.y)=72,width(Ph0of2Dtnt.x)=42
	ModifyTable width(Ph0of2Dtnt.d)=72
EndMacro


Window TableOf2DWaveOfPh0() : Table
	PauseUpdate; Silent 1		// building window...
	Edit/W=(1309,97,1602,765) Ph0of2Dtnt.xy as "Recorded Values of Ph0 in 2D set"
	ModifyTable format(Point)=1,width(Point)=42,width(Ph0of2Dtnt.d)=78
EndMacro

Window TableOf2DWaveOfMag() : Table
	PauseUpdate; Silent 1		// building window...
	Edit/W=(1309,97,1602,765) Magof2Dtnt.xy as "Recorded Values of Magnitude in 2D set"
	ModifyTable format(Point)=1,width(Point)=42,width(Magof2Dtnt.d)=78
EndMacro


Function Realar(ctrlName,checked) : CheckBoxControl		//This function will add/remove the real FID from the graph
	String ctrlName
	Variable checked
	if (checked)
		Execute "Appendtograph source_wave_real"
		Execute "ModifyGraph rgb(source_wave_real)=(65280,0,0)"
		Execute "ModifyGraph lsize=1"
	else
		Execute "RemoveFromGraph source_wave_real"
	endif
End

Function Imagar(ctrlName,checked) : CheckBoxControl		//This function will add/remove the imaginary FID from the graph
	String ctrlName
	Variable checked
	if (checked)
		Execute "Appendtograph source_wave_imag"
		Execute "ModifyGraph rgb(source_wave_imag)=(0,52224,0)"
		Execute "ModifyGraph lsize=1"
	else
		Execute "RemoveFromGraph source_wave_imag"
	endif
End

Function Magar(ctrlName,checked) : CheckBoxControl		//This function will add/remove the magnitude FID from the graph

	String ctrlName
	Variable checked
	NVAR notphased
	if (checked)
			Wave 	source_wave_real, source_wave_imag
			Duplicate/O  source_wave_real, source_wave_mag
			source_wave_mag = Sqrt(source_wave_real^2 + source_wave_imag^2)			//Magnitude (calculated if checked)
			Execute "Appendtograph source_wave_mag"
			Execute "ModifyGraph rgb(source_wave_mag)=(0,0,65280)"
			Execute "ModifyGraph lsize=1"
		else
			Execute/Z "RemoveFromGraph source_wave_mag"
	endif

End



Macro PhaseAndSaveBulkV7()
	SetDataFolder root:  // In case other macros do something funny
	If (Exists("source_wave_real")<1)
		Make/O source_wave_real, source_wave_imag, source_wave_mag
	endif
	DoWindow/F SaveThisData		//Bring the window to the front (so we don't make a million copies)
	If (V_flag<1)			//Build Window if it doesn't already exist
		SaveThisData()
		DoWindow/T SaveThisData, "No Data File Loaded--Use Import"
	endif
	Variable/G phase0, notphased=1, usecursors = 0, zerofillbool = 0

End

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ E N D    Original PhaseAndSave.ipf ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//


///////////////////////////////////////////////////////////////////////////BEGIN KENNY'S FFT ADD ON/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


Window FFTGraph() : Graph																					////This is the FFT window
	PauseUpdate; Silent 1		// building window...
	Execute "Display /W=(37.5,79.25,678,516.5)  ftsource_wave_real,ftsource_wave_imag,ftsource_wave_mag"
	ModifyGraph lSize=1
	ModifyGraph grid=1
	ModifyGraph gridRGB=(56576,56576,56576)
	Execute "ModifyGraph rgb(ftsource_wave_imag)=(0,52224,0)"
	Execute "ModifyGraph rgb(ftsource_wave_mag)=(0,0,65280)"
	ControlBar 50
	SetVariable cphase,pos={49,24},size={65,19},title="Coarse",fSize=12,frame=0									//fine and course phase adjustments
	SetVariable cphase,limits={-Inf,Inf,0.05},value=coursepFT
	SetVariable fphase,pos={129,24},size={45,19},title="Fine",fSize=12,frame=0
	SetVariable fphase,limits={-Inf,Inf,0.005},value= finepFT
	SetVariable phaseone, pos = {200,24}, size = {124,19},title = " ", fSize = 12, frame = 1							//This sets the phase one correction in microseconds,
	SetVariable phaseone, limits={-Inf,Inf,.1}, value = phaseoneus													// i.e., if you type in a time t here, a frequency dependent
	SetDrawLayer UserFront																					//phase correction given by 2*pi*v*t (v is the frequency) is added
	ValDisplay valdisp2,pos={049,5},size={125,15},title="Phase Angle"
	ValDisplay valdisp2,limits={0,0,0},barmisc={0,1000},value= phaseFFT											//This is the phase angle display
	ValDisplay valdisp3,pos={200,5},size={127,15}, title="Phase One Correction (us)", frame = 0
	ValDisplay valdisp3,limits={0,0,0},barmisc={0,1000}, value = 0													//This is not actually a display, it is just used as a label for the phase one setvariable
	ValDisplay valdisp4, pos={625,5}, size={94,15}, title = "File #"
	ValDisplay valdisp4, limits={0,0,0}, barmisc={0,1000}, value= ftfileselect
	ValDisplay valdisp5, pos={625,28}, size={94,15}, title = "Total Files"
	ValDisplay valdisp5, limits={0,0,0}, barmisc={0,1000}, value= filenumber

	Label bottom "Frequency"
	Label left "NMR Signal (arb. units)"
	CheckBox addreal,pos={546,3},size={58,10},proc=AddRemReal,title="Real"										//These checkboxes control which waves are displayed
	CheckBox addreal,value= 1
	CheckBox addimagine,pos={546,18},size={58,10},proc=AddRemImagine,title="Imaginary"
	CheckBox addimagine,value= 1
	CheckBox addmag,pos={546,33},size={58,10},proc=AddRemMag,title="Magnitude"
	CheckBox addmag,value= 1
	Button button5,pos={335,3},size={100,40},proc=ExportFTWaves,title="Export FFT"							//This will export the FFT to waves
	Button button6,pos={438,3},size={100,40},proc=Close_ftWindow,title="Close Window"							//this button just closes the window
End


Proc Close_ftWindow(ctrlName): ButtonControl																	//This just closes the	procedure which closes FFTGraph
	String ctrlName
	DoWindow/K FFTGraph
	KillWaves/Z ftsource_wave_real, ftsource_wave_imag, ftsource_wave_mag
End


Proc ExportFTWaves(ctrlName): ButtonControl   //This procedure just exports the FFT data, exactly the same way as is done in Dale's original phase and save
	String ctrlName

	SetDataFolder root:  // In case other macros do something funny
	if(filenumber == 1)
	String ftfnamereal = source_file[0,15]+"ftreal", ftfnameimag=source_file[0,15]+"ftimag", ftfnamemag=source_file[0,15]+"ftmagnitude"

	GetAxis/Q bottom
	Cursor A, ftsource_wave_real, V_min; Cursor B, ftsource_wave_real, V_max;

	Execute "Duplicate/O/R=(xcsr(A),xcsr(B)) ftsource_wave_real, '" + ftfnamereal+"'"
	Execute "Duplicate/O/R=(xcsr(A),xcsr(B)) ftsource_wave_imag, '" + ftfnameimag+"'"
	Execute "Duplicate/O/R=(xcsr(A),xcsr(B)) ftsource_wave_mag, '" + ftfnamemag+"'"

	Execute "'"+ftfnamereal+"'=ftsource_wave_real(x)"
	Execute "'"+ftfnameimag+"'=ftsource_wave_imag(x)"
	Execute "'"+ftfnamemag+"'=ftsource_wave_mag(x)"

	print "Wave '"+ftfnamereal+"' was generated in  root."
	print "Wave '"+ftfnameimag+"' was generated in  root."
	print  "Wave '"+ftfnamemag+"' was generated in  root."
	else

	String  ftfnamereal = source_file[0,15]+" ftreal[" + Num2str(ftfileselect) + "]"
	String  ftfnameimag=source_file[0,15]+" ftimag[" + Num2str(ftfileselect) + "]"
	String  ftfnamemag=source_file[0,15]+" ftmag[" + Num2str(ftfileselect) + "]"

	GetAxis/Q bottom
	Cursor A, ftsource_wave_real, V_min; Cursor B, ftsource_wave_real, V_max;

	Execute "Duplicate/O/R=(xcsr(A),xcsr(B)) ftsource_wave_real, '" + ftfnamereal+"'"
	Execute "Duplicate/O/R=(xcsr(A),xcsr(B)) ftsource_wave_imag, '" + ftfnameimag+"'"
	Execute "Duplicate/O/R=(xcsr(A),xcsr(B)) ftsource_wave_mag, '" + ftfnamemag+"'"

	Execute "'"+ftfnamereal+"'=ftsource_wave_real(x)"
	Execute "'"+ftfnameimag+"'=ftsource_wave_imag(x)"
	Execute "'"+ftfnamemag+"'=ftsource_wave_mag(x)"

	print "Wave '"+ftfnamereal+"' was generated in  root."
	print "Wave '"+ftfnameimag+"' was generated in  root."
	print  "Wave '"+ftfnamemag+"' was generated in  root."

	endif
End

Function AddRemReal(ctrlName,checked) : CheckBoxControl		//This function just activates the "add and remove real spectrum from FFT graph" macros which follow it
	String ctrlName
	Variable checked
	if (checked)
		Execute "Appendtograph ftsource_wave_real"
		Execute "ModifyGraph rgb(ftsource_wave_real)=(65280,0,0)"
		Execute "ModifyGraph lsize=1"
	else
		Execute "RemoveFromGraph ftsource_wave_real"
	endif
End

Function AddRemImagine(ctrlName,checked) : CheckBoxControl		//This function just activates the "add and remove imaginary spectrum from FFT graph" macros which follow it
	String ctrlName
	Variable checked
	if (checked)
		Execute "Appendtograph ftsource_wave_imag"
		Execute "ModifyGraph rgb(ftsource_wave_imag)=(0,52224,0)"
		Execute "ModifyGraph lsize=1"
	else
		Execute "RemoveFromGraph ftsource_wave_imag"
	endif
End

Function AddRemMag(ctrlName,checked) : CheckBoxControl		//This function just activates the "add and remove magnitude spectrum from FFT graph" macros which follow it
	String ctrlName
	Variable checked
	if (checked)
		Execute "Appendtograph ftsource_wave_mag"
		Execute "ModifyGraph rgb(ftsource_wave_mag)=(0,0,65280)"
		Execute "ModifyGraph lsize=1"
	else
		Execute "RemoveFromGraph ftsource_wave_mag"
	endif
End



Function PopupFFT(ctrlName,popNum,popStr) : PopupMenuControl												//This function is activated by a choice made on the
	String ctrlName																							// FFT popup menu on the phase and save window
	Variable popNum																							// it basically just tests which choice was made
	String popStr																								//and runs the appropriate macro (after propting the apodization

	If (popNum==1)
		Execute "FourierTransform()"
	endif
	If (popNum==2)
		Execute "GaussApodFourierTransform()"
	endif
	If (popNum==3)
		Execute "ExpApodFourierTransform()"
	endif
End


Function zerofill(ctrlName,checked) : CheckBoxControl			//If checked the real and imaginary parts are divided by scan number
	String ctrlName
	Variable checked
	Variable/G zerofillbool
	If (checked)
		zerofillbool=1
	else
		zerofillbool=0
	endif
End


Function ZfillPrompt()
	NVAR zfill
	variable tempzfill
	prompt tempzfill, "Enter Fill Time (ms)"
	DoPrompt "ZERO FILL", tempzfill
	zfill = tempzfill*.001
End


/////BEGIN PROCEDURES WHICH DO THE FOURIER TRANSFORMING

Proc FourierTransform()																	//This is a straightforward FFT, with no apodization
	SetDataFolder root:  // In case other macros do something funny

	variable/G ftfileselect = fileselect													//label the 2d file you are looking at
	variable checka																		//we check first whether or not the two cursors are on the screen
	variable checkb

	if(zerofillbool)																		//if zero fill is checked activate the  zerofill prompt function
		variable/G zfill
		ZfillPrompt()
	endif

	checka = waveexists(Csrwaveref(A))
	checkb = waveexists(Csrwaveref(B))
	GetAxis/Q Bottom

	if(usecursors == 0) 																	//"usecursors" is a global variable, which is 1 if the user wants to set the FFT range
		Cursor A, source_wave_real, V_min; Cursor B, source_wave_real, V_max;				//with the cursors and 0 if they just want to FFT the whole screen.  If it is zero here
	endif																				//we just throw some cursors up on the limits of the screen
	if(checka==0)																		//make sure there is actually a cursor A and B to set the range if usecursors, if not, just FFT the
		Cursor A, source_wave_real, V_min; Cursor B, source_wave_real, V_max;				//whole screen
	endif
	if(checkb==0)
		Cursor A, source_wave_real, V_min; Cursor B, source_wave_real, V_max;
	endif

	variable points																		//These variable are for storing a waves dimensions and scaling
	variable step
	variable start

	Duplicate/O source_wave_real, tempsource_wave_real			//we duplicate the data waves in the phase and save program (the portion
	Duplicate/O source_wave_imag, tempsource_wave_imag		//selected)
	Duplicate/O source_wave_imag, tempsource_wave_mag			//duplicate a magnitude wave (just to have another wave here

	//Get rid of dependencies on first phasing
	SetFormula tempsource_wave_real, ""
	SetFormula tempsource_wave_imag, ""
	SetFormula tempsource_wave_mag,""

	Duplicate/O/R=(xcsr(A),xcsr(B)) tempsource_wave_real, ftsource_wave_real			//we duplicate the data waves in the phase and save program (the portion
	Duplicate/O/R=(xcsr(A),xcsr(B)) tempsource_wave_imag, ftsource_wave_imag			//selected)
	Duplicate/O/R=(xcsr(A),xcsr(B)) tempsource_wave_imag, ftsource_wave_mag			//duplicate a magnitude wave (just to have another wave here)

	if(zerofillbool)																			//if zerofill was checked append the desired points
		variable tempsteps
		variable temptotalsteps
		tempsteps = deltax(ftsource_wave_real)
		tempsteps = round(zfill/tempsteps)
		temptotalsteps = DimSize(ftsource_wave_real,0)

		ftsource_wave_real = ftsource_wave_real - ftsource_wave_real[(temptotalsteps - 1)]
		ftsource_wave_imag = ftsource_wave_imag - ftsource_wave_imag[(temptotalsteps - 1)]

		InsertPoints (temptotalsteps),(tempsteps), ftsource_wave_real
		InsertPoints (temptotalsteps),(tempsteps), ftsource_wave_imag
		InsertPoints (temptotalsteps),(tempsteps), ftsource_wave_mag
	endif

	duplicate/o ftsource_wave_real, trial1

	if(usecursors == 0)
		GetAxis/Q bottom
		Cursor/K A
		Cursor/K B
		HideInfo
	endif

	points = DimSize(ftsource_wave_real,0)								//record the dimensions of the waves
	step = deltax(ftsource_wave_real)
	start = leftx(ftsource_wave_real)

	make/o/C ftsource_wave_cmplx												//make a complex wave with the same dimensions and make it the complex signal
	Redimension/N = (points) ftsource_wave_cmplx									// wave
	SetScale/P x (start),(step),"s", ftsource_wave_cmplx

	ftsource_wave_cmplx=ftsource_wave_real + cmplx(0,1)*ftsource_wave_imag
	ftsource_wave_cmplx[0] = ftsource_wave_cmplx[0]/2						//make correction for FFT operation
	FFT ftsource_wave_cmplx													//FFT the complex wave

	points = DimSize(ftsource_wave_cmplx,0)										//record the new dimensions/scaling of the complex wave
	step = deltax(ftsource_wave_cmplx)
	start = leftx(ftsource_wave_cmplx)

	ftsource_wave_real= 0														//make the real and imaginary and magnitude waves have these dimensions/scaling and set them = 0
	Redimension/N = (points) ftsource_wave_real
	SetScale/P x (start),(step),"Hz", ftsource_wave_real

	ftsource_wave_imag= 0
	Redimension/N = (points) ftsource_wave_imag
	SetScale/P x (start),(step),"Hz", ftsource_wave_imag

	ftsource_wave_mag= 0
	Redimension/N = (points) ftsource_wave_mag
	SetScale/P x (start),(step),"Hz", ftsource_wave_mag
	ftsource_wave_mag=sqrt(magsqr(ftsource_wave_cmplx))							//set the magnitude wave equal to the magnitude of the complex FFT

	variable/G phaseFFT																	//this is the phase factor for the FFT	, which will be equal to a fine + a course phase
	variable/G finepft
	variable/G coursepft
	variable/G phaseone																	//This is the phase one correction in seconds
	variable/G phaseoneus																//this is the phase one	 correction in micro seconds
	phaseone = 0																		//initialize the phase one corrections to zero
	phaseoneus = 0

	duplicate/o ftsource_wave_mag, phaseonewave									//make a wave whose entries are 2*pi*v where v is the frequency independent variableof the FFT
	phaseonewave = 2*pi*x

	finepft=0																				//initialize the phase corrections to zero
	coursepft=0

	phaseone := (10^-6)*phaseoneus												//the phase one is set in terms of the phaseoneus which is set by the user
	phaseFFT := finepft + coursepft												// the phase is set as the sum of the course and fine phase adjustments

	ftsource_wave_real:= (real(ftsource_wave_cmplx)*cos(phaseFFT - phaseonewave*phaseone) + imag(ftsource_wave_cmplx)*sin(phaseFFT - phaseonewave*phaseone))
	ftsource_wave_imag := (imag(ftsource_wave_cmplx)*cos(phaseFFT - phaseonewave*phaseone) - real(ftsource_wave_cmplx)*sin(phaseFFT - phaseonewave*phaseone))
																						//set the real and imaginary FFT in terms of the complex FFT with the given
																						//phase and phase one (2*pi*v*(offset time)) correction
	BuildFTGraph() 																		//Build the FFT graph
End


Proc GaussApodFourierTransform(apod)															//This an FFT, with gaussian apodization
	variable/G ftfileselect = fileselect
	Variable apod
	prompt apod, "Enter the Gaussian FWHM in Hz"
	apod = ((2/pi)*(ln(2)))/apod
	apod = 1/apod
	Silent 1

	variable checka																		//we check first whether or not the two cursors are on the screen
	variable checkb

	if(zerofillbool)																		//if zero fill is checked activate the  zerofill prompt function
		variable/G zfill
		ZfillPrompt()																	//put the time in sec (it is prompted in msec)
	endif

	checka = waveexists(Csrwaveref(A))
	checkb = waveexists(Csrwaveref(B))
	GetAxis/Q Bottom
	if(usecursors == 0) 																	//"usecursors" is a global variable, which is 1 if the user wants to set the FFT range
		Cursor A, source_wave_real, V_min; Cursor B, source_wave_real, V_max;				//with the cursors and 0 if they just want to FFT the whole screen.  If it is zero here
	endif																				//we just throw some cursors up on the limits of the screen
	if(checka==0)																		//make sure there is actually a cursor A and B to set the range if usecursors, if not, just FFT the
		Cursor A, source_wave_real, V_min; Cursor B, source_wave_real, V_max;				//whole screen
	endif
	if(checkb==0)
		Cursor A, source_wave_real, V_min; Cursor B, source_wave_real, V_max;
	endif

	variable points																		//These variable are for storing a waves dimensions and scaling
	variable step
	variable start

	Duplicate/O source_wave_real, tempsource_wave_real			//we duplicate the data waves in the phase and save program (the portion
	Duplicate/O source_wave_imag, tempsource_wave_imag			//selected)
	Duplicate/O source_wave_imag, tempsource_wave_mag			//duplicate a magnitude wave (just to have another wave here

	//Get rid of dependencies on first phasing
	SetFormula tempsource_wave_real, ""
	SetFormula tempsource_wave_imag, ""
	SetFormula tempsource_wave_mag,""

	Duplicate/O/R=(xcsr(A),xcsr(B)) tempsource_wave_real, ftsource_wave_real			//we duplicate the data waves in the phase and save program (the portion
	Duplicate/O/R=(xcsr(A),xcsr(B)) tempsource_wave_imag, ftsource_wave_imag			//selected)
	Duplicate/O/R=(xcsr(A),xcsr(B)) tempsource_wave_imag, ftsource_wave_mag			//duplicate a magnitude wave (just to have another wave here)


 	if(usecursors == 0)
		GetAxis/Q bottom
		Cursor/K A
		Cursor/K B
		HideInfo
	endif
																						//the variable apod stors the apodization value in Hz.  We multiply by a gaussian
																						//centered on the left edge of FFT range.  This is the gaussian apodization
	ftsource_wave_real= ftsource_wave_real*exp(-(((x - start)*apod)^2))
	ftsource_wave_imag= ftsource_wave_imag*exp(-(((x - start)*apod)^2))

	if(zerofillbool)																			//if zerofill was checked append the desired points
		variable tempsteps
		variable temptotalsteps
		tempsteps = deltax(ftsource_wave_real)
		tempsteps = round(zfill/tempsteps)
		temptotalsteps = DimSize(ftsource_wave_real,0)

		ftsource_wave_real = ftsource_wave_real - ftsource_wave_real[(temptotalsteps - 1)]
		ftsource_wave_imag = ftsource_wave_imag - ftsource_wave_imag[(temptotalsteps - 1)]

		InsertPoints (temptotalsteps),(tempsteps), ftsource_wave_real
		InsertPoints (temptotalsteps),(tempsteps), ftsource_wave_imag
		InsertPoints (temptotalsteps),(tempsteps), ftsource_wave_mag
	endif

	points = DimSize(ftsource_wave_real,0)								//record the dimensions of the wave
	step = deltax(ftsource_wave_real)
	start = leftx(ftsource_wave_real)

	make/o/C ftsource_wave_cmplx												//make a complex wave with the same dimensions and make it the complex signal
	Redimension/N = (points) ftsource_wave_cmplx									//wave
	SetScale/P x (start),(step),"s", ftsource_wave_cmplx

	ftsource_wave_cmplx=ftsource_wave_real + cmplx(0,1)*ftsource_wave_imag
	ftsource_wave_cmplx[0] = ftsource_wave_cmplx[0]/2						//make correction for FFT operation
	FFT ftsource_wave_cmplx													//FFT the complex wave

	points = DimSize(ftsource_wave_cmplx,0)										//record the new dimensions/scaling of the complex wave
	step = deltax(ftsource_wave_cmplx)
	start = leftx(ftsource_wave_cmplx)

	ftsource_wave_real= 0														//make the real and imaginary and magnitude waves have these dimensions/scaling and set them = 0
	Redimension/N = (points) ftsource_wave_real
	SetScale/P x (start),(step),"Hz", ftsource_wave_real

	ftsource_wave_imag= 0
	Redimension/N = (points) ftsource_wave_imag
	SetScale/P x (start),(step),"Hz", ftsource_wave_imag

	ftsource_wave_mag= 0
	Redimension/N = (points) ftsource_wave_mag
	SetScale/P x (start),(step),"Hz", ftsource_wave_mag
	ftsource_wave_mag=sqrt(magsqr(ftsource_wave_cmplx))							//set the magnitude wave equal to the magnitude of the complex FFT

	variable/G phaseFFT																	//this is the phase factor for the FFT	, which will be equal to a fine + a course phase
	variable/G finepft
	variable/G coursepft
	variable/G phaseone																	//This is the phase one correction in seconds
	variable/G phaseoneus																//this is the phase one	 correction in micro seconds
	phaseone = 0																		//initialize the phase one corrections to zero
	phaseoneus = 0

	duplicate/o ftsource_wave_mag, phaseonewave									//make a wave whose entries are 2*pi*v where v is the frequency independent variableof the FFT
	phaseonewave = 2*pi*x

	finepft=0																				//initialize the phase corrections to zero
	coursepft=0

	phaseone := (10^-6)*phaseoneus												//the phase one is set in terms of the phaseoneus which is set by the user
	phaseFFT := finepft + coursepft												// the phase is set as the sum of the course and fine phase adjustments

	ftsource_wave_real:= (real(ftsource_wave_cmplx)*cos(phaseFFT - phaseonewave*phaseone) + imag(ftsource_wave_cmplx)*sin(phaseFFT - phaseonewave*phaseone))
	ftsource_wave_imag := (imag(ftsource_wave_cmplx)*cos(phaseFFT - phaseonewave*phaseone) - real(ftsource_wave_cmplx)*sin(phaseFFT - phaseonewave*phaseone))
																						//set the real and imaginary FFT in terms of the complex FFT with the given
																						//phase and phase one (2*pi*v*(offset time)) correction
	BuildFTGraph() 																//Build the FFT graph
End


Proc ExpApodFourierTransform(apod)
	variable/G ftfileselect = fileselect
	Variable apod
	Prompt apod, "Enter the Lorentzian FWHM in Hz"
	apod = 1/(pi*apod)
	apod = 1/apod
	Silent 1

	GetAxis/Q Bottom
	variable checka																		//we check first whether or not the two cursors are on the screen
	variable checkb

	if(zerofillbool)																		//if zero fill is checked activate the  zerofill prompt function
		variable/G zfill
		ZfillPrompt()																	//put the time in sec (it is prompted in msec)
	endif


	checka = waveexists(Csrwaveref(A))
	checkb = waveexists(Csrwaveref(B))

	if(usecursors == 0) 																	//"usecursors" is a global variable, which is 1 if the user wants to set the FFT range
		Cursor A, source_wave_real, V_min; Cursor B, source_wave_real, V_max;				//with the cursors and 0 if they just want to FFT the whole screen.  If it is zero here
	endif																				//we just throw some cursors up on the limits of the screen
	if(checka==0)																		//make sure there is actually a cursor A and B to set the range if usecursors, if not, just FFT the
		Cursor A, source_wave_real, V_min; Cursor B, source_wave_real, V_max;				//whole screen
	endif
	if(checkb==0)
		Cursor A, source_wave_real, V_min; Cursor B, source_wave_real, V_max;
	endif

	variable points																		//These variable are for storing a waves dimensions and scaling
	variable step
	variable start

	Duplicate/O source_wave_real, tempsource_wave_real			//we duplicate the data waves in the phase and save program (the portion
	Duplicate/O source_wave_imag, tempsource_wave_imag			//selected)
	Duplicate/O source_wave_imag, tempsource_wave_mag			//duplicate a magnitude wave (just to have another wave here

	//Get rid of dependencies on first phasing
	SetFormula tempsource_wave_real, ""
	SetFormula tempsource_wave_imag, ""
	SetFormula tempsource_wave_mag,""

	Duplicate/O/R=(xcsr(A),xcsr(B)) tempsource_wave_real, ftsource_wave_real			//we duplicate the data waves in the phase and save program (the portion
	Duplicate/O/R=(xcsr(A),xcsr(B)) tempsource_wave_imag, ftsource_wave_imag			//selected)
	Duplicate/O/R=(xcsr(A),xcsr(B)) tempsource_wave_imag, ftsource_wave_mag			//duplicate a magnitude wave (just to have another wave here)

	if(usecursors == 0)
		GetAxis/Q bottom
		Cursor/K A
		Cursor/K B
		HideInfo
	endif

																						//the variable apod stors the apodization value in Hz.  We multiply by an exponential
																						//with "zero" at the left edge of FFT range.  This is the exponential apodization
	ftsource_wave_real = ftsource_wave_real*exp(-(x - start)*apod)
	ftsource_wave_imag = ftsource_wave_imag*exp(-(x - start)*apod)


	if(zerofillbool)																			//if zerofill was checked append the desired points
		variable tempsteps
		variable temptotalsteps
		tempsteps = deltax(ftsource_wave_real)
		tempsteps = round(zfill/tempsteps)
		temptotalsteps = DimSize(ftsource_wave_real,0)

		ftsource_wave_real = ftsource_wave_real - ftsource_wave_real[(temptotalsteps - 1)]
		ftsource_wave_imag = ftsource_wave_imag - ftsource_wave_imag[(temptotalsteps - 1)]

		InsertPoints (temptotalsteps),(tempsteps), ftsource_wave_real
		InsertPoints (temptotalsteps),(tempsteps), ftsource_wave_imag
		InsertPoints (temptotalsteps),(tempsteps), ftsource_wave_mag
	endif


	points = DimSize(ftsource_wave_real,0)													//record the dimensions of the wave
	step = deltax(ftsource_wave_real)
	start = leftx(ftsource_wave_real)


	make/o/C ftsource_wave_cmplx												//make a complex wave with the same dimensions and make it the complex signal
	Redimension/N = (points) ftsource_wave_cmplx								//wave
	SetScale/P x (start),(step),"s", ftsource_wave_cmplx

	ftsource_wave_cmplx = ftsource_wave_real + cmplx(0,1)*ftsource_wave_imag
	ftsource_wave_cmplx[0] = ftsource_wave_cmplx[0]/2					//make correction for FFT operation
	FFT ftsource_wave_cmplx												//FFT the complex wave

	points = DimSize(ftsource_wave_cmplx,0)										//record the new dimensions/scaling of the complex wave
	step = deltax(ftsource_wave_cmplx)
	start = leftx(ftsource_wave_cmplx)

	ftsource_wave_real= 0														//make the real and imaginary and magnitude waves have these dimensions/scaling and set them = 0
	Redimension/N = (points) ftsource_wave_real
	SetScale/P x (start),(step),"Hz", ftsource_wave_real

	ftsource_wave_imag= 0
	Redimension/N = (points) ftsource_wave_imag
	SetScale/P x (start),(step),"Hz", ftsource_wave_imag

	ftsource_wave_mag= 0
	Redimension/N = (points) ftsource_wave_mag
	SetScale/P x (start),(step),"Hz", ftsource_wave_mag
	ftsource_wave_mag=sqrt(magsqr(ftsource_wave_cmplx))						//set the magnitude wave equal to the magnitude of the complex FFT

	variable/G phaseFFT																	//this is the phase factor for the FFT	, which will be equal to a fine + a course phase
	variable/G finepft
	variable/G coursepft
	variable/G phaseone																	//This is the phase one correction in seconds
	variable/G phaseoneus																//this is the phase one	 correction in micro seconds
	phaseone = 0																		//initialize the phase one corrections to zero
	phaseoneus = 0

	duplicate/o ftsource_wave_mag, phaseonewave									//make a wave whose entries are 2*pi*v where v is the frequency independent variableof the FFT
	phaseonewave = 2*pi*x

	finepft=0																				//initialize the phase corrections to zero
	coursepft=0

	phaseone := (10^-6)*phaseoneus												//the phase one is set in terms of the phaseoneus which is set by the user
	phaseFFT := finepft + coursepft												// the phase is set as the sum of the course and fine phase adjustments


	ftsource_wave_real:= (real(ftsource_wave_cmplx)*cos(phaseFFT - phaseonewave*phaseone) + imag(ftsource_wave_cmplx)*sin(phaseFFT - phaseonewave*phaseone))
	ftsource_wave_imag := (imag(ftsource_wave_cmplx)*cos(phaseFFT - phaseonewave*phaseone) - real(ftsource_wave_cmplx)*sin(phaseFFT - phaseonewave*phaseone))
																						//set the real and imaginary FFT in terms of the complex FFT with the given
																						//phase and phase one (2*pi*v*(offset time)) correction
	BuildFTGraph() 																//Build the FFT graph
End



Proc BuildFTGraph()															//This macro just activates the FFTgraph() macro if FFTgraph isn't already open
	SetDataFolder root:  // In case other macros do something funny
	DoWindow/F FFTGraph		//Bring the window to the front (so we don't make a million copies)
	If (V_flag<1)			//Build Window if it doesn't already exist
		FFTGraph()
	endif
End


Proc SetWithCursors(ctrlName,secchecked) : CheckBoxControl						//This is controlled by the set with cursors check box on the original phase and save graph.  It sets "usecursors",
	String ctrlName															//which is a global variable, equal to zero if the box is unchecked and 1 if it is checked.  Also, when the box is checked
	Variable secchecked															//cursors are added to the right and left edges of the phase and save graph fot the use to set the FFT range

	if (secchecked)
		usecursors = 1
		GetAxis/Q bottom; Cursor A, source_wave_real, V_min; Cursor B, source_wave_real, V_max;
		Showinfo
	else
		usecursors = 0
		if(baselinebool == 1)
		else
		GetAxis/Q bottom
		Cursor/K A
		Cursor/K B
		HideInfo
		endif
	endif
End

///////////////////////////////////////////////////////////////////////////END KENNY'S FFT ADD ON/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function TestOf2DProcess()

NVAR filenumber, fileselect

Silent 1

variable i=0

Do
	Execute "UpOne(\"button5\")"
	Execute "PhaseCtrl(\"\")"
	i+=1
While (i<filenumber)

End

#pragma rtGlobals=1		// Use modern global access method.

//~~~~~~~~~~~~~~~~~~~~ WATERFALL Manipulate ~~~~~~~~~~~~~~~~~~~~~~~~~~//

// Created by Jared Rovny on Jan 16 2017
// -- used to manipulate data for visualization, using Igor's "fake waterfall" function
//--------
// -- Use the "waterfall manipulate" macro to manipulate a 3D visualization of 3D data. Pick a base wave name, provide the number of waves in each dimension, and use the 
// --    "flip indices" option to look at a slice of many 3D waves at a 2D index instead of many 2D waves at a particular 3D index.
// -------------------

Window FakeWaterfallWindow() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /K=1/W=(33,99,1200,900) as "WaterfallWindow"
	ControlBar 75
	SetVariable dy_var,proc=NewWaterfallControl,limits={-dyLimit,dyLimit,1e3},pos={175,9},size={90,14},title="dY",fSize=12,frame=0
	SetVariable dy_var, value=dy_G
	SetVariable dx_var,proc=NewWaterfallControl,limits={-0.5*dxLimit,0.5*dxLimit,1/(10*dimvar)},pos={175,29},size={90,14},title="dX",fSize=12,frame=0
	SetVariable dx_var, value=dx_G
	Slider dyoffset,proc=SliderWaterfallControl,pos={320,10},size={89,50},title="SliderY",fSize=12,frame=0
	Slider dxoffset,proc=SliderWaterfallControl,pos={411,10},size={89,50},title="SliderX",fSize=12,frame=0
	Slider dyoffset,limits={-dyLimit,dyLimit,1},variable= dy_G,side= 2,vert= 0
	Slider dxoffset,limits={-0.5*dxLimit,0.5*dxLimit,1/(10*dimvar)},variable= dx_G,side= 2,vert= 0
	
	SetVariable /Z WaveStr,pos={649,50},size={147,25},title="Data String",fSize=12,frame=0,value=WaterfallWaveStr_G
	
	CheckBox showrealcheck,pos={546,3},size={58,10},proc=ShowReal,title="Real"										//These checkboxes control which waves are displayed
	CheckBox showrealcheck,variable=showrealvar
	CheckBox showimagecheck,pos={546,18},size={58,10},proc=ShowImagine,title="Imaginary"
	CheckBox showimagecheck,variable=showimagevar
	CheckBox showmagcheck,pos={546,33},size={58,10},proc=ShowMag,title="Magnitude"
	CheckBox showmagcheck,variable=showmagvar
	
	CheckBox flipIndicescheck,pos={546,53},size={58,10},proc=FlipIndices,title="Flip Indices"
	CheckBox flipIndicescheck,variable=flipindices_G

	Button button0,pos={8,6},size={70,42},proc=OpenFFTData,title="Open \rFFT Data"
	Button button1,pos={93,5},size={70,42},proc=FakeWaterfallControl,title="Apply \rWaterfall"
	
	ValDisplay NIWaterfall1,pos={649,7},size={147,14},bodyWidth=62,limits={NIWaterfall_G,NIWaterfall_G,1},title="Num. Images", fSize=12, disable=2
	ValDisplay NIWaterfall1,value=NIWaterfall_G
	
	SetVariable CurrentIndex3D, proc=Set3DImage, limits={1,max(Num3D_G, NIWaterfall_G),1},pos={649,29},size={147,14},bodyWidth=62,title="Index 3D", fSize=12
	SetVariable CurrentIndex3D,value=Index3D_G
	
	SetVariable FilterNums, proc=FilterSideBands, limits={1,dimvar/2,1},pos={900,29},size={147,14},bodyWidth=62,title="Num. of \rFiltered points", fSize=12
	SetVariable FilterNums,value=FilteredPoints_G
	
	CheckBox hiddencheckbox,pos={4,54},size={37,14},proc=HiddenCheck,title="hidden",value= 1
EndMacro



Function FilterSideBands(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable
	
	SVAR WaterfallWaveStr_G
	NVAR NIWaterfall_G, flipIndices_G, num3D_G, index3D_G
	
	Variable i=1; Variable k_2D=1; Variable k_3D=1
	Do
		if(flipIndices_G)
			k_3D = i
			k_2D = min(index3D_G, Num3D_G)
		else
			k_3D = min(index3D_G, Num3D_G)
			k_2D = i
		endif
		
		Duplicate /O/C $(WaterfallWaveStr_G+"["+num2istr(k_2D)+"]["+num2str(k_3D)+"]") $"WaterfallWave_["+num2str(i)+"]"
		
		Wave /C tempwave1 = $"WaterfallWave_["+num2str(i)+"]"
		if(varNum)
			tempwave1[0,varNum-1] = 0 
			tempwave1[dimsize(tempwave1,0)-varNum-1, dimsize(tempwave1,0)-1] = 0 
		endif
	
		i+=1
	While(i<=NIWaterfall_G)
	
End


Function Set3DImage(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable
	
	SVAR WaterfallWaveStr_G
	NVAR NIWaterfall_G, flipIndices_G, num3D_G, FilteredPoints_G
	
	Variable i=1; Variable k_2D=1; Variable k_3D=1
	Do
		if(flipIndices_G)
			k_3D = i
			k_2D = min(varNum, Num3D_G)
		else
			k_3D = min(varNum, Num3D_G)
			k_2D = i
		endif
		
		Duplicate /O/C $(WaterfallWaveStr_G+"["+num2istr(k_2D)+"]["+num2str(k_3D)+"]") $"WaterfallWave_["+num2str(i)+"]"
		
		Wave /C tempwave1 = $"WaterfallWave_["+num2str(i)+"]"
		if(filteredPoints_G)
			tempwave1[0,filteredPoints_G-1] = 0 
			tempwave1[dimsize(tempwave1,0)-filteredPoints_G-1, dimsize(tempwave1,0)-1] = 0 
		endif
	
		i+=1
	While(i<=NIWaterfall_G)
	
End


Function HiddenCheck(ctrlName,checked) : CheckBoxControl		//This function will add/remove the magnitude FID from the graph
	
	String ctrlName
	Variable checked
	String graphName = "FakeWaterfallWindow"
	
	if(checked)
		ModifyGraph/W=$graphName mode=7, hbFill=1
	else
		ModifyGraph/W=$graphName mode=0	
	endif
	
End



Function FlipIndices(ctrlName,checked) : CheckBoxControl		//This function will add/remove the magnitude FID from the graph
	
	String ctrlName
	Variable checked
	String graphName = "FakeWaterfallWindow"
	
	NVAR flipIndices_G, index3D_G
	
	if(checked)
		flipIndices_G = 1
	else
		flipIndices_G = 0
	endif
	
	
	SVAR WaterfallWaveStr_G
	NVAR NIWaterfall_G, Num3D_G
	
	DoWindow/F WaterfallWindow
	
	Variable i=1; Variable k_2D=1; Variable k_3D=1
	Do
	
		If (Exists("WaterfallWave_["+num2istr(i)+"]")!=1)
			break;
		endif
		
		RemoveFromGraph $"WaterfallWave_["+num2istr(i)+"]"
		KillWaves $"WaterfallWave_["+num2istr(i)+"]"
	
		i+=1
	While(i<=NIWaterfall_G)
	
	
	i = NIWaterfall_G
	NIWaterfall_G = Num3D_G
	Num3D_G = i
	
	index3D_G = min(index3D_G, Num3D_G)
	
	Execute "PlotFFTData()"
	
End



Proc OpenFFTData(ctrlName): ButtonControl
	String ctrlName
	SetDataFolder root:  // In case other macros do something funny
	PauseUpdate
	
	Execute "PlotFFTData()"
End



Function PlotFFTData()

	NVAR NIWaterfall_G
	SVAR WaterfallWaveStr_G
	NVAR Index3D_G
	NVAR flipIndices_G
	
	variable frac = floor(65280/(NIWaterfall_G - 1 +1))
	variable i=1;
	variable j=1;
	
	variable k_2D = 1;
	variable k_3D = 1;
	
	variable wavemax_i = 0
	
	NVAR dyLimit, dxLimit, filteredPoints_G
	Wave tempWave = $(WaterfallWaveStr_G+"["+num2istr(1)+"]["+num2str(1)+"]")
	dxLimit=dimdelta(tempwave,0)*dimoffset(tempwave,0)/2
	dyLimit=wavemax_i
	Variable numindices = dimsize(tempwave,0)
	

	i=1
	j=1
	do //This goes through the waves to graph giving them gradually bluer coloring
		
		// print WaterfallWaveStr_G+"["+num2istr(j)+"]["+num2str(Index3D_G)+"]"
		
		if(flipIndices_G)
			k_3D = j
			k_2D = Index3D_G
		else
			k_3D = Index3D_G
			k_2D = j
		endif
		
		If (Exists(WaterfallWaveStr_G+"["+num2istr(k_2D)+"]["+num2str(k_3D)+"]")!=1)
			break;
		endif
	
		DoWindow/F WaterfallWindow
		// print WaterfallWaveStr_G+"["+num2istr(j)+"]["+num2str(Index3D_G)+"]"
		Duplicate /O/C $(WaterfallWaveStr_G+"["+num2istr(k_2D)+"]["+num2str(k_3D)+"]") $"WaterfallWave_["+num2str(j)+"]"
		
		AppendToGraph /C = (65280 - i*frac, 0, i*frac), $"WaterfallWave_["+num2str(j)+"]"
		
		// get the max amplitude of the wave, so you can get good window behavior later -- 
			Wave/C tempwave1 = $"WaterfallWave_["+num2str(j)+"]"
			make /o/n=(dimsize(tempwave1,0)) tempwave2
			
			tempwave2[]=abs(tempwave1[p])
			// print wavemax(tempwave2)
			if(wavemax(tempwave2) > wavemax_i)
				wavemax_i=wavemax(tempwave2)
			endif
		// --
		
		if(filteredPoints_G)
			tempwave1[0,filteredPoints_G-1] = 0 
			tempwave1[dimsize(tempwave1,0)-filteredPoints_G-1, dimsize(tempwave1,0)-1] = 0 
		endif
		
		i+=1
		j+=1
	while (1)

	
	ModifyGraph cmplxMode=1
	
	NVAR dyLimit, dxLimit
	
	Wave tempWave = $(WaterfallWaveStr_G+"["+num2istr(k_2D)+"]["+num2str(k_3D)+"]")
	dxLimit=dimdelta(tempwave,0)*dimoffset(tempwave,0)/2
	dyLimit=wavemax_i
	
	killwaves tempwave2
End

Function ShowReal(ctrlName,checked) : CheckBoxControl		//This function just activates the "add and remove real spectrum from FFT graph" macros which follow it   
	String ctrlName
	Variable checked
	DoWindow/F WaterfallWindow
	if (checked)
		Execute "ModifyGraph cmplxMode=1"
	endif
	NVAR showimagevar
	NVAR showmagvar
	showimagevar=0
	showmagvar=0
End
Function ShowImagine(ctrlName,checked) : CheckBoxControl		//This function just activates the "add and remove real spectrum from FFT graph" macros which follow it   
	String ctrlName
	Variable checked
	DoWindow/F WaterfallWindow
	if (checked)
		Execute "ModifyGraph cmplxMode=2"
	endif
	NVAR showrealvar
	NVAR showmagvar
	showrealvar=0
	showmagvar=0
End
Function ShowMag(ctrlName,checked) : CheckBoxControl		//This function just activates the "add and remove real spectrum from FFT graph" macros which follow it   
	String ctrlName
	Variable checked
	DoWindow/F WaterfallWindow
	if (checked)
		Execute "ModifyGraph cmplxMode=3"
	endif
	NVAR showrealvar
	NVAR showimagevar
	showrealvar=0
	showimagevar=0
End

Function SliderWaterfallControl(name, value, event) : SliderControl
		String name	// name of this slider control
		Variable value	// value of slider
		Variable event	// bit field: bit 0: value set; 1: mouse down, 
					//   2: mouse up, 3: mouse moved
		DoWindow/F WaterfallWindow
		Execute "ApplyFakeWaterfallMac(\"FakeWaterfallWindow\", dx_G, dy_G, 1)"
		
	End


Function NewWaterfallControl(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable
	
	DoWindow/F WaterfallWindow
	Execute "ApplyFakeWaterfallMac(\"FakeWaterfallWindow\", dx_G, dy_G, 1)"
End


Proc FakeWaterfallControl(ctrlName): ButtonControl
	String ctrlName
	SetDataFolder root:  // In case other macros do something funny
	PauseUpdate
	
	Execute "ApplyFakeWaterfallMac(\"FakeWaterfallWindow\", dx_G, dy_G, 1)"
	
End


// Igor can display waterfall plots using the NewWaterfall operation (choose Windows->New->Packages->Waterfall Plot).
// This requires storing your data in a 2D wave. You can also create a 3D waterfall plot using Gizmo.
//
// However, for the common case of displaying a series of spectra, you may find that a "fake waterfall plot"
// is more convenient and works with your original waveform or XY data.
//
// A fake waterfall plot is a regular graph with multiple waveform or XY traces where you use Igor's X and Y
// trace display offset feature to create the waterfall effect. This is simple and also gives you a regular
// Igor graph with regular traces that you can format and annotate using familiar techniques.
//
// The ApplyFakeWaterfall function converts a regular graph to a fake waterfall plot.
// The RemoveFakeWaterfall function converts it back to a regular graph.

Function ApplyFakeWaterfallMac(graphName, dx, dy, hidden)		// e.g., ApplyFakeWaterfall("Graph0", 2, 100, 1)
	String graphName	// Name of graph or "" for top graph
	Variable dx, dy		// Used to offset traces to create waterfall effect
	Variable hidden		// If true, apply hidden line removal
	
	String traceList = TraceNameList(graphName, ";", 1)
	Variable numberOfTraces = ItemsInLIst(traceList)

	Variable traceNumber
	for(traceNumber=0; traceNumber<numberOfTraces; traceNumber+=1)
		String trace = StringFromList(traceNumber, traceList)
		Variable offsetX = (numberOfTraces-traceNumber-1) * dx
		Variable offsetY = (numberOfTraces-traceNumber-1) * dy
		ModifyGraph/W=$graphName offset($trace)={offsetX,offsetY}
		ModifyGraph/W=$graphName plusRGB($trace)=(65535,65535,65535)	// Fill color is white
		if (hidden)
			ModifyGraph/W=$graphName mode($trace)=7, hbFill($trace)=1		// Fill to zero, erase mode
		else
			ModifyGraph/W=$graphName mode($trace)=0						// Lines between points
		endif
	endfor
End

Function RemoveFakeWaterfallMac(graphName)		// e.g., RemoveFakeWaterfall("Graph0")
	String graphName	// Name of graph or "" for top graph
	
	String traceList = TraceNameList(graphName, ";", 1)
	Variable numberOfTraces = ItemsInLIst(traceList)

	Variable traceNumber
	for(traceNumber=0; traceNumber<numberOfTraces; traceNumber+=1)
		String trace = StringFromList(traceNumber, traceList)
		ModifyGraph/W=$graphName offset($trace)={0,0}
		ModifyGraph/W=$graphName mode($trace)=0							// Lines between points
		ModifyGraph/W=$graphName plusRGB($trace)=(65535,65535,65535)	// Fill color is white
	endfor
End




Macro WaterfallManipulate()
	SetDataFolder root:  // In case other macros do something funny
	
	Variable/G NIWaterfall_G=0, dy_G=0, dx_G=0,dyLimit=1e5,dxLimit=5000,showrealvar=1,showimagevar=0,showmagvar=0, dimvar=0, Index3D_G=1, Num3D_G=1, flipIndices_G=0, FilteredPoints_G=0
	String/G WaterfallWaveStr_G="QuadraticEcFFT"
	
	// get the wavename and number of waves
	GetWaveDialog()

	// get the limits of those waves
	duplicate /C/O $WaterfallWaveStr_G tempWaveR
	redimension /r tempwaveR
	dxLimit=pnt2x($WaterfallWaveStr_G, dimsize($WaterfallWaveStr_G,0))
	dyLimit=wavemax(tempWaveR)
	dimvar=dimsize($WaterfallWaveStr_G,0)
	killwaves tempwaveR
	
	// print dxLimit, dyLimit

	// get the base wave string, to which will be appended "[1]", "[2]", etc.
	Variable nameSize=strlen(WaterfallWaveStr_G)
	nameSize = nameSize - 7 - floor(log(Index3D_G))
	WaterfallWaveStr_G = WaterfallWaveStr_G[0,(nameSize)]
	
	If (Exists("WaterfallManipulateWave")<1)
		Make/O WaterfallManipulateWave
	endif
	DoWindow/F FakeWaterfallWindow		//Bring the window to the front (so we don't make a million copies)
	If (V_flag<1)			//Build Window if it doesn't already exist
		FakeWaterfallWindow()
		DoWindow/T FakeWaterfallWindow, "Waterfall Window"
	endif
	
	Execute "PlotFFTData()"
	Execute "ApplyFakeWaterfallMac(\"FakeWaterfallWindow\", dx_G, dy_G, 1)"
End


Function GetWaveDialog()
	
	NVAR NIWaterfall_G
	NVAR Index3D_G
	NVAR Num3D_G
	SVAR WaterfallWaveStr_G
	NVAR flipIndices_G
	
	Variable LocalNIWaterfall
	String LocalWaterfallWaveStr
	Variable LocalIndex3D
	Variable LocalNum3D
	Variable LocalFlipIndices

	Prompt LocalWaterfallWaveStr, "Choose base wave", popup WaveList("*[1][1]*", ";", "")
	Prompt LocalNIWaterfall, "Enter number of images per waterfall: "
	Prompt LocalNum3D, "Enter total number of 3D waves (or 2D waves, if flipping): "
	Prompt LocalIndex3D, "Enter starting 3D index: "
	Prompt LocalFlipIndices, "Do you want to flip your 2D & 3D indices?"
	DoPrompt "Waterfall preparation", LocalWaterfallWaveStr, LocalNIWaterfall, LocalNum3D, LocalIndex3D, LocalFlipIndices
	
	WaterfallWaveStr_G = LocalWaterfallWaveStr
	NIWaterfall_G = LocalNIWaterfall
	Index3D_G = LocalIndex3D
	Num3D_G = LocalNum3D
	flipIndices_G = LocalFlipIndices
	
End
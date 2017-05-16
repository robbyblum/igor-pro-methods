#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function y2pnt(inputWave, y1)
	Wave inputWave
	Variable y1
	
	return round((y1 - DimOffset(inputWave, 1))/DimDelta(inputWave,1))
End

Function z2pnt(inputWave, z1)
	Wave inputWave
	Variable z1
	
	return round((z1 - DimOffset(inputWave, 2))/DimDelta(inputWave,2))
End

Function t2pnt(inputWave, t1)
	Wave inputWave
	Variable t1
	
	return round((t1 - DimOffset(inputWave, 3))/DimDelta(inputWave,3))
End

Function pnt2y(inputWave, pntNum)
	Wave inputWave
	Variable pntNum
	
	return DimOffset(inputWave, 1) + trunc(pntNum)*DimDelta(inputWave,1)
End

Function pnt2z(inputWave, pntNum)
	Wave inputWave
	Variable pntNum
	
	return DimOffset(inputWave, 2) + trunc(pntNum)*DimDelta(inputWave,2)
End

Function pnt2t(inputWave, pntNum)
	Wave inputWave
	Variable pntNum
	
	return DimOffset(inputWave, 3) + trunc(pntNum)*DimDelta(inputWave,3)
End


Function CopyScale(srcWave,destWave,srcDim,destDim)
	Wave srcWave
	Wave destWave
	Variable srcDim
	Variable destDim
	
	switch(destDim)
		case 0:
			SetScale/P x, DimOffset(srcWave,srcDim), DimDelta(srcWave,srcDim), WaveUnits(srcWave,srcDim), destWave
			break
		case 1:
			SetScale/P y, DimOffset(srcWave,srcDim), DimDelta(srcWave,srcDim), WaveUnits(srcWave,srcDim), destWave
			break
		case 2:
			SetScale/P z, DimOffset(srcWave,srcDim), DimDelta(srcWave,srcDim), WaveUnits(srcWave,srcDim), destWave
			break
		case 3:
			SetScale/P t, DimOffset(srcWave,srcDim), DimDelta(srcWave,srcDim), WaveUnits(srcWave,srcDim), destWave
			break
		default:
			print "ERROR: invalid destDim!"
	endswitch
	
End



// Dang, why did I have to make this function myself? This is the kind of thing that should be built-in.
Function CloseAllGraphs()
	String GraphList= WinList("*",";","WIN:1")

	String windowName
	Variable i=0
	do
		windowName= StringFromList(i,GraphList)
		if( strlen(windowName) == 0 )
			break
		endif
		
		Execute ("DoWindow/K "+windowName)
		
		i += 1
	while (1)	// exit is via break statement
End

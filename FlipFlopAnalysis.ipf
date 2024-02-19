//﻿#pragma TextEncoding = "UTF-8" // Chip commented this out, but perhaps it's important?
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
//--------------------------------------------------------------------------//
// Chip's SUMMARY of what the macros do, in rough order of use:
//--------------------------------------------------------------------------//
// First, load the needed flip flop data from CSV files:
//
// LoadFlipFlopDataMT()  -- loads microtubule track data and creates plot
// LoadFlipFlopDataG()  -- loads GFP track data, applies drift correction and creates plot
// LoadFlipFlopDataD()  -- loads DNA track data, applies drift correction and creates plot
//--------------------------------------------------------------------------//
// Next, adjust VLines to indicate start or end times for the windows using the following utilities:
//
// GtoMTtransfer()  -- copies VLines from the GFP graph to the MT graph
// GtoDtransfer()  -- copies VLines from the GFP graph to the DNA graph
// DtoGtransfer()  -- copies VLines from the DNA graph to the GFP graph
// HideVlines()  -- removes (hides) VLines from MT, GFP, and DNA graphs
//--------------------------------------------------------------------------//
// Once VLines are correctly indicating start or end times, these times can be saved into window start/end waves:
//
// MTstarts()  -- saves window start times from the MT graph, and puts VLines at these times onto the GFP and DNA graphs
// GDstarts()  -- saves window start times from the GFP and DNA graphs
// MTends()  -- saves window end times from the MT graph, and puts VLines at these times onto the GFP and DNA graphs
// GDends()  -- saves window end times form the GFP and DNA graphs
//--------------------------------------------------------------------------//
// To visually check the saved window starts and ends, use the following utilities:
//
// ShowWindows()  -- puts VLines at the saved start AND end times onto MT, GFP, and DNA graphs
// ShowStarts()  -- puts VLines at the saved start times onto MT, GFP, and DNA graphs
// ShowEnds()  -- puts VLines at the saved end times onto MT, GFP, and DNA graphs
//--------------------------------------------------------------------------//
// To calculate and view the mean positions within each saved time window:
//
// CalcMeans()  -- not only calculates mean positions but also indicates means on the flip flop data graphs and makes Y-vs-X plots too
// EqualizeFlipFlopVals()  -- pads all the window time and mean position waves so they all have a row for every time window
// FinalFlipFlopVals()  -- creates a table showing all the window time and mean position waves
//--------------------------------------------------------------------------//
// The macros most useful for command-line entry are listed immediately BELOW, followed by the foundational subroutines,
// and then routines for button-panel operation.
//--------------------------------------------------------------------------//
// Loads MT flip flop data from user specified CSV file.
// Then creates a graph to display just the x-values.
macro LoadFlipFlopdataMT()
  silent 1; pauseupdate
  variable Xnmpp = 76.0 // X-axis nanometers per pixel for the "RED" channel (641-nm excitation) - Josh measured these on 4/26/21
  variable Ynmpp = 76.0 // Y-axis nanometers per pixel for the "RED" channel (641-nm excitation)
  variable Tpf = 0.2 // Time elapsed per frame in seconds
  LoadFlipFlopData()
  Killwaves junk, Trajectory, zW, m0, m1, m2, m3, m4, NPscore
  CalibrateFlipFlopData(Xnmpp,Ynmpp,Tpf)
  DisplayRawFlipFlopDataMT()
  Rename Frame, FrameMT
  Rename xW, xWMT
  Rename yW, yWMT
  DoWindow/F RawFlipFlopData
  DoWindow/C RawFlipFlopDataMT
end
//--------------------------------------------------------------------------//
// Loads GFP flip flop data from user specified CSV file.
// Then creates a graph to display x-values in heavy green, with y-values in light green behind.
macro LoadFlipFlopdataG()
  silent 1; pauseupdate
  variable Xnmpp = 75.3 // X-axis nanometers per pixel for the "GRN" channel (488-nm excitation) - Josh measured these on 4/26/21
  variable Ynmpp = 75.3 // Y-axis nanometers per pixel for the "GRN" channel (488-nm excitation)
  variable Tpf = 0.2 // Time elapsed per frame in seconds
  LoadFlipFlopData()
  //Killwaves junk, Trajectory, zW, m0, m1, m2, m3, m4, NPscore // old version deleted all moments
  Killwaves junk, Trajectory, zW, m1, m3, m4 // new retains m0, spot brightness, m2, a measure of spot size, and NPscore
  //m2*=Xnmpp*Ynmpp // calibration of second moment into nanometers squared (this is only approximate if Xnmpp != Ynmpp)
  Rename m0, m0G
  Rename m2, m2G
  Rename NPscore, NPscoreG
  CalibrateFlipFlopData(Xnmpp,Ynmpp,Tpf)
  LinearDriftCorrect() // also creates graph for displaying the data
  Rename Frame, FrameG
  Rename xW, xWG
  Rename yW, yWG
  Rename xWdc, xWdcG
  Rename yWdc, yWdcG
  Rename fit_xW, fit_xWG
  Rename fit_yW, Fit_yWG
  DoWindow/F RawFlipFlopData
  DoWindow/C RawFlipFlopDataG
  DoWindow/F FlipFlopDataDC
  DoWindow/C FlipFlopDataDCG
  ModifyGraph rgb(yWdcG)=(32768,65280,32768),rgb(xWdcG)=(0,39168,0)
end
//--------------------------------------------------------------------------//
// Loads DNA flip flop data from user specified CSV file.
// Then creates a graph to display x-values in bright red, with y-values in light red behind.
macro LoadFlipFlopdataD()
  silent 1; pauseupdate
  variable Xnmpp = 75.0 // X-axis nanometers per pixel for the "BLU" channel (561-nm excitation) - Josh measured these on 4/26/21
  variable Ynmpp = 74.5 // Y-axis nanometers per pixel for the "BLU" channel (561-nm excitation)
  variable Tpf = 0.2 // Time elapsed per frame in seconds
  LoadFlipFlopData()
  Killwaves junk, Trajectory, zW, m0, m1, m2, m3, m4, NPscore
  CalibrateFlipFlopData(Xnmpp,Ynmpp,Tpf)
  LinearDriftCorrect() // also creates graph for displaying the data
  Rename Frame, FrameD
  Rename xW, xWD
  Rename yW, yWD
  Rename xWdc, xWdcD
  Rename yWdc, yWdcD
  REname fit_xW, fit_xWD
  Rename fit_yW, Fit_yWD
  DoWindow/F RawFlipFlopData
  DoWindow/C RawFlipFlopDataD
  DoWindow/F FlipFlopDataDC
  DoWindow/C FlipFlopDataDCD
  ModifyGraph rgb(yWdcD)=(65280,48896,48896),rgb(xWdcD)=(65280,0,0)
end
//--------------------------------------------------------------------------//
// Gets window start times for the MT data from vline offsets.
// Run this after loading MT, GFP, and DNA data (if available)
// and after adjusting the vline offsets on the MT data graph.
macro MTstarts()
  DoWindow/F RawFlipFlopDataMT
  if(V_flag!=0) // if the RawFlipFlopDataMT window exists
    GetWindowStarts("windowstartMT")
    DoWindow/F FlipFlopDataDCG
    if(V_flag!=0) // if the FlipFlopDataDCG window exists
      updateoffsetwindowstartMT() // then copy the vlines onto it
    endif
    DoWindow/F FlipFlopDataDCD
    if(V_flag!=0) // if the FlipFlopDataDCD window exists
      updateoffsetwindowstartMT() // then copy the vlines onto it
    endif
  else
    Print "MTstarts() routine did not find the window, RawFlipFlopDataMT."
  endif
end
//--------------------------------------------------------------------------//
// Gets window start times for the GFP and DNA data from vline offsets
macro GDstarts()
  DoWindow/F FlipFlopDataDCG
  if(V_flag!=0) // if the FlipFlopDataDCG window exists
    GetWindowStarts("windowstartG") // then get windowstartG values from its vline offsets
  endif
  DoWindow/F FlipFlopDataDCD
  if(V_flag!=0) // if the FlipFlopDataDCD window exists
    GetWindowStarts("windowstartD") // then get windowstartG values from its vline offsets
  endif
end
//--------------------------------------------------------------------------//
// Gets window end times for the MT data from vline offsets.
// Run this after loading MT, GFP, and DNA data (if available)
// and after adjusting the vline offsets on the MT data graph.
macro MTends()
  DoWindow/F RawFlipFlopDataMT
  GetWindowEnds("windowendMT")
  DoWindow/F FlipFlopDataDCG
  if(V_flag!=0) // if the FlipFlopDataDCG window exists
    updateoffsetwindowendMT() // then copy the vlines onto it
  endif
  DoWindow/F FlipFlopDataDCD
  if(V_flag!=0) // if the FlipFlopDataDCD window exists
    updateoffsetwindowendMT() // then copy the vlines onto it
  endif
end
//--------------------------------------------------------------------------//
// Gets window end times for the GFP and DNA data from vline offsets
macro GDends()
  DoWindow/F FlipFlopDataDCG
  if(V_flag!=0) // if the FlipFlopDataDCG window exists
    GetWindowEnds("windowendG") // then get windowendG values from its vline offsets
  endif
  DoWindow/F FlipFlopDataDCD
  if(V_flag!=0) // if the FlipFlopDataDCD window exists
    GetWindowEnds("windowendD") // then get windowendG values from its vline offsets
  endif
end
//--------------------------------------------------------------------------//
// Transfers vlines from the GFP flip flop graph to the DNA flip flop graph.
macro GtoDtransfer()
  silent 1; pauseupdate
  DoWindow/F FlipFlopDataDCG
  if(V_flag!=0) // if the FlipFlopDataDCG window exists
    GetWindowStarts("dummyStarts") // dummy wave to hold vline offsets temporarily
    DoWindow/F FlipFlopDataDCD
    if(V_flag!=0) // if the FlipFlopDataDCD window exists
      concatenate/o/np {dummyStarts},offsets // then put the dummyStarts into offsets
      make/o/n=100 offsets // and pad offsets with zeros up to 100 elements
      updatevlinepositions() // and then put vlines at all the offsets to indicate starts and ends
    endif
  else
    Print "GtoDtransfer() routine did not find the window, FlipFlopDataDCG."
  endif
  killwaves dummyStarts
end
//--------------------------------------------------------------------------//
// Transfers vlines from the GFP flip flop graph to the MT flip flop graph.
macro GtoMTtransfer()
  silent 1; pauseupdate
  DoWindow/F FlipFlopDataDCG
  if(V_flag!=0) // if FlipFlopDataDCG window exists
    GetWindowStarts("dummyStarts") // dummy wave to hold vline offsets temporarily
    DoWindow/F RawFlipFlopDataMT
    if(V_flag!=0) // if the RawFlipFlopDataMT window exists
      concatenate/o/np {dummyStarts},offsets // then put the dummyStarts into offsets
      make/o/n=100 offsets // and pad offsets with zeros up to 100 elements
      updatevlinepositions() // and then put vlines at all the offsets to indicate starts and ends
    endif
  else
    Print "GtoMTtransfer() routine did not find the window, FlipFlopDataDCG."
  endif
  killwaves dummyStarts
end
//--------------------------------------------------------------------------//
// Transfers vlines from the DNA flip flop graph to the MT flip flop graph.
macro DtoMTtransfer()
  silent 1; pauseupdate
  DoWindow/F FlipFlopDataDCD
  if(V_flag!=0) // if the FlipFlopDataDCD window exists
    GetWindowStarts("dummyStarts") // dummy wave to hold vline offsets temporarily
    DoWindow/F RawFlipFlopDataMT
    if(V_flag!=0) // if the RawFlipFlopDataMT window exists
      concatenate/o/np {dummyStarts},offsets // then put the dummyStarts into offsets
      make/o/n=100 offsets // and pad offsets with zeros up to 100 elements
      updatevlinepositions() // and then put vlines at all the offsets to indicate starts and ends
    endif
  else
    Print "DtoMTtransfer() routine did not find the window, FlipFlopDataDCD."
  endif
  killwaves dummyStarts
end
//--------------------------------------------------------------------------//
// Transfers vlines from the DNA flip flop graph to the GFP flip flop graph.
macro DtoGtransfer()
  silent 1; pauseupdate
  DoWindow/F FlipFlopDataDCD
  if(V_flag!=0) // if the FlipFlopDataDCD window exists
    GetWindowStarts("dummyStarts") // dummy wave to hold vline offsets temporarily
    DoWindow/F FlipFlopDataDCG
    if(V_flag!=0) // if the FlipFlopDataDCG window exists
      concatenate/o/np {dummyStarts},offsets // then put the dummyStarts into offsets
      make/o/n=100 offsets // and pad offsets with zeros up to 100 elements
      updatevlinepositions() // and then put vlines at all the offsets to indicate starts and ends
    endif
  else
    Print "DtoGtransfer() routine did not find the window, FlipFlopDataDCD."
  endif
  killwaves dummyStarts
end
//--------------------------------------------------------------------------//
// Calculates average positions and SDs within the selected windows for GFP and DNA flip flop data.
// Then adds symbols to indicate these averages onto the drift corrected data GFP and DNA plots.
macro CalcMeans()
  silent 1; pauseupdate
  variable i=0
  variable meanXavgMT
  if(exists("windowstartMT")&&exists("windowendMT")&&exists("xWMT")) // if MT flip flop data exists
    make/o/n=(numpnts(windowendMT)) XavgMT,windowmdpntMT // then make avg and mdpnt waves
    windowmdpntMT = (windowstartMT+windowendMT)/2
    do // loop through all the windows specified for the MT data
      extract/o xWMT,dummy,(FrameMT>=windowstartMT[i])&&(FrameMT<=windowendMT[i])
      XavgMT[i]=mean(dummy)
      i+=1
    while(i<numpnts(windowendMT))
    meanXavgMT=mean(XavgMT)
    XavgMT=sign(XavgMT-meanXavgMT)
  else
    print "CalcMeans() did not find MT data and/or the corresponding window starts and ends."
  endif
  if(exists("xWdcG")&&exists("yWdcG")&&exists("windowstartG")&&exists("windowendG")) // if drift corrected GFP flip flop data exists
    make/o/n=(numpnts(windowendG)) XavgG,YavgG,XsdG,YsdG,windowmdpntG // then make the avg and mdpnt waves
    windowmdpntG = ((windowstartG+windowendG)/2)
    i=0
    do // loop through all the windows specified for the GFP data
      extract/o xWdcG,dummy,(FrameG>=windowstartG[i])&&(FrameG<=windowendG[i])
      XavgG[i]=mean(dummy)
      XsdG[i]=sqrt(variance(dummy))
      extract/o yWdcG,dummy,(FrameG>=windowstartG[i])&&(FrameG<=windowendG[i])
      YavgG[i]=mean(dummy)
      YsdG[i]=sqrt(variance(dummy))
      i+=1
    while(i<numpnts(windowendG))
    dowindow yWdcGvsxWdcG // sets v_flag equal to 1 if this window exists
     if (v_flag ==0) // if the Y vs X graph does not exist
      display yWdcG vs xwdcG // then make the Y vs X graph
      dowindow/C yWdcGvsxWdcG
      ModifyGraph mode=2,lsize=2,rgb=(30583,30583,30583),mirror=2,standoff=0,grid=2,fSize=8,width=144,height=144,axThick=0.5
      SetAxis left -150,150
      SetAxis bottom -150,150
      Label left "Y position (pixels)"
      Label bottom "X position (pixels)"
      appendtograph YavgG vs XavgG
      ModifyGraph mode(YavgG)=3,marker(YavgG)=19,mrkThick(YavgG)=0.75,rgb(YavgG)=(0,65280,0)
      dowindow/F FlipFlopDataDCG
      appendtograph XavgG vs windowmdpntG
      ModifyGraph mode(XavgG)=3,marker(XavgG)=29,mrkThick(XavgG)=2,rgb(XavgG)=(0,0,0)
      ErrorBars XavgG Y,wave=(XsdG,XsdG)
    endif
  else
    print "CalcMeans() did not find drift corrected GFP data and/or the corresponding window starts and ends.."
  endif
  if(exists("xWdcD")&&exists("yWdcD")&&exists("windowstartD")&&exists("windowendD")) // if drift corrected DNA flip flop data exists
    make/o/n=(numpnts(windowendD)) XavgD,YavgD,XsdD,YsdD,windowmdpntD // then make the avg and mdpnt waves
    windowmdpntD = ((windowstartD+windowendD)/2)
    i=0
    do // loop through all the windows specified for the DNA data
      extract/o xWdcD,dummy,(FrameD>=windowstartD[i])&&(FrameD<=windowendD[i])
      XavgD[i]=mean(dummy)
      XsdD[i]=sqrt(variance(dummy))
      extract/o yWdcD,dummy,(FrameD>=windowstartD[i])&&(FrameD<=windowendD[i])
      YavgD[i]=mean(dummy)
      YsdD[i]=sqrt(variance(dummy))
      i+=1
    while(i<numpnts(windowendD))
    dowindow yWdcDvsxWdcD // sets v_flag equal to 1 if this window exists
    if (v_flag ==0) // if the Y vs X graph does not exist
      display yWdcD vs xWdcD // then make the Y vs X graph
      dowindow/C yWdcDvsxWdcD
      ModifyGraph mode=2,lsize=2,rgb=(30583,30583,30583),mirror=2,standoff=0,grid=2,fSize=8,width=144,height=144,axThick=0.5
      SetAxis left -150,150
      SetAxis bottom -150,150
      Label left "Y position (pixels)"
      Label bottom "X position (pixels)"
      appendtograph YavgD vs XavgD
      ModifyGraph mode(YavgD)=3,marker(YavgD)=19,mrkThick(YavgD)=0.75,rgb(YavgD)=(65280,0,0)
      dowindow/F FlipFlopDataDCD
      appendtograph XavgD vs windowmdpntD
      ModifyGraph mode(XavgD)=3,marker(XavgD)=29,mrkThick(XavgD)=2,rgb(XavgD)=(0,0,0)
      ErrorBars XavgD Y,wave=(XsdD,XsdD)
    endif
  else
    print "CalcMeans() did not find drift corrected DNA data and/or the corresponding window starts and ends."
  endif
  if(exists("xWdcG")&&exists("xWdcD")&&exists("XavgG")&&exists("XavgD")) // if all waves needed for the GFP vs DNA graph exist
    dowindow GFPvsDNA // sets v_flag equal to 1 if this window exists
    if (v_flag ==0) // if the GFPvsDNA graph does not exist
      GraphGFPvsDNA()
    endif
  endif
  if(exists("XavgMT")&&exists("XavgG")&&exists("XavgD")) // if all waves needed for the GD vs MT graph exist
    dowindow GDvsMT // sets v_flag equal to 1 if this window exists
    if (v_flag ==0) // if the GD vs MT graph does not exist
      GraphGDvsMT()
    endif
  endif
  //RefineDriftCorrections() // this "refinement" often seems to make the drift look worse, not better!
end
//--------------------------------------------------------------------------//
// Shows the window starts and ends on all the existing flip flop graphs by adding vlines
macro ShowWindows()
  DoWindow/F RawFlipFlopDataMT
  if((V_flag!=0)&&exists("windowstartMT")&&exists("windowendMT")) // if the FlipFlopDataMT window exists etc
    concatenate/o/np {windowstartMT,windowendMT},offsets // then put all the MT starts and ends into offsets
    make/o/n=100 offsets // and pad offsets with zeros up to 100 elements
    updatevlinepositions() // and then put vlines at all the offsets to indicate starts and ends
  endif
  DoWindow/F FlipFlopDataDCG
  if((V_flag!=0)&&exists("windowstartG")&&exists("windowendG")) // if the FlipFlopDataDCG window exists etc
    concatenate/o/np {windowstartG,windowendG},offsets // then put all the GFP starts and ends into offsets
    make/o/n=100 offsets // and pad offsets with zeros up to 100 elements
    updatevlinepositions() // and then put vlines at all the offsets to indicate starts and ends
  endif
  DoWindow/F FlipFlopDataDCD
  if((V_flag!=0)&&exists("windowstartD")&&exists("windowendD")) // if the FlipFlopDataDCD window exists etc
    concatenate/o/np {windowstartD,windowendD},offsets // then put all the DNA starts and ends into offsets
    make/o/n=100 offsets // and pad offsets with zeros up to 100 elements
    updatevlinepositions() // and then put vlines at all the offsets to indicate window starts and ends
  endif
end
//--------------------------------------------------------------------------//
// Shows the window starts on all the existing flip flop graphs by adding vlines
macro ShowStarts()
  DoWindow/F RawFlipFlopDataMT
  if((V_flag!=0)&&exists("windowstartMT")) // if the FlipFlopDataMT window and windowstartMT exist
    concatenate/o/np {windowstartMT},offsets // then put all the MT starts and ends into offsets
    make/o/n=100 offsets // and pad offsets with zeros up to 100 elements
    updatevlinepositions()
  endif
  DoWindow/F FlipFlopDataDCG
  if((V_flag!=0)&&exists("windowstartG")) // if the FlipFlopDataDCG window and windowstartG exist
    concatenate/o/np {windowstartG},offsets // then put all the MT starts and ends into offsets
    make/o/n=100 offsets // and pad offsets with zeros up to 100 elements
    updatevlinepositions()
  endif
  DoWindow/F FlipFlopDataDCD
  if((V_flag!=0)&&exists("windowstartD")) // if the FlipFlopDataDCD window and windowstartG exist
    concatenate/o/np {windowstartD},offsets // then put all the MT starts and ends into offsets
    make/o/n=100 offsets // and pad offsets with zeros up to 100 elements
    updatevlinepositions()
  endif
end
//--------------------------------------------------------------------------//
// Shows the window starts on all the existing flip flop graphs by adding vlines
macro ShowEnds()
  DoWindow/F RawFlipFlopDataMT
  if((V_flag!=0)&&exists("windowendMT")) // if the FlipFlopDataMT window and windowendMT exist
    concatenate/o/np {windowendMT},offsets // then put all the MT starts and ends into offsets
    make/o/n=100 offsets // and pad offsets with zeros up to 100 elements
    updatevlinepositions()
  endif
  DoWindow/F FlipFlopDataDCG
  if((V_flag!=0)&&exists("windowendG")) // if the FlipFlopDataDCG window and windowendG exist
    concatenate/o/np {windowendG},offsets // then put all the MT starts and ends into offsets
    make/o/n=100 offsets // and pad offsets with zeros up to 100 elements
    updatevlinepositions()
  endif
  DoWindow/F FlipFlopDataDCD
  if((V_flag!=0)&&exists("windowendD")) // if the FlipFlopDataDCD window and windowendD exist
    concatenate/o/np {windowendD},offsets // then put all the MT starts and ends into offsets
    make/o/n=100 offsets // and pad offsets with zeros up to 100 elements
    updatevlinepositions()
  endif
end
//--------------------------------------------------------------------------//
// Removes all the vlines from all existing flip flop graphs
macro HideVlines()
  DoWindow/F RawFlipFlopDataMT
  if(V_flag!=0) // if the FlipFlopDataMT window exists
    make/o/n=100 offsets
    offsets=0
    updatevlinepositions() 
  endif
  DoWindow/F FlipFlopDataDCG
  if(V_flag!=0) // if the FlipFlopDataDCG window exists
    make/o/n=100 offsets
    offsets=0
    updatevlinepositions() 
  endif
  DoWindow/F FlipFlopDataDCD
  if(V_flag!=0) // if the FlipFlopDataDCD window exists
    make/o/n=100 offsets
    offsets=0
    updatevlinepositions() 
  endif
end
//--------------------------------------------------------------------------//
// Creates a table showing all the final values
macro FinalFlipFlopVals()
  DoWindow FinalFlipFlopVals
  if(V_flag==0) // if the FinalVals table does not already exist
    edit // creates a new empty table
    DoWindow/C FinalFlipFlopVals // names the new table
    if(exists("windowstartMT"))
      //sort windowstartMT,windowstartMT,windowendMT,windowmdpntMT,XavgMT // this sort shouldn't be needed?
      append windowstartMT,windowendMT,windowmdpntMT,XavgMT
    endif
    if(exists("windowstartG"))
      //sort windowstartG,windowstartG,windowendG,windowmdpntG,XavgG,XsdG,YavgG,YsdG // this sort shouldn't be needed?
      append windowstartG,windowendG,windowmdpntG,XavgG,XsdG,YavgG,YsdG
    endif
    if(exists("windowstartD"))
      //sort windowstartD,windowstartD,windowendD,windowmdpntD,XavgD,XsdD,YavgD,YsdD // this sort shouldn't be needed?
      append windowstartD,windowendD,windowmdpntD,XavgD,XsdD,YavgD,YsdD
    endif
    ModifyTable/Z size=8,width=55
  else
    Print "FinalVals table has already been created.  Kill it and rerun this macro to refresh."
  endif
end
//--------------------------------------------------------------------------//
// Pads the final vals for MT, GFP, and DNA where needed with NaNs,
// thereby ensuring that all time windows are represented in all three categories.
// This will facilitate compilation together with vals from other individual KTs.
macro EqualizeFlipFlopVals()
  Equalize("G","MT")
  Equalize("D","MT")
  Equalize("D","G")
  Equalize("MT","G")
  Equalize("G","D")
  Equalize("MT","D")
end
//--------------------------------------------------------------------------//
// The macros ABOVE are the most useful for command-line entry.
// Those BELOW are mainly sub-macros called by those above. 
//--------------------------------------------------------------------------//
// A pairwise equalization subroutine called by EqualizeFlipFlopVals() above.
macro Equalize(idA,idB)
  string idA // identifier of waves to be padded, "G", "D", or "MT"
  string idB // identifier of waves to use for reference, "G", "D", or "MT"
  silent 1; pauseupdate
  variable i=0
  variable numpntsA // temp storage for lengths of idA waves
  variable numpntsB = numpnts($("windowmdpnt"+idB)) // storage for lengths of idB waves
  if(exists("windowmdpnt"+idB)) // if CalcMeans was run on the idB data
    do // loop through values of windowmdpnt+idB, padding the idA waves
      if(exists("windowmdpnt"+idA)) // if CalcMeans was run on idA flip flop data
        numpntsA=numpnts($("windowstart"+idA))
        if(i<numpntsA) // if idA flip flop data has an "ith" window....
          if($("windowend"+idB)[i]<$("windowstart"+idA)[i]) // idB window is before the "ith" window of idA
            InsertPoints i,1,$("windowstart"+idA),$("windowend"+idA),$("windowmdpnt"+idA),$("Xavg"+idA) // insert a zero into each idA wave
            $("windowstart"+idA)[i]=$("windowstart"+idB)[i] // copy window limits from idB into idA windows
            $("windowend"+idA)[i]=$("windowend"+idB)[i]
            $("windowmdpnt"+idA)[i]=($("windowstart"+idA)[i]+$("windowend"+idA)[i])/2
            $("Xavg"+idA)[i]=NaN
            if(exists("Xsd"+idA)) // this check is needed because no mean positions besides Xavg exist when idA="MT"
              InsertPoints i,1,$("Xsd"+idA),$("Yavg"+idA),$("Ysd"+idA) // insert a zero into each idA wave
              $("Xsd"+idA)[i]=NaN // and convert zeros to NaNs
              $("Yavg"+idA)[i]=NaN
              $("Ysd"+idA)[i]=NaN
            endif
          endif
        else // else idA flip flop data does NOT have an "ith" window....
          InsertPoints (numpntsA),1,$("windowstart"+idA),$("windowend"+idA),$("windowmdpnt"+idA),$("Xavg"+idA) // add a zero onto bottom of each wave
          $("windowstart"+idA)[numpntsA]=$("windowstart"+idB)[numpntsA] // copy window limits from MT windows
          $("windowend"+idA)[numpntsA]=$("windowend"+idB)[numpntsA]
          $("windowmdpnt"+idA)[numpntsA]=($("windowstart"+idA)[numpntsA]+$("windowend"+idA)[numpntsA])/2
          $("Xavg"+idA)[numpntsA]=NaN
          if(exists("Xsd"+idA)) // this check is needed because no mean positions besides Xavg exist when idA="MT"
            InsertPoints (numpntsA),1,$("Xsd"+idA),$("Yavg"+idA),$("Ysd"+idA) // add a zero onto bottom of each wave
            $("Xsd"+idA)[numpntsA]=NaN // and convert zeros to NaNs
            $("Yavg"+idA)[numpntsA]=NaN
            $("Ysd"+idA)[numpntsA]=NaN
          endif
        endif
      else // else CalcMeans was not run on idA flip flop data, so create empty waves based on idB data
        duplicate/o $("windowstart"+idB),$("windowstart"+idA)
        duplicate/o $("windowend"+idB),$("windowend"+idA)
        duplicate/o $("windowmdpnt"+idB),$("windowmdpnt"+idA)
        make/o/n=(numpntsB) $("Xavg"+idA)
        $("Xavg"+idA)=NaN 
        if(!stringmatch(idA,"MT")) // if idA does not equal "MT"
          make/o/n=(numpntsB) $("Xsd"+idA),$("Yavg"+idA),$("Ysd"+idA) // then make new mean position waves
          $("Xsd"+idA)=NaN // and fill the mean position waves with NaNs
          $("Yavg"+idA)=NaN
          $("Ysd"+idA)=NaN
        endif
        //print "EqualizeFlipFlopVals() did not find "+idA+" window data"
      endif
      i+=1
    while(i<numpntsB) // loop through values of windowmdpnt+idB, padding the idA waves
  else
    //print "EqualizeFlipFlopVals() did not find "+idB+" window data."
  endif
end
//--------------------------------------------------------------------------//
// Loads flip flop data automatically
macro LoadFlipFlopData()
  LoadWave/A/G
  if(exists("wave11")) // normally, twelve waves numbered 0 through 11 would be created
    Rename wave0, Junk
    Rename wave1, Trajectory
    Rename wave2, Frame
    Rename wave3, xW
    Rename wave4, yW
    Rename wave5, zW
    Rename wave6, m0
    Rename wave7, m1
    Rename wave8, m2
    Rename wave9, m3
    Rename wave10, m4
    Rename wave11, NPscore
  else // but some of the files only have eleven, because the "Trajectory" wave was sometimes skipped
    Print "LoadFlipFlopData() did not find all the expected waves."
  endif
  //edit junk, trajectory, frame, xw, yw, zw, m0, m1, m2,m3,m4,NPscore
end
//--------------------------------------------------------------------------//
// Calibrates flip flop data automatically, given calibration coefficients
macro CalibrateFlipFlopData(Xnmpp,Ynmpp,Tpf)
  variable Xnmpp // X-axis nanometers per pixel
  variable Ynmpp // Y-axis nanometers per pixel
  variable Tpf // Time elapsed per frame
  Frame*=Tpf
  xW*=Xnmpp
  yW*=Ynmpp
end
//--------------------------------------------------------------------------//
//Gets window start times from vline offsets
macro GetWindowStarts(wavenm)
  String wavenm // user-input string to indicate wavename for window start times
  if (stringmatch(wavenm, "")) // if user inputs an empty string, then default wave called "windowstart" will be created
    wavenm="windowstart"
  endif
  if(CountVLines()>0)
    make/O/n=(CountVLines()) $wavenm
    variable i=0
    do
      $wavenm[i] = offsets[i]
      //offsets[i] = 0 // un-comment this to "remove" all the vlines after their values have been used
      i=i+1
  while(i<numpnts($wavenm))
  sort $wavenm,$wavenm // sort so they'll be in chronological order rather than reverse chronological like the offsets wave
  UpdateVlinepositions()
  endif
end
//--------------------------------------------------------------------------//
//Gets window end times from vline offsets
macro GetWindowEnds(wavenm)
  String wavenm // user-input string to indicate wavename for window end times
  if (stringmatch(wavenm, "")) // if user inputs an empty string, then default wave called "windowend" will be created
    wavenm="windowend"
  endif
  if(CountVLines()>0)
    make/O/n=(CountVLines()) $wavenm
    variable i=0
    do
      $wavenm[i]=offsets[i]
      //offsets[i] = 0 // un-comment this to "remove" all the vlines after their values have been used
      i=i+1
    while(i<numpnts($wavenm))
    sort $wavenm,$wavenm // sort so they'll be in chronological order rather than reverse chronological like the offsets wave
    UpdateVlinepositions()
  endif
  //edit windowstart, windowend
  //edit offsets
end
//------------------------------------------------------//
//updates offsets with windowstart values//
Function UpdateoffsetwindowstartMT()
  wave offsets
  wave windowstartMT
  offsets[0,(numpnts(windowstartMT)-1)] = windowstartMT
  UpdateVLinePositions()
End
//-------------------------------------------------------//
//updates offsets with windowend values//
Function UpdateoffsetwindowendMT()
  wave offsets
  wave windowendMT
  offsets[0,(numpnts(windowendMT)-1)] = windowendMT
  UpdateVLinePositions()
End
//--------------------------------------------------------------------------//
//Display a graph of the xW and yW waves
macro DisplayRawFlipFlopData()
 Display xW, yW vs Frame // important to plot versus frame because tracking sometimes drops frames!
 DoWindow/C RawFlipFlopData
 SetWindow RawFLipFLopData, hook=NewQuickVLines, hookcursor=0, hookEvents=1
 InitializeVLines()
 ModifyGraph width=360,height=144,mirror=2,fSize=8,standoff=0 //modify graph and display//
 Label bottom "Time (s)"
 Label left "Position (nm)"
 ModifyGraph rgb(yW)=(0,0,65280)
 ReorderTraces xW,{yW}
 Wavestats/Q xW
 SetAxis left(V_min-1),(V_max+1)
 Setaxis/A bottom
end
//--------------------------------------------------------------------------//
//Display a graph of the xW and yW waves specifically for the 641(MT) channel
Macro DisplayRawFlipFlopDataMT()
  display xW vs Frame
  DoWindow/C RawFlipFlopDataMT
  SetWindow RawFLipFLopDataMT, hook=NewQuickVLines, hookcursor=0, hookEvents=1
  InitializeVLines()
  ModifyGraph width=360,height=144,mirror=2,fSize=8,standoff=0,axThick=0.5 //modify graph and display//
  Label bottom "Time (s)"
  Label left "Position (nm)"
  ModifyGraph btLen=4,rgb(xW)=(47872,47872,47872),mode(xW)=2,lsize(xW)=1 // gray dots for the MT graph
  Wavestats/Q xW
  SetAxis left(V_min-1),(V_max+1)
  if(exists("FrameMT")) // if MT flip flop data is already loaded
    wavestats/q FrameMT
    Setaxis bottom V_min,V_max // then set limits of x-axis to match limits of MT flip flop data
  else
    Setaxis/A bottom
  endif
end
//--------------------------------------------------------------------------//
//Applies simple linear drift correction to raw flip flop data
macro LinearDriftCorrect()
  CurveFit/q line xW /X=Frame /D
  duplicate/o xW xWdc
  xWdc=xW-(W_coef[0]+W_coef[1]*Frame[p])
  CurveFit/q line yW /X=Frame /D
  duplicate/o yW yWdc
  yWdc=yW-(W_coef[0]+W_coef[1]*Frame[p])
  display xWdc, yWdc vs Frame
  DoWindow/C FlipFlopDataDC
  SetWindow FlipFlopDataDC, hook=NewQuickVLines, hookcursor=0, hookEvents=1
  InitializeVLines()
  ReorderTraces xWdc,{yWdc}
  Label bottom "Time (s)"
  Label left "Position (nm)"
  ModifyGraph width=360,height=144,mirror=2,fSize=8,standoff=0,axThick=0.5 //modify graph and display
  SetAxis left -150,150
  wavestats/q Frame // find the widest limits among all the loaded data
  variable minpnt=V_min
  variable maxpnt=V_max
  if(exists("FrameMT")) // if MT flip flop data is already loaded
    wavestats/q FrameMT
    minpnt = min(minpnt,V_min)
    maxpnt = max(maxpnt,V_max)
    print "found FrameMT"
  endif
  if(exists("FrameG")) // if GFP flip flop data is already loaded
    wavestats/q FrameG
    minpnt = min(minpnt,V_min)
    maxpnt = max(maxpnt,V_max)
    print "found FrameG"
  endif
  if(exists("FrameD")) // if DNA flip flop data is already loaded
    wavestats/q FrameD
    minpnt = min(minpnt,V_min)
    maxpnt = max(maxpnt,V_max)
    print "found FrameD"
  endif
  Setaxis bottom minpnt,maxpnt // then set limits of x-axis to match widest limits
end 
//---------------------------------------------------------------------------//
// Refines the drift corrections based solely on points inside the windows.
macro RefineDriftCorrections()
  if(exists("XavgG")&&exists("windowmdpntG")&&exists("XsdG")&&exists("xWdcG")&&exists("frameG")&&exists("YavgG")&&exists("YsdG")&&exists("yWdcG"))
    curvefit/q line  XavgG /X=windowmdpntG /W=XsdG // refine X-axis for GFP traces
    LinearShift("XavgG","windowmdpntG",W_coef[0],W_coef[1])
    LinearShift("xWdcG","frameG",W_coef[0],W_coef[1])
    curvefit/q line  YavgG /X=windowmdpntG /W=YsdG // refine Y-axis for GFP traces
    LinearShift("YavgG","windowmdpntG",W_coef[0],W_coef[1])
    LinearShift("yWdcG","frameG",W_coef[0],W_coef[1])
  else
    Print "RefineDriftCorrections() did not find the waves for GFP traces."
  endif

  if(exists("XavgD")&&exists("windowmdpntD")&&exists("XsdD")&&exists("xWdcD")&&exists("frameD")&&exists("YavgD")&&exists("YsdD")&&exists("yWdcD"))
    curvefit/q line  XavgD /X=windowmdpntD /W=XsdD // refine X-axis for DNA traces
    LinearShift("XavgD","windowmdpntD",W_coef[0],W_coef[1])
    LinearShift("xWdcD","frameD",W_coef[0],W_coef[1])
    curvefit/q line  YavgD /X=windowmdpntD /W=YsdD // refine Y-axis for DNA traces
    LinearShift("YavgD","windowmdpntD",W_coef[0],W_coef[1])
    LinearShift("yWdcD","frameD",W_coef[0],W_coef[1])
  else
    Print "RefineDriftCorrections() did not find the waves for DNA traces."
  endif
end
//---------------------------------------------------------------------------//
// Applies simple linear shift to specified wave given offset and slope params from a line fit.
// This is for post-analysis refinement of drift correction, based solely on points inside the windows.
macro LinearShift(Ywname,Xwname,offset,slope)
  string Ywname // name of wave to be shifted, "XavgG", "YavgG", "XavgD", or "YavgD", maybe others too?
  string Xwname // name of wave of corresponding X-values for the wave to be shifted
  variable offset // y-intercept from line fit that defines the new horizontal axis
  variable slope // slope from line fit that defines the new horizontal axis
  silent 1; pauseupdate
  //$(Ywname) = $(Ywname) - (offset+slope*$(Xwname)[p]) // I think this has an error due to scaling problem!!!
end
//--------------------------------------------------------------------------//
// Comparison graph to see if the GFP is outside the DNA
macro GraphGFPvsDNA()
  display xWdcG vs xWdcD
  ModifyGraph mode=2,lsize=2,rgb=(30583,30583,30583),mirror=2,standoff=0,grid=2,fSize=8,width=144,height=144,axThick=0.5
  SetAxis left -150,150
  SetAxis bottom -150,150
  Label left "GFP X-axis position (nm)"
  Label bottom "DNA X-axis position (nm)"
  appendtograph XavgG vs XavgD
  ModifyGraph mode(XavgG)=3,marker(XavgG)=19,mrkThick(XavgG)=0.75,rgb(XavgG)=(0,65280,65280)
  make/o/n=2 dliney, dlinex
  dliney={-150,150}
  dlinex={-150,150}
  appendtograph dliney vs dlinex
  ModifyGraph lstyle(dliney)=1,lsize(dliney)=0.5
  ModifyGraph rgb(dliney)=(0,0,0)
  ModifyGraph lstyle=0
  ModifyGraph marker(XavgG)=19,rgb(XavgG)=(0,65280,65280)
  dowindow/C GFPvsDNA
end
//--------------------------------------------------------------------------//
// Another comparison graph to see if the GFP is outside the DNA
// This one plots both GFP and DNA distances versus the MT orientation
macro GraphGDvsMT()
  wavestats/q XavgMT
  if(numpnts(XavgMT)==V_numNaNs) // the MT orientations are completely undefined
    if (FlipFlopYesNoPanel("Guess MT orientation from GFP?","No","Yes")==1)
      XavgMT=sign(XavgG)
    endif
  endif
  display XavgG,XavgD vs XavgMT
  ModifyGraph mode=4,lsize=0.5,lstyle=0,msize=0,marker=19,rgb(XavgG)=(0,39168,0),rgb(XavgD)=(65280,0,0)
  ModifyGraph mirror=2,standoff=0,grid=2,fSize=8,width=144,height=144,axThick=0.5
  Label left "X-axis position (nm)"
  Label bottom "MT orientation"
  SetAxis bottom -1.5,1.5
  SetAxis left -75,75
  dowindow/C GDvsMT
end
//--------------------------------------------------------------------------//
// Routine to make a button panel, to avoid need for typing seventeen different commands.
macro SetupFlipFlopAnalysis()
  silent 1; pauseupdate
  NewPanel/W=(1670,50,1910,450) as "Flip Flop Analysis" // left,top,right,bottom? coords for chips surface pad
  ModifyPanel cbRGB=(51456,44032,58880) // light purple - GO HUSKIES!
  SetDrawEnv textrgb= (0,0,0),fsize=14,fstyle=1  // black text
  DrawText 60,20,"Flip Flop Analysis" 
  Button LoadMTdata pos={15,30},size={100,30},proc=LoadMTdata,title="Load MT Data", win=Panel0
  Button LoadGFPdata pos={15,65},size={100,30},proc=LoadGFPdata,title="Load GFP Data",win=Panel0
  Button LoadDNAdata pos={15,100},size={100,30},proc=LoadDNAdata,title="Load DNA Data", win=Panel0
  Button GtoMTtran pos={125,30},size={100,30},proc=GtoMTtran,title="G to MT transfer",win=Panel0
  Button GtoDtran pos={125,65},size={100,30},proc=GtoDtran,title="G to D transfer",win=Panel0
  Button DtoGtran pos={125,100},size={100,30},proc=DtoGtran,title="D to G transfer",win=Panel0

  Button MTstarts pos={15,160},size={100,30},proc=MTstartsFunc,title="Get MT starts",win=Panel0
  Button GDstarts pos={15,195},size={100,30},proc=GDstartsFunc,title="Get G & D starts",win=Panel0
  Button MTends pos={15,230},size={100,30},proc=MTendsFunc,title="Get MT ends",win=Panel0
  Button GDends pos={15,265},size={100,30},proc=GDendsFunc,title="Get G & D ends",win=Panel0
  Button HideVlines pos={125,160},size={100,30},proc=HideVLinesFunc,title="Hide All Vlines",win=Panel0
  Button ShowWindows pos={125,195},size={100,30},proc=ShowWindowsFunc,title="Show Windows",win=Panel0
  Button ShowStarts pos={125,230},size={100,30},proc=ShowStartsFunc,title="Show Starts",win=Panel0
  Button ShowEnds pos={125,265},size={100,30},proc=ShowEndsFunc,title="Show Ends",win=Panel0

  Button CalcMeans pos={70,325},size={100,30},proc=CalcMeansFunc,title="Calculate Means",win=Panel0
  Button CreateTable pos={15,360},size={100,30},proc=CreateTableFunc,title="Create Data Table",win=Panel0
  Button Equalize pos={125,360},size={100,30},proc=EqualizeFunc,title="Equalize Table",win=Panel0
end
//----------------------------------------------------------------------------------------------------------------------------//
// All the control functions for the button panel are below.
// Since buttons have to call functions, but all the code is in macros, these just call the macros!
function LoadMTdata(ctrlName) : ButtonControl
  string ctrlName
  execute "LoadFlipFlopDataMT()"
end
function LoadGFPdata(ctrlName) : ButtonControl
  string ctrlName
  execute "LoadFlipFlopDataG()"
end
function LoadDNAdata(ctrlName) : ButtonControl
  string ctrlName
  execute "LoadFlipFlopDataD()"
end
function GtoMTtran(ctrlName) : ButtonControl
  string ctrlName
  execute "GtoMTtransfer()"
end
function GtoDtran(ctrlName) : ButtonControl
  string ctrlName
  execute "GtoDtransfer()"
end
function DtoGtran(ctrlName) : ButtonControl
  string ctrlName
  execute "DtoGtransfer()"
end
function MTstartsFunc(ctrlName) : ButtonControl
  string ctrlName
  execute "MTstarts()"
end
function GDstartsFunc(ctrlName) : ButtonControl
  string ctrlName
  execute "GDstarts()"
end
function MTendsFunc(ctrlName) : ButtonControl
  string ctrlName
  execute "MTends()"
end
function GDendsFunc(ctrlName) : ButtonControl
  string ctrlName
  execute "GDends()"
end
function HideVLinesFunc(ctrlName) : ButtonControl
  string ctrlName
  execute "HideVLines()"
end
function ShowWindowsFunc(ctrlName) : ButtonControl
  string ctrlName
  execute "ShowWindows()"
end
function ShowStartsFunc(ctrlName) : ButtonControl
  string ctrlName
  execute "ShowStarts()"
end
function ShowEndsFunc(ctrlName) : ButtonControl
  string ctrlName
  execute "ShowEnds()"
end
function CalcMeansFunc(ctrlName) : ButtonControl
  string ctrlName
  execute "CalcMeans()"
end
function CreateTableFunc(ctrlName) : ButtonControl
  string ctrlName
  execute "FinalFlipFlopVals()"
end
function EqualizeFunc(ctrlName) : ButtonControl
  string ctrlName
  execute "EqualizeFlipFlopVals()"
end
//----------------------------------------------------------------------------------------------------------------------------//
// Below are routines for semi-automatically compiling data from numerous individual analysis files,
// each corresponding to a single assembled KT particle, into one giant data table, for global analysis.
// The user selects multiple files using a dialog box.
macro compileflipflopdata()
  silent 1; pauseupdate
  variable i,j,done=0,num,numnewevents=0,numfilesselected=0,numnewfiles=0
  string filepath,outputpaths
  num=WaveExists($"filenum")+WaveExists($"filename")+WaveExists($"filelist") // records of the files selected
  num+=WaveExists($"wstartMT")+WaveExists($"wendMT")+WaveExists($"wmdMT") // windows for MT data
  num+=WaveExists($"wstartG")+WaveExists($"wendG")+WaveExists($"wmdG") // windows for GFP data
  num+=WaveExists($"wstartD")+WaveExists($"wendD")+WaveExists($"wmdD") // windows for DNA data
  num+=WaveExists($"XavG")+WaveExists($"XerG")+WaveExists($"YavG")+WaveExists($"YerG") // GFP pos data
  num+=WaveExists($"XavD")+WaveExists($"XerD")+WaveExists($"YavD")+WaveExists($"YerD") // DNA pos data
  num+=WaveExists($"XavMT") // MT orientation data
  if (num==21) // all waves already exist
    print "compileflipflopdata() found that all 21 waves already existed."
  else // all twenty one waves do not already exist...
    make/o/n=0/t filename,filelist
    make/o/n=0 filenum,wstartMT,wendMT,wmdMT,wstartG,wendG,wmdG,wstartD,wendD,wmdD
    make/o/n=0 XavG,XerG,YavG,YerG,XavD,XerD,YavD,YerD,XavMT
    print "compileflipflopdata() created all 21 of the necessary waves."
  endif
  do
    open/r/d/mult=1/t=".pxp" num // file dialog allowing multi-file selection, returns a null string if cancel is pressed
    outputpaths = s_filename
    if (strlen(outputpaths) != 0) // if files were selected
      numfilesselected = itemsinlist(outputpaths,"\r")
      i=0
      do
        killwaves/z windowstartMT,windowendMT,windowmdpntMT,XavgMT
        killwaves/z windowstartG,windowendG,windowmdpntG,XavgG,XsdG,YavgG,YsdG
        killwaves/z windowstartD,windowendD,windowmdpntD,XavgD,XsdD,YavgD,YsdD
        filepath=stringfromlist(i,outputpaths,"\r")
        num=countobjects("",1) // counts number of waves
        loaddata/o/j="windowstartMT;windowendMT;windowmdpntMT;XavgMT" filepath
        loaddata/o/j="windowstartG;windowendG;windowmdpntG;XavgG;XsdG;YavgG;YsdG" filepath
        loaddata/o/j="windowstartD;windowendD;windowmdpntD;XavgD;XsdD;YavgD;YsdD" filepath
        if (num+18 == countobjects("",1)) // if eighteen waves were successfully grabbed
          make/o/n=(numpnts(windowstartMT)) thisfilenum
          make/o/n=(numpnts(windowstartMT))/t thisfilename
          j=0
          do // fill filenum and filename waves
            thisfilenum[j]=numnewfiles
            thisfilename[j]=StringFromList((ItemsInList(filepath,":")-1),filepath,":")
            j+=1
          while (j<numpnts(windowstartMT))
          make/o/n=1/t thisfilelist // one point wave for thisfilelist
          thisfilelist=StringFromList((ItemsInList(filepath,":")-1),filepath,":")
          Concatenate/kill/np {windowstartMT}, wstartMT
          Concatenate/kill/np {windowendMT}, wendMT
          Concatenate/kill/np {windowmdpntMT}, wmdMT
          Concatenate/kill/np {XavgMT}, XavMT
          Concatenate/kill/np {windowstartG}, wstartG
          Concatenate/kill/np {windowendG}, wendG
          Concatenate/kill/np {windowmdpntG}, wmdG
          Concatenate/kill/np {XavgG}, XavG
          Concatenate/kill/np {XsdG}, XerG
          Concatenate/kill/np {YavgG}, YavG
          Concatenate/kill/np {YsdG}, YerG          
          Concatenate/kill/np {windowstartD}, wstartD
          Concatenate/kill/np {windowendD}, wendD
          Concatenate/kill/np {windowmdpntD}, wmdD
          Concatenate/kill/np {XavgD}, XavD
          Concatenate/kill/np {XsdD}, XerD
          Concatenate/kill/np {YavgD}, YavD
          Concatenate/kill/np {YsdD}, YerD
          Concatenate/kill/np {thisfilenum}, filenum
          Concatenate/kill/np {thisfilename}, filename
          Concatenate/kill/np {thisfilelist}, filelist
          numnewevents+=j
        else
          Print "Could not load the required waves from file: "+filepath
        endif
        i+=1
        numnewfiles+=1
      while (i<numfilesselected)
    endif
    if (FlipFlopYesNoPanel("MoreFiles?","No","Yes")==0)
      done=1
    endif
  while(done!=1)
  Print "Got "+num2str(numnewevents)+" from "+num2str(numnewfiles)+" files"
  makecompilationdatatable()
end
//----------------------------------------------------------------------------------------------------------------------------//
// Makes a table showing all the compiled data
macro makecompilationdatatable()
  DoWindow/F MsmntTable
  if (V_flag == 0) // if table does not already exist
    Edit filenum,filename,wstartMT,wendMT,wmdMT,XavMT,wstartG,wendG,wmdG,XavG,XerG,YavG,YerG,wstartD,wendD,wmdD,XavD,XerD,YavD,YerD,filelist
    DoWindow /C $"MsmntTable"
    MoveWindow 10,40,800,500
    ModifyTable size=8,width=40
  endif
end
//-------------------------------------------------------------------------------------------------------------//
// Josh's Yes No Panel copied below
// This version is identical to that in "CompileDam1Data", but I gave it a unique name,
// with "FlipFlop" in the name, just so this IPF file can be self-sufficient while avoiding conflict
// when both IPFs are loaded.  -Chip, 4/23/2021
Function FlipFlopYesNoPanel(InputString,button0Name,button1Name)	
	// Makes an Yes/No dialog box.  
	// Returns 0 if button0 is pressed,
	//             1 if button1 is pressed
	String InputString,button0Name,button1Name	// Dialog text, and name of two buttons	
	NewPanel/k=2/W=(600,300,800,400) //left,top,right,bottom
	DoWindow/C FlipFlopDialogPanel // renames the window "FlipFlopDialogPanel"
	SetDrawEnv xcoord= rel,ycoord= rel,textxjust= 1,textyjust= 1 // use relative coords and center justify text
	DrawText 0.5,0.2,InputString // draws the text with relative coordinates
	Button FlipFlopButton0 pos={20,60},size={60,20},proc=FlipFlopButton0,title=button0Name
	Button FlipFlopButton1 pos={110,60},size={60,20},proc=FlipFlopButton1,title=button1Name
	variable/G whichButton = NaN // create a global variable to remember which button is pressed
	PauseForUser FlipFlopDialogPanel // pauses operation until the "Dialog Panel" window is killed
	variable temp = whichButton // stores state of whichButton global variable in local temp variable
	Killvariables/Z whichButton // kills the global variable
	//print "got the following:  "+num2str(temp)
	return temp // returns the number of the button that got pressed
End
Function FlipFlopButton0(ctrlName) : ButtonControl
String ctrlName
	NVAR whichButton // local definition of global variable
	whichButton = 0 // set global variable 
	DoWindow/K FlipFlopDialogPanel // kill the window "DialogPanel"
End
Function FlipFlopButton1(ctrlName) : ButtonControl
String ctrlName
	NVAR whichButton
	whichButton = 1
	DoWindow/K FlipFlopDialogPanel
End
//-------------------------------------------------------------------------------------------------------------//
// This is a messy macro to quickly generate graphs for looking at compiled data
macro CompilationGraphs()
  dowindow/F GDvsMT
  if (V_flag == 0) // if GDvsMT graph does not already exist
    display XavG,XavD vs XavMT // essentially the same graph as above but for compiled data from many KT particles
    ModifyGraph mode=4,lsize=0.5,lstyle=0,msize=0,marker=19,rgb(XavG)=(0,39168,0),rgb(XavD)=(65280,0,0)
    ModifyGraph mirror=2,standoff=0,grid=2,fSize=8,width=144,height=144,axThick=0.5
    Label left "X-axis position (nm)"
    Label bottom "MT orientation"
    SetAxis bottom -1.5,1.5
    SetAxis left -75,75
    dowindow/C GDvsMT
  endif
  dowindow/f GFPvsDNA
  if(V_flag==0) // if GFPvsDNA graph does not already exist
    display  XavG vs XavD
    ModifyGraph mode=3,marker=19,mrkThick=0.75,mirror=2,standoff=0,grid=2,fSize=8,width=144,height=144,axThick=0.5
    ModifyGraph rgb=(0,65280,65280)
    SetAxis left -75,75
    SetAxis bottom -75,75
    Label left "GFP X-axis position (nm)"
    Label bottom "DNA X-axis position (nm)"
    make/o/n=2 dliney, dlinex
    dliney={-75,75}
    dlinex={-75,75}
    appendtograph dliney vs dlinex
    ModifyGraph lstyle(dliney)=1,lsize(dliney)=0.5
    ModifyGraph rgb(dliney)=(0,0,0)
    ModifyGraph lstyle=0
    dowindow/C GFPvsDNA
  endif
  dowindow/f XvsFlop
  if(V_flag==0) // if XvsFlop graph does not already exist
    display XavD,XavG
    modifygraph mode=3,marker=19,mrkThick=0.75,mirror=2,standoff=0,grid=2,fSize=8,width=180,height=144,axThick=0.5
    modifygraph rgb(XavG)=(0,52224,0),rgb(XavD)=(65280,0,0)
    setaxis left -75,75
    label left "X-axis position (nm)"
    label bottom "Half-period (flop) number"
    dowindow/c XvsFlop
  endif
  dowindow/F GDYvsMT
  if (V_flag == 0) // if GDYvsMT graph does not already exist [Y-axis version]
    display YavG,YavD vs XavMT // essentially the same graph as above but for compiled data from many KT particles
    ModifyGraph mode=4,lsize=0.5,lstyle=1,msize=0,marker=8,rgb(YavG)=(0,39168,0),rgb(YavD)=(65280,0,0)
    ModifyGraph mirror=2,standoff=0,grid=2,fSize=8,width=144,height=144,axThick=0.5
    Label left "Y-axis position (nm)"
    Label bottom "MT orientation"
    SetAxis bottom -1.5,1.5
    SetAxis left -75,75
    dowindow/C GDYvsMT
  endif
  dowindow/f GFPYvsDNAY
  if(V_flag==0) // if GFPYvsDNAY graph does not already exist
    display  YavG vs YavD
    ModifyGraph mode=3,marker=8,mrkThick=0.75,mirror=2,standoff=0,grid=2,fSize=8,width=144,height=144,axThick=0.5
    ModifyGraph rgb=(0,65280,65280)
    SetAxis left -75,75
    SetAxis bottom -75,75
    Label left "GFP Y-axis position (nm)"
    Label bottom "DNA Y-axis position (nm)"
    make/o/n=2 dliney, dlinex
    dliney={-75,75}
    dlinex={-75,75}
    appendtograph dliney vs dlinex
    ModifyGraph lstyle(dliney)=1,lsize(dliney)=0.5
    ModifyGraph rgb(dliney)=(0,0,0)
    ModifyGraph lstyle=0
    dowindow/C GFPYvsDNAY
  endif
  dowindow/f YvsFlop
  if(V_flag==0) // if YvsFlop graph does not already exist
    display YavD,YavG
    modifygraph mode=3,marker=8,mrkThick=0.75,mirror=2,standoff=0,grid=2,fSize=8,width=180,height=144,axThick=0.5
    modifygraph rgb(YavG)=(0,52224,0),rgb(YavD)=(65280,0,0)
    setaxis left -75,75
    label left "Y-axis position (nm)"
    label bottom "Half-period (flop) number"
    dowindow/c YvsFlop
  endif
  dowindow/f Xhisto
  if(V_flag==0) // if the Xhisto graph does not already exist
    make/n=20/o XavD_Hist
    histogram/b={-75,7.5,20} XavD,XavD_Hist
    make/n=20/o XavG_Hist
    histogram/b={-75,7.5,20} XavG,XavG_Hist
    display XavD_Hist,XavG_Hist
    modifygraph mode=6,lsize=0.75,mirror=2,standoff=0,fSize=8,axThick=0.5
    modifygraph rgb(XavD_Hist)=(65280,0,0),rgb(XavG_Hist)=(0,52224,0)
    modifygraph swapXY=1,width=108,height=144
    label bottom "Counts"
    label left "X-axis position (nm)"
    dowindow/c Xhisto
  endif
  dowindow/f Yhisto
  if(V_flag==0) // if the Yhisto graph does not already exist
    make/n=20/o YavD_Hist
    histogram/b={-75,7.5,20} YavD,YavD_Hist
    make/n=20/o YavG_Hist
    histogram/b={-75,7.5,20} YavG,YavG_Hist
    display YavD_Hist,YavG_Hist
    modifygraph mode=6,lsize=0.75,mirror=2,standoff=0,fSize=8,axThick=0.5
    modifygraph rgb(YavD_Hist)=(65280,0,0),rgb(YavG_Hist)=(0,52224,0)
    modifygraph swapXY=1,width=108,height=144
    label bottom "Counts"
    label left "Y-axis position (nm)"
    dowindow/c Yhisto
  endif
end
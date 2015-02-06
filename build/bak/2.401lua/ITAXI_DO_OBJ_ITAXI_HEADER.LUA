function do_obj_itaxi_header ()
  local scrlines = "LARGE,iTAXI_T,40,2,C;" .."LARGE,iTAXI_T,41,3,C;".."BUTTONM_1,iTAXI_T,60,5,C;" .."BUTTONM_2,iTAXI_T,61,7,C;"
  local scrkeys  = KEY.CLR+KEY.CNCL
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "BUTTONM_1" then
    scrlines = "LARGE,iTAXI_T,42,2,C;" .."STRING,"..taxicfg.header0..",0,6,1,42;" .."BUTTONA,THIS,ALPHA ,B,C;"
    screvent,scrinput = terminal.DisplayObject(scrlines,KEY.CLR+KEY.CNCL+KEY.OK,EVT.TIMEOUT,ScrnTimeout)
    if screvent == "KEY_OK" and scrinput ~= taxicfg.header0 then
      terminal.SetJsonValue("iTAXI_CFG","HEADER0",scrinput)
	  taxicfg.header0 = scrinput
    end
  elseif screvent == "BUTTONM_2" then
    scrlines = "LARGE,iTAXI_T,43,2,C;" .."STRING,"..taxicfg.header1..",0,6,1,42;" .."BUTTONA,THIS,ALPHA ,B,C;"
    screvent,scrinput = terminal.DisplayObject(scrlines,KEY.CLR+KEY.CNCL+KEY.OK,EVT.TIMEOUT,ScrnTimeout)
    if screvent == "KEY_OK" and scrinput ~= taxicfg.header1 then
      terminal.SetJsonValue("iTAXI_CFG","HEADER1",scrinput)
	  taxicfg.header1 = scrinput
    end
  end
  return do_obj_itaxi_smenu()
end

function do_obj_itaxi_timeoffset()
  local s_tz = "0"
  local tz = terminal.GetJsonValue("iTAXI_CFG","RISTIMEOFFSET")
  if tz and tz ~= "" then s_tz = tz end
  
  local scrlines = "LARGE,THIS,TIME TO ADJUST (MINUTES),2,C;" .."STRING," .. s_tz .. ",,6,18,10,1;".."BUTTONA,THIS,ALPHA ,B,C;"
  local scrkeys  = KEY.CLR+KEY.CNCL+KEY.OK
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "KEY_OK" and s_tz ~= scrinput then
    if not tonumber(scrinput) then 
		 terminal.DisplayObject("WIDELBL,THIS,INVALID NUMBER,3,C;",scrkeys,EVT.TIMEOUT,ScrnErrTimeout)
    else terminal.SetJsonValue("iTAXI_CFG","RISTIMEOFFSET",scrinput)
		 config.timeadjust = scrinput
	end
  end
  return do_obj_itaxi_smenu()
end

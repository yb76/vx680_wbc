function do_obj_itaxi_commission ()
  local scrlines = "LARGE,iTAXI_T,9,2,C;" .."LPERCENT,"..taxicfg.comm..",0,5,20,6;"
  local scrkeys  = KEY.CLR+KEY.CNCL+KEY.OK
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "KEY_OK" and taxicfg.comm ~= tonumber(scrinput) then
    taxicfg.comm = tonumber(scrinput)
    if taxicfg.hire then taxicfg.h_comm=taxicfg.comm; terminal.SetJsonValue("iTAXI_CFG","HIRE_COMM",scrinput)
    else terminal.SetJsonValue("iTAXI_CFG","COMM",scrinput) end
  end
  return do_obj_itaxi_smenu()
end

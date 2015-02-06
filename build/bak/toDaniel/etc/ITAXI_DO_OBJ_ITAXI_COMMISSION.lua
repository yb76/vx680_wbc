function do_obj_itaxi_commission ()
  local scrlines = "LARGE,iTAXI_T,9,2,C;" .."LPERCENT,"..taxicfg.comm..",0,5,20,6;"
  local scrkeys  = KEY.CLR+KEY.CNCL+KEY.OK
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "KEY_OK" then
    taxicfg.comm = tonumber(scrinput)
    terminal.SetJsonValue("iTAXI_CFG","COMM",scrinput)
  end
  return do_obj_itaxi_smenu()
end

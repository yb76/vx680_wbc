function do_obj_itaxi_serv_gst ()
  local scrlines = "LARGE,iTAXI_T,8,2,C;" .."LPERCENT,"..taxicfg.serv_gst..",0,5,20,6;"
  local scrkeys  = KEY.CLR+KEY.CNCL+KEY.OK
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "KEY_OK" and taxicfg.serv_gst ~= tonumber(scrinput) then
    taxicfg.serv_gst = tonumber(scrinput) or 0
    if taxicfg.hire then taxicfg.h_serv_gst=taxicfg.serv_gst; terminal.SetJsonValue("iTAXI_CFG","HIRE_SERV_GST",scrinput)
    else terminal.SetJsonValue("iTAXI_CFG","SERV_GST",scrinput) end
  end
  return do_obj_itaxi_smenu()
end

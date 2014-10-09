function do_obj_itaxi_serv_gst ()
  local scrlines = "LARGE,iTAXI_T,8,2,C;" .."LPERCENT,"..taxicfg.serv_gst..",0,5,20,6;"
  local scrkeys  = KEY.CLR+KEY.CNCL+KEY.OK
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "KEY_OK" and taxicfg.serv_gst ~= tonumber(scrinput) then
    taxicfg.serv_gst = tonumber(scrinput) or 0
    terminal.SetJsonValue("iTAXI_CFG","SERV_GST",scrinput)
  end
  return do_obj_itaxi_smenu()
end

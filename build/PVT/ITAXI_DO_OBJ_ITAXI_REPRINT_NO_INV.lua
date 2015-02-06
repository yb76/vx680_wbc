function do_obj_itaxi_reprint_no_inv()
  local scrlines = ",THIS,REPRINT,-1,C;" .."WIDELBL,THIS,INVOICE DOES,3,C;" .."WIDELBL,THIS,NOT EXIST,4,C;"
  terminal.ErrorBeep()
  local screvent,scrinput = terminal.DisplayObject(scrlines,KEY.CLR+KEY.CNCL,EVT.TIMEOUT,ScrnErrTimeout)
  if screvent == "TIME" or screvent == "KEY_CLR" then
     return do_obj_itaxi_reprint_menu()
  else
    return do_obj_itaxi_finish()
  end
end

function do_obj_itaxi_reprint()
  local scrlines = ",THIS,REPRINT,-1,C;"..",iTAXI_T,120,5,C;" .."LNUMBER,,0,7,15,6;".."BUTTONL,THIS,PRINT,B,C"
  local screvent,scrinput=terminal.DisplayObject(scrlines,KEY.OK+KEY.CLR+KEY.CNCL,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "KEY_OK" or screvent == "BUTTONL" then
    if #scrinput > 0 then return do_obj_itaxi_reprint_do(tonumber(scrinput))
    else return do_obj_itaxi_reprint()
    end
  elseif screvent == "KEY_CLR" then
     return do_obj_itaxi_reprint_menu()
  else
    return do_obj_itaxi_finish()
  end
end

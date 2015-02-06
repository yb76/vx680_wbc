function do_obj_itaxi_auth_no()
  local scrlines = ",THIS,AUTHORITY NO,4,C;" .. "STRING," .. taxicfg.auth_no .. ",,6,15,10,1;".."BUTTONA,THIS,ALPHA ,B,C;"
  local screvent,scrinput = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL,EVT.TIMEOUT,ScrnTimeout)
  
  if screvent == "KEY_OK" then
    taxicfg.auth_no = scrinput
    terminal.SetJsonValue("iTAXI_CFG","AUTH_NO",taxicfg.auth_no)
    return do_obj_itaxi_abn_no()
  else
    return do_obj_itaxi_sign_on()
  end
end

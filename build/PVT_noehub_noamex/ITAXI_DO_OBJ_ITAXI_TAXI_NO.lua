function do_obj_itaxi_taxi_no()
  local scrlines = ",THIS,ENTER "..(taxicfg.hire and "HIRE CAR NO" or "TAXI NO")..",4,C;".. "STRING," .. taxicfg.taxi_no .. ",,7,14,10,1;".."BUTTONA,THIS,ALPHA ,B,C;"
  local screvent,scrinput = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL+KEY.CLR,EVT.TIMEOUT,ScrnTimeout)
  
  if screvent == "KEY_OK" then
    terminal.SetJsonValue("iTAXI_CFG","TAXI_NO",scrinput)
    taxicfg.taxi_no = scrinput
    taxicfg.signed_on = true
    return do_obj_itaxi_finish()
  elseif screvent == "KEY_CLR" then
    return do_obj_itaxi_abn_no()
  else
    return do_obj_itaxi_sign_on()
  end
end

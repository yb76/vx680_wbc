function do_obj_itaxi_smenu ()
  local scrlines = "LARGE,iTAXI_T,1,0,C;" .."BUTTONM_1,iTAXI_T,3,2,C;" .."BUTTONM_2,iTAXI_T,4,4,C;".."BUTTONM_3,iTAXI_T,5,6,C;".."BUTTONM_4,iTAXI_T,6,8,C;".."BUTTONM_5,iTAXI_T,7,10,C;".."BUTTONM_6,THIS,TIME ADJUSTMENT,12,C;"

  local scrkeys  = KEY.CLR+KEY.CNCL
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "TIME" or screvent == "CANCEL" or screvent == "KEY_CLR" then 
    return do_obj_itaxi_finish()
  elseif screvent == "BUTTONM_1" then
    return do_obj_itaxi_serv_gst()
  elseif screvent == "BUTTONM_2" then
    return do_obj_itaxi_commission()
  elseif screvent == "BUTTONM_3" then
    return do_obj_itaxi_header()
  elseif screvent == "BUTTONM_4" then
    return do_obj_itaxi_trailer12()
  elseif screvent == "BUTTONM_5" then
    return do_obj_itaxi_abn_option()
  elseif screvent == "BUTTONM_6" then
    return do_obj_itaxi_timeoffset()
  else
    return do_obj_itaxi_smenu()
  end
end

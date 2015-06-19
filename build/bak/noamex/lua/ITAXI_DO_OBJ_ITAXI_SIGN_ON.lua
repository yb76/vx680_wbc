function do_obj_itaxi_sign_on()
  local scrlines = "WIDELBL,iTAXI_T,160,3,C;" .. "WIDELBL,iTAXI_T,161,4,C;"..",THIS,PRESS GREEN KEY,7,C;"..",THIS,TO CONTINUE,8,C;"
                   .. "BUTTONL_1,THIS,SIGN-ON,B,C;" 
  terminal.DisplayObject(scrlines,KEY.OK,0,0)
  return do_obj_itaxi_auth_no()
end

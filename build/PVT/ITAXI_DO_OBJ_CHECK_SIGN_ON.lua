function do_obj_check_sign_on()
  if taxicfg.taxi_no == "" then return do_obj_itaxi_sign_on() 
  else taxicfg.signed_on = true; return do_obj_itaxi_finish() end
end

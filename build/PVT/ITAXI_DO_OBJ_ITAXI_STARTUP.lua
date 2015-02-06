function do_obj_itaxi_startup()
  if not taxicfg.signed_on then taxi.finishreturn = true; do_obj_check_sign_on(); taxi.finishreturn = false end
  if not taxicfg.registered then taxicfg.registered = true; do_obj_gprs_register() end
  return 0
end

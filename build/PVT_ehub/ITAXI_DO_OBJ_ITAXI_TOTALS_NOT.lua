function do_obj_itaxi_totals_not()
  terminal.ErrorBeep()
  local scrlines = "WIDELBL,iTAXI_T,144,2,C;" 
  terminal.DisplayObject(scrlines,KEY.CLR+KEY.CNCL,EVT.TIMEOUT,ScrnTimeout)
  taxicfg.auth_no = ""
  taxicfg.abn_no = ""
  taxicfg.taxi_no = ""
  terminal.SetJsonValue("iTAXI_CFG","AUTH_NO","")
  terminal.SetJsonValue("iTAXI_CFG","ABN_NO","")
  terminal.SetJsonValue("iTAXI_CFG","TAXI_NO","")
  return do_obj_itaxi_sign_on()
end

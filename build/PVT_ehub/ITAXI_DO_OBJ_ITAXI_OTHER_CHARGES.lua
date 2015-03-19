function do_obj_itaxi_other_charges()
  local otherchg = taxi.otherchg or 0
  local scrlines = "WIDELBL,iTAXI_T,94,2,C;" .. "AMOUNT," .. otherchg ..",5,5,C,8;"

  local scrkeys = KEY.OK+KEY.CNCL+KEY.CLR
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "KEY_OK" then
    taxi.otherchg = tonumber(scrinput)
    taxi.subtotal = taxi.meter + taxi.otherchg
    return do_obj_itaxi_pay()
  elseif screvent == "KEY_CLR" then
    taxi.otherchg = 0
    return do_obj_itaxi_meter()
  else
    return do_obj_itaxi_finish()
  end
end

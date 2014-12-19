function do_obj_itaxi_pay()
  taxi.serv_gst = 0
  if taxicfg.serv_gst > 0 then taxi.serv_gst = math.floor(taxi.subtotal / 10000 * tonumber (taxicfg.serv_gst)+0.5) end
  local line1 = "PICK UP:" .. string.format("%13s", taxi.pickup )
  local line2 = "DROP OFF:" .. string.format("%12s", taxi.dropoff )
  local line3 = "TOTAL FARE:" .. string.format("%10s", string.format( "$%.2f", taxi.subtotal/100))
  local line4,line5,line6,line7 = "103","104","105","163"
  local scrlines = ",THIS," .. line1 ..",0,5;" .. ",THIS," .. line2 ..",1,5;" .. "WIDELBL,THIS," .. line3 ..",3,5;" 
              .. ",THIS,IS THIS CORRECT?,6,C;"   .. "BUTTONS_1,iTAXI_T," .. line6 ..",B,10;"
          .. "BUTTONS_2,iTAXI_T," .. line7 ..",B,33;"
  
  local scrkeys = KEY.OK+KEY.CNCL+KEY.CLR
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  
  check_logon_ok()
  if screvent == "KEY_OK" or screvent == "BUTTONS_1" then
    local ret = do_obj_itaxi_tip()
    if ret then return ret()
    elseif taxi.cash then
      return do_obj_itaxi_cash()
    elseif taxi.ctls then
        return ctls_tran()
    elseif not taxi.chipcard and not taxi.track2 then
        return ctls_tran()
    else 
        return do_obj_itaxi_pay_swipe()
    end
  elseif screvent == "BUTTONS_2" or screvent == "KEY_CLR" then
    return do_obj_itaxi_meter()
  else
    return do_obj_itaxi_finish()
  end
end

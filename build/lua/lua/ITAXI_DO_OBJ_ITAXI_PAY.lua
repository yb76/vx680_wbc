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
    local ret = 0
	if taxi.cash then
        local scrlines1 = "WIDELBL,,37,2,C;" .."WIDELBL,,26,4,C;"
        terminal.DisplayObject(scrlines1,0,0,0)
    
          local timestr = terminal.Time( "DD/MM/YY        hh:mm:ss" )
          local otherchgstr = ""
          if taxi.otherchg > 0 then otherchgstr = "OTHR CHRGS:\\R".. string.format("$%.2f",taxi.otherchg/100) .."\\n" end
          local auth_no,abn_no,taxi_no =  taxicfg.auth_no,taxicfg.abn_no,taxicfg.taxi_no
		  local abn_str = abn_no and (taxi.subtotal > 7500 or taxi.subtotal<=7500 and not taxicfg.abn_skip) and ( "DRVR ABN:\\R" .. abn_no .."\\n" ) or ""
          local header,mtrailer,ctrailer = get_itaxi_print()

          local prtvalue= header .. "\\CCASH RECEIPT\\n" ..
            "\\4\\w------------------------------------------\\n" ..
            "\\fMERCHANT ID:\\R" .. string.sub(config.mid,-8) .. "\\n" ..
            "\\fTERMINAL ID:\\R" .. config.tid .. "\\n" ..
            "\\fDRIVER NO:\\R" .. (auth_no or "") .. "\\n" ..
            abn_str ..
            "TAXI NO:\\R" .. (taxi_no or "") .."\\n" ..
            "\\4\\W\\CTAX INVOICE\\n" ..
            "\\f\\C" .. timestr .."\\n" ..
            "\\4\\w------------------------------------------\\n" ..
            "\\fPICK UP:\\R" .. taxi.pickup .."\\n" ..
            "\\fDROP OFF:\\R" .. taxi.dropoff .. "\\n\\n" ..
            "METER FARE:\\R" .. string.format("$%.2f",taxi.meter/100) .. "\\n" ..
            otherchgstr ..
            "\\f \\R----------\\n" ..
            "\\fTOTAL:\\R" .. string.format("$%.2f", taxi.subtotal/100) .. "\\n\\n" ..
            "\\C** CASH RECEIPT **\\n\\n" .. ctrailer

          terminal.Print(prtvalue,true)
          checkPrint(prtvalue)
          return do_obj_itaxi_finish()
 --   elseif not check_logon_ok() then
 --       return do_obj_itaxi_finish()
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

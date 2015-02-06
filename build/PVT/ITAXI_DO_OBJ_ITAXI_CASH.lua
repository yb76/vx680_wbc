function do_obj_itaxi_cash()
  local scrlines1 = "WIDELBL,,37,2,C;" .."WIDELBL,,26,4,C;"
  terminal.DisplayObject(scrlines1,0,0,0)

  local timestr = terminal.Time( "DD/MM/YY        hh:mm:ss" )
  local otherchgstr= ""
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
end

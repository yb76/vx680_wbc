function do_obj_itaxi_pay_do()
  ecrd = {}
  local otherchgstr = ""
  if taxi.otherchg and taxi.otherchg > 0 then otherchgstr = "OTHR CHRGS:\\R".. string.format("$%.2f",taxi.otherchg/100) .."\\n" end
  ecrd.POO = "YES"; ecrd.TRACK = "YES"; ecrd.AMT = taxi.subtotal + taxi.serv_gst
  ecrd.KEEP = taxi.subtotal; ecrd.FUNCTION = "PRCH" ; ecrd.TIMER = ""
  ecrd.HEADER,ecrd.MTRAILER,ecrd.CTRAILER = get_itaxi_print()
  local abn_str = taxicfg.abn_no and (taxi.subtotal+taxi.serv_gst > 7500 or taxi.subtotal+taxi.serv_gst<=7500 and not taxicfg.abn_skip) and ( "DRVR ABN:\\R" .. taxicfg.abn_no .."\\n" ) or ""
  ecrd.HEADER_OK = "\\f\\W\\CTAX INVOICE\\n" .. "\\fINV#:\\R"..taxicfg.inv.."\\n" ..
    "\\fDRIVER NO:\\R" .. (taxicfg.auth_no or "") .. "\\n" ..
    abn_str ..
    "TAXI NO:\\R" .. (taxicfg.taxi_no or "") .."\\n" ..
    "\\fPICK UP:\\R" .. taxi.pickup .."\\n" ..
    "DROP OFF:\\R" .. taxi.dropoff .. "\\n" ..
    "METER FARE:\\R" .. string.format("$%.2f",taxi.meter/100) .. "\\n" ..
    otherchgstr ..
    "\\f \\R----------\\n" ..
    "\\4TOTAL FARE(INC GST):\\R" .. string.format( "$%.2f", taxi.subtotal/100)  .. "\\n" ..
    "SERVICE FEE:\\R" .. string.format( "$%.2f", taxi.serv_gst*10/100/11)  .. "\\n" ..
    "GST ON SERVICE FEE:\\R" .. string.format( "$%.2f", taxi.serv_gst/100-taxi.serv_gst*10/100/11)  .. "\\n" ..
    "\\f \\R----------\\n" ..
    "TOTAL:\\R" .. string.format( "$%.2f", (taxi.subtotal+ taxi.serv_gst )/100) .."\\n"
  ecrd.TRACK2 = taxi.track2
  ecrd.CARDNAME = taxi.track2 and taxi.cardname
  ecrd.CTLS = taxi.ctls
  ecrd.TLVs = taxi.tlvs 
  ecrd.CTEMVRS    = taxi.CTemvrs
  ecrd.CVMLIMIT = taxi.cvmlimit
  ecrd.CHIPCARD = taxi.chipcard
  ecrd.ENTRY = taxi.entry
  ecrd.RETURN = do_obj_itaxi_finish
  return do_obj_iecr_start()
end

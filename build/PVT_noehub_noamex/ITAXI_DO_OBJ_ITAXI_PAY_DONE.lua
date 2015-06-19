function do_obj_itaxi_pay_done(rtnvalue)
  local taxi_min,taxi_next= terminal.GetArrayRange("TAXI")
  local inv = tonumber( taxicfg.inv )
  if taxi_next >0 and taxi_next - taxi_min > taxicfg.max_kept_inv then
    terminal.FileRemove("TAXI" .. taxi_min)
    taxi_min = taxi_min + 1
  end

  local taxi_nextfile = "TAXI"..taxi_next
  taxi.current_taxi_idx = taxi_next
  local tipstr = taxi.tip and taxi.tip > 0 and (",TIP:"..taxi.tip) or ""
  local taxistr = "{TYPE:DATA,NAME:"..taxi_nextfile..",GROUP:WBC,VERSION:3.0,INV:"..inv..",STAN:"..ecrd.INV..",TXNTOTAL:"..ecrd.AMT..",SUBTOTAL:"..ecrd.KEEP..",HEADER:".. ecrd.HEADER..",HEADER_OK:"..ecrd.HEADER_OK..",MRECEIPT:"..ecrd.MRECEIPT..",TRAILER:"..ecrd.MTRAILER..",CRCPT:"..ecrd.CRECEIPT..tipstr.."}"
  
  terminal.NewObject(taxi_nextfile,taxistr)
  terminal.SetArrayRange("TAXI",taxi_min,taxi_next+1)
  local taxitxn_min,taxitxn_next= terminal.GetArrayRange("iTAXI_TXN")
  local taxitxn_nextfile = "iTAXI_TXN"..taxitxn_next
  local account = ( ecrd.ACCOUNT == "4" and "CR" or ( ecrd.ACCOUNT=="1" and "SAV" or "CHQ"))
  local dt = string.sub(ecrd.DATE,3,4)..string.sub(ecrd.DATE,1,2) --ddmm
  local taxitxnstr = "{TYPE:DATA,NAME:iTAXI_TXN"..taxitxn_next..",GROUP:WBC,VERSION:3.0,DATE:"..dt..",TIME:"..ecrd.TIME..",TID:"..ecrd.TID..",DRIVER:"..taxicfg.auth_no..",ABN:"..taxicfg.abn_no..",TAXI:"..taxicfg.taxi_no..",STAN:"..ecrd.INV..",INV:"..inv..",METER:"..taxi.meter..",FARE:"..ecrd.KEEP..",TOTAL:"..ecrd.AMT..",COMM:"..taxicfg.comm..",PICK_UP:"..taxi.pickup..",DROP_OFF:"..taxi.dropoff..",PAN:TODO,CARDNO:"..ecrd.CARDNO..",ACCOUNT:"..account..",RC:"..ecrd.RC..",AUTHID:"..ecrd.AUTHID..tipstr.."}"
  terminal.NewObject(taxitxn_nextfile,taxitxnstr)
  terminal.SetArrayRange("iTAXI_TXN","",taxitxn_next+1)
  taxi.current_taxitxn_idx = taxitxn_next

  taxicfg.daily = taxicfg.daily + ecrd.AMT
  taxicfg.monthly = taxicfg.monthly + ecrd.AMT
  inv = inv + 1
  taxicfg.inv = string.format("%06d", inv )
  terminal.SetJsonValue("iTAXI_CFG","INV", taxicfg.inv)
  terminal.SetJsonValue("iTAXI_CFG","DAILY",taxicfg.daily)
  terminal.SetJsonValue("iTAXI_CFG","MONTHLY",taxicfg.monthly)
  if rtnvalue then return rtnvalue
  else return do_obj_itaxi_finish() end
end

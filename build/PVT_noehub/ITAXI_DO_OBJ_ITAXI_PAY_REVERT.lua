function do_obj_itaxi_pay_revert(rtnvalue)
  terminal.FileRemove("TAXI"..tostring(taxi.current_taxi_idx))
  terminal.SetArrayRange("TAXI","",taxi.current_taxi_idx)
  terminal.FileRemove("iTAXI_TXN"..tostring(taxi.current_taxitxn_idx))
  terminal.SetArrayRange("iTAXI_TXN","",taxi.current_taxitxn_idx)
  taxicfg.inv = string.format("%06d", tonumber(taxicfg.inv)-1 )
  terminal.SetJsonValue("iTAXI_CFG","INV", taxicfg.inv)
  if rtnvalue then return rtnvalue
  else return do_obj_itaxi_finish() end
end

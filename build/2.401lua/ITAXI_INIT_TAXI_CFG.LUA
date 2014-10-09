function init_taxi_cfg()
  taxicfg.header0,taxicfg.header1,taxicfg.trailer0,taxicfg.trailer1,taxicfg.trailer2,taxicfg.trailer3,taxicfg.abn_no,taxicfg.abn,taxicfg.taxi_no,taxicfg.auth_no,taxicfg.inv,taxicfg.last_inv,taxicfg.batch= 
  terminal.GetJsonValue("iTAXI_CFG","HEADER0","HEADER1","TRAILER0","TRAILER1","TRAILER2","TRAILER3","ABN_NO","ABN","TAXI_NO","AUTH_NO","INV","LAST_INV","BATCH")
  taxicfg.comm,taxicfg.serv_gst,taxicfg.day,taxicfg.month,taxicfg.daily,taxicfg.monthly,taxicfg.day_limit,taxicfg.month_limit,taxicfg.ctls_slimit =terminal.GetJsonValueInt("iTAXI_CFG","COMM","SERV_GST","DAY","MONTH","DAILY","MONTHLY","DAY_LIMIT","MONTH_LIMIT","CTLS_S_LIMIT")
  taxicfg.header = "\\ggmcabs.bmp" .."\\f\\C" .. taxicfg.header0 .. "\\n" .."\\C" .. taxicfg.header1 .. "\\n"
  local cfgtrailer2 = ( taxicfg.trailer2 == "" and "" or ("\\4\\H\\C" .. taxicfg.trailer2 .. "\\n"))
  local cfgtrailer3 = ( taxicfg.trailer3 == "" and "" or ("\\4\\H\\C" .. taxicfg.trailer3 .. "\\n"))
  taxicfg.mtrailer = ""
  taxicfg.ctrailer = "\\4\\H\\C" .. taxicfg.trailer0 .. "\\n".. "\\4\\H\\C" .. taxicfg.trailer1 .. "\\n" .. cfgtrailer2
  taxicfg.max_kept_inv,taxicfg.max_kept_batch,taxicfg.max_txn= terminal.GetJsonValueInt("ITAXI_OPTIONS","MAX_KEPT_INV","MAX_KEPT_BATCH","MAX_TXN")
  taxicfg.loc0,taxicfg.loc1,taxicfg.loc2,taxicfg.loc3,taxicfg.loc4,taxicfg.loc5,taxicfg.abn_skip = terminal.GetJsonValue("ITAXI_OPTIONS","LOC0","LOC1","LOC2","LOC3","LOC4","LOC5","ABN_SKIP")
  if taxicfg.abn_skip~="NO" then taxicfg.abn_skip=true else taxicfg.abn_skip=nil end
  
end

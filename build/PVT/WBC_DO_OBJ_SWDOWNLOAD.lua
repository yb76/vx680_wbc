function do_obj_swdownload()
  local scrlines = "WIDELBL,,84,2,C;" .. "WIDELBL,,26,3,C;"
  terminal.DisplayObject(scrlines,0,0,0)
  terminal.UploadObj("iPAY_CFG")
  local ok = terminal.Remote()
  if not ok then terminal.ErrorBeep() end 
  scrlines = "WIDELBL,,84,2,C;" .. "WIDELBL,THIS,"..(ok and "SUCCESS" or "FAILED!")..",3,C;"
  terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL,EVT.TIMEOUT,500)
  return do_obj_gprs_register(do_obj_txn_finish)
end

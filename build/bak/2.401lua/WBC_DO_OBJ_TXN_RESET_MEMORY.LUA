function do_obj_txn_reset_memory()
  local scrlines = "WIDELBL,THIS,RESET MEMORY?,2,C;".."WIDELBL,,73,3,C;"
  local screvent,_=terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,30000)
  if screvent == "KEY_OK" then 
	local scrlines = "WIDELBL,,27,2,C;" .."WIDELBL,,26,3,C;"
	terminal.DisplayObject(scrlines,0,0,0)
	terminal.SetJsonValue("CONFIG","BATCHNO", "000000")
	config.logonstatus = "194"
	terminal.SetJsonValue("CONFIG","LOGON_STATUS",config.logonstatus)
	config.stan = "000000"
	terminal.SetJsonValue("CONFIG","STAN",config.stan)
	config.settledate = ""
	terminal.SetJsonValue("CONFIG","SETTLEDATE","")
	config.roc = "000000"
	terminal.SetJsonValue("CONFIG","ROC",config.roc)
	config.tid = ""
	terminal.SetJsonValue("CONFIG","TID","")
	config.mid = ""
	terminal.SetJsonValue("CONFIG","MID","")
	terminal.SetJsonValue("iPAY_CFG","TID","")
	terminal.SetJsonValue("iPAY_CFG","MID","")
	terminal.SetJsonValue("DUPLICATE","RECEIPT","")
	local fmin,fmax = terminal.GetArrayRange("AUTHTXN")
	for i=fmin,fmax-1 do terminal.FileRemove("AUTHTXN"..i) end
	terminal.SetArrayRange("AUTHTXN","0","0")
	fmin,fmax = terminal.GetArrayRange("SAF")
	for i=fmin,fmax-1 do terminal.FileRemove("SAF"..i) end
	terminal.SetArrayRange("SAF","0","0")
	fmin,fmax = terminal.GetArrayRange("REVERSAL")
	for i=fmin,fmax-1 do terminal.FileRemove("REVERSAL"..i) end
	terminal.SetArrayRange("REVERSAL","0","0")
	
	terminal.FileRemove("SHFTSTTL")
	scrlines = "WIDELBL,THIS,RESET MEMORY,2,C;".."WIDELBL,THIS,SUCCESS,3,C;"
	terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,3000)
	config.logok = false
  end
  return do_obj_txn_finish()
end

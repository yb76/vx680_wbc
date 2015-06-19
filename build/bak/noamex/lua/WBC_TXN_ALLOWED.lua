function txn_allowed(txnfunc)
  if config.txn_check_inited == nil then
	local prch,moto,ecom = terminal.GetJsonValue("CONFIG","PRCH","MOTO","ECOM")
    if prch == "NO" then config.txn_prch_disabled = true end
	if moto == "NO" then config.txn_moto_disabled = true end
	if ecom == "NO" then config.txn_ecom_disabled = true end
	config.txn_check_inited = true
  end
  
  if check_rev_ok()==false then
	local scrlines = "WIDELBL,THIS,REVERSAL,2,C;".."WIDELBL,THIS,PENDING,3,C;"
	terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,3000)  
	return false 
  end
  local bret = true
  if txnfunc == "PRCH" then bret = not config.txn_prch_disabled 
  elseif  txnfunc == "MOTO" then bret = not config.txn_moto_disabled 
  elseif  txnfunc == "ECOM" then bret = not config.txn_ecom_disabled 
  else 
    local txncfg = terminal.GetJsonValue("CONFIG",txnfunc)
	if txncfg == "NO" then bret = false else bret = true end
  end
  if not bret then
	local scrlines = "WIDELBL,THIS,TRANSACTION,2,C;".."WIDELBL,THIS,NOT ALLOWED,3,C;"
	terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL,EVT.TIMEOUT,3000)
	terminal.ErrorBeep()
  end
  return bret
end

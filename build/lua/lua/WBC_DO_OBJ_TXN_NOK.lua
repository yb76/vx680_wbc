function do_obj_txn_nok(tcperrmsg)
  local nextstep = nil
  local printerr = true
  if true or txn.rc == "Z1" or txn.rc == "Z3" or txn.rc == "Z4" then --TESTING
	txn.emvprint = get_emv_print_tags()
  end
  local errcode,errmsg,errline2= "","",""
  local evt,to = EVT.TIMEOUT,500
  if txn.localerror then errcode,errmsg = localerrorcode(tcperrmsg),tcperrmsg 
  else errcode,errmsg = txn.rc,txn.rc_desc or ""
    local rc = txn.rc
	if string.sub(txn.rc,1,1)~="Z" then rc = "H"..rc end
    if not errmsg or errmsg == "" then errmsg = wbc_errorcode(rc) end
	if rc == "H91" and txn.emv and txn.chipcard and not txn.emv.fallback and not txn.ctls and not txn.earlyemv then
		nextstep = do_obj_offline_check
		printerr = false; to = 1000
		errline2 = "WIDELBL,THIS,CHECKING CARD,4,C;"
	elseif rc == "H55" and not txn.re_pin then
		to = 1000
		txn.re_pin = 1
		nextstep =  --[[txn.apps and txn.apps > 0 and do_obj_wbc_swipe_insert or]] do_obj_pin
	elseif txn.ctls and rc == "H65" then 
		errline2 = "WIDELBL,THIS,PLEASE INSERT CARD,4,C;"
		evt = EVT.SCT_IN+EVT.TIMEOUT
		to = 15000
	end
  end
  if tcperrmsg and ( tcperrmsg == "NO_RESPONSE" or tcperrmsg == "TIMEOUT") then
	copy_txn_to_reversal()
  end
  
  local scrlines = "WIDELBL,,120,2,C;"
  scrlines = scrlines.. "WIDELBL,THIS," .. (errmsg or "") ..",3,C;"..errline2
  terminal.ErrorBeep()
  local screvent = terminal.DisplayObject(scrlines,KEY.CLR+KEY.CNCL+KEY.OK,evt,to)
  if txn.rc == "55" and nextstep then
    if printerr then do_obj_txn_nok_print(errcode,errmsg,1) end
    if not txn.ctls and txn.chipcard and not txn.emv.fallback and not txn.earlyemv then 
    	terminal.EmvResetGlobal()
	    emv_init()
  		get_cardinfo()
	end
    return nextstep()
  elseif nextstep then
    if printerr then do_obj_txn_nok_print(errcode,errmsg,1) end
    return nextstep()
  elseif screvent == "CHIP_CARD_IN" then
    return do_obj_idle()
  elseif txn.rc and txn.rc == "98" or tcperrmsg == "MAC" then config.logonstatus = "194"; config.logok = false
	do_obj_txn_nok_print(errcode,errmsg,1)  
	check_logon_ok() 
	return do_obj_txn_finish()
  else return do_obj_txn_nok_print(errcode,errmsg)
  end
end

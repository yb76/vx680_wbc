----------------------------iPAY---------------------------------------
function do_obj_wbc_mcr_chip()
  check_logon_ok()
  local nextstep = do_obj_wbc_swipe_insert
  txn.func = "PRCH"
  if not txn_allowed(txn.func) then nextstep = do_obj_txn_finish end
  return nextstep()
end

function do_obj_wbc_swipe_insert()
  txn.emv = {}
  local ok = 0
  if txn.ctls == "CTLS_E" then
    txn.chipcard = true
    txn.cvmlimit = ecrd.CVMLIMIT
    local aid = get_value_from_tlvs("9F06")
    if string.sub(aid,1,10) == "A000000384" and config.ehub == "YES" then
	 txn.eftpos = true
    end
  elseif txn.chipcard then 
    ok = emv_init()
  end
  if ok ~= 0 then return do_obj_emv_error(ok)  else	return do_obj_prchamount()  end
end

function emv_init()
  local ok = 0
  if txn.chipcard then
    ok = terminal.EmvTransInit()
	local amt,acctype,eftpos_mcard = ecrd.AMT,0,0
	txn.apps = 0
    if ok == 0 then ok,txn.apps,eftpos_mcard = terminal.EmvSelectApplication(amt,acctype) end
	if ok == 0 then
		local tag_aid = string.upper(terminal.EmvGetTagData(0x4F00))
		local eftpos = (tag_aid and string.sub(tag_aid,1,10) == "A000000384") 
		if eftpos and config.ehub == "YES" then txn.eftpos = true end
		if eftpos_mcard == 1 then txn.eftpos_mcard = 1 end
	end
    if ok ~= 0 and config.fallback and ok ~= 103 --[[CARD_REMOVED]] and ok ~= 104 --[[CARD_BLOCKED]] and ok ~= 105 --[[APPL_BLOCKED]] and ok ~= 110 --[[TRANS_CANCELLED]] and ok ~= 130 --[[INVALID_PARAMETER]] then
      txn.emv.fallback = true
    end
  end
  return ok
end

function check_logon_ok()
	if config.logok == true then return true
	else 
		if config.tid == "" or config.mid == "" then
			local scrlines = "WIDELBL,,51,2,C;" .. "WIDELBL,,53,4,C;"
			local screvent,scrinput = terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,0,0)
			return false
		end
		
		local scrlines = "WIDELBL,THIS,LOGON,2,C;" .. "WIDELBL,THIS,PLEASE WAIT,3,C;"
		terminal.DisplayObject(scrlines,0,0,0)
		local txnbak = txn
		txn = {}
		txn.func = "LGON"
		txn.finishreturn = true
		do_obj_logon_start()
		txn = txnbak
		txn.finishreturn = false
	  return config.logok
	end
end

function check_rev_ok()
	return ( not config.safsign or config.safsign and do_obj_saf_rev_send("REVERSAL") )
end

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

function do_obj_prchamount()
  txn.prchamt = ecrd.AMT
  txn.cashamt = 0
  txn.totalamt = txn.prchamt
  return do_obj_swipecard()
end

function do_obj_swipecard()
  local scrlines = "WIDELBL,THIS,SWIPE/INSERT,2,C;".."WIDELBL,THIS,CARD,3,C;"
  local scrkeys  = KEY.FUNC+KEY.CNCL
  local screvents = EVT.TIMEOUT+EVT.MCR+EVT.SCT_IN
  local scrtimeout = 30000
  local cardexpired = false
  local cardreject = false
  if not config.manualentry then scrkeys = KEY.CNCL end -- no manual input
  if txn.emv_retry then scrlines = "WIDELBL,THIS,INSERT CARD,2,C;"; screvents = EVT.TIMEOUT+EVT.SCT_IN end
  
  if txn.chipcard and txn.emv.fallback then
    scrlines = "WIDELBL,THIS,SWIPE CARD,2,C;"
    scrkeys  = KEY.CNCL
    screvents = EVT.TIMEOUT+EVT.MCR
  elseif txn.swipefirst == 1 and not txn.ctls and not txn.cardname  then
    local swipeflag,cardname = swipecheck( txn.track2)
	if swipeflag < 0 then cardreject = true
	elseif swipeflag == 0 then
      scrlines = "WIDELBL,THIS,INSERT CARD,2,C;"
      screvents = EVT.TIMEOUT+EVT.SCT_IN
      txn.swipefirst = nil
      txn.track2 = nil	
	elseif swipeflag > 0 then
		txn.cardname = cardname
	end
  end
  
  if txn.CTEMVRS and txn.CTEMVRS == "10" then return do_obj_transdial() --offline declined
  elseif txn.CTEMVRS and txn.CTEMVRS == "W30" then return do_obj_transdial() --offline declined
  elseif cardreject then return do_obj_txn_finish()
  elseif txn.moto then return do_obj_cardentry()
  elseif txn.swipefirst == 1 then return do_obj_account()
  elseif txn.chipcard and not txn.emv.fallback and not txn.emv_retry then return do_obj_account()
  else
    txn.track2 = nil
    local screvent,_ = terminal.DisplayObject(scrlines,scrkeys,screvents,scrtimeout)
    if screvent == "MCR" then
      txn.track2 = terminal.GetTrack(2)
      if txn.track2 == nil or #txn.track2 < 11 then return do_obj_swipecard()
      elseif not txn.emv.fallback then txn.swipefirst = 1;return do_obj_swipecard() -- double check the chipflag
      elseif txn.totalamt then return do_obj_account() 
	  else txn.swipefirst = 1; return do_obj_prchamount() end
    elseif screvent == "KEY_FUNC" then
	  local pwd_ok = true
      if ecrd.AMT and do_obj_iecr_chk_manual_password then pwd_ok = do_obj_iecr_chk_manual_password() end
	  if pwd_ok then return do_obj_cardentry() else return do_obj_swipecard() end
    elseif screvent == "TIME" then
      return do_obj_trantimeout()
    elseif screvent == "CANCEL" then
      return do_obj_txn_finish()
    elseif screvent == "CHIP_CARD_IN" then
      txn.chipcard = true
      local ok = emv_init()
      if ok ~= 0 then return do_obj_emv_error(ok)
      else txn.emv_retry = true
		if txn.totalamt then return do_obj_account() else return do_obj_prchamount() end
	  end
    end
  end
end

function do_obj_cardentry()
  local scrlines = "WIDELBL,,110,2,C;" .. "LNUMBER,,0,5,10,19,13;"
  local scrkeys  = KEY.OK+KEY.CLR+KEY.CNCL
  local screvents = EVT.TIMEOUT
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,screvents,30000)

  txn.moto = false
  if screvent == "KEY_CLR" then
    return do_obj_swipecard()
  elseif screvent == "KEY_OK" then
    txn.moto = true
    txn.pan = scrinput
    txn.account = "CREDIT"
    if terminal.Luhn(txn.pan) == false then return do_obj_luhnerror()
    else return do_obj_card_expiry() end
  elseif screvent == "CANCEL" then
    return do_obj_txn_finish()
  elseif screvent == "TIME" then
    return do_obj_swipecard()
  end
end

function do_obj_luhnerror()
  local scrlines = "WIDELBL,,120,3,C;" .. "WIDELBL,,123,5,C;"
  local scrkeys  = KEY.CLR+KEY.CNCL
  terminal.ErrorBeep()
  local screvent,_ = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,30000)
  if screvent == "KEY_CLR" then return do_obj_swipecard()
  else return do_obj_txn_finish() end
end

function do_obj_card_expiry()
  local scrlines = "WIDELBL,,111,2,C;" .. "LNUMBER,,0,5,18,4,4;"
  local scrkeys  = KEY.OK+KEY.CLR+KEY.CNCL
  local screvents = EVT.TIMEOUT
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,screvents,30000)

  if screvent == "KEY_CLR" then
    return do_obj_cardentry()
  elseif screvent == "KEY_OK" then
    local mm = tonumber(string.sub(scrinput,1,2))
    if mm > 12 or mm < 1 then return do_obj_invmonth()
    else txn.expiry = scrinput
         return do_obj_ccv()
    end
  else return do_obj_txn_finish()
  end
end

function do_obj_invmonth()
  terminal.ErrorBeep()
  local scrlines = "WIDELBL,,299,3,C;" .. "WIDELBL,,201,5,C;"
  local screvent = terminal.DisplayObject(scrlines,KEY.CLR+KEY.CNCL,EVT.TIMEOUT,3000)
  if screvent == "KEY_CLR" then
    return do_obj_card_expiry()
  else
    return do_obj_txn_finish()
  end
end

function do_obj_ccv()
  local scrlines = "WIDELBL,,112,2,C;" .. "LNUMBER,,0,5,17,5,1;"
  local scrkeys  = KEY.OK+KEY.CLR+KEY.CNCL
  local screvents = EVT.TIMEOUT
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,screvents,30000)

  if screvent == "KEY_CLR" then
    return do_obj_card_expiry()
  elseif screvent == "KEY_OK" then
    if #scrinput > 0 then txn.ccv = "CCV" .. scrinput .. "\\" end
    return do_obj_account()
  else
    return do_obj_txn_finish()
  end
end

function get_cardinfo()
  terminal.DisplayObject("WIDELBL,THIS,READING DATA,2,C;".."WIDELBL,,26,4,C;",0,0,ScrnTimeoutZO)

  if txn.ctls == "CTLS_E" then
		local EMVPAN = get_value_from_tlvs("5A00")
		local EMVPANSeq = get_value_from_tlvs("5F34")
		local EMVTRACK2 = get_value_from_tlvs("5700")
		local EMVCVMR = get_value_from_tlvs("9F34")
		local EMV9F6C = get_value_from_tlvs("9F6C")
		local EMV9F66 = get_value_from_tlvs("9F66")

		txn.ctlsPin = nil

		if not txn.ctlsPin and #EMV9F66 > 0  then --VISA
			local tag9f66_2 = tonumber(string.sub( EMV9F66,3,4),16)
			local tag9f6c_1 = #EMV9F6C>0 and tonumber(string.sub( EMV9F6C,1,2),16) or 0
			local tag9f6c_2 = #EMV9F6C>0 and tonumber(string.sub( EMV9F6C,3,4),16) or 0
			local pinflag = hasbit(tag9f6c_1,bit(8)) 
			local signflag = hasbit(tag9f6c_1,bit(7))
			if pinflag or signflag then
				if pinflag and config.no_pin then
					txn.rc = "W31"
					txn.localerror = true
					return false,"CVM FAILED"
				end
				txn.ctlsPin = pinflag and "2" or signflag and "1" or "4"
			else txn.ctlsPin = "4"
			end
		elseif string.sub(EMVCVMR,2,2) == "2" then txn.ctlsPin = "2" --Enciphered PIN verified online
		elseif string.sub(EMVCVMR,2,2) == "E" then txn.ctlsPin = "1" --Signature (paper).
		elseif string.sub(EMVCVMR,2,2) == "F" then txn.ctlsPin = "4" --No CVM required.
		end

		if not txn.ctlsPin then txn.ctlsPin = "4" end
		if EMVPAN ~= "" then txn.emv.pan = EMVPAN end
		if EMVPANSeq~= "" then txn.emv.panseqnum = EMVPANSeq  end
		if EMVTRACK2~= "" then txn.emv.track2 = EMVTRACK2 end
		if txn.emv.track2 and #txn.emv.track2 > 37 then txn.emv.track2 = string.sub( txn.emv.track2,1,37) end	
	elseif txn.ctls == "CTLS_S" then
		local EMVCVMR = get_value_from_tlvs("9F34")
		if string.sub(EMVCVMR,2,2) == "2" then txn.ctlsPin = "2" --Enciphered PIN verified online
		elseif string.sub(EMVCVMR,2,2) == "E" then txn.ctlsPin = "1" --Signature (paper).
		elseif string.sub(EMVCVMR,2,2) == "F" then txn.ctlsPin = "4" --No CVM required.
		end
  elseif txn.chipcard and not txn.emv.fallback then
    if terminal.EmvReadAppData() == 0 then
       txn.emv.pan,txn.emv.panseqnum,txn.emv.track2 = terminal.EmvGetTagData(0x5A00,0x5F34,0x5700)
       if txn.emv.track2 and #txn.emv.track2 > 37 then txn.emv.track2 = string.sub( txn.emv.track2,1,37) end
    end
  end
  local pan = txn.pan or txn.track2 or (txn.emv and txn.emv.pan) 
  if pan and #pan > 10 then 
      if txn.track2 then _,_,pan = string.find(txn.track2, "(%d*)=") end
	  local cardname_prefix,_,_ = terminal.LocateCpat("CPAT_ALL",string.sub(pan,1,6))
      if #cardname_prefix > 2 then cardname_prefix = string.sub(cardname_prefix,-2) end
	  local cardname = terminal.TextTable("CARD_NAME",cardname_prefix)
	  txn.cardname = cardname
	  txn.fullpan = string.match( pan,"%d+")
	end 
  return 0
end

function do_obj_account()
  --if txn.emverr and txn.emverr == 146 then txn.chipcard = nil ; txn.emv.fallback = false; txn.emv = {} end
  local acc4 = "CHQ"
  local acc5 = "SAV"
  local acc6 = "CR"
  local scrlines_nocr = "WIDELBL,,115,2,C;".. "BUTTONS_1,THIS,".. acc4 .. ",B,4;".. "BUTTONS_2,THIS,".. acc5 .. ",B,21;"
  local scrlines = scrlines_nocr .. "BUTTONS_3,THIS,".. acc6 .. ",B,38;"
  local scrkeys  = KEY.CNCL
  local screvents = EVT.TIMEOUT+EVT.SCT_OUT
  txn.account = ""
  local ok,desc = get_cardinfo()
  local acct = ""
  if ok and txn.chipcard and not txn.fallback and not txn.earlyemv then
	if txn.ctls == "CTLS_E" then
	  local f9f06 = get_value_from_tlvs("9F06")
	  local cfgfile = terminal.EmvFindCfgFile(f9f06)
	  if cfgfile ~="" then acct = terminal.GetJsonValue(cfgfile,"CTLS_ACCT") end
	else acct = terminal.EmvGlobal("GET","ACCT")
		if ( not acct or acct == "" ) and txn.eftpos_mcard  then acct = "CREDIT" end
	end
  end
  txn.account = (acct or "")
  
  if not ok then
	return do_obj_txn_nok(desc)
  elseif txn.ctls and txn.CTEMVRS == "W30" then
	return do_obj_transdial()  
  elseif txn.account ~="" then
		scrlines = "WIDELBL,THIS,"..txn.account.." ACCOUNT,2,C;".."WIDELBL,,26,4,C;"
		terminal.DisplayObject(scrlines,0,EVT.TIMEOUT,ScrnTimeoutHF)
		return do_obj_pin()
  elseif txn.ctls or txn.cardname == "AMEX" or txn.cardname == "DINERS" or txn.cardname =="JCB" or txn.moto or txn.pan then
	txn.account = "CREDIT" 
	scrlines = "WIDELBL,,119,2,C;".."WIDELBL,,26,3,C;"
	terminal.DisplayObject(scrlines,0,EVT.TIMEOUT,ScrnTimeoutHF)
    return do_obj_pin()
  else
      if txn.cardname and string.sub(txn.cardname,1,5) == "DEBIT" then scrlines = scrlines_nocr end
	  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnTimeout)
	  if screvent == "TIME" then
		return do_obj_trantimeout()
	  elseif screvent == "BUTTONS_1" then
		txn.account = "CHEQUE"
		scrlines = "WIDELBL,,117,2,C;".."WIDELBL,,26,4,C;"
		terminal.DisplayObject(scrlines,0,0,0)
		return do_obj_pin()
	  elseif screvent == "BUTTONS_2" then
		txn.account = "SAVINGS"
		scrlines = "WIDELBL,,118,2,C;".."WIDELBL,,26,4,C;"
		terminal.DisplayObject(scrlines,0,0,0)
		return do_obj_pin()
	  elseif screvent == "BUTTONS_3" then
		txn.account = "CREDIT"
		scrlines = "WIDELBL,,119,2,C;".."WIDELBL,,26,4,C;"
		terminal.DisplayObject(scrlines,0,0,0)
		return do_obj_pin()
	  elseif screvent == "CHIP_CARD_OUT" then
		return do_obj_emv_error(101)
	  else
		return do_obj_txn_finish()
	  end
	end
end

function do_obj_pin()
  if txn.chipcard and not txn.ctls and (( txn.account == "SAVINGS" or txn.account == "CHEQUE" ) and not txn.eftpos ) then txn.earlyemv = true end

  if txn.pan then return do_obj_transdial()
  elseif txn.ctls and txn.chipcard and config.ctls_cvm and not hasbit( tonumber(config.ctls_cvm,16),bit(7))  then do_obj_transdial()
  elseif txn.ctls and txn.ctlsPin and txn.ctlsPin ~= "2" and txn.ctlsPin ~= "3" then 
  	return do_obj_transdial()
  elseif txn.chipcard and not txn.earlyemv and not txn.emv.fallback and not txn.ctls 
	then txn.pinblock_flag = "TODO";return do_obj_transdial()
  else
    local amtstr = string.format( "$%.2f", txn.totalamt/100.0 )
	amtstr = string.format( "%9s",amtstr)
    local scrlines = "WIDELBL,THIS,TOTAL:          " .. amtstr ..",2,3;"
	local pinbypass = false
	if txn.ctls and ( not txn.chipcard and txn.cardname ~="MASTERCARD" or txn.ctlsPin == "3") then pinbypass = true 
	elseif not txn.ctls and txn.account == "CREDIT" then pinbypass = true end
	scrlines = scrlines .. ( pinbypass and "PIN,,,P5,P11,0;" or scrlines .. "PIN,,,P5,P11,1;" ) 

    local scrkeys  = KEY.CNCL+KEY.NO_PIN+KEY.OK
    local screvents = EVT.TIMEOUT+EVT.SCT_OUT
    local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnTimeout)
    if screvent == "KEY_OK" then
      txn.pinblock_flag = "TODO"
	  if txn.ctlsPin == "3" then txn.ctlsPin = "2" end
      return do_obj_transdial()
    elseif screvent =="KEY_NO_PIN" then
      txn.pinblock_flag = "NOPIN"
      return do_obj_transdial()
    elseif screvent == "TIME" then
      return do_obj_trantimeout()
	elseif screvent == "CHIP_CARD_OUT" then
		return do_obj_emv_error(101)
    else
      return do_obj_txn_finish()
    end
  end
end

function do_obj_trantimeout()
  local scrlines = "WIDELBL,,120,2,C;" .. "WIDELBL,,122,3,C;"
  local scrkeys  = KEY.OK+KEY.CLR+KEY.CNCL
  terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT+EVT.SCT_OUT,30000)
  return do_obj_txn_finish()
end

function do_obj_offline_check(revrequired)
	local FAILED_TO_CONNECT = 3
	local ret = config.no_offline and -1 or terminal.EmvUseHostData(FAILED_TO_CONNECT,"")
	if ret == 0 then 
		txn.rc = "Y3"
		--prepare 0220
		if txn.func ~= "AUTH" then
			local safmin,safnext = terminal.GetArrayRange("SAF")
			local saffile = "SAF"..safnext
			terminal.FileCopy("TXN_REQ", saffile)
			terminal.SetJsonValue(saffile,"0","220")
			local mmddhhmmss = terminal.Time( "MMDDhhmmss")
			if txn.emv and txn.emv.tlv then
				local newtlv = txn.emv.tlv .. terminal.EmvPackTLV("8A00")
				terminal.SetJsonValue(saffile,"55",newtlv)
			end
			terminal.SetJsonValue(saffile,"12",string.sub(mmddhhmmss,5,10))
			terminal.SetJsonValue(saffile,"13",string.sub(mmddhhmmss,1,4))
			terminal.SetJsonValue(saffile,"11","000000")
			terminal.SetJsonValue(saffile,"37",string.format("%12s","000000"))
			terminal.SetJsonValue("TXN_REQ","11","000000")
			terminal.SetJsonValue("TXN_REQ","37",string.format("%12s","000000"))
			if revrequired then
				get_next_id("ROC") 
				terminal.SetJsonValue(saffile,"62",terminal.HexToString(config.roc))
				terminal.SetJsonValue("TXN_REQ","62",terminal.HexToString(config.roc))
			end
			
			terminal.SetArrayRange("SAF","",tostring(safnext+1))
			txn.saf_generated = true
		end
		return do_obj_txn_ok()
	else
		txn.rc = "Z3"
		return do_obj_txn_nok(txn.rc)
	end
end

function do_obj_transdial()
  local emvok,emvret = true,0
  local tcpreturn = ""
  local nextstep = nil
  if not txn.ctls and txn.chipcard and not txn.emv.fallback then
    if not txn.earlyemv then
	  if terminal.EmvIsCardPresent() then
		local acc = (txn.account=="SAVINGS" and 0x10 or txn.account == "CHEQUE" and 0x20 or txn.account=="CREDIT" and 0x30)
		if emvret == 0 then emvret = terminal.EmvSetAccount(acc) end
		if emvret == 0 then emvret = terminal.EmvDataAuth() end
		if emvret == 0 then emvret = terminal.EmvProcRestrict() end
		if emvret == 0 then emvret = terminal.EmvCardholderVerify() end
 		if emvret == 0 then emvret = terminal.EmvProcess1stAC() end
 		if emvret == 137 then --ONLINE_REQUEST
		elseif emvret == 150 or emvret == 133  then -- TRANS_APPROVED or OFFLINE_APPROVED
		elseif emvret == 151 or emvret == 134  then -- TRANS_DECLINED or OFFLINE_DECLINED
		else emvok = false
		end
	  else emvret = 101
	  end
    end
  end
  if emvok then get_next_id("ROC") end

  if txn.ctls == "CTLS_E" then
		if txn.CTEMVRS then
			if txn.CTEMVRS == "35" then -- Online 
				local scrlines = "WIDELBL,,21,4,C;"
				  terminal.DisplayObject(scrlines,0,0,ScrnTimeoutZO)
				  tcpreturn = tcpconnect()
				  if tcpreturn == "NOERROR" then 
					return do_obj_transstart()
				  else 
						txn.rc = "W21"
						return do_obj_txn_nok("CONNECT")
				  end
			elseif txn.CTEMVRS == "W30" then --or txn.CTEMVRS == " 0" and toomany_saf() then -- Ofline Auth
				txn.rc = "W30"
				txn.localerror = true
				return do_obj_txn_nok("SAF LIMIT EXCEEDED")
			elseif txn.CTEMVRS == " 0" then -- Ofline Auth
				txn.rc = "Y1"
				local as2805msg = prepare_txn_req()
				if txn.func ~= "AUTH" then
					--prepare 0220
					local safmin,safnext = terminal.GetArrayRange("SAF")
					local saffile = "SAF"..safnext
					local ret = terminal.FileCopy( "TXN_REQ", saffile)
					terminal.SetJsonValue(saffile,"0","220")
					terminal.SetJsonValue(saffile,"39",txn.rc)
					terminal.SetArrayRange("SAF","",tostring(safnext+1))
					txn.saf_generated = true
				end
				return do_obj_txn_ok()
			elseif txn.CTEMVRS == "10" then -- Ofline Declined
				txn.rc = "Z1"
				return do_obj_txn_nok(txn.rc)
			else
				return do_obj_emv_error(txn.CTEMVRS)
			end
		else
			return do_obj_emv_error(101)
		end
  elseif txn.chipcard and emvret == 137 or  emvret == 0 then --go online
      local scrlines = "WIDELBL,,21,2,C;"
      terminal.DisplayObject(scrlines,0,0,0)
      tcpreturn = tcpconnect()
      if tcpreturn == "NOERROR" then return do_obj_transstart()
	  else 
		if  txn.chipcard and not txn.emv.fallback and not txn.earlyemv then
			txn.offline = true
			local as2805msg = prepare_txn_req()
			return do_obj_offline_check()
		else
	      	txn.rc = "W21"
			return do_obj_txn_nok("CONNECT")
		end
	  end
  elseif not config.no_offline and ( emvret == 150 or emvret == 133 ) then
    txn.rc = "Y1"
	local as2805msg = prepare_txn_req()
	if txn.func ~= "AUTH" then
		--prepare 0220
		local safmin,safnext = terminal.GetArrayRange("SAF")
		local saffile = "SAF"..safnext
		local ret = terminal.FileCopy( "TXN_REQ", saffile)
		if txn.emv and txn.emv.tlv then
			local rc = terminal.HexToString(txn.rc)
			terminal.EmvSetTagData(0x8A00,rc)
			local newtlv = txn.emv.tlv .. terminal.EmvPackTLV("8A00")
			terminal.SetJsonValue(saffile,"55",newtlv)
		end
		terminal.SetJsonValue(saffile,"0","220")
		terminal.SetArrayRange("SAF","",tostring(safnext+1))
		txn.saf_generated = true
	end
    return do_obj_txn_ok()
  elseif emvret == 151 or emvret == 134 then
    txn.rc = "Z1"
	return do_obj_txn_nok(txn.rc)
  elseif emvret ~= 0 then
    return do_obj_emv_error(emvret)
  end
end

function do_obj_transstart()
  get_next_id("STAN")
  local scrlines = "WIDELBL,,27,2,C;" .."WIDELBL,,26,3,C;"
  terminal.DisplayObject(scrlines,0,0,0)
  local pan = txn.fullpan
  local onlpin = terminal.EmvGlobal("GET","ONLINEPIN")
  if onlpin and txn.pinblock_flag == "TODO" then
	local key_pin = config.key_pin
	txn.pinblock = terminal.PinBlock(key_pin,pan,txn.totalamt,config.stan,(txn.chipcard and not txn.earlyemv and not txn.emv.fallback and "1" or "0"))
	if txn.pinblock == "" then txn.pinblock = nil end
  end
  return do_obj_txn_req()
end

function do_obj_saf_rev_start(nextstep,mode)
	saf_rev_check()
	local rev_exist = config.safsign and string.find(config.safsign,"+")
	local saf_exist = config.safsign and string.find(config.safsign,"*")
	local saf_sent,rev_sent = false,false
	if (not mode or mode == "REVERSAL") and rev_exist then rev_sent = do_obj_saf_rev_send("REVERSAL") end
	if (not mode or mode == "SAF") and saf_exist then saf_sent = do_obj_saf_rev_send("SAF") end
	if rev_sent or saf_sent then saf_rev_check() end
	if nextstep then return nextstep()
	else return 0 end
end

function saf_rev_check()
  local safmin,safmax= terminal.GetArrayRange("SAF")
  local revmin,revmax= terminal.GetArrayRange("REVERSAL")
  if safmax > safmin or revmax > revmin then
	config.safsign =( revmax>revmin and "+" or "" ) ..( safmax>safmin and "*" or "")
  else config.safsign = false
  end
end

function do_obj_saf_rev_send(fname)
  local safmin,safmax= terminal.GetArrayRange(fname)
  if safmin == safmax then return true
  else
    local msg_flds = {}
    local scrlines_saf = "WIDELBL,THIS,SENDING SAF,2,C;" .."WIDELBL,,26,3,C;"
	local scrlines_rev = "WIDELBL,THIS,SENDING REVERSAL,2,C;" .."WIDELBL,,26,3,C;"
    local retmsg = "NOERROR"
	local ok = false
	for i=safmin,(txn.safonce and safmin or safmax-1) do
      local saffile = fname .. i
      if terminal.FileExist(saffile) then
		ok = false
        local errmsg,fld0,fld2,fld3,fld4,fld11,fld12,fld13,fld14,fld15,fld22,fld23,fld24,fld25,fld32,fld35,fld37,fld38,fld41,fld42,fld47,fld54,fld55,fld39,fld44,fld48,fld62,fld64,repeatsent
        fld0,fld2,fld3,fld4,fld11,fld12,fld13,fld14,fld22,fld23,fld24,fld25,fld32,fld35,fld37,fld38,fld41,fld42,fld47,fld54,fld55,fld62,repeatsent =
          terminal.GetJsonValue(saffile,"0","2", "3", "4", "11","12","13", "14", "22", "23", "24", "25", "32", "35", "37","38", "41", "42", "47", "54", "55","62","SENT")
        if fld0 ~= "220" then fld0 = "400" end
		if fld0 == "400" then terminal.DisplayObject(scrlines_rev,0,0,0) else terminal.DisplayObject(scrlines_saf,0,0,0) end
		if fld0 == "220" and (fld11 == "000000" or fld11 == "0" or fld11 == "") then 
			fld11 = get_next_id("STAN"); fld37 = string.format("%12s",fld11) 
			terminal.SetJsonValue(saffile,"11",fld11)
			terminal.SetJsonValue(saffile,"37",fld37)
		end
        local msg400_flds = {"0:"..fld0,"2:"..fld2,"3:"..fld3,"4:"..fld4,"11:"..fld11,"14:"..fld14,"22:"..fld22,"23:"..fld23,"24:"..fld24,"25:"..fld25,"32:"..fld32,"35:"..fld35,"37:"..fld37,"41:"..fld41,"42:"..fld42,"47:"..fld47,"54:"..fld54,"55:"..fld55, "62:"..fld62, "64:KEY="..config.key_kmacs}
        local msg220_flds = {"0:"..fld0,"2:"..fld2,"3:"..fld3,"4:"..fld4,"11:"..fld11,"12:"..fld12,"13:"..fld13,"14:"..fld14,"22:"..fld22,"23:"..fld23,"24:"..fld24,"25:"..fld25,"32:"..fld32,"35:"..fld35,"37:"..fld37,"38:"..fld38,"41:"..fld41,"42:"..fld42,"47:"..fld47,"54:"..fld54,"55:"..fld55, "62:"..fld62, "64:KEY="..config.key_kmacs}
        local as2805msg = ( fld0 == "220" and terminal.As2805Make(msg220_flds) or terminal.As2805Make(msg400_flds))
		retmsg = tcpconnect()
        if retmsg == "NOERROR" and as2805msg ~= "" then retmsg = tcpsend(as2805msg) end
        if retmsg ~= "NOERROR" then break end
        as2805msg = ""
        retmsg,as2805msg = tcprecv()
        if retmsg ~= "NOERROR" then break end
		if not as2805msg or as2805msg == "" then break end
        local msg_t = { "GET,12","GET,13", "GET,15","IGN,24","GETS,39","GETS,44","GETS,47","GETS,48","GETS,64" }
        if as2805msg ~= "" then
		  errmsg,fld12,fld13,fld15,fld39,fld44,fld47,fld48,fld55,fld64 = terminal.As2805Break( as2805msg, msg_t )
		  local data_nomac,data_mac = string.sub(as2805msg,1,#as2805msg-16),string.sub(as2805msg,-16)
		  local chkmac = terminal.Mac(data_nomac,"",config.key_kmacr)
		  if string.sub(chkmac,1,8) ~= string.sub(data_mac,1,8) or fld39 == "98" then config.logonstatus = "194"; config.logok = false ; check_logon_ok() end
		  if #fld47 > 0 then hosttag_process(fld47) end
		  if #fld48 then sessionkey_update(fld48) end
          if fld39 == "00" then
			terminal.FileRemove(fname..i)
			terminal.SetArrayRange(fname,tostring(i+1),"")
		  end
		  
		  if fld39 ~= "00" then break end
		  ok = true
		end
	  else terminal.SetArrayRange(fname,tostring(i+1),"")
	  end
	end
	if txn.safonce and ( safmin < safmax-1 ) then ok = false end
	saf_rev_check()
	return ok
  end
end

function prepare_txn_req()
    local msg_flds = {}
    local msgid = "200"
    local proccode = ""
    if txn.func == "PRCH" then proccode = "00" end
	if txn.rc and txn.rc == "Y1" then msgid = "220" end
	
    table.insert(msg_flds,"0:"..msgid)
    if txn.pan then table.insert(msg_flds,"2:"..txn.pan) end

    if txn.account == "SAVINGS" then proccode = proccode .. "1000"
    elseif txn.account == "CHEQUE" then proccode = proccode .. "2000"
    elseif txn.account == "CREDIT" then proccode = proccode .. "3000" end
    table.insert(msg_flds,"3:" .. proccode)
    table.insert(msg_flds,"4:" .. tostring(txn.totalamt))
    if msgid == "220" then
      local mmddhhmmss = terminal.Time( "MMDDhhmmss")
      table.insert(msg_flds,"11:" .. "000000")
      table.insert(msg_flds,"12:"..string.sub(mmddhhmmss,5,10))
      table.insert(msg_flds,"13:"..string.sub(mmddhhmmss,1,4))
	else
      table.insert(msg_flds,"11:" .. config.stan)
	end
    if txn.expiry then table.insert(msg_flds,"14:"..string.sub(txn.expiry,3,4)..string.sub(txn.expiry,1,2)) end
    local posentry = ""
    if txn.pan  then posentry = "01"
	elseif txn.ctls and txn.chipcard then posentry = "07"
	elseif txn.ctls and not txn.chipcard then posentry = "91"
    elseif txn.chipcard and txn.emv.fallback then
		local _,_,_,trk2 = string.find(txn.track2, "(%d*)=(%d*)")
		local chipflag = (trk2 and string.sub(trk2,5,5) or "")
		if chipflag == "1" then posentry = "02"; txn.chipcard = false ; txn.emv.fallback = false
		else posentry = "80" end
    elseif txn.chipcard and txn.emv.pan then posentry = "05"
    elseif txn.track2  then posentry = "02"
    end
    posentry = posentry .. "1"
    table.insert(msg_flds,"22:" .. posentry)
    if txn.chipcard and txn.emv.panseqnum then table.insert(msg_flds,"23:" .. txn.emv.panseqnum) end
    table.insert(msg_flds,"24:000")

    if txn.pan then txn.poscc = "08"
	elseif not txn.poscc then txn.poscc = "00" end
    table.insert(msg_flds,"25:" .. txn.poscc)
    table.insert(msg_flds,"32:" .. config.aiic)
    if txn.track2 then table.insert(msg_flds,"35:" .. txn.track2)
    elseif txn.chipcard and txn.emv.track2 then table.insert(msg_flds,"35:" .. txn.emv.track2) end

    table.insert(msg_flds,"37:" ..  string.format("%12s",config.stan))
    if txn.authid and #txn.authid > 0 then table.insert(msg_flds,"38:" ..txn.authid) end
    table.insert(msg_flds,"41:" ..config.tid)
    table.insert(msg_flds,"42:" ..config.mid)
    local fld47 = ""
    local tcc = ""
    if txn.cardname == "VISA" and txn.account == "CREDIT" then  tcc = "05"
    elseif txn.cardname == "MASTERCARD" and txn.account == "CREDIT" then tcc = (txn.ctls and txn.chipcard and "03" or txn.ctls and not txn.chipcard and "03" or "08")
    elseif txn.account == "CREDIT" then tcc = "08"
    else tcc = "03" end
    if txn.ccv then fld47 = fld47 ..txn.ccv  end
    fld47 = fld47 .. "TCC" ..tcc.."\\"
	local wcv = "1"
	local cvmr = (txn.ctls == "CTLS_E" and get_value_from_tlvs("9F34")) or txn.chipcard and not txn.earlyemv and not txn.emv.fallback and not txn.ctls and terminal.EmvGetTagData(0x9f34)
	
	if txn.moto then wcv = "1"
	elseif cvmr and #cvmr >0 then
		local cvmr1,cvmr3 = string.sub(cvmr,2,2),string.sub(cvmr,5,6)
		if cvmr1 == "1" or cvmr1 == "3" or cvmr1 == "4" or cvmr1 == "5" then
			txn.offlinepin = true ; wcv = "3"
		elseif cvmr1 == "F" then
			wcv = "6"
		elseif cvmr1 == "E" then
			wcv = "1"
		elseif txn.pinblock and #txn.pinblock > 0 then wcv = "2"
		else wcv = "6"
		end
	elseif txn.pinblock and #txn.pinblock > 0 then wcv = "2"
	else wcv = "1" --signature
	end

	fld47 = fld47 .."WCV"..wcv.."\\"
    if txn.chipcard and txn.emv.fallback and posentry == "801" then fld47 = fld47 .."FCR\\" end
    table.insert(msg_flds,"47:" ..terminal.HexToString(fld47))

	local _,_,olpin = string.find(fld47, "WCV2")
    if not txn.offlinepin and txn.pinblock and #txn.pinblock > 0 then table.insert(msg_flds,"52:" ..txn.pinblock) end

	local tlvs =""
    if txn.chipcard and not txn.earlyemv and not txn.emv.fallback then
	  if txn.ctls == "CTLS_E" then
			local tagvalue = ""
			tagvalue = get_value_from_tlvs("5000")
			local EMV5000 = "50".. string.format("%02X",#tagvalue/2) .. tagvalue
			tagvalue = get_value_from_tlvs("9F02")
			local EMV9f02 = "9F02"..string.format("%02X",#tagvalue/2)  .. tagvalue
			tagvalue = get_value_from_tlvs("9F03")
			if tagvalue == "" then tagvalue = "000000000000" end
			local EMV9f03 = "9F03"..string.format("%02X",#tagvalue/2)  .. tagvalue
			tagvalue = get_value_from_tlvs("9F26")
			local EMV9f26 = "9F26"..string.format("%02X",#tagvalue/2) .. tagvalue
			tagvalue = get_value_from_tlvs("8200")
			local EMV8200 = "82".. string.format("%02X",#tagvalue/2) .. tagvalue
			tagvalue = get_value_from_tlvs("9F36")
			local EMV9f36 = "9F36"..string.format("%02X",#tagvalue/2)  .. tagvalue
			tagvalue = get_value_from_tlvs("9F34")
			local EMV9f34 = "9F34"..string.format("%02X",#tagvalue/2)  .. tagvalue
			tagvalue = get_value_from_tlvs("9F35")
			if tagvalue == "" then tagvalue = "22" end
			local EMV9f35 = "9F35"..string.format("%02X",#tagvalue/2)  .. tagvalue
			tagvalue = get_value_from_tlvs("9F27")
			local EMV9f27 = "9F27"..string.format("%02X",#tagvalue/2)  .. tagvalue
  			local EMV9f1e = "9F1E08"..terminal.HexToString(string.sub(config.serialno,-8))
			tagvalue = get_value_from_tlvs("9F10")
			local EMV9f10 = "9F10"..string.format("%02X",#tagvalue/2)  .. tagvalue
			tagvalue = get_value_from_tlvs("9F33")
			local EMV9f33 = "9F33"..string.format("%02X",#tagvalue/2) .. tagvalue
			if tagvalue == "" then EMV9f33 = "9F3303E068C8" end
			tagvalue = get_value_from_tlvs("9F1A")
			local EMV9f1a = "9F1A"..string.format("%02X",#tagvalue/2)  .. tagvalue
			tagvalue = get_value_from_tlvs("9500")
			if #tagvalue > 0 and txn.eftpos and #tagvalue ~= "0000000000" then tagvalue = "0000000000" end
			local EMV9500 = "95".. string.format("%02X",#tagvalue/2) .. tagvalue
			tagvalue = get_value_from_tlvs("5F2A")
			local EMV5f2a = "5F2A"..string.format("%02X",#tagvalue/2)  .. tagvalue
			tagvalue = get_value_from_tlvs("9A00")
			local EMV9a00 = "9A".. string.format("%02X",#tagvalue/2) .. tagvalue
			tagvalue = get_value_from_tlvs("9C00")
			local EMV9c00 = "9C".. string.format("%02X",#tagvalue/2) .. tagvalue
			tagvalue = get_value_from_tlvs("9F37")
			local EMV9f37 = "9F37"..string.format("%02X",#tagvalue/2) .. tagvalue
			tagvalue = get_value_from_tlvs("8400")
			local EMV8400 = "84"..string.format("%02X",#tagvalue/2) .. tagvalue
			local EMV9f21 = "9F2103"..terminal.Time( "hhmmss")
			tagvalue = get_value_from_tlvs("9F53")
			local EMV9f53 = "9F53"..string.format("%02X",#tagvalue/2) .. tagvalue
			tlvs=tlvs..EMV5f2a..EMV8200..(txn.eftpos and EMV8400 or "")..EMV9500..EMV9a00..EMV9c00..EMV9f02..EMV9f03..EMV9f10..EMV9f1a..EMV9f21..EMV9f26..EMV9f27..EMV9f33..EMV9f34..(txn.eftpos and EMV9f35 or "")..EMV9f36..EMV9f37..(txn.cardname == "MASTERCARD" and EMV9f53 or "")
	  else
        tlvs = terminal.EmvPackTLV("5F2A".."8200"..(txn.eftpos and "8400" or "").."9500".."9A00".."9C00".."9F02".."9F03".."9F10".."9F1A".."9F21".."9F26".."9F27".."9F33".."9F34"..(txn.eftpos and "9F35" or "").."9F36".."9F37"..(txn.cardname == "MASTERCARD" and "9F53" or ""))
	  end
      txn.emv.tlv = tlvs
      table.insert(msg_flds,"55:" ..tlvs)
    end

    table.insert(msg_flds,"62:"..terminal.HexToString(config.roc))
    table.insert(msg_flds,"64:KEY=" .. config.key_kmacs)
    local as2805msg = terminal.As2805Make( msg_flds)

    if as2805msg ~= "" then
      local txnstr = "{TYPE:DATA,NAME:TXN_REQ,GROUP:WBC,VERSION:1,CARDNAME:"..( txn.cardname or "") .."," .. table.concat(msg_flds,",") .."}"
      terminal.NewObject("TXN_REQ",txnstr)
    end

    return (as2805msg)
end

function do_obj_txn_req()
	local as2805msg = prepare_txn_req()
    local retmsg = ""
    if as2805msg == "" then txn.localerror = true 
		return do_obj_txn_nok(retmsg)
	else
		if terminal.FileExist("TXN_REQ") then
			local fld0 = terminal.GetJsonValue("TXN_REQ","0")
			if fld0 == "200" then
				local revfile = "REV_TODO"
				terminal.FileCopy( "TXN_REQ", revfile)
			end
		end

		retmsg = tcpsend(as2805msg)
		if retmsg ~= "NOERROR" then 
			if  txn.chipcard and not txn.emv.fallback and not txn.earlyemv then
				txn.offline = true
				local revrequired = false
				if retmsg == "NO_RESPONSE" or retmsg == "TIMEOUT" then
					copy_txn_to_reversal()
					revrequired = true
				end
				return do_obj_offline_check(revrequired)
			else txn.localerror = true 
				return do_obj_txn_nok(retmsg)
			end
		else return do_obj_txn_resp()
		end
	end
end

function do_obj_txn_resp()
  local scrlines = "WIDELBL,,27,2,C;" .. "WIDELBL,,26,3,C;"
  terminal.DisplayObject(scrlines,0,0,0)
  local rcvmsg,errmsg,fld12,fld13,fld15,fld37,fld38,fld39,fld44,fld47,fld48,fld55,fld64
  errmsg, rcvmsg = tcprecv()
  if errmsg ~= "NOERROR" or not rcvmsg or rcvmsg == "" then 
	if errmsg == "NOERROR" then errmsg = "NO_RESPONSE" end
	if  txn.chipcard and not txn.emv.fallback and not txn.earlyemv and not txn.ctls then
		txn.offline = true
		copy_txn_to_reversal()
		local revrequired = true
		return do_obj_offline_check(revrequired)
	else txn.localerror = true
		return do_obj_txn_nok(errmsg)
	end
  else
    txn.host_response = true
    local msg_t = {"GET,12","GET,13","GET,15","GETS,37","GETS,38","GETS,39","GETS,44","GETS,47","GETS,48","GETS,55","GETS,64" }
    errmsg,fld12,fld13,fld15,fld37,fld38,fld39,fld44,fld47,fld48,fld55,fld64 = terminal.As2805Break( rcvmsg, msg_t )
    if fld12 and fld13 then txn.time = fld13..fld12 end
    if fld38 and #fld38>0 then txn.authid = fld38 end
    if fld39 and #fld39>0 then txn.rc = fld39 end
    if fld44 and #fld44>0 then txn.rc_desc = fld44 end
	if fld47 and #fld47>0 then hosttag_process(fld47) end
	if config.hostsettle and fld15 and #fld15>0 then txn.newbatch = settledate_update(fld15) end
    local data_nomac,data_mac = string.sub(rcvmsg,1,#rcvmsg-16),string.sub(rcvmsg,-16)
    local chkmac = terminal.Mac(data_nomac,"",config.key_kmacr)

    if fld48 and #fld48>80 then sessionkey_update(fld48) end
    if errmsg ~= "NOERROR" then return do_obj_txn_nok(errmsg)  -- as2805 error
    elseif string.sub(chkmac,1,8) ~= string.sub(data_mac,1,8) then
		if fld39 == "98" and fld48 ~= "" then -- invalid session key
			copy_txn_to_reversal(); return do_obj_txn_nok()
		elseif fld39 == "98" and fld48 =="" then -- invalid MAC
			return do_obj_txn_nok()
		else
			txn.localerror = true
			copy_txn_to_reversal()
			return do_obj_txn_nok("MAC") -- mac error 
		end
    elseif fld39 ~= "00" and fld39 ~= "08" then 
      local HOST_DECLINED = 2
	  if not txn.ctls and txn.chipcard and not txn.emv.fallback and not txn.earlyemv and fld39~="91" then 
			  terminal.EmvUseHostData(HOST_DECLINED,fld55) end
      return do_obj_txn_nok(errmsg)
    else 
      if txn.time and string.len(txn.time)  == 10 then
        local yyyymm = terminal.Time( "YYYYMM")
        local yyyy,mm = string.sub(yyyymm,1,4),string.sub(yyyymm,5,6)
        if mm == "01" and string.sub(txn.time,1,2) == "12" then yyyy = tonumber(yyyy) -1 end
        if mm == "12" and string.sub(txn.time,1,2) == "01" then yyyy = tonumber(yyyy) +1 end
   		txn.time = yyyy..txn.time
        terminal.TimeSet(txn.time,config.timeadjust)
      end
      local HOST_AUTHORISED,emvok = 1,0

      if not txn.ctls and txn.chipcard and not txn.emv.fallback and not txn.earlyemv then
		if not terminal.EmvIsCardPresent() then emvok = 103 
		else local rc = terminal.HexToString(txn.rc)
			terminal.EmvSetTagData(0x8A00,rc)
			emvok = terminal.EmvUseHostData(HOST_AUTHORISED,fld55) 
		end
	  end
      if emvok ~= 0--[[TRANS_DECLINE]] then 
	    copy_txn_to_reversal()
		if emvok == 103 then txn.rc = "W33"; txn.localerror = true
			return do_obj_txn_nok("CARD REMOVED")
		else txn.rc = "Z4" 
			return do_obj_txn_nok(txn.rc) 
		end
      else
		return do_obj_txn_ok() 
	  end
    end
  end
end

function do_obj_txn_ok()
	local pinchked = not txn.ctls and txn.chipcard and txn.offlinepin or txn.pinblock or txn.ctls
    local signflag =  not txn.moto and ( txn.ctlsPin == "1" or txn.ctlsPin == "3" or txn.rc == "08" or (txn.chipcard and terminal.EmvGlobal("GET","SIGN")) or not pinchked and not txn.eftpos) 
	local scrlines,resultstr,resultstr_nosign = "","",""
	if txn.rc == "08" then 
		scrlines =  "WIDELBL,,147,2,C;" .."WIDELBL,,54,3,C;" 
		resultstr = "APPROVED\\R" .. txn.rc.."\\n" 
	else scrlines =  "WIDELBL,,30,2,C;" .."WIDELBL,,147,3,C;" 
		resultstr = "APPROVED\\R" .. txn.rc.."\\n" 
	end
	resultstr_nosign = resultstr
	if signflag then 
		resultstr = resultstr .. "CARDHOLDER SIGN HERE:\\n\\n\\n\\n\\nX______________________\\n"
	end
	
    terminal.DisplayObject(scrlines,0,0,0)
    local who = "MERCHANT COPY\\n"
	txn.mreceipt= get_ipay_print( who, true, resultstr)
	who = "CUSTOMER COPY\\n"
	txn.creceipt= get_ipay_print( who, true, resultstr_nosign)
    local prtvalue = (ecrd.HEADER or "") ..(ecrd.HEADER_OK or "") .. txn.mreceipt ..(ecrd.MTRAILER or "") ..(config.debugemv and get_emv_print_tags(config.debugemv) or "").."\\n"
    terminal.Print(prtvalue,true)
	checkPrint(prtvalue)
	terminal.FileRemove("REV_TODO")
	do_obj_iecr_end(0)
	
    local prt_keep = (ecrd.HEADER  or "") .. (ecrd.HEADER_OK or "") ..prtvalue.. (ecrd.MTRAILER or "") .."\\n"
	local signok = true
	if signflag then signok = do_obj_txn_sig() end
	if signok then
      terminal.SetJsonValue("DUPLICATE","RECEIPT",prt_keep)
      return do_obj_txn_second_copy()
	else
	  do_obj_itaxi_pay_revert(0)
	  if txn.rc == "Y1" or txn.rc == "Y3" then return do_obj_txn_finish()
	  else return do_obj_saf_rev_start(do_obj_txn_finish,"REVERSAL") end
	end
end

function update_total()
	local cardname = txn.cardname
	if txn.account ~= "CREDIT" then cardname = "DEBIT" end
    local prchnum,prchamt,cashnum,cashamt,rfndnum,rfndamt=terminal.GetJsonValueInt("SHFT","PRCHNUM","PRCHAMT","CASHNUM","CASHAMT","RFNDNUM","RFNDAMT")
    local cr_s_num,cr_s_amt,cr_r_num,cr_r_amt,dr_s_num,dr_s_amt,dr_r_num,dr_r_amt,auth_s_num,auth_s_amt,auth_r_num,auth_r_amt,card_prch_num,card_prch_amt,card_rfnd_num,card_rfnd_amt=
	terminal.GetJsonValueInt("SHFTSTTL","CR_PRCHNUM","CR_PRCHAMT","CR_RFNDNUM","CR_RFNDAMT","DR_PRCHNUM","DR_PRCHAMT","DR_RFNDNUM","DR_RFNDAMT","AUTH_PRCHNUM","AUTH_PRCHAMT","AUTH_RFNDNUM","AUTH_RFNDAMT",cardname.."_PRCHNUM",cardname.."_PRCHAMT",cardname.."_RFNDNUM",cardname.."_RFNDAMT")
    if txn.prchamt>0 and txn.func == "PRCH" then
      terminal.SetJsonValue("SHFT","PRCHAMT",prchamt+txn.prchamt)
      terminal.SetJsonValue("SHFT","PRCHNUM",prchnum+1)
	end
	if txn.totalamt>0 and txn.func == "PRCH" then
      terminal.SetJsonValue("SHFTSTTL",cardname.."_PRCHAMT",card_prch_amt+txn.totalamt)
      terminal.SetJsonValue("SHFTSTTL",cardname.."_PRCHNUM",card_prch_num+1)
      if txn.account == "CREDIT" then
        terminal.SetJsonValue("SHFTSTTL","CR_PRCHAMT",cr_s_amt+txn.totalamt)
        terminal.SetJsonValue("SHFTSTTL","CR_PRCHNUM",cr_s_num+1)
      else
        terminal.SetJsonValue("SHFTSTTL","DR_PRCHAMT",dr_s_amt+txn.totalamt)
        terminal.SetJsonValue("SHFTSTTL","DR_PRCHNUM",dr_s_num+1)
      end
  end
end

function do_obj_txn_sig()
  local scrlines = "WIDELBL,,33,3,C;" .."BUTTONS_1,THIS,YES,8,10;".. "BUTTONS_2,THIS,NO,8,33;"
  if txn.chipcard and terminal.EmvIsCardPresent() then
  	local scrlines_card = "WIDELBL,THIS,REMOVE CARD,2,C;".."WIDELBL,THIS,CHECK SIGNATURE,3,C;"
	terminal.DisplayObject(scrlines_card,0,EVT.SCT_OUT+EVT.TIMEOUT,15000)
  end
  local screvent = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL,EVT.TIMEOUT,120000)
  if screvent =="BUTTONS_1" or screvent =="KEY_OK" or screvent =="TIME" then
    return true
  elseif screvent =="BUTTONS_2" or screvent=="CANCEL" then
	  local scrlines = "WIDELBL,THIS,WARNING,2,C;" .."TEXT,THIS,YOU ARE ABOUT TO,4,C;"..
	  "TEXT,THIS,DECLINE THIS FARE.,5,C;".."TEXT,THIS,DO YOU WANT TO,6,C;".."TEXT,THIS,CANCEL PAYMENT,7,C;".."BUTTONS_1,THIS,YES,10,10;".. "BUTTONS_2,THIS,NO,10,33;"
	  local screvent,_ = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL,EVT.TIMEOUT,300000)
	  if screvent == "BUTTONS_1" or screvent == "KEY_OK" or screvent == "TIME"  then
		if txn.tcpsent then
			local safmin,safnext = terminal.GetArrayRange("REVERSAL")
			local saffile = "REVERSAL"..safnext
			local ret = terminal.FileCopy( "TXN_REQ", saffile)
			terminal.SetJsonValue(saffile,"0","400")
			if txn.cardname == "VISA" and  txn.emv.tlv and #txn.emv.tlv > 0 then 
				local newtlv = txn.emv.tlv .. terminal.EmvPackTLV("8A009F5B")
				terminal.SetJsonValue(saffile,"55",newtlv)
			end
			terminal.SetArrayRange("REVERSAL","",safnext+1)
		end
		if txn.saf_generated then
			local safmin,safnext = terminal.GetArrayRange("SAF")
			terminal.FileRemove("SAF"..(safnext-1))
			terminal.SetArrayRange("SAF","",safnext-1)
		end
		txn.rc = "T8"
		local resultstr= "DECLINED\\RSA\\nSIGNATURE MISMATCH\\n\\n"
		local who = "MERCHANT COPY\\n"
		local prtvalue = (ecrd.HEADER or "") .. get_ipay_print( who, false, resultstr)..(ecrd.MTRAILER or "") .."\\n"
		terminal.Print(prtvalue,true)
		checkPrint(prtvalue)
		local scrlines = "WIDELBL,,36,4,C;" .."BUTTONS_1,THIS,YES,8,10;".. "BUTTONS_2,THIS,NO,8,33;"
		local screvent = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL+KEY.CLR,EVT.TIMEOUT,30000)
		who = "CUSTOMER COPY\\n"
		local prtvalue2 = (ecrd.HEADER or "") .. get_ipay_print( who, false, resultstr)..(ecrd.MTRAILER or "") .."\\n"
		if screvent == "BUTTONS_1" or screvent == "TIME" or screvent == "KEY_OK" then
			terminal.Print(prtvalue2,true)
			checkPrint(prtvalue2)
		end
	
		local rcptfile = "TAXI_Dclnd"
		local data = "{TYPE:DATA,NAME:"..rcptfile..",GROUP:CBA,VERSION:2.0,HEADER:".. (ecrd.HEADER or "")..",CRCPT:"..prtvalue2..",MRECEIPT:"..prtvalue..",TRAILER:"..(ecrd.MTRAILER or "").."}"
		terminal.NewObject(rcptfile,data)
		return false 
	  elseif screvent == "BUTTONS_2" or screvent == "KEY_CLR" or screvent == "CANCEL" then
		return do_obj_txn_sig()
	  end
  end
end

function do_obj_txn_second_copy()
  local scrlines = "WIDELBL,,36,4,C;" .."BUTTONS_1,THIS,YES,8,10;".. "BUTTONS_2,THIS,NO,8,33;"
  local screvent,_ = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL+KEY.CLR,EVT.TIMEOUT,30000)

  if screvent == "BUTTONS_1" or screvent == "KEY_OK" then
    scrlines = "WIDELBL,,37,2,C;" .."WIDELBL,,26,3,C;"
    terminal.DisplayObject(scrlines,0,0,0)
    local prtvalue = (ecrd.HEADER or "") .. (ecrd.HEADER_OK or "") .. txn.creceipt.. (ecrd.CTRAILER or "") .."\\n"
    terminal.Print(prtvalue,true)
	checkPrint(prtvalue)
    terminal.SetJsonValue("DUPLICATE","RECEIPT",prtvalue)
  end
  update_total()
  return do_obj_txn_finish()
end

function copy_txn_to_reversal()
	if terminal.FileExist("TXN_REQ") then
		local fld0 = terminal.GetJsonValue("TXN_REQ","0")
		if fld0 == "200" then
			local safmin,safnext = terminal.GetArrayRange("REVERSAL")
			local saffile = "REVERSAL"..safnext
			local ret = terminal.FileCopy( "TXN_REQ", saffile)
			terminal.SetJsonValue(saffile,"0","400")
			if txn.rc and txn.cardname == "VISA" and txn.emv.tlv and #txn.emv.tlv > 0 then 
				terminal.EmvSetTagData(0x8A00,terminal.HexToString(txn.rc))
				local newtlv = txn.emv.tlv .. terminal.EmvPackTLV("8A009F5B")
				terminal.SetJsonValue(saffile,"55",newtlv)
			end
			terminal.SetArrayRange("REVERSAL","",safnext+1)
			saf_rev_check()
		end
	end
end

function do_obj_txn_nok(tcperrmsg)
  local nextstep = nil
  local printerr = true
  if txn.rc == "Z1" or txn.rc == "Z3" or txn.rc == "Z4" then
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

function do_obj_txn_nok_print(errcode,errmsg,ret)
	local result_str = "DECLINED\\R"..(errcode or "").."\\n" .. (errmsg or "") .."\\n"
	local amttrans = txn.totalamt and txn.totalamt > 0
	local who = amttrans and "MERCHANT COPY\\n" or ""
	local print_info1 = get_ipay_print_nok(who,result_str)
	local prtvalue = (ecrd.HEADER or "") ..print_info1.. (ecrd.MTRAILER or "") .."\\n"
    terminal.Print(prtvalue,true)
	checkPrint(prtvalue)
	if amttrans then
		local scrlines = "WIDELBL,,36,4,C;" .."BUTTONS_1,THIS,YES,8,10;".. "BUTTONS_2,THIS,NO,8,33;"
		local screvent = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL+KEY.CLR,EVT.TIMEOUT,30000)
		who = "CUSTOMER COPY\\n"
		local print_info2 = get_ipay_print_nok(who,result_str)
		if screvent == "BUTTONS_1" or screvent == "KEY_OK" then
			scrlines = "WIDELBL,,37,2,C;" .."WIDELBL,,26,3,C;"
			terminal.DisplayObject(scrlines,0,0,0)
			prtvalue = (ecrd.HEADER or "") ..print_info2.. (ecrd.MTRAILER or "") .."\\n"
			terminal.Print(prtvalue,true)
			checkPrint(prtvalue)
		end
		local rcptfile = "TAXI_Dclnd"
		local data = "{TYPE:DATA,NAME:"..rcptfile..",GROUP:CBA,VERSION:2.0,HEADER:".. ecrd.HEADER..",CRCPT:"..print_info2..",MRECEIPT:"..print_info1..",TRAILER:"..ecrd.MTRAILER.."}"
		terminal.NewObject(rcptfile,data)
	end
	if ret then return ret else return do_obj_txn_finish() end
end

function do_obj_logon_init()
  local scrlines = ",,78,4,C;" .. "BUTTONS_1,THIS,YES,8,10;".. "BUTTONS_2,THIS,NO,8,33;"
  local scrkeys  = KEY.CLR+KEY.CNCL+KEY.OK
  local screvents = EVT.TIMEOUT
  local scrtimeout = 30000
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,screvents,scrtimeout)

  if screvent == "KEY_OK" or screvent == "BUTTONS_1" then
    scrlines = "WIDELBL,,21,4,C;"
	terminal.DisplayObject(scrlines,0,0,0)
	txn.func = "LGON"
	txn.manuallogon = true
    return do_obj_logon_start()
  else
    return do_obj_txn_finish()
  end
end

function do_obj_logon_start()
  local rc = ""
  local tcpreturn = tcpconnect()
  if tcpreturn == "NOERROR" then
    return do_obj_logon_req()
  else
    return do_obj_logon_nok(tcpreturn)
  end
end

function do_obj_logon_req()
   if config.logonstatus == "" then
      config.logonstatus = "195"
      terminal.SetJsonValue("CONFIG","LOGON_STATUS",config.logonstatus)
   end
   local scrlines = "WIDELBL,,25,2,C;" .. ( ("WIDELBL,THIS,STEP "..config.logonstatus)..",3,C;").."WIDELBL,,26,4,C;"
   local screvent,scrinput = terminal.DisplayObject(scrlines,0,0,0)

   local fld60 = ""
   if config.logonstatus == "195" then
      local ktke = terminal.GetJsonValue("IRIS_CFG","KTK")
      local kvc = terminal.Kvc( "",ktke)
      local msg60_195 = { "N,16," .. config.ppid , "b,24," .. kvc, "N,2,09","a,2," .. config.sw_ver, "N,4,0209","a,8,"..config.serialno, "N,4,0006" }
      fld60 = terminal.As2805MakeCustom( msg60_195 )
    elseif config.logonstatus == "194" or config.logonstatus == "193" or config.logonstatus == "001" then
      local kek_ppasn = "11111111"
      local msg60 = { "N,16," .. config.ppid , "b,32," .. kek_ppasn, "a,2," .. config.sw_ver,"a,2,  ", "a,8,"..config.serialno, "N,4,0006" }
      fld60 = terminal.As2805MakeCustom( msg60 )
    end

    local fld47 = ""
    if config.logonstatus == "001" then
      if config.emvactive == "0" then fld47 = "WEM0\\" else fld47 = "WEM1\\" end
      if config.msgenc == "2" then fld47 = fld47 .. "WME2\\"  else fld47 = fld47 .. "WME0\\" end
	  fld47 = terminal.HexToString(fld47)
    end
    local msg_flds = {"0:800","3:920000","11:"..get_next_id("STAN"), "24:000","32:".. config.aiic, "41:"..config.tid, "42:" ..config.mid, "47:"..fld47, "60:"..fld60,"70:".. config.logonstatus}
    local as2805msg = terminal.As2805Make( msg_flds)

    local retmsg = ""
    if as2805msg ~= "" then retmsg = tcpsend(as2805msg) end
    if retmsg ~= "NOERROR" then txn.localerror = true; return do_obj_logon_nok(retmsg)
    else return do_obj_logon_resp() end
end

function do_obj_logon_resp()
  local errmsg, rcvmsg = tcprecv()
  if errmsg ~= "NOERROR" then
    txn.localerror = true
    return do_obj_logon_nok(errmsg)
  elseif not rcvmsg or rcvmsg == "" then
    txn.localerror = true
	return do_obj_logon_nok("NO_RESPONSE")
  else
    local msg_t = {"GET,12","GET,13","GETS,39","GETS,44","GETS,47","GET,48","GET,70" }
    local errmsg,fld12,fld13,fld39,fld44,fld47,fld48,fld70 = terminal.As2805Break( rcvmsg, msg_t )
    if fld39 and #fld39>0 then txn.rc = fld39 end
    if fld44 and #fld44>0 then txn.rc_desc = fld44 end
    if errmsg ~= "NOERROR" then return do_obj_logon_nok(errmsg)
    elseif fld39 ~= "00" then return do_obj_logon_nok(fld39)
    elseif tonumber(fld70) == 195 then
      local pdh = string.sub(fld48, 1, 68 )
      local ekd = string.sub(fld48, 37 , 68 )
      local pdhmac = string.sub(fld48, 69 , 76)
      local ettab = string.sub(fld48, 77)

      local key_ktkman,key_ktkspn = terminal.GetJsonValue("IRIS_CFG", "KTK","KTKSPN")
      local ok = terminal.Derive3Des( ekd,"",config.key_kdatar,key_ktkman)
      local chkmac = terminal.Mac(pdh,"A200",config.key_kdatar)

      if string.sub(chkmac,1,8) ~= pdhmac then return do_obj_logon_nok("MAC")
      else
        local dttab = terminal.Dec(ettab,"",16,config.key_kdatar)
        local payload = string.sub(dttab,1,46)
        local plmac = string.sub(dttab,47,54)

        local ktkdata = string.sub(dttab,53,84)
        if terminal.DesStore( ktkdata,16,key_ktkspn) == false  then return do_obj_logon_nok("KTKSPN")
        else
            terminal.SetJsonValue("CONFIG","LOGON_STATUS","194")
            config.logonstatus = "194"
            return do_obj_logon_req()
        end
      end
    elseif tonumber(fld70) == 194  then
      local pdh = string.sub(fld48, 1, 68 )
      local ekd = string.sub(fld48, 37 , 68 )
      local pdhmac = string.sub(fld48, 69 , 76)
      local ewtab = string.sub(fld48, 77)

      local key_ktkspn,key_ktma,key_ktmb = terminal.GetJsonValue("IRIS_CFG", "KTKSPN","KTMA","KTMB")
      local ok = terminal.Derive3Des( ekd,"",config.key_kdatar,key_ktkspn)
      local chkmac = terminal.Mac(pdh,"A200",config.key_kdatar)
      if string.sub(chkmac,1,8) ~= pdhmac then return do_obj_logon_nok("MAC")
      else
        local dwtab = terminal.Dec(ewtab,"",16,config.key_kdatar)
        local keycount = string.sub(dwtab,21,24)

        local idx,i = 25, 1
        if keycount == "0003" or keycount == "0005" then
          while i <= tonumber(keycount) do
            local keytype = string.sub(dwtab, idx, idx + 3) ; idx = idx + 4
            local keyver = string.sub(dwtab, idx, idx + 7) ; idx = idx + 8
            local keydata = string.sub(dwtab, idx, idx + 31); idx = idx + 32
            if keytype == "0007" then terminal.DesStore( keydata,16,key_ktma)
            elseif keytype == "0008" then terminal.DesStore( keydata,16,key_ktmb)
            end
            i = i + 1
          end
        end
        idx = idx + 4
        local payload = string.sub(dwtab,1,idx - 1)
        terminal.SetJsonValue("CONFIG","LOGON_STATUS","193")
        config.logonstatus = "193"
        return do_obj_logon_req()
      end
    elseif tonumber(fld70) == 193  then
      local key_ktma,key_ktmb,key_kek1,key_kek2,key_ppasn = terminal.GetJsonValue("IRIS_CFG","KTMA","KTMB","KEK1","KEK2","PPASN")
      local key_ind = string.sub(fld48, 1, 2 )
      local ktm
      if key_ind == "41" then key_ind = "A"; ktm = key_ktma
      elseif key_ind == "42" then key_ind = "B" ; ktm = key_ktmb end

      local ekek1 = string.sub(fld48, 3 , 34 )
      local ekek2 = string.sub(fld48, 35 , 66 )
      local eppasn = string.sub(fld48, 67 , 82)

      local ok = terminal.Derive3Des( ekek1,"",key_kek1,ktm)
      ok = terminal.Derive3Des( ekek2,"",key_kek2,ktm)
      local ppasn = terminal.Dec( eppasn,"8888","16",ktm)
      terminal.SetJsonValue("CONFIG","PPASN",ppasn)
      ok = terminal.DesStore( ppasn, "8", key_ppasn)

      if key_ind == "A" then terminal.SetJsonValue("CONFIG","LOGON_STATUS","001");config.logonstatus = "001"
      elseif key_ind == "B" then terminal.SetJsonValue("CONFIG","LOGON_STATUS","001");config.logonstatus = "001" end
      return do_obj_logon_req()

    elseif tonumber(fld70) == 1  then
	  if #fld47 > 0 then hosttag_process(fld47) end
      local ok = sessionkey_update(fld48)
      if ok then config.logok = true; return do_obj_logon_ok()
      else terminal.SetJsonValue("CONFIG","LOGON_STATUS","194");config.logonstatus = "194" end
    else
      if config.logonstatus ~= "195" then config.logonstatus = "194" end
      return do_obj_logon_req()
    end
  end
end

function do_obj_logon_ok()
  if txn.manuallogon then
	  local timestr = terminal.Time( "DD/MM/YY hh:mm" )
	  local scrlines = "WIDELBL,,35,4,C;"
	  local screvent,scrinput = terminal.DisplayObject(scrlines,0,0,0)
	  local prtdata = "\\C\\H" .. config.servicename .."\\n\\n" ..
					  "\\C" .. config.merch_loc0 .."\\n" ..
					  "\\C" .. config.merch_loc1 .."\\n" ..
					  "\\CMERCHANT LOGON\\n\\n" ..
					  "MERCHANT ID:\\R" .. config.mid .. "\\n" ..
					  "TERMINAL ID:\\R" .. config.tid .."\\n" ..
					  "DATE/TIME:\\R" .. timestr .. "\\n" ..
					  "BANK REF:\\R" .. config.stan.. "\\n" ..
					  "APPROVED\\R00\\n" ..
					  "\\4------------------------------------------\\n"
	  terminal.Print(prtdata,true)
	  checkPrint(prtdata)
  end
  return do_obj_txn_finish()
end

function do_obj_logon_nok(errormsg)
  local result,rcpttxt,disptxt = "",errormsg,errormsg
  if errormsg and #errormsg == 2 then result = "DECLINED"; rcpttxt = wbc_errorcode("H"..errormsg); disptxt = rcpttxt
  else result= "CANCELLED" end

  local scrlines = "WIDELBL,THIS,LOGON "..result..",4,C;".."WIDELBL,THIS,"..disptxt..",6,C;"
  local screvent,scrinput = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL+KEY.CLR,EVT.TIMEOUT,ScrnErrTimeout)
  local timestr = terminal.Time( "DD/MM/YY hh:mm" )
  result = "\\n" ..result .. "\\R" ..(errormsg or "") .."\\n"
  if rcpttxt ~= errormsg then  result = result .. "\\R" .. rcpttxt .."\\n" end
  local prtdata = "\\C\\H" .. config.servicename .."\\n\\n" ..
				  "\\C" .. config.merch_loc0 .."\\n" ..
				  "\\C" .. config.merch_loc1 .."\\n" ..
				  "\\CMERCHANT LOGON\\n\\n" ..
				  "MERCHANT ID:\\R" .. config.mid .. "\\n" ..
				  "TERMINAL ID:\\R" .. config.tid .."\\n" ..
				  "DATE/TIME:\\R" .. timestr .. "\\n" ..
				  "BANK REF:\\R" .. config.stan.. "\\n" ..
				  "PPID:\\R" .. config.ppid .. "\\n" ..
				  result .. "\\n" ..
				  "\\4------------------------------------------\\n"
  terminal.Print(prtdata,true)
  checkPrint(prtdata)
  return do_obj_txn_finish()
end

function do_obj_emv_error(emvstat)
  local scrlines,linestr="",""
  local gemv_techfallback = terminal.EmvGlobal("GET","TECHFALLBACK")
  gemv_techfallback = gemv_techfallback and config.fallback
  --if emvstat == 146 and gemv_techfallback then gemv_techfallback = false end
  local screvents = EVT.TIMEOUT
  local scrkeys = KEY.OK+KEY.CNCL

  if terminal.EmvIsCardPresent() then 
	linestr = "WIDELBL,THIS,REMOVE CARD,4,C;"
	screvents = EVT.SCT_OUT 
	scrkeys = 0
  end
  txn.emv_retry = not txn.emv_retry
  if txn.emv_retry then
    linestr = "WIDELBL,THIS,PLEASE RETRY,4,C;"; txn.emv.fallback = false
  elseif gemv_techfallback then txn.emv.fallback = true;linestr = "WIDELBL,THIS,USE FALLBACK,4,C;" end
  --NO_ATR
  if emvstat == 157 then scrlines = "WIDELBL,THIS,NO ATR,2,C;" ..linestr
  elseif emvstat==101 then scrlines="WIDELBL,,277,2,C;"..linestr
  elseif emvstat==103 then scrlines="WIDELBL,,283,2,C;"..linestr
  elseif emvstat==104 then scrlines="WIDELBL,,275,2,C;"..linestr
  elseif emvstat==106 then scrlines="WIDELBL,,282,2,C;"..linestr
  elseif emvstat==107 then scrlines="WIDELBL,,276,2,C;"..linestr
  elseif emvstat==108 then scrlines="WIDELBL,,281,2,C;"..linestr
  elseif emvstat==112 then scrlines="WIDELBL,,273,2,C;".."WIDELBL,,274,3,C;"..linestr
  elseif emvstat==113 then scrlines="WIDELBL,,276,2,C;".."WIDELBL,,274,3,C;"..linestr
  elseif emvstat==114 or emvstat==119 then scrlines="WIDELBL,,276,2,C;".."WIDELBL,,272,3,C;"..linestr
  elseif emvstat==116 then scrlines="WIDELBL,,120,2,C;"..linestr
  elseif emvstat==118 then scrlines="WIDELBL,,275,2,C;".."WIDELBL,,274,3,C;"..linestr
  elseif emvstat==125 then scrlines="WIDELBL,,285,2,C;"..linestr
  elseif emvstat==146 then scrlines="WIDELBL,,288,2,C;".."WIDELBL,,289,3,C;"..linestr
  else scrlines="WIDELBL,,276,2,C;"..linestr
  end
  terminal.DisplayObject(scrlines,scrkeys,screvents,3000)
  if gemv_techfallback or txn.emv_retry then return do_obj_swipecard()
  else return do_obj_txn_finish() end 
end

function tcpconnect()
  if not config.tcptimeout then config.tcptimeout = 30 end
  local tcperrmsg = terminal.TcpConnect( "6",config.apn,"B1","0","",config.hip,config.port,config.tcptimeout,"4096","10000") -- "6" CLNP
  return(tcperrmsg)
end

function msg_enc (method,msg)
	local newmsg,iv,ivrn = "","",""
	if method == "E" then
		ivrn = string.format("%06d",math.random(100000,999999))
		iv = "5757575757"..ivrn
		newmsg = terminal.Enc(msg,"","16",config.key_kdatas,iv)..ivrn.. terminal.HexToString(config.tid..string.format("%-15s",config.mid).."WME").."03"
	elseif method == "D" then

		local tail = string.sub( msg, -52)
		iv = "5757575757".. string.sub(tail,1,6)
		local msg_notail = string.sub(msg,1, #msg - 52 )
		newmsg = terminal.Enc(msg_notail,"","16",config.key_kdatar,iv)
	end
	return newmsg 
end

function tcpsend(msg)
  local tcperrmsg = ""
  local mti = ( msg and #msg > 4 and string.sub(msg,1,4) or "")
  if config.msgenc == "2" and ( mti == "0100" or mti=="0200" or mti == "0220" or mti == "0400") then
	msg = mti .. msg_enc( "E", string.sub(msg,5))
  end
  tcperrmsg = terminal.TcpSend(msg)
  txn.tcpsent = true
  return(tcperrmsg)
end

function tcprecv()
  local rcvmsg,tcperrmsg ="",""
  tcperrmsg,rcvmsg = terminal.TcpRecv("2000",config.tcptimeout)
  if tcperrmsg == "NOERROR" and #rcvmsg > 4 and config.msgenc == "2" then
    local mti = string.sub(rcvmsg,1,4)
    if mti == "0110" or mti=="0210" or mti == "0230" or mti == "0410" then
		rcvmsg = mti .. msg_enc( "D", string.sub(rcvmsg,5))
	end
  end
  if tcperrmsg ~= "NOERROR" and tcperrmsg ~= "TIMEOUT" and tcperrmsg ~= "NO_RESPONSE" then tcperrmsg = "NO_RESPONSE" end
  return tcperrmsg,rcvmsg
end

function localerrorcode(errmsg)
  txn.localerror = true
  local pstnerr_t = {LINE="W1",ANSWER="W2",BUSY="W3",NOPHONENUM="W4",CARRIER="W6",HOST="W6",SOCKET="W7",
               SHUTDOWN="W8",DHCP="W9",PPP_AUTH="W10",PPP_LCP="W11",IPCP="W12",ETH_SND_FAIL="W13",
               ETH_RCV_FAIL="W14",BATTERY="W15",COVERAGE="W16",SIM="W17",NETWORK="W18",PDP="W19",SIGNAL="W20",
               CONNECT="W21",GENERAL="W22",RCV_FAIL="W23",TIMEOUT="W24",ITIMEOUT="W25",MAC="W26",RCV_FAIL="W27",SND_FAIL="W28",
			   NO_RESPONSE="W29", SWIPE_INSERT="W32",CARD_REMOVED="W33"
			   }
  return(pstnerr_t[errmsg])
end

function wbc_errorcode(errcode)
  local wbcerr_t = { Z1="CANNOT PAY",Z3="ISSUER UNAVAILABLE",Z4="CANNOT PAY",H03="INVALID PINPAD",H05="CANNOT PAY",H06="CANNOT PAY",H13="CANNOT PAY",H14="CONTACT ISSUER",
  H19="CONTACT ISSUER",H30="FORMAT ERROR",H39="WRONG ACCOUNT",H51="INSUFFICIENT FUNDS",H54="EXPIRED CARD",H55="INCORRECT PIN",H75="EXCEED PIN TRIES",H91="ISSUER NOT AVAILABLE",H97="SETTLE NOT AVAILABLE",H98="INVALID MAC"
  }
  local msg = wbcerr_t[errcode]
  return(msg)
end

function jsontable2string( jtable_t)
  local jsontag, jsonvalue, jtable_s = "","",""
  for jsontag,jsonvalue in pairs(jtable_t) do
    if jtable_s == "" then jtable_s = "{" .. jsontag .. ":" .. jsonvalue
    else jtable_s = jtable_s .. "," .. jsontag .. ":" .. jsonvalue end
  end
  if #jtable_s > 0 then jtable_s = jtable_s .."}" end
  return jtable_s
end

function hosttag_process(fld47)
  if #fld47 > 0 then
	local stags = terminal.StringToHex(fld47,#fld47)
	local i = 1
	for tag in string.gmatch(stags, "%w+") do 
		local name,value = string.sub(tag,1,3),string.sub(tag,4)
		if name == "WMC" then
		  terminal.SetJsonValue("CONFIG","MCC",value)
		elseif name == "WTC" then
		  terminal.SetJsonValue("CONFIG","TCC",value)
		elseif name == "WKR" then
		  terminal.FileRemove(string.sub(value,10).."."..string.sub(value,-2))
		end
	end
  end
end

function settledate_update(fld15,amt_in,cardname_in)
	if config.settledate == "" then config.settledate = fld15;terminal.SetJsonValue("CONFIG","SETTLEDATE",fld15) end
	if config.settledate == fld15 then return false end
	txn.newbatch_updating = true
	terminal.FileRemove("PREV_SHFTSTTL")
	terminal.FileRename("SHFTSTTL","PREV_SHFTSTTL")
	local safmin,safmax= terminal.GetArrayRange("SAF")
	for i=safmin-1,safmax-1 do
		local amt,cardname = "0",""
		if i == safmin-1 then amt,cardname = amt_in,cardname_in
		else amt,cardname = terminal.GetJsonValue("SAF"..i,"4","CARDNAME") end
		if amt and cardname then
			local cr_s_num,cr_s_amt,card_prch_num,card_prch_amt=
			terminal.GetJsonValueInt("SHFTSTTL","CR_PRCHNUM","CR_PRCHAMT",cardname.."_PRCHNUM",cardname.."_PRCHAMT")
			local namt = tonumber(amt)
			terminal.SetJsonValue("SHFTSTTL",cardname.."_PRCHAMT",card_prch_amt+namt)
			terminal.SetJsonValue("SHFTSTTL",cardname.."_PRCHNUM",card_prch_num+1)
			terminal.SetJsonValue("SHFTSTTL","CR_PRCHAMT",cr_s_amt+namt)
			terminal.SetJsonValue("SHFTSTTL","CR_PRCHNUM",cr_s_num+1)
		end
	end
	do_obj_saf_rev_start()
	if config.safsign then 
		local timestr = terminal.Time( "DD/MM/YY hh:mm" )
		local prtvalue = "\\H\\CMERCHANT COPY\\n\\n" ..
                  "\\C**SAF PENDING***" .. "\\n" ..
				  "\\C**PLEASE CLEAN**" .. "\\n" ..
                  "TERMINAL ID:\\R" .. config.tid .."\\n" ..
                  "DATE/TIME:\\R" .. timestr .. "\\n"
		terminal.Print(prtvalue,true)
		return false 
	else
		terminal.SetJsonValue("CONFIG","SETTLEDATE",fld15)
		config.settledate = fld15
		return true
	end
end

function sessionkey_update(fld48)
    local key_kek1,key_kek2,key_kdr,key_kds,key_kmacr,key_kmacs,key_pin,key_ppasn = terminal.GetJsonValue("IRIS_CFG","KEK1","KEK2","KDr","KDs","KMACr","KMACs","KPE","PPASN")
    local key_ind = string.sub(fld48, 1, 2 )
    local emacs,edatas,emacr,epin,edatar
    local ok = false

    emacr = string.sub(fld48,3,34)
    edatar = string.sub(fld48,35,66)
    emacs = string.sub(fld48,67,98)
    epin = string.sub(fld48,99,130)
    edatas = string.sub(fld48,131,162)
    if key_ind == "31" then
      ok = terminal.Owf(key_ppasn,key_kek1,key_kek1,0)
    elseif key_ind == "32" then
      ok = terminal.Owf(key_ppasn,key_kek1,key_kek2,1)
      ok = terminal.Owf(key_ppasn,key_kek2,key_kek2,0)
    end
    ok = ok and terminal.Derive3Des( emacr,"24C0",key_kmacr,key_kek1)
    ok = ok and terminal.Derive3Des( edatar,"22C0",key_kdr,key_kek1)
    ok = ok and terminal.Derive3Des( emacs,"48C0",key_kmacs,key_kek1)
    ok = ok and terminal.Derive3Des( epin,"42C0",key_pin,key_kek1)
    ok = ok and terminal.Derive3Des( edatas,"44C0",key_kds,key_kek1)
    return ok
end

function do_obj_shft_reset()
  local scrlines = "WIDELBL,,37,4,C;" .. "WIDELBL,,26,6,C;"
  local screvent,scrinput = terminal.DisplayObject(scrlines,0,0,0)
  local doubleh=""
  local prtvalue=""
  if ecrd.HEADER then prtvalue = ecrd.HEADER else doubleh = "\\h" end
  local mytime1,mytime2=terminal.Time("DD/MM/YY"),terminal.Time("DD/MM/YY           hh:mm")
  local prchamt,cashamt,tipsamt,rfndamt,prchnum,cashnum,tipsnum,rfndnum= terminal.GetJsonValueInt("SHFT","PRCHAMT","CASHAMT","TIPSAMT","RFNDAMT","PRCHNUM","CASHNUM","TIPSNUM","RFNDNUM")
  prchamt=prchamt/100
  cashamt=cashamt/100
  tipsamt=tipsamt/100
  rfndamt=rfndamt/100
  local value="\\C\\f"..doubleh.."------------------------\\n\\C" ..config.servicename.."\\n"..
    "\\C" .. config.merch_loc0 .."\\n" ..
    "\\C" .. config.merch_loc1 .."\\n\\n" ..
    "MERCHANT ID:\\R"..config.mid.."\\n" ..
    "TERMINAL ID:\\R"..config.tid.."\\n\\n"..
    "SHIFT TOTALS\\R"..mytime1.."\\n"..
    "PURCHASE ".. string.format("%03s",prchnum) .."\\R".. string.format("$%.2f",prchamt).."\\n"..
    "CASH OUT ".. string.format("%03s",cashnum) .."\\R".. string.format("$%.2f",cashamt).."\\n"..
    "TIPS     ".. string.format("%03s",tipsnum) .."\\R".. string.format("$%.2f",tipsamt).."\\n"..
    "REFUND   ".. string.format("%03s",rfndnum) .."\\R".. string.format("$%.2f",rfndamt).."\\n"..
    "   NET\\R" ..string.format("$%.2f",(prchamt+cashamt+tipsamt+rfndamt)) .."\\n\\n" ..
    "APPROVED\\n" ..
    "TOTALS RESET\\n\\n" ..
    mytime2.."\\n" ..
    "------------------------\\n"
    ecrd.BODY = value
	prtvalue = prtvalue .. value ..(ecrd.TRAILER or "") .."\\n"
	terminal.Print(prtvalue,true)
	checkPrint(prtvalue)
    terminal.FileRemove("SHFT")
    return do_obj_txn_finish()
end

function do_obj_txn_finish(nosaf)
  terminal.FileRemove("TXN_REQ")
  terminal.FileRemove("REV_TODO")
  if txn.finishreturn then return txn.finishreturn
  else
    terminal.EmvResetGlobal()
	terminal.TcpDisconnect()
    if txn.chipcard and terminal.EmvIsCardPresent() and not (ecrd and ecrd.RETURN) then
      terminal.EmvPowerOff()
      local scrlines = "WIDELBL,,286,2,C;"
      terminal.DisplayObject(scrlines,0,EVT.SCT_OUT,0)
	end
	local nextstep = ( ecrd.RETURN or do_obj_idle )
	if nosaf or txn.rc == "Y3" or txn.rc == "Z3" or ( txn.tcpsent == false and txn.rc ~= "Y1") or config.safsign and string.find(config.safsign,"+")
		then saf_rev_check(); return nextstep()
    else txn.safonce = true; return do_obj_saf_rev_start(nextstep,"SAF") end
  end
end

function get_emv_print_tags(tagprint)
	if txn.ctls then if not txn.chipcard then return "" end
	else if not ( txn.chipcard and terminal.EmvIsCardPresent()) then return "" end	end
	local prttags = "\\n"
	local f4f,f50,f9f26,f9f27,f9f10,f9f37,f9f36,f9500,f9a00,f9c00,f9f02,f5f2a,f8200,f5a00,f9f1a,f9f34,f9f03,f5f34,f9f33,f9b00,f9f1d,f9f1b,f8e00
	local tac_default,tac_denial,tac_online, iac_default,iac_denial,iac_online
	
	if txn.ctls and txn.chipcard then
			local f9f06 = get_value_from_tlvs("9F06")
			f4f = get_value_from_tlvs("8400")
			if f4f=="" and f9f06~="" then f4f = f9f06 end
			f50 = get_value_from_tlvs("5000")
			f9f26 = get_value_from_tlvs("9F26")
			f9f27 = get_value_from_tlvs("9F27")
			f9f10 = get_value_from_tlvs("9F10")
			f9f37 = get_value_from_tlvs("9F37")
			f9f36 = get_value_from_tlvs("9F36")
			f9500 = get_value_from_tlvs("9500")
			f9a00 = get_value_from_tlvs("9A00")
			f9c00 = get_value_from_tlvs("9C00")
			f9f02 = get_value_from_tlvs("9F02")
			f5f2a = get_value_from_tlvs("5F2A")
			f8200 = get_value_from_tlvs("8200")
			f5a00 = get_value_from_tlvs("5A00")
			f9f1a = get_value_from_tlvs("9F1A")
			f9f34 = get_value_from_tlvs("9F34")
			f9f03 = get_value_from_tlvs("9F03")
			f5f34 = get_value_from_tlvs("5F34")
			f9f33 = get_value_from_tlvs("9F33")
			f9b00 = get_value_from_tlvs("9B00")
			f8e00 = get_value_from_tlvs("8E00")
			tac_default,tac_denial,tac_online= terminal.CTLSEmvGetTac(f4f)

			iac_default = get_value_from_tlvs("9F0D")
			iac_denial = get_value_from_tlvs("9F0E")
			iac_online = get_value_from_tlvs("9F0F")

	else
		f4f,f50,f9f26,f9f27,f9f10,f9f37,f9f36,f9500,f9a00,f9c00,f9f02,f5f2a,f8200,f5a00,f9f1a,f9f34,f9f03,f5f34,f9f33,f9b00,f9f1d,f9f1b,f8e00 =
			terminal.EmvGetTagData(0x4F00,0x5000,0x9F26,0x9F27,0x9F10,0x9F37,0x9F36,0x9500,0x9A00,0x9C00,0x9F02,0x5F2A,0x8200,0x5A00,0x9F1A,0x9F34,0x9F03,0x5F34,0x9F33,0x9B00,0x9F1D,0x9F1B,0x8E00) 
		tac_default,tac_denial,tac_online, iac_default,iac_denial,iac_online = terminal.EmvGetTacIac()
	end

	local i9f03 = ( f9f03 == "" and 0 or tonumber(f9f03))
	local i9f02 = ( f9f02 == "" and 0 or tonumber(f9f02))
	local pan = f5a00 and string.match(f5a00,"%d+") or ""
	pan = pan and #pan>0 and (string.rep("*",#pan - 4 ) .. string.sub(pan,-4)) or ""
	prttags = prttags.."AID:\\R"..f4f.."\\n".." \\R"..terminal.StringToHex(f50,#f50).."\\n"
	 ..(f9f27=="80" and "ARQC" or f9f27=="40" and "TC" or "AAC") ..":\\R".. f9f26.."\\n"
	 .."CID:\\R".. f9f27.."\\n"
	 .."IAD:\\R".. f9f10.."\\n"
	 .."UN:\\R".. f9f37.."\\n"
	 .."ATC:\\R".. f9f36.."\\n"
	 .."TVR:\\R".. f9500.."\\n"
	 .."TSI:\\R".. f9b00.."\\n"
	 .."TD:\\R".. f9a00.."\\n"
	 .."TT:\\R".. f9c00.."\\n"
	 .."Amount:\\R".. string.format("$%.2f",i9f02/100).."\\n"
	 .."TCuC:\\R".. f5f2a.."\\n"
	 .."AIP:\\R".. f8200.."\\n"
	 .."PAN:\\R".. pan.."\\n"
	 .."TCC:\\R".. f9f1a.."\\n"
	 .."CVMR:\\R".. f9f34.."\\n"
	 .."OthAmt:\\R".. string.format("$%.2f",i9f03/100).."\\n"
	 .."PANSeq:\\R".. f5f34.."\\n"
	 .."FloorLmt:\\R".. (f9f1b or " ").."\\n"
	 .."TermCap:\\R".. (f9f33 or " ").."\\n"
	 .."CVMRule:\\R".. (f8e00 or " ").."\\n"
	 .."    Issuer     Terminal\\n"
	 .."Dn "..(iac_denial==""  and "          " or iac_denial).." ".. (tac_denial or "") .."\\n"
	 .."On "..(iac_online==""  and "          " or iac_online).." ".. (tac_online or "").."\\n"
	 .."Df "..(iac_default=="" and "          " or iac_default).." "..(tac_default or "").."\\n"
	return(prttags)
end

function get_ipay_print_nok(who,result_str)
  local cardinfo1,cardinfo2 = "",""
  local s_pan = txn.fullpan and ( string.rep(".",10) .. string.sub(txn.fullpan,-4)) or nil
  local cardentry = ""
  if txn.pan then cardentry = "(M)"
  elseif txn.ctls then cardentry = "(T)"
  elseif txn.chipcard and txn.emv.fallback then cardentry = "(F)"
  elseif txn.chipcard then cardentry = "(C)"
  elseif txn.track2 then cardentry = "(S)"
  end
  cardinfo1 = s_pan and ("\\C"..( txn.cardname and txn.cardname or "") .. "\\n\\C" .. s_pan .. " " .. cardentry .."\\n" ) or ""

  local prttags = ""
  if txn.rc == "Z1" or txn.rc == "Z3" or txn.rc == "Z4" then
	prttags = txn.emvprint
  elseif txn.chipcard and not txn.emv.fallback and not txn.earlyemv then
	local pds4f,pds50,pds9f26,pds9f12 
	if txn.ctls then
		pds4f,pds50,pds9f26,pds9f12 = get_value_from_tlvs("8400"),get_value_from_tlvs("5000"),get_value_from_tlvs("9F26"),get_value_from_tlvs("9F12")
		if pds4f == "" then pds4f = get_value_from_tlvs("9F06") end
	else
		pds4f,pds50,pds9f26,pds9f12 = terminal.EmvGetTagData(0x4F00,0x5000,0x9F26,0x9F12)
	end
	local cname = ( pds9f12 ~= "" ) and pds9f12 or pds50 
	cname = terminal.StringToHex(cname,#cname)
	cname = string.gsub( cname, "%s+$", "")
	prttags = "AID:\\R"..pds4f.."\\n".." \\R"..cname.."\\n".."AAC:\\R "..pds9f26.."\\n"
  end

  cardinfo2 = prttags

  local func,s_amt = "",""
  local amt = txn.prchamt or 0
  if txn.moto and txn.poscc == "08" then func = "MAIL/PHONE"
  elseif txn.moto and txn.poscc == "59" then func = "E-COMMERCE"
  elseif txn.func =="PRCH" then func = (txn.cashamt and txn.cashamt>0 and "PUR/CASH" or "PURCHASE")
  else func = txn.func
  end

  if txn.prchamt and txn.prchamt>0 then	s_amt = "AMOUNT\\R"..string.format("$%.2f",amt/100) .."\\n"  end
  if txn.totalamt then	s_amt = s_amt .. " \\R---------\\n".. "TOTAL AUD \\R" .. string.format("$%.2f",txn.totalamt/100).. "\\n\\n"  end

  local acc = txn.account and ( "\\4ACCT TYPE:\\R" .. txn.account.. "\\n" ) or ""
  local stan = ""
  if not txn.tcpsent or (txn.offline and txn.rc and txn.rc ~="Z3") or txn.func == "COMP" or ( txn.rc and ( txn.rc == "Y1" or txn.rc == "Y3")) then stan = ""
  else stan =  "BANK REF:\\R"..config.stan.."\\n" end

  local prtvalue = "\\4------------------------------------------\\n" ..
    "\\C\\F" ..( ecrd.HEADER and "" or "\\H") .. who ..
    "\\C\\f" ..( ecrd.HEADER and "" or "\\H") .. config.servicename .."\\n" ..
    "\\C" .. config.merch_loc0 .."\\n" ..
    "\\C" .. config.merch_loc1 .."\\n" ..
    cardinfo1 ..
	acc..
	"TRANS TYPE:\\R" .. func.. "\\n"..
    "TERMINAL ID:\\R" .. config.tid .. "\\n" ..
	(txn.totalamt and ("INV/ROC NO:\\R"..config.roc .."\\n") or "" )..
	stan..
	"DATE/TIME:\\R".. terminal.Time( "DD/MM/YY hh:mm" ) .."\\n"..
	cardinfo2 .. "\\n"..
	s_amt ..
    "\\H".. result_str ..
    "\\4------------------------------------------\\n"
  return prtvalue
end

function get_ipay_print(who,result_ok,result_str)
  local is_merch = ( #who > 8 and (string.sub( who,1,8) == "MERCHANT"))
  local card_exp = ""
  local cardinfo1,cardinfo2 = "",""
  if txn.orig_txnfile then --void or comp/retrieve
    cardinfo1,cardinfo2 = terminal.GetJsonValue( txn.orig_txnfile,"CARDINFO1","CARDINFO2")
  else
	local fullpan = false --(( txn.rc == "Y1" or txn.rc == "Y3" or txn.func == "AUTH" ) and is_merch )
	local s_pan = txn.fullpan and ( fullpan and txn.fullpan or string.rep(".",10) .. string.sub(txn.fullpan,-4)) or ""
	local cardentry = ""
	if txn.pan then cardentry = "(M)"
	elseif txn.ctls then cardentry = "(T)"
	elseif txn.chipcard and txn.emv.fallback then cardentry = "(F)"
	elseif txn.chipcard then cardentry = "(C)"
	elseif txn.track2 then cardentry = "(S)"
	end

	if fullpan then
		local expirydate = ""
		if txn.expiry then expirydate = string.sub(txn.expiry,1,2) .."/" .. string.sub(txn.expiry,3,4)
		elseif txn.track2 then
		  local _,_,_,trk2 = string.find(txn.track2, "(%d*)=(%d*)")
		  expirydate = (trk2 and string.sub(trk2,3,4) .."/" .. string.sub(trk2,1,2) or "")
		elseif txn.chipcard then
		  local f5f24 = terminal.EmvGetTagData(0x5F24)
		  expirydate = (#f5f24>4 and string.sub(f5f24,3,4) .."/" .. string.sub(f5f24,1,2) or "")
		end
		card_exp = ( #expirydate >=4 and "EXPIRY DATE(MM/YY):\\R"..expirydate .."\\n" or "")
	end
	local prt_emv = ""
	if txn.chipcard and not txn.emv.fallback and not txn.earlyemv then
		local pds4f,pds50,pds9f26,pds9f27,pds9f12 
		if txn.ctls then
		  pds4f,pds50,pds9f26,pds9f27,pds9f12 = get_value_from_tlvs("8400"),get_value_from_tlvs("5000"),get_value_from_tlvs("9F26"),get_value_from_tlvs("9F27"),get_value_from_tlvs("9F12")
		  if pds4f == "" then pds4f = get_value_from_tlvs("9F06") end
		else
		  pds4f,pds50,pds9f26,pds9f27,pds9f12 = terminal.EmvGetTagData(0x4F00,0x5000,0x9F26,0x9F27,0x9F12)
		end
		local cname = ( pds9f12 ~= "" ) and pds9f12 or pds50 
		cname = terminal.StringToHex(cname,#cname)
		cname = string.gsub( cname, "%s+$", "")
		local label_9f26 = (pds9f27 == "40" and "TC" or pds9f27 == "80" and "ARQC" or "AAC")  
		prt_emv = "AID:\\R"..pds4f.."\\n".." \\R"..cname.."\\n"..label_9f26..":\\R "..pds9f26.."\\n"
	end
	cardinfo1 = "\\C"..txn.cardname .. "\\n\\C" .. s_pan .. " " .. cardentry .."\\n" 
	local keep_cardinfo1 = "\\C"..txn.cardname .. "\\n\\C" .. string.rep(".",10) .. string.sub(s_pan,-4) .. " " .. cardentry .."\\n\\n" 
	terminal.SetJsonValue("TXN_REQ","CARDINFO1",keep_cardinfo1)
	terminal.SetJsonValue("TXN_REQ","CARDNAME",txn.cardname)
	cardinfo2 = prt_emv
	terminal.SetJsonValue("TXN_REQ","CARDINFO2",cardinfo2)
  end
  local func,s_amt,amt = "","",txn.prchamt
  if txn.moto and txn.poscc == "08" then func = "MAIL/PHONE"
  elseif txn.moto and txn.poscc == "59" then func = "E-COMMERCE"
  elseif txn.func =="PRCH" then func = "PURCHASE"
  else func = txn.func
  end
  local authstr = ""
  if result_ok and txn.authid and #txn.authid > 0 then authstr = "AUTH ID:\\R"..txn.authid.."\\n" end
  if txn.prchamt and txn.prchamt>0 then	s_amt = "AMOUNT\\R"..string.format("$%.2f",amt/100) .."\\n"   end
  s_amt = s_amt .. " \\R---------\\n".. ( "TOTAL AUD \\R" .. string.format("$%.2f",txn.totalamt/100)).. "\\n\\n" 
  local stan = ""
  if not txn.tcpsent or txn.offline or ( txn.rc and ( txn.rc == "Y1" or txn.rc == "Y3")) then stan = ""
  else stan =  "BANK REF:\\R"..config.stan.."\\n" end
  
  local banktime = txn.time and string.len(txn.time)==14 and ( "\\3BANK TIME:\\R"..string.sub(txn.time,7,8).."/"..string.sub(txn.time,5,6).."/"..string.sub(txn.time,3,4).." "..string.sub(txn.time,9,10)..":"..string.sub(txn.time,11,12).."\\n") or "\\n"

  local prtvalue = "\\4------------------------------------------\\n" ..
    "\\C\\F" ..( ecrd.HEADER and "" or "\\H") .. who ..
    "\\C\\f" ..( ecrd.HEADER and "" or "\\H") .. config.servicename .."\\n" ..
    "\\C" .. config.merch_loc0 .."\\n" ..
    "\\C" .. config.merch_loc1 .."\\n" ..
    cardinfo1 ..
	"\\4ACCT TYPE:\\R" .. txn.account.. "\\n"..
	"TRANS TYPE:\\R" .. func.. "\\n"..
    "TERMINAL ID:\\R" .. config.tid .. "\\n" ..
	"INV/ROC NO:\\R"..config.roc.."\\n"..
	stan ..
	"DATE/TIME:\\R".. terminal.Time( "DD/MM/YY hh:mm" ) .."\\n"..
    card_exp ..
	cardinfo2 .."\\n"..
	s_amt ..
    authstr..
    "\\H".. result_str ..
	banktime..
    "\\4------------------------------------------\\n"
  return prtvalue
end

function get_next_id(idtype)
  if idtype == "ROC" then
	if config.roc == nil or config.roc == "" or tonumber(config.roc) >= 999999 then config.roc = "000001"
	else config.roc = string.format("%06d",tonumber(config.roc) + 1) end
	terminal.SetJsonValue("CONFIG","ROC",config.roc)
	return config.roc
  elseif idtype == "STAN" then
    if config.stan == nil or config.stan == "" or tonumber(config.stan) >= 999999 then config.stan = "000001"
	else config.stan = string.format("%06d",tonumber(config.stan) + 1) end
	terminal.SetJsonValue("CONFIG","STAN",config.stan)
	return config.stan
  elseif idtype == "BATCHNO" then
	local batchno = terminal.GetJsonValue("CONFIG","BATCHNO")
    if batchno == "" or batchno == "999999" then batchno = "000001" else batchno = string.format("%06d", tonumber(batchno)+1) end
    terminal.SetJsonValue("CONFIG","BATCHNO", batchno)
	return batchno
  else
    return 0
  end
end

function funckeymenu()
  local scrlines = ",,40,2,C;" .. "LHIDDEN,,0,5,17,8;"					   
  local screvent,scrinput = terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,30000)

  if screvent == "KEY_CLR" or screvent == "CANCEL" or screvent=="TIME" then
    return do_obj_txn_finish()
  elseif screvent == "KEY_OK" then
    require ("WBCCONFIG")
    if scrinput == "7410" then
      return do_obj_termconfig()
    elseif scrinput == "3824" then
      return do_obj_termconfig_maintain()
    elseif scrinput == "5295" then
	  if config.tid == "" or config.mid == "" then
			local scrlines = "WIDELBL,,51,2,C;" .. "WIDELBL,,53,4,C;"
			terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,30000)
			return do_obj_txn_finish()
      else return do_obj_logon_init() end
    elseif scrinput == "5296" then
	  terminal.SetJsonValue("CONFIG","LOGON_STATUS","195")
	  config.logonstatus = "195"
      return do_obj_logon_init()
    elseif scrinput == "5297" then
	  config.msgenc = "2"
      return do_obj_logon_init()
    elseif scrinput == "5298" then
	  terminal.SetJsonValue("CONFIG","LOGON_STATUS","194")
	  config.logonstatus = "194"
	  return do_obj_logon_init()
    elseif scrinput == "00100100" then
      return do_obj_swdownload()
    elseif scrinput == "37" then
		local scrlines = "WIDELBL,THIS,DEBUG PRINT,2,C;".."WIDELBL,THIS,"..(config.debugemv and "DISABLE" or "ENABLE").."?,3,C;"
		local screvent = terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,30000)
		if screvent == "KEY_OK" then config.debugemv = not config.debugemv end
		return do_obj_txn_finish()
    elseif scrinput == "5620" then
	  return do_obj_clear_saf()
    elseif scrinput == "5628" then
	  return do_obj_upload_saf()
    elseif scrinput == "3701" then
	  terminal.CTLSEmvGetCfg()
	  return do_obj_txn_finish()
    elseif scrinput == "00200200" then
	  return do_obj_txn_reset_memory()
    else return do_obj_check_pswd(scrinput)
    end
  end
end

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

function do_obj_clear_saf()
	local screvent=""
	local revmin,revmax= terminal.GetArrayRange("REVERSAL")
	local safmin,safmax= terminal.GetArrayRange("SAF")
	if revmax == revmin and safmax == safmin then 
		local scrlines = "WIDELBL,THIS,REVERSAL/SAF,2,C;" .. "WIDELBL,THIS,EMPTY,3,C;"
		screvent,_ = terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,30000)
		return do_obj_txn_finish(true)
	else
		local fname = "REVERSAL"
		for i=revmin,revmax-1 do
		  if terminal.FileExist(fname..i) then
			local roc = terminal.GetJsonValue(fname..i,"62")
			roc = terminal.StringToHex(roc,#roc)
			local scrlines = "WIDELBL,THIS,DELETE REVERSAL?,2,C;" .. "WIDELBL,THIS,ROC/INV:"..roc..",3,C;".."BUTTONS_YES,THIS,YES,B,10;" .."BUTTONS_NO,THIS,NO,B,33;" 
			screvent,_ = terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,30000)
			if screvent == "BUTTONS_YES" or screvent == "KEY_OK" then terminal.FileRemove(fname .. i); terminal.SetArrayRange(fname, i+1, "") end 
			break
		  end
		end

		if screvent == "" then
		  local fname = "SAF"
		  for i=safmin,safmax-1 do
			if terminal.FileExist(fname..i) then
				local roc = terminal.GetJsonValue(fname..i,"62")
				roc = terminal.StringToHex(roc,#roc)
				local scrlines = "WIDELBL,THIS,DELETE SAF?,2,C;" .. "WIDELBL,THIS,ROC/INV:"..roc..",3,C;".."BUTTONS_YES,THIS,YES,B,10;" .."BUTTONS_NO,THIS,NO,B,33;"
				screvent,_ = terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,30000)
				if screvent == "BUTTONS_YES" or screvent == "KEY_OK" then terminal.FileRemove(fname .. i); terminal.SetArrayRange(fname, i+1, "") end 
				break
			end
		  end
		end
		saf_rev_check()
		return do_obj_txn_finish(true)
	end
end

function do_obj_upload_saf()
  local scrlines = "WIDELBL,THIS,UPLOAD ,2,C;" .. "WIDELBL,THIS,REVERSAL/SAF,3,C;".."BUTTONS_YES,THIS,YES,B,10;"  .."BUTTONS_NO,THIS,NO,B,33;"
  local screvent = terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,30000)
  if screvent == "BUTTONS_YES" or screvent == "KEY_OK" then return do_obj_saf_rev_start(do_obj_txn_finish)
  else return do_obj_txn_finish(true) end
end

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

function get_value_from_tlvs(tag,tlvs_s)
	local value = ""
	if not txn.TLVs and not tlvs_s then return "" end
	local tlvs = tlvs_s or txn.TLVs
	if not txn.TLVs_table then
		txn.TLVs_table = {}
		local idx = 1
		local tlen = 0
		while idx < #tlvs do
			local chktag = string.sub(tlvs,idx,idx+3)
			idx = idx + 4
			if chktag == "LEN6" then
				chktag = string.sub(tlvs,idx,idx+5)
				idx = idx + 6
			end
			tlen = tonumber( "0x"..( string.sub(tlvs,idx,idx+1) or "00"))
			idx = idx + 2
			value = string.sub(tlvs,idx,idx+tlen*2-1)
			idx = idx + tlen*2
			txn.TLVs_table[ chktag ] = value
		end
	end
	
	value = txn.TLVs_table [ tag ]
	if not value then value = "" end
	return value
end

function checkPrint(prtvalue)
  while true do
	local prtok = terminal.PrinterStatus()
	if prtok == "OK" then return 
	else
		local scrlines = "WIDELBL,THIS,PRINTER ERROR,2,C;" .. "WIDELBL,THIS,"..prtok..",3,C;" .."BUTTONS_Y,THIS,RETRY ,B,4;".."BUTTONS_N,THIS,CANCEL,B,33;"
		local screvent,_ = terminal.DisplayObject(scrlines,KEY.FUNC,0,0)
		if screvent == "BUTTONS_Y" then terminal.Print(prtvalue,true)
		elseif screvent == "KEY_FUNC" then
			local slen = 1
			prtvalue = string.gsub(prtvalue,"\\n","\n")
			prtvalue = string.gsub(prtvalue,"\n+","\n")
			prtvalue = string.gsub(prtvalue,"\\.","")
			prtvalue = string.gsub(prtvalue,"-----------","")
			while slen <=#prtvalue do terminal.DebugDisp(string.sub(prtvalue,slen,slen+240)); slen=slen+241 end
			return
		else return end
	end
  end
end

function do_obj_gprs_register(nextfunc)
  local scrlines = "WIDELBL,,228,4,C;" .. "WIDELBL,THIS,"..config.apn..",6,C;"
  local screvent,scrinput = terminal.DisplayObject(scrlines,0,0,0)
  local retmsg = tcpconnect()
  scrlines = "WIDELBL,,228,3,C;" .. "WIDELBL,THIS,"..config.apn..",4,C;"
  if retmsg == "NOERROR" then
    scrlines = scrlines .. "WIDELBL,THIS,SUCCESS!!,6,C;"
  else
    terminal.ErrorBeep()
    scrlines = scrlines .. "WIDELBL,THIS,FAILED!!,6,C;"
	scrlines = scrlines .. "WIDELBL,THIS,"..retmsg..",8,C;"
  end
  terminal.DisplayObject(scrlines,0,EVT.TIMEOUT,ScrnTimeoutHF)
  if nextfunc then return nextfunc() else return 0 end
end

function swipecheck(track2)
  if track2 == nil or #track2 < 11 or callback.mcr_func == nil then terminal.ErrorBeep(); return -1 end

  local _,_,pan,panetc = string.find(track2, "(%d*)=(%d*)")
  if not (pan and #pan > 11) then 
		terminal.ErrorBeep()
  		local scrlines1 = "WIDELBL,THIS,TRAN CANCELLED,2,C;" .. "WIDELBL,THIS,CARD NOT SUPPORTED,4,C;"
		terminal.DisplayObject(scrlines1,KEY.CNCL,EVT.TIMEOUT,ScrnErrTimeout)
		return -1
  end

  local expirydate = (panetc and string.sub(panetc,1,4) or "")
  local currmonth = terminal.Time( "YYMM") 
  if expirydate ~= "" and tonumber(currmonth) > tonumber(expirydate) then
		terminal.ErrorBeep()
		local scrlines1 = "WIDELBL,THIS,TRAN CANCELLED,2,C;" .. "WIDELBL,THIS,CARD EXPIRED,4,C;"
		terminal.DisplayObject(scrlines1,KEY.CNCL,EVT.TIMEOUT,ScrnErrTimeout)
		return -1
  end

  local cardname_prefix,_,_ = terminal.LocateCpat("CPAT_ALL",string.sub(pan,1,6))
  if #cardname_prefix < 2 then 
		terminal.ErrorBeep()
  		local scrlines1 = "WIDELBL,THIS,TRAN CANCELLED,2,C;" .. "WIDELBL,THIS,CARD NOT SUPPORTED,4,C;"
		terminal.DisplayObject(scrlines1,KEY.CNCL,EVT.TIMEOUT,ScrnErrTimeout)
		return -1
  end

  if #cardname_prefix > 2 then cardname_prefix = string.sub(cardname_prefix,-2) end
  local cardname = terminal.TextTable("CARD_NAME",cardname_prefix)

  local chipflag = (panetc and string.sub(panetc,5,5) or "")
  if chipflag == "2" or chipflag == "6" then		
      terminal.ErrorBeep(); return 0 
  end

  return 1,cardname
end

function bit(p)
  return 2^(p-1)
end
function hasbit(x,p)
  return x%(p+p)>=p
end

function debugPrint(msg)
	local maxlen = #msg
	local idx = 1
	if not maxlen or maxlen ==0 then return end
	while true do
		terminal.Print("\\4"..string.sub(msg, idx, idx+125).."\\n", false)
		idx = idx + 126
		if idx > maxlen then break end
	end
	terminal.Print("\\n", true)
end


callback.func_func = funckeymenu
if not callback.chip_func then callback.chip_func = do_obj_wbc_mcr_chip end
if not callback.mcr_func then callback.mcr_func = do_obj_wbc_mcr_chip end
if terminal.FileExist("REV_TODO") then
  local revmin,revnext = terminal.GetArrayRange("REVERSAL")
  local revfile = "REVERSAL"..revnext
  terminal.FileCopy( "REV_TODO", revfile)
  terminal.SetArrayRange("REVERSAL","",revnext+1)
  terminal.FileRemove("REV_TODO")
end
config.msgenc = "2"
saf_rev_check()

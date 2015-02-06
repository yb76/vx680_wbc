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
				txn.tcperror = true
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

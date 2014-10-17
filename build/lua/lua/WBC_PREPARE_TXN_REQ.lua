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
	local cvmr = (txn.ctls == "CTLS_E" and get_value_from_tlvs("9F34")) or not txn.earlyemv and not txn.emv.fallback and not txn.ctls and terminal.EmvGetTagData(0x9f34)
	
	if txn.moto then wcv = "1"
	elseif cvmr then
		local cvmr1,cvm3 = string.sub(cvmr,2,2),string.sub(cvmr,5,6)
		if cvm3=="02" and (cvmr1 == "1" or cvmr1 == "3" or cvmr1 == "4" or cvmr1 == "5") then
			txn.offlinepin = true ; wcv = "3"
		elseif cvm3=="02" and (cvmr1 == "F") then
			wcv = "6"
		elseif cvm3=="02" and (cvmr1 == "E") then
			wcv = "1"
		elseif cvm1=="2" and txn.pinblock and #txn.pinblock > 0 then wcv = "2"
		end
	elseif txn.pinblock and #txn.pinblock > 0 then wcv = "2"
	end

	fld47 = fld47 .."WCV"..wcv.."\\"
    if txn.chipcard and txn.emv.fallback and posentry == "801" then fld47 = fld47 .."FCR\\" end
	terminal.DebugDisp("boyang fld47 = ".. fld47)
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
			if tagvalue == "" then tagvalue = "000000000000" end -- TEST
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

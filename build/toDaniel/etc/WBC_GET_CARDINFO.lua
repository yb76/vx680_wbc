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
			local signflag = hasbit(tag9f6c_1,bit(7)) or (txn.totalamt >= txn.cvmlimit and EMV9F6C =="")
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

function get_emv_print_tags(tagprint)
	if txn.ctls then if not txn.chipcard then return "" end
	else if not ( txn.chipcard and terminal.EmvIsCardPresent()) then return "" end	end
	local prttags = "\\n"
	local f4f,f50,f9f26,f9f27,f9f10,f9f37,f9f36,f9500,f9a00,f9c00,f9f02,f5f2a,f8200,f5a00,f9f1a,f9f34,f9f03,f5f34,f9f33,f9b00,f9f1d
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

			tac_default,tac_denial,tac_online= terminal.CTLSEmvGetTac(f4f)

			iac_default = get_value_from_tlvs("9F0D")
			iac_denial = get_value_from_tlvs("9F0E")
			iac_online = get_value_from_tlvs("9F0F")

	else
		f4f,f50,f9f26,f9f27,f9f10,f9f37,f9f36,f9500,f9a00,f9c00,f9f02,f5f2a,f8200,f5a00,f9f1a,f9f34,f9f03,f5f34,f9f33,f9b00,f9f1d =
			terminal.EmvGetTagData(0x4F00,0x5000,0x9F26,0x9F27,0x9F10,0x9F37,0x9F36,0x9500,0x9A00,0x9C00,0x9F02,0x5F2A,0x8200,0x5A00,0x9F1A,0x9F34,0x9F03,0x5F34,0x9F33,0x9B00,0x9F1D) 
		tac_default,tac_denial,tac_online, iac_default,iac_denial,iac_online = terminal.EmvGetTacIac()
	end

	local i9f03 = ( f9f03 == "" and 0 or tonumber(f9f03))
	local i9f02 = ( f9f02 == "" and 0 or tonumber(f9f02))
	local pan = f5a00 and string.match(f5a00,"%d+") or ""
	pan = pan and #pan>0 and (string.rep("*",#pan - 4 ) .. string.sub(pan,-4)) or ""
	prttags = prttags.."AID:\\R"..f4f.."\\n".." \\R"..terminal.StringToHex(f50,#f50).."\\n"
	prttags = prttags..(tagprint and "AC" or "AAC") ..":\\R".. f9f26.."\\n"
	prttags = prttags.."CID:\\R".. f9f27.."\\n"
	prttags = prttags.."IAD:\\R".. f9f10.."\\n"
	prttags = prttags.."UN:\\R".. f9f37.."\\n"
	prttags = prttags.."ATC:\\R".. f9f36.."\\n"
	prttags = prttags.."TVR:\\R".. f9500.."\\n"
	prttags = prttags.."TSI:\\R".. f9b00.."\\n"
	prttags = prttags.."TD:\\R".. f9a00.."\\n"
	prttags = prttags.."TT:\\R".. f9c00.."\\n"
	prttags = prttags.."Amount:\\R".. string.format("$%.2f",i9f02/100).."\\n"
	prttags = prttags.."TCuC:\\R".. f5f2a.."\\n"
	prttags = prttags.."AIP:\\R".. f8200.."\\n"
	prttags = prttags.."PAN:\\R".. pan.."\\n"
	prttags = prttags.."TCC:\\R".. f9f1a.."\\n"
	prttags = prttags.."CVMR:\\R".. f9f34.."\\n"
	prttags = prttags.."OthAmt:\\R".. string.format("$%.2f",i9f03/100).."\\n"
	prttags = prttags.."PANSeq:\\R".. f5f34.."\\n"
	prttags = prttags.."    Issuer     Terminal\\n"
	prttags = prttags.."Dn "..iac_denial.." "..(tac_denial or "").."\\n"
	prttags = prttags.."On "..iac_online.." "..(tac_online or "").."\\n"
	prttags = prttags.."Df "..iac_default.." "..(tac_default or "").."\\n"
	return(prttags)
end

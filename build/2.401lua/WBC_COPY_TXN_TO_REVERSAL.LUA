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

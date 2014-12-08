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
		--terminal.EmvSetTagData(0x8A00,txn.rc)
		return do_obj_txn_nok(txn.rc)
	end
end

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

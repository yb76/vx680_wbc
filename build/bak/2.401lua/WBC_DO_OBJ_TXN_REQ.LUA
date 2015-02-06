function do_obj_txn_req()
	local as2805msg = prepare_txn_req()
    local retmsg = ""
    if as2805msg == "" then txn.tcperror = true 
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
			else txn.tcperror = true 
				return do_obj_txn_nok(retmsg)
			end
		else return do_obj_txn_resp()
		end
	end
end

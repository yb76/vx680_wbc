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

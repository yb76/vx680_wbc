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

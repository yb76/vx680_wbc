function settledate_update(fld15,amt_in,cardname_in)
	if config.settledate == "" then config.settledate = fld15;terminal.SetJsonValue("CONFIG","SETTLEDATE",fld15) end
	if config.settledate == fld15 then return false end
	txn.newbatch_updating = true
	terminal.FileRemove("PREV_SHFTSTTL")
	terminal.FileRename("SHFTSTTL","PREV_SHFTSTTL")
	local safmin,safmax= terminal.GetArrayRange("SAF")
	for i=safmin-1,safmax-1 do
		local amt,cardname = "0",""
		if i == safmin-1 then amt,cardname = amt_in,cardname_in
		else amt,cardname = terminal.GetJsonValue("SAF"..i,"4","CARDNAME") end
		if amt and cardname then
			local cr_s_num,cr_s_amt,card_prch_num,card_prch_amt=
			terminal.GetJsonValueInt("SHFTSTTL","CR_PRCHNUM","CR_PRCHAMT",cardname.."_PRCHNUM",cardname.."_PRCHAMT")
			local namt = tonumber(amt)
			terminal.SetJsonValue("SHFTSTTL",cardname.."_PRCHAMT",card_prch_amt+namt)
			terminal.SetJsonValue("SHFTSTTL",cardname.."_PRCHNUM",card_prch_num+1)
			terminal.SetJsonValue("SHFTSTTL","CR_PRCHAMT",cr_s_amt+namt)
			terminal.SetJsonValue("SHFTSTTL","CR_PRCHNUM",cr_s_num+1)
		end
	end
	do_obj_saf_rev_start()
	if config.safsign then 
		local timestr = terminal.Time( "DD/MM/YY hh:mm" )
		local prtvalue = "\\H\\CMERCHANT COPY\\n\\n" ..
                  "\\C**SAF PENDING***" .. "\\n" ..
				  "\\C**PLEASE CLEAN**" .. "\\n" ..
                  "TERMINAL ID:\\R" .. config.tid .."\\n" ..
                  "DATE/TIME:\\R" .. timestr .. "\\n"
		terminal.Print(prtvalue,true)
		return false 
	else
		terminal.SetJsonValue("CONFIG","SETTLEDATE",fld15)
		config.settledate = fld15
		return true
	end
end

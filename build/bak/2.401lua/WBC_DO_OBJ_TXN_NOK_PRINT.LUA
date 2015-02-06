function do_obj_txn_nok_print(errcode,errmsg,ret)
	local result_str = "DECLINED\\R"..(errcode or "").."\\n" .. (errmsg or "") .."\\n"
	local amttrans = txn.totalamt and txn.totalamt > 0
	local who = amttrans and "MERCHANT COPY\\n" or ""
	local print_info1 = get_ipay_print_nok(who,result_str)
	local prtvalue = (ecrd.HEADER or "") ..print_info1.. (ecrd.MTRAILER or "") .."\\n"
    terminal.Print(prtvalue,true)
	checkPrint(prtvalue)
	if amttrans then
		local scrlines = "WIDELBL,,36,4,C;" .."BUTTONS_1,THIS,YES,8,10;".. "BUTTONS_2,THIS,NO,8,33;"
		local screvent = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL+KEY.CLR,EVT.TIMEOUT,30000)
		who = "CUSTOMER COPY\\n"
		local print_info2 = get_ipay_print_nok(who,result_str)
		if screvent == "BUTTONS_1" or screvent == "KEY_OK" then
			scrlines = "WIDELBL,,37,2,C;" .."WIDELBL,,26,3,C;"
			terminal.DisplayObject(scrlines,0,0,0)
			prtvalue = (ecrd.HEADER or "") ..print_info2.. (ecrd.MTRAILER or "") .."\\n"
			terminal.Print(prtvalue,true)
			checkPrint(prtvalue)
		end
		local rcptfile = "TAXI_Dclnd"
		local data = "{TYPE:DATA,NAME:"..rcptfile..",GROUP:CBA,VERSION:2.0,HEADER:".. ecrd.HEADER..",CRCPT:"..print_info2..",MRECEIPT:"..print_info1..",TRAILER:"..ecrd.MTRAILER.."}"
		terminal.NewObject(rcptfile,data)
	end
	if ret then return ret else return do_obj_txn_finish() end
end

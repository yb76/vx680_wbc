function do_obj_txn_sig()
  local scrlines = "WIDELBL,,33,3,C;" .."BUTTONS_1,THIS,YES,8,10;".. "BUTTONS_2,THIS,NO,8,33;"
  if txn.chipcard and terminal.EmvIsCardPresent() then
  	local scrlines_card = "WIDELBL,THIS,REMOVE CARD,2,C;".."WIDELBL,THIS,CHECK SIGNATURE,3,C;"
	terminal.DisplayObject(scrlines_card,0,EVT.SCT_OUT+EVT.TIMEOUT,15000)
  end
  local screvent = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL,EVT.TIMEOUT,120000)
  if screvent =="BUTTONS_1" or screvent =="KEY_OK" or screvent =="TIME" then
    return true
  elseif screvent =="BUTTONS_2" or screvent=="CANCEL" then
	  local scrlines = "WIDELBL,THIS,WARNING,2,C;" .."TEXT,THIS,YOU ARE ABOUT TO,4,C;"..
	  "TEXT,THIS,DECLINE THIS FARE.,5,C;".."TEXT,THIS,DO YOU WANT TO,6,C;".."TEXT,THIS,CANCEL PAYMENT,7,C;".."BUTTONS_1,THIS,YES,10,10;".. "BUTTONS_2,THIS,NO,10,33;"
	  local screvent,_ = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL,EVT.TIMEOUT,300000)
	  if screvent == "BUTTONS_1" or screvent == "KEY_OK" or screvent == "TIME"  then
		if txn.tcpsent then
			local safmin,safnext = terminal.GetArrayRange("REVERSAL")
			local saffile = "REVERSAL"..safnext
			local ret = terminal.FileCopy( "TXN_REQ", saffile)
			terminal.SetJsonValue(saffile,"0","400")
			if txn.cardname == "VISA" and  txn.emv.tlv and #txn.emv.tlv > 0 then 
				local newtlv = txn.emv.tlv .. terminal.EmvPackTLV("8A009F5B")
				terminal.SetJsonValue(saffile,"55",newtlv)
			end
			terminal.SetArrayRange("REVERSAL","",safnext+1)
		end
		if txn.saf_generated then
			local safmin,safnext = terminal.GetArrayRange("SAF")
			terminal.FileRemove("SAF"..(safnext-1))
			terminal.SetArrayRange("SAF","",safnext-1)
		end
		txn.rc = "T8"
		local resultstr= "DECLINED\\RSA\\nSIGNATURE MISMATCH\\n\\n"
		local who = "MERCHANT COPY\\n"
		local prtvalue = (ecrd.HEADER or "") .. get_ipay_print( who, false, resultstr)..(ecrd.MTRAILER or "") .."\\n"
		terminal.Print(prtvalue,true)
		checkPrint(prtvalue)
		local scrlines = "WIDELBL,,36,4,C;" .."BUTTONS_1,THIS,YES,8,10;".. "BUTTONS_2,THIS,NO,8,33;"
		local screvent = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL+KEY.CLR,EVT.TIMEOUT,30000)
		who = "CUSTOMER COPY\\n"
		local prtvalue2 = (ecrd.HEADER or "") .. get_ipay_print( who, false, resultstr)..(ecrd.MTRAILER or "") .."\\n"
		if screvent == "BUTTONS_1" or screvent == "TIME" or screvent == "KEY_OK" then
			terminal.Print(prtvalue2,true)
			checkPrint(prtvalue2)
		end
	
		local rcptfile = "TAXI_Dclnd"
		local data = "{TYPE:DATA,NAME:"..rcptfile..",GROUP:CBA,VERSION:2.0,HEADER:".. (ecrd.HEADER or "")..",CRCPT:"..prtvalue2..",MRECEIPT:"..prtvalue..",TRAILER:"..(ecrd.MTRAILER or "").."}"
		terminal.NewObject(rcptfile,data)
		return false 
	  elseif screvent == "BUTTONS_2" or screvent == "KEY_CLR" or screvent == "CANCEL" then
		return do_obj_txn_sig()
	  end
  end
end

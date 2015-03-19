
function do_obj_tip_input()
  local tipcnt = tip_exists()
  if tipcnt and tipcnt >= 60 then
	  local scrlines = "LARGE,,191,2,C;" .."LARGE,,192,3,C;"
	  local scrkeys  = KEY.OK+KEY.CNCL+KEY.CLR
	  local screvents = EVT.TIMEOUT
	  terminal.DisplayObject(scrlines,scrkeys,screvents,30000)
	  return do_obj_cycle3()
  else
	  local scrlines = "LARGE,THIS,ENTER TXN ROC,2,C;" .."LNUMBER,,0,3,1,6,1;"
	  local scrkeys  = KEY.OK+KEY.CNCL+KEY.CLR
	  local screvents = EVT.TIMEOUT
	  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,screvents,30000)
	  if screvent == "KEY_OK" and #scrinput >= 1 then local tip_roc = scrinput; return do_obj_tip_chk(tip_roc)
	  else return do_obj_cycle3()
	  end
  end
end

function get_tipmax()
	if not config.tipmax then
		config.tipmax = terminal.GetJsonValue("CONFIG","TIPMAX")
		if config.tipmax == "" then config.tipmax = 50 else config.tipmax = tonumber(config.tipmax) end
	end
	return config.tipmax
end

function do_obj_tip_chk(tiproc)
  local safname = "CRTXN"
  local found,i = false,0
  local safmin,safnext = terminal.GetArrayRange(safname)
  local roc,procc,tipdone,mti
  local saffile =""
  
  if safmin<safnext then
    i = safmin
    while i < safnext do
      saffile = safname..i
      roc,procc,tipdone,mti = terminal.GetJsonValue(saffile,"62","3","TIPDONE","0")
	  if roc ~= "" and tonumber(terminal.StringToHex(roc,#roc)) == tonumber(tiproc) then 
	    if procc=="003000" then found = true end
		break 
	  end
	  i = i+ 1
    end
  end
  local scrlines = ""
  local scrkeys  = KEY.OK+KEY.CNCL+KEY.CLR
  local screvents = EVT.TIMEOUT

  if not found then
    scrlines = "LARGE,THIS,TRANSACTION,2,C;" .."LARGE,THIS,NOT FOUND,3,C;" 
	terminal.DisplayObject(scrlines,scrkeys,screvents,30000)
	return do_obj_cycle3()
  elseif tipdone == "YES" then
    scrlines = "LARGE,THIS,TRANSACTION,2,C;" .."LARGE,THIS,TIP ADJUSTED,3,C;" 
	terminal.DisplayObject(scrlines,scrkeys,screvents,30000)
	return do_obj_cycle3()
  else
	txn.orig_txnfile = saffile
    local pramt = terminal.GetJsonValue(safname .. i, "4")
	local stmp = string.format("$%.2f",tonumber(pramt)/100)
	scrlines = "LARGE,THIS,"..(mti =="220" and "COMP :" or "PURCH:").. string.format("%10s",stmp)..",2,1;"
    	.."LARGE,THIS,TIP:,3,1;"  .. "LAMOUNT,,0,3,7,10,1,,,"
	local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,screvents,30000)

	if screvent == "KEY_OK" and #scrinput > 0 then
	  local tipmax = get_tipmax()
	  tipmax = pramt*tonumber(tipmax)/100
	  local tip = tonumber( scrinput)
	  if tip > tipmax then scrlines = "LARGE,THIS,EXCEED TIP LIMIT,2,C;" 
		terminal.ErrorBeep()
	    terminal.DisplayObject(scrlines,scrkeys,screvents,30000)
		return do_obj_cycle3()
	  else 
	    local safmin,safnext = terminal.GetArrayRange("TIPSAF")
		local tipfile = "TIPSAF"..safnext
		local roc = terminal.GetJsonValue( safname..i, "62")
		terminal.SetJsonValue( safname..i, "TIPDONE","YES")
	    terminal.FileCopy( safname..i, tipfile)
	    terminal.SetJsonValue(tipfile,"0","220")
		terminal.SetJsonValue(tipfile,"3","023000")
		terminal.SetJsonValue(tipfile,"4",tonumber(pramt)+tip)
		terminal.SetJsonValue(tipfile,"11","000000")
		local mmddhhmmss = terminal.Time( "MMDDhhmmss")
        terminal.SetJsonValue(tipfile,"12",string.sub(mmddhhmmss,5,10))
        terminal.SetJsonValue(tipfile,"13",string.sub(mmddhhmmss,1,4))
		local s_amt= terminal.HexToString(string.format("%012s",tip))
		terminal.SetJsonValue(tipfile,"54",s_amt)
		s_amt= terminal.HexToString(string.format("%012s",tostring(pramt)))
		terminal.SetJsonValue(tipfile,"60",s_amt)
		terminal.SetArrayRange("TIPSAF","",safnext+1)
		tip_print(roc,tonumber(pramt),tip)
		update_total()
		scrlines = "LARGE,THIS,TIP ADJUSTMENT,2,C;" .."LARGE,THIS,COMPLETE,3,C;" 
	    terminal.DisplayObject(scrlines,scrkeys,screvents,30000)
		return do_obj_cycle3()
	  end
	else return do_obj_cycle3() end
  end
end

function tip_print(roc,pramt,tipamt)
	local scrlines,resultstr = "",""
	local rc = "00"
	local resultstr = "APPROVED\\R" .. rc.."\\n\\n"
    local who = "MERCHANT\\n\\CCOPY\\n"
	txn.func = "TIPS"
	txn.authid = terminal.GetJsonValue(txn.orig_txnfile,"38")
	txn.cardname = terminal.GetJsonValue(txn.orig_txnfile,"CARDNAME")
	txn.cashamt = 0; txn.prchamt = pramt + tipamt; txn.tipamt = tipamt; txn.totalamt = txn.prchamt
	txn.account = "CREDIT"
	local roc_keep = config.roc
	config.roc = terminal.StringToHex(roc,#roc)
	txn.offline = true
    local prtvalue = (ecrd.HEADER or "") ..get_ipay_print( who, true, resultstr)..(ecrd.MTRAILER or "") .."\\n"
    terminal.Print(prtvalue,true)
	checkPrint(prtvalue)
	config.roc = roc_keep
end

function do_obj_tip_list()
  local scrlines = "LARGE,THIS,LIST TIP TRANS?,2,C;" .."LARGE,,73,3,C;" 
  local scrkeys  = KEY.OK+KEY.CNCL+KEY.CLR
  local screvents = EVT.TIMEOUT
  local safmin,safnext = terminal.GetArrayRange("TIPSAF")
  if safmin < safnext then
	local screvent,_ = terminal.DisplayObject(scrlines,scrkeys,screvents,30000)
	local found = false
	if screvent == "KEY_OK" then 
		local prtvalue = ""
		local safmin,safnext = terminal.GetArrayRange("TIPSAF")
		local i = safmin
		prtvalue = "\\C\\f\\H" .. config.servicename .. "\\n" ..
			"\\C" .. config.merch_loc0 .."\\n" ..
			"\\C" .. config.merch_loc1 .."\\n\\n" ..
			"\\hMERCHANT ID:\\R" .. config.mid .. "\\n" ..
			"TERMINAL ID:\\R" .. config.tid .. "\\n" ..
			"TIPPING TRANSACTION LIST\\n\\n" .. 
			"INV/ROC TXN AMT  TIP AMT\\n" ..
			"------ --------- -------\\n"

		while i< safnext do
		  local roc,txnamt, tipamt = terminal.GetJsonValue("TIPSAF"..i,"62","60","54")
		  if #roc>0 and #txnamt>0 and #tipamt>0 then
			local s_txnamt = string.format("$%.2f",tonumber(terminal.StringToHex(txnamt,#txnamt))/100)
			local s_tipamt = string.format("$%.2f",tonumber(terminal.StringToHex(tipamt,#tipamt))/100)
			tipstr = terminal.StringToHex(roc,#roc) .. string.format("%10s",s_txnamt) ..string.format("%8s",s_tipamt) .."\\n"
			prtvalue = prtvalue ..tipstr
		  end
		  i = i+1
		end
		prtvalue = prtvalue .. "\\n".. terminal.Time("DD/MM/YY hh:mm" ) .."\\n"
		terminal.Print(prtvalue,true)
		checkPrint(prtvalue)
	  end
	else
		scrlines = "LARGE,THIS,TRANSACTION,2,C;" .."LARGE,THIS,NOT FOUND,3,C;" 
		terminal.DisplayObject(scrlines,scrkeys,screvents,30000)
	end
	return do_obj_cycle3()
end

function tip_exists()
	local safmin,safnext = terminal.GetArrayRange("TIPSAF")
	if safmin < safnext then local cnt = safnext-safmin; return cnt
	else return false end
end

function do_obj_tip_xmit(returnok,auto)
  local scrlines = "LARGE,THIS,TRANSMIT TIPS?,2,C;" .."LARGE,,73,3,C;" 
  local scrkeys  = KEY.OK+KEY.CNCL+KEY.CLR
  local screvents = EVT.TIMEOUT
  local screvent = ""
  screvent = not auto and terminal.DisplayObject(scrlines,scrkeys,screvents,30000) or "KEY_OK"
  local found,ok = false,false
  if screvent == "KEY_OK" then 
	local safmin,safnext = terminal.GetArrayRange("TIPSAF")
	if safmin < safnext then
	  scrlines = "LARGE,,27,2,C;".."LARGE,,26,3,C;"
      terminal.DisplayObject(scrlines,0,0,0)
	  local i = safmin
	  while i< safnext do
		ok = false
	    get_next_id("STAN")
		local fld48 = ""
	    local fld0,fld2,fld3,fld4,fld12,fld13,fld14,fld22,fld23,fld24,fld25,fld32,fld35,fld37,fld38,fld39 = terminal.GetJsonValue("TIPSAF"..i,"0","2","3","4","12","13","14","22","23","24","25","32","35","37","38","39")
	    local fld41,fld42,fld47,fld54,fld55,fld60,fld62= terminal.GetJsonValue("TIPSAF"..i,"41","42","47","54","55","60","62")
	    local msg220_flds = {"0:"..fld0,"2:"..fld2,"3:"..fld3,"4:"..fld4,"11:"..config.stan,"12:"..fld12,"13:"..fld13,"14:"..fld14,"22:"..fld22,"23:"..fld23,"24:"..fld24,"25:"..fld25,"32:"..fld32,"35:"..fld35,"37:"..fld37,"39:"..fld39,"41:"..fld41,"42:"..fld42,"47:"..fld47,"54:"..fld54,"55:"..fld55, "60:"..fld60,"62:"..fld62, "64:KEY="..config.key_kmacs}
	    local as2805msg = terminal.As2805Make( msg220_flds)
	    local retmsg = tcpconnect(); if retmsg ~= "NOERROR" then break end
        if as2805msg ~= "" then retmsg = tcpsend(as2805msg) end;if retmsg ~= "NOERROR" then break end
        as2805msg = ""
        retmsg,as2805msg = tcprecv();if retmsg ~= "NOERROR" then break end
        local msg_t = { "IGN,0", "IGN,3,", "IGN,11,", "GET,12","GET,13","IGN,24", "GETS,39","IGN,41","GETS,47","GETS,48"}
        retmsg,fld12,fld13,fld39,fld47,fld48 = terminal.As2805Break( as2805msg, msg_t )
		if #fld47 > 0 then hosttag_process(fld47) end
		if #fld48 > 80 then sessionkey_update(fld48) end
		if fld39 == "98" then config.logonstatus = "194"; config.logok = false ; check_logon_ok() end
        if fld39 ~= "00" then break end
        terminal.FileRemove("TIPSAF"..i)
        terminal.SetArrayRange("TIPSAF",i+1,"")
	    i = i + 1
	    ok = true
	  end
	  if not returnok then
		if ok then scrlines = "LARGE,THIS,TIP TRANSACTIONS,2,C;".."LARGE,THIS,TRANSMITTED,3,C;"
		else scrlines = "LARGE,THIS,TIP TRANSMIT,2,C;".."LARGE,THIS,FAILED,3,C;" end
		terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT, (auto and 2000 or 30000))
	  end
	else
	  scrlines = "LARGE,THIS,BATCH EMPTY,2,C;"
      terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,(auto and 2000 or 30000))
	  ok = true
	end
  end 
  if returnok then return ok
  else return do_obj_cycle3() end
end

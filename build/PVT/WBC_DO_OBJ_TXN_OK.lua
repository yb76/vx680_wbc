function do_obj_txn_ok()
	local pinchked = not txn.ctls and txn.chipcard and txn.offlinepin or txn.pinblock or txn.ctls
    local signflag =  not txn.moto and ( txn.ctlsPin == "1" or txn.ctlsPin == "3" or txn.rc == "08" or (txn.chipcard and terminal.EmvGlobal("GET","SIGN")) or not pinchked and not txn.eftpos) 
	local scrlines,resultstr,resultstr_nosign = "","",""
	if txn.rc == "08" then 
		scrlines =  "WIDELBL,,147,2,C;" .."WIDELBL,,54,3,C;" 
		resultstr = "APPROVED\\R" .. txn.rc.."\\n" 
	else scrlines =  "WIDELBL,,30,2,C;" .."WIDELBL,,147,3,C;" 
		resultstr = "APPROVED\\R" .. txn.rc.."\\n" 
	end
	resultstr_nosign = resultstr
	if signflag then 
		resultstr = resultstr .. "CARDHOLDER SIGN HERE:\\n\\n\\n\\n\\nX______________________\\n"
	end
	
    terminal.DisplayObject(scrlines,0,0,0)
    local who = "MERCHANT COPY\\n"
	txn.mreceipt= get_ipay_print( who, true, resultstr)
	who = "CUSTOMER COPY\\n"
	txn.creceipt= get_ipay_print( who, true, resultstr_nosign)
    local prtvalue = (ecrd.HEADER or "") ..(ecrd.HEADER_OK or "") .. txn.mreceipt ..(ecrd.MTRAILER or "") ..(config.debugemv and get_emv_print_tags(config.debugemv) or "").."\\n"
    terminal.Print(prtvalue,true)
	checkPrint(prtvalue)
	terminal.FileRemove("REV_TODO")
	do_obj_iecr_end(0)
	
    local prt_keep = (ecrd.HEADER  or "") .. (ecrd.HEADER_OK or "") ..prtvalue.. (ecrd.MTRAILER or "") .."\\n"
	local signok = true
	if signflag then signok = do_obj_txn_sig() end
	if signok then
      terminal.SetJsonValue("DUPLICATE","RECEIPT",prt_keep)
      return do_obj_txn_second_copy()
	else
	  do_obj_itaxi_pay_revert(0)
	  if txn.rc == "Y1" or txn.rc == "Y3" then return do_obj_txn_finish()
	  else return do_obj_saf_rev_start(do_obj_txn_finish,"REVERSAL") end
	end
end

function do_obj_txn_resp()
  local scrlines = "WIDELBL,,27,2,C;" .. "WIDELBL,,26,3,C;"
  terminal.DisplayObject(scrlines,0,0,0)
  local rcvmsg,errmsg,fld12,fld13,fld15,fld37,fld38,fld39,fld44,fld47,fld48,fld55,fld64
  errmsg, rcvmsg = tcprecv()
  if errmsg ~= "NOERROR" or not rcvmsg or rcvmsg == "" then 
	if errmsg == "NOERROR" then errmsg = "NO_RESPONSE" end
	if  txn.chipcard and not txn.emv.fallback and not txn.earlyemv then
		txn.offline = true
		copy_txn_to_reversal()
		local revrequired = true
		return do_obj_offline_check(revrequired)
	else txn.tcperror = true
		return do_obj_txn_nok(errmsg)
	end
  else
    txn.host_response = true
    local msg_t = {"GET,12","GET,13","GET,15","GETS,37","GETS,38","GETS,39","GETS,44","GETS,47","GETS,48","GETS,55","GETS,64" }
    errmsg,fld12,fld13,fld15,fld37,fld38,fld39,fld44,fld47,fld48,fld55,fld64 = terminal.As2805Break( rcvmsg, msg_t )
    if fld12 and fld13 then txn.time = fld13..fld12 end
    if fld38 and #fld38>0 then txn.authid = fld38 end
--terminal.DebugDisp("fld39="..fld39)
    if fld39 and #fld39>0 then txn.rc = fld39 end
    if fld44 and #fld44>0 then txn.rc_desc = fld44 end
	if fld47 and #fld47>0 then hosttag_process(fld47) end
	if config.hostsettle and fld15 and #fld15>0 then txn.newbatch = settledate_update(fld15) end
    local data_nomac,data_mac = string.sub(rcvmsg,1,#rcvmsg-16),string.sub(rcvmsg,-16)
    local chkmac = terminal.Mac(data_nomac,"",config.key_kmacr)

    if fld48 and #fld48>80 then sessionkey_update(fld48) end
    if errmsg ~= "NOERROR" then return do_obj_txn_nok(errmsg)  -- as2805 error
    elseif string.sub(chkmac,1,8) ~= string.sub(data_mac,1,8) then
		if fld39 == "98" and fld48 ~= "" then -- invalid session key
			copy_txn_to_reversal(); return do_obj_txn_nok()
		elseif fld39 == "98" and fld48 =="" then -- invalid MAC
			return do_obj_txn_nok()
		else
			txn.tcperror = true
			copy_txn_to_reversal()
			return do_obj_txn_nok("MAC") -- mac error 
		end
    elseif fld39 ~= "00" and fld39 ~= "08" then 
      local HOST_DECLINED = 2
      if not txn.ctls and txn.chipcard and not txn.emv.fallback and not txn.earlyemv then terminal.EmvUseHostData(HOST_DECLINED,fld55) end
      return do_obj_txn_nok(errmsg)
    else 
      if txn.time and string.len(txn.time)  == 10 then
        local yyyymm = terminal.Time( "YYYYMM")
        local yyyy,mm = string.sub(yyyymm,1,4),string.sub(yyyymm,5,6)
        if mm == "01" and string.sub(txn.time,1,2) == "12" then yyyy = tonumber(yyyy) -1 end
        if mm == "12" and string.sub(txn.time,1,2) == "01" then yyyy = tonumber(yyyy) +1 end
   		txn.time = yyyy..txn.time
        terminal.TimeSet(txn.time,config.timeadjust)
      end
      local HOST_AUTHORISED,emvok = 1,0

      if not txn.ctls and txn.chipcard and not txn.emv.fallback and not txn.earlyemv then
		local rc = terminal.HexToString(txn.rc)
		terminal.EmvSetTagData(0x8A00,rc)
		emvok = terminal.EmvUseHostData(HOST_AUTHORISED,fld55) 
	  end
      if emvok ~= 0--[[TRANS_DECLINE]] then 
		txn.rc = "Z4"
	    copy_txn_to_reversal()
        return do_obj_txn_nok(txn.rc) 
      else
		return do_obj_txn_ok() 
	  end
    end
  end
end

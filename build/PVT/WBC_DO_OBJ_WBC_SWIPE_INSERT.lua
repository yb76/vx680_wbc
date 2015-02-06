function do_obj_wbc_swipe_insert()
  txn.emv = {}
  local ok = 0
  if txn.ctls == "CTLS_E" then
    txn.chipcard = true
    txn.cvmlimit = ecrd.CVMLIMIT
    local aid = get_value_from_tlvs("9F06")
    if string.sub(aid,1,10) == "A000000384" and config.ehub == "YES" then
	 txn.eftpos = true
    end
  elseif txn.chipcard then 
    ok = emv_init()
  end
  if ok ~= 0 then return do_obj_emv_error(ok)  else	return do_obj_prchamount()  end
end

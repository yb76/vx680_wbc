function do_obj_wbc_swipe_insert()
  txn.emv = {}
  local ok = 0
  if txn.ctls == "CTLS_E" then
    txn.chipcard = true
    txn.cvmlimit = ecrd.CVMLIMIT
  elseif txn.chipcard then 
    ok = emv_init()
  end
  if ok ~= 0 then return do_obj_emv_error(ok)  else	return do_obj_prchamount()  end
end

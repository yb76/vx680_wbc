function do_obj_wbc_mcr_chip()
  check_logon_ok()
  local nextstep = do_obj_wbc_swipe_insert
  txn.func = "PRCH"
  if not txn_allowed(txn.func) then nextstep = do_obj_txn_finish end
  return nextstep()
end

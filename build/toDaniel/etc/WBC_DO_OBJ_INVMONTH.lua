function do_obj_invmonth()
  terminal.ErrorBeep()
  local scrlines = "WIDELBL,,299,3,C;" .. "WIDELBL,,201,5,C;"
  local screvent = terminal.DisplayObject(scrlines,KEY.CLR+KEY.CNCL,EVT.TIMEOUT,3000)
  if screvent == "KEY_CLR" then
    return do_obj_card_expiry()
  else
    return do_obj_txn_finish()
  end
end

function do_obj_luhnerror()
  local scrlines = "WIDELBL,,120,3,C;" .. "WIDELBL,,123,5,C;"
  local scrkeys  = KEY.CLR+KEY.CNCL
  terminal.ErrorBeep()
  local screvent,_ = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,30000)
  if screvent == "KEY_CLR" then return do_obj_swipecard()
  else return do_obj_txn_finish() end
end

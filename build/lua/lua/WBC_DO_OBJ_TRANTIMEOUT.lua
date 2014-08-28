function do_obj_trantimeout()
  local scrlines = "WIDELBL,,120,2,C;" .. "WIDELBL,,122,3,C;"
  local scrkeys  = KEY.OK+KEY.CLR+KEY.CNCL
  terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT+EVT.SCT_OUT,30000)
  return do_obj_txn_finish()
end

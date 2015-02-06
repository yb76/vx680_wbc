function do_obj_logon_init()
  local scrlines = ",,78,4,C;" .. "BUTTONS_1,THIS,YES,8,10;".. "BUTTONS_2,THIS,NO,8,33;"
  local scrkeys  = KEY.CLR+KEY.CNCL+KEY.OK
  local screvents = EVT.TIMEOUT
  local scrtimeout = 30000
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,screvents,scrtimeout)

  if screvent == "KEY_OK" or screvent == "BUTTONS_1" then
    scrlines = "WIDELBL,,21,4,C;"
	terminal.DisplayObject(scrlines,0,0,0)
	txn.func = "LGON"
	txn.manuallogon = true
    return do_obj_logon_start()
  else
    return do_obj_txn_finish()
  end
end

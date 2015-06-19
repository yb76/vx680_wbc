function do_obj_txn_second_copy()
  local scrlines = "WIDELBL,,36,4,C;" .."BUTTONS_1,THIS,YES,8,10;".. "BUTTONS_2,THIS,NO,8,33;"
  local screvent,_ = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL+KEY.CLR,EVT.TIMEOUT,30000)

  if screvent == "BUTTONS_1" or screvent == "KEY_OK" then
    scrlines = "WIDELBL,,37,2,C;" .."WIDELBL,,26,3,C;"
    terminal.DisplayObject(scrlines,0,0,0)
    local prtvalue = (ecrd.HEADER or "") .. (ecrd.HEADER_OK or "") .. txn.creceipt.. (ecrd.CTRAILER or "") .."\\n"
    terminal.Print(prtvalue,true)
	checkPrint(prtvalue)
    terminal.SetJsonValue("DUPLICATE","RECEIPT",prtvalue)
  end
  update_total()
  return do_obj_txn_finish()
end

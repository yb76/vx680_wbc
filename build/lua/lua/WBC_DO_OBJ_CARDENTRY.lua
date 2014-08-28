function do_obj_cardentry()
  local scrlines = "WIDELBL,,110,2,C;" .. "LNUMBER,,0,5,10,19,13;"
  local scrkeys  = KEY.OK+KEY.CLR+KEY.CNCL
  local screvents = EVT.TIMEOUT
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,screvents,30000)

  txn.moto = false
  if screvent == "KEY_CLR" then
    return do_obj_swipecard()
  elseif screvent == "KEY_OK" then
    txn.moto = true
    txn.pan = scrinput
    txn.account = "CREDIT"
    if terminal.Luhn(txn.pan) == false then return do_obj_luhnerror()
    else return do_obj_card_expiry() end
  elseif screvent == "CANCEL" then
    return do_obj_txn_finish()
  elseif screvent == "TIME" then
    return do_obj_swipecard()
  end
end

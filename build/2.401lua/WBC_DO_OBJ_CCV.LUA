function do_obj_ccv()
  local scrlines = "WIDELBL,,112,2,C;" .. "LNUMBER,,0,5,17,5,1;"
  local scrkeys  = KEY.OK+KEY.CLR+KEY.CNCL
  local screvents = EVT.TIMEOUT
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,screvents,30000)

  if screvent == "KEY_CLR" then
    return do_obj_card_expiry()
  elseif screvent == "KEY_OK" then
    if #scrinput > 0 then txn.ccv = "CCV" .. scrinput .. "\\" end
    return do_obj_account()
  else
    return do_obj_txn_finish()
  end
end

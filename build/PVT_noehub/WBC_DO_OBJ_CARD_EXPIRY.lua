function do_obj_card_expiry()
  local scrlines = "WIDELBL,,111,2,C;" .. "LNUMBER,,0,5,18,4,4;"
  local scrkeys  = KEY.OK+KEY.CLR+KEY.CNCL
  local screvents = EVT.TIMEOUT
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,screvents,30000)

  if screvent == "KEY_CLR" then
    return do_obj_cardentry()
  elseif screvent == "KEY_OK" then
    local mm = tonumber(string.sub(scrinput,1,2))
    if mm > 12 or mm < 1 then return do_obj_invmonth()
    else txn.expiry = scrinput
         return do_obj_ccv()
    end
  else return do_obj_txn_finish()
  end
end

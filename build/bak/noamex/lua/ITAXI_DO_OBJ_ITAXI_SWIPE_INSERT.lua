function do_obj_itaxi_swipe_insert()
  local nextstep = do_obj_itaxi_pickup
  taxi = {}
  if common.track2 then
    taxi.track2 = common.track2 
    local swipeflag,cardname = swipecheck(taxi.track2)
    if swipeflag < 0 then 
      nextstep = do_obj_itaxi_finish 
    elseif swipeflag == 0 then
      local scrlines = "WIDELBL,THIS,INSERT CARD,4,C;"
      local screvent = terminal.DisplayObject(scrlines,KEY.CNCL,EVT.TIMEOUT+EVT.SCT_IN,ScrnTimeout)
      if screvent ~= "CHIP_CARD_IN" then nextstep = do_obj_itaxi_finish 
      else common.entry = "CHIP" end
    else taxi.cardname = cardname
    end
  end
  if common.entry == "CHIP" then 
    local retval = terminal.EmvTransInit()
    if retval ~= 0 then 
        terminal.ErrorBeep()
        local scrlines1="WIDELBL,THIS,CARD ERROR,2,C;" .. "WIDELBL,THIS,REMOVE CARD,4,C;"
        terminal.DisplayObject(scrlines1,0,EVT.SCT_OUT,0)
        nextstep = do_obj_itaxi_finish
    else
        taxi.chipcard = true 
    end
  elseif common.entry == "CTLS" then taxi.ctls = "CTLS"
  end
  
  if nextstep ~= do_obj_itaxi_finish then
    local inv,lastinv=taxicfg.inv, taxicfg.last_inv
    if tonumber(inv)-tonumber(lastinv)> taxicfg.max_txn then 
      terminal.ErrorBeep()
      local scrlines = "WIDELBL,THIS,SIGN OFF then ON,3,C;".."WIDELBL,THIS,THEN RETRY,4,C;".."WIDELBL,THIS,TRANSACTION,5,C;"
      local screvent,scrinput = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL,EVT.TIMEOUT,ScrnErrTimeout)
      nextstep = do_obj_itaxi_finish
    end
  end
  return nextstep()
end

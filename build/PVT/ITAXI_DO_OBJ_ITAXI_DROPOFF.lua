function do_obj_itaxi_dropoff()
  local nextstep = do_obj_itaxi_meter
  if not taxicfg.dropoff_scr then
    local loc0,loc1,loc2,loc3,loc4,loc5 = taxicfg.loc0,taxicfg.loc1,taxicfg.loc2,taxicfg.loc3,taxicfg.loc4,taxicfg.loc5
    local scrlines = "WIDELBL,THIS,DROP OFF TO,-1,C;" .. "BUTTONM_0,THIS,"..loc0..",2,C;" .. "BUTTONM_1,THIS,"..loc1..",4,C;"
                .. "BUTTONM_2,THIS,"..loc2..",6,C;" .. "BUTTONM_3,THIS,"..loc3..",8,C;" .. "BUTTONM_4,THIS,"..loc4..",10,C;" .. "BUTTONM_5,THIS,"..loc5..",12,C;"
    taxicfg.dropoff_scr = scrlines
  end

  local scrkeys = KEY.CNCL+KEY.CLR
  local screvent,scrinput = terminal.DisplayObject(taxicfg.dropoff_scr,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  
  if screvent == "BUTTONM_0" then
    taxi.dropoff = taxicfg.loc0
  elseif screvent == "BUTTONM_1" then
    taxi.dropoff = taxicfg.loc1
  elseif screvent == "BUTTONM_2" then
    taxi.dropoff = taxicfg.loc2
  elseif screvent == "BUTTONM_3" then
    taxi.dropoff = taxicfg.loc3
  elseif screvent == "BUTTONM_4" then
    taxi.dropoff = taxicfg.loc4
  elseif screvent == "BUTTONM_5" then
    taxi.dropoff = taxicfg.loc5
  elseif screvent == "KEY_CLR" then
    nextstep = do_obj_itaxi_pickup
  else
    nextstep = do_obj_itaxi_finish
  end
  return nextstep()
end

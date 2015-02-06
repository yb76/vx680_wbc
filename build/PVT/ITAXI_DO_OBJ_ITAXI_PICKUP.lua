function do_obj_itaxi_pickup()
  local nextstep = do_obj_itaxi_dropoff
  if txn_allowed("PRCH") then
      if not taxicfg.pickup_scr then
        local loc0,loc1,loc2,loc3,loc4,loc5 = taxicfg.loc0,taxicfg.loc1,taxicfg.loc2,taxicfg.loc3,taxicfg.loc4,taxicfg.loc5
        local scrlines = "WIDELBL,THIS,<color_red>PICK UP FROM,-1,C;" .. "BUTTONM_0,THIS,"..loc0..",2,C;" .. "BUTTONM_1,THIS," ..loc1..",4,C;" 
        .. "BUTTONM_2,THIS,"..loc2..",6,C;" .. "BUTTONM_3,THIS,"..loc3..",8,C;" .. "BUTTONM_4,THIS,"..loc4..",10,C;"
        .. "BUTTONM_5,THIS,"..loc5..",12,C;"
        taxicfg.pickup_scr = scrlines
      end

      local scrkeys = KEY.CNCL
      local screvents = EVT.TIMEOUT
      local screvent,scrinput = terminal.DisplayObject(taxicfg.pickup_scr,scrkeys,screvents,ScrnTimeout)
        
      if screvent == "BUTTONM_0" then
        taxi.pickup = taxicfg.loc0
      elseif screvent == "BUTTONM_1" then
        taxi.pickup = taxicfg.loc1
      elseif screvent == "BUTTONM_2" then
        taxi.pickup = taxicfg.loc2
      elseif screvent == "BUTTONM_3" then
        taxi.pickup = taxicfg.loc3
      elseif screvent == "BUTTONM_4" then
        taxi.pickup = taxicfg.loc4
      elseif screvent == "BUTTONM_5" then
        taxi.pickup = taxicfg.loc5
      else
        nextstep = do_obj_itaxi_finish
      end
    else
        nextstep = do_obj_itaxi_finish
    end
  return nextstep()
end

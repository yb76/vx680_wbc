function do_obj_itaxi_meter()
  local meteramt = taxi.meter or 0
    local scrlines = "WIDELBL,iTAXI_T,93,2,C;" .. "AMOUNT," .. meteramt ..",5,5,C,9,1;"
  local scrkeys = KEY.OK+KEY.CNCL+KEY.CLR
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "KEY_OK" then
      local ok = true
      local amt = tonumber(scrinput) or 0
      if scrinput == "" or amt < 500 or amt >10000 then
        scrlines = "WIDELBL,THIS,AMOUNT IS "..(amt > 10000 and "GREATER THAN $100 ?" or "LESS THAN $5?") ..",5,C;".."BUTTONS_1,THIS,YES,8,10;".. "BUTTONS_2,THIS,NO,8,33;"
        scrkeys  = KEY.CNCL
        screvent = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
        if screvent == "BUTTONS_1" then ok = true else ok = false end
      end
      if ok then
        taxi.meter = tonumber(scrinput)
        return do_obj_itaxi_other_charges()
      else
        return do_obj_itaxi_meter()
      end
  elseif screvent == "KEY_CLR" then
    taxi.meter = 0
    return do_obj_itaxi_dropoff()
  else
    return do_obj_itaxi_finish()
  end
end

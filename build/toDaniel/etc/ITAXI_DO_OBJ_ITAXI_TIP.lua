function do_obj_itaxi_tip()
  local amt = taxi.subtotal + ( not taxi.cash and taxi.serv_gst or 0)
  local line1 = "TOTAL FARE:" .. string.format("%10s", string.format( "$%.2f", amt/100))
  local amt2 = math.floor(amt/100 + 2.50)*100
  local amt5 = round_near5(amt/100+ 5)*100
  local amt10 =round_near5(amt/100+10)*100

  local s1,s2,s3 = string.format("$%.0f",amt2/100),string.format("$%.0f",amt5/100),string.format("$%.0f",amt10/100)
  if #s1 ==2 then s1 = " "..s1 end;if #s2 ==2 then s2 = " "..s2 end;if #s3 ==2 then s3 = " "..s3 end
  if #s1 ==3 then s1 = s1.." " end;if #s2 ==3 then s2 = s2.." " end;if #s3 ==3 then s3 = s3.." " end
  local scrlines = "WIDELBL,THIS," .. line1 ..",1,5;" 
    .. ",THIS,  WOULD YOU LIKE TO TIP YOUR   DRIVER? ROUND YOUR TOTAL TO:,3,C;"   
    .."BUTTONS_1,THIS,"..s1..",7,4;"
    .."BUTTONS_2,THIS,"..s2..",7,20;"
    .."BUTTONS_3,THIS,"..s3..",7,36;"
    .."BUTTONL_4,THIS,".."CONTINUE"..",B,C;"

  local scrkeys = KEY.OK+KEY.CNCL+KEY.CLR
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)

  taxi.tip = 0
  local tip_gst = 0
  if screvent == "BUTTONL_4" then
  elseif screvent == "BUTTONS_1" then
		tip_gst = amt2 - amt
  elseif screvent == "BUTTONS_2" then
		tip_gst = amt5 - amt
  elseif screvent == "BUTTONS_3" then
		tip_gst = amt10 - amt
  end
  if tip_gst > 0 then 
    local pct = 1+ tonumber (taxicfg.serv_gst)/10000
    taxi.tip = taxi.cash and tip_gst or math.floor( tip_gst/pct + 0.5)
    taxi.meter = taxi.meter + taxi.tip
    taxi.subtotal = taxi.meter + taxi.otherchg
    taxi.serv_gst = taxi.serv_gst + tip_gst - taxi.tip
  end
  
  if screvent == "KEY_CLR" then
    return do_obj_itaxi_meter
  elseif screvent == "TIME" or screvent == "CANCEL" then
    return do_obj_itaxi_finish
  else return nil
  end
end

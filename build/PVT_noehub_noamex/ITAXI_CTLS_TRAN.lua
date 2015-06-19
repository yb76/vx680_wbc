function ctls_tran()
    local amt = taxi.subtotal+taxi.serv_gst
    local translimit,cvmlimit=0,0
    local nosaf = 0
    local tr1,tr2,tlvs,emvres = terminal.CtlsCall(0,amt,nosaf)

    if tr2 ~= "" then
        if taxicfg.ctls_slimit > 0 and amt > taxicfg.ctls_slimit then tr2 = ""; emvres = "-1025"; end
    elseif tlvs ~= "" then
    end

    local safexceed = (nosaf ==1 and tonumber(emvres) == 0)
	if tlvs ~= "" and string.sub(get_value_from_tlvs("9F06",tlvs),1,10)=="A000000025" then -- disable Amex
		return do_obj_itaxi_paymentmethod(true)
	elseif  tr2 ~= "" then
        if not safexceed then
            local scrlines1 = "WIDELBL,THIS,PROCESSING..,3,C;" .. "WIDELBL,THIS,PLEASE WAIT,5,C;"
            terminal.DisplayObject(scrlines1,0,EVT.TIMEOUT,500)
        end
        taxi.ctls = "CTLS_S"
        taxi.tlvs = tlvs
        taxi.track2 = tr2
        return do_obj_itaxi_pay_swipe()
    elseif tlvs ~= "" then
        taxi.CTemvrs = emvres
        if not safexceed then
            local scrlines1 = "WIDELBL,THIS,PROCESSING..,3,C;" .. "WIDELBL,THIS,PLEASE WAIT,5,C;"
            terminal.DisplayObject(scrlines1,0,EVT.TIMEOUT,500)
        else
            taxi.CTemvrs = "W30"
        end
        taxi.ctls = "CTLS_E"
        taxi.tlvs = tlvs
        taxi.chipcard = true 
        return do_obj_itaxi_pay_swipe()        
    elseif emvres == "99" or emvres =="-1025" then 
        if emvres == "-1025" then terminal.DisplayObject("WIDELBL,THIS,NO CONTACTLESS,3,C;".. 
          "WIDELBL,THIS,FOR AMOUNT >".. string.format("%.2f",translimit/100.0) ..",5,C;",KEY.OK,EVT.TIMEOUT,2000) end
        return do_obj_itaxi_paymentmethod()
    elseif emvres == "-1001" or emvres =="-1002" then 
		if emvres == "-1001" then taxi.track2 = terminal.GetTrack(2) else taxi.chipcard = true end
		return do_obj_itaxi_pay_swipe()
    elseif emvres == "-2" then
	  if do_obj_iecr_chk_manual_password() then
		taxi.entry = "MOTO"
		return do_obj_itaxi_pay_swipe()
	  else
		return do_obj_itaxi_finish()
	  end
    elseif emvres == "-1" then --CANCEL
	  return do_obj_itaxi_finish()
	else
        terminal.ErrorBeep()
        if emvres == "-13" then
            if terminal.EmvIsCardPresent() then terminal.DisplayObject("WIDELBL,THIS,REMOVE CARD,3,C;",0,EVT.SCT_OUT,0)
            else    terminal.DisplayObject("WIDELBL,THIS,TRAN CANCELLED,3,C;",0,EVT.TIMEOUT,2000)
            end
        else    terminal.DisplayObject("WIDELBL,THIS,CARD ERROR,3,C;",0,EVT.TIMEOUT,2000)
        end
        return do_obj_itaxi_finish()
    end
end

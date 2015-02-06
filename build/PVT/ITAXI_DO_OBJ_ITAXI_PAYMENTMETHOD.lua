function do_obj_itaxi_paymentmethod(noinsert)
    local scrlines = "WIDELBL,THIS,SWIPE/INSERT,1,C;".."WIDELBL,THIS,CARD,2,C;"
    local screvents = EVT.TIMEOUT+EVT.MCR+EVT.SCT_IN
	if noinsert then
    	scrlines = "WIDELBL,THIS,SWIPE CARD,2,C;"
    	screvents = EVT.TIMEOUT+EVT.MCR
	end
    local scrkeys  = KEY.CNCL
    taxi.CTemvrs=nil; taxi.tlvs = nil; taxi.ctls = nil; terminal.Sleep(2000)
    local screvent = terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnTimeout)

    if screvent == "MCR" then taxi.track2 = terminal.GetTrack(2); return do_obj_itaxi_pay_swipe()
    elseif screvent == "CHIP_CARD_IN" then taxi.chipcard = true; return do_obj_itaxi_pay_swipe()
    else return do_obj_itaxi_finish()
    end
end

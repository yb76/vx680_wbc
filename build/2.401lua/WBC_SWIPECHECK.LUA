function swipecheck(track2)
  if track2 == nil or #track2 < 11 or callback.mcr_func == nil then terminal.ErrorBeep(); return -1 end

  local _,_,pan,panetc = string.find(track2, "(%d*)=(%d*)")
  if not (pan and #pan > 11) then 
		terminal.ErrorBeep()
  		local scrlines1 = "WIDELBL,THIS,TRAN CANCELLED,2,C;" .. "WIDELBL,THIS,CARD NOT SUPPORTED,4,C;"
		terminal.DisplayObject(scrlines1,KEY.CNCL,EVT.TIMEOUT,ScrnErrTimeout)
		return -1
  end

  local expirydate = (panetc and string.sub(panetc,1,4) or "")
  local currmonth = terminal.Time( "YYMM") 
  if expirydate ~= "" and tonumber(currmonth) > tonumber(expirydate) then
		terminal.ErrorBeep()
		local scrlines1 = "WIDELBL,THIS,TRAN CANCELLED,2,C;" .. "WIDELBL,THIS,CARD EXPIRED,4,C;"
		terminal.DisplayObject(scrlines1,KEY.CNCL,EVT.TIMEOUT,ScrnErrTimeout)
		return -1
  end

  local cardname_prefix,_,_ = terminal.LocateCpat("CPAT_ALL",string.sub(pan,1,6))
  if #cardname_prefix < 2 then 
		terminal.ErrorBeep()
  		local scrlines1 = "WIDELBL,THIS,TRAN CANCELLED,2,C;" .. "WIDELBL,THIS,CARD NOT SUPPORTED,4,C;"
		terminal.DisplayObject(scrlines1,KEY.CNCL,EVT.TIMEOUT,ScrnErrTimeout)
		return -1
  end

  if #cardname_prefix > 2 then cardname_prefix = string.sub(cardname_prefix,-2) end
  local cardname = terminal.TextTable("CARD_NAME",cardname_prefix)

  local chipflag = (panetc and string.sub(panetc,5,5) or "")
  if chipflag == "2" or chipflag == "6" then		
      terminal.ErrorBeep(); return 0 
  end

  return 1,cardname
end

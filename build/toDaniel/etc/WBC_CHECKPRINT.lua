function checkPrint(prtvalue)
  while true do
	local prtok = terminal.PrinterStatus()
	if prtok == "OK" then return 
	else
		local scrlines = "WIDELBL,THIS,PRINTER ERROR,2,C;" .. "WIDELBL,THIS,"..prtok..",3,C;" .."BUTTONS_Y,THIS,RETRY ,B,4;".."BUTTONS_N,THIS,CANCEL,B,33;"
		local screvent,_ = terminal.DisplayObject(scrlines,KEY.FUNC,0,0)
		if screvent == "BUTTONS_Y" then terminal.Print(prtvalue,true)
		elseif screvent == "KEY_FUNC" then
			local slen = 1
			prtvalue = string.gsub(prtvalue,"\\n","\n")
			prtvalue = string.gsub(prtvalue,"\n+","\n")
			prtvalue = string.gsub(prtvalue,"\\.","")
			prtvalue = string.gsub(prtvalue,"-----------","")
			while slen <=#prtvalue do terminal.DebugDisp(string.sub(prtvalue,slen,slen+240)); slen=slen+241 end
			return
		else return end
	end
  end
end

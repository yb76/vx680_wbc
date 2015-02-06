function do_obj_gprs_register(nextfunc)
  local scrlines = "WIDELBL,,228,4,C;" .. "WIDELBL,THIS,"..config.apn..",6,C;"
  local screvent,scrinput = terminal.DisplayObject(scrlines,0,0,0)
  local retmsg = tcpconnect()
  scrlines = "WIDELBL,,228,3,C;" .. "WIDELBL,THIS,"..config.apn..",4,C;"
  if retmsg == "NOERROR" then
    scrlines = scrlines .. "WIDELBL,THIS,SUCCESS!!,6,C;"
  else
    terminal.ErrorBeep()
    scrlines = scrlines .. "WIDELBL,THIS,FAILED!!,6,C;"
	scrlines = scrlines .. "WIDELBL,THIS,"..retmsg..",8,C;"
  end
  terminal.DisplayObject(scrlines,0,EVT.TIMEOUT,ScrnTimeoutHF)
  if nextfunc then return nextfunc() else return 0 end
end

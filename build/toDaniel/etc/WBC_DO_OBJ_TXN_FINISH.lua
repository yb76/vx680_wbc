function do_obj_txn_finish(nosaf)
  terminal.FileRemove("TXN_REQ")
  terminal.FileRemove("REV_TODO")
  if txn.finishreturn then return txn.finishreturn
  else
    terminal.EmvResetGlobal()
	terminal.TcpDisconnect()
    if txn.chipcard and terminal.EmvIsCardPresent() and not (ecrd and ecrd.RETURN) then
      terminal.EmvPowerOff()
      local scrlines = "WIDELBL,,286,2,C;"
      terminal.DisplayObject(scrlines,0,EVT.SCT_OUT,0)
	end
	local nextstep = ( ecrd.RETURN or do_obj_idle )
	if nosaf or txn.rc == "Y3" or txn.rc == "Z3" or ( txn.tcpsent == false and txn.rc ~= "Y1") or config.safsign and string.find(config.safsign,"+")
		then saf_rev_check(); return nextstep()
    else txn.safonce = true; return do_obj_saf_rev_start(nextstep,"SAF") end
  end
end

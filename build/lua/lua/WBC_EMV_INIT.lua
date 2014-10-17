function emv_init()
  local ok = 0
  if txn.chipcard then
    ok = terminal.EmvTransInit()
	local amt,acctype,eftpos_mcard = ecrd.AMT,0,0
	txn.apps = 0
    if ok == 0 then ok,txn.apps,eftpos_mcard = terminal.EmvSelectApplication(amt,acctype) end
	if ok == 0 then
		local tag_aid = string.upper(terminal.EmvGetTagData(0x4F00))
		local eftpos = (tag_aid and string.sub(tag_aid,1,10) == "A000000384") 
		if eftpos and config.ehub == "YES" then txn.eftpos = true end
		if eftpos_mcard == 1 then txn.eftpos_mcard = 1 end
		terminal.DebugDisp("txn.eftpos_mcard = ".. (txn.eftpos_mcard or "empty"))
	end
    if ok ~= 0 and config.fallback and ok ~= 103 --[[CARD_REMOVED]] and ok ~= 104 --[[CARD_BLOCKED]] and ok ~= 105 --[[APPL_BLOCKED]] and ok ~= 110 --[[TRANS_CANCELLED]] and ok ~= 130 --[[INVALID_PARAMETER]] then
      txn.emv.fallback = true
    end
  end
  return ok
end

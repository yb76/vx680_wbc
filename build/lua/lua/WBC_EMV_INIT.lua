function emv_init()
  local ok = 0
  if txn.chipcard then
    ok = terminal.EmvTransInit()
	local amt,acctype = ecrd.AMT,0
    if ok == 0 then ok = terminal.EmvSelectApplication(amt,acctype) end
	if not config.ehub then config.ehub = terminal.GetJsonValue("CONFIG","EHUB") end
	config.ehub = "YES" -- boyang
	if ok == 0 then
		local tag_aid = string.upper(terminal.EmvGetTagData(0x4F00))
		local eftpos = (tag_aid and string.sub(tag_aid,1,10) == "A000000384") 
		if eftpos and config.ehub == "YES" then txn.eftpos = true end
	end
    if ok ~= 0 and config.fallback and ok ~= 103 --[[CARD_REMOVED]] and ok ~= 104 --[[CARD_BLOCKED]] and ok ~= 105 --[[APPL_BLOCKED]] and ok ~= 110 --[[TRANS_CANCELLED]] and ok ~= 130 --[[INVALID_PARAMETER]] and not (ok == 146 --[[CANDIDATELIST_EMPTY]] and txn.eftpos) then
      txn.emv.fallback = true
    end
  end
  return ok
end

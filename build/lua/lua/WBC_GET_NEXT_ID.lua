function get_next_id(idtype)
  if idtype == "ROC" then
	if config.roc == nil or config.roc == "" or tonumber(config.roc) >= 999999 then config.roc = "000001"
	else config.roc = string.format("%06d",tonumber(config.roc) + 1) end
	terminal.SetJsonValue("CONFIG","ROC",config.roc)
	return config.roc
  elseif idtype == "STAN" then
    if config.stan == nil or config.stan == "" or tonumber(config.stan) >= 999999 then config.stan = "000001"
	else config.stan = string.format("%06d",tonumber(config.stan) + 1) end
	terminal.SetJsonValue("CONFIG","STAN",config.stan)
	return config.stan
  elseif idtype == "BATCHNO" then
	local batchno = terminal.GetJsonValue("CONFIG","BATCHNO")
    if batchno == "" or batchno == "999999" then batchno = "000001" else batchno = string.format("%06d", tonumber(batchno)+1) end
    terminal.SetJsonValue("CONFIG","BATCHNO", batchno)
	return batchno
  else
    return 0
  end
end

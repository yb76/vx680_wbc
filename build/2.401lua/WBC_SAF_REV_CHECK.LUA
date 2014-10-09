function saf_rev_check()
  local safmin,safmax= terminal.GetArrayRange("SAF")
  local revmin,revmax= terminal.GetArrayRange("REVERSAL")
  if safmax > safmin or revmax > revmin then
	config.safsign =( revmax>revmin and "+" or "" ) ..( safmax>safmin and "*" or "")
  else config.safsign = false
  end
end

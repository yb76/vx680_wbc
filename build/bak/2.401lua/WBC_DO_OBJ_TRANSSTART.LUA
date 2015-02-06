function do_obj_transstart()
  get_next_id("STAN")
  local scrlines = "WIDELBL,,27,2,C;" .."WIDELBL,,26,3,C;"
  terminal.DisplayObject(scrlines,0,0,0)
  local pan = txn.fullpan
  local onlpin = terminal.EmvGlobal("GET","ONLINEPIN")
  if onlpin and txn.pinblock_flag == "TODO" then
	local key_pin = config.key_pin
	txn.pinblock = terminal.PinBlock(key_pin,pan,txn.totalamt,config.stan,(txn.chipcard and not txn.earlyemv and not txn.emv.fallback and "1" or "0"))
	if txn.pinblock == "" then txn.pinblock = nil end
  end
  return do_obj_txn_req()
end

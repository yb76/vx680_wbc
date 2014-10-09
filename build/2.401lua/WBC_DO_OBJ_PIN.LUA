function do_obj_pin()
  if txn.chipcard and not txn.ctls and (( txn.account == "SAVINGS" or txn.account == "CHEQUE" ) and not txn.eftpos ) then txn.earlyemv = true end

  if txn.pan then return do_obj_transdial()
  elseif txn.ctls and txn.chipcard and config.ctls_cvm and not hasbit( tonumber(config.ctls_cvm,16),bit(7))  then do_obj_transdial()
  elseif txn.ctls and txn.chipcard and txn.ctlsPin ~= "2" and txn.ctlsPin ~= "3" then 
  	return do_obj_transdial()
  elseif txn.chipcard and not txn.earlyemv and not txn.emv.fallback and not txn.ctls 
	then txn.pinblock_flag = "TODO";return do_obj_transdial()
  else
    local amtstr = string.format( "$%.2f", txn.totalamt/100.0 )
	amtstr = string.format( "%9s",amtstr)
    local scrlines = "WIDELBL,THIS,TOTAL:          " .. amtstr ..",2,3;"
	local pinbypass = false
	if txn.ctls and ( not txn.chipcard and txn.cardname ~="MASTERCARD" or txn.ctlsPin == "3") then pinbypass = true 
	elseif not txn.ctls and txn.account == "CREDIT" then pinbypass = true end
	scrlines = scrlines .. ( pinbypass and "PIN,,,P5,P11,0;" or scrlines .. "PIN,,,P5,P11,1;" ) 

    local scrkeys  = KEY.CNCL+KEY.NO_PIN+KEY.OK
    local screvents = EVT.TIMEOUT+EVT.SCT_OUT
    local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,screvents,ScrnTimeout)
    if screvent == "KEY_OK" then
      txn.pinblock_flag = "TODO"
	  if txn.ctlsPin == "3" then txn.ctlsPin = "2" end
      return do_obj_transdial()
    elseif screvent =="KEY_NO_PIN" then
      txn.pinblock_flag = "NOPIN"
      return do_obj_transdial()
    elseif screvent == "TIME" then
      return do_obj_trantimeout()
	elseif screvent == "CHIP_CARD_OUT" then
		return do_obj_emv_error(101)
    else
      return do_obj_txn_finish()
    end
  end
end

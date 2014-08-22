-----------------------iECR----------------------------
function do_obj_iecr_start()
  if ecrd.AMT and ecrd.AMT > 0 and ecrd.TRACK2 and #ecrd.TRACK2 > 10 then
        txn.swipefirst = 1 ; txn.track2 = ecrd.TRACK2 
		txn.cardname = ecrd.CARDNAME
  end
  if ecrd.CTLS then txn.ctls = ecrd.CTLS;txn.TLVs = ecrd.TLVs; txn.CTEMVRS = ecrd.CTEMVRS  end
  if ecrd.CHIPCARD then txn.chipcard = true; txn.emv = {} end
  if ecrd.ENTRY == "MOTO" then txn.moto = true   end
  if ecrd.FUNCTION == "PRCH" then txn.func = ecrd.FUNCTION; return do_obj_wbc_swipe_insert() 
  elseif ecrd.FUNCTION == "SHFT" then txn.func = ecrd.FUNCTION; return do_obj_shft_reset()
  end
end

function do_obj_iecr_end(rtnvalue)
  if txn.rc == "00" or txn.rc == "08" or txn.rc == "Y1" or txn.rc == "Y3" or txn.rc == "11" then
    ecrd.TID=config.tid
    ecrd.MID=config.mid
    ecrd.AMT=txn.totalamt
    ecrd.INV=config.roc
    if txn.cashamt>0 then ecrd.CASH=txn.cashamt end

    ecrd.CARDTYPE = txn.cardname
    ecrd.CARDNO = txn.cardname .." " .. string.len(txn.fullpan) .. " " .. string.sub(txn.fullpan,-4)
    ecrd.ACCOUNT = (txn.account=="SAVINGS" and "1" or (txn.account == "CHEQUE" and "2") or "4")
	if txn.time and config.timeadjust and #config.timeadjust > 0 and tonumber(config.timeadjust)~=0 then
		txn.time = terminal.Time("MMDDhhmmss")
	end
	ecrd.DATE = txn.time and string.len(txn.time)==10 and string.sub(txn.time,1,4) or txn.time and string.len(txn.time)==14 and string.sub(txn.time,5,8) or terminal.Time("MMDD")
	ecrd.TIME = txn.time and string.len(txn.time)==10 and string.sub(txn.time,5,10) or txn.time and string.len(txn.time)==14 and string.sub(txn.time,9,14) or terminal.Time("hhmmss")
    ecrd.AUTHID = txn.authid or ""
    ecrd.MRECEIPT = txn.mreceipt
    ecrd.RC = txn.rc
    ecrd.CRECEIPT = txn.creceipt
    return do_obj_itaxi_pay_done(rtnvalue)
  else
    return do_obj_itaxi_finish()
  end
end

function do_obj_iecr_chk_manual_password()
  local pwd = terminal.GetJsonValue("CONFIG","MOTO_PWD")
  if pwd == "" then pwd = "110711" end
  return check_pwd(pwd)
end
----------------------------------------

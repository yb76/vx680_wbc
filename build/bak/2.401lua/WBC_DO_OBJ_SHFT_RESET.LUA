function do_obj_shft_reset()
  local scrlines = "WIDELBL,,37,4,C;" .. "WIDELBL,,26,6,C;"
  local screvent,scrinput = terminal.DisplayObject(scrlines,0,0,0)
  local doubleh=""
  local prtvalue=""
  if ecrd.HEADER then prtvalue = ecrd.HEADER else doubleh = "\\h" end
  local mytime1,mytime2=terminal.Time("DD/MM/YY"),terminal.Time("DD/MM/YY           hh:mm")
  local prchamt,cashamt,tipsamt,rfndamt,prchnum,cashnum,tipsnum,rfndnum= terminal.GetJsonValueInt("SHFT","PRCHAMT","CASHAMT","TIPSAMT","RFNDAMT","PRCHNUM","CASHNUM","TIPSNUM","RFNDNUM")
  prchamt=prchamt/100
  cashamt=cashamt/100
  tipsamt=tipsamt/100
  rfndamt=rfndamt/100
  local value="\\C\\f"..doubleh.."------------------------\\n\\C" ..config.servicename.."\\n"..
    "\\C" .. config.merch_loc0 .."\\n" ..
    "\\C" .. config.merch_loc1 .."\\n\\n" ..
    "MERCHANT ID:\\R"..config.mid.."\\n" ..
    "TERMINAL ID:\\R"..config.tid.."\\n\\n"..
    "SHIFT TOTALS\\R"..mytime1.."\\n"..
    "PURCHASE ".. string.format("%03s",prchnum) .."\\R".. string.format("$%.2f",prchamt).."\\n"..
    "CASH OUT ".. string.format("%03s",cashnum) .."\\R".. string.format("$%.2f",cashamt).."\\n"..
    "TIPS     ".. string.format("%03s",tipsnum) .."\\R".. string.format("$%.2f",tipsamt).."\\n"..
    "REFUND   ".. string.format("%03s",rfndnum) .."\\R".. string.format("$%.2f",rfndamt).."\\n"..
    "   NET\\R" ..string.format("$%.2f",(prchamt+cashamt+tipsamt+rfndamt)) .."\\n\\n" ..
    "APPROVED\\n" ..
    "TOTALS RESET\\n\\n" ..
    mytime2.."\\n" ..
    "------------------------\\n"
    ecrd.BODY = value
	prtvalue = prtvalue .. value ..(ecrd.TRAILER or "") .."\\n"
	terminal.Print(prtvalue,true)
	checkPrint(prtvalue)
    terminal.FileRemove("SHFT")
    return do_obj_txn_finish()
end

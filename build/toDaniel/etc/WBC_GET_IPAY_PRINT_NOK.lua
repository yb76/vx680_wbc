function get_ipay_print_nok(who,result_str)
  local cardinfo1,cardinfo2 = "",""
  local s_pan = txn.fullpan and ( string.rep(".",10) .. string.sub(txn.fullpan,-4)) or nil
  local cardentry = ""
  if txn.pan then cardentry = "(M)"
  elseif txn.ctls then cardentry = "(T)"
  elseif txn.chipcard and txn.emv.fallback then cardentry = "(F)"
  elseif txn.chipcard then cardentry = "(C)"
  elseif txn.track2 then cardentry = "(S)"
  end
  cardinfo1 = s_pan and ("\\C"..( txn.cardname and txn.cardname or "") .. "\\n\\C" .. s_pan .. " " .. cardentry .."\\n" ) or ""

  local prttags = ""
  if true or txn.rc == "Z1" or txn.rc == "Z3" or txn.rc == "Z4" then --TESTING
	prttags = txn.emvprint
  elseif txn.chipcard and not txn.emv.fallback and not txn.earlyemv then
	local pds4f,pds50,pds9f26,pds9f12 
	if txn.ctls then
		pds4f,pds50,pds9f26,pds9f12 = get_value_from_tlvs("8400"),get_value_from_tlvs("5000"),get_value_from_tlvs("9F26"),get_value_from_tlvs("9F12")
		if pds4f == "" then pds4f = get_value_from_tlvs("9F06") end
	else
		pds4f,pds50,pds9f26,pds9f12 = terminal.EmvGetTagData(0x4F00,0x5000,0x9F26,0x9F12)
	end
	local cname = ( pds9f12 ~= "" ) and pds9f12 or pds50 
	cname = terminal.StringToHex(cname,#cname)
	cname = string.gsub( cname, "%s+$", "")
	prttags = "AID:\\R"..pds4f.."\\n".." \\R"..cname.."\\n".."AAC:\\R "..pds9f26.."\\n"
  end

  cardinfo2 = prttags

  local func,s_amt = "",""
  local amt = txn.prchamt or 0
  if txn.moto and txn.poscc == "08" then func = "MAIL/PHONE"
  elseif txn.moto and txn.poscc == "59" then func = "E-COMMERCE"
  elseif txn.func =="PRCH" then func = (txn.cashamt and txn.cashamt>0 and "PUR/CASH" or "PURCHASE")
  else func = txn.func
  end

  if txn.prchamt and txn.prchamt>0 then	s_amt = "AMOUNT\\R"..string.format("$%.2f",amt/100) .."\\n"  end
  if txn.totalamt then	s_amt = s_amt .. " \\R---------\\n".. "TOTAL AUD \\R" .. string.format("$%.2f",txn.totalamt/100).. "\\n\\n"  end

  local acc = txn.account and ( "\\4ACCT TYPE:\\R" .. txn.account.. "\\n" ) or ""
  local stan = ""
  if not txn.tcpsent or (txn.offline and txn.rc and txn.rc ~="Z3") or txn.func == "COMP" or ( txn.rc and ( txn.rc == "Y1" or txn.rc == "Y3")) then stan = ""
  else stan =  "BANK REF:\\R"..config.stan.."\\n" end

  local prtvalue = "\\4------------------------------------------\\n" ..
    "\\C\\F" ..( ecrd.HEADER and "" or "\\H") .. who ..
    "\\C\\f" ..( ecrd.HEADER and "" or "\\H") .. config.servicename .."\\n" ..
    "\\C" .. config.merch_loc0 .."\\n" ..
    "\\C" .. config.merch_loc1 .."\\n" ..
    cardinfo1 ..
	acc..
	"TRANS TYPE:\\R" .. func.. "\\n"..
    "TERMINAL ID:\\R" .. config.tid .. "\\n" ..
	(txn.totalamt and ("INV/ROC NO:\\R"..config.roc .."\\n") or "" )..
	stan..
	"DATE/TIME:\\R".. terminal.Time( "DD/MM/YY hh:mm" ) .."\\n"..
	cardinfo2 .. "\\n"..
	s_amt ..
    "\\H".. result_str ..
    "\\4------------------------------------------\\n"
  return prtvalue
end

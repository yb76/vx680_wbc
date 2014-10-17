function get_ipay_print(who,result_ok,result_str)
  local is_merch = ( #who > 8 and (string.sub( who,1,8) == "MERCHANT"))
  local card_exp = ""
  local cardinfo1,cardinfo2 = "",""
  if txn.orig_txnfile then --void or comp/retrieve
    cardinfo1,cardinfo2 = terminal.GetJsonValue( txn.orig_txnfile,"CARDINFO1","CARDINFO2")
  else
	local fullpan = false --(( txn.rc == "Y1" or txn.rc == "Y3" or txn.func == "AUTH" ) and is_merch )
	local s_pan = txn.fullpan and ( fullpan and txn.fullpan or string.rep(".",10) .. string.sub(txn.fullpan,-4)) or ""
	local cardentry = ""
	if txn.pan then cardentry = "(M)"
	elseif txn.ctls then cardentry = "(T)"
	elseif txn.chipcard and txn.emv.fallback then cardentry = "(F)"
	elseif txn.chipcard then cardentry = "(C)"
	elseif txn.track2 then cardentry = "(S)"
	end

	if fullpan then
		local expirydate = ""
		if txn.expiry then expirydate = string.sub(txn.expiry,1,2) .."/" .. string.sub(txn.expiry,3,4)
		elseif txn.track2 then
		  local _,_,_,trk2 = string.find(txn.track2, "(%d*)=(%d*)")
		  expirydate = (trk2 and string.sub(trk2,3,4) .."/" .. string.sub(trk2,1,2) or "")
		elseif txn.chipcard then
		  local f5f24 = terminal.EmvGetTagData(0x5F24)
		  expirydate = (#f5f24>4 and string.sub(f5f24,3,4) .."/" .. string.sub(f5f24,1,2) or "")
		end
		card_exp = ( #expirydate >=4 and "EXPIRY DATE(MM/YY):\\R"..expirydate .."\\n" or "")
	end
	local prt_emv = ""
	if txn.chipcard and not txn.emv.fallback and not txn.earlyemv then
		local pds4f,pds50,pds9f26,pds9f27,pds9f12 
		if txn.ctls then
		  pds4f,pds50,pds9f26,pds9f27,pds9f12 = get_value_from_tlvs("9F06"),get_value_from_tlvs("5000"),get_value_from_tlvs("9F26"),get_value_from_tlvs("9F27"),get_value_from_tlvs("9F12")
		  if pds4f == "" then pds4f = get_value_from_tlvs("8400") end
		else
		  pds4f,pds50,pds9f26,pds9f27,pds9f12 = terminal.EmvGetTagData(0x4F00,0x5000,0x9F26,0x9F27,0x9F12)
		end
		local cname = ( pds9f12 ~= "" ) and pds9f12 or pds50 
		cname = terminal.StringToHex(cname,#cname)
		cname = string.gsub( cname, "%s+$", "")
		local label_9f26 = (pds9f27 == "40" and "TC" or pds9f27 == "80" and "ARQC" or "AAC")  
		prt_emv = "AID:\\R"..pds4f.."\\n".." \\R"..cname.."\\n"..label_9f26..":\\R "..pds9f26.."\\n"
	end
	cardinfo1 = "\\C"..txn.cardname .. "\\n\\C" .. s_pan .. " " .. cardentry .."\\n" 
	local keep_cardinfo1 = "\\C"..txn.cardname .. "\\n\\C" .. string.rep(".",10) .. string.sub(s_pan,-4) .. " " .. cardentry .."\\n\\n" 
	terminal.SetJsonValue("TXN_REQ","CARDINFO1",keep_cardinfo1)
	terminal.SetJsonValue("TXN_REQ","CARDNAME",txn.cardname)
	cardinfo2 = prt_emv
	terminal.SetJsonValue("TXN_REQ","CARDINFO2",cardinfo2)
  end
  local func,s_amt,amt = "","",txn.prchamt
  if txn.moto and txn.poscc == "08" then func = "MAIL/PHONE"
  elseif txn.moto and txn.poscc == "59" then func = "E-COMMERCE"
  elseif txn.func =="PRCH" then func = "PURCHASE"
  else func = txn.func
  end
  local authstr = ""
  if result_ok and txn.authid and #txn.authid > 0 then authstr = "AUTH ID:\\R"..txn.authid.."\\n" end
  if txn.prchamt and txn.prchamt>0 then	s_amt = "AMOUNT\\R"..string.format("$%.2f",amt/100) .."\\n"   end
  s_amt = s_amt .. " \\R---------\\n".. ( "TOTAL AUD \\R" .. string.format("$%.2f",txn.totalamt/100)).. "\\n\\n" 
  local stan = ""
  if not txn.tcpsent or txn.offline or ( txn.rc and ( txn.rc == "Y1" or txn.rc == "Y3")) then stan = ""
  else stan =  "BANK REF:\\R"..config.stan.."\\n" end
  
  local banktime = txn.time and string.len(txn.time)==14 and ( "\\3BANK TIME:\\R"..string.sub(txn.time,7,8).."/"..string.sub(txn.time,5,6).."/"..string.sub(txn.time,3,4).." "..string.sub(txn.time,9,10)..":"..string.sub(txn.time,11,12).."\\n") or "\\n"

  local prtvalue = "\\4------------------------------------------\\n" ..
    "\\C\\F" ..( ecrd.HEADER and "" or "\\H") .. who ..
    "\\C\\f" ..( ecrd.HEADER and "" or "\\H") .. config.servicename .."\\n" ..
    "\\C" .. config.merch_loc0 .."\\n" ..
    "\\C" .. config.merch_loc1 .."\\n" ..
    cardinfo1 ..
	"\\4ACCT TYPE:\\R" .. txn.account.. "\\n"..
	"TRANS TYPE:\\R" .. func.. "\\n"..
    "TERMINAL ID:\\R" .. config.tid .. "\\n" ..
	"INV/ROC NO:\\R"..config.roc.."\\n"..
	stan ..
	"DATE/TIME:\\R".. terminal.Time( "DD/MM/YY hh:mm" ) .."\\n"..
    card_exp ..
	cardinfo2 .."\\n"..
	s_amt ..
    authstr..
    "\\H".. result_str ..
	banktime..
    "\\4------------------------------------------\\n"
  return prtvalue
end

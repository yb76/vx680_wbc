function update_total()
	local cardname = txn.cardname
	if txn.account ~= "CREDIT" then cardname = "DEBIT" end
    local prchnum,prchamt,cashnum,cashamt,rfndnum,rfndamt=terminal.GetJsonValueInt("SHFT","PRCHNUM","PRCHAMT","CASHNUM","CASHAMT","RFNDNUM","RFNDAMT")
    local cr_s_num,cr_s_amt,cr_r_num,cr_r_amt,dr_s_num,dr_s_amt,dr_r_num,dr_r_amt,auth_s_num,auth_s_amt,auth_r_num,auth_r_amt,card_prch_num,card_prch_amt,card_rfnd_num,card_rfnd_amt=
	terminal.GetJsonValueInt("SHFTSTTL","CR_PRCHNUM","CR_PRCHAMT","CR_RFNDNUM","CR_RFNDAMT","DR_PRCHNUM","DR_PRCHAMT","DR_RFNDNUM","DR_RFNDAMT","AUTH_PRCHNUM","AUTH_PRCHAMT","AUTH_RFNDNUM","AUTH_RFNDAMT",cardname.."_PRCHNUM",cardname.."_PRCHAMT",cardname.."_RFNDNUM",cardname.."_RFNDAMT")
    if txn.prchamt>0 and txn.func == "PRCH" then
      terminal.SetJsonValue("SHFT","PRCHAMT",prchamt+txn.prchamt)
      terminal.SetJsonValue("SHFT","PRCHNUM",prchnum+1)
	end
	if txn.totalamt>0 and txn.func == "PRCH" then
      terminal.SetJsonValue("SHFTSTTL",cardname.."_PRCHAMT",card_prch_amt+txn.totalamt)
      terminal.SetJsonValue("SHFTSTTL",cardname.."_PRCHNUM",card_prch_num+1)
      if txn.account == "CREDIT" then
        terminal.SetJsonValue("SHFTSTTL","CR_PRCHAMT",cr_s_amt+txn.totalamt)
        terminal.SetJsonValue("SHFTSTTL","CR_PRCHNUM",cr_s_num+1)
      else
        terminal.SetJsonValue("SHFTSTTL","DR_PRCHAMT",dr_s_amt+txn.totalamt)
        terminal.SetJsonValue("SHFTSTTL","DR_PRCHNUM",dr_s_num+1)
      end
  end
end

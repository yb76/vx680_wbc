function do_obj_logon_req()
   if config.logonstatus == "" then
      config.logonstatus = "195"
      terminal.SetJsonValue("CONFIG","LOGON_STATUS",config.logonstatus)
   end
   local scrlines = "WIDELBL,,25,2,C;" .. ( ("WIDELBL,THIS,STEP "..config.logonstatus)..",3,C;").."WIDELBL,,26,4,C;"
   local screvent,scrinput = terminal.DisplayObject(scrlines,0,0,0)

   local fld60 = ""
   if config.logonstatus == "195" then
      local ktke = terminal.GetJsonValue("IRIS_CFG","KTK")
      local kvc = terminal.Kvc( "",ktke)
      local msg60_195 = { "N,16," .. config.ppid , "b,24," .. kvc, "N,2,09","a,2," .. config.sw_ver, "N,4,0209","a,8,"..config.serialno, "N,4,0006" }
      fld60 = terminal.As2805MakeCustom( msg60_195 )
    elseif config.logonstatus == "194" or config.logonstatus == "193" or config.logonstatus == "001" then
      local kek_ppasn = "11111111"
      local msg60 = { "N,16," .. config.ppid , "b,32," .. kek_ppasn, "a,2," .. config.sw_ver,"a,2,  ", "a,8,"..config.serialno, "N,4,0006" }
      fld60 = terminal.As2805MakeCustom( msg60 )
    end

    local fld47 = ""
    if config.logonstatus == "001" then
      if config.emvactive == "0" then fld47 = "WEM0\\" else fld47 = "WEM1\\" end
      if config.msgenc == "2" then fld47 = fld47 .. "WME2\\"  else fld47 = fld47 .. "WME0\\" end
	  fld47 = terminal.HexToString(fld47)
    end
    local msg_flds = {"0:800","3:920000","11:"..get_next_id("STAN"), "24:000","32:".. config.aiic, "41:"..config.tid, "42:" ..config.mid, "47:"..fld47, "60:"..fld60,"70:".. config.logonstatus}
    local as2805msg = terminal.As2805Make( msg_flds)

    local retmsg = ""
    if as2805msg ~= "" then retmsg = tcpsend(as2805msg) end
    if retmsg ~= "NOERROR" then txn.localerror = true; return do_obj_logon_nok(retmsg)
    else return do_obj_logon_resp() end
end

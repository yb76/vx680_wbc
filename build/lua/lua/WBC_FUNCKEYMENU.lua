function funckeymenu()
  local scrlines = ",,40,2,C;" .. "LHIDDEN,,0,5,17,8;"					   
  local screvent,scrinput = terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,30000)

  if screvent == "KEY_CLR" or screvent == "CANCEL" or screvent=="TIME" then
    return do_obj_txn_finish()
  elseif screvent == "KEY_OK" then
    require ("WBCCONFIG")
    if scrinput == "7410" then
      return do_obj_termconfig()
    elseif scrinput == "3824" then
      return do_obj_termconfig_maintain()
    elseif scrinput == "5295" then
	  if config.tid == "" or config.mid == "" then
			local scrlines = "WIDELBL,,51,2,C;" .. "WIDELBL,,53,4,C;"
			terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,30000)
			return do_obj_txn_finish()
      else return do_obj_logon_init() end
    elseif scrinput == "5296" then
	  terminal.SetJsonValue("CONFIG","LOGON_STATUS","195")
	  config.logonstatus = "195"
      return do_obj_logon_init()
    elseif scrinput == "5297" then
	  config.msgenc = "2"
      return do_obj_logon_init()
    elseif scrinput == "5298" then
	  terminal.SetJsonValue("CONFIG","LOGON_STATUS","194")
	  config.logonstatus = "194"
	  return do_obj_logon_init()
    elseif scrinput == "00100100" then
      return do_obj_swdownload()
    elseif scrinput == "37" then
		local scrlines = "WIDELBL,THIS,DEBUG PRINT,2,C;".."WIDELBL,THIS,"..(config.debugemv and "DISABLE" or "ENABLE").."?,3,C;"
		local screvent = terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,30000)
		if screvent == "KEY_OK" then config.debugemv = not config.debugemv end
		return do_obj_txn_finish()
    elseif scrinput == "5620" then
	  return do_obj_clear_saf()
    elseif scrinput == "5628" then
	  return do_obj_upload_saf()
    elseif scrinput == "3701" then
	  terminal.CTLSEmvGetCfg()
	  return do_obj_txn_finish()
    elseif scrinput == "00200200" then
	  return do_obj_txn_reset_memory()
    elseif scrinput == "987654" then
	  config.no_online = true
	  return do_obj_txn_finish()
    else return do_obj_check_pswd(scrinput)
    end
  end
end

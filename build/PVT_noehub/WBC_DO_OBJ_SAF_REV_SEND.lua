function do_obj_saf_rev_send(fname)
  local safmin,safmax= terminal.GetArrayRange(fname)
  if safmin == safmax then return true
  else
    local msg_flds = {}
    local scrlines_saf = "WIDELBL,THIS,SENDING SAF,2,C;" .."WIDELBL,,26,3,C;"
	local scrlines_rev = "WIDELBL,THIS,SENDING REVERSAL,2,C;" .."WIDELBL,,26,3,C;"
    local retmsg = "NOERROR"
	local ok = false
	for i=safmin,(txn.safonce and safmin or safmax-1) do
      local saffile = fname .. i
      if terminal.FileExist(saffile) then
		ok = false
        local errmsg,fld0,fld2,fld3,fld4,fld11,fld12,fld13,fld14,fld15,fld22,fld23,fld24,fld25,fld32,fld35,fld37,fld38,fld41,fld42,fld47,fld54,fld55,fld39,fld44,fld48,fld62,fld64,repeatsent
        fld0,fld2,fld3,fld4,fld11,fld12,fld13,fld14,fld22,fld23,fld24,fld25,fld32,fld35,fld37,fld38,fld41,fld42,fld47,fld54,fld55,fld62,repeatsent =
          terminal.GetJsonValue(saffile,"0","2", "3", "4", "11","12","13", "14", "22", "23", "24", "25", "32", "35", "37","38", "41", "42", "47", "54", "55","62","SENT")
        if fld0 ~= "220" then fld0 = "400" end
		if fld0 == "400" then terminal.DisplayObject(scrlines_rev,0,0,0) else terminal.DisplayObject(scrlines_saf,0,0,0) end
		if fld0 == "220" and (fld11 == "000000" or fld11 == "0" or fld11 == "") then 
			fld11 = get_next_id("STAN"); fld37 = string.format("%12s",fld11) 
			terminal.SetJsonValue(saffile,"11",fld11)
			terminal.SetJsonValue(saffile,"37",fld37)
		end
        local msg400_flds = {"0:"..fld0,"2:"..fld2,"3:"..fld3,"4:"..fld4,"11:"..fld11,"14:"..fld14,"22:"..fld22,"23:"..fld23,"24:"..fld24,"25:"..fld25,"32:"..fld32,"35:"..fld35,"37:"..fld37,"41:"..fld41,"42:"..fld42,"47:"..fld47,"54:"..fld54,"55:"..fld55, "62:"..fld62, "64:KEY="..config.key_kmacs}
        local msg220_flds = {"0:"..fld0,"2:"..fld2,"3:"..fld3,"4:"..fld4,"11:"..fld11,"12:"..fld12,"13:"..fld13,"14:"..fld14,"22:"..fld22,"23:"..fld23,"24:"..fld24,"25:"..fld25,"32:"..fld32,"35:"..fld35,"37:"..fld37,"38:"..fld38,"41:"..fld41,"42:"..fld42,"47:"..fld47,"54:"..fld54,"55:"..fld55, "62:"..fld62, "64:KEY="..config.key_kmacs}
        local as2805msg = ( fld0 == "220" and terminal.As2805Make(msg220_flds) or terminal.As2805Make(msg400_flds))
		retmsg = tcpconnect()
        if retmsg == "NOERROR" and as2805msg ~= "" then retmsg = tcpsend(as2805msg) end
        if retmsg ~= "NOERROR" then break end
        as2805msg = ""
        retmsg,as2805msg = tcprecv()
        if retmsg ~= "NOERROR" then break end
		if not as2805msg or as2805msg == "" then break end
        local msg_t = { "GET,12","GET,13", "GET,15","IGN,24","GETS,39","GETS,44","GETS,47","GETS,48","GETS,64" }
        if as2805msg ~= "" then
		  errmsg,fld12,fld13,fld15,fld39,fld44,fld47,fld48,fld55,fld64 = terminal.As2805Break( as2805msg, msg_t )
		  local data_nomac,data_mac = string.sub(as2805msg,1,#as2805msg-16),string.sub(as2805msg,-16)
		  local chkmac = terminal.Mac(data_nomac,"",config.key_kmacr)
		  if string.sub(chkmac,1,8) ~= string.sub(data_mac,1,8) or fld39 == "98" then config.logonstatus = "194"; config.logok = false ; check_logon_ok() end
		  if #fld47 > 0 then hosttag_process(fld47) end
		  if #fld48 then sessionkey_update(fld48) end
          if fld39 == "00" then
			terminal.FileRemove(fname..i)
			terminal.SetArrayRange(fname,tostring(i+1),"")
		  end
		  
		  if fld39 ~= "00" then break end
		  ok = true
		end
	  else terminal.SetArrayRange(fname,tostring(i+1),"")
	  end
	end
	if txn.safonce and ( safmin < safmax-1 ) then ok = false end
	saf_rev_check()
	return ok
  end
end

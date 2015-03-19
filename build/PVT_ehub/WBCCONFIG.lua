
local KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6,KEY_7 =0x2,0x4,0x8,0x10,0x20,0x40,0x80
local ScrnTimeout = 30000

function do_obj_check_pswd(pswd)
  if pswd == "9876" then batch_update() end
  return do_obj_txn_finish()
end

function do_obj_termconfig()
  local scrlines = "WIDELBL,,50,5,C;" .. "WIDELBL,,51,7,C;"
  local scrkeys = KEY_1+KEY_2+KEY_5+KEY.CLR+KEY.CNCL
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)

  if screvent == "KEY_1" then
    return do_obj_tid()
  elseif screvent == "KEY_2" then
    return do_obj_mid()
  elseif screvent == "KEY_5" then
    return do_obj_comms_param()
  else
    return do_obj_idle()
  end
end

function do_obj_termconfig_maintain()
  local scrlines = "WIDELBL,,50,5,C;" .. "WIDELBL,,52,7,C;"
  local scrkeys = KEY_1+KEY_2+KEY_3+KEY_4+KEY_5+KEY.CLR+KEY.CNCL
  local screvent,_ = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)

  if screvent == "KEY_1" then
    local scrlines = "WIDELBL,,60,5,C;" .. "WIDELBL,THIS,"..(config.tid or "")..",7,C;"
    local scrkeys = KEY.OK+KEY.CNCL+KEY.CLR
    terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
    return do_obj_termconfig_maintain()
  elseif screvent == "KEY_2" then
    local scrlines = "WIDELBL,,61,5,C;" .. "WIDELBL,THIS,"..(config.mid or "")..",7,C;"
    local scrkeys = KEY.OK+KEY.CNCL+KEY.CLR
    terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
    return do_obj_termconfig_maintain()
  elseif screvent == "KEY_3" then
    local ppid = terminal.Ppid()
    local scrlines = "WIDELBL,THIS,PPID,5,C;" .. "WIDELBL,THIS,"..(ppid or "")..",7,C;"
    local scrkeys = KEY.OK+KEY.CNCL+KEY.CLR
    terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
    return do_obj_termconfig_maintain()
  elseif screvent == "KEY_4" then
    local safmin,safmax = terminal.GetArrayRange("SAF")
	local cnt = safmax - safmin 
    local scrlines = "WIDELBL,THIS,SAF COUNT,5,C;" .. "WIDELBL,THIS,"..cnt..",7,C;"
    local scrkeys = KEY.OK+KEY.CNCL+KEY.CLR
    terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
    return do_obj_termconfig_maintain()
  elseif screvent == "KEY_5" then
    local safmin,safmax = terminal.GetArrayRange("TIPSAF")
	local cnt = safmax - safmin 
    local scrlines = "WIDELBL,THIS,TIPSAF COUNT,5,C;" .. "WIDELBL,THIS,"..cnt..",7,C;"
    local scrkeys = KEY.OK+KEY.CNCL+KEY.CLR
    terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
    return do_obj_termconfig_maintain()  
  else
    return do_obj_idle()
  end
end

function do_obj_tid()
  local tid = terminal.GetJsonValue("CONFIG","TID")
  local safmin,safmax = terminal.GetArrayRange("SAF")

  if tonumber(safmax)>tonumber(safmin) then
    local scrlines = "WIDELBL,,60,5,C;" .. "WIDELBL,THIS,"..(tid or "")..",7,C;"
    local scrkeys = KEY.OK+KEY.CNCL+KEY.CLR
    local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
    return do_obj_termconfig()
  else
    local scrlines = "LARGE,,60,5,C;" .. "LNUMBER,"..tid..",0,7,14,8,8;"
    local scrkeys = KEY.OK+KEY.CNCL
    local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)

    if screvent == "KEY_OK" then
      if scrinput ~= tid then
        terminal.SetJsonValue("CONFIG","TID",scrinput)
        config.tid = scrinput
        terminal.SetJsonValue("iPAY_CFG","TID",scrinput)
        config.logok = false
		if config.logonstatus ~= "195" then
			terminal.SetJsonValue("CONFIG","LOGON_STATUS","194")
			config.logonstatus = "194"
		end
	  end
    end
  end
  return do_obj_termconfig()
end

function do_obj_mid()
  local mid = terminal.GetJsonValue("CONFIG","MID")
  local safmin,safmax = terminal.GetArrayRange("SAF")
  if tonumber(safmax)>tonumber(safmin) then
    local scrlines = "WIDELBL,,61,5,C;" .. "WIDELBL,THIS,"..(config.mid or "")..",7,C;"
    local scrkeys = KEY.OK+KEY.CNCL+KEY.CLR
    local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  else
    local scrlines = "LARGE,,61,5,C;" .. "LNUMBER,"..mid..",0,7,8,15,8;"
    local scrkeys = KEY.OK+KEY.CNCL
    local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)

    if screvent == "KEY_OK" then
      if scrinput ~= mid then
        terminal.SetJsonValue("CONFIG","MID",scrinput)
        config.mid = scrinput
        terminal.SetJsonValue("iPAY_CFG","MID",scrinput)
        config.logok = false
		if config.logonstatus ~= "195" then
			terminal.SetJsonValue("CONFIG","LOGON_STATUS","194")
			config.logonstatus = "194"
		end
	  end
    end
  end
  return do_obj_termconfig()
end

function do_obj_comms_param()
  local changed = false
  local hip,port,apn,tcptm = terminal.GetJsonValue("CONFIG","HIP0","PORT0","APN","BANKTCPTIMEOUT")
  local scrlines = ",THIS,BANK IP ADDRESS,5,C;" .. "STRING,"..hip..",,8,11,15,7;".."BUTTONA,THIS,ALPHA ,B,C;"
  local scrkeys = KEY.OK+KEY.CNCL+KEY.CLR
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "KEY_OK" then
		if scrinput ~= hip and #scrinput>0 then
			changed = true;config.hip = scrinput;terminal.SetJsonValue("CONFIG","HIP0",scrinput) 
		end
		scrlines = ",,223,5,C;" .. "STRING,"..port..",,8,17,5,1;"
		screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
		if screvent == "KEY_OK" then
		  if scrinput ~= port and #scrinput>0 then 
				changed = true;config.port = scrinput;terminal.SetJsonValue("CONFIG","PORT0",scrinput) 
			end
		  scrlines = ",,226,5,C;" .. "STRING,"..apn..",,8,8,19,1;".."BUTTONA,THIS,ALPHA ,B,C;"
		  screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
		  if screvent == "KEY_OK" then
			if scrinput ~= apn and #scrinput>0 then 
					changed = true;config.apn = scrinput;terminal.SetJsonValue("CONFIG","APN",scrinput) 
			end
			if tcptm == "" then tcptm = "30" end
			scrlines = ",THIS,BANK TCP TIMEOUT,5,C;" .. "STRING,"..tcptm..",,8,8,19,1;"
			screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
			if scrinput ~= tcptm and #scrinput>0 then 
				config.tcptimeout = tonumber(scrinput);terminal.SetJsonValue("CONFIG","BANKTCPTIMEOUT",scrinput) 
			end
		  end
		end
  end
  if changed then do_obj_gprs_register() end
  return do_obj_termconfig()
end

function batch_update()
  local batchno = terminal.GetJsonValue("iTAXI_CFG","BATCH")
  local scrlines = "LARGE,THIS,UPDATE BATCH NO?,2,C;".."LARGE,,73,4,C;"
  local screvent = terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,30000)
  if screvent ~= "KEY_OK" then return 0 end 
  local upmsg = "{TYPE:DATA,GROUP:iTAXI,NAME:iTAXI_CFG_INIT,TID:"..config.tid..",BATCH:"..batchno.."}"
  terminal.UploadMsg(upmsg)
  local ver = terminal.GetJsonValue("iTAXI_CFG","VERSION")
  upmsg = "{TYPE:DATA,GROUP:iTAXI,NAME:iTAXI_CFG,VERSION:"..ver.."}"
  terminal.UploadMsg(upmsg)
  scrlines = "LARGE,,27,2,C;" .."LARGE,,26,3,C;"
  terminal.DisplayObject(scrlines,0,0,0)
  batchno = terminal.GetJsonValue("iTAXI_CFG","BATCH")
  terminal.Remote()
  scrlines = "LARGE,THIS,NEW BATCH:"..batchno..",3,C;".."LARGE,THIS,PLEASE RESTART,4,C;"
  terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,30000)
  return 0
end

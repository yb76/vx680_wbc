--
local ScrnTimeout = 20000

function do_obj_comms(nextstep)
  local pwd = terminal.GetJsonValue("IRIS_CFG","COMMS_PWD")
  if pwd == "" then pwd = "165005" end
  local chkpwd_ok = check_pwd(pwd)
  if not chkpwd_ok then
	return nextstep()
  else
	return do_obj_comms_oip(nextstep)
  end
end

function do_obj_comms_oip(nextstep)
  local oip = terminal.GetJsonValue("IRIS_CFG","OIP")
  local scrlines =  ",THIS,TMS APN,2,C;".."STRING,"..oip..",,6,4,22,1;".."BUTTONA,THIS,ALPHA ,B,C;"
  local scrkeys = KEY.OK+KEY.CNCL
  local screvent,scrinput= terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "KEY_OK" then
    if scrinput~= oip then terminal.SetJsonValue("IRIS_CFG","OIP",scrinput) end
	return do_obj_comms_hip(nextstep)
  else
    return nextstep()
  end
end

function do_obj_comms_hip(nextstep)
  local hip = terminal.GetJsonValue("IRIS_CFG","HIP")
  local scrlines =  ",THIS,TMS IP ADDRESS ,2,C;".."STRING,"..hip..",,6,6,20,7;".."BUTTONA,THIS,ALPHA ,B,C;"
  local scrkeys = KEY.OK+KEY.CLR+KEY.CNCL
  local screvent,scrinput= terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "KEY_OK" then
    if scrinput~= hip then terminal.SetJsonValue("IRIS_CFG","HIP",scrinput) end
    return do_obj_comms_port(nextstep)
  elseif screvent == "KEY_CLR" then
    return do_obj_comms_oip(nextstep)
  else
    return nextstep()
  end
end

function do_obj_comms_port(nextstep)
  local port,commstype = terminal.GetJsonValue("IRIS_CFG","PORT","COMMS_TYPE")
  local scrlines =  ",THIS,TMS PORT,2,C;".."STRING,"..port..",,6,18,5,4;"
  local scrkeys = KEY.OK+KEY.CLR+KEY.CNCL
  local screvent,scrinput= terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "KEY_OK" then
    if scrinput~= port then terminal.SetJsonValue("IRIS_CFG","PORT",scrinput) end
    if commstype~= "IP" then terminal.SetJsonValue("IRIS_CFG","COMMS_TYPE","IP") end
    return nextstep()
  elseif screvent == "KEY_CLR" then
    return do_obj_comms_hip(nextstep)
  else
    return nextstep()
  end
end

function check_pwd(pwd)
  local ok = false
  local scrlines = ",,40,2,C;" .. "LHIDDEN,,0,5,17,8;"					   
  local screvent,scrinput = terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "KEY_OK" then
    if pwd == scrinput then ok = true
    else  scrlines = "WIDELBL,,77,2,C;"
		terminal.ErrorBeep()
       terminal.DisplayObject(scrlines,KEY.CNCL,EVT.TIMEOUT,500)
    end
  end
  return ok
end

function check_pwd_moto(pwd)
  local ok = 0
  local scrlines = "WIDELBL,,40,2,C;" .. "LHIDDEN,,0,5,17,8,0;"					   
  local screvent,scrinput = terminal.DisplayObject(scrlines,KEY.CNCL+KEY.OK,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "KEY_OK" then
		if pwd == scrinput then
			ok = 1
			return ok
		else  
			scrlines = "WIDELBL,,77,2,C;"
			terminal.ErrorBeep()
			terminal.DisplayObject(scrlines,KEY.CNCL,EVT.TIMEOUT,500)
			return 2
		end
  elseif screvent == "KEY_CLR" then
		return check_pwd_moto(pwd)
  elseif screvent == "TIME" then
		return 2
  elseif screvent == "CANCEL" then
		return 0
  end
end

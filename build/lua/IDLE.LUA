ScrnTimeout = 30000
ScrnErrTimeout = 10000
ScrnTimeoutZO = 0
ScrnTimeoutTN = 10000
ScrnTimeoutTHR = 3000
ScrnTimeoutHF = 500
--
package.path = "?.lua;I:?.lua"

txn = {}
config = {}
KEY = {}
EVT = {}
ecrd = {}
common = {}
callback = {}
local idlescrlines=nil
local ticknow=terminal.SysTicks()
local idletimeout = 10000
local locked =  (terminal.GetJsonValue("CONFIG","LOCKTERMINAL") == "YES" and true or nil)

function do_obj_idle()
  common = {}; txn = {}; txn.emv = {}; ecrd = {}
  local scrlines = ""
  local scrlines_sale = "BUTTONL_1,THIS,SALE,8,C;BUTTONL_2,THIS,MENU,11,C;"
  local scrkeys  = KEY.LCLR+KEY.FUNC
  local screvents = EVT.TIMEOUT+EVT.MCR+EVT.SCT_IN
  local scrtimeout = 30000
  local battlimit = 10

  if locked then waitforunlock() end
  local charging,batt = terminal.GetBattery()

  if idlescrlines == nil then
    idlescrlines = "BATTERY,,0,-2,32,;"
    .."TIMEDISP,,0,-1,0;"
	.."BUTTONL_1,THIS,SALE,8,C;" 
	.."BUTTONL_2,THIS,MENU,11,C;"
	.."BITMAP,THIS,gmcabs_color.bmp,P60,P0;"
    .."SIGNAL,,0,-2,0;"
  end
  
  local topright = ( config.safsign or "") .. ( config.logok  and "" or "L" )
  local idlescrlines_safsign = idlescrlines .. ( topright ~= "" and (",THIS,"..topright.." ,0,R;" ) or "")
  idlescrlines_safsign = idlescrlines_safsign ..",THIS,"..config.tid..",-1,33,;"

  if batt < battlimit then 
    local scrlines_batt = "BITMAP,THIS,please_recharge.bmp,P180,P20;"
	idlescrlines_safsign = string.gsub(idlescrlines_safsign,scrlines_sale,scrlines_batt)
  end

  local screvent,_ = terminal.DisplayObject(idlescrlines_safsign,scrkeys,screvents,scrtimeout)
  idletimeout = 10000
  if screvent ~= "TIME" then ticknow = terminal.SysTicks() end
  if screvent == "TIME" then 
    local now = terminal.SysTicks()
	if callback.timeout_func[callback.timeout_idx] then 
      callback.timeout_idx = callback.timeout_idx +1
      return callback.timeout_func[callback.timeout_idx-1]() 
	elseif callback.timeout_func[1] then
		callback.timeout_idx = 1
		return callback.timeout_func[1]() 
	elseif batt>= battlimit and ticknow and now - ticknow > 60000 then
	  --PowerSaveMode
	  terminal.PowerSaveMode(0,1,1200000,600000,18000000)
	  ticknow = terminal.SysTicks()
	  return do_obj_idle()
    else
      return do_obj_idle()
    end
  elseif batt<battlimit then
	  return do_obj_idle()
  elseif screvent == "KEY_FUNC" then
    if callback.func_func then return callback.func_func()
    else return do_obj_idle() end
  elseif screvent == "BUTTONL_2" then
    if callback.sk1_func then return callback.sk1_func()
    else return do_obj_idle() end
  elseif screvent == "BUTTONL_1" then
    if callback.sk2_func then return callback.sk2_func()
    else return do_obj_idle() end
  elseif screvent == "KEY_LCLR" then
    if callback.lclr_func then return callback.lclr_func()
    else return do_obj_comms(do_obj_idle) end
  elseif screvent == "MCR" then
    local track2 = terminal.GetTrack(2)
    if not track2 or #track2<10 or not callback.mcr_func then
		terminal.ErrorBeep()
	    return do_obj_idle()
    else common.entry = "SWIPE"; common.track2 = track2; 
	    return callback.mcr_func() 
    end
  elseif screvent == "CHIP_CARD_IN" then
	if callback.chip_func then common.entry = "CHIP"; return callback.chip_func()
		else return do_obj_idle() 
	end
  else
    return do_obj_idle()
  end
end

function load_apps()
  callback.timeout_func = {}
  callback.timeout_idx = 1
  local i = 0
  while true do
    local app = terminal.GetJsonValue("__MENU","APP"..i)
    if app == "" then break 
    else 
      require(app)
    end
    i = i + 1
  end
  require("COMM")
end

function waitforunlock()
  locked =  (terminal.GetJsonValue("CONFIG","LOCKTERMINAL") == "YES" and true or nil)
  if not locked then return 0 end
  while true do
	local scrlines = "WIDELBL,THIS,TERMINAL IS LOCKED,3,C;"
	local screvent= terminal.DisplayObject(scrlines,KEY.FUNC,0,0)
	if screvent == "KEY_FUNC" then
		terminal.UploadObj("iPAY_CFG")
		terminal.Remote()
		locked = terminal.GetJsonValue("CONFIG","LOCKTERMINAL")
		if locked ~= "YES" then break end
	end
  end
end

function init_config()
  KEY.FUNC = 0x400
  KEY.CNCL = 0x800
  KEY.CLR  = 0x1000
  KEY.OK   = 0x2000
  KEY.ASTERISK = 0x2000000
  KEY.LCLR = 0x4000000
  KEY.NO_PIN = 0x8000000

  EVT.TIMEOUT = 0x01
  EVT.SCT_IN  = 0x02
  EVT.SCT_OUT = 0x04
  EVT.MCR     = 0x08
  EVT.SER_DATA = 0x80
  EVT.SER2_DATA = 0x100

  config.model = terminal.Model()
  config.ppid = terminal.Ppid()
  config.serialno= terminal.SerialNo()
  config.servicename,config.merch_loc0,config.merch_loc1 = terminal.GetJsonValue("CONFIG","SERVICENAME","MERCH_LOC0","MERCH_LOC1")
  config.servicename = ( config.servicename ~= "" and config.servicename or "EFTPOS FROM ST GEORGE" )
  config.merch_loc0 = (config.merch_loc0 ~="" and config.merch_loc0 or "GM CABS AUSTRALIA ")
  config.merch_loc1 = (config.merch_loc1 ~="" and config.merch_loc1 or "MASCOT        NSW AU")
  config.logok = false

  local manualentry = terminal.GetJsonValue("CONFIG","MANUALENTRY")
  if manualentry == "YES" then config.manualentry = true else config.manualentry = false end
  config.hostsettle,config.autosettle,config.settledate = terminal.GetJsonValue("CONFIG","HOSTSETTLE","AUTOSETTLE","SETTLEDATE")
  if config.hostsettle ~= "YES" then config.hostsettle = false end
  if config.autosettle ~= "YES" then config.autosettle = false end
  config.key_pin,config.key_kmacr,config.key_kmacs,config.key_kdatar,config.key_kdatas = terminal.GetJsonValue("IRIS_CFG","KPE","KMACr","KMACs","KDr","KDs")
  config.stan,config.roc,config.logonstatus,config.tid,config.mid,config.emvactive,config.msgenc = terminal.GetJsonValue("CONFIG","STAN","ROC","LOGON_STATUS","TID","MID","EMV_ACTIVE","MSG_ENC")
  if config.logonstatus == "" or config.logonstatus == "195" then config.logonstatus = "195" else config.logonstatus = "194" end
  terminal.SetJsonValue("CONFIG","LOGON_STATUS",config.logonstatus)

  if config.roc == "" then config.roc = "000000"; terminal.SetJsonValue("CONFIG","ROC", config.roc) end
  if config.stan == "" then config.stan= "000001"; terminal.SetJsonValue("CONFIG","STAN", config.stan) end
  config.hip,config.port,config.apn = terminal.GetJsonValue("CONFIG","HIP0","PORT0","APN")
  config.sw_ver,config.aiic = terminal.GetJsonValue("ITAXI_CFG","VERSION"),terminal.GetJsonValue("IRIS_CFG","AIIC") 
  if config.sw_ver == "" then config.sw_ver = "10" else config.sw_ver = string.sub(config.sw_ver,-2) end
  if config.aiic == "" then config.aiic = "560192" end
  config.timeadjust = terminal.GetJsonValue("iTAXI_CFG","RISTIMEOFFSET")
  if config.timeadjust == "" or config.timeadjust == "0" then config.timeadjust = nil end
  local fb = terminal.GetJsonValue("CONFIG","EMVFALLBACK")
  config.fallback = (fb~="NO" and true or false)
  config.ehub = terminal.GetJsonValue("CONFIG","EHUB")
  config.tcptimeout = terminal.GetJsonValue("CONFIG","BANKTCPTIMEOUT")
  if config.tcptimeout =="" then config.tcptimeout = "30" end
  if config.ehub ~= "NO" then config.ehub = "YES" end

end

init_config()
terminal.DoTmsCmd()
load_apps()
check_logon_ok()
do_obj_idle()

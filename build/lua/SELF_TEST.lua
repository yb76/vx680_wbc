--
local ScrnBootTimeout = 1000

function do_obj_self_test()
  local model = terminal.Model()
  local KEY_CLR,EVT_TIMEOUT = 0x1000,0x01
  local scrlines = "WIDELBL,,2,4,C;" .. "WIDELBL,THIS,ALL GOOD,6,C;"
  local scrkeys  = KEY_CLR
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT_TIMEOUT,ScrnBootTimeout)
  return do_obj_iris_logo()
end

function do_obj_iris_logo()
  local appname = terminal.GetJsonValue("CONFIG","PAYMENTAPP_NAME")
  if appname == "" then appname = "iPAY" end
  local ApplVer = terminal.GetJsonValue("ITAXI_CFG","VERSION")
  local scrlines =  "WIDELBL,THIS,"..appname..",4,C;".."WIDELBL,THIS,".."V " .. ApplVer..",6,C;"
  local KEY_OK,EVT_TIMEOUT = 0x2000,0x01
  local scrkeys  = KEY_OK
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT_TIMEOUT,ScrnBootTimeout)
  local scrlines = "WIDELBL,,24,4,C;".."WIDELBL,,26,6,C;"
  terminal.DisplayObject(scrlines,0,0,0)
  terminal.SetNextObject("IDLE.lua")
  return 0
end

do_obj_self_test()

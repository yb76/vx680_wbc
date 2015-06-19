--------------------------
package.path = "?.lua"
KEY,EVT={},{}

function init_config()
  KEY.FUNC = 0x400
  KEY.CNCL = 0x800
  KEY.CLR  = 0x1000
  KEY.OK   = 0x2000
  EVT.TIMEOUT = 0x01
end

function do_obj_boot()
  local configname=terminal.GetJsonValue("CONFIG","NAME")
  local ppid=terminal.Ppid()
  local srclines = "WIDELBL,THIS,PLEASE WAIT,4,C;"
  terminal.DisplayObject(srclines,0,0,0)

  if configname == "" or ppid =="" then
    terminal.SetNextObject("KEYS.lua")
    return 0
  else
    terminal.InitCommEng()
    terminal.SetNextObject("SELF_TEST.lua")
    return 0
  end
end

init_config()
do_obj_boot()

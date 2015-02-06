
local KEY,EVT={},{}

function init_config()
  KEY.CNCL = 0x800
  KEY.CLR  = 0x1000
  KEY.OK   = 0x2000
  EVT.SER_DATA = 0x80
end

function do_obj_keys_init()
  local ret = terminal.SerConnect("","0","10","100","115200","8","N","1","")
  local ppid = terminal.Ppid()
  if ppid ~= "" then return do_obj_keys_done()
  else 
    terminal.SecInit()
    return do_obj_keys_wait()
  end
end

function do_obj_keys_wait()
  local scrlines = "WIDELBL,LOCAL_T,6,4,C;" .. "WIDELBL,LOCAL_T,200,6,C;"
  local screvent,_ = terminal.DisplayObject(scrlines,KEY.CNCL,EVT.SER_DATA,0)
  if screvent == "CANCEL" then
    terminal.Reboot()
  elseif screvent == "SER_DATA" then
    local serdata = terminal.SerRecv("")
    return do_obj_keys(serdata)
  end
end

function do_obj_keys(serdata_in)
  local master,sk,ktk = terminal.GetJsonValue("IRIS_CFG","MASTER","SK","KTK")
  local ok = true
  local serdata = terminal.StringToHex( serdata_in,#serdata_in)
  if #serdata < 256 or string.sub(serdata,1,3) ~= "SS," then ok = false end
  if ok then
    local pubk = ""
    _,_,_,pubk= string.find (serdata, "([%a%d]*),([%a%d]*),")
    -- AA BB CCCCCCCC DDDD : AA- modulus length BB-exponent length CCCC: modulus DDDD: exponent
   local kpk_sess = "5"
   ok = terminal.RsaStore(pubk, kpk_sess)
   if ok then
     local kd = "220"
     ok = terminal.DesRandom("16",kd)
     local ePK_kd = terminal.RsaWrap3Des(kpk_sess,kd)
     if ePK_kd == "" then ok = false end
     terminal.SerSend("","06"..ePK_kd)
     local serdata2 = terminal.SerRecv("")
     serdata2 = terminal.StringToHex( serdata2,#serdata2)
     if ok and #serdata2> 50 and string.sub( serdata2,1,3) == "PP," then
       local ppid,ektkman,esk,emaster = "","","",""
       _,_,_,ppid,ektkman,esk,emaster =string.find (serdata2, "([%a%d]*),([%a%d]*),([%a%d]*),([%a%d]*),([%a%d]*)")
       terminal.PpidUpdate(ppid)
       ok = ok and terminal.Derive3Des(ektkman,"",ktk,kd)
       local lkey = string.sub(terminal.GetKey(ktk),1,16)
       ok = ok and terminal.Derive3Des(string.sub(ektkman,-16)..string.sub(ektkman,1,16),"",ktk,kd)
       local rkey = string.sub(terminal.GetKey(ktk),1,16)

       terminal.DesStore(lkey..rkey,"16",ktk)
       ok = ok and terminal.Derive3Des(esk,"",sk,kd)
       ok = ok and terminal.InjectInternalKey("16",master)

       local serialno= terminal.SerialNo()
       local tosend = "06" .. string.format("%10s",serialno)..string.format("%16s",ppid)..terminal.Time("YYMMDDhhmmss")
       terminal.SerSend("",tosend)
       terminal.Sleep(1000)
     else
       ok = false
     end 
   end
  end
  
  if not ok then
    terminal.ErrorBeep()
    return do_obj_keys_wait()
  else 
    return do_obj_keys_done()
  end
end

function do_obj_keys_done()
  local config_t = {}
  local model = terminal.Model()
  local jtable_s = ""
  --local hip,port,apn = "10.1.3.78","10781","STGEFTPOS"
  local hip,port,apn = "192.168.110.69","6552","TNSICOMAU2"
  jtable_s = "{TYPE:DATA,NAME:CONFIG,GROUP:WBC,VERSION:1,HIP0:"..hip..",PORT0:"..port..",APN:"..apn..",MANUALENTRY:YES,HOSTSETTLE:YES,AUTOSETTLE:NO}" 

  terminal.NewObject("CONFIG",jtable_s)
  local ppid = terminal.Ppid()
  local scrlines = "WIDELBL,LOCAL_T,203,4,C;" .."WIDELBL,THIS,"..ppid..",6,C;"
  local screvent,scrinput = terminal.DisplayObject(scrlines,KEY.OK+KEY.CLR+KEY.CNCL,0,0)
  if screvent == "KEY_OK" then 
    terminal.Reboot()
  elseif screvent == "KEY_CLR" or screvent == "CANCEL" then
    terminal.PpidRemove()
    return do_obj_keys_wait()
  end
end

init_config()
do_obj_keys_init()

function do_subobj_itaxi_update()
  local idx , upmsg,upload_ok = 0, "",true
  local scrlines = "WIDELBL,THIS,UPDATE,3,C;".."WIDELBL,THIS,IN PROGRESS,4,C;"..",THIS,**PLEASE WAIT**,7,C"
  local screvent,_=terminal.DisplayObject(scrlines,0,0,0)
  local taxitxn_min,taxitxn_next= terminal.GetArrayRange("iTAXI_TXN")

  for i=taxitxn_min,taxitxn_next-1 do
    local msg = terminal.GetJsonObject("iTAXI_TXN"..i)
    upmsg = upmsg .. msg
    if idx >= 10 or i == taxitxn_next - 1 then 
      if not string.find(upmsg,"NAME:iTAXI_TXN0,") then upmsg = string.gsub(upmsg,"NAME:iTAXI_TXN"..i,"NAME:iTAXI_TXN0") end -- server require one iTAXI_TXN0
      terminal.UploadMsg(upmsg)
      terminal.SetJsonValue("iTAXI_RESULT","TEXT","*")  
      terminal.Remote() 
      local result = terminal.GetJsonValue("iTAXI_RESULT","TEXT")
      if result == "*" then upload_ok=false; break  -- upload failed
      else 
        for k=idx,1,-1 do terminal.FileRemove("iTAXI_TXN"..i-idx+k) end
        terminal.SetArrayRange("iTAXI_TXN",i+1,"")
        idx = 1; upmsg = ""
      end
    end
    idx = idx + 1
  end
  if upload_ok then
    terminal.UploadObj("iPAY_CFG")  
    terminal.SetJsonValue("iTAXI_CFG","BATCH_SENT",taxicfg.batch)
    terminal.UploadObj("iTAXI_CFG")
    terminal.SetJsonValue("iTAXI_RESULT","TEXT","*")  
    terminal.Remote()
    local result = terminal.GetJsonValue("iTAXI_RESULT","TEXT")
    if result == "*" then upload_ok=false end
  else
    terminal.ErrorBeep()
    scrlines = "WIDELBL,THIS,UPLOAD,2,C,;".."WIDELBL,THIS,FAILED,3,C;"
    terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL+KEY.CLR,EVT.TIMEOUT,ScrnErrTimeout)
  end
  return upload_ok 
end

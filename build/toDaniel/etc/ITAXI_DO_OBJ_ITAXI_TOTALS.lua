function do_obj_itaxi_totals()
  local header,trailer = "","\\n\\4\\W\\iINV No.\\RFARE\\n\\4\\W"
  local taxi_min,taxi_next= terminal.GetArrayRange("TAXI")
  local subtotal_d,num_d,tips_d = 0,0,0
  local inv,last_inv,batch = taxicfg.inv,taxicfg.last_inv,taxicfg.batch  

  do_obj_saf_rev_start()
  local rev_exist = config.safsign and string.find(config.safsign,"+")
  local saf_exist = config.safsign and string.find(config.safsign,"*")
  if (saf_exist or rev_exist) then
    scrlines = "WIDELBL,THIS,"..(rev_exist and "REVERSAL" or "")..(saf_exist and " SAF" or "") ..",2,C,;".."WIDELBL,THIS,PENDING,3,C;"
    terminal.DisplayObject(scrlines,KEY.OK,EVT.TIMEOUT,2000)
  end

  local saf_inv = {}
  if saf_exist then
    local safmin,safmax= terminal.GetArrayRange("SAF")
    if safmax > safmin then 
      for i=safmin,safmax-1 do 
        local roc = terminal.GetJsonValue("SAF"..i,"ROC")
        if #roc > 0 then saf_inv[i - safmin + 1] = tonumber(roc) end
      end
	end
  end 
    
  for i = taxi_next-1,taxi_min,-1 do
      local taxifile = "TAXI" .. i
      local inv,subtotal,stan,tip=terminal.GetJsonValue(taxifile,"INV","SUBTOTAL","STAN","TIP")
      if #inv >0 and tonumber(inv)==tonumber(last_inv) then break 
      elseif inv =="" or subtotal=="" then
      else 
        local offline_pending = false
        if stan ~= "" and #saf_inv > 0 then for _,v in ipairs(saf_inv) do if tonumber(v) == tonumber(stan) then offline_pending = true end end end
        subtotal_d = subtotal_d + tonumber(subtotal)
        local itip = (tip=="" and 0 or tonumber(tip))
        tips_d = tips_d + itip
        num_d = num_d + 1
        trailer = trailer .. ( offline_pending and "*" or "") ..string.format("%06s",inv) .."\\R" ..string.format("$%.2f",tonumber(subtotal-itip)/100) .."\\n"
      end
  end

  local s1 = string.format("%-10s%16s","BATCH:","#"..batch)
  local scrlines = ",THIS,"..s1..",0,3;" 
  local inv_s,lastinv_s = "",""
  if num_d > 0 then 
    s1 = string.format("%-10s%16s","FROM INV:","#"..tostring(tonumber(last_inv)+1))
    scrlines = scrlines .. ",THIS,"..s1..",1,3;"
    s1 = string.format("%-10s%16s","TO INV:","#"..tostring(tonumber(inv)-1))
    scrlines = scrlines .. ",THIS,"..s1..",2,3;"
  end
  if tips_d>0 then subtotal_d = subtotal_d - tips_d end
  s1 = string.format("%-10s%16s","TOTAL:",string.format("$%.2f",subtotal_d/100))
  scrlines = scrlines.. ",THIS,"..s1 ..",3,3;"
  scrlines = scrlines.. "WIDELBL,iTAXI_T,110,6,C;" .."WIDELBL,iTAXI_T,111,7,C;" .."BUTTONS_YES,iTAXI_T,105,B,10;"  .."BUTTONS_NO,iTAXI_T,163,B,33;" 
  
  local screvent,_=terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "TIME" then 
    return do_obj_itaxi_finish()
  elseif screvent == "KEY_CLR" or screvent=="BUTTONS_NO" or screvent == "CANCEL" then 
    return do_obj_itaxi_finish()
  elseif screvent == "KEY_OK" or screvent== "BUTTONS_YES" then
    if subtotal_d == 0 then return do_obj_itaxi_totals_not()
    else
 
      local comm,header1,header0,auth_no,abn_no,taxi_no = taxicfg.comm,taxicfg.header1,taxicfg.header0,taxicfg.auth_no,taxicfg.abn_no,taxicfg.taxi_no
      local hdr1 = header1 ..string.format(" %.2f",taxicfg.comm/100) .."%"
      local comm_d = math.floor((subtotal_d+tips_d) * tonumber(comm)/ 10000)
      local payable_d = subtotal_d+tips_d + comm_d
      local batch4 = string.sub( string.format("%06s",batch),3,6)
      local mytime = terminal.Time( "DDMMYYhhmm")
	  local tipstr = tips_d > 0 and ( "TIPS:\\R"..string.format("$%.2f",tips_d/100).."\\n") or ""
      trailer = trailer .." \\R----------\\n" .."TOTAL FARES:\\R"..string.format("$%.2f",subtotal_d/100).."\\n("..
        num_d.." TRANSACTIONS)\\n\\n"..tipstr.."DRIVER BONUS:\\R"..string.format("$%.2f",comm_d/100).."\\n(GST INCL.)\\nDRIVER PAY:\\R"..string.format("$%.2f",payable_d/100).."\\n"
		.."\\4\\W\\C"..hdr1..
        "\\n\\*"..string.format("%04s",batch4)..config.tid..string.format("%06d",payable_d)..mytime..
        "\\3\\C"..string.format("%04s",batch4)..config.tid..string.format("%06d",payable_d)..mytime .."\\n"
      header = "\\ggmcabs.bmp\\n\\4\\W\\C"..header0.."\\n\\C"..hdr1.."\\n\\n\\CDRIVER NO:\\R"..auth_no.."\\n\\CDRVR ABN:\\R"..abn_no.."\\n\\CTAXI NO:\\R" ..
        taxi_no.."\\n\\n\\CBatch #:"..batch.."\\n\\n"

      local inv,batch= taxicfg.inv, taxicfg.batch

      taxicfg.batch = string.format("%06d",tonumber(taxicfg.batch) + 1)
      taxicfg.last_inv = string.format("%06d",tonumber(taxicfg.inv) - 1)
      taxicfg.auth_no = ""
      taxicfg.abn_no = ""
      taxicfg.taxi_no = ""
      terminal.SetJsonValue("iTAXI_CFG","BATCH",taxicfg.batch)
      terminal.SetJsonValue("iTAXI_CFG","LAST_INV",taxicfg.last_inv)
      terminal.SetJsonValue("iTAXI_CFG","ABN_NO","")
      terminal.SetJsonValue("iTAXI_CFG","AUTH_NO","")
      terminal.SetJsonValue("iTAXI_CFG","TAXI_NO","")

      ecrd = {}
      ecrd.FUNCTION = "SHFT"
      ecrd.RETURN = do_obj_itaxi_totals_done
      ecrd.HEADER = header; ecrd.TRAILER=trailer
      return do_obj_iecr_start()
    end
  end
end

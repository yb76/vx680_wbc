function do_obj_itaxi_reprint_do(inv_p,rcptfile)
  local inv,found,taxifile=0,false,""
  if rcptfile then taxifile = rcptfile; found = true
  else
    local taxi_min,taxi_next= terminal.GetArrayRange("TAXI")
    if taxi_next == taxi_min then found = false
    elseif inv_p == nil then taxifile = "TAXI"..tostring(taxi_next-1);found = true 
    else 
        for i = taxi_next-1,taxi_min,-1 do
            taxifile = "TAXI" .. i
            inv = tonumber(terminal.GetJsonValue(taxifile,"INV"))
            if inv == inv_p then found = true; break end
        end
    end
  end
  
  if not found then return do_obj_itaxi_reprint_no_inv()
  else
    local dup_str = "\\4\\W\\i   ** DUPLICATE **   \\n"
    local scrlines = ",THIS,REPRINT,-1,C;" .."WIDELBL,iTAXI_T,122,3,C;" .."WIDELBL,iTAXI_T,123,4,C;" 
    terminal.DisplayObject(scrlines,0,0,0)
    local header,header_ok,mreceipt,trailer,trailer_ok,CustRcpt = terminal.GetJsonValue(taxifile,"HEADER","HEADER_OK","MRECEIPT","TRAILER","TRAILER_OK","CRCPT")
    terminal.Print(header,false)
    terminal.Print(dup_str,false)
    if #header_ok > 0 then terminal.Print(header_ok,false); terminal.Print(dup_str,false) end
    terminal.Print(mreceipt,false)
    terminal.Print(dup_str,false)
    terminal.Print(trailer,false)
    
    if trailer_ok and #trailer_ok > 0 then terminal.Print(trailer_ok,false) end
    terminal.Print("\\n",true)
    
	local scrlines = "WIDELBL,,36,4,C;" .."BUTTONS_1,THIS,YES,8,10;".. "BUTTONS_2,THIS,NO,8,33;"
	local screvent,_ = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL,EVT.TIMEOUT,ScrnTimeout)
	if screvent == "BUTTONS_1" or screvent == "TIME" or screvent == "KEY_OK" then
		scrlines = "WIDELBL,,37,2,C;" .."WIDELBL,,26,4,C;"
		terminal.DisplayObject(scrlines,0,0,ScrnTimeoutZO)
		local who = "\\CCUSTOMER\\n\\CCOPY\\n"
		terminal.Print(header,false)
		terminal.Print(dup_str,false)
		if trailer_ok and #trailer_ok > 0 then terminal.Print(header_ok,false); terminal.Print(dup_str,false) end
		terminal.Print(CustRcpt,false)
		terminal.Print(dup_str,false)
		terminal.Print(trailer,false)
		if trailer_ok and #trailer_ok > 0 then terminal.Print(trailer_ok,false) end
		terminal.Print("\\n",true)
	end
    return do_obj_itaxi_fmenu()
  end
end

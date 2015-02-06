function do_obj_itaxi_retotal(fileno)
    local batchno = 0
    local shftfile = nil
    local scrlines,screvent,scrinput ="","",""
    if not fileno then
        scrlines = ",THIS,REPRINT,-1,C;" ..",iTAXI_T,124,5,C;".."LNUMBER,,0,7,15,6,1;".."BUTTONL,THIS,PRINT,B,C"
        screvent,scrinput = terminal.DisplayObject(scrlines,KEY.OK+KEY.CNCL+KEY.CLR,EVT.TIMEOUT,30000)
        batchno = (scrinput and #scrinput>0 and tonumber(scrinput) or 0)
        if batchno > 0 and ( screvent == "KEY_OK" or screvent == "BUTTONL" ) then
            local shft_min,shft_next= terminal.GetArrayRange("PREV_SHFT")
            for i = shft_next-1,shft_min,-1 do
              local bch = terminal.GetJsonValue("PREV_SHFT"..i,"BATCH")
              if bch ~= "" and tonumber(bch) == batchno then shftfile= "PREV_SHFT"..i; break end
            end
        end
    else shftfile = "PREV_SHFT"..fileno
    end

    if screvent == "KEY_CLR" then
        return do_obj_itaxi_reprint_menu()
    elseif screvent == "TIME" or screvent=="CANCEL" then
        return do_obj_itaxi_finish()
    elseif not shftfile then return do_obj_itaxi_retotal_no_batch()
    else
        local header,body,trailer = terminal.GetJsonValue(shftfile,"HEADER","BODY","TRAILER")
        local dup_str = "\\4\\W\\i   ** DUPLICATE **   \\n"
        local scrlines = "WIDELBL,iTAXI_T,122,2,C;" .."WIDELBL,iTAXI_T,123,3,C;" 
        terminal.DisplayObject(scrlines,0,0,0)
        local prtvalue = header..dup_str..body..dup_str..trailer..dup_str.."\n\n"
        terminal.Print(prtvalue,true)
        checkPrint(dup_str)
        return do_obj_itaxi_fmenu()
    end
end

function do_obj_itaxi_abn_option()
  local scrlines = "LARGE,iTAXI_T,7,2,C;" .."LARGE,THIS,PRINT ABN IF TOTAL IS,5,C;".."LARGE,THIS,LESS OR EQUAL $75?,6,C;".."BUTTONS_1,THIS,YES,8,10;".. "BUTTONS_2,THIS,NO,8,33;"
  local scrkeys  = KEY.CNCL
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  if screvent == "BUTTONS_1" and taxicfg.abn_skip then
    taxicfg.abn_skip = nil
    terminal.SetJsonValue("ITAXI_OPTIONS","ABN_SKIP","NO")
  elseif screvent == "BUTTONS_2" and not taxicfg.abn_skip then
    taxicfg.abn_skip = true
    terminal.SetJsonValue("ITAXI_OPTIONS","ABN_SKIP","YES")
  end
  return do_obj_itaxi_smenu()
end

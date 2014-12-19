function do_obj_itaxi_trailer12 ()
  local scrlines = "LARGE,iTAXI_T,50,2,C;" .."BUTTONM_1,iTAXI_T,60,5,C;" .."BUTTONM_2,iTAXI_T,61,7,C;".."BUTTONM_3,iTAXI_T,62,9,C;"
  local scrkeys  = KEY.CLR+KEY.CNCL
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  local nextstep = do_obj_itaxi_smenu
  if screvent == "BUTTONM_1" then
        scrlines = "LARGE,iTAXI_T,52,2,C;" .."STRING,"..taxicfg.trailer0..",0,6,3,30;".."BUTTONA,THIS,ALPHA ,B,C;"
        screvent,scrinput = terminal.DisplayObject(scrlines,KEY.CLR+KEY.CNCL+KEY.OK,EVT.TIMEOUT,ScrnTimeout)
        if screvent == "KEY_OK" and scrinput ~= taxicfg.trailer0 then
            terminal.SetJsonValue("iTAXI_CFG","TRAILER0",scrinput)
            taxicfg.trailer0 = scrinput
        end
  elseif screvent == "BUTTONM_2" then
        scrlines = "LARGE,iTAXI_T,53,2,C;" .."STRING,"..taxicfg.trailer1..",0,6,3,30;".."BUTTONA,THIS,ALPHA ,B,C;"
        screvent,scrinput = terminal.DisplayObject(scrlines,KEY.CLR+KEY.CNCL+KEY.OK,EVT.TIMEOUT,ScrnTimeout)
        if screvent == "KEY_OK" and scrinput ~= taxicfg.trailer1 then
            terminal.SetJsonValue("iTAXI_CFG","TRAILER1",scrinput)
            taxicfg.trailer1 = scrinput
        end
  elseif screvent == "BUTTONM_3" then
        scrlines = "LARGE,iTAXI_T,54,2,C;" .."STRING,"..taxicfg.trailer2..",0,6,3,30;".."BUTTONA,THIS,ALPHA ,B,C;"
        screvent,scrinput = terminal.DisplayObject(scrlines,KEY.CLR+KEY.CNCL+KEY.OK,EVT.TIMEOUT,ScrnTimeout)
        if screvent == "KEY_OK" and scrinput ~= taxicfg.trailer2 then
            terminal.SetJsonValue("iTAXI_CFG","TRAILER2",scrinput)
            taxicfg.trailer2 = scrinput
        end
  end
  return nextstep()
end

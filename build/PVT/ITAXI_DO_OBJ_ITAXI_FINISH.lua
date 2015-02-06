function do_obj_itaxi_finish()
  if taxi.chipcard then terminal.EmvPowerOff()
    if terminal.EmvIsCardPresent() then
        local scrlines = "WIDELBL,,286,2,C;"
        terminal.DisplayObject(scrlines,0,EVT.SCT_OUT,0)
    end
  end
  if taxi.finishreturn then return taxi.finishreturn
  else 
    if taxi.reconnect then do_obj_gprs_register() end
    taxi = {};  common = {}; return do_obj_idle() 
  end
end

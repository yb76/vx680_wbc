function do_obj_itaxi_pay_swipe()
  local amt = taxi.subtotal + taxi.serv_gst
  local ddmm = terminal.Time("DDMM")
  local dd,mm = tonumber(string.sub(ddmm,1,2)),tonumber(string.sub(ddmm,3,4))
  if taxicfg.day ~= dd then 
    taxicfg.day = dd
    taxicfg.daily = 0
    terminal.SetJsonValue("iTAXI_CFG","DAY",dd)
    terminal.SetJsonValue("iTAXI_CFG","DAILY","0")
  end
  if taxicfg.month ~= mm then 
    taxicfg.month = mm
    taxicfg.monthly = 0
    terminal.SetJsonValue("iTAXI_CFG","MONTH",mm)
    terminal.SetJsonValue("iTAXI_CFG","MONTHLY","0")
  end 
  if amt + taxicfg.daily > taxicfg.day_limit then return do_obj_pay_above_limit("DAY", taxicfg.day_limit)
  elseif amt + taxicfg.monthly > taxicfg.month_limit then return do_obj_pay_above_limit("MONTH", taxicfg.month_limit)
  else return do_obj_itaxi_pay_do()
  end
end

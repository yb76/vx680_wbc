function do_obj_itaxi_select_driver()
  taxicfg.serv_gst,taxicfg.comm = terminal.GetJsonValueInt("iTAXI_CFG","SERV_GST","COMM") -- this might have been switched to hire car value
  if taxicfg.h_comm == 0 then taxicfg.h_comm = 300 end
  if taxicfg.h_serv_gst == 0 then taxicfg.h_serv_gst = 1100 end
  local line1 = "TAXI DRIVER"
  local line2 = "HIRE CAR DRIVER"
  local line1txt = "SERVICE FEE:"..tostring(taxicfg.serv_gst/100.0).."% COMM:"..tostring(taxicfg.comm/100.0).."%"
  local line2txt = "SERVICE FEE:"..tostring(taxicfg.h_serv_gst/100.0).."% COMM:"..tostring(taxicfg.h_comm/100.0).."%"
  local scrlines = ",THIS,ENTER DRIVER TYPE,1,C;" .. "BUTTONL_1,THIS,"..line1..",P113,C;"..",THIS,"..line1txt..",6,C;".. "BUTTONL_2,THIS,"..line2..",P236,C;"..",THIS,"..line2txt..",12,C;"
  local scrkeys = KEY.CNCL
  local screvent,scrinput = terminal.DisplayObject(scrlines,scrkeys,EVT.TIMEOUT,ScrnTimeout)
  taxicfg.hire = nil
  if screvent == "BUTTONL_1" then
    return do_obj_itaxi_taxi_no()
  elseif screvent == "BUTTONL_2" then
	taxicfg.comm = taxicfg.h_comm
	taxicfg.serv_gst = taxicfg.h_serv_gst
	taxicfg.hire = true
    terminal.SetJsonValue("iTAXI_CFG","DRIVERTYPE","HIRE")
    return do_obj_itaxi_taxi_no()
  else
    return do_obj_itaxi_sign_on()
  end
end

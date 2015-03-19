function do_obj_logon_start()
  local rc = ""
  local tcpreturn = tcpconnect()
  if tcpreturn == "NOERROR" then
    return do_obj_logon_req()
  else
    return do_obj_logon_nok(tcpreturn)
  end
end

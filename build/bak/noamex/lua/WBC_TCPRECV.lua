function tcprecv()
  local rcvmsg,tcperrmsg ="",""
  tcperrmsg,rcvmsg = terminal.TcpRecv("2000",config.tcptimeout)
  if tcperrmsg == "NOERROR" and #rcvmsg > 4 and config.msgenc == "2" then
    local mti = string.sub(rcvmsg,1,4)
    if mti == "0110" or mti=="0210" or mti == "0230" or mti == "0410" then
		rcvmsg = mti .. msg_enc( "D", string.sub(rcvmsg,5))
	end
  end
  if tcperrmsg ~= "NOERROR" and tcperrmsg ~= "TIMEOUT" and tcperrmsg ~= "NO_RESPONSE" then tcperrmsg = "NO_RESPONSE" end
  return tcperrmsg,rcvmsg
end

function tcpsend(msg)
  local tcperrmsg = ""
  local mti = ( msg and #msg > 4 and string.sub(msg,1,4) or "")
  if config.msgenc == "2" and ( mti == "0100" or mti=="0200" or mti == "0220" or mti == "0400") then
	msg = mti .. msg_enc( "E", string.sub(msg,5))
  end
  if mti == "0200" then debugPrint(msg) end
  tcperrmsg = terminal.TcpSend(msg)
  txn.tcpsent = true
  return(tcperrmsg)
end

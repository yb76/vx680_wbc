function tcpconnect()
  if not config.tcptimeout then config.tcptimeout = 30 end
  local tcperrmsg = terminal.TcpConnect( "6",config.apn,"B1","0","",config.hip,config.port,config.tcptimeout,"4096","10000") -- "6" CLNP
  return(tcperrmsg)
end

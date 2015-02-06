function msg_enc (method,msg)
	local newmsg,iv,ivrn = "","",""
	if method == "E" then
		ivrn = string.format("%06d",math.random(100000,999999))
		iv = "5757575757"..ivrn
		newmsg = terminal.Enc(msg,"","16",config.key_kdatas,iv)..ivrn.. terminal.HexToString(config.tid..string.format("%-15s",config.mid).."WME").."03"
	elseif method == "D" then

		local tail = string.sub( msg, -52)
		iv = "5757575757".. string.sub(tail,1,6)
		local msg_notail = string.sub(msg,1, #msg - 52 )
		newmsg = terminal.Enc(msg_notail,"","16",config.key_kdatar,iv)
	end
	return newmsg 
end

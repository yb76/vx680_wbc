function debugPrint(msg)
	local maxlen = #msg
	local idx = 1
	if not maxlen or maxlen ==0 then return end
	while true do
		terminal.Print("\\4"..string.sub(msg, idx, idx+125).."\\n", false)
		idx = idx + 126
		if idx > maxlen then break end
	end
	terminal.Print("\\n", true)
end

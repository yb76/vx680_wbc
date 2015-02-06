function debugPrint(msg)
	local maxlen = #msg
	local idx = 0
	while true do
		terminal.Print("\\4"..string.sub(msg, idx, idx+199).."\\n", false)
		idx = idx + 200
		if idx > maxlen then break end
	end
	terminal.Print("\\n", true)
end

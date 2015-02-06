function hosttag_process(fld47)
  if #fld47 > 0 then
	local stags = terminal.StringToHex(fld47,#fld47)
	local i = 1
	for tag in string.gmatch(stags, "%w+") do 
		local name,value = string.sub(tag,1,3),string.sub(tag,4)
		if name == "WMC" then
		  terminal.SetJsonValue("CONFIG","MCC",value)
		elseif name == "WTC" then
		  terminal.SetJsonValue("CONFIG","TCC",value)
		elseif name == "WKR" then
		  terminal.FileRemove(string.sub(value,10).."."..string.sub(value,-2))
		end
	end
  end
end

function jsontable2string( jtable_t)
  local jsontag, jsonvalue, jtable_s = "","",""
  for jsontag,jsonvalue in pairs(jtable_t) do
    if jtable_s == "" then jtable_s = "{" .. jsontag .. ":" .. jsonvalue
    else jtable_s = jtable_s .. "," .. jsontag .. ":" .. jsonvalue end
  end
  if #jtable_s > 0 then jtable_s = jtable_s .."}" end
  return jtable_s
end

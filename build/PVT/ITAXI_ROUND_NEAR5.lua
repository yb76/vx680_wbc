function round_near5(num_input)
  local iret = 0
  local num10 = math.floor(num_input/10)*10
  local num_left = num_input - num10
  if num_left >= 7.50 then iret = num10 + 10
  elseif num_left < 2.5 then iret = num10
  else iret = num10 + 5 end
  return (iret)
end

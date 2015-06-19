function do_obj_emv_error(emvstat)
 if emvstat == 146 then
  txn.chipcard = nil
  return do_obj_swipecard(true)
 else
  local scrlines,linestr="",""
  local gemv_techfallback = terminal.EmvGlobal("GET","TECHFALLBACK")
  gemv_techfallback = gemv_techfallback and config.fallback
  --if emvstat == 146 and gemv_techfallback then gemv_techfallback = false end
  local screvents = EVT.TIMEOUT
  local scrkeys = KEY.OK+KEY.CNCL

  if terminal.EmvIsCardPresent() then 
	linestr = "WIDELBL,THIS,REMOVE CARD,4,C;"
	screvents = EVT.SCT_OUT 
	scrkeys = 0
  end
  txn.emv_retry = not txn.emv_retry
  if txn.emv_retry then
    linestr = "WIDELBL,THIS,PLEASE RETRY,4,C;"; txn.emv.fallback = false
  elseif gemv_techfallback then txn.emv.fallback = true;linestr = "WIDELBL,THIS,USE FALLBACK,4,C;" end
  --NO_ATR
  if emvstat == 157 then scrlines = "WIDELBL,THIS,NO ATR,2,C;" ..linestr
  elseif emvstat==101 then scrlines="WIDELBL,,277,2,C;"..linestr
  elseif emvstat==103 then scrlines="WIDELBL,,283,2,C;"..linestr
  elseif emvstat==104 then scrlines="WIDELBL,,275,2,C;"..linestr
  elseif emvstat==106 then scrlines="WIDELBL,,282,2,C;"..linestr
  elseif emvstat==107 then scrlines="WIDELBL,,276,2,C;"..linestr
  elseif emvstat==108 then scrlines="WIDELBL,,281,2,C;"..linestr
  elseif emvstat==112 then scrlines="WIDELBL,,273,2,C;".."WIDELBL,,274,3,C;"..linestr
  elseif emvstat==113 then scrlines="WIDELBL,,276,2,C;".."WIDELBL,,274,3,C;"..linestr
  elseif emvstat==114 or emvstat==119 then scrlines="WIDELBL,,276,2,C;".."WIDELBL,,272,3,C;"..linestr
  elseif emvstat==116 then scrlines="WIDELBL,,120,2,C;"..linestr
  elseif emvstat==118 then scrlines="WIDELBL,,275,2,C;".."WIDELBL,,274,3,C;"..linestr
  elseif emvstat==125 then scrlines="WIDELBL,,285,2,C;"..linestr
  elseif emvstat==146 then scrlines="WIDELBL,,288,2,C;".."WIDELBL,,289,3,C;"..linestr
  else scrlines="WIDELBL,,276,2,C;"..linestr
  end
  terminal.DisplayObject(scrlines,scrkeys,screvents,3000)
  if gemv_techfallback or txn.emv_retry then return do_obj_swipecard()
  else return do_obj_txn_finish() end 
 end
end

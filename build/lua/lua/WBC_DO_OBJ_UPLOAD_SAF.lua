function do_obj_upload_saf()
  local scrlines = "WIDELBL,THIS,UPLOAD ,2,C;" .. "WIDELBL,THIS,REVERSAL/SAF,3,C;".."BUTTONS_YES,THIS,YES,B,10;"  .."BUTTONS_NO,THIS,NO,B,33;"
  local screvent = terminal.DisplayObject(scrlines,KEY.CNCL+KEY.CLR+KEY.OK,EVT.TIMEOUT,30000)
  if screvent == "BUTTONS_YES" or screvent == "KEY_OK" then return do_obj_saf_rev_start(do_obj_txn_finish)
  else return do_obj_txn_finish(true) end
end

function do_obj_itaxi_totals_done()

  local shft_min,shft_next= terminal.GetArrayRange("PREV_SHFT")
  if shft_next - shft_min > taxicfg.max_kept_batch then
    terminal.SetArrayRange("PREV_SHFT",shft_min+1,"")
    terminal.FileRemove("PREV_SHFT"..shft_min)
  end
  local shft_nextfile = "PREV_SHFT"..shft_next
  local lastbatch = string.format("%06d",tonumber(taxicfg.batch) - 1)
  local SHFT= { TYPE="DATA",NAME=shft_nextfile,GROUP="WBC",VERSION="1",BATCH=lastbatch,
    HEADER=ecrd.HEADER, BODY=ecrd.BODY, TRAILER=ecrd.TRAILER}
    terminal.SetArrayRange("PREV_SHFT","",shft_next+1)
  local shftstr = jsontable2string (SHFT)
  terminal.NewObject(shft_nextfile,shftstr)
  ecrd ={}
  do_subobj_itaxi_update()
  do_obj_gprs_register()
  return do_obj_itaxi_sign_on()
end

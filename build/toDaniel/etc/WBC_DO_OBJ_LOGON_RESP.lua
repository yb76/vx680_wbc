function do_obj_logon_resp()
  local errmsg, rcvmsg = tcprecv()
  if errmsg ~= "NOERROR" then
    txn.localerror = true
    return do_obj_logon_nok(errmsg)
  elseif not rcvmsg or rcvmsg == "" then
    txn.localerror = true
	return do_obj_logon_nok("NO_RESPONSE")
  else
    local msg_t = {"GET,12","GET,13","GETS,39","GETS,44","GETS,47","GET,48","GET,70" }
    local errmsg,fld12,fld13,fld39,fld44,fld47,fld48,fld70 = terminal.As2805Break( rcvmsg, msg_t )
    if fld39 and #fld39>0 then txn.rc = fld39 end
    if fld44 and #fld44>0 then txn.rc_desc = fld44 end
    if errmsg ~= "NOERROR" then return do_obj_logon_nok(errmsg)
    elseif fld39 ~= "00" then return do_obj_logon_nok(fld39)
    elseif tonumber(fld70) == 195 then
      local pdh = string.sub(fld48, 1, 68 )
      local ekd = string.sub(fld48, 37 , 68 )
      local pdhmac = string.sub(fld48, 69 , 76)
      local ettab = string.sub(fld48, 77)

      local key_ktkman,key_ktkspn = terminal.GetJsonValue("IRIS_CFG", "KTK","KTKSPN")
      local ok = terminal.Derive3Des( ekd,"",config.key_kdatar,key_ktkman)
      local chkmac = terminal.Mac(pdh,"A200",config.key_kdatar)

      if string.sub(chkmac,1,8) ~= pdhmac then return do_obj_logon_nok("MAC")
      else
        local dttab = terminal.Dec(ettab,"",16,config.key_kdatar)
        local payload = string.sub(dttab,1,46)
        local plmac = string.sub(dttab,47,54)

        local ktkdata = string.sub(dttab,53,84)
        if terminal.DesStore( ktkdata,16,key_ktkspn) == false  then return do_obj_logon_nok("KTKSPN")
        else
            terminal.SetJsonValue("CONFIG","LOGON_STATUS","194")
            config.logonstatus = "194"
            return do_obj_logon_req()
        end
      end
    elseif tonumber(fld70) == 194  then
      local pdh = string.sub(fld48, 1, 68 )
      local ekd = string.sub(fld48, 37 , 68 )
      local pdhmac = string.sub(fld48, 69 , 76)
      local ewtab = string.sub(fld48, 77)

      local key_ktkspn,key_ktma,key_ktmb = terminal.GetJsonValue("IRIS_CFG", "KTKSPN","KTMA","KTMB")
      local ok = terminal.Derive3Des( ekd,"",config.key_kdatar,key_ktkspn)
      local chkmac = terminal.Mac(pdh,"A200",config.key_kdatar)
      if string.sub(chkmac,1,8) ~= pdhmac then return do_obj_logon_nok("MAC")
      else
        local dwtab = terminal.Dec(ewtab,"",16,config.key_kdatar)
        local keycount = string.sub(dwtab,21,24)

        local idx,i = 25, 1
        if keycount == "0003" or keycount == "0005" then
          while i <= tonumber(keycount) do
            local keytype = string.sub(dwtab, idx, idx + 3) ; idx = idx + 4
            local keyver = string.sub(dwtab, idx, idx + 7) ; idx = idx + 8
            local keydata = string.sub(dwtab, idx, idx + 31); idx = idx + 32
            if keytype == "0007" then terminal.DesStore( keydata,16,key_ktma)
            elseif keytype == "0008" then terminal.DesStore( keydata,16,key_ktmb)
            end
            i = i + 1
          end
        end
        idx = idx + 4
        local payload = string.sub(dwtab,1,idx - 1)
        terminal.SetJsonValue("CONFIG","LOGON_STATUS","193")
        config.logonstatus = "193"
        return do_obj_logon_req()
      end
    elseif tonumber(fld70) == 193  then
      local key_ktma,key_ktmb,key_kek1,key_kek2,key_ppasn = terminal.GetJsonValue("IRIS_CFG","KTMA","KTMB","KEK1","KEK2","PPASN")
      local key_ind = string.sub(fld48, 1, 2 )
      local ktm
      if key_ind == "41" then key_ind = "A"; ktm = key_ktma
      elseif key_ind == "42" then key_ind = "B" ; ktm = key_ktmb end

      local ekek1 = string.sub(fld48, 3 , 34 )
      local ekek2 = string.sub(fld48, 35 , 66 )
      local eppasn = string.sub(fld48, 67 , 82)

      local ok = terminal.Derive3Des( ekek1,"",key_kek1,ktm)
      ok = terminal.Derive3Des( ekek2,"",key_kek2,ktm)
      local ppasn = terminal.Dec( eppasn,"8888","16",ktm)
      terminal.SetJsonValue("CONFIG","PPASN",ppasn)
      ok = terminal.DesStore( ppasn, "8", key_ppasn)

      if key_ind == "A" then terminal.SetJsonValue("CONFIG","LOGON_STATUS","001");config.logonstatus = "001"
      elseif key_ind == "B" then terminal.SetJsonValue("CONFIG","LOGON_STATUS","001");config.logonstatus = "001" end
      return do_obj_logon_req()

    elseif tonumber(fld70) == 1  then
	  if #fld47 > 0 then hosttag_process(fld47) end
      local ok = sessionkey_update(fld48)
      if ok then config.logok = true; return do_obj_logon_ok()
      else terminal.SetJsonValue("CONFIG","LOGON_STATUS","194");config.logonstatus = "194" end
    else
      if config.logonstatus ~= "195" then config.logonstatus = "194" end
      return do_obj_logon_req()
    end
  end
end

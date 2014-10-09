function sessionkey_update(fld48)
    local key_kek1,key_kek2,key_kdr,key_kds,key_kmacr,key_kmacs,key_pin,key_ppasn = terminal.GetJsonValue("IRIS_CFG","KEK1","KEK2","KDr","KDs","KMACr","KMACs","KPE","PPASN")
    local key_ind = string.sub(fld48, 1, 2 )
    local emacs,edatas,emacr,epin,edatar
    local ok = false

    emacr = string.sub(fld48,3,34)
    edatar = string.sub(fld48,35,66)
    emacs = string.sub(fld48,67,98)
    epin = string.sub(fld48,99,130)
    edatas = string.sub(fld48,131,162)
    if key_ind == "31" then
      ok = terminal.Owf(key_ppasn,key_kek1,key_kek1,0)
    elseif key_ind == "32" then
      ok = terminal.Owf(key_ppasn,key_kek1,key_kek2,1)
      ok = terminal.Owf(key_ppasn,key_kek2,key_kek2,0)
    end
    ok = ok and terminal.Derive3Des( emacr,"24C0",key_kmacr,key_kek1)
    ok = ok and terminal.Derive3Des( edatar,"22C0",key_kdr,key_kek1)
    ok = ok and terminal.Derive3Des( emacs,"48C0",key_kmacs,key_kek1)
    ok = ok and terminal.Derive3Des( epin,"42C0",key_pin,key_kek1)
    ok = ok and terminal.Derive3Des( edatas,"44C0",key_kds,key_kek1)
    return ok
end

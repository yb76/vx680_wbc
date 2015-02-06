function do_obj_ecom_moto(poscc)
	txn.poscc = poscc
	txn.moto = true
	return do_obj_prchamount()
end

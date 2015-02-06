function check_rev_ok()
	return ( not config.safsign or config.safsign and do_obj_saf_rev_send("REVERSAL") )
end

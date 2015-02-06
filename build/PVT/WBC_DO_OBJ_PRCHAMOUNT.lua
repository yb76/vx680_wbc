function do_obj_prchamount()
  txn.prchamt = ecrd.AMT
  txn.cashamt = 0
  txn.totalamt = txn.prchamt
  return do_obj_swipecard()
end

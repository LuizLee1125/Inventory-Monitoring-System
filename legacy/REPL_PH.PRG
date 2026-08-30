* program.....: repl_ph.prg


set talk off
* set stat off
set scor off

sele 1
   use stkfyl index stk_n
sele 2
   use stkrec index trans_cn, trans_id, si_id
   set order to 0

do while .not. eof()
   stor stk_n  to sv_stk_n
   sele 1
   seek sv_stk_n
   if found()
      stor stk_dv  to sv_stk_dv
      stor splyr_n to sv_splyr
      sele 2
      repl stk_dv  with sv_stk_dv
      repl splyr_n with sv_splyr
      unlock
   endif
   sele 2
   skip
enddo



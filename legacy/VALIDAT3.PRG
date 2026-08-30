* program.....: Validat4.prg

clear
clear prog

set scor off
set talk off
set stat off

? "please wait...."

sele 1
     use custfyl index cust_n

sele 2
     use stkrec
sele 3
     use sifyl
sele 4
     use srfyl
sele 5
     use colecfyl
sele 6
     use colecrec
sele 7
     use stkfyl index stk_n

sele 2
do while .not. eof()
   if trans_c<>"S" .or. trans_c<>"R"
      skip
      loop
   endif
   store cust_n to sv_cust_n
   store stk_n  to sv_stk_n
   sele 7
   seek sv_stk_n
   if found()
      sele 2
      replace splyr_n with stkfyl->splyr_n
      replace stk_m   with stkfyl->stk_m
      replace stk_dv  with stkfyl->stk_dv
      replace stk_cat with stkfyl->stk_cat
   endif
   sele 1
   seek sv_cust_n
   if found()
      sele 2
      replace cust_s with custfyl->cust_s
   else
      sele 2
      replace cust_s with "          "
   endif
   sele 2
   skip
enddo


sele 3
do while .not. eof()
   store cust_n to sv_cust_n
   sele 1
   seek sv_cust_n
   if found()
      sele 3
      replace cust_s with custfyl->cust_s
      replace cust_m with custfyl->cust_m
      replace cust_ac with custfyl->cust_ac
   else
      sele 3
      replace cust_s with "          "
   endif
   skip
enddo

sele 4
do while .not. eof()
   store cust_n to sv_cust_n
   sele 1
   seek sv_cust_n
   if found()
      sele 4
      replace cust_s with custfyl->cust_s
      replace cust_m with custfyl->cust_m
      replace cust_ac with custfyl->cust_ac
   else
      sele 4
      replace cust_s with "          "
   endif
   skip
enddo

sele 5
do while .not. eof()
   store cust_n to sv_cust_n
   sele 1
   seek sv_cust_n
   if found()
      sele 5
      replace cust_s with custfyl->cust_s
      replace cust_m with custfyl->cust_m
   else
      sele 5
      replace cust_s with "          "
   endif
   skip
enddo

sele 6
do while .not. eof()
   store cust_n to sv_cust_n
   sele 1
   seek sv_cust_n
   if found()
      sele 6
      replace cust_s with custfyl->cust_s
      replace cust_m with custfyl->cust_m

   else
      sele 6
      replace cust_s with "         "
   endif
   skip
enddo

close data


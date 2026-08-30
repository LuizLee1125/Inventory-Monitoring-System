* program....: rep_coll.prg
*            : 10/28/2010
*            : replace all blank customer code, cust desc and date of collection


sele 1
   use colecfyl index or_n, or_cd
   set order to 0
sele 2
   use colecrec index colec_n


sele 1
go top

rep_cctr=0
repcolopt=" "
save screen to repcolscrn

set colo to +w/+g
@ 14,10 clear to 16,74
@ 14,10 to 16,74
@ 15,11 say "Repl. blank cust. no, desc & coll. date in coll. file [Y/N]?" get repcolopt pict '!' valid repcolopt$'YN'
read

if repcolopt="N"
   rest screen from repcolscrn
   return
endif

set colo to +w/bg
@ 14,10 clear to 16,74
@ 14,10 to 16,74
@ 15,11 say " Replaced "
@ 15,21 say rep_cctr pict "99"
@ 15,25 say "blank cust. no., desc & coll. date. pls wait..."

do while .not. eof()

   if cust_n=" "
      store colec_n to sv_colec_n
      sele 2
      seek sv_colec_n
      if found()
         store cust_n to sv_cust_n
         store cust_m to sv_cust_m
         store colec_d to sv_colec_d
         sele 1
         repl cust_n with sv_cust_n
         repl cust_m with sv_cust_m
         repl colec_d with sv_colec_d
         unlock
         rep_cctr=rep_cctr+1
         @ 15,21 say rep_cctr pict "99"
      endif
   endif
   sele 1
   skip

enddo

close data

set colo to +w/+g
@ 14,10 clear to 16,74
@ 14,10 to 16,74
@ 15,11 say "     Finished processing.  Press any key to continue...     "
atl=inkey(0)
rest screen from repcolscrn

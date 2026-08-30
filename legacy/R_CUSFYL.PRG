* program.....: R_CusFyl.prg
*             : reactivation of customer from old

SET CENTURY ON
USE o_CUSFYL INDEX o_CUST_N

DO BRDR1
&C_BODY
@ 4, 4   SAY 'Customer Code       :'
@ 5, 4   SAY 'Customer Name       :'
@ 6, 4   SAY 'Customer Address    :'
@ 7, 4   SAY 'Customer City       :'
@ 8, 4   SAY 'Area Code           :'
@ 9, 4   SAY 'Customer Tel No.    :'
@ 10, 4  SAY 'Start Date          :'
@ 11, 4  SAY 'Price Category      :'
@ 12, 4  SAY 'Type / Terms        :           /   days'
@ 13, 4  SAY 'Credit Limit        :'
@ 14, 4  SAY 'Contact Person      :'
@ 15, 4  SAY 'Salesman            :'
@ 16, 4  SAY 'Proprietor Name     :'
@ 17, 4  SAY 'Proprietor Address  :'
@ 18, 4  SAY 'Proprietor Tel. No. :'
@ 19, 4  SAY 'Remarks             :'
@ 9, 47  SAY 'Last Purchase :'
@ 10, 47 SAY 'Purchases     :'
@ 11, 47 SAY 'Charges       :'
@ 12, 47 SAY 'Payments      :'
@ 13, 47 SAY 'Unclear Checks:'
@ 14, 47 SAY 'Balance       :'

save screen to atlscrn

action="SAY"
choice="T"

DO WHILE .T.
   set colo to
   @ 21,0 clear to 24,79
   if tobemoved
      set colo to +gr/n
      @ 4,59 say "* to be moved"
   else
      set colo to
      @ 4,59 say "             "
   endif

   &C_GET
   @ 4, 26 say cust_n   PICTURE '@!'
   @ 05,26 say cust_m   PICT '@!'
   @ 06,26 say cust_ad  PICT '@!'
   @ 07,26 say cust_ct  PICT '@!'
   @ 08,26 say cust_ac  PICT '@!'
   @ 09,26 say cust_p   PICT '@!'
   @ 10,26 say cust_sd  PICT '99/99/9999'
   @ 11,26 say cust_pc  PICT '@!'
   @ 12,26 say cust_tp  PICT '@!'
   @ 12,37 say cust_t   PICT '###'
   @ 13,26 say cust_cl  PICT '#,###,###.##'
   @ 14,26 say cust_cp  PICT '@!'
   @ 16,26 say prop_m   PICT '@!'
   @ 17,26 say prop_ad  PICT '@!'
   @ 18,26 say prop_p   PICT '@!'
   @ 19,26 say cust_rem PICT '@!'
   @ 09,63 say cust_lt  PICT '99/99/9999'
   @ 10,63 say cust_pur PICT '###,###,###.##'
   @ 11,65 say cust_crg PICT '#,###,###.##'
   @ 12,63 say cust_pay PICT '###,###,###.##'
   @ 13,65 say cust_flt PICT '#,###,###.##'
   @ 14,65 SAY cust_pur+cust_crg-cust_pay PICTURE '#,###,###.##'
   @ 1, 69 SAY user_m   PICTURE '@!'

*  set colo to +w/b, +gr/r
*  @ 22, 18 prompt " Next "
*  @ 22, 25 prompt " Prev "
*  @ 22, 32 prompt " Top "
*  @ 22, 38 prompt " Bott "
*  @ 22, 45 prompt " Find "
*  if .not. tobemoved
*     @ 22, 52 prompt " Move "
*  else
*     @ 22, 52 prompt " Reca "
*  endif
*  @ 22, 59 prompt " Quit "
*  menu to atlbar

   do option10
   atlbar=choice

   do case
      case atlbar="N"
           skip
           if eof()
              save screen to atlscreen
              atlmsg="this is the last record, press any key..."
              atllen=len(atlmsg)
              set colo to rb/rb
              @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
              set colo to +w/rb
              @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
              @ 12,41-atllen/2 say atlmsg
              atlkeypress=inkey(0)
              restore screen from atlscreen
              go bott
              loop
           endif
      case atlbar="V"
           skip -1
           if bof()
              save screen to atlscreen
              atlmsg="this is the first record, press any key..."
              atllen=len(atlmsg)
              set colo to rb/rb
              @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
              set colo to +w/rb
              @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
              @ 12,41-atllen/2 say atlmsg
              atlkeypress=inkey(0)
              restore screen from atlscreen
              go top
              loop
           endif
      case atlbar="T"
           go top
      case atlbar="B"
           go bott
      case atlbar="F"
           atlrecno=recno()
           save screen to atlscrn2
           atlStkN=space(10)
           @ 4,26 get atlStkN pict "@!"
           read
           if atlStkN=" "
              restore screen from atlscrn2
              loop
           endif
           atlStkN=trim(atlStkN)
           seek atlStkN
           if .not. found()
              save screen to atlscrn2
              atlmsg="customer code "+trim(atlStkN)+" not found! press any key to continue..."
              atllen=len(atlmsg)
              set colo to rb/rb
              @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
              set colo to +w/rb
              @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
              @ 12,41-atllen/2 say atlmsg
              keypress=inkey(0)
              rest screen from atlscrn2
              go atlrecno
              loop
           endif
      case atlbar="M"
              repl tobemoved with .t.
      case atlbar="R"
              repl tobemoved with .f.
      case atlbar="Q"
           exit
   endcase
enddo

save screen to atlscreen
atlmsg="please wait... verifying customers to be moved..."
atllen=len(atlmsg)
set colo to rb/rb
@ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
set colo to +w/rb
@ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
@ 12,41-atllen/2 say atlmsg
count for tobemoved to atlctr
rest screen from atlscreen

if atlctr>=1
   save screen to atlscreen
   atlmsg=" moving customer records to archive... please wait..."
   atllen=len(atlmsg)
   set colo to rb/rb
   @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
   set colo to +w/rb
   @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
   @ 12,41-atllen/2 say atlmsg

   use

   SELE 2
      use o_cusfyl index o_cust_n
   SELE 1
      USE custfyl INDEX cust_n

   sele 2

   do while .not. eof()
     if tobemoved
        store cust_n     to   x_cust_n
        store cust_m     to   x_cust_m
        store cust_ad    to   x_cust_ad
        store cust_ct    to   x_cust_ct
        store cust_ac    to   x_cust_ac
        store cust_p     to   x_cust_p  
        store cust_sd    to   x_cust_sd
        store cust_pc    to   x_cust_pc
        store cust_tp    to   x_cust_tp
        store cust_t     to   x_cust_t
        store cust_cl    to   x_cust_cl
        store cust_cp    to   x_cust_cp
        store cust_s     to   x_cust_s
        store prop_m     to   x_prop_m
        store prop_ad    to   x_prop_ad
        store prop_p     to   x_prop_p
        store cust_rem   to   x_cust_rem
        store cust_lt    to   x_cust_lt
        store cust_pur   to   x_cust_pur
        store cust_crg   to   x_cust_crg
        store cust_pay   to   x_cust_pay
        store cust_flt   to   x_cust_flt
        store user_m     to   x_user_m
        if rlock()
           dele
           unlock
        endif
        sele 1
        if flock()
           appe blank
           replace cust_n    with  x_cust_n
           replace cust_m    with  x_cust_m
           replace cust_ad   with  x_cust_ad
           replace cust_ct   with  x_cust_ct
           replace cust_ac   with  x_cust_ac
           replace cust_p    with  x_cust_p  
           replace cust_sd   with  x_cust_sd
           replace cust_pc   with  x_cust_pc
           replace cust_tp   with  x_cust_tp
           replace cust_t    with  x_cust_t
           replace cust_cl   with  x_cust_cl
           replace cust_cp   with  x_cust_cp
           replace cust_s    with  x_cust_s
           replace prop_m    with  x_prop_m
           replace prop_ad   with  x_prop_ad
           replace prop_p    with  x_prop_p
           replace cust_rem  with  x_cust_rem
           replace cust_lt   with  x_cust_lt
           replace cust_pur  with  x_cust_pur
           replace cust_crg  with  x_cust_crg
           replace cust_pay  with  x_cust_pay
           replace cust_flt  with  x_cust_flt
           replace user_m    with  muser
           unlock
        endif
     endif
     sele 2
     skip
   enddo

   rest screen from atlscreen
   atlmsg=" Finished processing!!! Press any key to continue ..."
   atllen=len(atlmsg)
   set colo to rb/rb
   @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
   set colo to +w/rb
   @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
   @ 12,41-atllen/2 say atlmsg
   keypress=inkey(0)
   rest screen from atlscreen
endif

close data
set century off
return

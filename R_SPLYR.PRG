* program.....: R_Splyr.prg
*             : recall supplier records

SET CENTURY ON
USE SPLYRFYL INDEX SPLYR_N

choice= 'S'

DO BRDR1
&C_BODY
@  6, 5  SAY 'Supplier Code    :'     
@  7, 5  SAY 'Supplier Name    :'
@  8, 5  SAY 'Supplier Address :'
@  9, 5  SAY 'Supplier City    :'
@ 10, 5  SAY 'Area Code        :'
@ 11, 5  SAY 'Supplier Tel No. :'
@ 13, 5  SAY 'Type / Terms     :           /   days'
@ 14, 5  SAY 'Credit Limit     :'
@ 15, 5  SAY 'Contact Person   :'
@ 16, 5  SAY 'Remarks          :'
@ 12, 46 SAY 'Last Purchase :'
@ 13, 46 SAY 'Purchases     :'
@ 14, 46 SAY 'Charges       :'
@ 15, 46 SAY 'Payments      :'
@ 16, 46 SAY 'Balance       :'

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
   @ 6, 24 SAY Splyr_N   PICT '@!'
   @ 07,24 SAY Splyr_M   PICT '@!'
   @ 08,24 SAY Splyr_Ad  PICT '@!'
   @ 09,24 SAY Splyr_Ct  PICT '@!'
   @ 10,24 SAY Splyr_Ac  PICT '@!'
   @ 11,24 SAY Splyr_P   PICT '@!'
   @ 13,24 SAY Splyr_Tp  PICT '@!'
   @ 13,35 SAY Splyr_T   PICT '###'
   @ 14,24 SAY Splyr_Cl  PICT '#,###,###.##'
   @ 15,24 SAY Splyr_Cp  PICT '@!'
   @ 16,24 SAY Splyr_Rem PICT '@!'
   @ 12,62 SAY Splyr_Lt  PICT '99/99/9999'
   @ 13,62 SAY Splyr_Pur PICT '###,###,###.##'
   @ 14,64 SAY Splyr_Crg PICT '#,###,###.##'
   @ 15,62 SAY Splyr_Pay PICT '###,###,###.##'
   @ 1, 69 SAY User_M    PICT '@!'
   @ 16,64 SAY Splyr_Pur+Splyr_Crg-Splyr_Pay PICTURE '#,###,###.##'

   do option10
   atlbar=choice

   do case
      case atlbar="N"
           skip
           if eof()
              set colo to +w/rb
              @ 23, 22 say "end of file encountered. press any key..."
              keypress=inkey(0)
              set colo to
              @ 23, 22 clear to 23,79
              go bott
           endif
      case atlbar="V"
           skip -1
           if bof()
              set colo to +w/rb
              @ 23, 18 say "beginning of file encountered. press any key..."
              keypress=inkey(0)
              set colo to
              @ 23, 18 clear to 23,79
              go top
           endif
      case atlbar="T"
           go top
      case atlbar="B"
           go bott
      case atlbar="F"
           atlrecno=recno()
           save screen to atlscrn2
           atlStkN=space(10)
           @ 6,24 get atlStkN pict "@!"
           read
           if atlStkN=" "
              restore screen from atlscrn2
              loop
           endif
           atlStkN=trim(atlStkN)
           seek atlStkN
           if .not. found()
              set colo to b/b
              @ 12,11 clear to 14,69
              set colo to +gr/b
              @ 12,11 to 14,69
              set colo to +w/b,+gr/rb
              @ 13,13 say "Supplier Code not found! Press any key to continue..."
              keypress=inkey(0)
              rest screen from atlscrn2
              go atlrecno
              loop
           endif
      case atlbar="M" && move - 6
              repl tobemoved with .t.
      case atlbar="R"
              repl tobemoved with .f.
      case atlbar="Q"
           exit
   endcase
enddo

set colo to b/b
@ 12,11 clear to 14,69
set colo to +gr/b
@ 12,11 to 14,69
set colo to +w/b,+gr/rb
@ 13,13 say "   please wait... verifying suppliers for recall...  "
count for tobemoved to atlctr

if atlctr>=1
   set colo to b/b
   @ 12,11 clear to 14,69
   set colo to +gr/b
   @ 12,11 to 14,69
   set colo to +w/b,+gr/rb
   @ 13,13 say " reactivating old supplier records... please wait..."

   sele 1
      use Splyrfyl index Splyr_N
   sele 2
      use O_Splyr  index O_SplyrN

   do while .not. eof()
     if tobemoved
        store Splyr_N   to Xsplyr_n
        store splyr_m   to Xsplyr_m
        store splyr_ad  to xsplyr_ad
        store splyr_ct  to Xsplyr_ct
        store splyr_ac  to Xsplyr_ac
        store splyr_p   to Xsplyr_p
        store splyr_tp  to Xsplyr_tp
        store splyr_t   to Xsplyr_t
        store splyr_cl  to Xsplyr_cl
        store splyr_cp  to Xsplyr_cp
        store splyr_rem to Xsplyr_rem
        store splyr_lt  to Xsplyr_lt
        store splyr_pur to Xsplyr_pur
        store splyr_crg to Xsplyr_crg
        store splyr_pay to Xsplyr_pay
        store splyr_bal to Xsplyr_bal
        if rlock()
           dele
           unlock
        endif
        sele 1
        if flock()
           appe blank
           replace Splyr_N   with Xsplyr_n
           replace splyr_m   with Xsplyr_m
           replace splyr_ad  with xsplyr_ad
           replace splyr_ct  with Xsplyr_ct
           replace splyr_ac  with Xsplyr_ac
           replace splyr_p   with Xsplyr_p
           replace splyr_tp  with Xsplyr_tp
           replace splyr_t   with Xsplyr_t
           replace splyr_cl  with Xsplyr_cl
           replace splyr_cp  with Xsplyr_cp
           replace splyr_rem with Xsplyr_rem
           replace splyr_lt  with Xsplyr_lt
           replace splyr_pur with Xsplyr_pur
           replace splyr_crg with Xsplyr_crg
           replace splyr_pay with Xsplyr_pay
           replace splyr_bal with Xsplyr_bal
           unlock
        endif
     endif
     sele 2
     skip
   enddo
       
   set colo to b/b
   @ 12,11 clear to 14,69
   set colo to +gr/b
   @ 12,11 to 14,69
   set colo to +w/b,+gr/rb
   @ 13,13 say " Finished processing!!! Press any key to continue ..."
   keypress=inkey(0)
endif

close data
set century off
return


* program.....: SRPurge.prg
*             : allow purging of Sales Returns
*             : 06-03-2011


set exclusive on
set deleted on

SELECT 4
   USE O_STKREC index o_cn, o_tid, o_sid

SELECT 3
   USE O_SRFYL index o_sr_n, o_sr_d, o_sr_cd

SELECT 2
   USE STKREC INDEX TRANS_CN, TRANS_ID, SI_ID

SELECT 1
   USE SRFYL INDEX SR_N, SR_D, SR_CD

DO BRDR1
&C_BODY
@ 5, 4  SAY 'Sales Return No:'
@ 6, 4  SAY 'Customer Code  :'
@ 6, 34 SAY 'Customer  :'
@ 7, 34 SAY 'Address   :'
@ 8, 34 SAY 'City      :'
@ 9, 34 SAY 'Area Code :'
@ 8, 4  SAY 'Territory Code :'
@ 11, 4 SAY 'Status         :'
@ 13, 4 SAY 'Invoice Date   :'
@ 14, 4 SAY 'Invoice Cost   :'
@ 15, 4 SAY 'Invoice Amount :'
@ 16, 4 SAY 'Discount       :   ,  ,   %'
@ 17, 4 SAY 'Net Amount     :'
@ 18, 4 SAY 'Remarks        :'
@ 14,50 SAY 'Date Posted :'
@ 15,50 SAY 'Adjustments :'
@ 16,50 SAY 'Payments    :'
@ 18,50 SAY 'Balance     :'

set colo to
@ 21,00 clear to 24,79
choice= 'T'
action= 'SAY'

DO WHILE .T.

   set colo to
   @ 21,0 clear to 24,79
   if tobemoved
      set colo to +gr/n
      @ 4,46 say "* to be moved"
   else
      set colo to
      @ 4,46 say "             "
   endif

   SET COLO TO +W/BG
   @ 05,21 SAY inv_n   PICTURE '@!'
   @ 06,21 SAY cust_n  PICTURE '@!'
   @ 06,46 SAY cust_m  PICTURE '@!'
   @ 07,46 SAY cust_ad PICTURE '@!'
   @ 08,46 SAY cust_ct PICTURE '@!'
   @ 09,46 SAY cust_ac PICTURE '@!'
   @ 08,21 SAY cust_s  PICTURE '@!'

  if inv_bal<=0
     @ 11, 21 say "Posted    "
  else
     @ 11, 21 say "NOT Posted"
  endif

   set cent on
   @ 13,21 SAY inv_d   PICTURE '99/99/9999'
   @ 14,64 SAY post_d  PICTURE '99/99/9999'
   set cent off
   @ 14,21 SAY inv_c   PICTURE '@Z #,###,###.##'
   @ 15,21 SAY inv_a   PICTURE '#,###,###.##'
   @ 16,21 SAY dcount1 PICTURE '##.##'
   @ 16,24 SAY dcount2 PICTURE '##'
   @ 16,27 SAY dcount3 PICTURE '##'
   @ 17,21 SAY net_a   PICTURE '#,###,###.##'
   @ 18,21 SAY si_rem  PICTURE '@!'
   @ 15,64 SAY inv_adj PICTURE '#,###,###.##'
   @ 16,64 SAY inv_pay PICTURE '#,###,###.##'
   @ 1, 69 SAY post_m  PICTURE '@!'
   
   @ 18,64 SAY inv_bal PICTURE '#,###,###.##'
                                            
   set colo to +gr, +*w/b
   do option10
   atlbar=choice

   do case
      case atlbar="N" && next - 1
           skip
           if eof()
              set colo to +w/rb
              @ 23, 22 say "end of file encountered. press any key..."
              keypress=inkey(0)
              set colo to
              @ 23, 22 clear to 23,79
              go bott
           endif

      case atlbar="V" && previous - 2
           skip -1
           if bof()
              set colo to +w/rb
              @ 23, 18 say "beginning of file encountered. press any key..."
              keypress=inkey(0)
              set colo to
              @ 23, 18 clear to 23,79
              go top
           endif

      case atlbar="T" && top - 3
           go top

      case atlbar="B" && bottom - 4
           go bott

      case atlbar = "F"  && find
           set exact off
           store space(10) to mSv_Sin
           store recno()   to mRecno
           set colo to ,+gr/r
           @ 5,21 get mSv_Sin pict '@!'
           read
           if mSv_Sin=" "
              set exact on
              loop
           endif
           seek trim(mSv_SiN)
           if .not. found()
              save screen to atlscreen
              atlmsg="computer SR # "+trim(mSv_Sin)+" not found! press any key to continue..."
              atllen=len(atlmsg)
              set colo to rb/rb
              @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
              set colo to +w/rb
              @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
              @ 12,41-atllen/2 say atlmsg
              atlkeypress=inkey(0)
              restore screen from atlscreen
              go mRecno
           endif
           set exact on
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
@ 13,13 say "    please wait... verifying stocks to be moved...   "
count for tobemoved to atlctr

if atlctr>=1
   set colo to b/b
   @ 12,11 clear to 14,69
   set colo to +gr/b
   @ 12,11 to 14,69
   set colo to +w/b,+gr/rb
   @ 13,13 say "  moving stock records to archive... please wait...  "

   sele 1
   go top
   do while .not. eof()
      if .not. tobemoved
         skip
         loop
      endif
      stor inv_n to sv_inv_n
      sele 3
      append blank
      replace inv_n   with srfyl->inv_n
      replace rinv_n  with srfyl->rinv_n
      replace cust_n  with srfyl->cust_n
      replace cust_m  with srfyl->cust_m
      replace cust_ad with srfyl->cust_ad
      replace cust_ct with srfyl->cust_ct
      replace cust_ac with srfyl->cust_ac
      replace cust_s  with srfyl->cust_s
      replace inv_d   with srfyl->inv_d
      replace si_rem  with srfyl->si_rem
      replace cust_pc with srfyl->cust_pc
      replace inv_c   with srfyl->inv_c
      replace inv_pc  with srfyl->inv_pc
      replace inv_a   with srfyl->inv_a
      replace dcount1 with srfyl->dcount1
      replace dcount2 with srfyl->dcount2
      replace dcount3 with srfyl->dcount3
      replace net_a   with srfyl->net_a
      replace user_m  with srfyl->user_m
      replace status  with srfyl->status
      replace post_d  with srfyl->post_d
      replace inv_adj with srfyl->inv_adj
      replace inv_pay with srfyl->inv_pay
      replace inv_bal with srfyl->inv_bal
      replace paid    with srfyl->paid
      replace post_m  with srfyl->post_m
      replace tobemoved with .F.

      * mark for deletion the record in the srfyl
      sele 1
      dele

      * look for the corresponding records in the transaction file
      sele 2
      go top

      trankey="R"+sv_inv_n
      seek trankey
      do while .not. eof() .and. trans_n=sv_inv_n
         repl qty1l with "MOV"
         sele 4
         append blank
         replace trans_c   with stkrec->trans_c
         replace trans_n   with stkrec->trans_n
         replace trans_d   with stkrec->trans_d
         replace cust_n    with stkrec->cust_n
         replace cust_s    with stkrec->cust_s
         replace stk_n     with stkrec->stk_n
         replace stk_m     with stkrec->stk_m
         replace stk_pc    with stkrec->stk_pc
         replace stk_ac    with stkrec->stk_ac
         replace qty_s     with stkrec->qty_s
         replace qty_pq    with stkrec->qty_pq
         replace qty_pu    with stkrec->qty_pu
         replace splyr_n   with stkrec->splyr_n
         replace qty1      with stkrec->qty1
         replace qty2      with stkrec->qty2
         replace qty3      with stkrec->qty3
         replace stk_dv    with stkrec->stk_dv
         replace stk_cat   with stkrec->stk_cat
         replace issue_d   with stkrec->issue_d
         replace issue_q   with stkrec->issue_q
         replace issue_fg  with stkrec->issue_fg
         replace issue_u   with stkrec->issue_u
         replace issue_cp  with stkrec->issue_cp
         replace issue_p   with stkrec->issue_p
         replace dcount1   with stkrec->dcount1
         replace dcount2   with stkrec->dcount2
         replace dcount3   with stkrec->dcount3
         replace t_prys    with stkrec->t_prys
         replace t_ac      with stkrec->t_ac
         replace t_pc      with stkrec->t_pc
         replace lot_n     with stkrec->lot_n
         replace expiry_d  with stkrec->expiry_d
         replace user_m    with stkrec->user_m
         replace taym      with stkrec->taym
         sele 2
         skip
      enddo

      * continue the next iteration on srfyl
      sele 1
      skip

   enddo

   * clean up
   set colo to +gr/b,+gr/rb
   @ 13,13 say "  cleaning all deleted records...... please wait...  "

   sele 1
   pack

   sele 2
   dele for qty1l="MOV"
   pack

   set colo to +w/r,+gr/rb
   @ 13,13 say "  processing finished. press any key to continue...  "
   atlkey=inkey(0)

else
   set colo to b/b
   @ 12,11 clear to 14,69
   set colo to +gr/b
   @ 12,11 to 14,69
   set colo to +w/b,+gr/rb
   @ 13,13 say "        Do you want to purge by inclusive dates?  "
   atlkey=inkey(0)
   if atlkey=121 .or. atlkey=89
      set colo to b/b
      @ 12,11 clear to 14,69
      set colo to +gr/b
      @ 12,11 to 14,69
      set colo to +w/b,+gr/rb
      @ 13,13 say "    input inclusive dates: [99/99/9999]-[99/99/9999] "
      sdate=ctod(' ')
      edate=date()
      set cent on
      @ 13,41 get sdate picture '99/99/9999'
      @ 13,54 get edate picture '99/99/9999'
      read
      set cent off

      set colo to b/b
      @ 12,11 clear to 14,69
      set colo to +gr/b
      @ 12,11 to 14,69
      set colo to +w/b,+gr/rb
      @ 13,13 say "            Proceed to archive Sales Return [Y/N]  "
      atlkey=inkey(0)
      if atlkey=121 .or. atlkey=89
      set colo to b/b
      @ 12,11 clear to 14,69
      set colo to +gr/b
      @ 12,11 to 14,69
      set colo to +w/b,+gr/rb
      @ 13,13 say "  moving stock records to archive... please wait...  "

      sele 1
      go top
      do while .not. eof()
         if inv_d>=sdate .and. inv_d<=edate
            repl tobemoved with .t.
         endif
         skip
      enddo

      sele 1
      go top
      do while .not. eof()
         if .not. tobemoved
            skip
            loop
         endif
         stor inv_n to sv_inv_n
         sele 3
         append blank
         replace inv_n   with srfyl->inv_n
         replace rinv_n  with srfyl->rinv_n
         replace cust_n  with srfyl->cust_n
         replace cust_m  with srfyl->cust_m
         replace cust_ad with srfyl->cust_ad
         replace cust_ct with srfyl->cust_ct
         replace cust_ac with srfyl->cust_ac
         replace cust_s  with srfyl->cust_s
         replace inv_d   with srfyl->inv_d
         replace si_rem  with srfyl->si_rem
         replace cust_pc with srfyl->cust_pc
         replace inv_c   with srfyl->inv_c
         replace inv_pc  with srfyl->inv_pc
         replace inv_a   with srfyl->inv_a
         replace dcount1 with srfyl->dcount1
         replace dcount2 with srfyl->dcount2
         replace dcount3 with srfyl->dcount3
         replace net_a   with srfyl->net_a
         replace user_m  with srfyl->user_m
         replace status  with srfyl->status
         replace post_d  with srfyl->post_d
         replace inv_adj with srfyl->inv_adj
         replace inv_pay with srfyl->inv_pay
         replace inv_bal with srfyl->inv_bal
         replace paid    with srfyl->paid
         replace post_m  with srfyl->post_m
         replace tobemoved with .F.
   
         * mark for deletion the record in the srfyl
         sele 1
         dele
   
         * look for the corresponding records in the transaction file
         sele 2
         go top

         trankey="R"+sv_inv_n
         seek trankey
         do while .not. eof() .and. trans_n=sv_inv_n
            repl qty1l with "MOV"
            sele 4
            append blank
            replace trans_c   with stkrec->trans_c
            replace trans_n   with stkrec->trans_n
            replace trans_d   with stkrec->trans_d
            replace cust_n    with stkrec->cust_n
            replace cust_s    with stkrec->cust_s
            replace stk_n     with stkrec->stk_n
            replace stk_m     with stkrec->stk_m
            replace stk_pc    with stkrec->stk_pc
            replace stk_ac    with stkrec->stk_ac
            replace qty_s     with stkrec->qty_s
            replace qty_pq    with stkrec->qty_pq
            replace qty_pu    with stkrec->qty_pu
            replace splyr_n   with stkrec->splyr_n
            replace qty1      with stkrec->qty1
            replace qty2      with stkrec->qty2
            replace qty3      with stkrec->qty3
            replace stk_dv    with stkrec->stk_dv
            replace stk_cat   with stkrec->stk_cat
            replace issue_d   with stkrec->issue_d
            replace issue_q   with stkrec->issue_q
            replace issue_fg  with stkrec->issue_fg
            replace issue_u   with stkrec->issue_u
            replace issue_cp  with stkrec->issue_cp
            replace issue_p   with stkrec->issue_p
            replace dcount1   with stkrec->dcount1
            replace dcount2   with stkrec->dcount2
            replace dcount3   with stkrec->dcount3
            replace t_prys    with stkrec->t_prys
            replace t_ac      with stkrec->t_ac
            replace t_pc      with stkrec->t_pc
            replace lot_n     with stkrec->lot_n
            replace expiry_d  with stkrec->expiry_d
            replace user_m    with stkrec->user_m
            replace taym      with stkrec->taym
            sele 2
            skip
         enddo

         * continue the next iteration on srfyl
         sele 1
         skip

      enddo

      * clean up
      set colo to +gr/b,+gr/rb
      @ 13,13 say "  cleaning all deleted records...... please wait...  "
 
      sele 1
      pack

      sele 2
      dele for qty1l="MOV"
      pack

      set colo to +w/r,+gr/rb
      @ 13,13 say "  processing finished. press any key to continue...  "
      atlkey=inkey(0)

      endif
   endif

endif

set talk off
set deleted on
set century off
set exclusive off
close data
return

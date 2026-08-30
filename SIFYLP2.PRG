* program.....: SiFylp2.prg
*             : allow editing of remarks, changing of price codes
*             : without affecting the inventory control sequence
*             : 08-30-03

SELECT 1
   USE SIFYL   INDEX SI_N, SI_D, SI_CD, SI_DINV, colec_x

DO BRDR1
&C_BODY
@ 4, 4  SAY 'Invoice No.    :'
@ 5, 4  SAY 'Customer Code  :'
@ 4, 34 SAY 'Customer  :'
@ 5, 34 SAY 'Address   :'
@ 6, 34 SAY 'City      :'
@ 7, 34 SAY 'Area Code :'
@ 8, 4  SAY 'Address  Code  :'
@ 8, 34 SAY 'Company   :'
@ 9, 34 SAY 'Address   :'
@ 10,34 SAY 'City      :'
@ 10, 4 SAY 'Territory code :'
@ 12, 4 SAY 'Type / Terms   :           /    days'
@ 12,50 SAY 'PAID        :'
@ 13, 4 SAY 'Status         :'
@ 14, 4 SAY 'Invoice Date   :'
@ 15, 4 SAY 'Invoice Cost   :'
@ 16, 4 SAY 'Invoice Amount :'
@ 17, 4 SAY 'Discount       :   ,  ,   %'
@ 18, 4 SAY 'Net Amount     :'
@ 19, 4 SAY 'Remarks        :'
@ 14,50 SAY 'Date Posted :'
@ 15,50 SAY 'Adjustments :'
@ 16,50 SAY 'Payments    :'
@ 18,50 SAY 'Balance     :'

set colo to
@ 21,00 clear to 24,79
choice= 'T'
action= 'SAY'


DO WHILE .T.

   *IF DELETED()
   *   SET COLO TO +GR
   *   @ 12,50 SAY "* record is deleted *"
   *else
   *   set colo to n/n
   *   @ 12,50 say "                     "
   *endif
   SET COLO TO +W/BG
   @ 4, 21 SAY inv_n   PICTURE '@!'
   @ 05,21 SAY cust_n  PICTURE '@!'
   @ 04,46 SAY cust_m  PICTURE '@!'
   @ 05,46 SAY cust_ad PICTURE '@!'
   @ 06,46 SAY cust_ct PICTURE '@!'
   @ 07,46 SAY cust_ac PICTURE '@!'
   @ 08,21 SAY ad_n    PICTURE '@!'
   @ 08,46 SAY co_m    PICTURE '@!'
   @ 09,46 SAY co_ad   PICTURE '@!'
   @ 10,46 SAY co_ct   PICTURE '@!'
   @ 10,21 SAY cust_s  PICTURE '@!'
   @ 12,21 SAY cust_tp PICTURE '@!'
   @ 12,32 SAY cust_t  PICTURE '@Z ###'

   if PAID="T"
      @ 12,64 say "TRUE "
   else                 
      @ 12,64 say "FALSE"
   endif

   DO CASE
      CASE status=' '
           @ 13, 21 SAY 'For Invoicing'
      CASE status='I'
           @ 13, 21 SAY 'For Posting  '
      CASE status='P'
           @ 13, 21 SAY 'Posted       '
      CASE status='C'
           @ 13, 21 SAY 'Cancelled    '
   ENDCASE

   set cent on
   @ 14,21 SAY inv_d   PICTURE '99/99/9999'
   @ 14,64 SAY post_d  PICTURE '99/99/9999'
   set cent off
   @ 15,21 SAY inv_c   PICTURE '@Z #,###,###.##'
   @ 16,21 SAY inv_a   PICTURE '#,###,###.##'
   @ 17,21 SAY dcount1 PICTURE '##.##'
   @ 17,24 SAY dcount2 PICTURE '##'
   @ 17,27 SAY dcount3 PICTURE '##'
   @ 19,21 SAY si_rem  PICTURE '@!'
   @ 15,64 SAY inv_adj PICTURE '#,###,###.##'
   @ 16,64 SAY inv_pay PICTURE '#,###,###.##'
   @ 1, 69 SAY post_m  PICTURE '@!'
   @ 18,21 SAY net_a   PICTURE '#,###,###.##'
   @ 18,64 SAY inv_bal PICTURE '#,###,###.##'

   set colo to +gr, +*w/b
   *@ 21,15 prompt " Top "
   *@ 21,20 prompt " Bottom "
   *@ 21,28 prompt " Next "
   *@ 21,34 prompt " Prev "
   *@ 21,40 prompt " Find "
   *@ 21,46 prompt " Remarks "
   *@ 21,55 prompt " Date "
   *@ 21,61 prompt " Quit "
   *menu to atlbar
   do option12
   atlbar=choice

   do case
      case atlbar = "T" && top
           go top
      case atlbar = "B" && bottom
           go bott
      case atlbar = "N" && next
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
      case atlbar = "V" && prev
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
      case atlbar = "F"  && find
           set exact off
           store space(10) to mSv_Sin
           store recno()   to mRecno
           set colo to ,+gr/r
           @ 4,21 get mSv_Sin pict '@!'
           read
           if mSv_Sin=" "
              set exact on
              loop
           endif
           seek trim(mSv_SiN)
           if .not. found()
              save screen to atlscreen
              atlmsg="computer inv. # "+trim(mSv_Sin)+" not found! press any key to continue..."
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
      case atlbar = "E"   && edit invoice no. and cust no.
           save screen to atlscreen
           store recno()   to mRecno
           minv_n = inv_n
           mcust_n= cust_n
           set colo to ,+gr/r
           @  4,21 get minv_n  PICTURE '@!'
           @ 05,21 get mcust_n PICTURE '@!'
           read
           save screen to atlscreen2
           atlmsg="Post "+trim(minv_n)+" to the Invoice (y/n)?"
           atllen=len(atlmsg)
           set colo to rb/rb
           @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+3
           set colo to +w/rb
           @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+3
           atloption=space(1)
           @ 12,41-atllen/2 say atlmsg
           @ 12,41-atllen/2+len(atlmsg)+1 get atloption pict '!' valid atloption$'YN' 
           read
           if atloption="Y"
              repl inv_n  with minv_n
              repl cust_n with mcust_n
              unlock
              restore screen from atlscreen2
           else
              restore screen from atlscreen
              go mRecno
              loop
           endif
      case atlbar = "D"   && unpaid the sales invoice
           if PAID="T"
              save screen to atl_screen2
              atlmsg="Are you sure you want to UnPaid this invoice (y/n)?"
              atllen=len(atlmsg)
              set colo to rb/rb
              @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+3
              set colo to +w/rb
              @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+3
              atloption=space(1)
              @ 12,41-atllen/2 say atlmsg
              @ 12,41-atllen/2+len(atlmsg)+1 get atloption pict '!' valid atloption$'YN' 
              read
              if atloption="Y"
                 replace inv_pay with 0
                 replace inv_bal with net_a
                 replace paid    with "F"
              endif
              restore screen from atl_screen2
              loop
           ELSE
              IF INV_BAL=0
                 save screen to atl_screen2
                 atlmsg="Are you sure you want to Paid this invoice (y/n)?"
                 atllen=len(atlmsg)
                 set colo to rb/rb
                 @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+3
                 set colo to +w/rb
                 @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+3
                 atloption=space(1)
                 @ 12,41-atllen/2 say atlmsg
                 @ 12,41-atllen/2+len(atlmsg)+1 get atloption pict '!' valid atloption$'YN' 
                 read
                 if atloption="Y"
                    replace paid    with "T"
                 endif
                 restore screen from atl_screen2
                 loop
              ENDIF
           endif
           *if deleted()
           *   recall
           *else
           *   delete
           *endif

      case atlbar = "R"   && Edit remarks
           save screen to atlscreen
           store recno()   to mRecno
           mSv_rem = Si_rem
           set colo to ,+gr/r
           @ 19,21 get mSv_rem   PICT '@!'
           read
           save screen to atlscreen2
           atlmsg="Post "+trim(mSv_rem)+" to the Invoice (y/n)?"
           atllen=len(atlmsg)
           set colo to rb/rb
           @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+3
           set colo to +w/rb
           @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+3
           atloption=space(1)
           @ 12,41-atllen/2 say atlmsg
           @ 12,41-atllen/2+len(atlmsg)+1 get atloption pict '!' valid atloption$'YN' 
           read
           if atloption="Y"
              repl Si_rem with mSv_rem
              unlock
              restore screen from atlscreen2
           else
              restore screen from atlscreen
              go mRecno
              loop
           endif
      case atlbar = "I"   && Edit Date
           save screen to atlscreen
           store recno()   to mRecno
           mSv_date = inv_d
           set colo to ,+gr/r
           set cent on
           @ 14,21 get mSv_date  PICTURE '99/99/9999'
           read
           set cent off
           save screen to atlscreen2
           atlmsg="Post "+dtoc(mSv_date)+" to the Invoice (y/n)?"
           atllen=len(atlmsg)
           set colo to rb/rb
           @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+3
           set colo to +w/rb
           @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+3
           atloption=space(1)
           @ 12,41-atllen/2 say atlmsg
           @ 12,41-atllen/2+len(atlmsg)+1 get atloption pict '!' valid atloption$'YN' 
           read
           if atloption="Y"
              repl inv_d with mSv_date
              unlock
              restore screen from atlscreen2
           else
              restore screen from atlscreen
              go mRecno
              loop
           endif

      case atlbar = "Q"  && quit
           exit

   endcase
enddo

close data
set exact off
set cent off
return

* program.....: SrFylp2.prg
*             : allow editing of remarks, changing of price codes
*             : without affecting the inventory control sequence
*             : 08-27-18

SELECT 1
   USE SRFYL   INDEX SR_N, SR_D, SR_CD

DO BRDR1
&C_BODY
@ 4, 4  SAY 'Sales Return No.:'
@ 5, 4  SAY 'Customer Code  :'
@ 4, 34 SAY 'Customer  :'
@ 5, 34 SAY 'Address   :'
@ 6, 34 SAY 'City      :'
@ 7, 34 SAY 'Area Code :'
@ 7, 4 SAY 'Territory code :'
@  9, 4 TO 9,75
@ 11, 4 SAY 'Status         :'
@ 11,50 SAY 'PAID        :'
@ 13, 4 SAY 'Sales Ret. Date:'
@ 14, 4 SAY 'Sales Ret. Cost:'
@ 15, 4 SAY 'Sales Ret. Amt.:'
@ 16, 4 SAY 'Discount       :   ,  ,   %'
@ 17, 4 SAY 'Net Amount     :'
@ 19, 4 SAY 'Remarks        :'
@ 14,50 SAY 'Adjustments :'
@ 15,50 SAY 'Payments    :'
@ 17,50 SAY 'Balance     :'

set colo to
@ 21,00 clear to 24,79
choice= 'T'
action= 'SAY'


DO WHILE .T.

   SET COLO TO +W/BG
   @ 4, 21 SAY inv_n   PICTURE '@!'
   @ 05,21 SAY cust_n  PICTURE '@!'
   @ 04,46 SAY cust_m  PICTURE '@!'
   @ 05,46 SAY cust_ad PICTURE '@!'
   @ 06,46 SAY cust_ct PICTURE '@!'
   @ 07,46 SAY cust_ac PICTURE '@!'
   @  7,21 SAY cust_s  PICTURE '@!'

   if PAID="T"
      @ 11,64 say "TRUE "
   else                 
      @ 11,64 say "FALSE"
   endif

   DO CASE
      CASE status=' '
           @ 11, 21 SAY 'For Invoicing'
      CASE status='I'
           @ 11, 21 SAY 'For Posting  '
      CASE status='P'
           @ 11, 21 SAY 'Posted       '
      CASE status='C'
           @ 11, 21 SAY 'Cancelled    '
   ENDCASE

   set cent on
   @ 13,21 SAY inv_d   PICTURE '99/99/9999'
   set cent off
   @ 14,21 SAY inv_c   PICTURE '@Z #,###,###.##'
   @ 15,21 SAY inv_a   PICTURE '#,###,###.##'
   @ 16,21 SAY dcount1 PICTURE '##.##'
   @ 16,24 SAY dcount2 PICTURE '##'
   @ 16,27 SAY dcount3 PICTURE '##'
   @ 19,21 SAY si_rem  PICTURE '@!'
   @ 14,64 SAY inv_adj PICTURE '#,###,###.##'
   @ 15,64 SAY inv_pay PICTURE '#,###,###.##'
   @ 1, 69 SAY post_m  PICTURE '@!'
   @ 17,21 SAY net_a   PICTURE '#,###,###.##'
   @ 17,64 SAY inv_bal PICTURE '#,###,###.##'

   set colo to +gr, +*w/b
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
           @ 13,21 get mSv_date  PICTURE '99/99/9999'
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

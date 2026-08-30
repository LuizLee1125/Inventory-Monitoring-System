* program.....: InvAdj.prg

SET CENTURY ON

SELECT 2
   USE STKREC INDEX TRANS_CN, TRANS_ID, SI_ID
SELECT 1
   USE STKFYL INDEX STK_N

choice= 'S'
DO BRDR1
&C_HEAD
@ 14, 21 SAY ' QUANTITY LOC. L.UPD. '
&C_BODY
@ 4, 5 SAY 'Stock Code      :'
@ 5, 5 SAY 'Description     :'
@ 6, 5 SAY 'Size            :'
@ 7, 5 SAY 'Lot Number      :'
@ 8, 5 SAY 'Expiry Date     :'
@ 9, 5 SAY 'Div./Category   :       -'
@ 10, 5 SAY 'Re-order Level  :'
@ 11, 5 SAY 'Maintain Level  :'
@ 12, 5 SAY 'Unit            :'
@ 13, 5 SAY 'Pkg. (Qty/Unit) :       /'
@ 15, 5 SAY 'On Hand         :'
@ 16, 5 SAY 'Bodega 2        :'
@ 17, 5 SAY 'Bodega 3        :'

set colo to
@ 21,00 clear to 24,79

DO WHILE .T.
   SET COLO TO +W/BG
   @ 4, 23 SAY stk_n    PICTURE '@!'
   @ 5, 23 SAY stk_m    PICTURE '@!'
   @ 6, 23 SAY qty_s    PICTURE '@!'
   @ 7, 23 SAY lot_n    PICTURE '@!'
   @ 8, 23 SAY expiry_d PICTURE '99/99/9999'
   @ 9, 23 SAY stk_dv   PICTURE '@!'
   @ 9, 31 SAY stk_cat  PICTURE '@!'
   @ 10,23 SAY qty_r    PICTURE '###,###'
   @ 11,23 SAY qty_m    PICTURE '###,###'
   @ 12,23 SAY qty_u    PICTURE '@!'
   @ 13,23 SAY qty_pq   PICTURE '#,###'
   @ 13,31 SAY qty_pu   PICTURE '@!'
   @ 15,23 SAY qty1     PICTURE '###,###'
   @ 15,31 SAY qty1L    PICTURE '@!'
   @ 15,35 SAY qty1Lu   PICTURE "99/99/9999"
   @ 16,23 SAY qty2     PICTURE '###,###'
   @ 16,31 SAY qty2L    PICTURE '@!'
   @ 16,35 SAY qty2Lu   PICTURE "99/99/9999"
   @ 17,23 SAY qty3     PICTURE '###,###'
   @ 17,31 SAY qty3L    PICTURE '@!'
   @ 17,35 SAY qty3Lu   PICTURE "99/99/9999"
   @ 1, 69 SAY user_m   PICTURE '@!'
   &C_HEAD
   @ 18, 5 SAY 'TOTAL           :'
   &C_GET
   @ 18, 22 SAY QTY1+QTY2+QTY3 PICTURE '####,###'

   set colo to +gr, +*w/b
   @ 21,20 prompt " Top "
   @ 21,25 prompt " Bottom "
   @ 21,33 prompt " Next "
   @ 21,39 prompt " Prev "
   @ 21,45 prompt " Find "
   @ 21,51 prompt " Edit "
   @ 21,57 prompt " Quit "
   menu to atlbar

   do case
      case atlbar = 1
           go top
      case atlbar = 2
           go bott
      case atlbar = 3
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
      case atlbar = 4
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
      case atlbar = 5  && find
           set exact off
           store space(10) to mStk_N
           store recno()   to mRecno
           set colo to ,+gr/r
           @ 4,23 get mStk_N pict '@!'
           read
           if mStk_N=" "
              set exact on
              loop
           endif
           seek trim(mStk_N)
           if .not. found()
              save screen to atlscreen
              atlmsg="stock code "+trim(mStk_n)+" not found! press any key to continue..."
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
      case atlbar = 6  && edit
           store QTY1 to mQty1
           store recno()   to mRecno
           set colo to ,+gr/b
           @ 15,23 GET mQty1 PICTURE '###,###'
           read
           if mQty1=Qty1
              loop
           endif
           @ 18, 22 SAY mQTY1 PICTURE '####,###'
           save screen to atlscreen
           atlmsg="Post edited "+trim(Stk_n)+" to the master file (y/n)?"
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
              stor stk_n  to sv_stk_n
              stor stk_m  to sv_stk_m
              stor qty1   to sv_qty1
              repl QTY1   with mQty1
              repl User_M with mUser
              unlock
              sele 2
              append blank
              REPLACE qty1    WITH mQty1
              REPLACE issue_q WITH sv_qty1
              REPLACE trans_n WITH 'INV-ADJ   '
              REPLACE trans_c WITH 'I'
              REPLACE trans_d WITH DATE()
              REPLACE stk_n   WITH sv_stk_n
              REPLACE stk_m   WITH sv_stk_m
              REPLACE user_m  WITH muser
              REPLACE TAYM    WITH TIME(1)
              UNLOCK
              SELECT 1
              restore screen from atlscreen
           else
              restore screen from atlscreen
              go mRecno
              loop
           endif

      case atlbar = 7  && quit
           exit
   endcase
enddo

SET CENTURY OFF
CLOSE DATABASE
RETURN
 

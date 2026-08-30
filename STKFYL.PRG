* program.....: Stkfyl.prg
*             : stock master file maintenance

SET CENTURY ON
SET EXACT ON
USE STKFYL INDEX STK_N

DO BRDR1
&C_HEAD
@ 14, 21 SAY ' QUANTITY LOC. L.UPD. '
@ 14, 59 SAY ' PRICE    MARK UP '
&C_BODY
@ 4, 5 SAY 'Stock Code      :'
@ 5, 5 SAY 'Description     :'
@ 6, 5 SAY 'Size            :'
@ 7, 5 SAY 'Lot Number      :'
@ 8, 5 SAY 'Expiry Date     :'
@ 9, 5 SAY 'Div./Category   :       -'
@10, 5 SAY 'Re-order Level  :'
@11, 5 SAY 'Maintain Level  :'
@12, 5 SAY 'Unit            :'
@13, 5 SAY 'Pkg. (Qty/Unit) :       /'
@15, 5 SAY 'On Hand         :'
@16, 5 SAY 'Bodega 2        :'
@17, 5 SAY 'Bodega 3        :'
@19, 5 SAY 'Remarks         :'
@ 6,40 SAY 'Form             :'
@ 7,40 SAY 'Last Purchase    :'
@ 8,40 SAY 'Supplier Code    :'
@ 9,40 SAY 'Purchase Cost    :'
@10,40 SAY 'Ave. Purc. Cost  :'
@11,40 SAY 'Catalog Price    :'
@12,40 SAY 'Price Update     :'
@13,40 SAY 'For Price Update :'
@15,55 SAY 'A :'
@16,55 SAY 'B :'
@17,55 SAY 'C :'
@18,55 SAY 'D :'
@19,55 SAY 'E :'
set colo to
@ 21,00 clear to 24,79

action="SAY"
choice="T"
DO WHILE .T.

   SET COLO TO +W/BG
   @ 4, 23 SAY STK_N     PICT '@!'
   @ 05,23 SAY STK_M     PICT '@!'
   @ 06,23 SAY QTY_S     PICT '@!'
   @ 07,23 SAY LOT_N     PICT '@!'
   *@ 08,23 SAY EXPIRY_D  PICT '99/99/9999'
   @ 08,23 say left(dtoc(expiry_d),3)
   @ 08,26 say righ(dtoc(expiry_d),4)
   @ 09,23 SAY STK_DV    PICT '@!'
   @ 09,31 SAY STK_CAT   PICT '@!'
   @ 10,23 SAY QTY_R     PICT '###,###'
   @ 11,23 SAY QTY_M     PICT '###,###'
   @ 12,23 SAY QTY_U     PICT '@!'
   @ 13,23 SAY QTY_PQ    PICT '#,###'
   @ 13,31 SAY QTY_PU    PICT '@!'
   @ 15,23 SAY QTY1      PICT '###,###'
   @ 15,31 SAY QTY1L     PICT '@!'
   @ 15,35 SAY QTY1LU    PICT '99/99/9999'
   @ 16,23 SAY QTY2      PICT '###,###'
   @ 16,31 SAY QTY2L     PICT '@!'
   @ 16,35 SAY QTY2LU    PICT '99/99/9999'
   @ 17,23 SAY QTY3      PICT '###,###'
   @ 17,31 SAY QTY3L     PICT '@!'
   @ 17,35 SAY QTY3LU    PICT '99/99/9999'
   @ 19,23 SAY STK_REM   PICT '@!'
   @ 06,59 SAY FORM      PICT '@!'
   @ 07,59 SAY STK_LT    PICT '99/99/9999'
   @ 08,59 SAY SPLYR_N   PICT '@!'
   @ 09,59 SAY STK_PC    PICT '##,###.##'
   @ 10,59 SAY STK_AC    PICT '##,###.##'
   @ 11,59 SAY STK_CP    PICT '##,###.##'
   @ 12,59 SAY PRYS_UD   PICT '99/99/9999'
   @ 13,59 SAY PRYS_CH   PICT 'L'
   @ 15,59 SAY PRYS_A    PICT '@Z ##,###.##'
   @ 15,70 SAY MARKUP_A1 PICT '@Z ###'
   @ 15,74 SAY MARKUP_A2 PICT '@Z ###'
   @ 16,59 SAY PRYS_B    PICT '@Z ##,###.##'
   @ 16,70 SAY MARKUP_B1 PICT '@Z ###'
   @ 16,74 SAY MARKUP_B2 PICT '@Z ###'
   @ 17,59 SAY PRYS_C    PICT '@Z ##,###.##'
   @ 17,70 SAY MARKUP_C1 PICT '@Z ###'
   @ 17,74 SAY MARKUP_C2 PICT '@Z ###'
   @ 18,59 SAY PRYS_D    PICT '@Z ##,###.##'
   @ 18,70 SAY MARKUP_D1 PICT '@Z ###'
   @ 18,74 SAY MARKUP_D2 PICT '@Z ###'
   @ 19,59 SAY PRYS_E    PICT '@Z ##,###.##'
   @ 19,70 SAY MARKUP_E1 PICT '@Z ###'
   @ 19,74 SAY MARKUP_E2 PICT '@Z ###'
   @ 1, 69 SAY USER_M    PICT '@!'
   &C_HEAD
   @ 18, 5 SAY 'TOTAL           :'
   &C_GET
   @ 18, 22 SAY QTY1+QTY2+QTY3 PICTURE '####,###'

*  set colo to +gr, +*w/b
*  @ 21,13 prompt " Top "
*  @ 21,18 prompt " Bottom "
*  @ 21,26 prompt " Next "
*  @ 21,32 prompt " Prev "
*  @ 21,38 prompt " Find "
*  @ 21,44 prompt " Add "
*  @ 21,49 prompt " Edit "
*  @ 21,55 prompt " Delete "
*  @ 21,63 prompt " Quit "
*  menu to atlbar
   do option6
   atlbar=choice

   do case
      case atlbar = "T" && 1
           go top
      case atlbar = "B" && 2
           go bott
      case atlbar = "N" && 3
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
      case atlbar = "V" && 4
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
      case atlbar = "F" && find 5
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
      case atlbar = "A"  && add 6
           store space(10) to mStk_N
           store recno()   to mRecno
           set colo to ,+gr/b
           @ 4,23 get mStk_N pict '@!'
           read
           if mStk_N=" "
              loop
           endif
           seek trim(mStk_N)
           if found()
              save screen to atlscreen
              atlmsg="stock code "+trim(mStk_n)+" already exists, press any key..."
              atllen=len(atlmsg)
              set colo to rb/rb
              @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
              set colo to +w/rb
              @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
              @ 12,41-atllen/2 say atlmsg
              atlkeypress=inkey(0)
              restore screen from atlscreen
              go mRecno
              loop
           endif      
           mStk_M     = space(30)
           mQty_S     = space(10)
           mLot_N     = space(15)
           mExp_m     = space(2)
           mExp_y     = space(4)
           mExpiry_D  = ctod('  /  /    ')
           mStk_Dv    = space(5)
           mStk_Cat   = space(5)
           mQty_R     = 0
           mQty_M     = 0
           mQty_U     = space(4)
           mQty_Pq    = 0
           mQty_Pu    = space(4)
           mQty1      = 0
           mQty1L     = space(3)
           mQty1LU    = date()
           mQty2      = 0
           mQty2L     = space(3)
           mQty2Lu    = date()
           mQty3      = 0
           mQty3L     = space(3)
           mQty3Lu    = date()
           mStk_Rem   = space(30)
           mForm      = space(5)
           mStk_Lt    = date()
           mSplyr_N   = space(10)
           mStk_Pc    = 0
           mStk_Ac    = 0
           mStk_CP    = 0
           mPrys_Ud   = date()
           mPrys_Ch   = "N"
           mPrys_A    = 0
           mMarkup_A1 = 0
           mMarkup_A2 = 0
           mPrys_B    = 0
           mMarkup_B1 = 0
           mMarkup_B2 = 0
           mPrys_C    = 0
           mMarkup_C1 = 0
           mMarkup_C2 = 0
           mPrys_D    = 0
           mMarkup_D1 = 0
           mMarkup_D2 = 0
           mPrys_E    = 0
           mMarkup_E1 = 0
           mMarkup_E2 = 0

           set colo to ,+w/bg
           @ 05,23 get mSTK_M     PICT '@!'
           @ 06,23 get mQTY_S     PICT '@!'
           @ 07,23 get mLOT_N     PICT '@!'
           @ 08,23 get mexp_m     pict '99'
           @ 08,25 say '/'
           @ 08,26 get mexp_y     pict '9999'
          *@ 08,23 get mEXPIRY_D  PICT '99/99/9999'
           @ 09,23 get mSTK_DV    PICT '@!'
           @ 09,31 get mSTK_CAT   PICT '@!'
           @ 10,23 get mQTY_R     PICT '###,###'
           @ 11,23 get mQTY_M     PICT '###,###'
           @ 12,23 get mQTY_U     PICT '@!'
           @ 13,23 get mQTY_PQ    PICT '#,###'
           @ 13,31 get mQTY_PU    PICT '@!'
           @ 15,23 get mQTY1      PICT '###,###'
           @ 15,31 get mQTY1L     PICT '@!'
           @ 15,35 get mQTY1LU    PICT '99/99/9999'
           @ 16,23 get mQTY2      PICT '###,###'
           @ 16,31 get mQTY2L     PICT '@!'
           @ 16,35 get mQTY2LU    PICT '99/99/9999'
           @ 17,23 get mQTY3      PICT '###,###'
           @ 17,31 get mQTY3L     PICT '@!'
           @ 17,35 get mQTY3LU    PICT '99/99/9999'
           @ 19,23 get mSTK_REM   PICT '@!'
           @ 06,59 get mFORM      PICT '@!'
           @ 07,59 get mSTK_LT    PICT '99/99/9999'
           @ 08,59 get mSPLYR_N   PICT '@!'
           @ 09,59 get mSTK_PC    PICT '##,###.##'
           @ 10,59 get mSTK_AC    PICT '##,###.##'
           @ 11,59 get mSTK_CP    PICT '##,###.##'
           @ 12,59 get mPRYS_UD   PICT '99/99/9999'
           @ 13,59 get mPRYS_CH   PICT 'L'
           @ 15,59 get mPRYS_A    PICT '@Z ##,###.##'
           @ 15,70 get mMARKUP_A1 PICT '@Z ###'
           @ 15,74 get mMARKUP_A2 PICT '@Z ###'
           @ 16,59 get mPRYS_B    PICT '@Z ##,###.##'
           @ 16,70 get mMARKUP_B1 PICT '@Z ###'
           @ 16,74 get mMARKUP_B2 PICT '@Z ###'
           @ 17,59 get mPRYS_C    PICT '@Z ##,###.##'
           @ 17,70 get mMARKUP_C1 PICT '@Z ###'
           @ 17,74 get mMARKUP_C2 PICT '@Z ###'
           @ 18,59 get mPRYS_D    PICT '@Z ##,###.##'
           @ 18,70 get mMARKUP_D1 PICT '@Z ###'
           @ 18,74 get mMARKUP_D2 PICT '@Z ###'
           @ 19,59 get mPRYS_E    PICT '@Z ##,###.##'
           @ 19,70 get mMARKUP_E1 PICT '@Z ###'
           @ 19,74 get mMARKUP_E2 PICT '@Z ###'
           READ
           @ 18, 22 SAY mQTY1+mQTY2+mQTY3 PICTURE '####,###'
           save screen to atlscreen
           atlmsg="Add "+trim(mStk_n)+" to the master file (y/n)?"
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
              append blank
              repl STK_N    with mSTK_N
              repl STK_M    with mSTK_M  
              repl QTY_S    with mQTY_S
              repl LOT_N    with mLOT_N
             *repl EXPIRY_D with mEXPIRY_D
              repl expiry_d with ctod(mexp_m+'/01/'+mexp_y)
              repl STK_DV   with mSTK_DV  
              repl STK_CAT  with mSTK_CAT 
              repl QTY_R    with mQTY_R   
              repl QTY_M    with mQTY_M   
              repl QTY_U    with mQTY_U   
              repl QTY_PQ   with mQTY_PQ  
              repl QTY_PU   with mQTY_PU  
              repl QTY1     with mQTY1    
              repl QTY1L    with mQTY1L   
              repl QTY1LU   with mQTY1LU
              repl QTY2     with mQTY2
              repl QTY2L    with mQTY2L
              repl QTY2LU   with mQTY2LU    
              repl QTY3     with mQTY3      
              repl QTY3L    with mQTY3L     
              repl QTY3LU   with mQTY3LU
              repl STK_REM  with mSTK_REM   
              repl FORM     with mFORM      
              repl STK_LT   with mSTK_LT
              repl SPLYR_N  with mSPLYR_N   
              repl STK_PC   with mSTK_PC    
              repl STK_AC   with mSTK_AC    
              repl STK_CP   with mSTK_CP    
              repl PRYS_UD  with mPRYS_UD
              repl PRYS_CH  with mPRYS_CH   
              repl PRYS_A   with mPRYS_A    
              repl MARKUP_A1 with mMARKUP_A1 
              repl MARKUP_A2 with mMARKUP_A2 
              repl PRYS_B    with mPRYS_B    
              repl MARKUP_B1 with mMARKUP_B1 
              repl MARKUP_B2 with mMARKUP_B2 
              repl PRYS_C    with mPRYS_C    
              repl MARKUP_C1 with mMARKUP_C1 
              repl MARKUP_C2 with mMARKUP_C2 
              repl PRYS_D    with mPRYS_D    
              repl MARKUP_D1 with mMARKUP_D1 
              repl MARKUP_D2 with mMARKUP_D2 
              repl PRYS_E    with mPRYS_E    
              repl MARKUP_E1 with mMARKUP_E1 
              repl MARKUP_E2 with mMARKUP_E2
              repl User_M    with mUser
              unlock
              restore screen from atlscreen
           else
              restore screen from atlscreen
              go mRecno
              loop
           endif

      case atlbar = "E"  && edit 7
           store stk_n to mStk_N
           store recno()   to mRecno
           set colo to ,+gr/r
           @ 4,23 get mStk_N pict '@!'
           read
           if mStk_N=" "
              loop
           endif
           seek trim(mStk_N)
           if found() .and. recno()<>mRecno
              save screen to atlscreen
              atlmsg="stock code "+trim(mStk_n)+" already exists, press any key..."
              atllen=len(atlmsg)
              set colo to rb/rb
              @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
              set colo to +w/rb
              @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
              @ 12,41-atllen/2 say atlmsg
              atlkeypress=inkey(0)
              restore screen from atlscreen
              go mRecno
              loop
           endif      
           mStk_M     = Stk_M
           mQty_S     = Qty_S
           mLot_N     = Lot_N
           mExpiry_D  = Expiry_D
           mexp_m     = left(dtoc(expiry_d),2)
           mexp_y     = righ(dtoc(expiry_d),4)
           mStk_Dv    = Stk_Dv  
           mStk_Cat   = Stk_Cat 
           mQty_R     = Qty_R 
           mQty_M     = Qty_M 
           mQty_U     = Qty_U  
           mQty_Pq    = Qty_Pq  
           mQty_Pu    = Qty_Pu
           mQty1      = Qty1
           mQty1L     = Qty1L
           mQty1LU    = Qty1LU
           mQty2      = Qty2 
           mQty2L     = Qty2L 
           mQty2Lu    = Qty2Lu
           mQty3      = Qty3 
           mQty3L     = Qty3L 
           mQty3Lu    = Qty3Lu 
           mStk_Rem   = Stk_Rem
           mForm      = Form
           mStk_Lt    = Stk_Lt
           mSplyr_N   = Splyr_N
           mStk_Pc    = Stk_Pc
           mStk_Ac    = Stk_Ac
           mStk_CP    = Stk_CP
           mPrys_Ud   = Prys_Ud
           mPrys_Ch   = Prys_Ch 
           mPrys_A    = Prys_A
           mMarkup_A1 = Markup_A1
           mMarkup_A2 = Markup_A2
           mPrys_B    = Prys_B
           mMarkup_B1 = Markup_B1
           mMarkup_B2 = Markup_B2
           mPrys_C    = Prys_C
           mMarkup_C1 = Markup_C1
           mMarkup_C2 = Markup_C2 
           mPrys_D    = Prys_D
           mMarkup_D1 = Markup_D1
           mMarkup_D2 = Markup_D2
           mPrys_E    = Prys_E 
           mMarkup_E1 = Markup_E1
           mMarkup_E2 = Markup_E2
           set colo to ,+w/bg
           @ 05,23 get mSTK_M     PICT '@!'
           @ 06,23 get mQTY_S     PICT '@!'
           @ 07,23 get mLOT_N     PICT '@!'
          *@ 08,23 get mEXPIRY_D  PICT '99/99/9999'
           @ 08,23 get mexp_m     pict '99'
           @ 08,26 get mexp_y     pict '9999'
           @ 09,23 get mSTK_DV    PICT '@!'
           @ 09,31 get mSTK_CAT   PICT '@!'
           @ 10,23 get mQTY_R     PICT '###,###'
           @ 11,23 get mQTY_M     PICT '###,###'
           @ 12,23 get mQTY_U     PICT '@!'
           @ 13,23 get mQTY_PQ    PICT '#,###'
           @ 13,31 get mQTY_PU    PICT '@!'
           @ 15,23 get mQTY1      PICT '###,###'
           @ 15,31 get mQTY1L     PICT '@!'
           @ 15,35 get mQTY1LU    PICT '99/99/9999'
           @ 16,23 get mQTY2      PICT '###,###'
           @ 16,31 get mQTY2L     PICT '@!'
           @ 16,35 get mQTY2LU    PICT '99/99/9999'
           @ 17,23 get mQTY3      PICT '###,###'
           @ 17,31 get mQTY3L     PICT '@!'
           @ 17,35 get mQTY3LU    PICT '99/99/9999'
           @ 19,23 get mSTK_REM   PICT '@!'
           @ 06,59 get mFORM      PICT '@!'
           @ 07,59 get mSTK_LT    PICT '99/99/9999'
           @ 08,59 get mSPLYR_N   PICT '@!'
           @ 09,59 get mSTK_PC    PICT '##,###.##'
           @ 10,59 get mSTK_AC    PICT '##,###.##'
           @ 11,59 get mSTK_CP    PICT '##,###.##'
           @ 12,59 get mPRYS_UD   PICT '99/99/9999'
           @ 13,59 get mPRYS_CH   PICT 'L'
           @ 15,59 get mPRYS_A    PICT '@Z ##,###.##'
           @ 15,70 get mMARKUP_A1 PICT '@Z ###'
           @ 15,74 get mMARKUP_A2 PICT '@Z ###'
           @ 16,59 get mPRYS_B    PICT '@Z ##,###.##'
           @ 16,70 get mMARKUP_B1 PICT '@Z ###'
           @ 16,74 get mMARKUP_B2 PICT '@Z ###'
           @ 17,59 get mPRYS_C    PICT '@Z ##,###.##'
           @ 17,70 get mMARKUP_C1 PICT '@Z ###'
           @ 17,74 get mMARKUP_C2 PICT '@Z ###'
           @ 18,59 get mPRYS_D    PICT '@Z ##,###.##'
           @ 18,70 get mMARKUP_D1 PICT '@Z ###'
           @ 18,74 get mMARKUP_D2 PICT '@Z ###'
           @ 19,59 get mPRYS_E    PICT '@Z ##,###.##'
           @ 19,70 get mMARKUP_E1 PICT '@Z ###'
           @ 19,74 get mMARKUP_E2 PICT '@Z ###'
           READ
           @ 18, 22 SAY mQTY1+mQTY2+mQTY3 PICTURE '####,###'
           save screen to atlscreen
           atlmsg="Post edited "+trim(mStk_n)+" to the master file (y/n)?"
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
              repl STK_N    with mSTK_N
              repl STK_M    with mSTK_M  
              repl QTY_S    with mQTY_S
              repl LOT_N    with mLOT_N
             *repl EXPIRY_D with mEXPIRY_D
              repl expiry_d with ctod(mexp_m+'/01/'+mexp_y)
              repl STK_DV   with mSTK_DV  
              repl STK_CAT  with mSTK_CAT 
              repl QTY_R    with mQTY_R   
              repl QTY_M    with mQTY_M   
              repl QTY_U    with mQTY_U   
              repl QTY_PQ   with mQTY_PQ  
              repl QTY_PU   with mQTY_PU  
              repl QTY1     with mQTY1    
              repl QTY1L    with mQTY1L   
              repl QTY1LU   with mQTY1LU
              repl QTY2     with mQTY2
              repl QTY2L    with mQTY2L
              repl QTY2LU   with mQTY2LU    
              repl QTY3     with mQTY3      
              repl QTY3L    with mQTY3L     
              repl QTY3LU   with mQTY3LU
              repl STK_REM  with mSTK_REM   
              repl FORM     with mFORM      
              repl STK_LT   with mSTK_LT
              repl SPLYR_N  with mSPLYR_N   
              repl STK_PC   with mSTK_PC    
              repl STK_AC   with mSTK_AC    
              repl STK_CP   with mSTK_CP    
              repl PRYS_UD  with mPRYS_UD
              repl PRYS_CH  with mPRYS_CH   
              repl PRYS_A   with mPRYS_A    
              repl MARKUP_A1 with mMARKUP_A1 
              repl MARKUP_A2 with mMARKUP_A2 
              repl PRYS_B    with mPRYS_B    
              repl MARKUP_B1 with mMARKUP_B1 
              repl MARKUP_B2 with mMARKUP_B2 
              repl PRYS_C    with mPRYS_C    
              repl MARKUP_C1 with mMARKUP_C1 
              repl MARKUP_C2 with mMARKUP_C2 
              repl PRYS_D    with mPRYS_D    
              repl MARKUP_D1 with mMARKUP_D1 
              repl MARKUP_D2 with mMARKUP_D2 
              repl PRYS_E    with mPRYS_E    
              repl MARKUP_E1 with mMARKUP_E1 
              repl MARKUP_E2 with mMARKUP_E2
              repl User_M    with mUser
              unlock
              restore screen from atlscreen
           else
              restore screen from atlscreen
              go mRecno
              loop
           endif

      case atlbar = "D"  && delete 8
           save screen to atlscreen
           stor recno() to mrecno1
           stor stk_n to mstk_n
           skip -1
           if .not. bof()
              store recno() to mrecno2
           else
              go top
              skip
              store recno() to mrecno2
           endif
           go mrecno1

           atlmsg="Are you sure you want to delete "+trim(mStk_n)+" (y/n)?"
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
              dele
              restore screen from atlscreen
              go mrecno2
           else
              restore screen from atlscreen
              go mRecno1
              loop
           endif   
      case atlbar = "Q"  && quit 9
           exit
   endcase
enddo

close data
set cent off
set exact off
return

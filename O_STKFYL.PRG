* program.....: O_Stkfyl.prg
*             : old stock master file maintenance

SET CENTURY ON
SET EXACT ON
USE O_STKFYL INDEX O_STK_N
*choice= 'S'

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
   @ 08,23 SAY EXPIRY_D  PICT '99/99/9999'
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

   *set colo to +gr, +*w/b
   *@ 21,13 prompt " Top "
   *@ 21,18 prompt " Bottom "
   *@ 21,26 prompt " Next "
   *@ 21,32 prompt " Prev "
   *@ 21,38 prompt " Find "
   *@ 21,44 prompt " Add "
   *@ 21,49 prompt " Edit "
   *@ 21,55 prompt " Delete "
   *@ 21,63 prompt " Quit "
   *menu to atlbar

   do option6
   atlbar=choice

   do case
      case atlbar = "T"
           go top
      case atlbar = "B"
           go bott
      case atlbar = "N"
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
      case atlbar = "V"
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
      case atlbar = "F" && find
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
      case atlbar = "A"  && add
              save screen to atlscreen
              atlmsg="sorry, ADD functionality is not feasible, press any key..."
              atllen=len(atlmsg)
              set colo to rb/rb
              @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
              set colo to +w/rb
              @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
              @ 12,41-atllen/2 say atlmsg
              atlkeypress=inkey(0)
              restore screen from atlscreen
              loop

      case atlbar = "E"  && edit
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
           @ 08,23 get mEXPIRY_D  PICT '99/99/9999'
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
              repl EXPIRY_D with mEXPIRY_D
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

      case atlbar = "D"  && delete
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
      case atlbar = "Q"  && quit
           exit
   endcase
enddo

close data
set cent off
set exact off
return




*****************
SET CENTURY ON

USE O_STKFYL INDEX O_STK_N
choice= 'SDA'

DO WHILE choice$'SDA'
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
    @ 10, 5 SAY 'Re-order Level  :'
    @ 11, 5 SAY 'Maintain Level  :'
    @ 12, 5 SAY 'Unit            :'
    @ 13, 5 SAY 'Pkg. (Qty/Unit) :       /'
    @ 15, 5 SAY 'On Hand         :'
    @ 16, 5 SAY 'Bodega 2        :'
    @ 17, 5 SAY 'Bodega 3        :'
    @ 19, 5 SAY 'Remarks         :'
    @ 6, 40 SAY 'Form             :'
    @ 7, 40 SAY 'Last Purchase    :'
    @ 8, 40 SAY 'Supplier Code    :'
    @ 9, 40 SAY 'Purchase Cost    :'
    @ 10, 40 SAY 'Ave. Purc. Cost  :'
    @ 11, 40 SAY 'Catalog Price    :'
    @ 12, 40 SAY 'Price Update     :'
    @ 13, 40 SAY 'For Price Update :'
    @ 15, 55 SAY 'A :'
    @ 16, 55 SAY 'B :'
    @ 17, 55 SAY 'C :'
    @ 18, 55 SAY 'D :'
    @ 19, 55 SAY 'E :'
    mfield01= SPACE(10)
    choice= 'F'
    action= 'GET'
    new= .T.
    DO WHILE choice$'FEVNTB'
        IF action='GET'
            key= mfield01
            &C_GET
            @ 4, 23 GET key PICTURE '@!'
            READ
            IF LEN(TRIM(key))=0
                SET CENTURY OFF
                CLOSE DATABASE
                RETURN
            ENDIF
            IF choice='F'.or.key<>mfield01
                DO MODE
                mfield01= key
            ENDIF
        ENDIF
        &C_GET
        IF action='SAY'
            mfield01= stk_n
            mfield02= stk_m
            mfield03= qty_s
            mfield04= lot_n
            mfield05= expiry_d
            mfield06= stk_dv
            mfield07= stk_cat
            mfield08= qty_r
            mfield09= qty_m
            mfield10= qty_u
            mfield11= qty_pq
            mfield12= qty_pu
            mfield13= qty1
            mfield14= qty1l
            mfield15= qty1lu
            mfield16= qty2
            mfield17= qty2l
            mfield18= qty2lu
            mfield19= qty3
            mfield20= qty3l
            mfield21= qty3lu
            mfield22= stk_rem
            mfield23= stk_lt
            mfield24= splyr_n
            mfield25= stk_pc
            mfield26= stk_ac
            mfield27= stk_cp
            mfield28= prys_ud
            mfield29= prys_ch
            mfield30= prys_a
            mfield31= markup_a1
            mfield32= markup_a2
            mfield33= prys_b
            mfield34= markup_b1
            mfield35= markup_b2
            mfield36= prys_c
            mfield37= markup_c1
            mfield38= markup_c2
            mfield39= prys_d
            mfield40= markup_d1
            mfield41= markup_d2
            mfield42= prys_e
            mfield43= markup_e1
            mfield44= markup_e2
            mfield45= user_m
            mfield46= form
        ENDIF
        IF choice='F'
            choice= 'E'
            mfield01= key
            mfield02= SPACE(30)
            mfield03= SPACE(10)
            mfield04= SPACE(15)
            mfield05= CTOD('  /  /    ')
            mfield06= SPACE(5)
            mfield07= SPACE(5)
            mfield08= 0
            mfield09= 0
            mfield10= SPACE(4)
            mfield11= 0
            mfield12= SPACE(4)
            mfield13= 0
            mfield14= SPACE(3)
            mfield15= DATE()
            mfield16= 0
            mfield17= SPACE(3)
            mfield18= DATE()
            mfield19= 0
            mfield20= SPACE(3)
            mfield21= DATE()
            mfield22= SPACE(30)
            mfield23= DATE()
            mfield24= SPACE(10)
            mfield25= 0
            mfield26= 0
            mfield27= 0
            mfield28= DATE()
            mfield29= 'N'
            mfield30= 0
            mfield31= 0
            mfield32= 0
            mfield33= 0
            mfield34= 0
            mfield35= 0
            mfield36= 0
            mfield37= 0
            mfield38= 0
            mfield39= 0
            mfield40= 0
            mfield41= 0
            mfield42= 0
            mfield43= 0
            mfield44= 0
            mfield45= muser
            mfield46= SPACE(5)
        ENDIF
        @ 4, 23 SAY mfield01 PICTURE '@!'
        @ 05,23 &ACTION mFIELD02 PICT '@!'
        @ 06,23 &ACTION mFIELD03 PICT '@!'
        @ 07,23 &ACTION mFIELD04 PICT '@!'
        @ 08,23 &ACTION mFIELD05 PICT '99/99/9999'
        @ 09,23 &ACTION mFIELD06 PICT '@!'
        @ 09,31 &ACTION mFIELD07 PICT '@!'
        @ 10,23 &ACTION mFIELD08 PICT '###,###'
        @ 11,23 &ACTION mFIELD09 PICT '###,###'
        @ 12,23 &ACTION mFIELD10 PICT '@!'
        @ 13,23 &ACTION mFIELD11 PICT '#,###'
        @ 13,31 &ACTION mFIELD12 PICT '@!'
        @ 15,23 &ACTION mFIELD13 PICT '###,###'
        @ 15,31 &ACTION mFIELD14 PICT '@!'
        @ 15,35 &ACTION mFIELD15
        @ 16,23 &ACTION mFIELD16 PICT '###,###'
        @ 16,31 &ACTION mFIELD17 PICT '@!'
        @ 16,35 &ACTION mFIELD18
        @ 17,23 &ACTION mFIELD19 PICT '###,###'
        @ 17,31 &ACTION mFIELD20 PICT '@!'
        @ 17,35 &ACTION mFIELD21
        @ 19,23 &ACTION mFIELD22 PICT '@!'
        @ 06,59 &ACTION mFIELD46 PICT '@!'
        @ 07,59 &ACTION mFIELD23
        @ 08,59 &ACTION mFIELD24 PICT '@!'
        @ 09,59 &ACTION mFIELD25 PICT '##,###.##'
        @ 10,59 &ACTION mFIELD26 PICT '##,###.##'
        @ 11,59 &ACTION mFIELD27 PICT '##,###.##'
        @ 12,59 &ACTION mFIELD28
        @ 13,59 &ACTION mFIELD29 PICT 'L'
        @ 15,59 &ACTION mFIELD30 PICT '@Z ##,###.##'
        @ 15,70 &ACTION mFIELD31 PICT '@Z ###'
        @ 15,74 &ACTION mFIELD32 PICT '@Z ###'
        @ 16,59 &ACTION mFIELD33 PICT '@Z ##,###.##'
        @ 16,70 &ACTION mFIELD34 PICT '@Z ###'
        @ 16,74 &ACTION mFIELD35 PICT '@Z ###'
        @ 17,59 &ACTION mFIELD36 PICT '@Z ##,###.##'
        @ 17,70 &ACTION mFIELD37 PICT '@Z ###'
        @ 17,74 &ACTION mFIELD38 PICT '@Z ###'
        @ 18,59 &ACTION mFIELD39 PICT '@Z ##,###.##'
        @ 18,70 &ACTION mFIELD40 PICT '@Z ###'
        @ 18,74 &ACTION mFIELD41 PICT '@Z ###'
        @ 19,59 &ACTION mFIELD42 PICT '@Z ##,###.##'
        @ 19,70 &ACTION mFIELD43 PICT '@Z ###'
        @ 19,74 &ACTION mFIELD44 PICT '@Z ###'
        @ 1, 69 SAY mfield45 PICTURE '@!'
        IF action='GET'
            READ
            IF READKEY()=4.or.READKEY()=261
                LOOP
            ENDIF
        ENDIF
        &C_HEAD
        @ 18, 5 SAY 'TOTAL           :'
        &C_GET
        @ 18, 22 SAY mfield13+mfield16+mfield19 PICTURE '####,###'
        DO OPTION1
    ENDDO
     IF choice='S'.and.action='GET'
    *    IF new
    *        APPEND BLANK
    *    ENDIF
         REPLACE stk_n WITH mfield01, stk_m WITH mfield02, qty_s WITH mfield03, lot_n WITH mfield04, expiry_d WITH mfield05, stk_dv WITH mfield06, stk_cat WITH mfield07, qty_r WITH mfield08, qty_m WITH mfield09
         REPLACE qty_u WITH mfield10, qty_pq WITH mfield11, qty_pu WITH mfield12
         REPLACE qty1 WITH mfield13, qty1l WITH mfield14, qty1lu WITH mfield15, qty2 WITH mfield16, qty2l WITH mfield17, qty2lu WITH mfield18, qty3 WITH mfield19, qty3l WITH mfield20, qty3lu WITH mfield21
         REPLACE stk_rem WITH mfield22, stk_lt WITH mfield23, splyr_n WITH mfield24, stk_pc WITH mfield25, stk_ac WITH mfield26, stk_cp WITH mfield27, prys_ud WITH mfield28, prys_ch WITH mfield29
         REPLACE prys_a WITH mfield30, markup_a1 WITH mfield31, markup_a2 WITH mfield32, prys_b WITH mfield33, markup_b1 WITH mfield34, markup_b2 WITH mfield35, prys_c WITH mfield36, markup_c1 WITH mfield37, markup_c2 WITH mfield38
         REPLACE prys_d WITH mfield39, markup_d1 WITH mfield40, markup_d2 WITH mfield41, prys_e WITH mfield42, markup_e1 WITH mfield43, markup_e2 WITH mfield44, user_m WITH muser, form WITH mfield46
         UNLOCK
     ENDIF
ENDDO
CLOSE DATABASE
SET CENTURY OFF
RETURN
 

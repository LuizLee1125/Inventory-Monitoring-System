* program.....: Bofyl.prg

SELECT 4
   USE STKFYL INDEX STK_N
SELECT 3
   USE BOFYL INDEX BOFYL
SELECT 2
   USE BOREC INDEX BOREC, BO_ID
   COPY STRU TO &mTEMPFYL
SELECT 1
   USE &mTEMPFYL ALIA TEMP EXCL

mtrans_c= 'S'
choice= 'S'
DO WHILE choice$'SDA'
    DO BRDR1
    &C_BODY
    @ 4, 2 SAY 'Invoice No.   :'
    @ 5, 2 SAY 'Customer Code :'
    @ 6, 2 SAY 'Address Code  :'
    @ 7, 2 SAY 'Salesman      :'
    @ 4, 51 SAY 'Date-Stat. :'
    @ 5, 51 SAY 'Type/Terms :'
    @ 6, 51 SAY 'Remarks    :'
    @ 7, 51 SAY 'P Cat / CA :'
    &C_HEAD
    @ 8, 1 SAY SPACE(78)
    @ 8, 5 SAY 'STOCK CODE   QTY.  UNIT DESCRIPTION            PRICE   DISCOUNT    TOTAL'
    SELECT 3
    mfield01= SPACE(10)
    choice= 'F'
    action= 'GET'
    new= .T.
    DO WHILE choice$'FEVNTB'
        &C_GET
        IF action='GET'
            key= mfield01
            @ 4, 18 GET key PICTURE '@!'
            READ
            IF LEN(TRIM(key))=0
                RETURN
            ENDIF
            IF choice='F'.or.key<>mfield01
                DO MODE
                mfield01= key
            ENDIF
        ENDIF
        IF action='SAY'
            mfield01= inv_n
            mfield02= cust_n
            mfield03= cust_m
            mfield04= cust_ad
            mfield05= cust_ct
            mfield06= ad_n
            mfield07= co_m
            mfield08= co_ad
            mfield09= co_ct
            mfield10= cust_s
            mfield11= inv_d
            mfield12= cust_tp
            mfield13= cust_t
            mfield14= si_rem
            mfield15= cust_pc
            mfield16= inv_c
            mfield17= inv_pc
            mfield18= inv_a
            mfield19= dcount1
            mfield20= dcount2
            mfield21= dcount3
            mfield22= net_a
            mfield23= user_m
            mfield24= status
        ENDIF
        IF choice='F'
            choice= 'E'
            mfield01= key
            mfield02= SPACE(10)
            mfield03= SPACE(30)
            mfield04= SPACE(30)
            mfield05= SPACE(30)
            mfield06= SPACE(10)
            mfield07= SPACE(30)
            mfield08= SPACE(30)
            mfield09= SPACE(30)
            mfield10= SPACE(10)
            mfield11= DATE()
            mfield12= SPACE(10)
            mfield13= 0
            mfield14= SPACE(14)
            mfield15= SPACE(1)
            mfield16= 0
            mfield17= 0
            mfield18= 0
            mfield19= 0
            mfield20= 0
            mfield21= 0
            mfield22= 0
            mfield23= muser
            mfield24= 'B'
        ENDIF
        &C_GET
        @ 4, 18 SAY mfield01 PICTURE '@!'
        IF mfield01<>inv_n
            mfield11= DATE()
            mfield24= 'B'
        ENDIF
        DO WHILE .T.
            @ 05,18 &ACTION mFIELD02 PICT '@!'
            IF action='GET'
                READ
                IF READKEY()=4.or.READKEY()=260
                    EXIT
                ENDIF
                subkey= mfield02
                SELECT 5
                USE CUSTFYL INDEX CUST_N
                DO VALID1
                IF EOF()
                    LOOP
                ELSE
                    mfield02= cust_n
                    mfield03= cust_m
                    mfield04= cust_ad
                    mfield05= cust_ct
                    mfield10= cust_s
                    mfield12= cust_tp
                    mfield13= cust_t
                    mfield15= cust_pc
                    @ 5, 18 SAY mfield02 PICTURE '@!'
                    @ 4, 29 SAY mfield03 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                    @ 5, 29 SAY mfield04 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                    @ 6, 29 SAY mfield05 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                    @ 7, 18 SAY mfield10 PICTURE '@!'
                    @ 7, 29 SAY cust_rem PICTURE '@!'
                    @ 5, 64 SAY mfield12 PICTURE '@!'
                    @ 5, 75 SAY mfield13 PICTURE '###'
                    @ 7, 64 SAY mfield15 PICTURE '@!'
                    @ 7, 66 SAY cust_cl-cust_bal PICTURE '#,###,###.##'
                ENDIF
                USE
                SELECT 3
            ENDIF
            DO WHILE .T.
                @ 06,18 &ACTION mFIELD06 PICT '@!'
                IF action='GET'
                    READ
                    IF READKEY()=4.or.READKEY()=260
                        EXIT
                    ENDIF
                    subkey= mfield06
                    IF LEN(TRIM(subkey))<>0
                        SELECT 5
                        USE ADFYL INDEX AD_N
                        DO VALID1
                        IF EOF()
                            LOOP
                        ELSE
                            mfield06= ad_n
                            mfield07= co_m
                            mfield08= co_ad
                            mfield09= co_ct
                            @ 6, 18 SAY mfield06 PICTURE '@!'
                            @ 4, 29 SAY mfield07 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                            @ 5, 29 SAY mfield08 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                            @ 6, 29 SAY mfield09 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                            IF READKEY()=4.or.READKEY()=260
                                LOOP
                            ENDIF
                        ENDIF
                        USE
                        SELECT 3
                    ENDIF
                ELSE
                    @ 5, 18 SAY mfield02 PICTURE '@!'
                    @ 4, 29 SAY mfield03 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                    @ 5, 29 SAY mfield04 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                    @ 6, 29 SAY mfield05 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                    IF mfield06<>SPACE(10)
                        @ 6, 18 SAY mfield06 PICTURE '@!'
                        @ 4, 29 SAY mfield07 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                        @ 5, 29 SAY mfield08 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                        @ 6, 29 SAY mfield09 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                    ENDIF
                    &C_CLEAR
                    @ 7, 29 SAY SPACE(20)
                    @ 7, 66 SAY SPACE(12)
                    &C_GET
                ENDIF
                @ 07,18 &ACTION mFIELD10 PICT '@!'
                @ 04,64 &ACTION mFIELD11
                @ 04,73 &ACTION mFIELD24 PICT '@!'
                @ 05,64 &ACTION mFIELD12 PICT '@!'
                @ 05,75 &ACTION mFIELD13 PICT '###'
                @ 06,64 &ACTION mFIELD14 PICT '@S14 !!!!!!!!!!!!!!!!!!!!'
                @ 07,64 &ACTION mFIELD15 PICT '@!'
                @ 1, 69 SAY mfield23 PICTURE '@!'
                IF action='GET'
                    READ
                    IF READKEY()=4.or.READKEY()=260
                        LOOP
                    ENDIF
                ENDIF
                IF action='GET'
                    DO WHILE mfield15<'A'.or.mfield15>'E'
                        @ 7, 64 GET mfield15 PICTURE '@!'
                        READ
                    ENDDO
                ENDIF
                EXIT
            ENDDO
            IF READKEY()=4.or.READKEY()=260
                LOOP
            ENDIF
            EXIT
        ENDDO
        IF READKEY()=4.or.READKEY()=260
            LOOP
        ENDIF
        lkey= mtrans_c+ bofyl->inv_n
        IF action='SAY'
            IF choice$'VNTB'
                &C_CLEAR
                @ 9, 1 CLEAR TO 19, 78
            ENDIF
            &C_CLEAR
            @ 22, 0
            &C_MESSAGE
            @ 23, 50 SAY ' Please wait... '
            SELECT 1
            ZAP
            SELECT 2
            SEEK lkey
            IF RLOCK()
                UNLOCK
            ENDIF
            DO WHILE  borec->trans_c+ borec->trans_n=lkey
                SELECT 1
                APPEND BLANK
                REPLACE trans_c WITH  borec->trans_c, trans_n WITH  borec->trans_n, trans_d WITH  borec->trans_d, cust_n WITH  borec->cust_n, cust_s WITH  borec->cust_s
                REPLACE stk_n WITH  borec->stk_n, stk_m WITH  borec->stk_m, stk_pc WITH  borec->stk_pc, stk_ac WITH  borec->stk_ac, qty_s WITH  borec->qty_s, qty1 WITH  borec->qty1
                REPLACE qty2 WITH  borec->qty2, qty3 WITH  borec->qty3, qty1l WITH  borec->qty1l, stk_dv WITH  borec->stk_dv, stk_cat WITH  borec->stk_cat, issue_d WITH  borec->issue_d
                REPLACE issue_q WITH  borec->issue_q, issue_fg WITH  borec->issue_fg, issue_u WITH  borec->issue_u, issue_p WITH  borec->issue_p
                REPLACE dcount1 WITH  borec->dcount1, dcount2 WITH  borec->dcount2, dcount3 WITH  borec->dcount3, t_prys WITH  borec->t_prys, t_ac WITH  borec->t_ac, t_pc WITH  borec->t_pc
                REPLACE lot_n WITH  borec->lot_n, expiry_d WITH  borec->expiry_d, user_m WITH  borec->user_m
                SELECT 2
                SKIP
                IF RLOCK()
                    UNLOCK
                ENDIF
            ENDDO
            &C_CLEAR
            @ 23, 0
            SELECT 1
            GOTO TOP
            pg= 0
        ENDIF
        DO WHILE .T.
            SELECT 1
            IF action='GET'.and.RECCOUNT()>0
                pg= INT((RECNO()-2)/10)
                IF RECNO()>pg*10
                    GOTO pg*10+1
                ENDIF
            ENDIF
            row= 9
            DO WHILE row<19
                IF EOF()
                    mstk_n= SPACE(10)
                    mstk_m= SPACE(30)
                    mstk_pc= 0
                    mstk_ac= 0
                    mqty_s= SPACE(10)
                    mqty1= 0
                    mqty2= 0
                    mqty3= 0
                    mqty1l= SPACE(3)
                    mstk_dv= SPACE(5)
                    mstk_cat= SPACE(5)
                    missue_q= 0
                    missue_fg= 0
                    missue_u= SPACE(4)
                    missue_p= 0
                    mdcount1= 0
                    mdcount2= 0
                    mdcount3= 0
                    mt_prys= 0
                    mt_ac= 0
                    mt_pc= 0
                    mlot_n= SPACE(15)
                    mexpiry_d= CTOD('  /  /  ')
                    muser_m= muser
                ELSE
                    mstk_n= stk_n
                    mstk_m= stk_m
                    mstk_pc= stk_pc
                    mstk_ac= stk_ac
                    mqty_s= qty_s
                    mqty1= qty1
                    mqty2= qty2
                    mqty3= qty3
                    mqty1l= qty1l
                    mstk_dv= stk_dv
                    mstk_cat= stk_cat
                    missue_q= issue_q
                    missue_fg= issue_fg
                    missue_u= issue_u
                    missue_p= issue_p
                    mdcount1= dcount1
                    mdcount2= dcount2
                    mdcount3= dcount3
                    mt_prys= t_prys
                    mt_ac= t_ac
                    mt_pc= t_pc
                    mlot_n= lot_n
                    mexpiry_d= expiry_d
                    muser_m= user_m
                ENDIF
                &C_GET
                @ row, 1 SAY RECNO() PICTURE '###'
                DO WHILE .T.
                    @ ROW,05 &ACTION mSTK_N PICT '@!'
                    IF action='GET'
                        READ
                        subkey= mstk_n
                        &C_CLEAR
                        @ 19, 1 SAY SPACE(78)
                        @ 22, 0
                        @ 23, 0
                        &C_GET
                        DO CASE
                            CASE READKEY()>3.and.READKEY()<8
                                DO KEYS
                                IF error
                                    error= .F.
                                    LOOP
                                ELSE
                                    EXIT
                                ENDIF
                            CASE LEN(TRIM(subkey))=0.and.EOF()
                                EXIT
                            CASE 'REMOVE'$subkey
                                mstk_n= 'REMOVE    '
                                &C_CLEAR
                                @ row, 5 CLEAR TO row, 78
                                &C_GET
                                EXIT
                            CASE READKEY()=12
                                EXIT
                        ENDCASE
                        SELECT 4
                        DO VALID1
                        IF EOF()
                            SELECT 1
                            LOOP
                        ELSE
                            mstk_n= stk_n
                            mstk_m= stk_m
                            mstk_pc= stk_pc
                            mstk_ac= stk_ac
                            mqty_s= qty_s
                            mqty1= qty1
                            mqty2= qty2
                            mqty3= qty3
                            mqty1l= qty1l
                            mstk_dv= stk_dv
                            mstk_cat= stk_cat
                            missue_u= qty_u
                            price= 'PRYS_'+mfield15
                            mISSUE_P  = &PRICE
                            mlot_n= lot_n
                            mexpiry_d= expiry_d
                            IF qty1<0
                                &C_MESSAGE
                                @ 23, 19 SAY ' Warning, no available stock (on hand). '
                                ?? CHR(7)
                            ENDIF
                            &C_HEAD
                            @ 19, 1 SAY SPACE(78)
                            @ 19, 3 SAY 'Packing :            On hand :         Bodega 2 :         Bodega 3 :'
                            @ 19, 13 SAY qty_pq PICTURE '#,###'
                            @ 19, 18 SAY '/'
                            @ 19, 19 SAY qty_pu PICTURE '@!'
                            @ 19, 34 SAY qty1 PICTURE '###,###'
                            @ 19, 53 SAY qty2 PICTURE '###,###'
                            @ 19, 72 SAY qty3 PICTURE '###,###'
                        ENDIF
                        SELECT 1
                    ENDIF
                    EXIT
                ENDDO
                DO CASE
                    CASE READKEY()=4.or.READKEY()=5
                        LOOP
                    CASE page
                        page= .F.
                        LOOP
                    CASE LEN(TRIM(mstk_n))=0.and.EOF()
                        IF READKEY()=7
                            action= 'GET'
                            LOOP
                        ENDIF
                        &C_CLEAR
                        @ row, 1 SAY SPACE(78)
                        GOTO TOP
                        EXIT
                    CASE READKEY()=12
                        EXIT
                ENDCASE
                &C_GET
                @ row, 5 SAY mstk_n PICTURE '@!'
                IF mstk_n<>'REMOVE'
                    @ ROW,16 &ACTION mISSUE_Q PICT '###,###'
                    @ row, 24 SAY missue_u PICTURE '@!'
                    @ row, 29 SAY mstk_m PICTURE '@S20'
                    @ ROW,50 &ACTION mISSUE_P PICT '#####.##'
                    @ ROW,59 &ACTION mDCOUNT1 PICT '###'
                    @ ROW,63 &ACTION mDCOUNT2 PICT '##'
                    @ ROW,66 &ACTION mDCOUNT3 PICT '##'
                    IF action='GET'
                        READ
                        mt_prys= missue_p
                        mt_prys= mt_prys-(mt_prys*mdcount1/100)
                        mt_prys= mt_prys-(mt_prys*mdcount2/100)
                        mt_prys= mt_prys-(mt_prys*mdcount3/100)
                        mt_prys= missue_q*mt_prys
                        mt_ac= missue_q*mstk_ac
                        mt_pc= missue_q*mstk_pc
                        IF mt_prys<mt_ac
                            &C_MESSAGE
                            @ 22, 22 SAY ' Warning, price is less than cost. '
                            ?? CHR(7)
                        ENDIF
                        IF mqty1-missue_q<0
                            &C_MESSAGE
                            @ 23, 19 SAY ' Warning, insufficient stock (on hand). '
                            ?? CHR(7)
                        ENDIF
                    ENDIF
                    &C_GET
                    @ row, 69 SAY mt_prys PICTURE '###,###.##'
                ENDIF
                IF action='GET'
                    IF EOF()
                        APPEND BLANK
                    ENDIF
                    REPLACE trans_c WITH mtrans_c, trans_n WITH mfield01, cust_n WITH mfield02, cust_s WITH mfield10
                    REPLACE stk_n WITH mstk_n, stk_m WITH mstk_m, stk_pc WITH mstk_pc, stk_ac WITH mstk_ac, qty_s WITH mqty_s, qty1l WITH mqty1l
                    REPLACE stk_dv WITH mstk_dv, stk_cat WITH mstk_cat, issue_d WITH mfield11
                    REPLACE issue_q WITH missue_q, issue_fg WITH missue_fg, issue_u WITH missue_u, issue_p WITH missue_p, dcount1 WITH mdcount1, dcount2 WITH mdcount2, dcount3 WITH mdcount3
                    REPLACE t_prys WITH mt_prys, t_ac WITH mt_ac, t_pc WITH mt_pc, lot_n WITH mlot_n, expiry_d WITH mexpiry_d, user_m WITH muser_m
                ENDIF
                SKIP
                row= row+1
                IF row=19.and.action='GET'
                    pg= pg+1
                    row= 9
                    &C_CLEAR
                    @ 9, 1 CLEAR TO 19, 78
                ENDIF
                IF row=19.and.(READKEY()=6.or.READKEY()=7)
                    action= 'GET'
                    row= row-1
                    SKIP  -1
                    LOOP
                ENDIF
            ENDDO
            IF action='GET'
                SUM FOR stk_n<>'REMOVE' t_ac, t_pc, t_prys TO mfield16, mfield17, mfield18
            ENDIF
            &C_HEAD
            @ 19, 1 SAY SPACE(78)
            @ 19, 55 SAY 'TOTAL'
            @ 19, 67 SAY mfield18 PICTURE '#,###,###.##'
            @ 20, 1 SAY SPACE(78)
            @ 20, 5 SAY 'DISCOUNT   %,   %,   %'
            &C_GET
            @ 20,15 &ACTION mFIELD19 PICT '##'
            @ 20,20 &ACTION mFIELD20 PICT '##'
            @ 20,25 &ACTION mFIELD21 PICT '##'
            IF action='GET'
                READ
                mfield22= mfield18
                mfield22= mfield22-(mfield22*mfield19/100)
                mfield22= mfield22-(mfield22*mfield20/100)
                mfield22= mfield22-(mfield22*mfield21/100)
                IF mfield22<mfield16
                    &C_MESSAGE
                    @ 23, 22 SAY ' Warning, price is less than cost. '
                    ?? CHR(7)
                ENDIF
            ENDIF
            &C_HEAD
            @ 20, 50 SAY 'NET AMOUNT'
            @ 20, 67 SAY mfield22 PICTURE '#,###,###.##'
            SELECT 3
            DO OPTION1
            IF choice='P'
                DO WHILE choice='P'
                    &C_CLEAR
                    @ 23, 0
                    confirm= ' '
                    &C_GET
                    DO WHILE .not. confirm$'AONM'
                        @ 23, 11 SAY ' A] Abort  O] Old Invoice  N] New Invoice  M] Marulas ' GET confirm PICTURE '!'
                        READ
                    ENDDO
                    &C_CLEAR
                    @ 23, 0
                    IF confirm<>'A'
                        &C_MESSAGE
                        @ 23, 50 SAY ' Loading Program ... '
                    ENDIF
                    DO CASE
                        CASE confirm='O'
                            DO SIOPRN
                        CASE confirm='N'
                            DO SINPRN
                        CASE confirm='M'
                            DO SIMPRN
                    ENDCASE
                    SELECT 3
                    DO OPTION1
                ENDDO
            ENDIF
            IF READKEY()=6.or.READKEY()=7
                SELECT 1
                DO PAGEKEY
                &C_CLEAR
                @ 21, 0
                &C_MESSAGE
                @ 21, 24 SAY ' NOTE: Please type your data. '
                LOOP
            ENDIF
            EXIT
        ENDDO
    ENDDO
    DO CASE
        CASE choice='D'.and..not. new
            SELECT 2
            SEEK lkey
            DO WHILE  borec->trans_c+ borec->trans_n=lkey
                SELECT 2
                DELETE
                SKIP
            ENDDO
            FLUSH
        CASE choice='S'.or.choice='M'
            SELECT 1
            GOTO TOP
            IF new
                USE
                SELECT 2
                APPE FROM &mTEMPFYL FOR STK_N <> "REMOVE"
                UNLOCK
                SELECT 1
                USE &mTEMPFYL ALIA TEMP EXCL
            ELSE
                SELECT 2
                SEEK lkey
                SELECT 1
                DO WHILE .not. EOF()
                    SELECT 2
                    IF EOF().or.trans_n<> bofyl->inv_n
                        APPEND BLANK
                    ENDIF
                    IF  temp->stk_n='REMOVE'
                        DELETE
                    ELSE
                        IF stk_n<> temp->stk_n.or.issue_q<> temp->issue_q
                            REPLACE qty1 WITH  temp->qty1, qty2 WITH  temp->qty2, qty3 WITH  temp->qty3, trans_d WITH  temp->trans_d
                        ENDIF
                        REPLACE trans_c WITH mtrans_c, trans_n WITH mfield01, cust_n WITH  temp->cust_n, cust_s WITH  temp->cust_s
                        REPLACE stk_n WITH  temp->stk_n, stk_m WITH  temp->stk_m, stk_pc WITH  temp->stk_pc, stk_ac WITH  temp->stk_ac
                        REPLACE qty1l WITH  temp->qty1l, stk_dv WITH  temp->stk_dv, stk_cat WITH  temp->stk_cat, issue_d WITH  temp->issue_d
                        REPLACE issue_q WITH  temp->issue_q, issue_fg WITH  temp->issue_fg, issue_u WITH  temp->issue_u, issue_p WITH  temp->issue_p, dcount1 WITH  temp->dcount1, dcount2 WITH  temp->dcount2
                        REPLACE dcount3 WITH  temp->dcount3, t_prys WITH  temp->t_prys, t_ac WITH  temp->t_ac, t_pc WITH  temp->t_pc, lot_n WITH  temp->lot_n, expiry_d WITH  temp->expiry_d, user_m WITH  temp->user_m
                        UNLOCK
                    ENDIF
                    IF mtrans_c+mfield01=lkey
                        SKIP
                    ELSE
                        SEEK lkey
                    ENDIF
                    SELECT 1
                    SKIP
                ENDDO
            ENDIF
            SELECT 3
            IF new
                APPEND BLANK
            ENDIF
            REPLACE inv_n WITH mfield01, cust_n WITH mfield02, cust_m WITH mfield03, cust_ad WITH mfield04, cust_ct WITH mfield05, ad_n WITH mfield06, co_m WITH mfield07, co_ad WITH mfield08, co_ct WITH mfield09
            REPLACE cust_s WITH mfield10, inv_d WITH mfield11, cust_tp WITH mfield12, cust_t WITH mfield13, si_rem WITH mfield14, cust_pc WITH mfield15
            REPLACE inv_c WITH mfield16, inv_pc WITH mfield17, inv_a WITH mfield18, dcount1 WITH mfield19, dcount2 WITH mfield20, dcount3 WITH mfield21, net_a WITH mfield22, user_m WITH muser, status WITH mfield24
            UNLOCK
            FLUSH
    ENDCASE
    SELECT 1
    ZAP
ENDDO
 

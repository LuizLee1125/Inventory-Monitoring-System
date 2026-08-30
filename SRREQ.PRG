
SET CENTURY ON
SELECT 6
USE CUSTFYL INDEX CUST_N
SELECT 5
USE SIFYL INDEX SI_N, SI_D, SI_CD
SELECT 4
USE STKFYL INDEX STK_N
SELECT 3
USE SRFYL INDEX SR_N, SR_D, SR_CD
SELECT 2
USE STKREC INDEX TRANS_CN, TRANS_ID, SI_ID
COPY STRU TO &mTEMPFYL
SELECT 1
USE &mTEMPFYL ALIA TEMP EXCL
mtrans_c= 'R'
choice= 'S'
DO WHILE choice$'SDA'
    DO BRDR1
    &C_BODY
    @ 4, 2 SAY 'SR No.        :'
    @ 5, 2 SAY 'Ref. SI No.   :'
    @ 6, 2 SAY 'Customer Code :'
    @ 7, 2 SAY 'Territory     :'
    @ 4, 51 SAY 'Date       :'
    @ 5, 51 SAY 'Remarks    :'
    @ 6, 51 SAY 'Price Cat. :'
    &C_HEAD
    @ 8, 1 SAY SPACE(78)
    @ 8, 5 SAY 'STOCK CODE  QTY.  BO UNIT DESCRIPTION          PRICE   DISCOUNT    TOTAL'
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
                SET CENTURY OFF
                CLOSE DATABASE
                RETURN
            ENDIF
            IF choice='F'.or.key<>mfield01
                DO MODE
                mfield01= key
            ENDIF
        ENDIF
        IF action='SAY'
            mfield01= inv_n
            mfield02= rinv_n
            mfield03= cust_n
            mfield04= cust_m
            mfield05= cust_ad
            mfield06= cust_ct
            mfield07= cust_ac
            mfield08= cust_s
            mfield09= inv_d
            mfield10= si_rem
            mfield11= cust_pc
            mfield12= inv_c
            mfield13= inv_pc
            mfield14= inv_a
            mfield15= dcount1
            mfield16= dcount2
            mfield17= dcount3
            mfield18= net_a
            mfield19= user_m
        ENDIF
        IF choice='F'
            choice= 'E'
            mfield01= key
            mfield02= SPACE(10)
            mfield03= SPACE(10)
            mfield04= SPACE(30)
            mfield05= SPACE(30)
            mfield06= SPACE(30)
            mfield07= SPACE(10)
            mfield08= SPACE(10)
            mfield09= DATE()
            mfield10= SPACE(20)
            mfield11= SPACE(1)
            mfield12= 0
            mfield13= 0
            mfield14= 0
            mfield15= 0
            mfield16= 0
            mfield17= 0
            mfield18= 0
            mfield19= muser
        ENDIF
        &C_GET
        @ 4, 18 SAY mfield01 PICTURE '@!'
        DO WHILE .T.
            @ 05,18 &ACTION mFIELD02 PICT '@!'
            IF action='GET'
                READ
                IF READKEY()=4.or.READKEY()=261
                    EXIT
                ENDIF
                subkey= mfield02
                IF LEN(TRIM(mfield02))<>0
                    SELECT 5
                    DO VALID2
                    IF EOF()
                        IF confirm='N'
                            LOOP
                        ENDIF
                    ELSE
                        mfield02= inv_n
                        mfield03= cust_n
                        mfield04= cust_m
                        mfield05= cust_ad
                        mfield06= cust_ct
                        mfield07= cust_ac
                        mfield08= cust_s
                        mfield11= cust_pc
                        @ 5, 18 SAY mfield02 PICTURE '@!'
                        @ 6, 18 SAY mfield03 PICTURE '@!'
                        @ 4, 29 SAY mfield04 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                        @ 5, 29 SAY mfield05 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                        @ 6, 29 SAY mfield06 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                        @ 7, 29 SAY mfield07 PICTURE '@!'
                        @ 7, 18 SAY mfield08 PICTURE '@!'
                        @ 6, 64 SAY mfield11 PICTURE '@!'
                    ENDIF
                ENDIF
                SELECT 3
            ENDIF
            DO WHILE .T.
                @ 06,18 &ACTION mFIELD03 PICT '@!'
                IF action='GET'
                    READ
                    IF READKEY()=4.or.READKEY()=261
                        EXIT
                    ENDIF
                    subkey= mfield03
                    IF LEN(TRIM(mfield02))=0
                        SELECT 6
                        DO VALID2
                        IF EOF()
                            IF confirm='N'
                                LOOP
                            ELSE
                                @ 4, 29 SAY mfield04 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                                @ 5, 29 SAY mfield05 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                                @ 6, 29 SAY mfield06 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                                READ
                            ENDIF
                        ELSE
                            mfield03= cust_n
                            mfield04= cust_m
                            mfield05= cust_ad
                            mfield06= cust_ct
                            mfield07= cust_ac
                            mfield08= cust_s
                            mfield11= cust_pc
                            @ 5, 18 SAY mfield02 PICTURE '@!'
                            @ 6, 18 SAY mfield03 PICTURE '@!'
                            @ 4, 29 SAY mfield04 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                            @ 5, 29 SAY mfield05 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                            @ 6, 29 SAY mfield06 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                            @ 7, 29 SAY mfield07 PICTURE '@!'
                            @ 7, 18 SAY mfield08 PICTURE '@!'
                            @ 6, 64 SAY mfield11 PICTURE '@!'
                            IF READKEY()=4.or.READKEY()=261
                                LOOP
                            ENDIF
                        ENDIF
                        SELECT 3
                    ENDIF
                ELSE
                    IF mfield02<>SPACE(10)
                        @ 6, 18 SAY mfield03 PICTURE '@!'
                        @ 4, 29 SAY mfield04 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                        @ 5, 29 SAY mfield05 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                        @ 6, 29 SAY mfield06 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                        @ 7, 18 SAY mfield07 PICTURE '@!'
                    ENDIF
                    &C_CLEAR
                    @ 7, 29 SAY SPACE(20)
                    @ 7, 66 SAY SPACE(12)
                    &C_GET
                ENDIF
                @ 07,18 &ACTION mFIELD08 PICT '@!'
                @ 04,64 &ACTION mFIELD09 PICT '99/99/9999'
                @ 05,64 &ACTION mFIELD10 PICT '@S14 !!!!!!!!!!!!!!!!!!!!'
                @ 06,64 &ACTION mFIELD11 PICT '@!'
                @ 1, 69 SAY mfield19 PICTURE '@!'
                IF action='GET'
                    READ
                    IF READKEY()=4.or.READKEY()=261
                        LOOP
                    ENDIF
                ENDIF
                IF action='GET'
                    DO WHILE mfield11<'A'.or.mfield11>'E'
                        @ 6, 64 GET mfield11 PICTURE '@!'
                        READ
                    ENDDO
                ENDIF
                EXIT
            ENDDO
            IF READKEY()=4.or.READKEY()=261
                LOOP
            ENDIF
            EXIT
        ENDDO
        IF READKEY()=4.or.READKEY()=261
            LOOP
        ENDIF
        lkey= mtrans_c+ srfyl->inv_n
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
            DO WHILE  stkrec->trans_c+ stkrec->trans_n=lkey
                SELECT 1
                APPEND BLANK
                REPLACE trans_c WITH  stkrec->trans_c, trans_n WITH  stkrec->trans_n, trans_d WITH  stkrec->trans_d, cust_n WITH  stkrec->cust_n, cust_s WITH  stkrec->cust_s
                REPLACE stk_n WITH  stkrec->stk_n, stk_m WITH  stkrec->stk_m, stk_pc WITH  stkrec->stk_pc, stk_ac WITH  stkrec->stk_ac, qty_s WITH  stkrec->qty_s, qty1 WITH  stkrec->qty1
                REPLACE qty2 WITH  stkrec->qty2, qty3 WITH  stkrec->qty3, qty1l WITH  stkrec->qty1l, stk_dv WITH  stkrec->stk_dv, stk_cat WITH  stkrec->stk_cat, issue_d WITH  stkrec->issue_d
                REPLACE issue_q WITH  stkrec->issue_q, issue_fg WITH  stkrec->issue_fg, issue_u WITH  stkrec->issue_u, issue_p WITH  stkrec->issue_p
                REPLACE dcount1 WITH  stkrec->dcount1, dcount2 WITH  stkrec->dcount2, dcount3 WITH  stkrec->dcount3, t_prys WITH  stkrec->t_prys, t_ac WITH  stkrec->t_ac, t_pc WITH  stkrec->t_pc
                REPLACE lot_n WITH  stkrec->lot_n, expiry_d WITH  stkrec->expiry_d, user_m WITH  stkrec->user_m
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
                    mexpiry_d= CTOD('  /  /    ')
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
                        DO VALID2
                        IF EOF()
                            IF confirm='N'
                                SELECT 1
                                LOOP
                            ELSE
                                @ ROW,24 &ACTION mISSUE_U PICT '@!'
                                @ ROW,29 &ACTION mSTK_M   PICT '@!'
                                READ
                            ENDIF
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
                            price= 'PRYS_'+mfield11
                            mISSUE_P  = &PRICE
                            mlot_n= lot_n
                            mexpiry_d= expiry_d
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
                    @ ROW,16 &ACTION mISSUE_Q PICT '#####'
                    @ ROW,22 &ACTION mISSUE_FG PICT '###'
                    @ row, 26 SAY missue_u PICTURE '@!'
                    @ row, 31 SAY mstk_m PICTURE '@S18'
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
                        mt_prys= (missue_q+missue_fg)*mt_prys
                        mt_ac= (missue_q+missue_fg)*mstk_ac
                        mt_pc= (missue_q+missue_fg)*mstk_pc
                    ENDIF
                    &C_GET
                    @ row, 69 SAY mt_prys PICTURE '###,###.##'
                ENDIF
                IF action='GET'
                    IF EOF()
                        APPEND BLANK
                    ENDIF
                    REPLACE trans_c WITH mtrans_c, trans_n WITH mfield01, trans_d WITH DATE(), cust_n WITH mfield03, cust_s WITH mfield08
                    REPLACE stk_n WITH mstk_n, stk_m WITH mstk_m, stk_pc WITH mstk_pc, stk_ac WITH mstk_ac, qty_s WITH mqty_s, qty1 WITH mqty1, qty2 WITH mqty2, qty3 WITH mqty3, qty1l WITH mqty1l
                    REPLACE stk_dv WITH mstk_dv, stk_cat WITH mstk_cat, issue_d WITH mfield09
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
                SUM FOR stk_n<>'REMOVE' t_ac, t_pc, t_prys TO mfield12, mfield13, mfield14
            ENDIF
            &C_HEAD
            @ 19, 1 SAY SPACE(78)
            @ 19, 55 SAY 'TOTAL'
            @ 19, 67 SAY mfield14 PICTURE '#,###,###.##'
            @ 20, 1 SAY SPACE(78)
            @ 20, 5 SAY 'DISCOUNT   %,   %,   %'
            &C_GET
            @ 20,15 &ACTION mFIELD15 PICT '##'
            @ 20,20 &ACTION mFIELD16 PICT '##'
            @ 20,25 &ACTION mFIELD17 PICT '##'
            IF action='GET'
                READ
                mfield18= mfield14
                mfield18= mfield18-(mfield18*mfield15/100)
                mfield18= mfield18-(mfield18*mfield16/100)
                mfield18= mfield18-(mfield18*mfield17/100)
            ENDIF
            &C_HEAD
            @ 20, 50 SAY 'NET AMOUNT'
            @ 20, 67 SAY mfield18 PICTURE '#,###,###.##'
            SELECT 3
            DO WHILE .T.
                DO OPTION4
                IF (status='P'.or.status='C').and.choice$'EDS'
                    &C_CLEAR
                    @ 21, 0
                    @ 22, 0
                    @ 23, 0
                    &C_MESSAGE
                    @ 23, 21 SAY ' Sales Return has already been posted. '
                    ?? CHR(7)
                    confirm= ' '
                    &C_GET
                    @ 21, 25 SAY ' Press any key to continue. ' GET confirm PICTURE '@!'
                    READ
                    &C_CLEAR
                    @ 22, 0
                    @ 23, 0
                ELSE
                    EXIT
                ENDIF
            ENDDO
            IF choice='P'
                DO WHILE choice='P'
                    &C_CLEAR
                    @ 23, 0
                    &C_MESSAGE
                    @ 23, 50 SAY ' Loading Program ... '
                    DO SRFPRN
                    SELECT 3
                    DO WHILE choice='P'
                        DO OPTION4
                        IF (status='P'.or.status='C').and.choice$'EDS'
                            &C_CLEAR
                            @ 21, 0
                            @ 22, 0
                            @ 23, 0
                            &C_MESSAGE
                            @ 23, 21 SAY ' Sales Return has already been posted. '
                            ?? CHR(7)
                            confirm= ' '
                            &C_GET
                            @ 21, 25 SAY ' Press any key to continue. ' GET confirm PICTURE '@!'
                            READ
                            &C_CLEAR
                            @ 22, 0
                            @ 23, 0
                            LOOP
                        ENDIF
                    ENDDO
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
            DO WHILE  stkrec->trans_c+ stkrec->trans_n=lkey
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
                    IF EOF().or.trans_n<> srfyl->inv_n
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
            REPLACE inv_n WITH mfield01, rinv_n WITH mfield02, cust_n WITH mfield03, cust_m WITH mfield04, cust_ad WITH mfield05, cust_ct WITH mfield06, cust_ac WITH mfield07, cust_s WITH mfield08
            REPLACE inv_d WITH mfield09, si_rem WITH mfield10, cust_pc WITH mfield11
            REPLACE inv_c WITH mfield12, inv_pc WITH mfield13, inv_a WITH mfield14, dcount1 WITH mfield15, dcount2 WITH mfield16, dcount3 WITH mfield17, net_a WITH mfield18, user_m WITH muser
            REPLACE inv_bal WITH net_a-inv_adj-inv_pay
            IF inv_bal=0
                REPLACE paid WITH 'T'
            ELSE
                REPLACE paid WITH 'F'
            ENDIF
            UNLOCK
            FLUSH
    ENDCASE
    SELECT 1
    ZAP
ENDDO
SET CENTURY OFF
CLOSE DATABASE
RETURN
 

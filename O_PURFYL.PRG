* program.....: O_PurFyl.prg
*             : old purchases

SET CENTURY ON

SELECT 4
USE STKFYL INDEX STK_N

SELECT 3
USE O_PURFYL INDEX OP_PUR_N, OP_PUR_D

SELECT 2
USE O_STKREC INDEX O_CN, O_TID, O_SID
COPY STRU TO &mTEMPFYL

SELECT 1
USE &mTEMPFYL ALIA TEMP EXCL

mtrans_c= 'P'
choice= 'A'

DO WHILE choice$'A'
    DO BRDR1
    &C_BODY
    @ 4, 2 SAY 'Invoice No.   :'
    @ 5, 2 SAY 'Supplier Code :'
    @ 6, 2 SAY 'Address       :'
    @ 7, 2 SAY 'City          :'
    @ 4, 51 SAY 'Date       :'
    @ 5, 51 SAY 'Type/Terms :'
    @ 6, 51 SAY 'Remarks    :'
    @ 7, 51 SAY 'To Bodega  :'
    &C_HEAD
    @ 8, 1 SAY SPACE(78)
    @ 8, 5 SAY 'STOCK CODE   QTY.  F-GDS UNIT CAT-PRICE   DISCOUNT  UNIT-COST      TOTAL'
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
            mfield02= splyr_n
            mfield03= splyr_m
            mfield04= splyr_ad
            mfield05= splyr_ct
            mfield06= inv_d
            mfield07= splyr_tp
            mfield08= splyr_t
            mfield09= trans_to
            mfield10= inv_rem
            mfield11= inv_a
            mfield12= dcount1
            mfield13= dcount2
            mfield14= dcount3
            mfield15= net_a
            mfield16= user_m
        ENDIF
        IF choice='F'
            choice= 'E'
            mfield01= key
            mfield02= SPACE(10)
            mfield03= SPACE(30)
            mfield04= SPACE(30)
            mfield05= SPACE(30)
            mfield06= DATE()
            mfield07= SPACE(10)
            mfield08= 0
            mfield09= '1'
            mfield10= SPACE(20)
            mfield11= 0
            mfield12= 0
            mfield13= 0
            mfield14= 0
            mfield15= 0
            mfield16= muser
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
                SELECT 5
                USE SPLYRFYL INDEX SPLYR_N
                DO VALID1
                IF EOF()
                    LOOP
                ELSE
                    mfield02= splyr_n
                    mfield03= splyr_m
                    mfield04= splyr_ad
                    mfield05= splyr_ct
                    mfield07= splyr_tp
                    mfield08= splyr_t
                    @ 5, 18 SAY mfield02 PICTURE '@!'
                    @ 5, 29 SAY mfield03 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                    @ 6, 29 SAY mfield04 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                    @ 7, 29 SAY mfield05 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                    @ 5, 64 SAY mfield07 PICTURE '@!'
                    @ 5, 75 SAY mfield08 PICTURE '###'
                    @ 7, 66 SAY splyr_cl-splyr_bal PICTURE '#,###,###.##'
                ENDIF
                USE
                SELECT 3
            ENDIF
            @ 5, 18 SAY mfield02 PICTURE '@!'
            @ 5, 29 SAY mfield03 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
            @ 6, 29 SAY mfield04 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
            @ 7, 29 SAY mfield05 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
            @ 04,64 &ACTION mFIELD06
            @ 05,64 &ACTION mFIELD07 PICT '@!'
            @ 05,75 &ACTION mFIELD08 PICT '###'
            @ 06,64 &ACTION mFIELD10 PICT '@S14 !!!!!!!!!!!!!!!!!!!!'
            @ 07,64 &ACTION mFIELD09 PICT '@!'
            @ 1, 69 SAY mfield16 PICTURE '@!'
            IF action='GET'
                READ
                IF READKEY()=4.or.READKEY()=261
                    LOOP
                ENDIF
            ENDIF
            IF action='GET'
                DO WHILE mfield09<'1'.or.mfield09>'3'
                    &C_CLEAR
                    @ 22, 0
                    ?? CHR(7)
                    confirm= ' '
                    &C_MESSAGE
                    @ 22, 29 SAY ' No such bodega code. '
                    @ 7, 64 GET mfield09 PICTURE '@!'
                    READ
                    &C_CLEAR
                    @ 22, 0
                ENDDO
            ENDIF
            EXIT
        ENDDO
        IF READKEY()=4.or.READKEY()=261
            LOOP
        ENDIF
        lkey= mtrans_c+ o_purfyl->inv_n
        bodga_to= 'QTY'+mfield09
        bodga_d= 'QTY'+trans_to
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
            DO WHILE  o_stkrec->trans_c+ o_stkrec->trans_n=lkey
                SELECT 1
                APPEND BLANK
                REPLACE trans_c WITH  o_stkrec->trans_c, trans_n WITH  o_stkrec->trans_n, trans_d WITH  o_stkrec->trans_d, cust_n WITH  o_stkrec->cust_n, cust_s WITH  o_stkrec->cust_s
                REPLACE stk_n WITH  o_stkrec->stk_n, stk_m WITH  o_stkrec->stk_m, stk_pc WITH  o_stkrec->stk_pc, stk_ac WITH  o_stkrec->stk_ac, qty_s WITH  o_stkrec->qty_s, qty1 WITH  o_stkrec->qty1
                REPLACE qty2 WITH  o_stkrec->qty2, qty3 WITH  o_stkrec->qty3, qty1l WITH  o_stkrec->qty1l, stk_dv WITH  o_stkrec->stk_dv, stk_cat WITH  o_stkrec->stk_cat, issue_d WITH  o_stkrec->issue_d
                REPLACE issue_q WITH  o_stkrec->issue_q, issue_fg WITH  o_stkrec->issue_fg, issue_u WITH  o_stkrec->issue_u, issue_p WITH  o_stkrec->issue_p
                REPLACE issue_cp WITH  o_stkrec->issue_cp, qty_pq WITH  o_stkrec->qty_pq, qty_pu WITH  o_stkrec->qty_pu
                REPLACE dcount1 WITH  o_stkrec->dcount1, dcount2 WITH  o_stkrec->dcount2, dcount3 WITH  o_stkrec->dcount3, t_prys WITH  o_stkrec->t_prys, t_ac WITH  o_stkrec->t_ac, t_pc WITH  o_stkrec->t_pc
                REPLACE lot_n WITH  o_stkrec->lot_n, expiry_d WITH  o_stkrec->expiry_d, user_m WITH  o_stkrec->user_m
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
                    mqty_pq= 0
                    mqty_pu= SPACE(4)
                    mqty1= 0
                    mqty2= 0
                    mqty3= 0
                    mqty1l= SPACE(3)
                    mstk_dv= SPACE(5)
                    mstk_cat= SPACE(5)
                    missue_q= 0
                    missue_fg= 0
                    missue_u= SPACE(4)
                    missue_cp= 0
                    missue_p= 0
                    mdcount1= 0
                    mdcount2= 0
                    mdcount3= 0
                    mt_prys= 0
                    mt_ac= 0
                    mlot_n= SPACE(15)
                    mexpiry_d= CTOD('  /  /    ')
                    muser_m= muser
                ELSE
                    mstk_n= stk_n
                    mstk_m= stk_m
                    mstk_pc= stk_pc
                    mstk_ac= stk_ac
                    mqty_s= qty_s
                    mqty_pq= qty_pq
                    mqty_pu= qty_pu
                    mqty1= qty1
                    mqty2= qty2
                    mqty3= qty3
                    mqty1l= qty1l
                    mstk_dv= stk_dv
                    mstk_cat= stk_cat
                    missue_q= issue_q
                    missue_fg= issue_fg
                    missue_u= issue_u
                    missue_cp= issue_cp
                    missue_p= issue_p
                    mdcount1= dcount1
                    mdcount2= dcount2
                    mdcount3= dcount3
                    mt_prys= t_prys
                    mt_ac= t_ac
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
                            mqty_pq= qty_pq
                            mqty_pu= qty_pu
                            mqty1= qty1
                            mqty2= qty2
                            mqty3= qty3
                            mqty1l= qty1l
                            mstk_dv= stk_dv
                            mstk_cat= stk_cat
                            missue_u= qty_pu
                            missue_cp= stk_cp
                            missue_p= stk_pc*qty_pq
                            mlot_n= lot_n
                            mexpiry_d= expiry_d
                            &C_HEAD
                            @ 19, 1 SAY SPACE(78)
                            @ 20, 1 SAY SPACE(78)
                            @ 19, 2 SAY 'Lot #:           Expiry:           Pkg.:    /     On Hand:'
                            @ 20, 2 SAY 'Rmark:                             Size:            Desk.:'
                            @ 19, 60 SAY qty1 PICTURE '###,###'
                            @ 19, 68 SAY qty_u PICTURE '@!'
                            @ 20, 8 SAY stk_rem PICTURE '@S28'
                            @ 20, 42 SAY qty_s PICTURE '@!'
                            @ 20, 60 SAY stk_m PICTURE '@S18'
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
                    @ ROW,16 &ACTION mISSUE_Q  PICT '###,###'
                    @ ROW,24 &ACTION mISSUE_FG PICT '#,###'
                    @ row, 30 SAY missue_u PICTURE '@!'
                    @ ROW,35 &ACTION mISSUE_CP PICT '##,###.##'
                    @ ROW,45 &ACTION mDCOUNT1  PICT '###'
                    @ ROW,49 &ACTION mDCOUNT2  PICT '##.#'
                    @ ROW,54 &ACTION mDCOUNT3  PICT '##'
                    @ row, 57 SAY missue_p PICTURE '##,###.##'
                    @  19,08 &ACTION mLOT_N PICT '@S10 !!!!!!!!!!!!!!!'
                    @  19,26 &ACTION mEXPIRY_D PICT "99/99/9999"
                    @  19,42 &ACTION mQTY_PQ PICT '####'
                    @  19,47 &ACTION mQTY_PU PICT '@!'
                    IF action='GET'
                        READ
                        &C_BRDR
                        @ 20, 1 TO 20, 78 DOUBLE
                        &C_CLEAR
                        @ 19, 1 SAY SPACE(78)
                        missue_p= missue_cp
                        missue_p= missue_p-(missue_p*mdcount1/100)
                        missue_p= missue_p-(missue_p*mdcount2/100)
                        missue_p= missue_p-(missue_p*mdcount3/100)
                        IF missue_q<>0.or.missue_fg<>0
                            missue_p= (missue_p*missue_q)/(missue_q+missue_fg)
                        ENDIF
                        mt_prys= (missue_q+missue_fg)*missue_p
                    ENDIF
                    &C_GET
                    @ row, 57 SAY missue_p PICTURE '##,###.##'
                    @ row, 67 SAY mt_prys PICTURE '#,###,###.##'
                ENDIF
                IF action='GET'
                    IF EOF()
                        APPEND BLANK
                    ENDIF
                    REPLACE trans_c WITH mtrans_c, trans_n WITH mfield01, trans_d WITH DATE(), cust_n WITH mfield02
                    REPLACE stk_n WITH mstk_n, stk_m WITH mstk_m, stk_pc WITH mstk_pc, stk_ac WITH mstk_ac, qty_s WITH mqty_s, qty_pq WITH mqty_pq, qty_pu WITH mqty_pu, stk_dv WITH mstk_dv, stk_cat WITH mstk_cat
                    REPLACE qty1 WITH mqty1, qty2 WITH mqty2, qty3 WITH mqty3, qty1l WITH mqty1l, lot_n WITH mlot_n, expiry_d WITH mexpiry_d
                    REPLACE issue_q WITH missue_q, issue_fg WITH missue_fg, issue_u WITH missue_u, issue_cp WITH missue_cp, issue_p WITH missue_p, dcount1 WITH mdcount1, dcount2 WITH mdcount2, dcount3 WITH mdcount3, issue_d WITH mfield06
                    REPLACE t_prys WITH mt_prys, user_m WITH muser_m
                ENDIF
                SKIP
                row= row+1
                IF row=19.and.action='GET'
                    pg= pg+1
                    row= 9
                    &C_BRDR
                    @ 20, 1 TO 20, 78 DOUBLE
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
                SUM FOR stk_n<>'REMOVE' t_prys TO mfield11
            ENDIF
            &C_BRDR
            @ 20, 1 TO 20, 78 DOUBLE
            &C_HEAD
            @ 19, 1 SAY SPACE(78)
            @ 19, 55 SAY 'TOTAL'
            @ 19, 67 SAY mfield11 PICTURE '#,###,###.##'
            mfield15= mfield11
            SELECT 3
            DO OPTION1
            IF READKEY()=6.or.READKEY()=7
                SELECT 1
                DO PAGEKEY
                LOOP
            ENDIF
            EXIT
        ENDDO
    ENDDO
    DO CASE
        CASE choice='D'.and..not. new
            SELECT 2
            SEEK lkey
            DO WHILE  o_stkrec->trans_c+ o_stkrec->trans_n=lkey
                SELECT 4
                SEEK  o_stkrec->stk_n
                IF .not. EOF()
                    REPLACE stk_pc WITH  o_stkrec->stk_pc, stk_ac WITH  o_stkrec->stk_ac
                    REPLACE qty_pq WITH  o_stkrec->qty_pq, qty_pu WITH  o_stkrec->qty_pu, lot_n WITH  o_stkrec->lot_n, expiry_d WITH  o_stkrec->expiry_d
                    REPL &BODGA_D WITH &BODGA_D - (O_STKREC->ISSUE_Q + O_STKREC->ISSUE_FG) * O_STKREC->QTY_PQ
                    UNLOCK
                ENDIF
                SELECT 2
                DELETE
                SKIP
            ENDDO
        CASE choice='S'.or.choice='M'
            SELECT 1
            GOTO TOP
            IF new
                DO WHILE .not. EOF()
                    IF  temp->stk_n<>'REMOVE'
                        SELECT 4
                        SEEK  temp->stk_n
                        IF .not. EOF()
                            mqty_t= qty1+qty2+qty3
                            IF mqty_t<=0.or.stk_ac<=0
                                REPLACE stk_ac WITH  temp->issue_p/ temp->qty_pq
                            ELSE
                                REPLACE stk_ac WITH (stk_ac*mqty_t+ temp->t_prys)/(mqty_t+(( temp->issue_q+ temp->issue_fg)* temp->qty_pq))
                            ENDIF
                            IF stk_cp<> temp->issue_cp
                                REPLACE prys_ch WITH 'Y'
                            ENDIF
                            REPLACE splyr_n WITH mfield02, stk_lt WITH mfield06, stk_pc WITH  temp->issue_p/ temp->qty_pq, stk_cp WITH  temp->issue_cp
                            REPLACE qty_pq WITH  temp->qty_pq, qty_pu WITH  temp->qty_pu, lot_n WITH  temp->lot_n, expiry_d WITH  temp->expiry_d
                            REPLACE stk_rem WITH STR( temp->issue_q,6)+' +'+STR( temp->issue_fg,6)+' LESS'+STR( temp->dcount1,3)+','+STR( temp->dcount2,4,2)+','+STR( temp->dcount3,2)
                            REPL &BODGA_TO WITH &BODGA_TO + (TEMP->ISSUE_Q + TEMP->ISSUE_FG) * TEMP->QTY_PQ
                            UNLOCK
                        ENDIF
                    ENDIF
                    SELECT 1
                    SKIP
                ENDDO
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
                    SELECT 4
                    IF  temp->stk_n<>'REMOVE'.and. temp->stk_n= o_stkrec->stk_n.and. temp->trans_c+ temp->trans_n= o_stkrec->trans_c+ o_stkrec->trans_n
                        SEEK  temp->stk_n
                        IF .not. EOF()
                            mprev_qty=  o_stkrec->qty1+ o_stkrec->qty2+ o_stkrec->qty3
                            IF mprev_qty<=0.or. o_stkrec->stk_ac<=0
                                REPLACE stk_ac WITH  temp->issue_p/ temp->qty_pq
                            ELSE
                                REPLACE stk_ac WITH ( o_stkrec->stk_ac*mprev_qty+ temp->t_prys)/(mprev_qty+(( temp->issue_q+ temp->issue_fg)* temp->qty_pq))
                            ENDIF
                            IF  o_stkrec->issue_cp<> temp->issue_cp
                                REPLACE prys_ch WITH 'Y'
                            ENDIF
                            REPLACE splyr_n WITH mfield02, stk_lt WITH mfield06, stk_pc WITH  temp->issue_p/ temp->qty_pq, stk_cp WITH  temp->issue_cp
                            REPLACE qty_pq WITH  temp->qty_pq, qty_pu WITH  temp->qty_pu, lot_n WITH  temp->lot_n, expiry_d WITH  temp->expiry_d
                            REPLACE stk_rem WITH STR( temp->issue_q,6)+' +'+STR( temp->issue_fg,6)+' LESS'+STR( temp->dcount1,3)+','+STR( temp->dcount2,4,2)+','+STR( temp->dcount3,2)
                            REPL &BODGA_TO WITH &BODGA_TO + (TEMP->ISSUE_Q + TEMP->ISSUE_FG) * TEMP->QTY_PQ           &BODGA_D  WITH &BODGA_D  - (O_STKREC->ISSUE_Q + O_STKREC->ISSUE_FG) * O_STKREC->QTY_PQ
                            UNLOCK
                        ENDIF
                    ELSE
                        IF  temp->stk_n<>'REMOVE'
                            SEEK  temp->stk_n
                            IF .not. EOF()
                                mprev_qty=  o_stkrec->qty1+ o_stkrec->qty2+ o_stkrec->qty3
                                IF mprev_qty<=0.or. o_stkrec->stk_ac<=0
                                    REPLACE stk_ac WITH  temp->issue_p/ temp->qty_pq
                                ELSE
                                    REPLACE stk_ac WITH ( o_stkrec->stk_ac*mprev_qty+ temp->t_prys)/(mprev_qty+(( temp->issue_q+ temp->issue_fg)* temp->qty_pq))
                                ENDIF
                                IF  o_stkrec->issue_cp<> temp->issue_cp
                                    REPLACE prys_ch WITH 'Y'
                                ENDIF
                                REPLACE splyr_n WITH mfield02, stk_lt WITH mfield06, stk_pc WITH  temp->issue_p/ temp->qty_pq, stk_cp WITH  temp->issue_cp
                                REPLACE qty_pq WITH  temp->qty_pq, qty_pu WITH  temp->qty_pu, lot_n WITH  temp->lot_n, expiry_d WITH  temp->expiry_d
                                REPLACE stk_rem WITH STR( temp->issue_q,6)+' +'+STR( temp->issue_fg,6)+' LESS'+STR( temp->dcount1,3)+','+STR( temp->dcount2,4,2)+','+STR( temp->dcount3,2)
                                REPL &BODGA_TO WITH &BODGA_TO + (TEMP->ISSUE_Q + TEMP->ISSUE_FG) * TEMP->QTY_PQ
                                UNLOCK
                            ENDIF
                        ENDIF
                        IF  temp->trans_n= o_stkrec->trans_n
                            SEEK  o_stkrec->stk_n
                            IF .not. EOF()
                                REPLACE stk_pc WITH  o_stkrec->stk_pc, stk_ac WITH  o_stkrec->stk_ac
                                REPLACE qty_pq WITH  o_stkrec->qty_pq, qty_pu WITH  o_stkrec->qty_pu, lot_n WITH  o_stkrec->lot_n, expiry_d WITH  o_stkrec->expiry_d
                                REPL &BODGA_D WITH &BODGA_D - (O_STKREC->ISSUE_Q + O_STKREC->ISSUE_FG) * O_STKREC->QTY_PQ
                                UNLOCK
                            ENDIF
                        ENDIF
                    ENDIF
                    SELECT 2
                    IF EOF().or.trans_n<> o_purfyl->inv_n
                        APPEND BLANK
                    ENDIF
                    IF  temp->stk_n='REMOVE'
                        DELETE
                    ELSE
                        IF stk_n<> temp->stk_n.or.issue_q<> temp->issue_q
                            REPLACE qty1 WITH  temp->qty1, qty2 WITH  temp->qty2, qty3 WITH  temp->qty3, trans_d WITH  temp->trans_d
                        ENDIF
                        REPLACE trans_c WITH mtrans_c, trans_n WITH mfield01, cust_n WITH  temp->cust_n
                        REPLACE stk_n WITH  temp->stk_n, stk_m WITH  temp->stk_m, qty1l WITH  temp->qty1l, stk_dv WITH  temp->stk_dv, stk_cat WITH  temp->stk_cat, qty_s WITH  temp->qty_s
                        REPLACE stk_pc WITH  temp->stk_pc, stk_ac WITH  temp->stk_ac, lot_n WITH  temp->lot_n, expiry_d WITH  temp->expiry_d
                        REPLACE issue_d WITH  temp->issue_d, issue_cp WITH  temp->issue_cp, qty_pq WITH  temp->qty_pq, qty_pu WITH  temp->qty_pu
                        REPLACE issue_q WITH  temp->issue_q, issue_fg WITH  temp->issue_fg, issue_u WITH  temp->issue_u, issue_p WITH  temp->issue_p, dcount1 WITH  temp->dcount1, dcount2 WITH  temp->dcount2
                        REPLACE dcount3 WITH  temp->dcount3, t_prys WITH  temp->t_prys, user_m WITH  temp->user_m
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
            REPLACE inv_n WITH mfield01, splyr_n WITH mfield02, splyr_m WITH mfield03, splyr_ad WITH mfield04, splyr_ct WITH mfield05, inv_d WITH mfield06, splyr_tp WITH mfield07, splyr_t WITH mfield08, trans_to WITH mfield09
            REPLACE inv_rem WITH mfield10, inv_a WITH mfield11, dcount1 WITH mfield12, dcount2 WITH mfield13, dcount3 WITH mfield14, net_a WITH mfield15, user_m WITH muser
            UNLOCK
    ENDCASE
    SELECT 1
    ZAP
ENDDO

SET CENTURY OFF
CLOSE DATABASE
RETURN
 

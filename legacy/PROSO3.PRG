
SELECT 5
USE BOFYL INDEX BOFYL
SELECT 4
USE BOREC INDEX BOREC, BO_ID
SELECT 3
USE STKFYL INDEX STK_N
SELECT 2
USE SOREC3 INDEX SOREC3 EXCLUSIVE
SELECT 1
USE SOFYL3 INDEX SOFYL3 EXCLUSIVE
&C_CLEAR
CLEAR
&C_BRDR
@ 0, 0 TO 2, 79
@ 3, 0 TO 20, 79 DOUBLE
&C_HEAD
@ 01,01 SAY &PRG
@ 1, 62 SAY 'USER : '+muser
&C_CHOICE
@ 9, 28 SAY ' PROCESS SALES ORDER '
&C_MESSAGE
@ 15, 19 SAY ' Note :  Do this in the main computer.        '
@ 16, 19 SAY '         Check system date before proceeding. '
&C_BODY
@ 5, 2 SAY ' UPDATING INVENTORY '
@ 6, 2 SAY ' VALIDATES S.O. ENTRY '
confirm= ' '
&C_GET
@ 21, 20 SAY 'Press <C> to Continue, any key to abort.' GET confirm PICTURE '!'
READ
IF confirm<>'C'
    RETURN
ENDIF
&C_CLEAR
@ 21, 0
confirm= ' '
DO WHILE .not. EOF()
    &C_CLEAR
    @ 5, 50 SAY SPACE(28)
    &C_BODY
    @ 5, 50 SAY 'PROCESSING S.O.# '+inv_n
    mswitch= .F.
    lkey= 'S'+inv_n
    SELECT 2
    SEEK lkey
    IF EOF()
        &C_CLEAR
        @ 21, 0
        confirm= ' '
        &C_GET
        @ 21, 20 SAY ' Empty record. Press any key to continue.' GET confirm PICTURE '!'
        READ
        &C_CLEAR
        @ 21, 0
        SELECT 1
        DELETE
        SKIP
        LOOP
    ENDIF
    DO WHILE trans_c+trans_n=lkey
        &C_CLEAR
        @ 6, 50 SAY SPACE(28)
        &C_BODY
        @ 6, 50 SAY 'STOCK CODE      '+stk_n
        SELECT 3
        SEEK  sorec3->stk_n
        DO WHILE .not. RLOCK()
            &C_CLEAR
            @ 21, 0
            confirm= ' '
            &C_GET
            DO WHILE .not. confirm$'Y,N'
                @ 21, 15 SAY ' Record is being use by another user, Retry (Y/N)?' GET confirm PICTURE '!'
                READ
            ENDDO
            IF confirm='Y'
                LOOP
            ELSE
                &C_CLEAR
                @ 21, 0
                SELECT 2
                DELETE
                SKIP
                EXIT
            ENDIF
        ENDDO
        IF confirm='N'
            confirm= ' '
            LOOP
        ENDIF
        IF EOF()
            &C_CLEAR
            @ 21, 0
            confirm= ' '
            &C_GET
            @ 21, 20 SAY ' No such stock code. Press any key to continue.' GET confirm PICTURE '!'
            READ
            &C_CLEAR
            @ 21, 0
            SELECT 2
            DELETE
            SKIP
            LOOP
        ENDIF
        SELECT 2
        REPLACE trans_d WITH DATE(), qty1 WITH  stkfyl->qty1, qty2 WITH  stkfyl->qty2, qty3 WITH  stkfyl->qty3
        SELECT 3
        DO CASE
            CASE qty1>= sorec3->issue_q
                REPLACE qty1 WITH qty1- sorec3->issue_q
                UNLOCK
            CASE qty1<1
                SELECT 4
                APPEND BLANK
                REPLACE trans_c WITH  sorec3->trans_c, trans_n WITH  sorec3->trans_n, trans_d WITH  sorec3->trans_d, cust_n WITH  sorec3->cust_n, cust_s WITH  sorec3->cust_s
                REPLACE stk_n WITH  sorec3->stk_n, stk_m WITH  sorec3->stk_m, stk_pc WITH  sorec3->stk_pc, stk_ac WITH  sorec3->stk_ac
                REPLACE qty1 WITH  sorec3->qty1, qty2 WITH  sorec3->qty2, qty3 WITH  sorec3->qty3
                REPLACE qty1l WITH  sorec3->qty1l, stk_dv WITH  sorec3->stk_dv, stk_cat WITH  sorec3->stk_cat, issue_d WITH  sorec3->issue_d
                REPLACE issue_q WITH  sorec3->issue_q, issue_fg WITH  sorec3->issue_fg, issue_u WITH  sorec3->issue_u, issue_p WITH  sorec3->issue_p, dcount1 WITH  sorec3->dcount1, dcount2 WITH  sorec3->dcount2
                REPLACE dcount3 WITH  sorec3->dcount3, t_prys WITH  sorec3->t_prys, t_ac WITH  sorec3->t_ac, t_pc WITH  sorec3->t_pc, lot_n WITH  sorec3->lot_n, expiry_d WITH  sorec3->expiry_d, user_m WITH  sorec3->user_m
                UNLOCK
                mswitch= .T.
                SELECT 2
                DELETE
            CASE qty1< sorec3->issue_q
                missue_q=  sorec3->issue_q- stkfyl->qty1
                mt_prys=  sorec3->issue_p
                mt_prys= mt_prys-(mt_prys* sorec3->dcount1/100)
                mt_prys= mt_prys-(mt_prys* sorec3->dcount2/100)
                mt_prys= mt_prys-(mt_prys* sorec3->dcount3/100)
                mt_prys= missue_q*mt_prys
                mt_ac= missue_q* sorec3->stk_ac
                mt_pc= missue_q* sorec3->stk_pc
                SELECT 4
                APPEND BLANK
                REPLACE trans_c WITH  sorec3->trans_c, trans_n WITH  sorec3->trans_n, trans_d WITH  sorec3->trans_d, cust_n WITH  sorec3->cust_n, cust_s WITH  sorec3->cust_s
                REPLACE stk_n WITH  sorec3->stk_n, stk_m WITH  sorec3->stk_m, stk_pc WITH  sorec3->stk_pc, stk_ac WITH  sorec3->stk_ac
                REPLACE qty1 WITH  sorec3->qty1, qty2 WITH  sorec3->qty2, qty3 WITH  sorec3->qty3
                REPLACE qty1l WITH  sorec3->qty1l, stk_dv WITH  sorec3->stk_dv, stk_cat WITH  sorec3->stk_cat, issue_d WITH  sorec3->issue_d
                REPLACE issue_q WITH missue_q, issue_fg WITH  sorec3->issue_fg, issue_u WITH  sorec3->issue_u, issue_p WITH  sorec3->issue_p, dcount1 WITH  sorec3->dcount1, dcount2 WITH  sorec3->dcount2
                REPLACE dcount3 WITH  sorec3->dcount3, t_prys WITH mt_prys, t_ac WITH mt_ac, t_pc WITH mt_pc, lot_n WITH  sorec3->lot_n, expiry_d WITH  sorec3->expiry_d, user_m WITH  sorec3->user_m
                UNLOCK
                mswitch= .T.
                SELECT 2
                missue_q=  stkfyl->qty1
                mt_prys= issue_p
                mt_prys= mt_prys-(mt_prys*dcount1/100)
                mt_prys= mt_prys-(mt_prys*dcount2/100)
                mt_prys= mt_prys-(mt_prys*dcount3/100)
                mt_prys= missue_q*mt_prys
                mt_ac= missue_q*stk_ac
                mt_pc= missue_q*stk_pc
                REPLACE issue_q WITH missue_q, t_prys WITH mt_prys, t_ac WITH mt_ac, t_pc WITH mt_pc
                SELECT 3
                REPLACE qty1 WITH 0
                UNLOCK
        ENDCASE
        SELECT 2
        SKIP
    ENDDO
    IF mswitch
        STORE 0.00 TO mt_prys, mt_ac, mt_pc
        SELECT 4
        SEEK lkey
        IF RLOCK()
            UNLOCK
        ENDIF
        DO WHILE trans_c+trans_n=lkey
            mt_prys= mt_prys+t_prys
            mt_ac= mt_ac+t_ac
            mt_pc= mt_pc+t_pc
            SKIP
        ENDDO
        mnet_a= mt_prys
        mnet_a= mnet_a-(mnet_a*dcount1/100)
        mnet_a= mnet_a-(mnet_a*dcount2/100)
        mnet_a= mnet_a-(mnet_a*dcount3/100)
        SELECT 5
        APPEND BLANK
        REPLACE inv_n WITH  sofyl3->inv_n, cust_n WITH  sofyl3->cust_n, cust_m WITH  sofyl3->cust_m, cust_ad WITH  sofyl3->cust_ad, cust_ct WITH  sofyl3->cust_ct
        REPLACE ad_n WITH  sofyl3->ad_n, co_m WITH  sofyl3->co_m, co_ad WITH  sofyl3->co_ad, co_ct WITH  sofyl3->co_ct, cust_s WITH  sofyl3->cust_s, inv_d WITH  sofyl3->inv_d
        REPLACE cust_tp WITH  sofyl3->cust_tp, cust_t WITH  sofyl3->cust_t, si_rem WITH  sofyl3->si_rem, cust_pc WITH  sofyl3->cust_pc
        REPLACE dcount1 WITH  sofyl3->dcount1, dcount2 WITH  sofyl3->dcount2, dcount3 WITH  sofyl3->dcount3, user_m WITH  sofyl3->user_m
        REPLACE inv_c WITH mt_ac, inv_pc WITH mt_pc, inv_a WITH mt_prys, net_a WITH mnet_a
        UNLOCK
        mswitch= .F.
    ENDIF
    SELECT 1
    SKIP
ENDDO
CLEAR
@ 2, 2 SAY ' UPDATING SALES INVOICE'
SELECT 1
GOTO TOP
DO WHILE .not. EOF()
    @ 5, 0
    @ 5, 2 SAY 'PROCESSING S.O.# '+inv_n
    lkey= 'S'+inv_n
    STORE 0.00 TO mt_prys, mt_ac, mt_pc
    SELECT 2
    SEEK lkey
    IF EOF()
        &C_CLEAR
        @ 21, 0
        confirm= ' '
        &C_GET
        @ 21, 20 SAY ' Empty record. Press anykey to continue.' GET confirm PICTURE '!'
        READ
        &C_CLEAR
        @ 21, 0
        SELECT 1
        DELETE
        SKIP
        LOOP
    ENDIF
    DO WHILE trans_c+trans_n=lkey
        mt_prys= mt_prys+t_prys
        mt_ac= mt_ac+t_ac
        mt_pc= mt_pc+t_pc
        SKIP
    ENDDO
    SELECT 1
    mnet_a= mt_prys
    mnet_a= mnet_a-(mnet_a*dcount1/100)
    mnet_a= mnet_a-(mnet_a*dcount2/100)
    mnet_a= mnet_a-(mnet_a*dcount3/100)
    REPLACE inv_c WITH mt_ac, inv_pc WITH mt_pc, inv_a WITH mt_prys, net_a WITH mnet_a
    SKIP
ENDDO
CLOSE DATABASE
SELECT 1
USE SIFYL INDEX SI_N, SI_D, SI_CD
APPEND FROM SOFYL3
UNLOCK
SELECT 2
USE STKREC INDEX TRANS_CN, TRANS_ID, SI_ID
APPEND FROM SOREC3
UNLOCK
&C_CLEAR
CLEAR
&C_MESSAGE
@ 23, 50 SAY ' Please Wait ... '
&C_CLEAR
@ 2, 1
COPY FILE SOFYL0.DBF TO SOFYL3.DBF
COPY FILE SOFYL0.IDX TO SOFYL3.IDX
COPY FILE SOREC0.DBF TO SOREC3.DBF
COPY FILE SOREC0.IDX TO SOREC3.IDX
RETURN
 

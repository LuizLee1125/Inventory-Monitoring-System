* program.....: ProBo.prg
*               process back order

SELECT 4
USE BOREC INDEX BOREC, BO_ID EXCLUSIVE
SELECT 3
USE STKFYL INDEX STK_N
SELECT 2
USE BOREC1 INDEX BOREC1 EXCLUSIVE
SELECT 1
USE BOFYL1 INDEX BOFYL1 EXCLUSIVE
&C_CLEAR
CLEAR
&C_BRDR
@ 0, 0 TO 2, 79
@ 3, 0 TO 20, 79 DOUBLE
&C_HEAD
@ 01,01 SAY &PRG
@ 1, 62 SAY 'USER : '+muser
&C_CHOICE
@ 9, 29 SAY ' PROCESS BACK ORDER '
&C_MESSAGE
@ 15, 19 SAY ' Note :  Do this in the main computer.        '
@ 16, 19 SAY '         Check system date before proceeding. '
confirm= ' '
&C_GET
@ 21, 18 SAY ' Press <C> to Continue, any key to abort. ' GET confirm PICTURE '!'
READ
IF confirm<>'C'
    RETURN
ENDIF
&C_CLEAR
@ 21, 0
&C_BODY
@ 5, 2 SAY ' Transferring marked for back order '
@ 6, 2 SAY ' Please, wait... '
ZAP
APPEND FROM BOFYL FOR status='B'
REPLACE ALL status WITH ' '
SELECT 2
ZAP
SELECT 5
USE BOFYL INDEX BOFYL EXCLUSIVE
IF error
    error= .F.
    RETURN
ENDIF
SELECT 2
&C_CLEAR
@ 6, 2 SAY SPACE(28)
SELECT 1
GOTO TOP
IF EOF()
    RETURN
ENDIF
DO WHILE .not. EOF()
    lkey= 'S'+inv_n
    &C_CLEAR
    @ 5, 50 SAY SPACE(28)
    &C_BODY
    @ 5, 50 SAY ' BACK ORDER NO.  '+inv_n
    SELECT 4
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
        &C_BODY
        @ 6, 50 SAY ' STOCK CODE      '+stk_n
        SELECT 2
        APPEND BLANK
        REPLACE trans_c WITH  borec->trans_c, trans_n WITH  borec->trans_n, trans_d WITH  borec->trans_d, cust_n WITH  borec->cust_n, cust_s WITH  borec->cust_s
        REPLACE stk_n WITH  borec->stk_n, stk_m WITH  borec->stk_m, stk_pc WITH  borec->stk_pc, stk_ac WITH  borec->stk_ac
        REPLACE qty1 WITH  borec->qty1, qty2 WITH  borec->qty2, qty3 WITH  borec->qty3
        REPLACE qty1l WITH  borec->qty1l, stk_dv WITH  borec->stk_dv, stk_cat WITH  borec->stk_cat, issue_d WITH  borec->issue_d
        REPLACE issue_q WITH  borec->issue_q, issue_fg WITH  borec->issue_fg, issue_u WITH  borec->issue_u, issue_p WITH  borec->issue_p, dcount1 WITH  borec->dcount1, dcount2 WITH  borec->dcount2
        REPLACE dcount3 WITH  borec->dcount3, t_prys WITH  borec->t_prys, t_ac WITH  borec->t_ac, t_pc WITH  borec->t_pc, lot_n WITH  borec->lot_n, expiry_d WITH  borec->expiry_d, user_m WITH  borec->user_m
        SELECT 4
        DELETE
        SKIP
    ENDDO
    SELECT 1
    SKIP
ENDDO
&C_CLEAR
@ 5, 2 SAY SPACE(76)
@ 6, 50 SAY SPACE(28)
&C_BODY
@ 5, 2 SAY ' Deleting marked for back order '
SELECT 5
DELETE FOR status='B'
SELECT 4
&C_CLEAR
@ 5, 2 SAY SPACE(76)
&C_BODY
@ 5, 2 SAY ' Updating Stock File '
SELECT 1
GOTO TOP
DO WHILE .not. EOF()
    &C_CLEAR
    @ 5, 50 SAY SPACE(28)
    &C_BODY
    @ 5, 50 SAY ' PROCESSING B.O.# '+inv_n
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
        &C_BODY
        @ 6, 50 SAY ' STOCK CODE      '+stk_n
        SELECT 3
        SEEK  borec1->stk_n
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
            CASE qty1>= borec1->issue_q
                REPLACE qty1 WITH qty1- borec1->issue_q
                UNLOCK
            CASE qty1<1
                SELECT 4
                APPEND BLANK
                REPLACE trans_c WITH  borec1->trans_c, trans_n WITH  borec1->trans_n, trans_d WITH  borec1->trans_d, cust_n WITH  borec1->cust_n, cust_s WITH  borec1->cust_s
                REPLACE stk_n WITH  borec1->stk_n, stk_m WITH  borec1->stk_m, stk_pc WITH  borec1->stk_pc, stk_ac WITH  borec1->stk_ac
                REPLACE qty1 WITH  borec1->qty1, qty2 WITH  borec1->qty2, qty3 WITH  borec1->qty3
                REPLACE qty1l WITH  borec1->qty1l, stk_dv WITH  borec1->stk_dv, stk_cat WITH  borec1->stk_cat, issue_d WITH  borec1->issue_d
                REPLACE issue_q WITH  borec1->issue_q, issue_fg WITH  borec1->issue_fg, issue_u WITH  borec1->issue_u, issue_p WITH  borec1->issue_p, dcount1 WITH  borec1->dcount1, dcount2 WITH  borec1->dcount2
                REPLACE dcount3 WITH  borec1->dcount3, t_prys WITH  borec1->t_prys, t_ac WITH  borec1->t_ac, t_pc WITH  borec1->t_pc, lot_n WITH  borec1->lot_n, expiry_d WITH  borec1->expiry_d, user_m WITH  borec1->user_m
                UNLOCK
                mswitch= .T.
                SELECT 2
                DELETE
            CASE qty1< borec1->issue_q
                missue_q=  borec1->issue_q- stkfyl->qty1
                mt_prys=  borec1->issue_p
                mt_prys= mt_prys-(mt_prys* borec1->dcount1/100)
                mt_prys= mt_prys-(mt_prys* borec1->dcount2/100)
                mt_prys= mt_prys-(mt_prys* borec1->dcount3/100)
                mt_prys= missue_q*mt_prys
                mt_ac= missue_q* borec1->stk_ac
                mt_pc= missue_q* borec1->stk_pc
                SELECT 4
                APPEND BLANK
                REPLACE trans_c WITH  borec1->trans_c, trans_n WITH  borec1->trans_n, trans_d WITH  borec1->trans_d, cust_n WITH  borec1->cust_n, cust_s WITH  borec1->cust_s
                REPLACE stk_n WITH  borec1->stk_n, stk_m WITH  borec1->stk_m, stk_pc WITH  borec1->stk_pc, stk_ac WITH  borec1->stk_ac
                REPLACE qty1 WITH  borec1->qty1, qty2 WITH  borec1->qty2, qty3 WITH  borec1->qty3
                REPLACE qty1l WITH  borec1->qty1l, stk_dv WITH  borec1->stk_dv, stk_cat WITH  borec1->stk_cat, issue_d WITH  borec1->issue_d
                REPLACE issue_q WITH missue_q, issue_fg WITH  borec1->issue_fg, issue_u WITH  borec1->issue_u, issue_p WITH  borec1->issue_p, dcount1 WITH  borec1->dcount1, dcount2 WITH  borec1->dcount2
                REPLACE dcount3 WITH  borec1->dcount3, t_prys WITH mt_prys, t_ac WITH mt_ac, t_pc WITH mt_pc, lot_n WITH  borec1->lot_n, expiry_d WITH  borec1->expiry_d, user_m WITH  borec1->user_m
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
        REPLACE inv_n WITH  bofyl1->inv_n, cust_n WITH  bofyl1->cust_n, cust_m WITH  bofyl1->cust_m, cust_ad WITH  bofyl1->cust_ad, cust_ct WITH  bofyl1->cust_ct
        REPLACE ad_n WITH  bofyl1->ad_n, co_m WITH  bofyl1->co_m, co_ad WITH  bofyl1->co_ad, co_ct WITH  bofyl1->co_ct, cust_s WITH  bofyl1->cust_s, inv_d WITH  bofyl1->inv_d
        REPLACE cust_tp WITH  bofyl1->cust_tp, cust_t WITH  bofyl1->cust_t, si_rem WITH  bofyl1->si_rem, cust_pc WITH  bofyl1->cust_pc
        REPLACE dcount1 WITH  bofyl1->dcount1, dcount2 WITH  bofyl1->dcount2, dcount3 WITH  bofyl1->dcount3, user_m WITH  bofyl1->user_m
        REPLACE inv_c WITH mt_ac, inv_pc WITH mt_pc, inv_a WITH mt_prys, net_a WITH mnet_a
        UNLOCK
        mswitch= .F.
    ENDIF
    SELECT 1
    SKIP
ENDDO
&C_CLEAR
@ 5, 2 SAY SPACE(77)
@ 6, 50 SAY SPACE(28)
&C_BODY
@ 5, 2 SAY ' Updating Sales Invoice '
SELECT 1
GOTO TOP
DO WHILE .not. EOF()
    &C_BODY
    @ 5, 50 SAY ' PROCESSING B.O.# '+inv_n
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
APPEND FROM BOFYL1
UNLOCK
SELECT 2
USE STKREC INDEX TRANS_CN, TRANS_ID, SI_ID
APPEND FROM BOREC1
UNLOCK
RETURN
 

* program.....: MnuRbild.prg
*             : rebuilding of indeces individually or whole

SET CENTURY ON
PRIVATE ALL LIKE PRG??
PRIVATE ALL LIKE M_*
prg1a    = 'A] Stock File          '
prg1b    = 'B] Inventory Record    '
prg1c    = 'C] Sales Invoice       '
prg1d    = 'D] Purchase Invoice    '
prg1e    = 'E] Bodega Transfer     '
prg1f    = 'F] Sales Return        '
prg1g    = 'G] Old Files           '
prg1h    = 'H] All of The Above    '
prg2a    = 'N] Customer File       '
prg2b    = 'O] Address File        '
prg2c    = 'P] Supplier File       '
prg2d    = 'Q] Territory File      '
prg2e    = 'R] Accounts File       '
prg2f    = 'S] Collection File     '
prg2g    = 'T] All of The Above    '
prg3a    = '1] Exit                '
prg3b    = '2] Password File       '
m_y_col1 = 8
m_y_col2 = 7
m_y_col3 = 2
m_col1   = 4
m_col2   = 29
m_col3   = 54
m_x      = 1
m_y      = 1
m_col    = m_col1
m_row    = 8
m_x_max  = 3
m_y_max  = m_y_col1

DO WHILE .T.
   &C_CLEAR
   CLEAR
   &C_BRDR
   @ 0, 15 TO 3, 64 DOUBLE
   &C_HEAD
   @ 1, 16 SAY SPACE(48)
   @ 1, 16 SAY SPACE((48-LEN(company))/2)+company
   @ 2, 16 SAY '            REBUILD INDEX FILES MENU            '
   &C_BRDR
   @ 4, 2 TO 23, 78
   @ 6, 3 TO 22, 27
   @ 5, 4 TO 7, 26 DOUBLE
   &C_HEAD
   @ 6, 5 SAY '   INVENTORY FILES   '
   &C_BRDR
   @ 6, 28 TO 22, 52
   @ 5, 29 TO 7, 51 DOUBLE
   &C_HEAD
   @ 6, 30 SAY '  ACCOUNTING FILES   '
   &C_BRDR
   @ 6, 53 TO 22, 77
   @ 5, 54 TO 7, 76 DOUBLE
   &C_HEAD
   @ 6, 55 SAY '     WORK SPACES     '
   &C_OPTION
   @  9,  4 SAY prg1a
   @ 10,  4 SAY prg1b
   @ 11,  4 SAY prg1c
   @ 12,  4 SAY prg1d
   @ 13,  4 SAY prg1e
   @ 14,  4 SAY prg1f
   @ 15,  4 SAY prg1g
   @ 16,  4 SAY prg1h
   @  9, 29 SAY prg2a
   @ 10, 29 SAY prg2b
   @ 11, 29 SAY prg2c
   @ 12, 29 SAY prg2d
   @ 13, 29 SAY prg2e
   @ 14, 29 SAY prg2f
   @ 15, 29 SAY prg2g
   @  9, 54 SAY prg3a
   @ 10, 54 SAY prg3b
   DO MENU3C
   prg= choice
   IF choice<>'PRG3A'
      &C_CLEAR
      CLEAR
      &C_BRDR
      @ 0, 1 TO 2, 78
      @ 3, 1 TO 20, 78 DOUBLE
      &C_HEAD
      @ 01,02 SAY &PRG
      &C_CHOICE
      @ 9, 27 SAY ' ATTEMPT TO RECOVER DATA '
      &C_MESSAGE
      @ 15, 20 SAY ' Note :  This might take a while to finish. '
      @ 16, 20 SAY '         This is use to recover data due to '
      @ 17, 20 SAY '            power interruption.             '
      confirm= ' '
      &C_GET
      @ 21, 20 SAY 'Press <C> to Continue, any key to abort.' GET confirm PICTURE '!'
      READ
      IF confirm<>'C'
         RETURN
      ENDIF
      &C_CLEAR
      CLEAR
      &C_MESSAGE
      @ 23, 50 SAY ' Rebuilding Indexes ... '
      &C_CLEAR
      @ 2, 0
      &C_BODY
      SET EXCLUSIVE ON
   ENDIF
   DO CASE
      CASE choice='PRG1A'
         ? "Stock Master File..."
         set talk on
         USE STKFYL
         PACK
         INDEX ON stk_n TO STK_N
      CASE choice='PRG1B'
         set colo to bg/bg
         @ 8,23 clear to 12,57
         set colo to +g/bg
         @ 8,23 to 12,57
         set colo to +w/bg,+n/w
         store " " to atl
         @ 10,25 say "Remove deleted records (y/n)?" get atl pict "Y"
         read
         set colo to
         clear
         &C_BODY
         ? "Transaction File..."
         set talk on
         use StkRec
         if upper(atl)="Y"
            pack
         endif
         INDEX ON trans_c+trans_n TO TRANS_CN
         *INDEX ON stk_n+SUBSTR(DTOC(trans_d),7,2)+SUBSTR(DTOC(trans_d),1,5) TO TRANS_ID
         *INDEX ON stk_n+SUBSTR(DTOC(issue_d),7,2)+SUBSTR(DTOC(issue_d),1,5) TO SI_ID
         INDEX ON stk_n+STR(YEAR(trans_d),4)+SUBSTR(DTOC(trans_d),1,5)+TAYM TO TRANS_ID
         INDEX ON stk_n+STR(YEAR(issue_d),4)+SUBSTR(DTOC(issue_d),1,5)+TAYM TO SI_ID

      CASE choice='PRG1C'
         ? "Sales Invoice File..."
         set talk on
         USE SIFYL
         * PACK
         INDEX ON inv_n TO SI_N
         INDEX ON inv_d TO SI_D
         INDEX ON str(year(inv_d),4)+SUBSTR(DTOC(inv_d),1,5)+inv_n TO SI_DINV
         *INDEX ON right(dtoc(inv_d),4)+left(dtoc(inv_d),2)+subs(dtoc(inv_d),4,2)+inv_n to si_dinv
         *INDEX ON paid+cust_n+SUBSTR(DTOC(inv_d),7,2)+SUBSTR(DTOC(inv_d),1,5) TO SI_CD
         INDEX ON paid+cust_n+STR(YEAR(inv_d),4)+SUBSTR(DTOC(inv_d),1,5) TO SI_CD
         INDEX ON TRIM(CUST_S)+TRIM(CUST_N)+STR(YEAR(INV_D),4)+SUBSTR(DTOC(INV_D),1,5) TO COLEC_X

      CASE choice='PRG1D'
         ? "Purchase File..."
         set talk on
         USE PURFYL
         * PACK
         INDEX ON inv_n TO PUR_N
         INDEX ON inv_d TO PUR_D

      CASE choice='PRG1E'
         ? "Bodega File..."
         set talk on
         USE BODGAFYL
         * PACK
         INDEX ON inv_n TO BODGA_N

      CASE choice='PRG1F'
         ? "Sales Return File..."
         set talk on
         USE SRFYL
         * PACK
         INDEX ON inv_n TO SR_N
         INDEX ON inv_d TO SR_D
         *INDEX ON paid+cust_n+SUBSTR(DTOC(inv_d),7,2)+SUBSTR(DTOC(inv_d),1,5) TO SR_CD
         INDEX ON paid+cust_n+STR(YEAR(inv_d),4)+SUBSTR(DTOC(inv_d),1,5) TO SR_CD

      CASE choice='PRG1G'
         ? "Old Customer File..."
         set talk on
         use O_Cusfyl
         index on cust_n to o_cust_n
         set talk off
         ? "Old Supplier File..."
         set talk on
         use O_Splyr
         index on splyr_n to o_splyrn
         set talk off
         ? "Old Purchase File..."
         set talk on
         use o_purfyl
         index on inv_d to op_pur_d
         index on inv_n to op_pur_n
         set talk off
         ? "Old Stock File..."
         set talk on
         use o_stkfyl
         index on stk_n to o_stk_n
         set talk off
         ? "Old Sales Invoice File..."
         set talk on
         use o_sifyl
         index on inv_d to os_si_d
         index on inv_n to os_si_n
         index on paid+cust_n+str(year(inv_d),4)+subst(dtoc(inv_d),1,5) to os_si_cd
         set talk off
         ? "Old SR File..."
         set talk on
         USE O_SRFYL
         INDEX ON inv_n TO O_SR_N
         INDEX ON inv_d TO O_SR_D
         INDEX ON paid+cust_n+STR(YEAR(inv_d),4)+SUBSTR(DTOC(inv_d),1,5) TO O_SR_CD
         set talk off
         ? "Old Transaction File..."
         set talk on
         use O_stkrec
         index on stk_n+str(year(trans_d),4)+subst(dtoc(trans_d),1,5) to o_tid
         index on stk_n+str(year(issue_d),4)+subst(dtoc(issue_d),1,5) to o_sid
         index on trans_c+trans_n to o_cn

      CASE choice='PRG1H'
         ? "Stock Master File...."
         set talk on
         USE STKFYL
         PACK
         INDEX ON stk_n TO STK_N
         set talk off
         save screen to atlscrn
         set colo to bg/bg
         @ 8,13 clear to 12,67
         set colo to +g/bg
         @ 8,13 to 12,67
         set colo to +w/bg,+n/w
         store " " to atl
         @ 10,15 say "Remove deleted records in Transaction File (y/n)?" get atl pict "Y"
         read
         set colo to
         clear
         &C_BODY
         restore screen from atlscrn
         @ 5,0 say ""
         ? "Transaction File..."
         set talk on
         use StkRec
         if upper(atl)="Y"
            pack
         endif
         INDEX ON trans_c+trans_n TO TRANS_CN
         *INDEX ON stk_n+SUBSTR(DTOC(trans_d),7,2)+SUBSTR(DTOC(trans_d),1,5) TO TRANS_ID
         *INDEX ON stk_n+SUBSTR(DTOC(issue_d),7,2)+SUBSTR(DTOC(issue_d),1,5) TO SI_ID
         INDEX ON stk_n+STR(YEAR(trans_d),4)+SUBSTR(DTOC(trans_d),1,5)+TAYM TO TRANS_ID
         INDEX ON stk_n+STR(YEAR(issue_d),4)+SUBSTR(DTOC(issue_d),1,5)+TAYM TO SI_ID

         set talk off
         ? "Sales Invoice File..."
         set talk on
         USE SIFYL
         * PACK
         INDEX ON inv_n TO SI_N
         INDEX ON inv_d TO SI_D
         INDEX ON str(year(inv_d),4)+SUBSTR(DTOC(inv_d),1,5)+inv_n TO SI_DINV
         *INDEX ON right(dtoc(inv_d),4)+left(dtoc(inv_d),2)+subs(dtoc(inv_d),4,2)+inv_n to si_dinv
         *INDEX ON paid+cust_n+SUBSTR(DTOC(inv_d),7,2)+SUBSTR(DTOC(inv_d),1,5) TO SI_CD
         INDEX ON paid+cust_n+STR(YEAR(inv_d),4)+SUBSTR(DTOC(inv_d),1,5) TO SI_CD

         set talk off
         ? "Purchase File..."
         set talk on
         USE PURFYL
         * PACK
         INDEX ON inv_n TO PUR_N
         INDEX ON inv_d TO PUR_D
         set talk off
         ? "Bodega File..."
         set talk on
         USE BODGAFYL
         * PACK
         INDEX ON inv_n TO BODGA_N
         set talk off
         ? "Sales Return File..."
         set talk on
         USE SRFYL
         * PACK
         INDEX ON inv_n TO SR_N
         INDEX ON inv_d TO SR_D
         *INDEX ON paid+cust_n+SUBSTR(DTOC(inv_d),7,2)+SUBSTR(DTOC(inv_d),1,5) TO SR_CD
         INDEX ON paid+cust_n+STR(YEAR(inv_d),4)+SUBSTR(DTOC(inv_d),1,5) TO SR_CD

      CASE choice='PRG2A'
         set talk on
         USE CUSTFYL
         PACK
         INDEX ON cust_n TO CUST_N

      CASE choice='PRG2B'
         set talk on
         USE ADFYL
         PACK
         INDEX ON ad_n TO AD_N

      CASE choice='PRG2C'
         set talk on
         USE SPLYRFYL
         PACK
         INDEX ON splyr_n TO SPLYR_N

      CASE choice='PRG2D'
         set talk on
         USE SMANFYL
         PACK
         INDEX ON sman_n TO SMAN_N

      CASE choice='PRG2E'
         set talk on
         USE ACCTFYL
         PACK
         INDEX ON acct_n TO ACCT_N

      CASE choice='PRG2F'
         set talk on
         USE COLECFYL
         * PACK
         INDEX ON colec_n TO OR_N
         *INDEX ON paid+cust_n+SUBSTR(DTOC(colec_d),7,2)+SUBSTR(DTOC(colec_d),1,5) TO OR_CD
         INDEX ON paid+cust_n+STR(YEAR(colec_d),4)+SUBSTR(DTOC(colec_d),1,5) TO OR_CD
         USE COLECREC
         * PACK
         INDEX ON colec_n TO COLEC_N
         INDEX ON colec_d TO COLEC_D
         INDEX ON inv_n TO CSI_N
         INDEX ON chk_dd TO CHK_DD

      CASE choice='PRG2G'
         ? "Customer File..."
         set talk on
         USE CUSTFYL
         PACK
         INDEX ON cust_n TO CUST_N
         set talk off
         ? "Address File..."
         set talk on
         USE ADFYL
         PACK
         INDEX ON ad_n TO AD_N
         set talk off
         ? "Supplier File..."
         set talk on
         USE SPLYRFYL
         PACK
         INDEX ON splyr_n TO SPLYR_N
         set talk off
         ? "Territory File..."
         set talk on
         USE SMANFYL
         PACK
         INDEX ON sman_n TO SMAN_N
         set talk off
         ? "Accounts File..."
         set talk on
         USE ACCTFYL
         PACK
         INDEX ON acct_n TO ACCT_N
         set talk off
         ? "Collection File..."
         set talk on
         USE COLECFYL
         * PACK
         INDEX ON colec_n TO OR_N
         *INDEX ON paid+cust_n+SUBSTR(DTOC(colec_d),7,2)+SUBSTR(DTOC(colec_d),1,5) TO OR_CD
         INDEX ON paid+cust_n+STR(YEAR(colec_d),4)+SUBSTR(DTOC(colec_d),1,5) TO OR_CD
         USE COLECREC
         * PACK
         INDEX ON colec_n TO COLEC_N
         INDEX ON colec_d TO COLEC_D
         INDEX ON inv_n TO CSI_N
         INDEX ON chk_dd TO CHK_DD

      CASE choice='PRG3A'
         CLOSE DATABASE
         SELECT 1
         SET TALK OFF
         SET EXCLUSIVE OFF
         SET CENT OFF
         RETURN

      CASE choice='PRG3B'
         USE PASSFYL
         PACK
         INDEX ON access_c+user_m TO ACCESS_C

   ENDCASE
   SET TALK OFF
   SET EXCLUSIVE OFF
   CLOSE DATABASE
   SELECT 1
ENDDO

SET CENT OFF
RETURN

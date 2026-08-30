* program.....: SiFyl3.Prg
* module......: revision of codes for sales invoice; for discounts only
* modified....: 02/26/05
                       

*SELECT 6
*   USE ADFYL INDEX AD_N
SELECT 5
   USE CUSTFYL INDEX CUST_N
SELECT 4
   USE STKFYL INDEX STK_N
SELECT 3
   USE SIFYL INDEX SI_N, SI_D, SI_CD, SI_DINV
SELECT 2
   USE STKREC INDEX TRANS_CN, TRANS_ID, SI_ID
   COPY STRU TO &mTEMPFYL
SELECT 1
   USE &mTEMPFYL ALIA TEMP EXCL

mtrans_c= 'S'
choice= 'S'
printed= .F.

DO WHILE choice$'SDA'
   DO BRDR1
   &C_BODY
   @ 4, 2 SAY 'Invoice No.   :'
   @ 5, 2 SAY 'Customer Code :'
   @ 6, 2 SAY 'Address Code  :'
   @ 7, 2 SAY 'Territory     :'
   @ 4, 51 SAY 'Date       :'
   @ 5, 51 SAY 'Type/Terms :'
   @ 6, 51 SAY 'Remarks    :'
   @ 7, 51 SAY 'Price Cat. :'
   &C_HEAD
   @ 8, 1 SAY SPACE(78)
   @ 8, 5 SAY 'STOCK CODE   QTY. UNIT DESCRIPTION            PRICE   DISCOUNT     TOTAL'
   SELECT 3
   DO CASE
      CASE MUSER='ALONA'
           mfield01='A'+RIGHT(STR(YEAR(DATE()),4),2)+LEFT(DTOC(DATE()),2)+'-    '
      CASE MUSER='NELIA'
           mfield01='N'+RIGHT(STR(YEAR(DATE()),4),2)+LEFT(DTOC(DATE()),2)+'-    '
      CASE MUSER='BILLY'
           mfield01='B'+RIGHT(STR(YEAR(DATE()),4),2)+LEFT(DTOC(DATE()),2)+'-    '
      OTHERWISE
           mfield01= SPACE(10)
   ENDCASE
   choice= 'F'
   action= 'GET'
   new= .T.
   sv_net_a=0
   DO WHILE choice$'FEVNTB'
      &C_GET
      IF action='GET'
         key= mfield01
         @ 4, 18 GET key PICTURE '@!'
         READ
         IF LEN(TRIM(key))=0 .OR. LEN(TRIM(KEY))=6
            CLOSE DATA
            RETURN
         ENDIF
         IF choice='F'.or.key<>mfield01
            do mode
           *DO MODE2
            mfield01= key
         ENDIF
      ENDIF
      IF .not. found() .AND. action="GET" .AND. NEW
         save screen to atlscreen
         atlmsg="record not found !!! press any key..."
         atllen=len(atlmsg)
         set colo to rb/rb
         @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
         set colo to +w/rb
         @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
         @ 12,41-atllen/2 say atlmsg
         atlkeypress=inkey(0)
         restore screen from atlscreen
         store space(10) to key, mfield01
         LOOP
      endif
      IF action='SAY'
         mfield01= inv_n
         mfield02= cust_n
         mfield03= cust_m
         mfield04= cust_ad
         mfield05= cust_ct
         mfield06= cust_ac
         mfield07= ad_n
         mfield08= co_m
         mfield09= co_ad
         mfield10= co_ct
         mfield11= cust_s
         mfield12= inv_d
         mfield13= cust_tp
         mfield14= cust_t
         mfield15= si_rem
         mfield16= cust_pc
         mfield17= inv_c
         mfield18= inv_pc
         mfield19= inv_a
         mfield20= dcount1
         mfield21= dcount2
         mfield22= dcount3
         mfield23= net_a
         mfield24= user_m
         sv_net_a=net_a
      ENDIF
      IF choice='F'
         choice= 'N'
         mfield01= key
         mfield02= SPACE(10)
         mfield03= SPACE(30)
         mfield04= SPACE(30)
         mfield05= SPACE(30)
         mfield06= SPACE(10)
         mfield07= SPACE(10)
         mfield08= SPACE(30)
         mfield09= SPACE(30)
         mfield10= SPACE(30)
         mfield11= SPACE(10)
         mfield12= DATE()
         mfield13= SPACE(10)
         mfield14= 0
         mfield15= SPACE(15)
         mfield16= SPACE(1)
         mfield17= 0
         mfield18= 0
         mfield19= 0
         mfield20= 0
         mfield21= 0
         mfield22= 0
         mfield23= 0
         mfield24= muser
      ENDIF
      &C_GET
      @ 4, 18 SAY mfield01 PICTURE '@!'
      DO WHILE .T.
         @ 05,18 SAY mFIELD02 PICT '@!'
         IF action='GET'
            READ
            IF READKEY()=4.or.READKEY()=260
               EXIT
            ENDIF
            subkey= mfield02
            SELECT 5
            DO VALID2
            IF EOF()
               IF confirm='N'
                  LOOP
               ELSE
                  @ 4, 29 GET mfield03 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                  @ 5, 29 GET mfield04 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                  @ 6, 29 GET mfield05 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                  @ 7, 29 GET mfield06 PICTURE '@!'
                  READ
               ENDIF
            ELSE
               mfield02= cust_n
               mfield03= cust_m
               mfield04= cust_ad
               mfield05= cust_ct
               mfield06= cust_ac
               mfield11= cust_s
               mfield13= cust_tp
               mfield14= cust_t
               mfield15= cust_rem
               mfield16= cust_pc
               @ 5, 18 SAY mfield02 PICTURE '@!'
               @ 4, 29 SAY mfield03 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
               @ 5, 29 SAY mfield04 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
               @ 6, 29 SAY mfield05 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
               @ 7, 18 SAY mfield11 PICTURE '@!'
               @ 7, 29 SAY mfield06 PICTURE '@!'
               @ 5, 64 SAY mfield13 PICTURE '@!'
               @ 5, 75 SAY mfield14 PICTURE '###'
               @ 6, 64 SAY mfield15 PICTURE '@S15 !!!!!!!!!!!!!!!!!!!!'
               @ 7, 64 SAY mfield16 PICTURE '@!'
            ENDIF
            SELECT 3
         ENDIF
         DO WHILE .T.
            @ 06,18 &ACTION mFIELD07 PICT '@!'
            IF action='GET'
               READ
               IF READKEY()=4.or.READKEY()=260
                  EXIT
               ENDIF
               subkey= mfield07
               IF LEN(TRIM(subkey))<>0
                        @ 4, 29 GET mfield08 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                        @ 5, 29 GET mfield09 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                        @ 6, 29 GET mfield10 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                        @ 7, 29 GET mfield06 PICTURE '@!'
                        READ
                  SELECT 3
               ENDIF
            ELSE
               @ 5, 18 SAY mfield02 PICTURE '@!'
               @ 4, 29 SAY mfield03 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
               @ 5, 29 SAY mfield04 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
               @ 6, 29 SAY mfield05 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
               @ 7, 29 SAY mfield06 PICTURE '@!'
               IF mfield07<>SPACE(10)
                  @ 6, 18 SAY mfield07 PICTURE '@!'
                  @ 4, 29 SAY mfield08 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                  @ 5, 29 SAY mfield09 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                  @ 6, 29 SAY mfield10 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
               ENDIF
            ENDIF
            set cent on
            @ 4, 64 SAY mfield12 pict "99/99/9999"
            set cent off
            @ 07,18 &ACTION mFIELD11 PICT '@!'
            @ 05,64 &ACTION mFIELD13 PICT '@!'
            @ 05,75 &ACTION mFIELD14 PICT '###'
            @ 06,64 &ACTION mFIELD15 PICT '@S15 !!!!!!!!!!!!!!!!!!!!'
            IF upper(ACTION)="GET"
               if MFIELD11="HOUSE" .OR. MFIELD11="HOUSE2"
                  @ 07,64 &ACTION mFIELD16 PICT '!' valid mfield16$"ABCE"
               ELSE
                  @ 07,64 &ACTION mFIELD16 PICT '!' valid mfield16$"ABCDE"
               ENDIF
            ELSE
               @ 07,64 &ACTION mFIELD16 PICT '!'
            ENDIF
            @ 1, 69 SAY mfield24 PICTURE '@!'
            DO CASE
               CASE status=' '
                  @ 7, 66 SAY 'For Invoicing'
               CASE status='I'
                  @ 7, 66 SAY 'For Posting  '
               CASE status='P'
                  @ 7, 66 SAY 'Posted       '
               CASE status='C'
                  @ 7, 66 SAY 'Cancelled    '
            ENDCASE
            IF action='GET'
               READ
               IF READKEY()=4.or.READKEY()=260
                  LOOP
               ENDIF
            ENDIF
            IF action='GET'
               DO WHILE mfield16<'A'.or.mfield16>'E'
                  IF MFIELD11="HOUSE" .OR. MFIELD11="HOUSE2"
                     @ 7, 64 GET mfield16 PICTURE '!' valid mfield16$"ABCE"
                  ELSE
                     @ 7, 64 GET mfield16 PICTURE '!' valid mfield16$"ABCDE"
                  ENDIF
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
      lkey= mtrans_c+ sifyl->inv_n
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
            REPLACE splyr_n with stkrec->splyr_n
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
               msplyr_n=splyr_n
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
               @ ROW,05 say mSTK_N PICT '@!'
               IF action='GET'
                  read
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
                        @ ROW,23 say mISSUE_U PICT '@!'
                        @ ROW,28 say mSTK_M   PICT '@!'
                        READ
                     ENDIF
                  ELSE
                     &C_HEAD
                     @ 19, 1 SAY SPACE(78)
                     @ 19, 3 SAY 'Packing :            On hand :         Bodega 2 :         Bodega 3 :'
                     @ 19, 13 SAY qty_pq PICTURE '#,###'
                     @ 19, 18 SAY '/'
                     @ 19, 19 SAY qty_pu PICTURE '@!'
                     @ 19, 34 SAY qty1 PICTURE '###,###'
                     @ 19, 53 SAY qty2 PICTURE '###,###'
                     @ 19, 72 SAY qty3 PICTURE '###,###'
*****
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
               @ ROW, 16 say     mISSUE_Q PICT '##,###'
               @ row, 23 SAY     missue_u PICT '@!'
               @ row, 28 SAY     mstk_m   PICT '@S20'
               @ row, 49 SAY     missue_p PICT '####.##'
               @ ROW, 57 &ACTION mDCOUNT1 PICT '99.99'
               @ ROW, 63 &ACTION mDCOUNT2 PICT '99'
               @ ROW, 66 &ACTION mDCOUNT3 PICT '99'
               IF action='GET'
                  READ
                  mt_prys= missue_q*missue_p
                  mt_prys= mt_prys-(mt_prys*mdcount1/100)
                  mt_prys= mt_prys-(mt_prys*mdcount2/100)
                  mt_prys= mt_prys-(mt_prys*mdcount3/100)
                  mt_prys= round(mt_prys,2)
                  mt_ac= missue_q*mstk_ac
                  mt_pc= missue_q*mstk_pc

               ENDIF
               &C_GET
               @ row, 69 SAY mt_prys PICTURE '###,###.##'
            ENDIF
            IF action='GET'
               IF EOF()
                  APPEND BLANK
               ENDIF
               REPLACE dcount1 WITH mdcount1, dcount2 WITH mdcount2, dcount3 WITH mdcount3
               REPLACE t_prys WITH mt_prys, t_ac WITH mt_ac, t_pc WITH mt_pc
               REPLACE USER_M WITH temp->user_m
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
            SUM FOR stk_n<>'REMOVE' t_ac, t_pc, t_prys TO mfield17, mfield18, mfield19
         ENDIF
         &C_HEAD
         @ 19, 1 SAY SPACE(78)
         @ 19, 55 SAY 'TOTAL'
         @ 19, 67 SAY mfield19 PICTURE '#,###,###.##'
         @ 20, 1 SAY SPACE(78)
         @ 20, 5 SAY 'DISCOUNT:      %,   %,   %'
         &C_GET
         @ 20,15 &ACTION mFIELD20 PICT '99.99'
         @ 20,23 &ACTION mFIELD21 PICT '99'
         @ 20,28 &ACTION mFIELD22 PICT '99'
         IF action='GET'
            READ
            mfield23= mfield19
            mfield23= mfield23-(mfield23*mfield20/100)
            mfield23= mfield23-(mfield23*mfield21/100)
            mfield23= mfield23-(mfield23*mfield22/100)
            mfield23= round(mfield23,2)
            IF mfield23<mfield17
               &C_MESSAGE
               @ 23, 22 SAY ' Warning, price is less than cost. '
               ?? CHR(7)
            ENDIF
         ENDIF
         &C_HEAD
         @ 20, 50 SAY 'NET AMOUNT'
         @ 20, 67 SAY mfield23 PICTURE '#,###,###.##'
         SELECT 3
         DO WHILE .T.
           *DO OPTION13
           do option4
            *SUSPEND
            IF choice='P' .AND. MFIELD01<>INV_N
               save screen to atlscreen
               atlmsg="Sorry, you cant print the invoice without saving! Press any key..."
               atllen=len(atlmsg)
               set colo to rb/rb
               @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
               set colo to +w/rb
               @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
               @ 12,41-atllen/2 say atlmsg
               atlkeypress=inkey(0)
               restore screen from atlscreen
               LOOP
            ENDIF
            EXIT
         ENDDO
         * SUSPEND
         IF choice='P'
            DO WHILE choice='P'
               &C_CLEAR
               @ 23, 0
               confirm= ' '
               &C_GET
               if MUser_M="CORA" .or. MUser="DEBBIE"
                  DO WHILE .not. confirm$'A12'
                     @ 23,20 SAY ' A] Abort   1] Invoice   2] Gate Pass ? ' GET confirm PICTURE '!'
                     READ
                  ENDDO
               else
                  DO WHILE .not. confirm$'A1'
                     @ 23,23 SAY ' A] Abort   1] Proceed to Print ? ' GET confirm PICTURE '!'
                     READ
                  ENDDO
               endif
               &C_CLEAR
               @ 23, 0
               IF confirm<>'A'
                  &C_MESSAGE
                  @ 23, 50 SAY ' Loading Program ... '
                  printed= .T.
               ENDIF
               DO CASE
                  CASE confirm='1'
                     DO SI7PRN
                  CASE confirm='2'
                     DO SI6PRN
               ENDCASE
               SELECT 3
               IF printed.and..not. new.and.status=' '
                  REPLACE status WITH 'P'
                  UNLOCK
               ENDIF
               do option4
              *DO OPTION13
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
      CASE CHOICE='E'
           LOOP
      * SUSPEND
      CASE choice='D'.and..not. new
       if muser="ADMIN"
         *SELECT 2
         *SEEK lkey
         *DO WHILE  stkrec->trans_c+ stkrec->trans_n=lkey
         *   SELECT 4
         *   SEEK  stkrec->stk_n
         *   IF .not. EOF()
         *      REPLACE qty1 WITH qty1+ stkrec->issue_q
         *      UNLOCK
         *   ENDIF
         *   SELECT 2
         *   DELETE
         *   SKIP
         *ENDDO
         *SELECT 5
         *IF cust_n<>mfield02
         *   SEEK TRIM(mfield02)
         *ENDIF
         *IF .NOT. EOF()
         *   REPLACE CUST_PUR WITH CUST_PUR-mfield23 &&***** changes to reflect purchases
         *ENDIF
         SELE 2
         FLUSH
       ENDIF
      CASE choice='S'.or.choice='M'
         SELECT 1
         GOTO TOP
         SELECT 2
         SEEK lkey
         SELECT 1
            DO WHILE .not. EOF()
               SELECT 4
               IF  temp->stk_n<>'REMOVE'.and. temp->stk_n= stkrec->stk_n.and. temp->trans_c+ temp->trans_n= stkrec->trans_c+ stkrec->trans_n
                  SEEK  temp->stk_n
                  IF .not. EOF()
                  *   REPLACE qty1 WITH qty1- temp->issue_q+ stkrec->issue_q
                  *   UNLOCK
                  ENDIF
               ELSE
                  IF  temp->stk_n<>'REMOVE'
                     SEEK  temp->stk_n
                     IF .not. EOF()
                     *   REPLACE qty1 WITH qty1- temp->issue_q
                     *   UNLOCK
                     ENDIF
                  ENDIF
                  IF  temp->trans_n= stkrec->trans_n
                     SEEK  stkrec->stk_n
                     IF .not. EOF()
                      *  REPLACE qty1 WITH qty1+ stkrec->issue_q
                      *  UNLOCK
                     ENDIF
                  ENDIF
               ENDIF
               SELECT 2
               IF EOF().or.trans_n<> sifyl->inv_n
                  APPEND BLANK
               ENDIF
               IF  temp->stk_n='REMOVE'
                  DELETE
               ELSE
                  IF stk_n<> temp->stk_n.or.issue_q<> temp->issue_q
                  *   REPLACE qty1 WITH  temp->qty1, qty2 WITH  temp->qty2, qty3 WITH  temp->qty3, trans_d WITH  temp->trans_d
                  ENDIF
                  REPLACE dcount1 WITH  temp->dcount1, dcount2 WITH  temp->dcount2
                  REPLACE dcount3 WITH  temp->dcount3, t_prys WITH  temp->t_prys, t_ac WITH  temp->t_ac, t_pc WITH  temp->t_pc
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
            SUM FOR stk_n<>'REMOVE' t_ac, t_pc, t_prys TO mfield17, mfield18, mfield19
            COUNT TO ATLCTR FOR STK_N<>"REMOVE"
            SELECT 5
            IF cust_n<>mfield02
               SEEK TRIM(mfield02)
            ENDIF
            IF .not. EOF()
               if cust_lt<mfield12
               *   REPLACE cust_lt WITH mfield12
               endif
               *REPLACE CUST_PUR WITH CUST_PUR-sv_net_a+mfield23 &&***** changes to reflect purchases
               UNLOCK
            ENDIF
         SELECT 3
         IF ATLCTR<>0
            REPLACE inv_a WITH mfield19, dcount1 WITH mfield20, dcount2 WITH mfield21
            REPLACE dcount3 WITH mfield22, net_a WITH mfield23
            REPLACE inv_bal WITH net_a-inv_adj-inv_pay
         ENDIF
         UNLOCK
         FLUSH
   ENDCASE
   SELECT 1
   ZAP
   printed= .F.
   close data
*   SELECT 6
*      USE ADFYL INDEX AD_N
   SELECT 5
      USE CUSTFYL INDEX CUST_N
   SELECT 4
      USE STKFYL INDEX STK_N
   SELECT 3
      USE SIFYL INDEX SI_N, SI_D, SI_CD, SI_DINV
   SELECT 2
      USE STKREC INDEX TRANS_CN, TRANS_ID, SI_ID
   SELECT 1
      USE &mTEMPFYL ALIA TEMP EXCL

ENDDO

CLOSE DATA
RETURN


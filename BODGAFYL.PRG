* program.....: BodgaFyl.prg
*             : transfer of stocks from 1 bodega to another
*             : 07/26/99

SELECT 4
   USE STKFYL INDEX STK_N
SELECT 3
   USE BODGAFYL INDEX BODGA_N
SELECT 2
   USE STKREC INDEX TRANS_CN, TRANS_ID, SI_ID
   COPY STRU TO &mTEMPFYL
SELECT 1
   USE &mTEMPFYL ALIA TEMP EXCL

set century on

mtrans_c= 'B'
choice= 'S'

DO WHILE choice$'SDA'
   DO BRDR1
   &C_BODY
   @ 4, 2  SAY 'Bodega Slip No. :'
   @ 5, 2  SAY 'From Bodega No. :'
   @ 6, 2  SAY 'To   Bodega No. :'
   @ 4, 47 SAY 'Date (mm/dd/yy)  :'
   *@ 5, 47 SAY 'Requisition Date :'
   &C_HEAD
   @ 8, 1 SAY SPACE(78)
   @ 8, 5 SAY 'STOCK CODE   QTY.  UNIT            DESCRIPTION'
   SELECT 3
   mfield01= SPACE(10)
   choice= 'F'
   action= 'GET'
   new= .T.
   DO WHILE choice$'FEVNTB'
      &C_GET
      IF action='GET'
         key= mfield01
         @ 4, 20 GET key PICTURE '@!'
         READ
         IF LEN(TRIM(key))=0
            CLOSE DATA
            RETURN
         ENDIF
         IF choice='F'.or.key<>mfield01
            DO MODE
            mfield01= key
         ENDIF
      ENDIF
      IF action='SAY'
         mfield01= inv_n
         mfield02= req_d
         mfield03= trans_fr
         mfield04= inv_d
         mfield05= user_m
         mfield06= processed
         mfield07= trans_to
         IF .not. mfield06
            mfield04= DATE()
         ENDIF
      ENDIF
      IF choice='F'
         choice= 'E'
         mfield01= key
         mfield02= CTOD('  /  /    ')
         mfield03= SPACE(1)
         mfield04= DATE()
         mfield05= muser
         mfield06= .F.
         mfield07= SPACE(1)
      ENDIF
      &C_GET
      @ 4, 20 SAY mfield01 PICTURE '@!'
      @ 05,20 &ACTION mFIELD03 PICT '@!'
      @ 06,20 &ACTION mFIELD07 PICT '@!'
      @ 04,68 &ACTION mFIELD04 PICT '99/99/9999'
      *@ 5, 68 SAY mfield02 PICT '99/99/9999'
      @ 1, 69 SAY mfield05 PICTURE '@!'
      IF action='GET'
         READ
         IF READKEY()=4.or.READKEY()=260
            LOOP
         ENDIF
         IF (.not. mfield03$'123')
            &C_CLEAR
            @ 22, 0
            @ 23, 0
            ?? CHR(7)
            confirm= ' '
            &C_MESSAGE
            @ 22, 18 SAY ' No such bodega code.                       '
            @ 23, 18 SAY ' Press <A> to Abort, any key to continue. ' GET confirm PICTURE '!'
            READ
            &C_CLEAR
            @ 22, 0
            @ 23, 0
            IF confirm='A'
               CLOSE DATA
               RETURN
            ELSE
               LOOP
            ENDIF
         ENDIF
      ENDIF
      bodga_fr= 'QTY'+mfield03
      bodga_o= 'QTY'+trans_fr
      bodga_to= 'QTY'+mfield07
      bodga_d= 'QTY'+trans_to
      lkey= mtrans_c+ bodgafyl->inv_n
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
            REPLACE user_m WITH  stkrec->user_m
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
                     mqty1= qty1
                     mqty2= qty2
                     mqty3= qty3
                     mqty1l= qty1l
                     mstk_dv= stk_dv
                     mstk_cat= stk_cat
                     missue_u= qty_u
                     IF qty1<1
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
               @ row, 29 SAY mstk_m PICTURE '@!'
               IF action='GET'
                  READ
               ENDIF
            ENDIF
            IF action='GET'
               IF EOF()
                  APPEND BLANK
               ENDIF
               REPLACE trans_c WITH mtrans_c, trans_n WITH mfield01, trans_d WITH DATE()
               REPLACE stk_n WITH mstk_n, stk_m WITH mstk_m, stk_pc WITH mstk_pc, stk_ac WITH mstk_ac, qty_s WITH mqty_s, qty1 WITH mqty1, qty2 WITH mqty2, qty3 WITH mqty3, qty1l WITH mqty1l
               REPLACE stk_dv WITH mstk_dv, stk_cat WITH mstk_cat, issue_d WITH mfield04
               REPLACE issue_q WITH missue_q, issue_fg WITH missue_fg, issue_u WITH missue_u, issue_p WITH missue_p, dcount1 WITH mdcount1, dcount2 WITH mdcount2, dcount3 WITH mdcount3
               REPLACE t_prys WITH mt_prys, t_ac WITH mt_ac, t_pc WITH mt_pc, user_m WITH muser_m
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
         SELECT 3
         DO OPTION4
         IF choice='P'
            DO WHILE choice='P'
               &C_MESSAGE
               @ 23, 50 SAY '...Printing'
               SELECT 1
               row_p= 0
               GOTO TOP
               SET CONSOLE OFF
               SET DEVICE TO PRINTER
               SET PRINTER ON
               ? CHR(27)+'@'
               @ row_p+1, 20 SAY '             MARINA TRADING               '
               @ row_p+2, 20 SAY '          BODEGA TRANSFER SLIP            '
               @ row_p+4, 5 SAY 'BODEGA SLIP NO :'
               @ row_p+4, 22 SAY mfield01 PICTURE '@!'
               @ row_p+4, 51 SAY 'DATE ISSUED :'
               @ row_p+4, 65 SAY mfield04
               @ row_p+5, 5 SAY 'TRANSFER FROM  : BODEGA '
               @ row_p+5, 29 SAY mfield03 PICTURE '@!'
               @ row_p+5, 60 SAY 'TO : BODEGA '
               @ row_p+5, 72 SAY mfield07 PICTURE '@!'
               @ row_p+6, 5 SAY REPLICATE('-',68)
               @ row_p+7, 10 SAY 'QUANTITY       STOCK CODE       DESCRIPTION'
               @ row_p+8, 5 SAY REPLICATE('-',68)
               row_p= row_p+9
               DO WHILE .not. EOF()
                  @ row_p, 5 SAY issue_q PICTURE '###,###'
                  @ row_p, 14 SAY issue_u PICTURE '@!'
                  @ row_p, 25 SAY stk_n PICTURE '@!'
                  @ row_p, 42 SAY stk_m PICTURE '@!'
                  row_p= row_p+1
                  SKIP
               ENDDO
               ? CHR(27)+'@'
               EJECT
               SET PRINTER OFF
               SET DEVICE TO SCREEN
               SET CONSOLE ON
               &C_CLEAR
               @ 23, 0
               SELECT 3
               DO OPTION4
            ENDDO
         ENDIF
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
         DO WHILE  stkrec->trans_c+ stkrec->trans_n=lkey
            SELECT 4
            SEEK  stkrec->stk_n
            IF .not. EOF()
               REPL &BODGA_TO WITH &BODGA_TO - STKREC->ISSUE_Q         &BODGA_FR WITH &BODGA_FR + STKREC->ISSUE_Q
               UNLOCK
            ENDIF
            SELECT 2
            DELETE
            SKIP
         ENDDO
         FLUSH
      CASE choice='S'.or.choice='M'
         SELECT 1
         GOTO TOP
         IF new.or..not.  bodgafyl->processed
            SELECT 2
            SEEK lkey
            SELECT 1
            DO WHILE .not. EOF()
               IF  temp->stk_n<>'REMOVE'
                  SELECT 4
                  SEEK  temp->stk_n
                  IF .not. EOF()
                     REPL &BODGA_TO WITH &BODGA_TO + TEMP->ISSUE_Q           &BODGA_FR WITH &BODGA_FR - TEMP->ISSUE_Q
                     UNLOCK
                  ENDIF
               ENDIF
               SELECT 2
               IF EOF().or.trans_n<> temp->trans_n
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
                  REPLACE dcount3 WITH  temp->dcount3, t_prys WITH  temp->t_prys, t_ac WITH  temp->t_ac, t_pc WITH  temp->t_pc, user_m WITH  temp->user_m
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
         ELSE
            SELECT 2
            SEEK lkey
            SELECT 1
            DO WHILE .not. EOF()
               SELECT 4
               IF  temp->stk_n<>'REMOVE'.and. temp->stk_n= stkrec->stk_n.and. temp->trans_c+ temp->trans_n= stkrec->trans_c+ stkrec->trans_n
                  SEEK  temp->stk_n
                  IF .not. EOF()
                     REPL &BODGA_TO WITH &BODGA_TO + TEMP->ISSUE_Q           &BODGA_FR WITH &BODGA_FR - TEMP->ISSUE_Q           &BODGA_O WITH &BODGA_O + STKREC->ISSUE_Q           &BODGA_D WITH &BODGA_D - STKREC->ISSUE_Q
                     UNLOCK
                  ENDIF
               ELSE
                  IF  temp->stk_n<>'REMOVE'
                     SEEK  temp->stk_n
                     IF .not. EOF()
                        REPL &BODGA_TO WITH &BODGA_TO + TEMP->ISSUE_Q            &BODGA_FR WITH &BODGA_FR - TEMP->ISSUE_Q
                        UNLOCK
                     ENDIF
                  ENDIF
                  IF  temp->trans_n= stkrec->trans_n
                     SEEK  stkrec->stk_n
                     IF .not. EOF()
                        REPL &BODGA_O WITH &BODGA_O + STKREC->ISSUE_Q            &BODGA_D WITH &BODGA_D - STKREC->ISSUE_Q
                        UNLOCK
                     ENDIF
                  ENDIF
               ENDIF
               SELECT 2
               IF EOF().or.trans_n<> temp->trans_n
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
                  REPLACE dcount3 WITH  temp->dcount3, t_prys WITH  temp->t_prys, t_ac WITH  temp->t_ac, t_pc WITH  temp->t_pc, user_m WITH  temp->user_m
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
         REPLACE inv_n WITH mfield01, req_d WITH mfield02, trans_fr WITH mfield03, inv_d WITH mfield04, user_m WITH muser, processed WITH .T., trans_to WITH mfield07
         UNLOCK
         FLUSH
   ENDCASE
   SELECT 1
   ZAP
ENDDO
 
CLOSE DATA
RETURN

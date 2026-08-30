* program.....: ColcFyl.prg
* module......: accounts receivables
* modified....: 03/19/99, y2k, close databases

SELECT 8
   USE CMFYL INDEX CM_N, CM_CD, CM_D
SELECT 7
   USE SRFYL INDEX SR_N, SR_CD, SR_D
SELECT 6
   USE DMFYL INDEX DM_N, DM_CD, DM_D
SELECT 5
   USE CUSTFYL INDEX CUST_N
SELECT 4
   USE SIFYL INDEX SI_N, SI_CD, SI_D, SI_DINV
SELECT 3
   USE COLECFYL INDEX OR_N, OR_CD
SELECT 2
   USE COLECREC INDEX COLEC_N, COLEC_D, CSI_N, CHK_DD
   COPY STRU TO &mTEMPFYL
SELECT 1
   USE &mTEMPFYL ALIA TEMP EXCL

choice= 'S'
DO WHILE choice$'SDA'
   DO BRDR1
   &C_BODY
   @ 4, 2  SAY 'CTR No. .     :'
   @ 5, 2  SAY 'Customer Code :'
   @ 4, 49 SAY 'Received Date :'
   @ 5, 49 SAY 'Discount      :     ,    ,'
   @ 6, 49 SAY 'Remarks       :'
   &C_HEAD
   @ 8, 1 SAY SPACE(78)                            
   @ 8, 5 SAY 'SI-NO.          ADJ.    PAYMENTS REM  CHECK NO.      CHECK-AMT.   CHK-DATE'
   SELECT 3
   * mfield01= SPACE(10)
   mfield01='C'+RIGHT(STR(YEAR(DATE()),4),2)+LEFT(DTOC(DATE()),2)+'-    '
   choice= 'F'
   action= 'GET'
   new= .T.
   DO WHILE choice$'FEVNTB'
      &C_GET
      IF action='GET'
         key= mfield01
         @ 4, 18 GET key PICTURE '@!'
         READ
         IF LEN(TRIM(key))=0 .OR. LEN(TRIM(KEY))=6
            close databases
            SET CENT OFF
            RETURN
         ENDIF
         IF choice='F'.or.key<>mfield01
            DO MODE
            mfield01= key
         ENDIF
      ENDIF
      IF action='SAY'
         flag= .T.
         mfield01= colec_n
         mfield02= cust_n
         mfield03= cust_m
         mfield04= colec_d
         mfield05= dcount1
         mfield06= dcount2
         mfield07= dcount3
         mfield08= colec_rem
         mfield09= colec_a
         mfield10= colec_adj
         mfield11= tchk_a
         mfield12= user_m
      ENDIF
      IF choice='F'
         choice= 'E'
         flag= .F.
         mfield01= key
         mfield02= SPACE(10)
         mfield03= SPACE(30)
         mfield04= DATE()
         mfield05= 0.0
         mfield06= 0.0
         mfield07= 0.0
         mfield08= SPACE(20)
         mfield09= 0
         mfield10= 0
         mfield11= 0
         mfield12= muser
      ENDIF
      &C_GET
      @ 4, 18 SAY mfield01 PICTURE '@!'
      DO WHILE .T.
         @ 05,18 &ACTION mFIELD02 PICT '@!'
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
                  @ 5, 29 GET mfield03 PICTURE '@!'
                  READ
               ENDIF
            ELSE
               mfield02= cust_n
               mfield03= cust_m
               @ 5, 18 SAY mfield02 PICTURE '@!'
               @ 6, 18 SAY mfield03 PICTURE '@!'
            ENDIF
            SELECT 3
         ENDIF
         @ 5, 18 SAY mfield02 PICTURE '@!'
         @ 6, 18 SAY mfield03 PICTURE '@!'
         set cent on
         @ 04,65 &ACTION mFIELD04 PICT '99/99/9999'
         @ 05,65 &ACTION mFIELD05 PICT '@Z ##.#'
         @ 05,70 &ACTION mFIELD06 PICT '@Z ##.#'
         @ 05,75 &ACTION mFIELD07 PICT '@Z ##.#'
         @ 06,65 &ACTION mFIELD08 PICT '@S14 !!!!!!!!!!!!!!!!!!!!'
         @ 1, 69 SAY mfield12 PICTURE '@!'
         IF action='GET'
            READ
            IF READKEY()=4.or.READKEY()=260
               set cent off
               LOOP
            ENDIF
         ENDIF
         set cent off
         EXIT
      ENDDO
      IF READKEY()=4.or.READKEY()=260
         LOOP
      ENDIF
      IF .not. flag.and.new
         &C_HEAD    
         @ 8, 5 SAY 'SI-NO.          ADJ.    PAYMENTS REM  SI/DM/SR/CM     BALANCE     SI-DATE '
         &C_CLEAR
         @ 22, 0
         &C_MESSAGE
         @ 23, 50 SAY ' Please wait... '
         SELECT 4
         SET ORDER TO 2
         SEEK 'F'+mfield02
         row= 9
         DO WHILE cust_n=mfield02.and.paid='F'.and..not. EOF().and.row<19
            @ row, 45 SAY inv_n   PICTURE '@!'
            @ row, 56 SAY inv_bal PICTURE '#,###,###.##'
            set cent on
            @ row, 69 SAY inv_d   PICTURE "99/99/9999"
            set cent off
            row= row+1
            SKIP
         ENDDO
         SET ORDER TO 1
         &C_CLEAR
         @ 23, 0
         &C_MESSAGE
         @ 23, 50 SAY ' Please wait... '
         SELECT 6
         SET ORDER TO 2
         SEEK 'F'+mfield02
         DO WHILE cust_n=mfield02.and.paid='F'.and..not. EOF().and.row<19
            @ row, 45 SAY inv_n   PICTURE '@!'
            @ row, 56 SAY inv_bal PICTURE '#,###,###.##'
            set cent on
            @ row, 69 SAY inv_d   PICTURE "99/99/9999"
            set cent off
            row= row+1
            SKIP
         ENDDO
         SET ORDER TO 1
         &C_CLEAR
         @ 23, 0
         &C_MESSAGE
         @ 23, 50 SAY ' Please wait... '
         SELECT 7
         SET ORDER TO 2
         SEEK 'F'+mfield02
         DO WHILE cust_n=mfield02.and.paid='F'.and..not. EOF().and.row<19
            @ row, 45 SAY inv_n PICTURE '@!'
            @ row, 56 SAY 0-inv_bal PICTURE '#,###,###.##'
            set cent on
            @ row, 69 SAY inv_d pict '99/99/9999'
            set cent off
            row= row+1
            SKIP
         ENDDO
         SET ORDER TO 1
         &C_CLEAR
         @ 23, 0
         &C_MESSAGE
         @ 23, 50 SAY ' Please wait... '
         SELECT 8
         SET ORDER TO 2
         SEEK 'F'+mfield02
         DO WHILE cust_n=mfield02.and.paid='F'.and..not. EOF().and.row<19
            @ row, 45 SAY inv_n PICTURE '@!'
            @ row, 56 SAY 0-inv_bal PICTURE '#,###,###.##'
            set cent on
            @ row, 69 SAY inv_d pict '99/99/9999'
            set cent off
            row= row+1
            SKIP
         ENDDO
         SET ORDER TO 1
         &C_CLEAR
         @ 23, 0
         SELECT 1
         GOTO TOP
      ENDIF
      lkey=  colecfyl->colec_n
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
         DO WHILE  colecrec->colec_n=lkey
            SELECT 1
            APPEND BLANK
            REPLACE chk_n WITH  colecrec->chk_n, chk_a WITH  colecrec->chk_a, chk_d WITH  colecrec->chk_d, chk_dd WITH  colecrec->chk_dd
            REPLACE inv_n WITH  colecrec->inv_n, cust_n WITH  colecrec->cust_n, cust_m WITH  colecrec->cust_m, cust_s WITH  colecrec->cust_s
            REPLACE inv_d WITH  colecrec->inv_d, colec_a WITH  colecrec->colec_a, inv_adj WITH  colecrec->inv_adj
            REPLACE colec_n WITH  colecrec->colec_n, colec_d WITH  colecrec->colec_d, colec_rem WITH  colecrec->colec_rem, inv_bal WITH  colecrec->inv_bal, user_m WITH  colecrec->user_m
            SELECT 2
            SKIP
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
            minv_bal= 0
            IF EOF()
               minv_n= SPACE(10)
               minv_d= CTOD('  /  /    ')
               mcust_n= SPACE(10)
               mcust_m= SPACE(30)
               mcust_s= SPACE(10)
               minv_adj= 0.00
               mcolec_a= 0.00
               mchk_n= SPACE(20)
               mchk_a= 0.00
               mchk_d= CTOD('  /  /    ')
               mcolec_rem= SPACE(20)
               muser_m= muser
            ELSE
               minv_n= inv_n
               minv_d= inv_d
               mcust_n= cust_n
               mcust_s= cust_s
               minv_adj= inv_adj
               mcolec_a= colec_a
               mchk_n= chk_n
               mchk_a= chk_a
               mchk_d= chk_d
               mcolec_rem= colec_rem
               muser_m= user_m
            ENDIF
            &C_GET
            @ row, 1 SAY RECNO() PICTURE '###'
            DO WHILE .T.
               @ ROW,05 &ACTION mINV_N PICT '!!!!!!!!!!'
               IF action='GET'
                  READ
                  subkey= minv_n
                  &C_BRDR
                  @ 20, 1 TO 20, 78 DOUBLE
                  &C_CLEAR
                  @ 19, 1 SAY SPACE(78)
                  @ 22, 0
                  @ 23, 0
                  DO CASE
                     CASE READKEY()>3.and.READKEY()<8
                        DO KEYS
                        IF error
                           error= .F.
                           LOOP
                        ELSE
                           EXIT
                        ENDIF
                     CASE LEN(TRIM(subkey))=0
                        EXIT
                     CASE 'REMOVE'$subkey
                        minv_n= 'REMOVE    '
                        &C_CLEAR
                        @ row, 5 CLEAR TO row, 78
                        &C_GET
                        EXIT
                     CASE READKEY()=12
                        EXIT
                  ENDCASE
                  SELECT 4
                  &C_MESSAGE
                  @ 23, 50 SAY ' Searching... '
                  subkey= LTRIM(TRIM(subkey))
                  IF LEN(subkey)=0
                     GOTO BOTTOM
                     SKIP
                  ELSE
                     SEEK subkey
                  ENDIF
                  &C_CLEAR
                  @ 23, 0
                  &C_GET
                  IF EOF()
                     SELECT 6
                     &C_MESSAGE
                     @ 23, 50 SAY ' Searching... '
                     subkey= LTRIM(TRIM(subkey))
                     IF LEN(subkey)=0
                        GOTO BOTTOM
                        SKIP
                     ELSE
                        SEEK subkey
                     ENDIF
                     &C_CLEAR
                     @ 23, 0
                     &C_GET
                     IF EOF()
                        SELECT 7
                        &C_MESSAGE
                        @ 23, 50 SAY ' Searching... '
                        subkey= LTRIM(TRIM(subkey))
                        IF LEN(subkey)=0
                           GOTO BOTTOM
                           SKIP
                        ELSE
                           SEEK subkey
                        ENDIF
                        &C_CLEAR
                        @ 23, 0
                        &C_GET
                        IF EOF()
                           SELECT 8
                           DO VALID1
                           IF EOF()
                              SELECT 1
                              LOOP
                           ELSE
                              IF minv_n= temp->inv_n
                                 minv_bal= ( temp->inv_bal)* -1
                              ELSE
                                 minv_bal= inv_bal
                              ENDIF
                              minv_n= inv_n
                              mcust_n= cust_n
                              mcust_m= cust_m
                              mcust_s= cust_s
                              minv_d= inv_d
                              mdcount= minv_bal
                              minv_adj= minv_bal-mdcount
                              &C_HEAD
                              @ 19, 1 SAY SPACE(78)
                              @ 20, 1 SAY SPACE(78)
                              @ 19, 1 SAY 'CM-Date             T-Amount Discount   Net Amount    Balance Remarks'
                              SET CENT OFF
                              @ 20, 1  SAY inv_d
                              @ 20, 19 SAY inv_a PICTURE '#######.##'
                              @ 20, 30 SAY dcount1 PICTURE '##.##'
                              @ 20, 35 SAY dcount2 PICTURE '##'
                              @ 20, 38 SAY dcount3 PICTURE '##'
                              @ 20, 41 SAY net_a PICTURE '#######.##'
                              @ 20, 52 SAY inv_bal PICTURE '#######.##'
                              @ 20, 63 SAY dm_rem PICTURE '@S16'
                           ENDIF
                        ELSE
                           IF minv_n= temp->inv_n
                              *minv_bal= (temp->inv_bal)* -1
                              minv_bal= -(temp->inv_bal)
                           ELSE
                              minv_bal= -inv_bal
                           ENDIF
                           minv_n= inv_n
                           mcust_n= cust_n
                           mcust_m= cust_m
                           mcust_s= cust_s
                           minv_d= inv_d
                           mdcount= minv_bal
                           minv_adj= minv_bal-mdcount
                           &C_HEAD
                           @ 19, 1 SAY SPACE(78)
                           @ 20, 1 SAY SPACE(78)
                           @ 19, 1 SAY 'SR-Date             T-Amount Discount   Net Amount    Balance Remarks'
                           SET CENT OFF
                           @ 20, 1 SAY inv_d
                           @ 20, 19 SAY inv_a PICTURE '#######.##'
                           @ 20, 30 SAY dcount1 PICTURE '##.##'
                           @ 20, 35 SAY dcount2 PICTURE '##'
                           @ 20, 38 SAY dcount3 PICTURE '##'
                           @ 20, 41 SAY net_a PICTURE '#######.##'
                           @ 20, 52 SAY inv_bal PICTURE '#######.##'
                           @ 20, 63 SAY si_rem PICTURE '@S16'
                        ENDIF
                     ELSE
                        IF minv_n= temp->inv_n
                           minv_bal=  temp->inv_bal
                        ELSE
                           minv_bal= inv_bal
                        ENDIF
                        minv_n= inv_n
                        mcust_n= cust_n
                        mcust_m= cust_m
                        mcust_s= cust_s
                        minv_d= inv_d
                        mdcount= minv_bal
                        IF mdcount>0
                           mdcount= mdcount-(mdcount*mfield05/100)
                           mdcount= mdcount-(mdcount*mfield06/100)
                           mdcount= mdcount-(mdcount*mfield07/100)
                        ENDIF
                        minv_adj= minv_bal-mdcount
                        &C_HEAD
                        @ 19, 1 SAY SPACE(78)
                        @ 20, 1 SAY SPACE(78)
                        @ 19, 1 SAY 'DM-Date             T-Amount Discount   Net Amount    Balance Remarks'
                        SET CENT OFF
                        @ 20, 1 SAY inv_d
                        @ 20, 19 SAY inv_a PICTURE '#######.##'
                        @ 20, 30 SAY dcount1 PICTURE '##.##'
                        @ 20, 35 SAY dcount2 PICTURE '##'
                        @ 20, 38 SAY dcount3 PICTURE '##'
                        @ 20, 41 SAY net_a PICTURE '#######.##'
                        @ 20, 52 SAY inv_bal PICTURE '#######.##'
                        @ 20, 63 SAY dm_rem PICTURE '@S16'
                     ENDIF
                  ELSE
                     IF minv_n= temp->inv_n
                        minv_bal=  temp->inv_bal
                     ELSE
                        minv_bal= inv_bal
                     ENDIF
                     minv_n= inv_n
                     mcust_n= cust_n
                     mcust_m= cust_m
                     mcust_s= cust_s
                     minv_d= inv_d
                     mdcount= minv_bal
                     IF mdcount>0
                        mdcount= mdcount-(mdcount*mfield05/100)
                        mdcount= mdcount-(mdcount*mfield06/100)
                        mdcount= mdcount-(mdcount*mfield07/100)
                     ENDIF
                     minv_adj= minv_bal-mdcount
                     &C_HEAD
                     @ 19, 1 SAY SPACE(78)
                     @ 20, 1 SAY SPACE(78)
                     @ 19, 1 SAY 'SI-Date  Type Terms T-Amount Discount   Net Amount    Balance Remarks'
                     SET CENT OFF
                     @ 20, 1 SAY inv_d
                     @ 20, 10 SAY cust_tp PICTURE '@S04'
                     @ 20, 15 SAY cust_t PICTURE '###'
                     @ 20, 19 SAY inv_a PICTURE '#######.##'
                     @ 20, 30 SAY dcount1 PICTURE '##.##'
                     @ 20, 35 SAY dcount2 PICTURE '##'
                     @ 20, 38 SAY dcount3 PICTURE '##'
                     @ 20, 41 SAY net_a PICTURE '#######.##'
                     @ 20, 52 SAY inv_bal PICTURE '#######.##'
                     @ 20, 63 SAY si_rem PICTURE '@S16'
                  ENDIF
                  IF cust_n<>mfield02
                     &C_MESSAGE
                     @ 23, 7 SAY ' Warning SI or DM or SR or CM does not belong to this Customer. '
                     ?? CHR(7)
                  ENDIF
                  IF status<>'P'
                     &C_MESSAGE
                     @ 23, 15 SAY ' Warning SI or DM or SR or CM is not yet posted. '
                     ?? CHR(7)
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
               CASE LEN(TRIM(minv_n))=0.and.EOF()
                  IF READKEY()=7
                     action= 'GET'
                     LOOP
                  ENDIF
               CASE READKEY()=12
                  EXIT
            ENDCASE
            &C_GET
            @ row, 5 SAY minv_n PICTURE '!!!!!!!!!!'
            IF minv_n<>'REMOVE'.and.LEN(TRIM(minv_n))<>0
               DO WHILE .T.
                  @ ROW,16 &ACTION mINV_ADJ   PICT '##,###.##'
                  IF action='GET'
                     READ
                     mcolec_a= minv_bal-minv_adj
                  ENDIF
                  @ ROW,26 &ACTION mCOLEC_A   PICT '####,###.##'
                  IF ACTION="GET"
                     @ ROW,38 &ACTION mCOLEC_REM PICT '@S6 !!!!!!!!!!!!!!!!!!!!'
                  ELSE
                     @ ROW,38 &ACTION mCOLEC_REM PICT '@S10 !!!!!!!!!!!!!!!!!!!!'
                  ENDIF
                  IF action='GET'
                     READ
                     IF READKEY()=4.or.READKEY()=260
                        LOOP
                     ENDIF
                  ENDIF
                  EXIT
               ENDDO
            ENDIF
            IF LEN(TRIM(minv_n))=0
               IF .not. flag.and.new
                  &C_HEAD     
                  @ 8, 5 SAY 'SI-NO.          ADJ.    PAYMENTS REM  CHECK NO.      CHECK-AMT.   CHK-DATE'
                  &C_CLEAR
                  @ 9, 43 CLEAR TO 18, 78
                  &C_GET
                  flag= .T.
               ENDIF
               SELECT 5
               SEEK mfield02
               mcust_s= cust_s
               SELECT 1
               DO WHILE .T.
                  @ ROW,43 &ACTION mCHK_N PICT '@S12 !!!!!!!!!!!!!!!!!!!!'
                  IF action='GET'
                     READ
                     IF LEN(TRIM(mchk_n))=0
                        IF .not. EOF()
                           LOOP
                        ELSE
                           EXIT
                        ENDIF
                     ENDIF
                  ENDIF
                  set cent on
                  @ ROW,56 &ACTION mCHK_A PICT '#,###,###.##'
                  @ ROW,69 &ACTION mCHK_D PICT '99/99/9999'
                  IF action='GET'
                     READ
                     IF READKEY()=4.or.READKEY()=260
                        set cent off
                        LOOP
                     ENDIF
                  ENDIF
                  set cent off
                  EXIT
               ENDDO
            ENDIF
            IF LEN(TRIM(minv_n))=0.and.LEN(TRIM(mchk_n))=0.and.EOF()
               &C_CLEAR
               @ row, 1 SAY SPACE(78)
               GOTO TOP
               EXIT
            ENDIF
            IF action='GET'
               IF EOF()
                  APPEND BLANK
               ENDIF
               REPLACE colec_n WITH mfield01, colec_d WITH mfield04, inv_d WITH minv_d, inv_bal WITH minv_bal
               REPLACE inv_n WITH minv_n, cust_n WITH mfield02, cust_m WITH mfield03, cust_s WITH mcust_s, inv_adj WITH minv_adj, colec_a WITH mcolec_a
               REPLACE chk_n WITH mchk_n, chk_a WITH mchk_a, chk_d WITH mchk_d, colec_rem WITH mcolec_rem, user_m WITH muser_m
               IF mchk_d<mfield04
                  REPLACE chk_dd WITH mfield04
               ELSE
                  REPLACE chk_dd WITH mchk_d
               ENDIF
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
            SUM FOR inv_n<>'REMOVE' colec_a, inv_adj, chk_a TO mfield09, mfield10, mfield11
            IF mfield09-mfield11<>0
               @ 23, 13 SAY ' Total Payment does not tally with Total Collections. '
               ? CHR(7)
            ENDIF
         ENDIF
         &C_HEAD
         @ 19, 1 SAY SPACE(78)
         @ 19, 5 SAY 'TOTAL'
         @ 19, 16 SAY mfield10 PICTURE '##,###.##'
         @ 19, 26 SAY mfield09 PICTURE '####,###.##'
         @ 19, 56 SAY mfield11 PICTURE '#,###,###.##'
         IF mfield09-mfield11<>0
            &C_BODY
            IF mfield09-mfield11>0
               @ 7, 57 SAY 'Short :'
            ELSE
               @ 7, 57 SAY ' Over :'
            ENDIF
            &C_GET
            @ 7, 65 SAY mfield09-mfield11 PICTURE '#,###,###.##'
         ELSE
            &C_CLEAR
            @ 7, 57 SAY SPACE(21)
            &C_GET
         ENDIF
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
        IF MUSER="ADMIN"
         SELECT 2
         SEEK lkey
         DO WHILE  colecrec->colec_n=lkey
            IF LEN(TRIM(inv_n))<>0
               SELECT 4
               SEEK  colecrec->inv_n
              *IF EOF()
              *   SELECT 6
              *   SEEK  colecrec->inv_n
              *ENDIF
               IF EOF()
                  SELECT 7
                  SEEK  colecrec->inv_n
               ENDIF
              *IF EOF()
              *   SELECT 8
              *   SEEK  colecrec->inv_n
              *ENDIF
               IF .not. EOF()
                  REPLACE inv_adj WITH inv_adj- colecrec->inv_adj
                  REPLACE inv_pay WITH inv_pay-ABS( colecrec->colec_a)
                  REPLACE inv_bal WITH net_a-inv_adj-inv_pay
                  IF inv_bal<=0
                     REPLACE paid WITH 'T'
                  ELSE
                     REPLACE paid WITH 'F'
                  ENDIF
                  UNLOCK
               ENDIF
            ENDIF
            SELECT 2
            DELETE
            SKIP
         ENDDO
         FLUSH
        ENDIF
      CASE choice='S'.and.action='GET'
         SELECT 1
         set cent on
         LOCATE FOR DTOC(chk_d)<>'  /  /    '
         set cent off
         IF chk_d>mfield04
            mchk_d= chk_d
            set cent on
            REPLACE all colec_rem WITH DTOC(mchk_d)
            set cent off
         ELSE                         
            set cent on
           *REPLACE all colec_rem WITH DTOC(chk_d)
            REPLACE all colec_rem WITH DTOC(mfield04)
            set cent off
         ENDIF
         GOTO TOP
         IF new
            DO WHILE .not. EOF()
               IF  temp->inv_n<>'REMOVE'
                  SELECT 4
                  SEEK  temp->inv_n
                  IF EOF()
                     SELECT 6
                     SEEK  temp->inv_n
                  ENDIF
                  IF EOF()
                     SELECT 7
                     SEEK  temp->inv_n
                  ENDIF
                  IF EOF()
                     SELECT 8
                     SEEK  temp->inv_n
                  ENDIF
                  IF .not. EOF()
                     REPLACE inv_adj WITH inv_adj+ temp->inv_adj
                     replace inv_pay WITH inv_pay+ABS( temp->colec_a)
                     REPLACE inv_bal WITH net_a-inv_adj-inv_pay
                     IF inv_bal<=0
                        REPLACE paid WITH 'T'
                     ELSE
                        REPLACE paid WITH 'F'
                     ENDIF
                     UNLOCK
                  ENDIF
               ENDIF
               SELECT 1
               SKIP
            ENDDO
            USE
            SELE 4
            IF .NOT. EOF()
               IF inv_bal<=0
                  REPLACE paid WITH 'T'
               ENDIF
               UNLOCK
            ENDIF
            SELE 7
            IF .NOT. EOF()
               IF inv_bal<=0
                  REPLACE paid WITH 'T'
               ENDIF
               UNLOCK
            ENDIF

            * USE

            SELECT 2
            APPE FROM &mTEMPFYL FOR INV_N <> "REMOVE"
            UNLOCK
            SELECT 1
            USE &mTEMPFYL ALIA TEMP EXCL
         ELSE
            SELECT 2
            SEEK lkey
            SELECT 1
            DO WHILE .not. EOF()
               SELECT 4
               IF  temp->inv_n<>'REMOVE'.and. temp->colec_n= colecrec->colec_n.and. temp->inv_n= colecrec->inv_n
                  SEEK  temp->inv_n
                  IF EOF()
                     SELECT 6
                     SEEK  temp->inv_n
                  ENDIF
                  IF EOF()
                     SELECT 7
                     SEEK  temp->inv_n
                  ENDIF
                  IF EOF()
                     SELECT 8
                     SEEK  temp->inv_n
                  ENDIF
                  IF .not. EOF()
                     REPLACE inv_adj WITH inv_adj+ temp->inv_adj- colecrec->inv_adj, inv_pay WITH inv_pay+ABS( temp->colec_a)-ABS( colecrec->colec_a), inv_bal WITH net_a-inv_adj-inv_pay
                     IF inv_bal<=0
                        REPLACE paid WITH 'T'
                     ELSE
                        REPLACE paid WITH 'F'
                     ENDIF
                     UNLOCK
                  ENDIF
               ELSE
                  IF  temp->inv_n<>'REMOVE'
                     SELECT 4
                     SEEK  temp->inv_n
                     IF EOF()
                        SELECT 6
                        SEEK  temp->inv_n
                     ENDIF
                     IF EOF()
                        SELECT 7
                        SEEK  temp->inv_n
                     ENDIF
                     IF EOF()
                        SELECT 8
                        SEEK  temp->inv_n
                     ENDIF
                     IF .not. EOF()
                        REPLACE inv_adj WITH inv_adj+ temp->inv_adj, inv_pay WITH inv_pay+ABS( temp->colec_a), inv_bal WITH net_a-inv_adj-inv_pay
                        IF inv_bal<=0
                           REPLACE paid WITH 'T'
                        ELSE
                           REPLACE paid WITH 'F'
                        ENDIF
                        UNLOCK
                     ENDIF
                  ENDIF
                  IF  temp->colec_n= colecrec->colec_n.and.LEN(TRIM( temp->inv_n))<>0
                     SELECT 4
                     SEEK  colecrec->inv_n
                     IF EOF()
                        SELECT 6
                        SEEK  colecrec->inv_n
                     ENDIF
                     IF EOF()
                        SELECT 7
                        SEEK  colecrec->inv_n
                     ENDIF
                     IF EOF()
                        SELECT 8
                        SEEK  colecrec->inv_n
                     ENDIF
                     IF .not. EOF()
                        REPLACE inv_adj WITH inv_adj- colecrec->inv_adj, inv_pay WITH inv_pay-ABS( colecrec->colec_a), inv_bal WITH net_a-inv_adj-inv_pay
                        IF inv_bal<=0
                           REPLACE paid WITH 'T'
                        ELSE
                           REPLACE paid WITH 'F'
                        ENDIF
                        UNLOCK
                     ENDIF
                  ENDIF
               ENDIF
               SELECT 2
               IF EOF().or.colec_n<> temp->colec_n
                  APPEND BLANK
               ENDIF
               IF  temp->inv_n='REMOVE'
                  DELETE
               ELSE
                  REPLACE chk_n WITH  temp->chk_n, chk_a WITH  temp->chk_a, chk_d WITH  temp->chk_d, chk_dd WITH  temp->chk_dd
                  REPLACE inv_n WITH  temp->inv_n, cust_n WITH  temp->cust_n, cust_m WITH  temp->cust_m, cust_s WITH  temp->cust_s, inv_adj WITH  temp->inv_adj
                  REPLACE colec_n WITH mfield01, colec_d WITH mfield04, colec_rem WITH  temp->colec_rem, user_m WITH  temp->user_m
                  REPLACE inv_bal WITH  temp->inv_bal, inv_d WITH  temp->inv_d, colec_a WITH  temp->colec_a
                  IF chk_d<colec_d
                     REPLACE chk_dd WITH colec_d
                  ELSE
                     REPLACE chk_dd WITH chk_d
                  ENDIF
                  UNLOCK
               ENDIF
               IF mfield01=lkey
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
         REPLACE colec_n WITH mfield01, cust_n WITH mfield02, cust_m WITH mfield03, colec_d WITH mfield04
         REPLACE dcount1 WITH mfield05, dcount2 WITH mfield06, dcount3 WITH mfield07, colec_rem WITH mfield08, colec_a WITH mfield09
         REPLACE colec_adj WITH mfield10, tchk_a WITH mfield11, user_m WITH muser
         IF mfield09-mfield11<=0
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

close databases
SET CENT OFF
return

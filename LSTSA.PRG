* program.....: LstSA.prg
*             : Statement of Accounts

SELECT 2
   USE SIFYL INDEX SI_CD
SELECT 1
   USE CUSTFYL INDEX CUST_N
minv_d= CTOD('  /  /    ')

DO BRDR2
@ 8, 5 SAY 'SI-NO.        SI-DATE       TERMS      ORIGINAL-AMT.           BALANCE'

set cent on
DO WHILE .T.                                 
   &C_BODY
   mfield01= SPACE(10)
   mfield02= SPACE(10)
   mfield03= SPACE(1)
   mfield04= SPACE(10)
   mfield05= SPACE(10)
   mfield06= DATE()
   @ 4, 2 SAY 'Territory Code :'
   @ 5, 2 SAY 'Area Code      :'
   * @ 6, 2 SAY 'Price Category :'
   @ 4, 43 SAY 'Start At Customer Code :'
   @ 5, 43 SAY 'Stop  At Customer Code :'
   @ 6, 43 SAY 'Cut-Off Date           :'
   DO WHILE .T.
      &C_GET
      @ 4, 19 GET mfield01 PICTURE '@!'
      SELECT 1
      @ 5, 19 GET mfield02 PICTURE '@!'
      * @ 6, 19 GET mfield03 PICTURE '@!'
      READ
      IF READKEY()=4.or.READKEY()=260
         LOOP
      ENDIF
      SET FILTER TO
      DO CASE
         * CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield02))<>0.and.LEN(TRIM(mfield03))<>0
         *    SET FILTER TO CUST_S=mfield01.and.cust_ac=mfield02.and.cust_pc=mfield03
         CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield02))<>0
            SET FILTER TO CUST_S=mfield01.and.cust_ac=mfield02
         * CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield03))<>0
         *    SET FILTER TO CUST_S=mfield01.and.cust_pc=mfield03
         * CASE LEN(TRIM(mfield02))<>0.and.LEN(TRIM(mfield03))<>0
         *    SET FILTER TO CUST_S=mfield02.and.cust_pc=mfield03
         CASE LEN(TRIM(mfield01))<>0
            SET FILTER TO CUST_S=mfield01
         CASE LEN(TRIM(mfield02))<>0
            SET FILTER TO cust_ac=mfield02
         * CASE LEN(TRIM(mfield03))<>0
         *    SET FILTER TO cust_pc=mfield03
      ENDCASE
      DO WHILE .T.
         GOTO BOTTOM
         mfield05= cust_n
         GOTO TOP
         mfield04= cust_n
         &C_GET
         @ 5, 68 SAY mfield05
         @ 4, 68 GET mfield04 PICTURE '@!'
         READ
         IF READKEY()=4.or.READKEY()=260
            EXIT
         ENDIF
         IF LEN(TRIM(mfield04))=0
            close data
            set cent off
            RETURN
         ELSE
            SEEK LTRIM(TRIM(mfield04))
         ENDIF
         IF EOF()
            confirm= ' '
            &C_CLEAR
            @ 21, 0 CLEAR
            &C_MESSAGE
            @ 23, 30 SAY ' No Such Customer Code. '
            &C_GET
            @ 21, 20 SAY ' Press <A> to Abort, any key to Continue. ' GET confirm PICTURE '!'
            READ
            IF confirm='A'
               set cent off
               close data
               RETURN
            ELSE
               &C_CLEAR
               @ 21, 0
               @ 23, 0
               LOOP
            ENDIF
         ELSE
            mfield04= cust_n
            @ 4, 68 SAY mfield04
         ENDIF
         @ 5, 68 GET mfield05 PICTURE '@!'
         READ
         IF mfield05=SPACE(10)
            CLOSE DATA
            SET CENT OFF
            RETURN
         ELSE
            SEEK LTRIM(TRIM(mfield05))
         ENDIF
         IF EOF()
            confirm= ' '
            &C_CLEAR
            @ 21, 0 CLEAR
            &C_MESSAGE
            @ 23, 30 SAY ' No Such Customer Code. '
            &C_GET
            @ 21, 20 SAY ' Press <A> to Abort, any key to Continue. ' GET confirm PICTURE '!'
            READ
            IF confirm='A'
               set cent on
               close data
               RETURN
            ELSE
               &C_CLEAR
               @ 21, 0
               @ 23, 0
               LOOP
            ENDIF
         ELSE
            mfield05= cust_n
            @ 5, 68 SAY mfield05
         ENDIF
         IF READKEY()=4.or.READKEY()=260
            LOOP
         ENDIF
         @ 6, 68 GET mfield06
         READ
         IF READKEY()=4.or.READKEY()=260
            LOOP
         ENDIF
         EXIT
      ENDDO
      IF READKEY()=4.or.READKEY()=260
         LOOP
      ENDIF
      EXIT
   ENDDO
   choice= 'L'
   DO OPTION8
   IF mfield04>mfield05.and.mfield05<>SPACE(10)
      mtemp= mfield04
      mfield04= mfield05
      mfield05= mtemp
   ENDIF
   SEEK mfield04
   DO CASE
      CASE choice='L'
         flag= 1
         row= 9
         STORE 0.00 TO stl1, stl2, stl3, stl4, gtl1, gtl2, gtl3, gtl4
         DO WHILE .not. EOF().and.cust_n<=mfield05 
            SELECT 2
            SEEK 'F'+ custfyl->cust_n
            IF .not. EOF()
               IF flag=1
                  c_list= c_option
                  flag= 0
               ELSE
                  c_list= c_body
                  flag= 1
               ENDIF
               &C_LIST
               @ row, 5 SAY cust_n
               @ row, 16 SAY cust_m
               row= row+2
            ENDIF
            DO WHILE .not. EOF().and.paid='F'.and.cust_n= custfyl->cust_n .AND. INV_D<=MFIELD06
               IF status<>'C'
                  @ row, 5 SAY inv_n PICTURE '@!'
                  @ row, 19 SAY inv_d
                  IF cust_t<>0
                     @ row, 31 SAY cust_t PICTURE '###'
                     @ row, 35 SAY 'days'
                  ENDIF
                  @ row, 43 SAY net_a PICTURE '###,###,###.##'
                  @ row, 61 SAY inv_bal PICTURE '###,###,###.##'
               ENDIF
               IF status<>'C'.and.(post_d<CTOD('01/01/1901').or.post_d=CTOD('  /  /  '))
                  stl1= stl1+inv_bal
                  gtl1= gtl1+inv_bal
               ENDIF
               IF status<>'C'.and.post_d>CTOD('01/01/1901')
                  DO CASE
                     CASE mfield06-inv_d<30
                        stl1= stl1+inv_bal
                        gtl1= gtl1+inv_bal
                     CASE mfield06-inv_d<60
                        stl2= stl2+inv_bal
                        gtl2= gtl2+inv_bal
                     CASE mfield06-inv_d<90
                        stl3= stl3+inv_bal
                        gtl3= gtl3+inv_bal
                     OTHERWISE
                        stl4= stl4+inv_bal
                        gtl4= gtl4+inv_bal
                  ENDCASE
               ENDIF
               row= row+1
               SKIP
               IF row>18.or.cust_n<> custfyl->cust_n
                  SELECT 1
                  SKIP
                  IF EOF()
                     EXIT
                  ELSE
                     SKIP  -1
                     SELECT 2
                  ENDIF
                  confirm= ' '
                  &C_CLEAR
                  @ 21, 0
                  &C_MESSAGE
                  @ 21, 20 SAY 'Press <A> to Abort, any key to continue.' GET confirm PICTURE '!'
                  READ
                  IF confirm='A'
                     close data
                     set cent off
                     RETURN
                  ENDIF
                  &C_CLEAR
                  @ 9, 1 CLEAR TO 19, 78
                  &C_LIST
                  row= 9
                  STORE 0.00 TO stl1, stl2, stl3, stl4
               ENDIF
            ENDDO
            SELECT 1
            IF EOF()
               EXIT
            ELSE
               SKIP
            ENDIF
         ENDDO
      CASE choice='P'
         do testprt
         pg= 1
         row= 56
         STORE 0.00 TO stl1, stl2, stl3, stl4, gtl1, gtl2, gtl3, gtl4
         &C_MESSAGE
         @ 23, 50 SAY '...Printing'
         SET CONSOLE OFF
         SET DEVICE TO PRINTER
         SET PRINTER ON
         ?? CHR(27)+CHR(64)
         ?? CHR(18)
         cdate= CMONTH(mfield06)+' '+STR(DAY(mfield06),2)+', '+STR(YEAR(mfield06),4)
         head= 'Statement of Accounts'
         head1= 'as of '+cdate
         DO CASE
            * CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield02))<>0.and.LEN(TRIM(mfield03))<>0
            *    head1= 'for Territory = '+TRIM(mfield01)+', Area Code = '+TRIM(mfield02)+' and Price Category = '+TRIM(mfield03)
            CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield02))<>0
               head1= 'for Territory = '+TRIM(mfield01)+' and Area Code = '+TRIM(mfield02)
            * CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield03))<>0
            *    head1= 'for Territory = '+TRIM(mfield01)+' and Price Category = '+TRIM(mfield03)
            * CASE LEN(TRIM(mfield02))<>0.and.LEN(TRIM(mfield03))<>0
            *    head1= 'for Area Code = '+TRIM(mfield02)+' and Price Category = '+TRIM(mfield03)
            CASE LEN(TRIM(mfield01))<>0
               head1= 'for Territory = '+TRIM(mfield01)
            CASE LEN(TRIM(mfield02))<>0
               head1= 'for Area Code = '+TRIM(mfield02)
            * CASE LEN(TRIM(mfield03))<>0
            *    head1= 'for Price Category = '+TRIM(mfield03)
         ENDCASE
         DO WHILE .not. EOF().and.cust_n<=mfield05
            IF row>52.and..not. EOF().and.cust_n<=mfield05
               IF pg>1
                  row= row+1
                  @ row+3, 52 SAY '...continued on page '+LTRIM(STR(pg+1))
                  ?
                  ?? CHR(18)
                  EJECT
                  SET PRINTER OFF
                  SET DEVICE TO SCREEN
                  SET CONSOLE ON
                  &C_CLEAR
                  @ 23, 0
                  confirm= ' '
                  &C_CLEAR
                  @ 23, 0
                  @ 21, 0
                  &C_MESSAGE
                  @ 21, 20 SAY ' Press <A> to Abort, any key to continue. ' GET confirm PICTURE '!'
                  READ
                  IF confirm='A'
                     set cent off
                     close data
                     RETURN
                  ENDIF
                  do testprt
                  &C_CLEAR
                  @ 23, 0
                  &C_MESSAGE
                  @ 23, 50 SAY '...Printing'
                  SET CONSOLE OFF
                  SET DEVICE TO PRINTER
                  SET PRINTER ON
               ENDIF
               pg= pg+1
               row= 1
            ENDIF
            DO WHILE .not. EOF().and.cust_n<=mfield05 
               SELECT 2
               SEEK 'F'+ custfyl->cust_n
               IF .not. EOF()
                  &pBOLD_ON
                  @ row+3, (80-LEN(company))/2 SAY company
                  &PBOLD_OFF
                  @ row+4, (80-LEN(head))/2 SAY head
                  row= row+7
                  &pBOLD_ON
                  @ row+1, 5 SAY cust_m PICTURE '@!'
                  &pBOLD_OFF
                  @ row+2, 5 SAY  custfyl->cust_ad PICTURE '@!'
                  @ row+3, 5 SAY  custfyl->cust_ct PICTURE '@!'
                  @ row+6, 5 SAY REPLICATE('-',70)
                  &pBOLD_ON
                  @ row+7, 5 SAY 'SI-NO.        SI-DATE       TERMS      ORIGINAL-AMT.           BALANCE'
                  &pBOLD_OFF
                  @ row+8, 5 SAY REPLICATE('-',70)
                  row= row+9
               ENDIF
               DO WHILE .not. EOF().and.paid='F'.and.cust_n= custfyl->cust_n .AND. INV_D<=MFIELD06
                  IF status<>'C'
                     @ row, 5 SAY inv_n PICTURE '@!'
                     @ row, 19 SAY inv_d
                     IF cust_t<>0
                        @ row, 31 SAY cust_t PICTURE '###'
                        @ row, 35 SAY 'days'
                     ENDIF
                     @ row, 43 SAY net_a PICTURE '###,###,###.##'
                     @ row, 61 SAY inv_bal PICTURE '###,###,###.##'
                  ENDIF
                  IF status<>'C'.and.(post_d<CTOD('01/01/01').or.post_d=CTOD('  /  /  '))
                     stl1= stl1+inv_bal
                     gtl1= gtl1+inv_bal
                  ENDIF
                  IF status<>'C'.and.post_d>CTOD('01/01/01')
                     DO CASE
                        CASE mfield06-inv_d<30
                           stl1= stl1+inv_bal
                           gtl1= gtl1+inv_bal
                        CASE mfield06-inv_d<60
                           stl2= stl2+inv_bal
                           gtl2= gtl2+inv_bal
                        CASE mfield06-inv_d<90
                           stl3= stl3+inv_bal
                           gtl3= gtl3+inv_bal
                        OTHERWISE
                           stl4= stl4+inv_bal
                           gtl4= gtl4+inv_bal
                     ENDCASE
                  ENDIF
                  row= row+1
                  SKIP
               ENDDO
               IF .not. EOF()
                  @ row+0, 61 SAY '--------------'
                  &pBOLD_ON
                  @ row+1, 50 SAY 'Total ...'
                  @ row+1, 61 SAY stl1+stl2+stl3+stl4 PICTURE '###,###,###.##'
                  &pBOLD_OFF
                  @ row+2, 61 SAY '=============='
                  row= row+3
                  @ row+1, 50 SAY '01-30 Days'
                  @ row+1, 61 SAY stl1 PICTURE '###,###,###.##'
                  @ row+2, 50 SAY '31-60 Days'
                  @ row+2, 61 SAY stl2 PICTURE '###,###,###.##'
                  @ row+3, 50 SAY '61-90 Days'
                  @ row+3, 61 SAY stl3 PICTURE '###,###,###.##'
                  @ row+4, 50 SAY '  +90 Days'
                  @ row+4, 61 SAY stl4 PICTURE '###,###,###.##'
                  row= 1
                  STORE 0.00 TO stl1, stl2, stl3, stl4
                  ?? CHR(18)
                  EJECT
                  SET PRINTER OFF
                  SET DEVICE TO SCREEN
                  SET CONSOLE ON
                  &C_CLEAR
                  @ 23, 0
                  confirm= ' '
                  &C_CLEAR
                  @ 23, 0
                  @ 21, 0
                  &C_MESSAGE
                  @ 21, 20 SAY ' Press <A> to Abort, any key to continue. ' GET confirm PICTURE '!'
                  READ
                  IF confirm='A'
                     close data
                     set cent off
                     RETURN
                  ENDIF
                  do testprt
                  &C_CLEAR
                  @ 23, 0
                  &C_MESSAGE
                  @ 23, 50 SAY '...Printing'
                  SET CONSOLE OFF
                  SET DEVICE TO PRINTER
                  SET PRINTER ON
               ENDIF
               SELECT 1
               SKIP
               IF EOF()
                  EXIT
               ENDIF
            ENDDO
            ?
            ?? CHR(18)
            EJECT
            SET PRINTER OFF
            SET DEVICE TO SCREEN
            SET CONSOLE ON
            &C_CLEAR
            @ 23, 0
         ENDDO
   ENDCASE
   &C_CLEAR
   @ 21, 0
   &C_MESSAGE
   confirm= ' '
   DO WHILE .not. confirm$'YN'
      @ 21, 23 SAY ' Return to Previous Menu (y/n). ' GET confirm PICTURE '!'
      READ
   ENDDO
   IF confirm='N'
      &C_CLEAR
      @ 9, 1 CLEAR TO 19, 78
      @ 21, 0
      row= 9
      LOOP
   ELSE
      close data
      set cent off
      RETURN
   ENDIF
ENDDO

set cent off
close data
return

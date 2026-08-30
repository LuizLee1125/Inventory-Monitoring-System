* program.....: LstPurF.prg
*             : purchase form; called from stock inquiry

SELECT 3
   USE BOREC INDEX BO_ID
SELECT 2
   USE STKREC INDEX SI_ID
mtempfyl1= mtempfyl-'.DBF'
mtempfyl2= mtempfyl-'.IDX'
COPY FILE STKFYL.DBF TO &mTEMPFYL1
COPY FILE STK_N.IDX  TO &mTEMPFYL2

SELECT 1
   USE &mTEMPFYL INDE &mTEMPFYL EXCL
DO BRDR2
*                   1         2         3         4         5         6
*           23456789012345678901234567890123456789012345678901234567890123456789012345678901
@ 8, 2 SAY 'STOCK CODE   EXP.DATE  PRICE-C LAST-PUR  QTY-PUR QTY-SLD  QTY-BO   AVAIL UNIT'

DO WHILE .T.
   &C_BODY
   mfield01= SPACE(10)
   mfield02= SPACE(5)
   mfield03= SPACE(5)
   mfield04= SPACE(10)
   mfield05= SPACE(10)
   @ 4, 2 SAY 'Supplier :'
   @ 5, 2 SAY 'Category :'
   @ 6, 2 SAY 'Division :'
   @ 4, 46 SAY 'Start At Stock Code :'
   @ 5, 46 SAY 'Stop  At Stock Code :'
   DO WHILE .T.
      &C_GET
      @ 4, 13 GET mfield01 PICTURE '@!'
      @ 5, 13 GET mfield02 PICTURE '@!'
      @ 6, 13 GET mfield03 PICTURE '@!'
      READ
      SET FILTER TO
      DO CASE
         CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield02))<>0.and.LEN(TRIM(mfield03))<>0
            SET FILTER TO splyr_n=mfield01.and.stk_cat=mfield02.and.stk_dv=mfield03
         CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield02))<>0
            SET FILTER TO splyr_n=mfield01.and.stk_cat=mfield02
         CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield03))<>0
            SET FILTER TO splyr_n=mfield01.and.stk_dv=mfield03
         CASE LEN(TRIM(mfield02))<>0.and.LEN(TRIM(mfield03))<>0
            SET FILTER TO stk_cat=mfield02.and.stk_dv=mfield03
         CASE LEN(TRIM(mfield01))<>0
            SET FILTER TO splyr_n=mfield01
         CASE LEN(TRIM(mfield02))<>0
            SET FILTER TO stk_cat=mfield02
         CASE LEN(TRIM(mfield03))<>0
            SET FILTER TO stk_dv=mfield03
      ENDCASE
      DO WHILE .T.
         GOTO BOTTOM
         mfield05= stk_n
         GOTO TOP
         mfield04= stk_n
         &C_GET
         @ 5, 68 SAY mfield05
         @ 4, 68 GET mfield04 PICTURE '@!'
         READ
         IF READKEY()=4.or.READKEY()=260
            EXIT
         ENDIF
         IF LEN(TRIM(mfield04))=0
            CLOSE DATA
            RETURN
         ELSE
            SEEK LTRIM(TRIM(mfield04))
         ENDIF
         IF EOF()
            choice= ' '
            &C_CLEAR
            @ 21, 0 CLEAR
            &C_MESSAGE
            @ 23, 30 SAY ' No Such Stock Code. '
            &C_GET
            @ 21, 20 SAY ' Press <A> to Abort, any key to Continue. ' GET choice PICTURE '!'
            READ
            IF choice='A'
               CLOSE DATA
               RETURN
            ELSE
               &C_CLEAR
               @ 21, 0
               @ 23, 0
               LOOP
            ENDIF
            mfield04= stk_n
            @ 4, 68 SAY mfield04
         ENDIF
         @ 5, 68 GET mfield05 PICTURE '@!'
         READ
         IF mfield05=SPACE(10)
            CLOSE DATA
            RETURN
         ELSE
            SEEK LTRIM(TRIM(mfield05))
         ENDIF
         IF EOF()
            choice= ' '
            &C_CLEAR
            @ 21, 0 CLEAR
            &C_MESSAGE
            @ 23, 30 SAY ' No Such Stock Code. '
            &C_GET
            @ 21, 20 SAY ' Press <A> to Abort, any key to Continue. ' GET choice PICTURE '!'
            READ
            IF choice='A'
               CLOSE DATA
               RETURN
            ELSE
               &C_CLEAR
               @ 21, 0
               @ 23, 0
               LOOP
            ENDIF
            mfield05= stk_n
            @ 5, 68 SAY mfield05
         ENDIF
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
         &C_CLEAR
         @ 9, 1 CLEAR TO 19, 78
         flag= 1
         row= 9
         DO WHILE .not. EOF().and.stk_n<=mfield05
            IF flag=1
               c_list= c_option
               flag= 0
            ELSE
               c_list= c_body
               flag= 1
            ENDIF
            &C_LIST
            @ row,  2 SAY stk_n    PICTURE '@!'
            if dtoc(expiry_d)<>" "
               set cent on
               @ row, 15 say left(dtoc(expiry_d),2)+'/'+right(dtoc(expiry_d),4)
               set cent off
            endif 
           *@ row, 14 SAY expiry_d PICTURE '99/99/99'
            @ row, 23 SAY prys_c   PICTURE '##,###.##'
            @ row, 33 SAY stk_lt   PICTURE '99/99/99'
            mstk_n= stk_n
            mstk_lt= stk_lt
            key= mstk_n+str(year(mstk_lt),4)+SUBSTR(DTOC(mstk_lt),1,5)
            SELECT 2
            set cent on
            SEEK key
            set cent off
            IF EOF()
               SEEK mstk_n
               DO CASE
                  CASE mstk_lt<issue_d
                     mstk_lt= issue_d
                  CASE mstk_lt>issue_d
                     DO WHILE .not. EOF().and.mstk_n=stk_n.and.mstk_lt>=issue_d
                        SKIP
                     ENDDO
                     mstk_lt= issue_d
               ENDCASE
               key= mstk_n+str(year(mstk_lt),4)+SUBSTR(DTOC(mstk_lt),1,5)
               set cent on
               SEEK key
               set cent off
               @ row, 41 SAY '*'
            ENDIF
            STORE 0 TO stl1, stl2
            DO WHILE .not. EOF().and.mstk_n=stk_n
               DO CASE
                  CASE trans_c='P'
                     stl1= stl1+issue_q*qty_pq
                     @ row, 43 SAY stl1 PICTURE '###,###'
                  CASE trans_c='S'
                     stl2= stl2+issue_q
                     @ row, 51 SAY stl2 PICTURE '###,###'
               ENDCASE
               SKIP
            ENDDO
            SELECT 1
            mstk_n= stk_n
            mstk_lt= stk_lt
            key= mstk_n+str(year(mstk_lt),4)+SUBSTR(DTOC(mstk_lt),1,5)
            SELECT 3
            set cent on
            SEEK key
            set cent off
            IF EOF()
               SEEK mstk_n
               DO CASE
                  CASE mstk_lt<issue_d
                     mstk_lt= issue_d
                  CASE mstk_lt>issue_d
                     DO WHILE .not. EOF().and.mstk_n=stk_n.and.mstk_lt>=issue_d
                        SKIP
                     ENDDO
                     mstk_lt= issue_d
               ENDCASE
               key= mstk_n+str(year(mstk_lt),4)+SUBSTR(DTOC(mstk_lt),1,5)
               set cent on
               SEEK key
               set cent off
            ENDIF
            STORE 0 TO stl3
            DO WHILE .not. EOF().and.mstk_n=stk_n
               stl3= stl3+issue_fg
               @ row, 59 SAY stl3 PICTURE '###,###'
               SKIP
            ENDDO
            SELECT 1
            @ row, 67 SAY qty1+qty2+qty3 PICTURE '###,###'
            @ row, 75 SAY qty_u PICTURE '@!'
            row= row+1
            SKIP
            IF row=19.and..not. EOF()
               choice= ' '
               &C_CLEAR
               @ 21, 0
               &C_MESSAGE
               @ 21, 20 SAY 'Press <A> to Abort, any key to continue.' GET choice PICTURE '!'
               READ
               IF choice='A'
                  CLOSE DATA
                  RETURN
               ENDIF
               &C_CLEAR
               @ 9, 1 CLEAR TO 19, 78
               row= 9
            ENDIF
         ENDDO
      CASE choice='P'
         do testprt
         pg= 1
         DO WHILE .T.
            &C_MESSAGE
            @ 23, 50 SAY '...Printing'
            SET CONSOLE OFF
            SET DEVICE TO PRINTER
            SET PRINTER ON
            ?? CHR(27)+CHR(64)
            ?? CHR(18)
            cdate= CMONTH(DATE())+' '+STR(DAY(DATE()),2)+', '+STR(YEAR(DATE()),4)
            head= 'Purchase Form for '+cdate
            head1= ' '
            DO CASE
               CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield02))<>0.and.LEN(TRIM(mfield03))<>0
                  head1= 'for Supplier = '+TRIM(mfield01)+', Category = '+TRIM(mfield02)+' and Division = '+TRIM(mfield03)
               CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield02))<>0
                  head1= 'for Supplier = '+TRIM(mfield01)+'and Category = '+TRIM(mfield02)
               CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield03))<>0
                  head1= 'for Supplier = '+TRIM(mfield01)+'and Division = '+TRIM(mfield03)
               CASE LEN(TRIM(mfield02))<>0.and.LEN(TRIM(mfield03))<>0
                  head1= 'for Category = '+TRIM(mfield02)+'and Division = '+TRIM(mfield03)
               CASE LEN(TRIM(mfield01))<>0
                  head1= 'for Supplier = '+TRIM(mfield01)
               CASE LEN(TRIM(mfield02))<>0
                  head1= 'for Category = '+TRIM(mfield02)
               CASE LEN(TRIM(mfield03))<>0
                  head1= 'for Division = '+TRIM(mfield03)
            ENDCASE
            @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
            @ 1, (80-LEN(company))/2 SAY company
            @ 2, (80-LEN(head))/2 SAY head
            IF LEN(TRIM(head1))<>0
               @ 3, (80-LEN(head1))/2 SAY head1
            ENDIF
            ?? CHR(15)
            @ 5, 1 SAY REPLICATE('-',129)
            @ 6, 1 SAY 'STOCK CODE REMARKS                          CATALOG   PACKING   PUR-COST   PRICE-A LAST-PUR  QTY-PUR QTY-SLD QTY-BkO   AVAIL UNIT'
            @ 7, 1 SAY REPLICATE('-',129)
            row= 7
            DO WHILE .not. EOF().and.stk_n<=mfield05
               row= row+1
               @ row, 1 SAY stk_n PICTURE '@!'
               @ row, 12 SAY stk_rem PICTURE '@!'
               @ row, 43 SAY stk_cp PICTURE '##,###.##'
               IF qty_pq<>1
                  @ row, 53 SAY qty_pq PICTURE '#,###'
                  @ row, 58 SAY '/'
                  @ row, 59 SAY qty_pu PICTURE '@!'
               ENDIF
               @ row, 64 SAY stk_pc PICTURE '##,###.##'
               @ row, 74 SAY prys_c PICTURE '##,###.##'
               @ row, 84 SAY stk_lt PICTURE '99/99/99'

               mstk_n= stk_n
               mstk_lt= stk_lt
               key= mstk_n+str(year(mstk_lt),4)+SUBSTR(DTOC(mstk_lt),1,5)
               SELECT 2
               set cent on
               SEEK key
               set cent off
               IF EOF()
                  SEEK mstk_n
                  DO CASE
                     CASE mstk_lt<issue_d
                        mstk_lt= issue_d
                     CASE mstk_lt>issue_d
                        DO WHILE .not. EOF().and.mstk_n=stk_n.and.mstk_lt>=issue_d
                           SKIP
                        ENDDO
                        mstk_lt= issue_d
                  ENDCASE
                  key= mstk_n+str(year(mstk_lt),4)+SUBSTR(DTOC(mstk_lt),1,5)
                  set cent on
                  SEEK key
                  set cent off
                  @ row, 92 SAY '*'
               ENDIF
               STORE 0 TO stl1, stl2
               DO WHILE .not. EOF().and.mstk_n=stk_n
                  DO CASE
                     CASE trans_c='P'
                        stl1= stl1+issue_q*qty_pq
                     CASE trans_c='S'
                        stl2= stl2+issue_q
                  ENDCASE
                  SKIP
               ENDDO
               SELECT 1
               mstk_n= stk_n
               mstk_lt= stk_lt
               key= mstk_n+str(year(mstk_lt),4)+SUBSTR(DTOC(mstk_lt),1,5)
               SELECT 3
               set cent on
               SEEK key
               set cent off
               IF EOF()
                  SEEK mstk_n
                  DO CASE
                     CASE mstk_lt<issue_d
                        mstk_lt= issue_d
                     CASE mstk_lt>issue_d
                        DO WHILE .not. EOF().and.mstk_n=stk_n.and.mstk_lt>=issue_d
                           SKIP
                        ENDDO
                        mstk_lt= issue_d
                  ENDCASE
                  key= mstk_n+str(year(mstk_lt),4)+SUBSTR(DTOC(mstk_lt),1,5)
                  SEEK key
               ENDIF
               STORE 0 TO stl3
               DO WHILE .not. EOF().and.mstk_n=stk_n
                  stl3= stl3+issue_q
                  SKIP
               ENDDO
               @ row, 94 SAY stl1 PICTURE '###,###'
               @ row, 102 SAY stl2 PICTURE '###,###'
               @ row, 110 SAY stl3 PICTURE '###,###'
               SELECT 1
               @ row, 118 SAY qty1+qty2+qty3 PICTURE '###,###'
               @ row, 126 SAY qty_u PICTURE '@!'
               IF qty2+qty3<>0
                  @ row, 130 SAY '*'
               ENDIF
               SKIP
               IF row>51.and..not. EOF()
                  @ row+3, 107 SAY '...continued on page '+LTRIM(STR(pg+1))
                  ?
                  ?? CHR(18)
                  EJECT
                  SET PRINTER OFF
                  SET DEVICE TO SCREEN
                  SET CONSOLE ON
                  &C_CLEAR
                  @ 23, 0
                  choice= ' '
                  &C_CLEAR
                  @ 23, 0
                  @ 21, 0
                  &C_MESSAGE
                  @ 21, 20 SAY ' Press <A> to Abort, any key to continue. ' GET choice PICTURE '!'
                  READ
                  IF choice='A'
                     CLOSE DATA
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
                  pg= pg+1
                  STORE 0.00 TO stl1, stl2, stl3, stl4
                  @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
                  @ 1, (80-LEN(head))/2 SAY head
                  IF LEN(TRIM(head1))<>0
                     @ 2, (80-LEN(head1))/2 SAY head1
                  ENDIF
                  ?? CHR(15)
                  @ 4, 1 SAY REPLICATE('-',129)
                  @ 5, 1 SAY 'STOCK CODE REMARKS                          CATALOG   PACKING   PUR-COST   PRICE-A LAST-PUR  QTY-PUR QTY-SLD QTY-BkO   AVAIL UNIT'
                  @ 6, 1 SAY REPLICATE('-',129)
                  row= 6
               ENDIF
            ENDDO
            IF EOF().or.stk_n>mfield05
               ?
               ?? CHR(18)
               EJECT
               SET PRINTER OFF
               SET DEVICE TO SCREEN
               SET CONSOLE ON
               &C_CLEAR
               @ 23, 0
               EXIT
            ENDIF
         ENDDO
   ENDCASE
   &C_CLEAR
   @ 21, 0
   &C_MESSAGE
   confirm= ' '
   DO WHILE .not. confirm$'YN'
      @ 21, 24 SAY ' Return to Previous Menu (y/n). ' GET confirm PICTURE '!'
      READ
   ENDDO
   IF confirm='N'
      &C_CLEAR
      @ 9, 1 CLEAR TO 19, 78
      @ 21, 0
      row= 9
      LOOP
   ELSE
      EXIT
   ENDIF
ENDDO

CLOSE DATA
RETURN

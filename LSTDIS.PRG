* program.....: LstDis.prg
*             : distribution record
*             : 11/05/99

SELECT 2
   USE STKFYL INDEX STK_N
SELECT 1
   USE STKREC INDEX TRANS_ID
DO BRDR2
@ 8, 2 SAY 'DATE      TRANS.NO.  C USER NAME  NAME/CODE     PLUS   MINUS QUANTITY'

DO WHILE .T.
   SET CENTURY ON
   &C_HEAD
   @ 20, 1 SAY SPACE(78)
   &C_MESSAGE
   @ 21, 20 SAY ' NOTE: Press <Enter> to Return to Main Menu. '
   &C_BODY
   @ 5, 2 SAY 'Stock Code :'
   @ 5, 45 SAY 'Start At Issued Date :'
   @ 6, 45 SAY 'Stop  At Issued Date :'
   DO WHILE .T.
      &C_GET
      mfield03= SPACE(10)
      @ 5, 15 GET mfield03 PICTURE '@!'
      READ
      IF LEN(TRIM(mfield03))=0
         SET CENTURY OFF
         CLOSE DATA
         RETURN
      ENDIF
      SEEK LTRIM(TRIM(mfield03))
      IF EOF()
         choice= ' '
         &C_CLEAR
         @ 21, 0 CLEAR
         &C_MESSAGE
         @ 23, 18 SAY ' No Recorded Transaction For Such Stock Code. '
         &C_GET
         @ 21, 20 SAY ' Press <A> to Abort, any key to Continue. ' GET choice PICTURE '!'
         READ
         IF choice='A'
            CLOSE DATA
            SET CENTURY OFF
            RETURN
         ELSE
            &C_CLEAR
            @ 21, 0
            @ 23, 0
            LOOP
         ENDIF
      ENDIF
      &C_GET
      mfield03= stk_n
      @ 5, 15 SAY mfield03 PICTURE '@!'
      EXIT
   ENDDO
   DO WHILE .T.
      mtrans_d= CTOD('01/01/1998')
      mfield02= DATE()
      SELECT 2
      SEEK mfield03
      IF .not. EOF()
         mfield01= qty1lu
      ELSE
         mfield01= trans_d
      ENDIF
      SELECT 1
      &C_GET
      @ 6, 68 SAY mfield02 PICTURE '99/99/9999'
      @ 5, 68 GET mfield01 PICTURE '99/99/9999'
      READ
      *SEEK mfield03+SUBSTR(DTOC(mfield01),7,2)+SUBSTR(DTOC(mfield01),1,5)
      SEEK mfield03+STR(YEAR(mfield01),4)+SUBSTR(DTOC(mfield01),1,5)
      IF EOF()
         SEEK mfield03
         DO CASE
            CASE mfield01<trans_d
               mfield01= trans_d
               confirm= ' '
               &C_CLEAR
               @ 21, 0 CLEAR
               &C_MESSAGE
               @ 23, 23 SAY ' Earliest Recorded Date is '+DTOC(mfield01)+'. '
               &C_GET
               @ 21, 20 SAY ' Press <A> to Abort, any key to Continue.' GET confirm PICTURE '!'
               READ
               &C_CLEAR
               @ 21, 0
               @ 23, 0
               IF confirm='A'
                  LOOP
               ENDIF
               &C_GET
               @ 5, 68 SAY mfield01 PICT "99/99/9999"
            CASE mfield01>trans_d
               DO WHILE .not. EOF().and.mfield03=stk_n.and.mfield01>=trans_d
                  SKIP
               ENDDO
               mfield01= trans_d
               confirm= ' '
               &C_CLEAR
               @ 21, 0 CLEAR
               &C_MESSAGE
               @ 23, 23 SAY ' Closest Recorded Date is '+DTOC(mfield01)+'. '
               &C_GET
               @ 21, 20 SAY ' Press <A> to Abort, any key to Continue.' GET confirm PICTURE '!'
               READ
               &C_CLEAR
               @ 21, 0
               @ 23, 0
               IF confirm='A'
                  LOOP
               ENDIF
               &C_GET
               @ 5, 68 SAY mfield01 PICT "99/99/9999"
         ENDCASE
      ENDIF
      @ 6, 68 GET mfield02 PICTURE '99/99/9999'
      READ
      EXIT
   ENDDO
   SET CENTURY OFF
   choice= 'L'
   DO OPTION8
   IF mfield01>mfield02
      mtemp= mfield01
      mfield01= mfield02
      mfield02= mtemp
   ENDIF
   *SEEK mfield03+SUBSTR(DTOC(mfield01),7,2)+SUBSTR(DTOC(mfield01),1,5)
   SEEK mfield03+STR(YEAR(mfield01),4)+SUBSTR(DTOC(mfield01),1,5)
   DO CASE
      CASE choice='L'
         STORE 0.00 TO stl1, stl2, gtl1, gtl2
         &C_CLEAR
         @ 10, 1 CLEAR TO 19, 78
         flag= 1
         row= 9
         DO WHILE .not. EOF().and.trans_d<=mfield02.and.stk_n=mfield03
            IF flag=1
               c_list= c_option
               flag= 0
            ELSE
               c_list= c_body
               flag= 1
            ENDIF
            &C_LIST
            IF mtrans_d<>trans_d
               mtrans_d= trans_d
               @ row, 2 SAY trans_d PICTURE '@!'
            ENDIF
            @ row, 12 SAY trans_n PICTURE '@!'
            @ row, 23 SAY trans_c PICTURE '@!'
            @ row, 25 SAY user_m PICTURE '@!'
            @ row, 36 SAY cust_n PICTURE '@!'
            DO CASE
               CASE trans_c='P'
                  @ row, 47 SAY issue_q*qty_pq PICTURE '###,###'
                  stl1= stl1+issue_q*qty_pq
                  gtl1= gtl1+issue_q*qty_pq
              * CASE trans_c='B'
              *    @ row, 47 SAY issue_q PICTURE '###,###'
              *    stl1= stl1+issue_q
              *    gtl1= gtl1+issue_q
               CASE trans_c='S'
                  @ row, 55 SAY issue_q PICTURE '###,###'
                  stl2= stl2+issue_q
                  gtl2= gtl2+issue_q
            ENDCASE
            @ row, 63 SAY qty1 PICTURE '###,###'
            row= row+1
            SKIP
            IF EOF()
               EXIT
            ENDIF
            IF row=19
               &C_HEAD
               @ 19, 1 SAY SPACE(78)
               @ 19, 10 SAY 'SUB   TOTAL'
               @ 19, 46 SAY stl1 PICTURE '####,###'
               @ 19, 54 SAY stl2 PICTURE '####,###'
               @ 20, 1 SAY SPACE(78)
               @ 20, 10 SAY 'GRAND TOTAL'
               @ 20, 46 SAY gtl1 PICTURE '####,###'
               @ 20, 54 SAY gtl2 PICTURE '####,###'
               choice= ' '
               &C_CLEAR
               @ 21, 0
               &C_MESSAGE
               @ 21, 20 SAY ' Press <A> to Abort, any key to continue.' GET choice PICTURE '!'
               READ
               IF choice='A'
                  SET CENTURY OFF
                  CLOSE DATA
                  RETURN
               ENDIF
               &C_CLEAR
               @ 9, 1 CLEAR TO 19, 78
               row= 9
               STORE 0.00 TO stl1, stl2
            ENDIF
         ENDDO
         &C_HEAD
         @ 19, 1 SAY SPACE(78)
         @ 19, 10 SAY 'SUB   TOTAL'
         @ 19, 46 SAY stl1 PICTURE '####,###'
         @ 19, 54 SAY stl2 PICTURE '####,###'
         @ 20, 1 SAY SPACE(78)
         @ 20, 10 SAY 'GRAND TOTAL'
         @ 20, 46 SAY gtl1 PICTURE '####,###'
         @ 20, 54 SAY gtl2 PICTURE '####,###'
      CASE choice='P'
         do testprt
         pg= 1
         STORE 0.00 TO stl1, stl2, gtl1, gtl2
         DO WHILE .T.
            &C_MESSAGE
            @ 23, 50 SAY '...Printing'
            SET CONSOLE OFF
            SET DEVICE TO PRINTER
            SET PRINTER ON
            ?? CHR(27)+CHR(64)
            ?? CHR(18)
            cdate= CMONTH(DATE())+' '+STR(DAY(DATE()),2)+', '+STR(YEAR(DATE()),4)
            head= 'Transaction Summary of '+LTRIM(TRIM(mfield03))
            head1= 'from '+DTOC(mfield01)+' to '+DTOC(mfield02)
            @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
            @ 1, (80-LEN(company))/2 SAY company
            @ 2, (80-LEN(head))/2 SAY head
            @ 3, (80-LEN(head1))/2 SAY head1
            ?? CHR(27)+'M'
            @ 5, 1 SAY '----------------------------------------------------------------------------------------'
            @ 6, 1 SAY 'CONTROL #  PUR-DATE REC-QTY LOT-NO.         EXP-DATE CUST-CODE  ISSUE-D  ISSUE-Q BALANCE'
            @ 7, 1 SAY '----------------------------------------------------------------------------------------'
            row= 7
            DO WHILE .not. EOF().and.trans_d<=mfield02.and.stk_n=mfield03
               IF trans_c='P'.or.trans_c='S'
                  row= row+1
                  @ row, 1 SAY trans_n PICTURE '@1'
                  DO CASE
                     CASE trans_c='P'
                        @ row, 12 SAY trans_d PICTURE '@!'
                        @ row, 21 SAY issue_q*qty_pq PICTURE '###,###'
                        stl1= stl1+issue_q*qty_pq
                        gtl1= gtl1+issue_q*qty_pq
                     CASE trans_c='S'
                        @ row, 54 SAY cust_n PICTURE '@!'
                        @ row, 65 SAY trans_d PICTURE '@!'
                        @ row, 74 SAY issue_q PICTURE '###,###'
                        stl2= stl2+issue_q
                        gtl2= gtl2+issue_q
                  ENDCASE
                  @ row, 29 SAY lot_n PICTURE '@!'
                  @ row, 45 SAY expiry_d
                  @ row, 82 SAY qty1 PICTURE '###,###'
               ENDIF
               SKIP
               IF EOF().or.trans_d>mfield02.or.stk_n<>mfield03
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
               IF row>52
                  row= row+1
                  @ row+2, 65 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                  @ 21, 20 SAY ' Press <A> to Abort, any key to continue.' GET choice PICTURE '!'
                  READ
                  IF choice='A'
                     SET CENTURY OFF
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
                  stl= 0.00
                  @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
                  @ 1, (80-LEN(head))/2 SAY head
                  IF LEN(TRIM(mfield03))<>0
                     @ 2, (80-LEN(head1))/2 SAY head1
                  ENDIF
                  ?? CHR(27)+'M'
                  @ 5, 1 SAY '----------------------------------------------------------------------------------------'
                  @ 6, 1 SAY 'CONTROL #  PUR-DATE REC-QTY LOT-NO.         EXP-DATE CUST-CODE  ISSUE-D  ISSUE-Q BALANCE'
                  @ 7, 1 SAY '----------------------------------------------------------------------------------------'
                  row= 7
               ENDIF
            ENDDO
            IF EOF().or.trans_d>mfield02.or.stk_n<>mfield03
               EXIT
            ENDIF
         ENDDO
      OTHERWISE
         EXIT
   ENDCASE
   confirm= ' '
   &C_CLEAR
   @ 21, 0
   &C_MESSAGE
   @ 21, 24 SAY ' Return to Previous Menu (y/n). ' GET confirm PICTURE '!'
   READ
   IF confirm='N'
      &C_CLEAR
      @ 9, 1 CLEAR TO 19, 78
      @ 21, 0
      @ 6, 15 SAY SPACE(12)
      row= 9
      LOOP
   ELSE
      EXIT
   ENDIF
ENDDO

CLOSE DATA
SET CENTURY OFF
RETURN

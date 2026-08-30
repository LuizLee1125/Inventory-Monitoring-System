* program.....: LstColC.prg
*             : listing of collections per customer

SELECT 1
   USE COLECREC INDEX COLEC_D, COLEC_N

DO BRDR2
*                   1         2         3         4         5         6         7
*           2345678901234567890123456789012345678901234567890123456789012345678901234567
@ 8, 2 SAY 'COL-DATE   COL-NO.    CUST-CODE  CHECK NUMBER               AMOUNT   CHK-DATE'
*           99/99/9999 1234567890 1234567890 12345678901234567890 1,234,567.99 99/99/9999

set cent on

DO WHILE .T.
   &C_HEAD
   @ 20, 1 SAY SPACE(78)
   &C_MESSAGE
   @ 21, 20 SAY ' NOTE: Press <Enter> to Return to Main Menu. '
   &C_BODY
   @ 5, 3 SAY 'Start At Issued Date :'
   @ 6, 3 SAY 'Stop  At Issued Date :'
   @ 5, 52 SAY 'Customer Code :'
   mcolec_d= CTOD('  /  /    ')
   GOTO BOTTOM
   mfield2= DATE()
   GOTO TOP
   mfield1= CTOD('  /  /    ')
   &C_GET
   @ 6, 26 SAY mfield2 pict '99/99/9999'
   @ 5, 26 GET mfield1 PICT '99/99/9999'
   READ
   IF mfield1=CTOD('  /  /    ')
      close data
      set cent off
      RETURN
   ELSE
      SEEK mfield1
      IF EOF()
         GOTO TOP
         IF mfield1>colec_d
            GOTO BOTTOM
            IF mfield1<colec_d
               SKIP
               DO WHILE EOF()
                  mfield1= mfield1+1
                  SEEK mfield1
               ENDDO
            ENDIF
         ENDIF
         mfield1= colec_d
         confirm= ' '
         &C_CLEAR
         @ 21, 0 CLEAR
         &C_MESSAGE
         @ 23, 23 SAY ' Earliest Recorded Date is '+DTOC(mfield1)+'. '
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
         @ 5, 26 SAY mfield1
      ENDIF
   ENDIF

   stor recno() to atl_recno
   @ 6, 26 GET mfield2 PICTURE '99/99/9999'
   READ
   SEEK mfield2
   IF EOF()
         GOTO atl_recno
         do while .t. .and. .not.eof()
            IF colec_d>mfield2
               exit
            endif
               SKIP
         enddo
         skip -1
         mfield2= colec_d
         confirm= ' '
         &C_CLEAR
         @ 21, 0 CLEAR
         &C_MESSAGE
         @ 23, 23 SAY ' Last Recorded Date is '+DTOC(mfield2)+'. '
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
         @ 6, 26 SAY mfield2 PICT '99/99/9999'
   ENDIF

   mfield3= SPACE(10)
   @ 5, 68 GET mfield3 PICTURE '@!'
   READ
   choice= 'L'
   DO OPTION8
   IF mfield1>mfield2
      mtemp= mfield1
      mfield1= mfield2
      mfield2= mtemp
   ENDIF
   SEEK mfield1
   DO CASE
      CASE choice='L'
         STORE 0.00 TO stl1, stl2, stl3, stl4, gtl1, gtl2, gtl3, gtl4
         &C_CLEAR
         @ 10, 1 CLEAR TO 19, 78
         flag= 1
         row= 9
         SET ORDER TO 2
         DO WHILE .not. EOF().and.colec_d<=mfield2
            IF LEN(TRIM(mfield3))<>0
               IF mfield3<>cust_n
                  SKIP
                  LOOP
               ENDIF
            ENDIF
            IF LEN(TRIM(chk_n))=0
               SKIP
               LOOP
            ENDIF
            IF flag=1
               c_list= c_option
               flag= 0
            ELSE
               c_list= c_body
               flag= 1
            ENDIF
            &C_LIST
            stl1= stl1+chk_a
            gtl1= gtl1+chk_a
            @ row, 2  SAY colec_d PICTURE '99/99/9999'
            @ row, 13 SAY colec_n PICTURE '@!'
            @ row, 24 SAY cust_n  PICTURE '@!'
            @ row, 35 SAY chk_n   PICTURE '@!'
            @ row, 56 SAY chk_a   PICTURE '#,###,###.##'
            @ row, 69 SAY chk_d   PICTURE '99/99/9999'
            row= row+1
            SKIP
            IF EOF()
               EXIT
            ENDIF
            IF row=19
               &C_HEAD
               @ 19, 1  SAY SPACE(78)
               @ 19, 10 SAY 'SUB   TOTAL'
               @ 19, 55 SAY stl1 PICTURE '##,###,###.##'
               @ 20, 1  SAY SPACE(78)
               @ 20, 10 SAY 'GRAND TOTAL'
               @ 20, 54 SAY gtl1 PICTURE '###,###,###.##'
               choice= ' '
               &C_CLEAR
               @ 21, 0
               &C_MESSAGE
               @ 21, 20 SAY ' Press <A> to Abort, any key to continue.' GET choice PICTURE '!'
               READ
               IF choice='A'
                  CLOSE DATA
                  SET CENT OFF
                  RETURN
               ENDIF
               &C_CLEAR
               @ 9, 1 CLEAR TO 19, 78
               row= 9
               STORE 0.00 TO stl1
            ENDIF
         ENDDO
         &C_HEAD
         @ 19, 1  SAY SPACE(78)
         @ 19, 10 SAY 'SUB   TOTAL'
         @ 19, 55 SAY stl1 PICTURE '##,###,###.##'
         @ 20, 1  SAY SPACE(78)
         @ 20, 10 SAY 'GRAND TOTAL'
         @ 20, 54 SAY gtl1 PICTURE '###,###,###.##'
         SET ORDER TO 1
      CASE choice='P'
         do testprt
         pg= 1
         STORE 0.00 TO stl1, gtl1
         DO WHILE .T.
            &C_MESSAGE
            @ 23, 50 SAY '...Printing'
            SET CONSOLE OFF
            SET DEVICE TO PRINTER
            SET PRINTER ON
            ?? CHR(27)+CHR(64)
            ?? CHR(18)
            cdate= CMONTH(DATE())+' '+STR(DAY(DATE()),2)+', '+STR(YEAR(DATE()),4)
            head= 'Collection Summary from '+DTOC(mfield1)+' to '+DTOC(mfield2)
            head1= 'For Customer Code = '+LTRIM(TRIM(mfield3))
            @ 3, 1 SAY 'Page '+LTRIM(STR(pg))
            @ 3, (80-LEN(company))/2 SAY company
            @ 4, (80-LEN(head))/2 SAY head
            IF LEN(TRIM(mfield3))<>0
               @ 5, (80-LEN(head1))/2 SAY head1
            ENDIF
            @ 7, 2 SAY '-----------------------------------------------------------------------------'
            @ 8, 2 SAY 'COL-DATE   COL-NO.    CUST-CODE  CHECK NUMBER               AMOUNT   CHK-DATE'
            @ 9, 2 SAY '-----------------------------------------------------------------------------'
            row= 9
            SET ORDER TO 2
            DO WHILE .not. EOF().and.colec_d<=mfield2
               IF LEN(TRIM(mfield3))<>0
                  IF mfield3<>cust_n
                     SKIP
                     LOOP
                  ENDIF
               ENDIF
               IF LEN(TRIM(chk_n))=0
                  SKIP
                  LOOP
               ENDIF
               stl1= stl1+chk_a
               gtl1= gtl1+chk_a
               row= row+1
               @ row, 2  SAY colec_d PICTURE '99/99/9999'
               @ row, 13 SAY colec_n PICTURE '@!'
               @ row, 24 SAY cust_n  PICTURE '@!'
               @ row, 35 SAY chk_n   PICTURE '@!'
               @ row, 56 SAY chk_a   PICTURE '#,###,###.##'
               @ row, 69 SAY chk_d   PICTURE '99/99/9999'
               SKIP
               IF row>51
                  @ row+1, 55 SAY              '-------------'
                  @ row+2, 55 SAY stl1 PICTURE '##,###,###.##'
                  @ row+3, 54 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                  pg= pg+1
                  STORE 0.00 TO stl1
                  @ 3, 1 SAY 'Page '+LTRIM(STR(pg))
                  @ 3, (80-LEN(head))/2 SAY head
                  IF LEN(TRIM(mfield3))<>0
                     @ 4, (80-LEN(head1))/2 SAY head1
                  ENDIF
                  @ 6, 2 SAY '-----------------------------------------------------------------------------'
                  @ 7, 2 SAY 'COL-DATE   COL-NO.    CUST-CODE  CHECK NUMBER               AMOUNT   CHK-DATE'
                  @ 8, 2 SAY '-----------------------------------------------------------------------------'
                  row= 8
               ENDIF
            ENDDO
            IF EOF().or.colec_d>mfield2
               IF pg>1
                  @ row+1, 54 SAY              '-------------'
                  @ row+2, 54 SAY stl1 PICTURE '##,###,###.##'
                  row= row+2
               ENDIF
               @ row+1, 53 SAY              '--------------'
               @ row+2, 53 SAY gtl1 PICTURE '###,###,###.##'
               @ row+3, 53 SAY              '=============='
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
            IF EOF().or.colec_d>mfield2
               EXIT
            ENDIF
         ENDDO
         SET ORDER TO 1
      OTHERWISE
         close data
         set cent off
         RETURN
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
      row= 9
      LOOP
   ELSE
      close data
      set cent off
      RETURN
   ENDIF
ENDDO

close data
set cent off
return

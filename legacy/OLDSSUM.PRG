* program.....: OldSSum.prg
*             : old sales summary
*             : 12/20/99

SELECT 1
   USE O_SIFYL INDEX OS_SI_D
DO BRDR2
@ 8, 2 SAY 'SI DATE   SI NO.     CUST.CODE     T. AMT.   NET AMT.     T.COST   G.PROFIT'

DO WHILE .T.
   SET CENTURY ON
   &C_HEAD
   @ 20, 1 SAY SPACE(78)
   &C_MESSAGE
   @ 21, 20 SAY ' NOTE: Press <Enter> to Return to Main Menu. '
   &C_BODY
   @ 5, 3 SAY 'Start At Issued Date :'
   @ 6, 3 SAY 'Stop  At Issued Date :'
   minv_d= CTOD('01/01/1998')
   GOTO BOTTOM
   mfield2= DATE()
   GOTO TOP
   mfield1= CTOD('  /  /    ')
   &C_GET
   @ 6, 26 SAY mfield2 PICTURE "99/99/9999"
   @ 5, 26 GET mfield1 PICTURE "99/99/9999"
   READ
   IF mfield1=CTOD('  /  /    ')
      SET CENTURY OFF
      CLOSE DATA
      RETURN
   ELSE
      SEEK mfield1
      IF EOF()
         GOTO TOP
         IF mfield1>inv_d
            GOTO BOTTOM
            IF mfield1<inv_d
               SKIP
               DO WHILE EOF()
                  mfield1= mfield1+1
                  SEEK mfield1
               ENDDO
            ENDIF
         ENDIF
         mfield1= inv_d
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
         @ 5, 26 SAY mfield1 PICT "99/99/9999"
      ENDIF
   ENDIF
   @ 6, 26 GET mfield2 PICTURE '99/99/9999'
   READ
   SEEK mfield2
   IF EOF()
      GOTO BOTTOM
      mfield2= inv_d
      confirm= ' '
      &C_CLEAR
      @ 21, 0 CLEAR
      &C_MESSAGE
      @ 23, 23 SAY ' Latest Recorded Date is '+DTOC(mfield2)+'. '
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
      @ 6, 26 SAY mfield2 PICT "99/99/9999"
   ENDIF
   choice= 'L'
   DO OPTION8
   IF mfield1>mfield2
      mtemp= mfield1
      mfield1= mfield2
      mfield2= mtemp
   ENDIF
   SEEK mfield1
   SET CENTURY OFF
   DO CASE
      CASE choice='L'
         STORE 0.00 TO stl1, stl2, stl3, stl4, gtl1, gtl2, gtl3, gtl4
         &C_CLEAR
         @ 10, 1 CLEAR TO 19, 78
         flag= 1
         row= 9
         DO WHILE .not. EOF().and.inv_d<=mfield2
            IF flag=1
               c_list= c_option
               flag= 0
            ELSE
               c_list= c_body
               flag= 1
            ENDIF
            &C_LIST
            stl1= stl1+inv_a
            stl2= stl2+net_a
            stl3= stl3+inv_c
            stl4= stl4+net_a-inv_c
            gtl1= gtl1+inv_a
            gtl2= gtl2+net_a
            gtl3= gtl3+inv_c
            gtl4= gtl4+net_a-inv_c
            @ row, 2 SAY inv_d PICTURE '@!'
            @ row, 12 SAY inv_n PICTURE '@!'
            @ row, 23 SAY cust_n PICTURE '@!'
            @ row, 34 SAY inv_a PICTURE '###,###.##'
            @ row, 45 SAY net_a PICTURE '###,###.##'
            @ row, 56 SAY inv_c PICTURE '###,###.##'
            @ row, 67 SAY net_a-inv_c PICTURE '###,###.##'
            row= row+1
            SKIP
            IF EOF()
               EXIT
            ENDIF
            IF row=19
               &C_HEAD
               @ 19, 1 SAY SPACE(78)
               @ 19, 10 SAY 'SUB   TOTAL'
               @ 19, 34 SAY stl1 PICTURE '#######.##'
               @ 19, 45 SAY stl2 PICTURE '#######.##'
               @ 19, 56 SAY stl3 PICTURE '#######.##'
               @ 19, 67 SAY stl4 PICTURE '#######.##'
               @ 20, 1 SAY SPACE(78)
               @ 20, 10 SAY 'GRAND TOTAL'
               @ 20, 34 SAY gtl1 PICTURE '##,###,###'
               @ 20, 45 SAY gtl2 PICTURE '##,###,###'
               @ 20, 56 SAY gtl3 PICTURE '##,###,###'
               @ 20, 67 SAY gtl4 PICTURE '##,###,###'
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
               STORE 0.00 TO stl1, stl2, stl3, stl4
            ENDIF
         ENDDO
         &C_HEAD
         @ 19, 1 SAY SPACE(78)
         @ 19, 10 SAY 'SUB   TOTAL'
         @ 19, 34 SAY stl1 PICTURE '#######.##'
         @ 19, 45 SAY stl2 PICTURE '#######.##'
         @ 19, 56 SAY stl3 PICTURE '#######.##'
         @ 19, 67 SAY stl4 PICTURE '#######.##'
         @ 20, 1 SAY SPACE(78)
         @ 20, 10 SAY 'GRAND TOTAL'
         @ 20, 34 SAY gtl1 PICTURE '##,###,###'
         @ 20, 45 SAY gtl2 PICTURE '##,###,###'
         @ 20, 56 SAY gtl3 PICTURE '##,###,###'
         @ 20, 67 SAY gtl4 PICTURE '##,###,###'
      CASE choice='P'
         do testprt
         pg= 1
         STORE 0.00 TO stl1, stl2, stl3, stl4, gtl1, gtl2, gtl3, gtl4
         DO WHILE .T.
            &C_MESSAGE
            @ 23, 50 SAY '...Printing'
            SET CONSOLE OFF
            SET DEVICE TO PRINTER
            SET PRINTER ON
            ?? CHR(27)+CHR(64)
            ?? CHR(18)
            cdate= CMONTH(DATE())+' '+STR(DAY(DATE()),2)+', '+STR(YEAR(DATE()),4)
            head= 'Sales Summary from '+DTOC(mfield1)+' to '+DTOC(mfield2)
            @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
            @ 1, (80-LEN(company))/2 SAY company
            @ 2, (80-LEN(head))/2 SAY head
            ?? CHR(15)
            @ 4, 7 SAY '----------------------------------------------------------------------------------------------------------------------'
            @ 5, 7 SAY 'SI DATE        SI NO.           CUSTOMER CODE       SI AMOUNT         NET AMOUNT         TOTAL COST       GROSS PROFIT'
            @ 6, 7 SAY '----------------------------------------------------------------------------------------------------------------------'
            row= 6
            DO WHILE .not. EOF().and.inv_d<=mfield2
               stl1= stl1+inv_a
               gtl1= gtl1+inv_a
               stl2= stl2+net_a
               gtl2= gtl2+net_a
               stl3= stl3+inv_c
               gtl3= gtl3+inv_c
               stl4= stl4+net_a-inv_c
               gtl4= gtl4+net_a-inv_c
               row= row+1
               IF minv_d<>inv_d
                  minv_d= inv_d
                  @ row, 7 SAY inv_d PICTURE '@!'
               ENDIF
               @ row, 22 SAY inv_n PICTURE '@!'
               @ row, 39 SAY cust_n PICTURE '@!'
               @ row, 56 SAY inv_a PICTURE '#,###,###.##'
               @ row, 75 SAY net_a PICTURE '#,###,###.##'
               @ row, 94 SAY inv_c PICTURE '#,###,###.##'
               @ row, 113 SAY net_a-inv_c PICTURE '#,###,###.##'
               SKIP
               IF row>50
                  @ row+1, 55 SAY REPLICATE('-',70)
                  @ row+2, 55 SAY stl1 PICTURE '##,###,###.##'
                  @ row+2, 74 SAY stl2 PICTURE '##,###,###.##'
                  @ row+2, 93 SAY stl3 PICTURE '##,###,###.##'
                  @ row+2, 112 SAY stl4 PICTURE '##,###,###.##'
                  @ row+4, 101 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                     CLOSE DATA
                     SET CENTURY OFF
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
                  ?? CHR(15)
                  @ 3, 7 SAY '----------------------------------------------------------------------------------------------------------------------'
                  @ 4, 7 SAY 'SI DATE        SI NO.           CUSTOMER CODE       SI AMOUNT         NET AMOUNT         TOTAL COST       GROSS PROFIT'
                  @ 5, 7 SAY '----------------------------------------------------------------------------------------------------------------------'
                  row= 5
               ENDIF
            ENDDO
            IF EOF().or.inv_d>mfield2
               IF pg>1
                  @ row+1, 55 SAY REPLICATE('-',70)
                  @ row+2, 55 SAY stl1 PICTURE '##,###,###.##'
                  @ row+2, 74 SAY stl2 PICTURE '##,###,###.##'
                  @ row+2, 93 SAY stl3 PICTURE '##,###,###.##'
                  @ row+2, 112 SAY stl4 PICTURE '##,###,###.##'
                  row= row+2
               ENDIF
               @ row+1, 55 SAY REPLICATE('=',70)
               @ row+2, 55 SAY gtl1 PICTURE '##,###,###.##'
               @ row+2, 74 SAY gtl2 PICTURE '##,###,###.##'
               @ row+2, 93 SAY gtl3 PICTURE '##,###,###.##'
               @ row+2, 112 SAY gtl4 PICTURE '##,###,###.##'
               @ row+3, 55 SAY REPLICATE('=',70)
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
      OTHERWISE
         SET CENTURY OFF
         CLOSE DATA
         RETURN
   ENDCASE
   choice= ' '
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
      EXIT
   ENDIF
ENDDO
SET CENTURY OFF
CLOSE DATA
RETURN
 

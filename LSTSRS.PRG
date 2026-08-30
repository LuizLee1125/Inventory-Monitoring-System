* program.....: LstSrS.prg
*             : sales return summary
*             : 11/05/99

SELECT 2
   USE STKREC INDEX TRANS_CN
SELECT 1
   USE SRFYL INDEX SR_D
DO BRDR2
*                   1         2         3         4         5         6         7
*           2345678901234567890123456789012345678901234567890123456789012345678901234567
@ 8, 2 SAY 'SR DATE     SR NO.     CUST.CODE     PHARMA 1-4      CONSUMER      NET AMT.'
*           99/99/9999  xxxxxxxxxx xxxxxxxxxx 99,999,999.99 99,999,999.99 99,999,999.99

DO WHILE .T.
   SET CENTURY ON
   &C_HEAD
   @ 20, 1 SAY SPACE(78)
   &C_MESSAGE
   @ 21, 20 SAY ' NOTE: Press <Enter> to Return to Main Menu. '
   &C_BODY
   @ 5, 3 SAY 'Start At Issued Date :'
   @ 6, 3 SAY 'Stop  At Issued Date :'
   @ 5, 57 SAY 'Territory:'
   minv_d= CTOD('01/01/2001')
   GOTO BOTTOM
   mfield2= DATE()
   GOTO TOP
   mfield1= CTOD('  /  /  ')
   &C_GET
   @ 6, 26 SAY mfield2 PICT "99/99/9999"
   @ 5, 26 GET mfield1 PICTURE "99/99/9999"
   READ
   IF mfield1=CTOD('  /  /  ')
      CLOSE DATA
      SET CENTURY OFF
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
   @ 6, 26 GET mfield2 PICTURE "99/99/9999"
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
   SET CENTURY OFF
   SEEK mfield1
   DO CASE
      CASE choice='L'
         STORE 0.00 TO ttl1, ttl2, ttl3, stl1, stl2, stl3, stl4, gtl1, gtl2, gtl3, gtl4
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
            IF LEN(TRIM(mfield3))<>0
               IF mfield3<>cust_s
                  SKIP
                  LOOP
               ENDIF
            ENDIF
            SET CENT ON
            @ row, 2 SAY inv_d PICTURE '99/99/9999'
            SET CENT OFF
            @ row, 14 SAY inv_n  PICTURE '@!'
            @ row, 25 SAY cust_n PICTURE '@!'
            @ row, 67 SAY net_a  PICTURE '###,###.##'
            minv_n= 'R'+inv_n
            STORE 0.00 TO ttl1, ttl2, ttl3
            SELECT 2
            SEEK minv_n
            DO WHILE .not. EOF().and.minv_n=trans_c+trans_n
               DO CASE
                  CASE LEFT(stk_dv,2)='PH'
                     ttl1= ttl1+t_prys
                  CASE stk_dv='CON'
                     ttl2= ttl2+t_prys
               ENDCASE
               @ row, 39 SAY ttl1 PICTURE '###,###.##'
               @ row, 53 SAY ttl2 PICTURE '###,###.##'
               SKIP
            ENDDO
            SELECT 1
            ttl1= ttl1-ttl1*dcount1/100
            ttl1= ttl1-ttl1*dcount2/100
            ttl1= ttl1-ttl1*dcount3/100
            ttl2= ttl2-ttl2*dcount1/100
            ttl2= ttl2-ttl2*dcount2/100
            ttl2= ttl2-ttl2*dcount3/100
            ttl3= ttl3-ttl3*dcount1/100
            ttl3= ttl3-ttl3*dcount2/100
            ttl3= ttl3-ttl3*dcount3/100
            @ row, 39 SAY ttl1 PICTURE '###,###.##'
            @ row, 53 SAY ttl2 PICTURE '###,###.##'
            stl1= stl1+ttl1
            stl2= stl2+ttl2
            stl3= stl3+ttl3
            stl4= stl4+net_a
            gtl1= gtl1+ttl1
            gtl2= gtl2+ttl2
            gtl3= gtl3+ttl3
            gtl4= gtl4+net_a
            row= row+1
            SKIP
            IF EOF()
               EXIT
            ENDIF
            IF row=19
               &C_HEAD
               @ 19, 1 SAY SPACE(78)
               @ 19, 10 SAY 'SUB   TOTAL'
               @ 19, 36 SAY stl1 PICTURE '##,###,###.##'
               @ 19, 50 SAY stl2 PICTURE '##,###,###.##'
               @ 19, 64 SAY stl4 PICTURE '##,###,###.##'
               @ 20, 1 SAY SPACE(78)
               @ 20, 10 SAY 'GRAND TOTAL'
               @ 20, 36 SAY gtl1 PICTURE '##,###,###.##'
               @ 20, 50 SAY gtl2 PICTURE '##,###,###.##'
               @ 20, 64 SAY gtl4 PICTURE '##,###,###.##'
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
         @ 19, 36 SAY stl1 PICTURE '##,###,###.##'
         @ 19, 50 SAY stl2 PICTURE '##,###,###.##'
         @ 19, 64 SAY stl4 PICTURE '##,###,###.##'
         @ 20, 1 SAY SPACE(78)
         @ 20, 10 SAY 'GRAND TOTAL'
         @ 20, 36 SAY gtl1 PICTURE '##,###,###.##'
         @ 20, 50 SAY gtl2 PICTURE '##,###,###.##'
         @ 20, 64 SAY gtl4 PICTURE '##,###,###.##'
      CASE choice='P'
         do testprt
         pg= 1
         STORE 0.00 TO ttl1, ttl2, ttl3, ttl4, stl1, stl2, stl3, stl4, stl5, gtl1, gtl2, gtl3, gtl4, gtl5
         DO WHILE .T.
            &C_MESSAGE
            @ 23, 50 SAY '...Printing'
            SET CONSOLE OFF
            SET DEVICE TO PRINTER
            SET PRINTER ON
            ?? CHR(27)+CHR(64)
            ?? CHR(18)
            cdate= CMONTH(DATE())+' '+STR(DAY(DATE()),2)+', '+STR(YEAR(DATE()),4)
            head= 'Sales Return Summary from '+DTOC(mfield1)+' to '+DTOC(mfield2)
            IF LEN(TRIM(mfield3))<>0
               head1= 'For Territory = '+LTRIM(TRIM(mfield3))
            ENDIF
            @ 3, 1 SAY 'Page '+LTRIM(STR(pg))
            @ 3, (80-LEN(company))/2 SAY company
            @ 4, (80-LEN(head))/2 SAY head
            IF LEN(TRIM(mfield3))<>0
               @ 5, (80-LEN(head1))/2 SAY head1
            ENDIF
            @ 7, 2 SAY '---------------------------------------------------------------------------'
            @ 8, 2 SAY 'SR DATE     SR NO.     CUST.CODE     PHARMA 1-4      CONSUMER      NET AMT.'
            @ 9, 2 SAY '---------------------------------------------------------------------------'

            row= 9
            DO WHILE .not. EOF().and.inv_d<=mfield2
               IF LEN(TRIM(mfield3))<>0
                  IF mfield3<>cust_s
                     SKIP
                     LOOP
                  ENDIF
               ENDIF
               row= row+1
               SET CENT ON
               @ row, 2 SAY inv_d PICTURE '99/99/9999'
               SET CENT OFF
               @ row, 14 SAY inv_n  PICTURE '@!'
               @ row, 25 SAY cust_n PICTURE '@!'
               @ row, 67 SAY net_a  PICTURE '###,###.##'

               minv_n= 'R'+inv_n
               STORE 0.00 TO ttl1, ttl2, ttl3, ttl4
               SELECT 2
               SEEK minv_n
               DO WHILE .not. EOF().and.minv_n=trans_c+trans_n
                  DO CASE
                     CASE LEFT(stk_dv,2)='PH'
                          ttl1= ttl1+t_prys
                     CASE stk_dv='CON'
                          ttl2= ttl2+t_prys
                  ENDCASE
                  SKIP
               ENDDO
               SELECT 1
               ttl1= ttl1-ttl1*dcount1/100
               ttl1= ttl1-ttl1*dcount2/100
               ttl1= ttl1-ttl1*dcount3/100
               ttl2= ttl2-ttl2*dcount1/100
               ttl2= ttl2-ttl2*dcount2/100
               ttl2= ttl2-ttl2*dcount3/100
               ttl3= ttl3-ttl3*dcount1/100
               ttl3= ttl3-ttl3*dcount2/100
               ttl3= ttl3-ttl3*dcount3/100
               ttl4= ttl4-ttl4*dcount1/100
               ttl4= ttl4-ttl4*dcount2/100
               ttl4= ttl4-ttl4*dcount3/100
               @ row, 39 SAY ttl1 PICTURE '###,###.##'
               @ row, 53 SAY ttl2 PICTURE '###,###.##'

               stl1= stl1+ttl1
               gtl1= gtl1+ttl1
               stl2= stl2+ttl2
               gtl2= gtl2+ttl2
               stl3= stl3+ttl3
               gtl3= gtl3+ttl3
               stl4= stl4+net_a
               gtl4= gtl4+net_a
               SKIP
               IF row>50
                  @ row+1, 36 SAY              '-------------'
                  @ row+1, 50 say              '-------------'
                  @ row+1, 64 say              '-------------'
                  @ row+2, 36 SAY stl1 PICTURE '##,###,###.##'
                  @ row+2, 50 SAY stl2 PICTURE '##,###,###.##'
                  @ row+2, 64 SAY stl4 PICTURE '##,###,###.##'
                  @ row+4, 55  SAY '...continued on page '+LTRIM(STR(pg+1))
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
                  STORE 0.00 TO stl1, stl2, stl3, stl4, stl5
                  @ 3, 1 SAY 'Page '+LTRIM(STR(pg))
                  @ 3, (80-LEN(head))/2 SAY head
                  IF LEN(TRIM(mfield3))<>0
                     @ 4, (80-LEN(head1))/2 SAY head1
                  ENDIF
                  @ 6, 2 SAY '---------------------------------------------------------------------------'
                  @ 7, 2 SAY 'SR DATE     SR NO.     CUST.CODE     PHARMA 1-4      CONSUMER      NET AMT.'
                  @ 8, 2 SAY '---------------------------------------------------------------------------'
                  row= 8
               ENDIF
            ENDDO
            IF EOF().or.inv_d>mfield2
               IF pg>1
                  @ row+1, 36 SAY              '-------------'
                  @ row+1, 50 say              '-------------'
                  @ row+1, 64 say              '-------------'
                  @ row+2, 36 SAY stl1 PICTURE '##,###,###.##'
                  @ row+2, 50 SAY stl2 PICTURE '##,###,###.##'
                  @ row+2, 64 SAY stl4 PICTURE '##,###,###.##'
                  row= row+2
               ENDIF
               @ row+1, 36 SAY              '-------------'
               @ row+1, 50 say              '-------------'
               @ row+1, 64 say              '-------------'
               @ row+2, 36 SAY gtl1 PICTURE '##,###,###.##'
               @ row+2, 50 SAY gtl2 PICTURE '##,###,###.##'
               @ row+2, 64 SAY gtl4 PICTURE '##,###,###.##'
               @ row+3, 36 SAY              '============='
               @ row+3, 50 say              '============='
               @ row+3, 64 say              '============='

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
         EXIT
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

CLOSE DATA
SET CENTURY OFF
RETURN

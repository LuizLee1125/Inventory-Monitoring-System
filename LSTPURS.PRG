* program.....: LstPurS.prg
*             : purchase summary
*             : 11/05/99

DO BRDR2
@ 8, 2 SAY 'SI DATE   SI NO.     SUPPLIER   REMARKS             NET AMOUNT  USER'

*save screen to atlscreen
*atlmsg="generate totals only (y/n)  "
*atlopt="N"
*atllen=len(atlmsg)
*set colo to rb/rb
*@ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
*set colo to +w/rb
*@ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
*@ 12,41-atllen/2 say atlmsg
*@ 12,40-atllen/2+len(atlmsg) get atlopt pict "Y" valid atlopt$"YyNn"
*read
*restore screen from atlscreen

*if atlopt="Y"
*   do lstpurst
*   return
*endif


SELECT 1
   USE PURFYL INDEX PUR_D

DO WHILE .T.
   SET CENTURY ON
   &C_HEAD
   @ 20, 1 SAY SPACE(78)
   &C_MESSAGE
   @ 21, 20 SAY ' NOTE: Press <Enter> to Return to Main Menu. '
   &C_BODY
   @ 5, 3 SAY 'Start At Issued Date :'
   @ 6, 3 SAY 'Stop  At Issued Date :'
   @ 5, 52 SAY 'Supplier Code :'
   minv_d= CTOD('01/01/2001')
   GOTO BOTTOM
   mfield2= DATE()
   GOTO TOP
   mfield1= CTOD('  /  /  ')
   &C_GET
   @ 6, 26 SAY mfield2 PICTURE '99/99/9999'
   @ 5, 26 GET mfield1 PICTURE '99/99/9999'
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
         @ 5, 26 SAY mfield1 PICT '99/99/9999'
      ENDIF
   ENDIF
   stor recno() to atl_recno
   @ 6, 26 GET mfield2 PICTURE '99/99/9999'
   READ
   SEEK mfield2
   IF EOF()
         GOTO atl_recno
         do while .t. .and. .not.eof()
            IF inv_d>mfield2
               exit
            endif
               SKIP
         enddo
         skip -1
         mfield2= inv_d
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
   SET CENTURY OFF
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
         STORE 0.00 TO stl1, gtl1
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
               IF mfield3<>splyr_n
                  SKIP
                  LOOP
               ENDIF
            ENDIF
            stl1= stl1+net_a
            gtl1= gtl1+net_a
            @ row, 2 SAY inv_d PICTURE '@!'
            @ row, 12 SAY inv_n PICTURE '@!'
            @ row, 23 SAY splyr_n PICTURE '@!'
            @ row, 34 SAY left(inv_rem,17) PICTURE '@!'
            @ row, 51 SAY net_a PICTURE '##,###,###.##'
            @ row, 66 say User_m
            row= row+1
            SKIP
            IF EOF()
               EXIT
            ENDIF
            IF row=19
               &C_HEAD
               @ 19, 1 SAY SPACE(78)
               @ 19, 10 SAY 'SUB   TOTAL'
               @ 19, 51 SAY stl1 PICTURE '##,###,###.##'
               @ 20, 1 SAY SPACE(78)
               @ 20, 10 SAY 'GRAND TOTAL'
               @ 20, 51 SAY gtl1 PICTURE '##,###,###.##'
               choice= ' '
               &C_CLEAR
               @ 21, 0
               &C_MESSAGE
               @ 21, 20 SAY ' Press <A> to Abort, any key to continue.' GET choice PICTURE '!'
               READ
               IF choice='A'
                  CLOSE DATA
                  SET CENTURY OFF
                  RETURN
               ENDIF
               &C_CLEAR
               @ 9, 1 CLEAR TO 19, 78
               row= 9
               STORE 0.00 TO stl1
            ENDIF
         ENDDO
         &C_HEAD
         @ 19, 1 SAY SPACE(78)
         @ 19, 10 SAY 'SUB   TOTAL'
         @ 19, 51 SAY stl1 PICTURE '##,###,###.##'
         @ 20, 1 SAY SPACE(78)
         @ 20, 10 SAY 'GRAND TOTAL'
         @ 20, 51 SAY gtl1 PICTURE '##,###,###.##'
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
            head= 'Purchase Summary from '+DTOC(mfield1)+' to '+DTOC(mfield2)
            head1= 'For Supplier Code = '+LTRIM(TRIM(mfield3))
            @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
            @ 1, (80-LEN(company))/2 SAY company
            @ 2, (80-LEN(head))/2 SAY head
            IF LEN(TRIM(mfield3))<>0
               @ 3, (80-LEN(head1))/2 SAY head1
            ENDIF
            @ 5, 6 SAY '--------------------------------------------------------------------'
            @ 6, 6 SAY 'PUR-DATE  PUR-NO.     SUPPLIER      TYPE OF TERMS         NET AMOUNT'
            @ 7, 6 SAY '--------------------------------------------------------------------'
            row= 7
            DO WHILE .not. EOF().and.inv_d<=mfield2
               IF LEN(TRIM(mfield3))<>0
                  IF mfield3<>splyr_n
                     SKIP
                     LOOP
                  ENDIF
               ENDIF
               stl1= stl1+net_a
               gtl1= gtl1+net_a
               row= row+1
               IF minv_d<>inv_d
                  minv_d= inv_d
                  @ row, 6 SAY inv_d PICTURE '@!'
               ENDIF
               @ row, 16 SAY inv_n PICTURE '@!'
               @ row, 28 SAY splyr_n PICTURE '@!'
               @ row, 40 SAY splyr_tp PICTURE '@!'
               @ row, 51 SAY splyr_t PICTURE '@Z ###'
               IF splyr_t<>0
                  @ row, 55 SAY 'DAYS'
               ENDIF
               @ row, 61 SAY net_a PICTURE '##,###,###.##'
               SKIP
               IF row>50
                  @ row+1, 61 SAY '------------'
                  @ row+2, 61 SAY stl1 PICTURE '##,###,###.##'
                  @ row+4, 49 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                  IF LEN(TRIM(mfield3))<>0
                     @ 2, (80-LEN(head1))/2 SAY head1
                  ENDIF
                  @ 4, 6 SAY '--------------------------------------------------------------------'
                  @ 5, 6 SAY 'PUR-DATE  PUR-NO.     SUPPLIER      TYPE OF TERMS         NET AMOUNT'
                  @ 6, 6 SAY '--------------------------------------------------------------------'
                  row= 6
               ENDIF
            ENDDO
            IF EOF().or.inv_d>mfield2
               IF pg>1
                  @ row+1, 61 SAY '-------------'
                  @ row+2, 61 SAY stl1 PICTURE '##,###,###.##'
                  row= row+2
               ENDIF
               @ row+1, 61 SAY '-------------'
               @ row+2, 61 SAY gtl1 PICTURE '##,###,###.##'
               @ row+3, 61 SAY '============='
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

SET CENTURY OFF
CLOSE DATA
RETURN

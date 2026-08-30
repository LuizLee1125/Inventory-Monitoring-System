* program.....: Sr_UnApl.prg
*             : 02/03/05
*             : display/printing of SR that are not applied

set cent off

use srfyl index sr_cd

minv_d= CTOD('  /  /    ')
DO BRDR2
*                   1         2         3         4         5         6         7
*           2345678901234567890123456789012345678901234567890123456789012345678901234
@ 8, 2 SAY 'Cust. Code Customer Name                  SR Date    SR No.   Amount    '
*           1234567890 123456789012345678901234567890 99/99/99 1234567890 999,999.99

DO WHILE .T.
   sele 1
   &C_BODY
   mfield01= SPACE(10)
   mfield02= SPACE(10)
   mfield03= SPACE(1)
   mfield04= SPACE(10)
   mfield05= SPACE(10)
   mfield06= DATE()
   @ 4, 2  SAY 'Territory      :'
   @ 5, 2  SAY 'Area Code      :'
   @ 4, 43 SAY 'Start At Customer Code :'
   @ 5, 43 SAY 'Stop  At Customer Code :'
   @ 6,  2 SAY 'Starting Date  :'
   @ 6, 43 SAY 'Ending Date            :'    && *****
   edate=date()                              && *****
   DO WHILE .T.
      &C_GET
      @ 4, 19 GET mfield01 PICTURE '@!'
      @ 5, 19 GET mfield02 PICTURE '@!'
      READ
      IF READKEY()=4.or.READKEY()=261
         LOOP
      ENDIF
      SET FILTER TO
      DO CASE
         CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield02))<>0
            SET FILTER TO cust_s=mfield01.and.cust_ac=mfield02 .and. paid="F"
         CASE LEN(TRIM(mfield01))<>0
            SET FILTER TO cust_s=mfield01 .and. paid="F" 
         CASE LEN(TRIM(mfield02))<>0
            SET FILTER TO cust_ac=mfield02 .and. paid="F"
         otherwise
            set filter to paid="F"
      ENDCASE
      DO WHILE .T.
         GOTO BOTTOM
         mfield05= cust_n
         GOTO TOP
         mfield04= cust_n
         &C_GET
         @ 4, 68 GET mfield04 PICTURE '@!'
         @ 5, 68 GET mfield05 PICTURE '@!'
         READ
         IF LEN(TRIM(mfield04))=0
            close data
            set cent off
            SET EXACT OFF
            RETURN
         ENDIF
         set cent on
         @ 6, 19 GET mfield06 pict '99/99/9999'
         @ 6, 68 GET edate    pict '99/99/9999'   && *****
         READ
         set cent off
         IF READKEY()=4.or.READKEY()=261
            LOOP
         ENDIF
         EXIT
      ENDDO
      IF READKEY()=4.or.READKEY()=261
         LOOP
      ENDIF
      EXIT
   ENDDO
   choice= 'L'
   DO OPTION8

   DO CASE
      CASE choice='L'
         flag= 1
         row=9
         STORE 0.00 TO stl1, gtl1

         DO WHILE .not. EOF() .and.cust_n<=mfield05
            if inv_d>edate .or. inv_d<mfield06
               skip
               loop
            endif

            store cust_n to sv_cust_n
            store cust_m to sv_cust_m
            IF flag=1
               c_list= c_option
            ELSE
               c_list= c_body
            ENDIF
            &C_LIST
            IF ROW>=19
                  confirm= ' '
                  &C_CLEAR
                  @ 21, 0
                  &C_MESSAGE
                  @ 21, 20 SAY 'Press <A> to Abort, any key to continue.' GET confirm PICTURE '!'
                  READ
                  IF confirm='A'
                     close data
                     set cent off
                     SET EXACT OFF
                     RETURN
                  ENDIF
                  &C_CLEAR
                  @ 9, 1 CLEAR TO 19, 78
                  &C_LIST
                  row=9
            ENDIF

            @ row, 02 say cust_n
            @ row, 13 say cust_m

            do while cust_n=sv_cust_n .and. .not. eof()
               if inv_d>edate .or. inv_d<mfield06
                  skip
                  loop
               endif

               IF flag=1
                  c_list= c_option
                  flag= 0
               ELSE
                  c_list= c_body
                  flag= 1
               ENDIF
               &C_LIST

               @ row, 44 say Inv_d   pict '99/99/9999'
               @ row, 55 say Inv_n
               @ row, 66 say Inv_bal pict '999,999.99'
               stl1=stl1 + Inv_bal
               gtl1=gtl1 + Inv_bal
               row=row+1
               skip
               IF ROW>=19
                  confirm= ' '
                  &C_CLEAR
                  @ 21, 0
                  &C_MESSAGE
                  @ 21, 20 SAY 'Press <A> to Abort, any key to continue.' GET confirm PICTURE '!'
                  READ
                  IF confirm='A'
                     close data
                     set cent off
                     SET EXACT OFF
                     RETURN
                  ENDIF
                  &C_CLEAR
                  @ 9, 1 CLEAR TO 19, 78
                  &C_LIST
                  row=9
                  if cust_n<>sv_cust_n
                     IF flag=1
                        c_list= c_option
                        flag= 0
                     ELSE
                        c_list= c_body
                        flag= 1
                     ENDIF
                     &C_LIST
                  else
                     IF flag=1
                        c_list= c_option
                     ELSE
                        c_list= c_body
                     ENDIF
                     &C_LIST
                  endif
                  @ row, 02 say sv_cust_n
                  @ row, 13 say sv_cust_m
               ENDIF
            ENDDO
            * customer break // display customer's totals
            set colo to +bg
            @ row, 58 say "Totals:"
            @ row, 66 say stl1 pict '999,999.99'
            row=row+2
            store 0 to stl1
         Enddo
         &C_HEAD
         @ 19, 1 SAY SPACE(78)
         @ 19, 10 SAY 'GRAND TOTAL'
         @ 19, 64 SAY gtl1 PICTURE '#,###,###.##'

      CASE choice='P'
         do testprt
         pg  = 1
         row = 0
         STORE 0.00 TO stl1, stl2, stl3, stl4, gtl1, gtl2, gtl3, gtl4
         &C_MESSAGE
         @ 23, 50 SAY '...Printing'
         SET CONSOLE OFF
         SET DEVICE TO PRINTER
         SET PRINTER ON
         ?? CHR(27)+CHR(64)
         ?? CHR(18)
         edate2=left(CMONTH(edate),3)+'. '+STR(DAY(edate),2)+', '+STR(YEAR(edate),4)
         cdate= left(CMONTH(mfield06),3)+'. '+STR(DAY(mfield06),2)+', '+STR(YEAR(mfield06),4)
         head= 'Unapplied Sales Return from '+cdate+' to '+edate2
         head1= ' '
         DO CASE
            CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield02))<>0
               head1= 'for Territory = '+TRIM(mfield01)+' and Area Code = '+TRIM(mfield02)
            CASE LEN(TRIM(mfield01))<>0
               head1= 'for Territory = '+TRIM(mfield01)
            CASE LEN(TRIM(mfield02))<>0
               head1= 'for Area Code = '+TRIM(mfield02)
         ENDCASE
         @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
         @ 1, (80-LEN(company))/2 SAY company
         @ 2, (80-LEN(head))/2 SAY head
         IF LEN(TRIM(head1))<>0
            @ 3, (80-LEN(head1))/2 SAY head1
         ENDIF
         @ 5, 2 say "=========================================================================="
         @ 6, 2 SAY 'Cust. Code Customer Name                  SR Date    SR No.         Amount'
         @ 7, 2 say "=========================================================================="
         pg= pg+1
         row=8

         STORE 0.00 TO stl1, gtl1

         DO WHILE .not. EOF() .and.cust_n<=mfield05
            if inv_d>edate .or. inv_d<mfield06
               skip
               loop
            endif

            store cust_n to sv_cust_n
            store cust_m to sv_cust_m
            IF ROW>=54
               @ row+1,54 SAY '...continued on page '+LTRIM(STR(pg))
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
                  close data
                  set cent off
                  SET EXACT OFF
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
               @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
               @ 1, (80-LEN(company))/2 SAY company
               @ 2, (80-LEN(head))/2 SAY head
               IF LEN(TRIM(head1))<>0
                  @ 3, (80-LEN(head1))/2 SAY head1
               ENDIF
               @ 5, 2 say "=========================================================================="
               @ 6, 2 SAY 'Cust. Code Customer Name                  SR Date    SR No.         Amount'
               @ 7, 2 say "=========================================================================="
               pg= pg+1
               row=8
            endif

            @ row, 02 say cust_n
            @ row, 13 say cust_m

            do while cust_n=sv_cust_n .and. .not. eof()
               if inv_d>edate .or. inv_d<mfield06
                  skip
                  loop
               endif

               @ row, 44 say Inv_d   pict '99/99/9999'
               @ row, 55 say Inv_n
               @ row, 66 say Inv_bal pict '999,999.99'
               stl1=stl1 + Inv_bal
               gtl1=gtl1 + Inv_bal
               row=row+1
               skip

               IF ROW>=54
                  @ row+1,54 SAY '...continued on page '+LTRIM(STR(pg))
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
                     close data
                     set cent off
                     SET EXACT OFF
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
                  @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
                  @ 1, (80-LEN(company))/2 SAY company
                  @ 2, (80-LEN(head))/2 SAY head
                  IF LEN(TRIM(head1))<>0
                     @ 3, (80-LEN(head1))/2 SAY head1
                  ENDIF
                  @ 5, 2 say "=========================================================================="
                  @ 6, 2 SAY 'Cust. Code Customer Name                  SR Date    SR No.         Amount'
                  @ 7, 2 say "=========================================================================="
                  pg= pg+1
                  row=8
                  @ row, 02 say sv_cust_n
                  @ row, 13 say sv_cust_m
               endif
            ENDDO
            * customer break // display customer's totals
            set colo to +bg
            @ row, 58 say "Totals:"
            @ row, 66 say stl1 pict '999,999.99'
            row=row+2
            store 0 to stl1
         Enddo
         &C_HEAD
         @ row+1, 49 SAY 'GRAND TOTALS:'
         @ row+1, 64 SAY gtl1 PICTURE '#,###,###.##'
         ?
         ?? CHR(18)
         EJECT
         SET PRINTER OFF
         SET DEVICE TO SCREEN
         SET CONSOLE ON
         &C_CLEAR
         @ 23, 0

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
      row=8
      LOOP
   ELSE
      close data
      set cent off
      SET EXACT OFF
      RETURN
   ENDIF
ENDDO

set cent off
SET EXACT OFF
close data
return

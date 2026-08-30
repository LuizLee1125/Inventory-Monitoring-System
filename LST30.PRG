* program.....: Lst30.prg
*               aging of accounts, current (within 30 days)

set cent off

select 3
   use srfyl index sr_cd
SELECT 2
   USE SIFYL INDEX SI_CD
SELECT 1
   USE CUSTFYL INDEX CUST_N

minv_d= CTOD('  /  /    ')
DO BRDR2
@ 8, 2 SAY 'SI-DATE  SI-NO.           30 DAYS       60 DAYS       90 DAYS  OVER 90 DAYS'

DO WHILE .T.
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
   @ 6,  2 SAY 'Cut-Off Date   :'
   @ 6, 43 SAY 'Ending Date            :'    && *****
   edate=date()                              && *****
   DO WHILE .T.
      &C_GET
      @ 4, 19 GET mfield01 PICTURE '@!'
      SELECT 1
      @ 5, 19 GET mfield02 PICTURE '@!'
      READ
      IF READKEY()=4.or.READKEY()=261
         LOOP
      ENDIF
      SET FILTER TO
      DO CASE
         CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield02))<>0
            SET FILTER TO cust_s=mfield01.and.cust_ac=mfield02
         CASE LEN(TRIM(mfield01))<>0
            SET FILTER TO cust_s=mfield01  
         CASE LEN(TRIM(mfield02))<>0
            SET FILTER TO cust_ac=mfield02 
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
         IF READKEY()=4.or.READKEY()=261
            EXIT
         ENDIF
         IF LEN(TRIM(mfield04))=0
            close data
            set cent off
            SET EXACT OFF
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
               SET EXACT OFF
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
            close data
            set cent off
            SET EXACT OFF
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
               set cent off
               close data
               SET EXACT OFF
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
         IF READKEY()=4.or.READKEY()=261
            LOOP
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
   IF mfield04>mfield05.and.mfield05<>SPACE(10)
      mtemp= mfield04
      mfield04= mfield05
      mfield05= mtemp
   ENDIF
   SEEK mfield04

   DO CASE
      CASE choice='L'
         flag= 1
         row=9
         STORE 0.00 TO stl1, stl2, stl3, stl4, gtl1, gtl2, gtl3, gtl4
         DO WHILE .not. EOF().and.cust_n<=mfield05
            SELECT 2
            SEEK 'F'+ custfyl->cust_n
            if inv_d>edate
               sele 1
               skip
               loop
            endif
            IF .not. EOF()
               IF flag=1
                  c_list= c_option
                  flag= 0
               ELSE
                  c_list= c_body
                  flag= 1
               ENDIF
               &C_LIST
               @ row,  2 SAY cust_n
               @ row, 13 SAY cust_m
               row= row+1
            ELSE
               SELE 1
               IF flag=1
                  c_list= c_option
                  flag= 0
               ELSE
                  c_list= c_body
                  flag= 1
               ENDIF
               &C_LIST

               @ row, 2 SAY cust_n
               @ row, 13 SAY cust_m
               @ row, 50 say "last purchase:"
               @ row, 66 say cust_lt
               row=row+1
               SELE 2
               IF ROW>=19
                  &C_HEAD
                  @ 19, 1 SAY SPACE(78)
                  @ 19, 10 SAY 'SUB   TOTAL'
                  @ 19, 22 SAY stl1 PICTURE '##,###,###.##'
                  @ 19, 36 SAY stl2 PICTURE '##,###,###.##'
                  @ 19, 50 SAY stl3 PICTURE '##,###,###.##'
                  @ 19, 64 SAY stl4 PICTURE '##,###,###.##'
                  @ 20, 1 SAY SPACE(78)
                  @ 20, 10 SAY 'GRAND TOTAL'
                  @ 20, 22 SAY gtl1 PICTURE '##,###,###.##'
                  @ 20, 36 SAY gtl2 PICTURE '##,###,###.##'
                  @ 20, 50 SAY gtl3 PICTURE '##,###,###.##'
                  @ 20, 64 SAY gtl4 PICTURE '##,###,###.##'

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
                  STORE 0.00 TO stl1, stl2, stl3, stl4
               ENDIF
            ENDIF
            DO WHILE .not. EOF().and.paid='F'.and.cust_n= custfyl->cust_n .and. inv_d<=edate && *****
               IF status<>'C'
                  @ row, 2 SAY inv_d
                  @ row, 11 SAY inv_n PICTURE '@!'
               ENDIF
               IF status<>'C'
                  DO CASE
                     CASE (mfield06-inv_d)<31
                        @ row, 22 SAY inv_bal PICTURE '##,###,###.##'
                        stl1= stl1+inv_bal
                        gtl1= gtl1+inv_bal
                    *CASE mfield06-inv_d<60
                    *   @ row, 36 SAY inv_bal PICTURE '##,###,###.##'
                    *   stl2= stl2+inv_bal
                    *   gtl2= gtl2+inv_bal
                    *CASE mfield06-inv_d<90
                    *   @ row, 50 SAY inv_bal PICTURE '##,###,###.##'
                    *   stl3= stl3+inv_bal
                    *   gtl3= gtl3+inv_bal
                    *OTHERWISE
                    *   @ row, 64 SAY inv_bal PICTURE '##,###,###.##'
                    *   stl4= stl4+inv_bal
                    *   gtl4= gtl4+inv_bal
                  ENDCASE
               ENDIF
               row= row+1
               SKIP
               IF row>=19 && .or.cust_n<>custfyl->cust_n
                  &C_HEAD
                  @ 19, 1 SAY SPACE(78)
                  @ 19, 10 SAY 'SUB   TOTAL'
                  @ 19, 22 SAY stl1 PICTURE '##,###,###.##'
                  @ 19, 36 SAY stl2 PICTURE '##,###,###.##'
                  @ 19, 50 SAY stl3 PICTURE '##,###,###.##'
                  @ 19, 64 SAY stl4 PICTURE '##,###,###.##'
                  @ 20, 1 SAY SPACE(78)
                  @ 20, 10 SAY 'GRAND TOTAL'
                  @ 20, 22 SAY gtl1 PICTURE '##,###,###.##'
                  @ 20, 36 SAY gtl2 PICTURE '##,###,###.##'
                  @ 20, 50 SAY gtl3 PICTURE '##,###,###.##'
                  @ 20, 64 SAY gtl4 PICTURE '##,###,###.##'
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
                     SET EXACT OFF
                     RETURN
                  ENDIF
                  &C_CLEAR
                  @ 9, 1 CLEAR TO 19, 78
                  &C_LIST
                  row=9
                  STORE 0.00 TO stl1, stl2, stl3, stl4
               ENDIF
            ENDDO
            row=row+1
            SELECT 1
            IF EOF()
               EXIT
           *ELSE
           *   ***
           *   store cust_n to sv_cust_n
           *   sele 3
           *   seek "F"+sv_cust_n
           *   if found()
           *      if row=8
           *         row=9
           *      endif
           *      @ row,2 say "Sales Return"
           *      row=row+1
           *      do while .not. eof() .and. cust_n=sv_cust_n
           *         @ row,2  say "CM: "
           *         @ row,7  say Inv_n
           *         @ row,19 say "Ref. Inv:"
           *         @ row,29 say RInv_N
           *         @ row,41 say "CM Date:"
           *         @ row,50 say Inv_d
           *         @ row,60 say "Amt:"
           *         @ row,65 say Net_A picture "999,999.99"
           *         row=row+1
           *         skip
           *
           *         if row>=19
           *            &C_HEAD
           *            @ 19, 1 SAY SPACE(78)
           *            @ 19, 10 SAY 'SUB   TOTAL'
           *            @ 19, 22 SAY stl1 PICTURE '##,###,###.##'
           *            @ 19, 36 SAY stl2 PICTURE '##,###,###.##'
           *            @ 19, 50 SAY stl3 PICTURE '##,###,###.##'
           *            @ 19, 64 SAY stl4 PICTURE '##,###,###.##'
           *            @ 20, 1 SAY SPACE(78)
           *            @ 20, 10 SAY 'GRAND TOTAL'
           *            @ 20, 22 SAY gtl1 PICTURE '##,###,###.##'
           *            @ 20, 36 SAY gtl2 PICTURE '##,###,###.##'
           *            @ 20, 50 SAY gtl3 PICTURE '##,###,###.##'
           *            @ 20, 64 SAY gtl4 PICTURE '##,###,###.##'
           * 
           *            confirm= ' '
           *            &C_CLEAR
           *            @ 21, 0
           *            &C_MESSAGE
           *            @ 21, 20 SAY 'Press <A> to Abort, any key to continue.' GET confirm PICTURE '!'
           *            READ
           *            IF confirm='A'
           *               close data
           *               set cent off
           *               SET EXACT OFF
           *               RETURN
           *            ENDIF
           *            &C_CLEAR
           *            @ 9, 1 CLEAR TO 19, 78
           *            &C_LIST
           *            row=9
           *         endif
           *      enddo
           *   endif
           *   sele 1
           *   SKIP
            ENDIF
            skip
         ENDDO

***** printing

      CASE choice='P'
         save screen to atlscreen
         atlmsg="include inactive accounts (y/n)  "
         atlopt="N"
         atllen=len(atlmsg)
         set colo to rb/rb
         @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
         set colo to +w/rb
         @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
         @ 12,41-atllen/2 say atlmsg
         @ 12,40-atllen/2+len(atlmsg) get atlopt pict "Y" valid atlopt$"YyNn"
         read
         restore screen from atlscreen

         * do testprt
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
         head= 'Outstanding Accts as of '+edate2+' / Cut-off: '+cdate
         head1= ' '
         DO CASE
            CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield02))<>0
               head1= 'for Territory = '+TRIM(mfield01)+' and Area Code = '+TRIM(mfield02)+' / Current (Within 30 Days)'
            CASE LEN(TRIM(mfield01))<>0
               head1= 'for Territory = '+TRIM(mfield01)+' / Current (Within 30 Days)'
            CASE LEN(TRIM(mfield02))<>0
               head1= 'for Area Code = '+TRIM(mfield02)+' / Current (Within 30 Days)'
         ENDCASE
         @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
         @ 1, (80-LEN(company))/2 SAY company
         @ 2, (80-LEN(head))/2 SAY head
         IF LEN(TRIM(head1))<>0
            @ 3, (80-LEN(head1))/2 SAY head1
         ENDIF
        *?? CHR(15)
         @ 5, 7 SAY REPLICATE('-',66)
        *               1         2         3         4         5         6         7
        *            78901234567890123456789012345678901234567890123456789012345678901234567890
        *@ 6, 7 SAY 'SI-DATE    DATE-POST  TERM  DATE-DUE   SI-NO.              30 DAYS          60 DAYS          90 DAYS     OVER 90 DAYS'
         @ 6, 7 SAY 'SI-DATE    DATE-POST  TERM  DATE-DUE   SI-NO.       within 30 DAYS'
         @ 7, 7 SAY REPLICATE('-',66)
         pg= pg+1
         row=8

         sele 1
         DO WHILE .not. EOF().and.cust_n<=mfield05
            sele 1
            store cust_n to sv_cust_n
            store cust_m to sv_cust_m
            sele 2
            seek "F"+sv_cust_n
            if inv_d>edate
               sele 1
               skip
               loop
            endif

            if found()
               if inv_d<=mfield06 .and. mfield06-inv_d<30
                  @ row, 7  SAY sv_cust_n
                  @ row, 18 SAY sv_cust_m
                  row= row+1
                  do while .not. eof() .and. cust_n=sv_cust_n .and. inv_d<=mfield06 .and. paid="F" .and. inv_d<=edate && *****
                     if row>53
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
                        * do testprt
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
                        *?? CHR(15)
                        @ 5, 7 SAY REPLICATE('-',66)
                        @ 6, 7 SAY 'SI-DATE    DATE-POST  TERM  DATE-DUE   SI-NO.              30 DAYS'
                        @ 7, 7 SAY REPLICATE('-',66)
                        pg= pg+1
                        row=8
                     endif
                     IF status<>'C' .AND. (mfield06-inv_d)<30
                        IF minv_d<>inv_d
                           minv_d= inv_d
                           @ row, 7 SAY inv_d
                        ENDIF
                        @ row, 18 SAY post_d
                        @ row, 29 SAY cust_t PICTURE '@Z ###'
                        IF post_d>CTOD('01/01/01')
                           @ row, 35 SAY inv_d+cust_t
                        ENDIF
                        @ row, 46 SAY inv_n PICTURE '@!'
                        DO CASE
                           CASE (mfield06-inv_d)<30
                              @ row, 59 SAY inv_bal PICTURE '###,###,###.##'
                              stl1= stl1+inv_bal
                              gtl1= gtl1+inv_bal
                          *CASE mfield06-inv_d<60
                          *   @ row, 76 SAY inv_bal PICTURE '###,###,###.##'
                          *   stl2= stl2+inv_bal
                          *   gtl2= gtl2+inv_bal
                          *CASE mfield06-inv_d<90
                          *   @ row, 93 SAY inv_bal PICTURE '###,###,###.##'
                          *   stl3= stl3+inv_bal
                          *   gtl3= gtl3+inv_bal
                          *OTHERWISE
                          *   @ row, 110 SAY inv_bal PICTURE '###,###,###.##'
                          *   stl4= stl4+inv_bal
                          *   gtl4= gtl4+inv_bal
                        ENDCASE
                     row= row+1
                     ENDIF
                     SKIP
                  enddo
                  @ row, 59   SAY '--------------'
                 *@ row, 76   SAY '--------------'
                 *@ row, 93   SAY '--------------'
                 *@ row, 110  SAY '--------------'
                  @ row+1, 45 SAY 'Sub   Total ...'
                  @ row+1, 59 SAY stl1 PICTURE '###,###,###.##'
                 *@ row+1, 76 SAY stl2 PICTURE '###,###,###.##'
                 *@ row+1, 93 SAY stl3 PICTURE '###,###,###.##'
                 *@ row+1,110 SAY stl4 PICTURE '###,###,###.##'
                  row=row+3
                  srtot=0
                  sele 3
                 *seek "F"+sv_cust_n
                 *if found()
                 *              *    2         3         4         5         6         7         8         9         10        11
                 *   *row= row+3 && 890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
                 *   @ row,18 say "Sales Return:    CM No.      Ref. Inv.   CM Date       Amount"
                 *              *                   1234567890  1234567890  99/99/99  999,999.99
                 *              *                                           total:
                 *   row=row+1
                 *   do while .not. eof() .and. cust_n=sv_cust_n
                 *      @ row, 35 say Inv_n
                 *      @ row, 47 say RInv_n
                 *      @ row, 59 say Inv_d
                 *      @ row, 69 say Net_a pict "999,999.99"
                 *      srtot=srtot+net_a
                 *      skip
                 *      row=row+1
                 *      if row>=54
                 *         @ row+1,102 SAY '...continued on page '+LTRIM(STR(pg))
                 *         ?
                 *         ?? CHR(18)
                 *         EJECT
                 *         SET PRINTER OFF
                 *         SET DEVICE TO SCREEN
                 *         SET CONSOLE ON
                 *         &C_CLEAR
                 *         @ 23, 0
                 *         confirm= ' '
                 *         &C_CLEAR
                 *         @ 23, 0
                 *         @ 21, 0
                 *         &C_MESSAGE
                 *         @ 21, 20 SAY ' Press <A> to Abort, any key to continue. ' GET confirm PICTURE '!'
                 *         READ
                 *         IF confirm='A'
                 *            close data
                 *            set cent off
                 *            SET EXACT OFF
                 *            RETURN
                 *         ENDIF
                 *         * do testprt
                 *         &C_CLEAR
                 *         @ 23, 0
                 *         &C_MESSAGE
                 *         @ 23, 50 SAY '...Printing'
                 *         SET CONSOLE OFF
                 *         SET DEVICE TO PRINTER
                 *         SET PRINTER ON
                 *         @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
                 *         @ 1, (80-LEN(company))/2 SAY company
                 *         @ 2, (80-LEN(head))/2 SAY head
                 *         IF LEN(TRIM(head1))<>0
                 *            @ 3, (80-LEN(head1))/2 SAY head1
                 *         ENDIF
                 *         ?? CHR(15)
                 *         @ 5, 7 SAY REPLICATE('-',117)
                 *         @ 6, 7 SAY 'SI-DATE    DATE-POST  TERM  DATE-DUE   SI-NO.              30 DAYS          60 DAYS          90 DAYS     OVER 90 DAYS'
                 *         @ 7, 7 SAY REPLICATE('-',117)
                 *         pg= pg+1
                 *         row=8
                 *      endif
                 *   enddo
                 *   @ row,59 say "Total:"
                 *   @ row,69 say srtot pict "999,999.99"
                 *   row=row+2
                 *endif
                  if row>53
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
                        * do testprt
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
                        *?? CHR(15)
                        @ 5, 7 SAY REPLICATE('-',66)
                        @ 6, 7 SAY 'SI-DATE    DATE-POST  TERM  DATE-DUE   SI-NO.              30 DAYS'
                        @ 7, 7 SAY REPLICATE('-',66)
                        pg= pg+1
                        row=8
                  endif
                  STORE 0.00 TO stl1, stl2, stl3, stl4
               endif
            else
             
               *suspend
               sele 1
               if row>53
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
                  * do testprt
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
                  ?? CHR(15)
                  @ 5, 7 SAY REPLICATE('-',66)
                  @ 6, 7 SAY 'SI-DATE    DATE-POST  TERM  DATE-DUE   SI-NO.              30 DAYS'
                  @ 7, 7 SAY REPLICATE('-',66)
                  pg= pg+1
                  row=8
               endif
             if atlopt="Y" .or. atlopt="y"
               @ row, 7  SAY cust_n
               @ row, 18 SAY cust_m
               @ row, 48 say "last purchase: "
               set cent on
               @ row, 63 say cust_lt pict "99/99/9999"
               set cent off
               sele 2
               row=row+2
             endif
            endif
            sele 1
            skip
         enddo
         @ row, 59   SAY '--------------'
        *@ row, 76   SAY '--------------'
        *@ row, 93   SAY '--------------'
        *@ row, 110  SAY '--------------'
         @ row+1, 45 SAY 'Grand Total ...'
         @ row+1, 59 SAY gtl1 PICTURE '###,###,###.##'
        *@ row+1, 76 SAY gtl2 PICTURE '###,###,###.##'
        *@ row+1, 93 SAY gtl3 PICTURE '###,###,###.##'
        *@ row+1,110 SAY gtl4 PICTURE '###,###,###.##'
         @ row+2, 59 SAY '=============='
        *@ row+2, 76 SAY '=============='
        *@ row+2, 93 SAY '=============='
        *@ row+2, 110 SAY '=============='
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

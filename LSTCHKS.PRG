* program.....: LstChks.prg
*             : checks listing

SELECT 2
   USE MOVECHKS INDEX MCHK_N
SELECT 1
   USE COLECREC INDEX CHK_DD

DO BRDR2
@ 8, 2 SAY 'COL-DATE COL-NO.    CUST-CODE  CHECK NO.           CHECK-DATE       AMOUNT'

DO WHILE .T.
   &C_HEAD
   @ 20, 1 SAY SPACE(78)
   &C_MESSAGE
   @ 21, 20 SAY ' NOTE: Press <Enter> to Return to Main Menu. '
   &C_BODY
   @ 5, 3 SAY 'Start At Issued Date :'
   @ 6, 3 SAY 'Stop  At Issued Date :'
   @ 5, 57 SAY 'Territory:'
   mchk_dd= CTOD('  /  /    ')
   GOTO BOTTOM
   mfield2= DATE()
   GOTO TOP
   mfield1= CTOD('  /  /    ')
   &C_GET
   set cent on
   @ 6, 26 SAY mfield2
   @ 5, 26 GET mfield1 PICTURE '99/99/9999'
   READ
   IF mfield1=CTOD('  /  /    ')
      set cent on
      close data
      RETURN
   ELSE
      SEEK mfield1
      IF EOF()
         GOTO TOP
         IF mfield1>chk_dd
            GOTO BOTTOM
            IF mfield1<chk_dd
               SKIP
               DO WHILE EOF()
                  mfield1= mfield1+1
                  SEEK mfield1
               ENDDO
            ENDIF
         ENDIF
         mfield1= chk_dd
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
   @ 6, 26 GET mfield2 PICTURE '99/99/9999'
   READ
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
   set cent off
   DO CASE
      CASE choice='L'
         STORE 0.00 TO stl1, stl2, stl3, stl4, gtl1, gtl2, gtl3, gtl4
         &C_CLEAR
         @ 10, 1 CLEAR TO 19, 78
         flag= 1
         row= 9
         DO WHILE .not. EOF().and.chk_dd<=mfield2
            IF LEN(TRIM(mfield3))<>0
               IF mfield3<>cust_s
                  SKIP
                  LOOP
               ENDIF
            ENDIF
            IF LEN(TRIM(chk_n))=0.or.chk_n='CASH'
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
            @ row, 2  SAY colec_d PICTURE '@!'
            @ row, 11 SAY colec_n PICTURE '@!'
            @ row, 22 SAY cust_n  PICTURE '@!'
            @ row, 33 SAY chk_n   PICTURE '@!'
            @ row, 54 SAY chk_d
            @ row, 63 SAY chk_a   PICTURE '##,###,###.##'
            row= row+1
            SKIP
            IF EOF()
               EXIT
            ENDIF
            IF row=19
               &C_HEAD
               @ 19, 1 SAY SPACE(78)
               @ 19, 10 SAY 'SUB   TOTAL'
               @ 19, 63 SAY stl1 PICTURE '##,###,###.##'
               @ 20, 1 SAY SPACE(78)
               @ 20, 10 SAY 'GRAND TOTAL'
               @ 20, 63 SAY gtl1 PICTURE '##,###,###.##'
               choice= ' '
               &C_CLEAR
               @ 21, 0
               &C_MESSAGE
               @ 21, 20 SAY ' Press <A> to Abort, any key to continue.' GET choice PICTURE '!'
               READ
               IF choice='A'
                  close data
                  set cent off
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
         @ 19, 63 SAY stl1 PICTURE '##,###,###.##'
         @ 20, 1 SAY SPACE(78)
         @ 20, 10 SAY 'GRAND TOTAL'
         @ 20, 63 SAY gtl1 PICTURE '##,###,###.##'
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
            head= 'Checks for Deposit from '+DTOC(mfield1)+' to '+DTOC(mfield2)
            head1= 'For Territory = '+LTRIM(TRIM(mfield3))
            @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
            @ 1, (80-LEN(company))/2 SAY company
            @ 2, (80-LEN(head))/2 SAY head
            IF LEN(TRIM(mfield3))<>0
               @ 3, (80-LEN(head1))/2 SAY head1
            ENDIF
            ? CHR(27)+'@'
            ?? CHR(27)+'M'

            @ 5, 0 SAY '------------------------------------------------------------------------------------------------'
            *                     1         2         3         4         5         6         7         8         9
            *           0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456
            @ 6, 0 SAY 'COL-DATE COL-NO.    CUST-CODE  CHECK NO.        CHK-DATE     AMOUNT    TOT AMT NEW DATE REMARKS '
            @ 7, 0 SAY '------------------------------------------------------------------------------------------------'
            *           99/99/99 xxxxxxxxxx xxxxxxxxxx xxxxxxxx-16-xxxx 99/99/99 999,999.99 999,999.99 99/99/99 XXXXXXXX
            *                                                                 99,999,999.99                            
            row= 7
            SV_CHKN=CHK_N
            SV_CUSTN=CUST_N
            totchkamt=0
            custsw=0
            chksw=0
            DO WHILE .not. EOF().and.chk_dd<=mfield2
               IF LEN(TRIM(mfield3))<>0
                  IF mfield3<>cust_s
                     SKIP
                     LOOP
                  ENDIF
               ENDIF
               IF LEN(TRIM(chk_n))=0 .or. .not. "#"$chk_n
                  SKIP
                  LOOP
               ENDIF

               sele 2
               seek sv_chkn
               if found()
                  polddate=old_date
                  pnewdate=new_date
                  premarks=left(remarks,8)
               ELSE
                  PNEWDATE=CTOD("")
                  PREMARKS=""
               endif
               sele 1

               stl1= stl1+chk_a
               gtl1= gtl1+chk_a
               totchkamt=totchkamt+chk_a
               row= row+1

               @ row, 00 SAY colec_d picture '99/99/99'
               @ row, 09 SAY colec_n PICTURE '@!'
               @ row, 20 SAY cust_n  PICTURE '@!'
               @ row, 31 SAY LEFT(chk_n,16)   PICTURE '@!'
               @ row, 48 SAY chk_d
               @ row, 57 SAY chk_a   PICTURE '###,###.##'
               SKIP
               if sv_chkn<>chk_n .or. eof()
                  @ row,68 say totchkamt pict "###,###.##"
                  IF PNEWDATE<>CTOD("")
                     @ row,79 say pnewdate
                  ENDIF
                  @ row,88 say premarks
                  totchkAmt=0
                  sv_chkn=chk_n
               endif
               IF row>50
                  @ row+1, 54 SAY '-------------'
                  @ row+2, 54 SAY stl1 PICTURE '##,###,###.##'
                  @ row+4, 53 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                  ?? CHR(27)+CHR(64)
                  ?? CHR(18)

                  @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
                  @ 1, (80-LEN(head))/2 SAY head
                  IF LEN(TRIM(mfield3))<>0
                     @ 2, (80-LEN(head1))/2 SAY head1
                  ENDIF

                  ? CHR(27)+'@'
                  ?? CHR(27)+'M'
 
                  @ 4, 0 SAY '------------------------------------------------------------------------------------------------'
                  @ 5, 0 SAY 'COL-DATE COL-NO.    CUST-CODE  CHECK NO.        CHK-DATE     AMOUNT    TOT AMT NEW DATE REMARKS '
                  @ 6, 0 SAY '------------------------------------------------------------------------------------------------'
                  row= 6
               ENDIF
            ENDDO
            IF EOF().or.chk_dd>mfield2
               IF pg>1
                  @ row+1, 54 SAY '-------------'
                  @ row+2, 54 SAY stl1 PICTURE '##,###,###.##'
                  row= row+2
               ENDIF
               @ row+1, 54 SAY '-------------'
               @ row+2, 54 SAY gtl1 PICTURE '##,###,###.##'
               @ row+3, 54 SAY '============='
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
            IF EOF().or.chk_dd>mfield2
               EXIT
            ENDIF
         ENDDO
      OTHERWISE
         set cent off
         close data
         return
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
      set cent off
      close data
      RETURN
   ENDIF
ENDDO

set cent off
close data
return

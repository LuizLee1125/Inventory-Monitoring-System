* program.....: LstCol%5.prg
*             : collection percentage (rem) for Gatepass, Zeny, Teddy
*             : 02-20-2016

SELECT 2
   USE COLECREC INDEX CSI_N
SELECT 1
   USE SIFYL INDEX SI_D

DO BRDR2

DO WHILE .T.
   &C_HEAD
   @ 8, 1 SAY 'SI DATE    SI NO.     CUST-CODE       NET-AMT.     PAID-AMT. COLEC-NO.  DAYS '
   @ 20, 1 SAY SPACE(78)                                                    
   &C_MESSAGE
   @ 21, 20 SAY ' NOTE: Press <Enter> to Return to Main Menu. '
   &C_BODY
   set cent on
   @ 5, 3 SAY 'Start At Issued Date :'
   @ 6, 3 SAY 'Stop  At Issued Date :'
   @ 5, 43 SAY 'G]atepass T]eddy Z]eny:'
   @ 6, 43 SAY 'Colection Cutoff Date :'
   minv_d= CTOD('  /  /    ')
   GOTO BOTTOM
   mfield02= DATE()
   GOTO TOP
   mfield01= CTOD('  /  /  ')
   &C_GET
   @ 6, 26 SAY mfield02 PICTURE '99/99/9999'
   @ 5, 26 GET mfield01 PICTURE '99/99/9999'
   READ
   IF mfield01=CTOD('  /  /    ')
      CLOSE DATA
      SET CENT OFF
      RETURN
   ENDIF
   mfield03= SPACE(1)
   mfield04= CTOD('  /  /  ')
   @ 6, 26 GET mfield02 PICTURE '@!'
   @ 5, 68 GET mfield03 PICTURE '@!'
   @ 6, 68 GET mfield04 PICTURE '@!'
   READ
   choice= 'L'
   DO OPTION8
   IF mfield01>mfield02
      mtemp= mfield01
      mfield01= mfield02
      mfield02= mtemp
   ENDIF
   SET CENT OFF
   DO CASE
      CASE choice='L'
         STORE 0.00 TO stl1, stl2, gtl1, gtl2
         &C_CLEAR
         @ 10, 1 CLEAR TO 19, 78
         flag= 1
         row= 9
         mfielda= mfield01
         SELECT 1
         SEEK mfielda
         IF EOF()
            GOTO TOP
            IF mfielda>inv_d
               GOTO BOTTOM
               IF mfielda<inv_d
                  SKIP
                  DO WHILE EOF()
                     mfielda= mfielda+1
                     SEEK mfielda
                  ENDDO
               ENDIF
            ENDIF
            mfielda= inv_d
         ENDIF
         DO WHILE .not. EOF().and.inv_d<=mfield02
           *IF LEN(TRIM(mfield03))<>0
               *IF mfield03<>cust_s
               IF left(inv_n,1)<>mfield03
                  SKIP
                  LOOP
               ENDIF
           *ENDIF
            IF flag=1
               c_list= c_option
               flag= 0
            ELSE
               c_list= c_body
               flag= 1
            ENDIF
            &C_LIST
            stl1= stl1+net_a
            gtl1= gtl1+net_a
            set cent on
            @ row, 1 SAY inv_d PICTURE '99/99/9999'
            set cent off
            @ row, 12 SAY inv_n PICTURE '@!'
            @ row, 23 SAY cust_n PICTURE '@!'
            @ row, 34 SAY net_a PICTURE '##,###,###.##'
            mflag= '0'
            SELECT 2
            SEEK  sifyl->inv_n
            DO WHILE .not. EOF().and.inv_n= sifyl->inv_n
               IF colec_d<mfield01.or.colec_d>mfield04
                  SKIP
                  LOOP
               ENDIF
               mflag= '1'
               stl2= stl2+colec_a
               gtl2= gtl2+colec_a
               &C_LIST
               @ row, 48 SAY colec_a PICTURE '##,###,###.##'
               @ row, 62 SAY colec_n PICTURE '@!'
               @ row, 73 SAY CTOD(RTRIM(LTRIM(colec_rem)))-inv_d PICTURE '###'
              *@ row, 73 SAY chk_d-inv_d PICTURE '###'
               row= row+1
               SKIP
               IF row=19
                  &C_HEAD
                  @ 19, 1 SAY SPACE(78)
                  @ 19, 10 SAY 'SUB   TOTAL'
                  @ 19, 32 SAY stl1 PICTURE '##,###,###.##'
                  @ 19, 46 SAY stl2 PICTURE '##,###,###.##'
                  @ 20, 1 SAY SPACE(78)
                  @ 20, 10 SAY 'GRAND TOTAL'
                  @ 20, 32 SAY gtl1 PICTURE '##,###,###.##'
                  @ 20, 46 SAY gtl2 PICTURE '##,###,###.##'
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
                  STORE 0.00 TO stl1, stl2
               ENDIF
            ENDDO
            IF mflag='0'
               row= row+1
            ENDIF
            SELECT 1
            SKIP
            IF EOF()
               EXIT
            ENDIF
            IF row=19
               &C_HEAD
               @ 19, 1 SAY SPACE(78)
               @ 19, 10 SAY 'SUB   TOTAL'
               @ 19, 32 SAY stl1 PICTURE '##,###,###.##'
               @ 19, 46 SAY stl2 PICTURE '##,###,###.##'
               @ 20, 1 SAY SPACE(78)
               @ 20, 10 SAY 'GRAND TOTAL'
               @ 20, 32 SAY gtl1 PICTURE '##,###,###.##'
               @ 20, 46 SAY gtl2 PICTURE '##,###,###.##'
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
               STORE 0.00 TO stl1, stl2
            ENDIF
         ENDDO
         &C_HEAD
         @ 19, 1 SAY SPACE(78)
         @ 19, 10 SAY 'SUB   TOTAL'
         @ 19, 32 SAY stl1 PICTURE '##,###,###.##'
         @ 19, 46 SAY stl2 PICTURE '##,###,###.##'
         @ 20, 1 SAY SPACE(78)
         @ 20, 10 SAY 'GRAND TOTAL'
         @ 20, 32 SAY gtl1 PICTURE '##,###,###.##'
         @ 20, 46 SAY gtl2 PICTURE '##,###,###.##'
         &C_BODY
         @ 6, 57 SAY '% COLLECTION : '
         @ 6, 72 SAY gtl2/gtl1*100 PICTURE '###.##'
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
            set cent on
            head= 'Percentage of Collection from '+DTOC(mfield01)+' to '+DTOC(mfield02)
            head1= 'For Start Ref.= '+LTRIM(TRIM(mfield03))+'     Cut-off Date: '+dtoc(mfield04)
            @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
            set cent off
            @ 1, (80-LEN(company))/2 SAY company
            @ 2, (80-LEN(head))/2 SAY head
            IF LEN(TRIM(mfield03))<>0
               @ 3, (80-LEN(head1))/2 SAY head1
            ENDIF
            ?? CHR(15)
            @ 5, 15 SAY '----------------------------------------------------------------------------------------------------'
            @ 6, 15 SAY 'SI DATE    SI NO.     CUST-CODE       NET-AMT.     PAID-AMT. COLEC-DATE COLEC-NO.  CHECK DATE  DAYS '
            @ 7, 15 SAY '----------------------------------------------------------------------------------------------------'
            row= 8                                                                  
            mfielda= mfield01
            SELECT 1
            SEEK mfielda
            IF EOF()
               GOTO TOP
               IF mfielda>inv_d
                  GOTO BOTTOM
                  IF mfielda<inv_d
                     SKIP
                     DO WHILE EOF()
                        mfielda= mfielda+1
                        SEEK mfielda
                     ENDDO
                  ENDIF
               ENDIF
               mfielda= inv_d
            ENDIF
            DO WHILE .not. EOF().and.inv_d<=mfield02
               *IF LEN(TRIM(mfield03))<>0
                  IF left(inv_n,1)<>mfield03
                     SKIP
                     LOOP
                  ENDIF
               *ENDIF
               stl1= stl1+net_a
               gtl1= gtl1+net_a
               set cent on
               @ row, 15 SAY inv_d PICTURE '99/99/9999'
               set cent off
               @ row, 26 SAY inv_n  PICTURE '@!'
               @ row, 37 SAY cust_n PICTURE '@!'
               @ row, 48 SAY net_a PICTURE '##,###,###.##'
               mflag= '0'
               SELECT 2
               SEEK  sifyl->inv_n
               DO WHILE .not. EOF().and.inv_n= sifyl->inv_n
                  IF colec_d<mfield01.or.colec_d>mfield04
                     SKIP
                     LOOP
                  ENDIF
                  mflag= '1'
                  stl2= stl2+colec_a
                  gtl2= gtl2+colec_a                             
                  @ row, 62 SAY colec_a PICTURE '##,###,###.##'
                  SET CENT ON
                  @ row, 76 SAY colec_d PICTURE '99/99/9999'
                  SET CENT OFF
                  @ row, 87 SAY colec_n PICTURE '@!'
                  @ row, 98 SAY colec_rem PICTURE '@!'
                  @ row, 110 SAY CTOD(RTRIM(LTRIM(colec_rem)))-inv_d PICTURE '###'
                 *@ row, 98 SAY chk_d PICTURE '99/99/9999'
                 *@ row, 110 SAY chk_d-inv_d PICTURE '###'

                  row= row+1
                  SKIP
               ENDDO
               IF mflag='0'
                  row= row+1
               ENDIF
               SELECT 1
               SKIP
               IF row>51
                  @ row+1, 48 SAY REPLICATE('-',27)
                  @ row+2, 48 SAY stl1 PICTURE '##,###,###.##'
                  @ row+2, 62 SAY stl2 PICTURE '##,###,###.##'
                  @ row+3, 90 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                     SET CENT OFF
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
                  STORE 0.00 TO stl1, stl2
                  @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
                  @ 1, (80-LEN(head))/2 SAY head
                  IF LEN(TRIM(mfield03))<>0
                     @ 2, (80-LEN(head1))/2 SAY head1
                  ENDIF
                  ?? CHR(15)
                  @ 4, 15 SAY '----------------------------------------------------------------------------------------------------'
                  @ 5, 15 SAY 'SI DATE    SI NO.     CUST-CODE       NET-AMT.     PAID-AMT. COLEC-DATE COLEC-NO.  CHECK DATE  DAYS '
                  @ 6, 15 SAY '----------------------------------------------------------------------------------------------------'
                  row= 7
               ENDIF
            ENDDO
            IF EOF().or.inv_d>mfield02
               IF pg>1
                  @ row+1, 48 SAY REPLICATE('-',27)
                  @ row+2, 48 SAY stl1 PICTURE '##,###,###.##'
                  @ row+2, 62 SAY stl2 PICTURE '##,###,###.##'
                  row= row+2
               ENDIF
               @ row+1, 48 SAY REPLICATE('=',27)
               @ row+2, 48 SAY gtl1 PICTURE '##,###,###.##'
               @ row+2, 62 SAY gtl2 PICTURE '##,###,###.##'
               @ row+3, 48 SAY REPLICATE('=',27)
               @ row+5, 48 SAY 'Percentage of Collection='
               @ row+5, 74 SAY gtl2/gtl1*100 PICTURE '###.##'
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
         CLOSE DATA
         SET CENT OFF
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
      @ 6, 57 SAY '                     '
      @ 9, 1 CLEAR TO 19, 78
      @ 21, 0
      row= 9
      LOOP
   ELSE
      CLOSE DATA
      SET CENT OFF
      RETURN
   ENDIF
ENDDO

SET CENT OFF
CLOSE DATA
RETURN

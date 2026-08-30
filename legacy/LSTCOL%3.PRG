* program.....: LstCol%3.prg
*             : customer accounts status; called from accounts receivables

SELECT 2
   USE COLECREC INDEX CSI_N, colec_n
SELECT 1
   USE SIFYL INDEX SI_D

DO BRDR2

DO WHILE .T.
   &C_HEAD
   *                    1         2         3         4         5         6         7
   *           123456789012345678901234567890123456789012345678901234567890123456789012345678
   @ 8, 1 SAY 'SI Date  Comp. No.  Ref. Inv.  Due Date  Unpaid Amt   Paid Amt. Check No.'
   *           99/99/99 xxxxxxxxxx xxxxxxxxxx 99/99/99  999,999.99  999,999.99 xxxxxxxxxxxxxx'
   @ 20, 1 SAY SPACE(78)                                                    
   &C_MESSAGE
   @ 21, 20 SAY ' NOTE: Press <Enter> to Return to Main Menu. '
   &C_BODY
   set cent on
   @ 5, 3 SAY 'Start At Issued Date :'
   @ 6, 3 SAY 'Stop  At Issued Date :'
   @ 5, 43 SAY '        Customer Code :'
  *@ 6, 43 SAY 'Colection Cutoff Date :'
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
   mfield03= SPACE(10)
   mfield04= CTOD('  /  /  ')
   @ 6, 26 GET mfield02 PICTURE '@!'
   @ 5, 68 GET mfield03 PICTURE '@!'
  *@ 6, 68 GET mfield04 PICTURE '@!'
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
            IF LEN(TRIM(mfield03))<>0
               IF mfield03<>cust_n
                  SKIP
                  LOOP
               ENDIF
            ENDIF
            IF flag=1
               c_list= c_option
               flag= 0
            ELSE
               c_list= c_body
               flag= 1
            ENDIF
            &C_LIST
            @ row,  1 SAY inv_d PICTURE '99/99/99'
            @ row, 10 SAY inv_n  PICTURE '@!'
            atlctr=1
            atlrem=""
            do while atlctr<20
               if subst(si_rem,atlctr,1)$"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
                  exit
               endif
               atlrem=atlrem+subst(si_rem,atlctr,1)
               atlctr=atlctr+1
            enddo
            @ row, 21 say left(atlrem,10) picture '@!'
            @ row, 32 SAY inv_d+30        PICTURE '99/99/99'
            if paid="F"
               @ row, 42 SAY inv_bal PICTURE '###,###.##'
               stl1=stl1+inv_bal
               gtl1=gtl1+inv_bal
            else
               @ row, 54 say inv_pay picture '###,###.##'
               stl2=stl2+inv_pay
               gtl2=gtl2+inv_pay
               SELECT 2
               set order to 1
               SEEK  sifyl->inv_n
               store colec_n to atl_colecn
               set order to 2
               seek atl_colecn
               do while colec_n=atl_colecn
                  if LEN(TRIM(CHK_N))<>0
                     exit
                  endif
                  skip
               enddo
               @ row, 65 say left(chk_n,13) pict "@!"
            endif
            row=row+1
            SELECT 1
            SKIP
            IF row>=19
               &C_HEAD
               @ 19, 1 SAY SPACE(78)
               @ 19, 10 SAY 'SUB   TOTAL'
               @ 19, 41 SAY stl1 PICTURE '####,###.##'
               @ 19, 53 SAY stl2 PICTURE '####,###.##'
               @ 20, 1 SAY SPACE(78)
               @ 20, 10 SAY 'GRAND TOTAL'
               @ 20, 41 SAY gtl1 PICTURE '####,###.##'
               @ 20, 53 SAY gtl2 PICTURE '####,###.##'
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
         @ 19, 41 SAY stl1 PICTURE '####,###.##'
         @ 19, 53 SAY stl2 PICTURE '####,###.##'
         @ 20, 1 SAY SPACE(78)
         @ 20, 10 SAY 'GRAND TOTAL'
         @ 20, 41 SAY gtl1 PICTURE '####,###.##'
         @ 20, 53 SAY gtl2 PICTURE '####,###.##'
      CASE choice='P'
            do testprt
            pg= 1
            STORE 0.00 TO stl1, stl2, gtl1, gtl2
            &C_MESSAGE
            @ 23, 50 SAY '...Printing'
            SET CONSOLE OFF
            SET DEVICE TO PRINTER
            SET PRINTER ON
            ?? CHR(27)+CHR(64)
            ?? CHR(18)
            cdate= CMONTH(DATE())+' '+STR(DAY(DATE()),2)+', '+STR(YEAR(DATE()),4)
            set cent on
            head= "Customer's Transaction Report from "+DTOC(mfield01)+' to '+DTOC(mfield02)
            head1= 'For Customer = '+LTRIM(TRIM(mfield03))
            @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
            set cent off
            @ 1, (80-LEN(company))/2 SAY company
            @ 2, (80-LEN(head))/2 SAY head
            IF LEN(TRIM(mfield03))<>0
               @ 3, (80-LEN(head1))/2 SAY head1
            ENDIF
            @ 5,  1 SAY '----------------------------------------------------------------------------'
            @ 6,  1 SAY 'SI Date  Comp. No.  Ref. Inv.  Due Date  Unpaid Amt   Paid Amt. Check No.'
            @ 7,  1 SAY '----------------------------------------------------------------------------'
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
               IF LEN(TRIM(mfield03))<>0
                  IF mfield03<>cust_n
                     SKIP
                     LOOP
                  ENDIF
               ENDIF
               @ row,  1 SAY inv_d PICTURE '99/99/99'
               @ row, 10 SAY inv_n  PICTURE '@!'
               atlctr=1
               atlrem=""
               do while atlctr<20
                  if subst(si_rem,atlctr,1)$"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
                     exit
                  endif
                  atlrem=atlrem+subst(si_rem,atlctr,1)
                  atlctr=atlctr+1
               enddo
               @ row, 21 say left(atlrem,10) picture '@!'
               @ row, 32 SAY inv_d+30        PICTURE '99/99/99'
               if paid="F"
                  @ row, 42 SAY inv_bal PICTURE '###,###.##'
                  stl1=stl1+inv_bal
                  gtl1=gtl1+inv_bal
               else
                  @ row, 54 say inv_pay picture '###,###.##'
                  stl2=stl2+inv_pay
                  gtl2=gtl2+inv_pay
                  SELECT 2
                  set order to 1
                  SEEK  sifyl->inv_n
                  store colec_n to atl_colecn
                  set order to 2
                  seek atl_colecn
                  do while colec_n=atl_colecn
                     if LEN(TRIM(CHK_N))<>0
                        exit
                     endif
                     skip
                  enddo
                  @ row, 65 say left(chk_n,13) pict "@!"
               endif
               row=row+1
               SELECT 1
               SKIP
               IF row>=51
                  &C_HEAD
                  @ row+1,  1 SAY SPACE(78)
                  @ row+1, 10 SAY 'SUB   TOTAL'
                  @ row+1, 41 SAY stl1 PICTURE '####,###.##'
                  @ row+1, 53 SAY stl2 PICTURE '####,###.##'
                  @ row+2,  1 SAY SPACE(78)
                  @ row+2, 10 SAY 'GRAND TOTAL'
                  @ row+2, 41 SAY gtl1 PICTURE '####,###.##'
                  @ row+2, 53 SAY gtl2 PICTURE '####,###.##'
                  @ row+4, 51 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                  @ 4,  1 SAY '----------------------------------------------------------------------------'
                  @ 5,  1 SAY 'SI Date  Comp. No.  Ref. Inv.  Due Date  Unpaid Amt   Paid Amt. Check No.'
                  @ 6,  1 SAY '----------------------------------------------------------------------------'
                  row= 7                                                                      
               ENDIF
            ENDDO
            @ row+1,  1 SAY SPACE(78)
            @ row+1, 10 SAY 'SUB   TOTAL'
            @ row+1, 41 SAY stl1 PICTURE '####,###.##'
            @ row+1, 53 SAY stl2 PICTURE '####,###.##'
            @ row+2, 1 SAY SPACE(78)
            @ row+2, 10 SAY 'GRAND TOTAL'
            @ row+2, 41 SAY gtl1 PICTURE '####,###.##'
            @ row+2, 53 SAY gtl2 PICTURE '####,###.##'
            EJECT
            SET PRINTER OFF
            SET DEVICE TO SCREEN
            SET CONSOLE ON
            &C_CLEAR
            @ 23, 0
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
       

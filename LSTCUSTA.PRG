* program.....: LstCustA.prg
*             : from AR; customer status

SELECT 1
   USE SIFYL INDEX COLEC_X
   *INDEX ON TRIM(CUST_S)+TRIM(CUST_N)+STR(YEAR(INV_D),4)+SUBSTR(DTOC(INV_D),1,5) TO COLEC_X
SELECT 2
   USE CUSTFYL  INDEX CUST_N

DO BRDR2

            *                      1         2         3         4         5         6         7
            *             1234567890123456789012345678901234567890123456789012345678901234567890123456789
            * @ 8, 1 SAY 'Cust. Code Customer Name                  Last Purch Tot. Purchase Unpaid Amt'
            *             xxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 99/99/9999 99,999,999.99 999,999.99

DO WHILE .T.
   &C_HEAD
   @  8, 1 SAY 'Cust. Code Customer Name                  Last Purch TotalPurchase Unpaid Amt'
   @ 20, 1 SAY SPACE(78)                                                    
   &C_MESSAGE
   @ 21, 20 SAY ' NOTE: Press <Enter> to Return to Main Menu. '
   &C_BODY
   set cent on
   @ 5,  3 SAY 'Start At Issued Date :'
   @ 6,  3 SAY 'Stop  At Issued Date :'
   @ 5, 42 SAY '             Territory :'
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
      set exact off
      RETURN
   ENDIF
   mfield03= SPACE(10)
   @ 6, 26 GET mfield02 PICTURE '99/99/9999'
   @ 5, 68 GET mfield03 PICTURE '@!'      && territory
   READ
   choice= 'L'
   DO OPTION8
   IF mfield01>mfield02
      mtemp= mfield01
      mfield01= mfield02
      mfield02= mtemp
   ENDIF

   SELE 2
   COPY TO TMPCUST FOR CUST_S=TRIM(MFIELD03)
   SELE 3
      USE TMPCUST
   DO CASE
      CASE choice='L'
         STORE 0.00 TO stl1, stl2, gtl1, gtl2
         &C_CLEAR
         @ 10, 1 CLEAR TO 19, 78
         flag= 1
         row= 9 
         mfielda= mfield01
         SELE 3
         DO WHILE .not. EOF()
            store cust_n   to sv_cust_n
            store cust_m   to sv_cust_m
            store cust_lt  to sv_cust_lt
            store cust_pur to sv_cust_pur

            sele 1
            seek TRIM(mfield03)+TRIM(Sv_cust_n)
            store 0 to unpd_amt, cust_sw
            do while .not. eof() .and. cust_n=trim(sv_cust_n)
               if inv_d>=mfield01 .and. inv_d<=mfield02
                  * customer is active for the specified date
                  * just accumulate the balance; "on" the cust. switch
                  store 1 to cust_sw
                  if paid="F"
                     unpd_amt=unpd_amt+inv_bal
                  endif
               else
                  * customer is inactive; check for the balance
                  if paid="F"
                     unpd_amt=unpd_amt+inv_bal
                  endif
               endif
               skip
            enddo
            if cust_sw=1
               sele 3
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
            @ ROW,01 SAY SV_CUST_N PICT '@!'
            @ ROW,12 SAY SV_CUST_M PICT '@!'
            set cent on
            @ row,43 say sv_cust_lt pict '99/99/9999'
            set cent off
            @ row,54 say sv_cust_pur pict '99,999,999.99'
            @ row,68 say unpd_amt   pict '999,999.99'
            stl1=stl1+sv_cust_pur
            stl2=stl2+unpd_amt
            gtl1=gtl1+sv_cust_pur
            gtl2=gtl2+unpd_amt
            ROW=ROW+1
            IF row>=19
               &C_HEAD
               @ 19, 1 SAY SPACE(78)
               @ 19, 10 SAY 'SUB   TOTAL'
               @ 19, 54 SAY stl1 PICTURE '##,###,###.##'
               @ 19, 68 SAY stl2 PICTURE '###,###.##'
               @ 20, 1 SAY SPACE(78)
               @ 20, 10 SAY 'GRAND TOTAL'
               @ 20, 54 SAY gtl1 PICTURE '##,###,###.##'
               @ 20, 68 SAY gtl2 PICTURE '###,###.##'
               choice= ' '
               &C_CLEAR
               @ 21, 0
               &C_MESSAGE
               @ 21, 20 SAY ' Press <A> to Abort, any key to continue.' GET choice PICTURE '!'
               READ
               IF choice='A'
                  CLOSE DATA
                  SET CENT OFF
                  set exact off
                  RETURN
               ENDIF
               &C_CLEAR
               @ 9, 1 CLEAR TO 19, 78
               row= 9
               STORE 0.00 TO stl1, stl2
            ENDIF

            SELECT 3
            SKIP
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
         head= 'Percentage of Collection from '+DTOC(mfield01)+' to '+DTOC(mfield02)
         head1= 'For Territory = '+LTRIM(TRIM(mfield03))+'     Cut-off Date: '+dtoc(mfield04)
         @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
         set cent off
         @ 1, (80-LEN(company))/2 SAY company
         @ 2, (80-LEN(head))/2 SAY head
         IF LEN(TRIM(mfield03))<>0
            @ 3, (80-LEN(head1))/2 SAY head1
         ENDIF
         ?? CHR(15)  
         @ 5, 15 SAY '---------------------------------------------------------------------------------------------------------'
         @ 6, 15 SAY 'Cust. Code  SI No.      Inv. Date       Net Amt.     Paid Amt.  Colec-Date  Colec-No.   Check Date   Days '
         @ 7, 15 SAY '---------------------------------------------------------------------------------------------------------'
         row= 8                                                                  
         mfielda= mfield01

            *****
            SELECT 4 && filtered customer master file per territory
      
            DO WHILE .not. EOF() 
               store cust_n to sv_cust_n
               store cust_m to sv_cust_m
               store cust_lt to sv_cust_lt
               store 1 to cust_sw

               SELECT 5
               LOCA FOR CUST_N=trim(SV_CUST_N)
               IF .NOT. FOUND()
                  if atloption="N"
                     sele 4
                     skip
                     loop
                  endif
                  @ ROW,15 SAY SV_CUST_N PICT '@!'
                  @ ROW,27 SAY SV_CUST_M PICT '@!'
                  @ ROW,67 say "last purchase: "
                  @ row,82 say sv_cust_lt
                  * @ ROW,67 SAY '----------'
                  ROW=ROW+2
                  IF row>51
                     @ row+1, 50 SAY REPLICATE('-',29)
                     @ row+2, 50 SAY stl1 PICTURE '##,###,###.##'
                     @ row+2, 64 SAY stl2 PICTURE '##,###,###.##'
                     @ row+3, 96 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                        set exact off
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
                     @ 4, 15 SAY '---------------------------------------------------------------------------------------------------------'
                     @ 5, 15 SAY 'Cust. Code  SI No.      Inv. Date       Net Amt.     Paid Amt.  Colec-Date  Colec-No.   Check Date   Days '
                     @ 6, 15 SAY '---------------------------------------------------------------------------------------------------------'
                     store 0.00 to stl1, stl2
                     row= 7
                  ENDIF
                  SELECT 4
                  SKIP
                  LOOP
               ENDIF

               * corresponding record is found in tmpsi; 2nd control break

               do while cust_n=trim(sv_cust_n) .and. .not. eof()
                  store inv_n to sv_inv_n
                  if cust_sw=1
                     @ row, 15 say Cust_N pict '@!'
                     cust_sw=2
                  endif
                  @ row, 27 say Inv_N pict '@!'
                  set cent on
                  @ row, 39 say Inv_D pict '99/99/9999'
                  set cent off

                  stl1= stl1+net_a
                  gtl1= gtl1+net_a
                  @ row, 50 SAY net_a PICTURE '##,###,###.##'
            
                  mflag= '0'
                  * locate corresponding record in the collection
   
                  SELECT 2
                  SEEK trim(sv_inv_n)
                  DO WHILE .not. EOF().and.inv_n=trim(sv_inv_n)
                     IF colec_d<mfield01.or.colec_d>mfield04
                        SKIP
                        LOOP
                     ENDIF
                     mflag= '1'
                     stl2= stl2+colec_a
                     gtl2= gtl2+colec_a
                     @ row, 64 SAY colec_a PICTURE '##,###,###.##'
                     SET CENT ON
                     @ row, 79 SAY colec_d picture '99/99/9999'
                     @ row, 91 SAY colec_n PICTURE '@!'
                     @ row,103 SAY CTOD(RTRIM(LTRIM(colec_rem)))   picture '99/99/9999'
                    *@ row,103 SAY chk_dd  picture '99/99/9999'
                     SET CENT OFF
                     @ row,116 SAY CTOD(RTRIM(LTRIM(colec_rem)))-inv_d PICTURE '###'
                    *@ row,116 SAY chk_dd-inv_d PICTURE '###'
                     row= row+1
                     SKIP
                     IF row>51
                        @ row+0, 50 SAY REPLICATE('-',29)
                        @ row+1, 50 SAY stl1 PICTURE '##,###,###.##'
                        @ row+1, 64 SAY stl2 PICTURE '##,###,###.##'
                        @ row+2, 96 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                           set exact off
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
                        @ 4, 15 SAY '---------------------------------------------------------------------------------------------------------'
                        @ 5, 15 SAY 'Cust. Code  SI No.      Inv. Date       Net Amt.     Paid Amt.  Colec-Date  Colec-No.   Check Date   Days '
                        @ 6, 15 SAY '---------------------------------------------------------------------------------------------------------'
                        store 0.00 to stl1, stl2
                        row= 7
                     ENDIF
                  ENDDO
                  IF mflag='0'
                     row= row+1
                  ENDIF
                  SELECT 5
                  SKIP
                  IF EOF()
                     EXIT
                  ENDIF
               ENDDO
               IF row>51
                  @ row+1, 50 SAY REPLICATE('-',29)
                  @ row+2, 50 SAY stl1 PICTURE '##,###,###.##'
                  @ row+2, 64 SAY stl2 PICTURE '##,###,###.##'
                  @ row+3, 96 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                     set exact off
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
                  @ 4, 15 SAY '-----------------------------------------------------------------------------------------------------'
                  @ 5, 15 SAY 'Cust. Code  SI No.      Inv. Date       Net Amt.     Paid Amt. Colec-Date Colec-No.  Check Date  Days '
                  @ 6, 15 SAY '-----------------------------------------------------------------------------------------------------'
                  store 0.00 to stl1, stl2
                  row= 7
               ENDIF
               IF ROW<>9
                  row=row+1
               ENDIF
               SELECT 4
               SKIP
            ENDDO
            @ row+1, 50 SAY REPLICATE('-',29)
            @ row+2, 50 SAY stl1 PICTURE '##,###,###.##'
            @ row+2, 64 SAY stl2 PICTURE '##,###,###.##'
            @ row+3, 50 SAY REPLICATE('=',29)
            @ row+4, 50 SAY gtl1 PICTURE '##,###,###.##'
            @ row+4, 64 SAY gtl2 PICTURE '##,###,###.##'
            @ row+5, 50 SAY REPLICATE('=',29)
            @ row+7, 48 SAY 'Percentage of Collection ='
            @ row+7, 76 SAY gtl2/gtl1*100 PICTURE '###.##'
            @ row+7, 76 SAY gtl2/gtl1*100 PICTURE '###.##'
            ?
            ?? CHR(18)
            EJECT
            SET PRINTER OFF
            SET DEVICE TO SCREEN
            SET CONSOLE ON
            &C_CLEAR
            @ 23, 0
      OTHERWISE
         CLOSE DATA
         SET CENT OFF
         set exact off
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
      close data
      SELECT 1
         USE SIFYL INDEX COLEC_X
         *INDEX ON CUST_S+CUST_N+STR(YEAR(INV_D),4)+SUBSTR(DTOC(INV_D),1,5) TO COLEC_X
      SELECT 2
         USE CUSTFYL  INDEX CUST_N
      LOOP
   ELSE
      CLOSE DATA
      SET CENT OFF
      set exact off
      RETURN
   ENDIF
ENDDO

SET CENT OFF
CLOSE DATA
set exact off
RETURN

 * PROGRAM.....: LSTPRYS1.PRG
*             : price list

mtempfyl1= mtempfyl-'.DBF'
mtempfyl2= mtempfyl-'.IDX'
COPY FILE STKFYL.DBF TO &mTEMPFYL1
COPY FILE STK_N.IDX  TO &mTEMPFYL2

SELECT 1
   USE &mTEMPFYL INDE &mTEMPFYL EXCL

DO BRDR2
@ 8, 1 SAY 'STOCK CODE DESCRIPTION                        PRICE  /UNIT'
price= SUBSTR(prg,5,1)
mprys= 'PRYS_'+price
@ 8, 53 SAY price

DO WHILE .T.
   &C_BODY
   mfield01= SPACE(10)
   mfield02= SPACE(5)
   mfield03= SPACE(5)
   mfield04= SPACE(10)
   mfield05= SPACE(10)
   @ 4, 2 SAY 'Supplier :'
   @ 5, 2 SAY 'Category :'
   @ 6, 2 SAY 'Division :'
   @ 4, 46 SAY 'Start At Stock Code :'
   @ 5, 46 SAY 'Stop  At Stock Code :'
   DO WHILE .T.
      &C_GET
      @ 4, 13 GET mfield01 PICTURE '@!'
      @ 5, 13 GET mfield02 PICTURE '@!'
      @ 6, 13 GET mfield03 PICTURE '@!'
      READ
      SET FILTER TO
      DO CASE
         CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield02))<>0.and.LEN(TRIM(mfield03))<>0
            *SET FILTER TO splyr_n=trim(mfield01).and.stk_cat=trim(mfield02).and.stk_dv=trim(mfield03)
            copy to stkprice.tmp fields stk_n, stk_m, qty_u, prys_a, prys_b, prys_c, prys_d, prys_e for splyr_n=trim(mfield01).and.stk_cat=trim(mfield02).and.stk_dv=trim(mfield03)
         CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield02))<>0
            *SET FILTER TO splyr_n=trim(mfield01).and.stk_cat=mfield02
            copy to stkprice.tmp fields stk_n, stk_m, qty_u, prys_a, prys_b, prys_c, prys_d, prys_e for splyr_n=trim(mfield01).and.stk_cat=trim(mfield02)
         CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield03))<>0
            *SET FILTER TO splyr_n=mfield01.and.stk_dv=mfield03
            copy to stkprice.tmp fields stk_n, stk_m, qty_u, prys_a, prys_b, prys_c, prys_d, prys_e for splyr_n=trim(mfield01).and.stk_dv=trim(mfield03)
         CASE LEN(TRIM(mfield02))<>0.and.LEN(TRIM(mfield03))<>0
            *SET FILTER TO stk_cat=mfield02.and.stk_dv=trim(mfield03)
            copy to stkprice.tmp fields stk_n, stk_m, qty_u, prys_a, prys_b, prys_c, prys_d, prys_e for stk_cat=trim(mfield02).and.stk_dv=trim(mfield03)
         CASE LEN(TRIM(mfield01))<>0
            *SET FILTER TO splyr_n=mfield01
            copy to stkprice.tmp fields stk_n, stk_m, qty_u, prys_a, prys_b, prys_c, prys_d, prys_e for splyr_n=trim(mfield01)
         CASE LEN(TRIM(mfield02))<>0
            *SET FILTER TO stk_cat=mfield02
            copy to stkprice.tmp fields stk_n, stk_m, qty_u, prys_a, prys_b, prys_c, prys_d, prys_e for stk_cat=trim(mfield02)
         CASE LEN(TRIM(mfield03))<>0
            *SET FILTER TO stk_dv=mfield03
            copy to stkprice.tmp fields stk_n, stk_m, qty_u, prys_a, prys_b, prys_c, prys_d, prys_e for stk_dv=trim(mfield03)
         OTHERWISE
            copy to stkprice.tmp fields stk_n, stk_m, qty_u, prys_a, prys_b, prys_c, prys_d, prys_e
      ENDCASE
      sele 2
         use stkprice.tmp ALIAS STKPRICE
      DO WHILE .T.
         GOTO BOTTOM
         mfield05= stk_n
         GOTO TOP
         mfield04= stk_n
         &C_GET
         @ 5, 68 SAY mfield05
         @ 4, 68 GET mfield04 PICTURE '@!'
         READ
         IF READKEY()=4.or.READKEY()=260
            EXIT
         ENDIF
         IF LEN(TRIM(mfield04))=0
            CLOSE DATA
            RETURN
         ELSE
            locate for stk_n=LTRIM(TRIM(mfield04))
         ENDIF
         IF EOF()
            choice= ' '
            &C_CLEAR
            @ 21, 0 CLEAR
            &C_MESSAGE
            @ 23, 30 SAY ' No Such Stock Code. '
            &C_GET
            @ 21, 20 SAY ' Press <A> to Abort, any key to Continue. ' GET choice PICTURE '!'
            READ
            IF choice='A'
               CLOSE DATA
               RETURN
            ELSE
               &C_CLEAR
               @ 21, 0
               @ 23, 0
               LOOP
            ENDIF
            mfield04= stk_n
            @ 4, 68 SAY mfield04
         ENDIF
         @ 5, 68 GET mfield05 PICTURE '@!'
         READ
         IF mfield05=SPACE(10)
            CLOSE DATA
            RETURN
         ELSE
            locate for stk_n=LTRIM(TRIM(mfield05))
         ENDIF
         IF EOF()
            choice= ' '
            &C_CLEAR
            @ 21, 0 CLEAR
            &C_MESSAGE
            @ 23, 30 SAY ' No Such Stock Code. '
            &C_GET
            @ 21, 20 SAY ' Press <A> to Abort, any key to Continue. ' GET choice PICTURE '!'
            READ
            IF choice='A'
               close data
               RETURN
            ELSE
               &C_CLEAR
               @ 21, 0
               @ 23, 0
               LOOP
            ENDIF
            mfield05= stk_n
            @ 5, 68 SAY mfield05
         ENDIF
         IF READKEY()=4.or.READKEY()=260
            LOOP
         ENDIF
         EXIT
      ENDDO
      IF READKEY()=4.or.READKEY()=260
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
   locate for stk_n=mfield04
   DO CASE
      CASE choice='L'
         &C_CLEAR
         @ 9, 1 CLEAR TO 19, 78
         flag= 1
         row= 9
         DO WHILE .not. EOF().and.stk_n<=mfield05
            IF flag=1
               c_list= c_option
               flag= 0
            ELSE
               c_list= c_body
               flag= 1
            ENDIF
            &C_LIST
            @ row, 1  SAY stk_n  PICTURE '@!'
            @ row,12  SAY stk_m  PICTURE '@!'
            @ ROW,45  SAY &mPRYS PICTURE '##,###.##'
            @ row,55  SAY qty_u  PICTURE '@!'
            row= row+1
            SKIP
            IF EOF()
               EXIT
            ENDIF
            IF row=19
               choice= ' '
               &C_CLEAR
               @ 21, 0
               &C_MESSAGE
               @ 21, 20 SAY 'Press <A> to Abort, any key to continue.' GET choice PICTURE '!'
               READ
               IF choice='A'
                  CLOSE DATA
                  RETURN
               ENDIF
               &C_CLEAR
               @ 9, 1 CLEAR TO 19, 78
               row= 9
            ENDIF
         ENDDO
      CASE choice='P'
         do testprt
         pg= 1
         DO WHILE .T.
            &C_MESSAGE
            @ 23, 50 SAY '...Printing'
            SET CONSOLE OFF
            SET DEVICE TO PRINTER
            SET PRINTER ON
            ?? CHR(27)+CHR(64)
            ?? CHR(18)
            cdate= CMONTH(DATE())+' '+STR(DAY(DATE()),2)+', '+STR(YEAR(DATE()),4)
            head= 'Price List as of '+cdate
            head1= ' '
            DO CASE
               CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield02))<>0.and.LEN(TRIM(mfield03))<>0
                  head1= 'for Supplier = '+TRIM(mfield01)+', Category = '+TRIM(mfield02)+' and Division = '+TRIM(mfield03)
               CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield02))<>0
                  head1= 'for Supplier = '+TRIM(mfield01)+', Category = '+TRIM(mfield02)
               CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield03))<>0
                  head1= 'for Supplier = '+TRIM(mfield01)+'and Division = '+TRIM(mfield03)
               CASE LEN(TRIM(mfield02))<>0.and.LEN(TRIM(mfield03))<>0
                  head1= 'for Category = '+TRIM(mfield02)+'and Division = '+TRIM(mfield03)
               CASE LEN(TRIM(mfield01))<>0
                  head1= 'for Supplier = '+TRIM(mfield01)
               CASE LEN(TRIM(mfield02))<>0
                  head1= 'for Category = '+TRIM(mfield02)
               CASE LEN(TRIM(mfield03))<>0
                  head1= 'for Division = '+TRIM(mfield03)
            ENDCASE
            @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
            @ 1, (80-LEN(company))/2 SAY company
            @ 2, (80-LEN(head))/2 SAY head
            IF LEN(TRIM(head1))<>0
               @ 3, (80-LEN(head1))/2 SAY head1
            ENDIF
            ?? chr(15)
            @ 5, 5 say "============================================================================================================================"
            @ 6, 5 say "Stock Code   Stock Description                 Price    Unit  | Stock Code   Stock Description                 Price    Unit"
            @ 6, 58  SAY price pict "!"
            @ 6, 122 say price pict "!"
            @ 7, 5 say "============================================================================================================================"
            row= 7
            rcount=reccount()
            DO WHILE .not. EOF().and.stk_n<=mfield05
               row= row+1
               mrecno=recno()
               @ row,  5 SAY stk_n  PICT '@!'
               @ row, 18 SAY stk_m  PICT '@!'
               @ row, 50 SAY &mPRYS PICT "##,###.##"
               @ row, 61 SAY qty_u  PICT "!!!!"
               @ row, 67 say "|"
               if PG=1
                  tmpval=mrecno+46
               else
                  tmpval=mrecno+47
               endif
               if tmpval<=rcount
                  go tmpval
                  if stk_n<=mfield05
                     @ row, 69 say stk_n  pict "@!"
                     @ row, 82 say stk_m  pict "@!"
                     @ row,114 say &mPRYS pict "##,###.##"
                     @ row,125 say qty_u  pict "!!!!"
                  endif
                  go mrecno
               endif
               if !eof()        
                  SKIP
               endif
               IF EOF().or.stk_n>mfield05
                  if eof()
                     @ row+2, 104 SAY '*** nothing follows ***'
                  endif
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
               IF row>52
                  row= row+1
                  if (recno()+46)>=rcount
                     go bott
                     skip
                     @ row+2, 104 SAY '*** nothing follows ***'
                     ?
                     ?? CHR(18)
                     EJECT
                     SET PRINTER OFF
                     SET DEVICE TO SCREEN
                     SET CONSOLE ON
                     &C_CLEAR
                     @23,0
                     exit
                  else
                     *IF RECNO()+47>RCOUNT
                     *   GOTO RECNO()+46
                     *ELSE
                     *   goto recno()+47
                     *ENDIF
                     if tmpval+1>rcount
                        go tmpval
                     else
                        go tmpval+1
                     endif
                     @ row+2, 005 say 'Prices are subject to change without prior notice !!!'
                     @ row+2, 104 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                     @ 21, 20 SAY ' Press <A> to Abort, any key to continue. ' GET choice PICTURE '!'
                     READ
                     IF choice='A'
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
                     IF LEN(TRIM(head1))<>0
                        @ 2, (80-LEN(head1))/2 SAY head1
                     ENDIF
                     ?? chr(15)
                     @ 4, 5 say "============================================================================================================================"
                     @ 5, 5 say "Stock Code   Stock Description                 Price    Unit  | Stock Code   Stock Description                 Price    Unit"
                     @ 5, 58  SAY price pict "!"
                     @ 5, 122 say price pict "!"
                     @ 6, 5 say "============================================================================================================================"
                     row= 6
                  ENDIF
               ENDIF
            ENDDO
            IF EOF().or.stk_n>mfield05
               EXIT
            ENDIF
         ENDDO
   ENDCASE
   &C_CLEAR
   @ 21, 0
   &C_MESSAGE
   confirm= ' '
   DO WHILE .not. confirm$'YN'
      @ 21, 24 SAY ' Return to Previous Menu (y/n). ' GET confirm PICTURE '!'
      READ
   ENDDO
   IF confirm='N'
      &C_CLEAR
      @ 9, 1 CLEAR TO 19, 78
      @ 21, 0
      row= 7
      SELE 2
      USE
      SELE 1
      LOOP
   ELSE
      EXIT
   ENDIF
ENDDO

CLOSE DATA
RETURN

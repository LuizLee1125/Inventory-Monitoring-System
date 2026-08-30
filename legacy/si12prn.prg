* program.....: Si12Prn.prg
*             : printing of new sales invoice 2013 - marina trading as per bir requirement
*             : 09/05/13

stl= 0
pg= 0
row_p= 0
length= 0
cdate= CMONTH(mfield12)+' '+STR(DAY(mfield12),2)+', '+str(year(mfield12),4)
IF mfield20<>0
   length= length+3
ENDIF
IF mfield21<>0
   length= length+3
ENDIF
IF mfield22<>0
   length= length+3
ENDIF
DO CASE
   CASE length>6
      pstop= 30
   CASE length>3
      pstop= 33
   CASE length>0
      pstop= 36
   OTHERWISE
      pstop= 39
ENDCASE
SELECT 1
SET ORDER TO 1
GOTO TOP
count FOR issue_p>=0.and.stk_n<>'REMOVE' to rcnt
LOCATE FOR stk_n<>'REMOVE'

do case
   case mfield20<>0 .and. mfield21=0 .and. mfield22=0
        totpg=rcnt/21
   case mfield20<>0 .and. mfield21<>0 .and. mfield22=0
        totpg=rcnt/18
   case mfield20<>0 .and. mfield21<>0 .and. mfield22<>0
        totpg=rcnt/15
   otherwise
        totpg=rcnt/24
endcase
if totpg<>int(totpg)
   totpg=int(totpg)+1
endif

do testprt
DO WHILE .not. EOF()
   IF row_p=0
      &C_CLEAR
      @ 23, 0
      &C_MESSAGE
      @ 23, 50 SAY '...Printing'
      SET CONSOLE OFF
      SET DEVICE TO PRINTER
      SET PRINTER ON
      ? CHR(27)+'@'
      ?? CHR(27)+'M'
      pg= pg+1

      *           1         2         3         4         5         6         7         8         9
      * 0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
      *                                                                   Reference : 1234567890
      * Sold To   : xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx                             Date : xxx. 99, 9999
      *             x---------------------45--------------------x        Cust. Code : xxxxxxxxxx
      * T.I.N.    : xxxxxxxxxxxxxxxxxxxx                                      Terms : xxxxx xxxxx
      * Territory : xxxxx - x    Remarks: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx       Page : 9 of 9
      *
      * ================================================================================================
      *    Qty Unit  Description                  Expiry Lot No.         Unit Price Discount      Amount
      * ================================================================================================
      * 99,999 cases xxxxxxxxxxxxxxxxxxxxxxxxxxxx  99-99 123456789012345  99,999.99 99%99%99% 999,999.99

     *@ row_p+7, 28 say "Remarks :"
      @ row_p+7, 73 say rtrim(mfield15)+' '+rtrim(mfield01) picture '@!'      && remarks

     *@ row_p+8, 66 say "Reference :"
     *@ row_p+8, 73 SAY mfield01 PICTURE '@!'      && computer number

     *@ row_p+8, 00 say "Sold To   :"
      @ row_p+8, 16 SAY mfield03 PICTURE '@!'   && customer name

     *@ row_p+8, 00 say "Territory :"
      @ row_p+8, 48 say '['
      @ row_p+8, 49 SAY trim(mfield11)+" - "+trim(mfield06)+"]"

     *@ row_p+9, 71 say "DATE :"
      @ row_p+9, 73 SAY cdate                      && transaction date

     *@ row_p+10, 00 SAY "T.I.N.    :"
      sele 5
      seek mfield02
      if found()
         mtin=tin
         mbus_style=bus_style
      else
         mtin=" "
         mbus_style=" "
      endif
      sele 1
      @ row_p+10, 16 say mTin
      @ row_p+10, 45 say mBus_style
     *@ row_p+8, 70 say "Terms :"
      IF mfield14=0
         @ row_p+10, 73 SAY mfield13 PICTURE '@!'
      ELSE
         @ row_p+10, 73 SAY RTRIM(TRIM(mfield13))+' '+STR(mfield14,3)+' days'
      ENDIF

     *@ row_p+11, 65 say "Cust. Code :"
      @ row_p+11, 73 SAY mfield02 PICTURE '@!'   && customer code

      *IF LEN(TRIM(mfield09))=0
         @ row_p+13, 16 SAY TRIM(mfield04)+', '-TRIM(mfield05)
      *ELSE
      *   @ row_p+13, 16 SAY TRIM(mfield09)+', '-TRIM(mfield10)
      *ENDIF

     *@ row_p+13, 71 say "Page :"
      @ row_p+13, 73 SAY pg PICTURE '##'
      @ row_p+13, 76 SAY "of"
      @ row_p+13, 79 say totpg pict '##'

     *@ row_p+14, 0 say "================================================================================================"
     *@ row_p+15, 0 say "   Qty Unit  Description                  Expiry Lot No.         Unit Price Discount      Amount"
     *@ row_p+16, 0 say "================================================================================================"

      row_p= row_p+16

   ENDIF

   IF .not. EOF()
      stl= stl+t_prys
      @ row_p, 0 SAY  issue_q PICTURE '##,###'
      @ row_p, 7 SAY  issue_u PICTURE '@!'
      @ row_p, 13 SAY stk_m PICTURE '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
     
     *@ row_p, 29 say qty1L   picture '!!!'
      
      IF MONTH(expiry_d)<>0
         IF MONTH(expiry_d)<=9
            @ row_p, 43 SAY '0'+RIGHT(STR(MONTH(expiry_d),2),1)
         ELSE
            @ row_p, 43 SAY MONTH(expiry_d) PICTURE '##'
         ENDIF
         @ row_p, 45 SAY '-'
         @ row_p, 46 SAY RIGHT(STR(YEAR(expiry_d),4),2)
      ENDIF

      @ row_p, 49 SAY lot_n   PICTURE '@!'
      if issue_p=0
         @ row_p,68 say '- free -'
      else
         @ row_p, 66 SAY issue_p PICTURE '##,###.##'
      endif
      mpercent= ' '
      IF dcount1<>0
         mpercent= STR(dcount1,5,2)
      ENDIF
      IF dcount2<>0
         IF LEN(LTRIM(mpercent))=0
            mpercent= STR(dcount2,2)
         ELSE
            mpercent= mpercent+','+STR(dcount2,2)
         ENDIF
      ENDIF
      IF dcount3<>0
         IF LEN(LTRIM(mpercent))=0
            mpercent= STR(dcount3,2)
         ELSE
            mpercent= mpercent+','+STR(dcount3,2)
         ENDIF
      ENDIF
      mpercent= LTRIM(mpercent)
      IF LEN(mpercent)<>0
         mpercent= SPACE(8-LEN(mpercent))+mpercent
         mpercent= mpercent+'%'
         @ row_p, 76 SAY mpercent
      ENDIF
      @ row_p, 86 SAY t_prys PICTURE '###,###.##'
      row_p= row_p+1
      CONTINUE
   ENDIF
   IF row_p>pstop.or.EOF()
      @ row_p+0, 85 SAY '-----------'
      set cent off
      @ row_p+1, 42 SAY '['
      @ row_p+1, 43 SAY DATE()
      @ row_p+1, 52 SAY TIME()
      @ row_p+1, 60 SAY ']'
      @ row_p+1, 76 SAY 'TOTAL...'
      @ row_p+1, 85 SAY 'P'
      @ row_p+1, 86 SAY stl PICTURE '###,###.##'
     * @ 41, 52 SAY '['
     * @ 41, 53 SAY DATE()
     * @ 41, 62 SAY TIME()
     * @ 41, 70 SAY ']'
     * @ 41, 76 SAY 'TOTAL...'
     * @ 41, 85 SAY 'P'
     * @ 41, 86 SAY stl PICTURE '###,###.##'
      gtl= stl
      esw=0
      IF mfield20<>0
         @ row_p+2, 74 SAY STR(mfield20,5,2)+'%'
         @ row_p+2, 86 SAY ROUND((gtl*mfield20/100),2) PICTURE '###,###.##'
         @ row_p+3, 01 say '********************************************'
         @ row_p+3, 85 SAY '-----------'
         gtl= gtl-ROUND((gtl*mfield20/100),2)
         @ row_p+4, 85 SAY 'P'
         @ row_p+4, 86 SAY gtl PICTURE '###,###.##'
         row_p= row_p+4
         esw=1
      ENDIF
      IF mfield21<>0
         @ row_p+2, 74 SAY STR(mfield21,2)+'%'
         @ row_p+2, 86 SAY ROUND((gtl*mfield21/100),2) PICTURE '###,###.##'
         if esw=0
            @ row_p+3, 01 say '********************************************'
            esw=1
         endif
         @ row_p+3, 85 SAY '-----------'
         gtl= gtl-ROUND((gtl*mfield21/100),2)
         @ row_p+4, 85 SAY 'P'
         @ row_p+4, 86 SAY gtl PICTURE '###,###.##'
         row_p= row_p+4
      ENDIF
      IF mfield22<>0
         @ row_p+2, 74 SAY STR(mfield22,2)+'%'
         @ row_p+2, 86 SAY ROUND((gtl*mfield22/100),2) PICTURE '###,###.##'
         if esw=0
            @ row_p+3, 01 say '********************************************'
            esw=1
         endif
         @ row_p+3, 85 SAY '-----------'
         gtl= gtl-ROUND((gtl*mfield22/100),2)
         @ row_p+4, 85 SAY 'P'
         @ row_p+4, 86 SAY gtl PICTURE '###,###.##'
         row_p= row_p+4
      ENDIF
     *@ 42, 85 SAY '==========='
     if eof()              
       *@ row_p+1, 01 say ' Total Amount of this invoice: P'
       *@ row_p+1, 33 say ROUND(mfield23,2) picture '###,###.##'
       *@ row_p+2, 01 say ' Inclusive E-Vat Amount      : P'
       *@ row_p+2, 33 say ROUND((mfield23/1.12)*.12,2) picture '###,###.##'
        @ 41, 28 say ROUND(mfield23,2) picture '###,###.##'
        @ 44, 28 say ROUND((mfield23/1.12)*.12,2) picture '###,###.##'
        row_p= row_p+2
     endif
      if eof() .and. esw=0
      *  @ row_p+2, 01 say '********************************************'
      endif
      
      IF .not. EOF()
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
         @ 21, 20 SAY 'Press <A> to Abort, any key to continue.' GET confirm PICTURE '!'
         READ
         IF confirm='A'
            EXIT
         ELSE
            row_p= 0
            stl= 0.00
            do testprt
         ENDIF
      ENDIF
   ENDIF
ENDDO
EJECT
SET PRINTER OFF
SET DEVICE TO SCREEN
SET CONSOLE ON
&C_CLEAR
@ 23, 0
SET ORDER TO 0
RETURN

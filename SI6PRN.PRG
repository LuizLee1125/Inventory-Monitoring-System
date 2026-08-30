* program.....: Si6Prn.prg
*             : printing of gate pass
*             : 11/05/99

stl    = 0
pg     = 0
row_p  = 0
length = 0
cdate  = left(CMONTH(mfield12),3)+'. '+STR(DAY(mfield12),2)+', '+str(year(mfield12),4)
IF mfield20<>0
   length = length+3
ENDIF
IF mfield21<>0
   length = length+3
ENDIF
IF mfield22<>0
   length = length+3
ENDIF
DO CASE
   CASE length>6
      pstop= 21        
   CASE length>3
      pstop= 24  
   CASE length>0
      pstop= 27
   OTHERWISE
      pstop= 30           
ENDCASE
SELECT 1
GOTO TOP
LOCATE FOR issue_p>0.and.stk_n<>'REMOVE'
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
      @ 01,45 say " MARINA TRADING  "
      @ 02,41 say "G A T E   P A S S"
      @ 04,01 say "Sold to  :"
      *IF LEN(TRIM(mfield09))=0
         @ 04,12 SAY mfield03 PICTURE '@!'
      *ELSE
      *   @ 04,12 SAY mfield08 PICTURE '@!'
      *ENDIF
      @ 04,68 say "Invoice No.:"
      @ 04,81 say mfield01 PICTURE '@!'
      @ 05,01 say "Territory:"
      @ 05,12 SAY mfield11
      @ 05,68 say "Date       :"
      @ 05,81 SAY cdate
      @ 06,01 say "Remarks  :"
      @ 06,12 SAY mfield15 PICTURE '@!'
      @ 06,68 say "Cust. Code :"
      @ 06,81 SAY mfield02 PICTURE '@!'
      @ 08,01 say "---------------------------------------------------------------------------------------------"
      @ 09,01 say "  Qty Unit  Lot No.          Description                   Expiry  U. Price Discount   Amount"
      @ 10,01 say "---------------------------------------------------------------------------------------------"
      row_p=12 
   ENDIF
   IF .not. EOF()
      stl= stl+t_prys
      @ row_p, 1  SAY issue_q PICTURE '#,###'
      @ row_p, 7  SAY issue_u PICTURE '@!'
      @ row_p, 13 SAY lot_n PICTURE '@!'
      @ row_p, 30 SAY stk_m PICTURE '!!!!!!!!!!!!!!!!!!!!!!!!!!!'
      IF MONTH(expiry_d)<>0
         IF MONTH(expiry_d)<=9
            @ row_p, 61 SAY '0'+RIGHT(STR(MONTH(expiry_d),2),1)
         ELSE
            @ row_p, 61 SAY MONTH(expiry_d) PICTURE '##'
         ENDIF
         @ row_p, 63 SAY '-'
         @ row_p, 64 SAY RIGHT(STR(YEAR(expiry_d),4),2)
      ENDIF
      @ row_p, 68 SAY issue_p PICTURE '#,###.##'
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
         @ row_p, 79 SAY mpercent
      ENDIF
      @ row_p, 85 SAY t_prys PICTURE '##,###.##'
      row_p= row_p+1
      CONTINUE
   ENDIF
   IF row_p>pstop.or.EOF()
      @ row_p+0, 84 SAY "----------"
      @ row_p+1, 76 SAY 'TOTAL:'
      @ row_p+1, 83 SAY 'P'
      @ row_p+1, 84 SAY stl PICTURE '###,###.##'
      row_p= row_p+1
      gtl= stl
      IF mfield20<>0
         @ row_p+1, 78 SAY STR(mfield20,5,2)+'%'
         @ row_p+1, 85 SAY gtl*mfield20/100 PICTURE '##,###.##'
         @ row_p+2, 84 SAY "----------"
         gtl= gtl-(gtl*mfield20/100)
         @ row_p+3, 83 SAY 'P'
         @ row_p+3, 84 SAY gtl PICTURE '###,###.##'
         row_p= row_p+3
      ENDIF
      IF mfield21<>0
         @ row_p+1, 78 SAY STR(mfield21,2)+'%'
         @ row_p+1, 85 SAY gtl*mfield21/100 PICTURE '##,###.##'
         @ row_p+2, 84 SAY "----------"
         gtl= gtl-(gtl*mfield21/100)
         @ row_p+3, 83 SAY 'P'
         @ row_p+3, 84 SAY gtl PICTURE '###,###.##'
         row_p= row_p+3
      ENDIF
      IF mfield22<>0
         @ row_p+1, 78 SAY STR(mfield22,2)+'%'
         @ row_p+1, 85 SAY gtl*mfield22/100 PICTURE '##,###.##'
         @ row_p+2, 84 SAY "----------"
         gtl= gtl-(gtl*mfield22/100)
         @ row_p+3, 83 SAY 'P'
         @ row_p+3, 84 SAY gtl PICTURE '###,###.##'
         row_p= row_p+3
      ENDIF
      @ row_p+1, 01 SAY 'Received By: _______________   Checked By: ________________'
      @ row_p+1, 84 SAY "=========="
   ENDIF
ENDDO

Eject
SET PRINTER OFF
SET DEVICE TO SCREEN
SET CONSOLE ON
&C_CLEAR
@ 23, 0
RETURN

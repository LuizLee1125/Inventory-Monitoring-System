* program.....: Si7Prn.prg
*             : printing of sales invoice (new)
*             : 11/05/99
* modified    : 03/23, 05/23
*             : inclusion of area code; free items not segregated

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
      pstop= 33
   CASE length>3
      pstop= 36
   CASE length>0
      pstop= 39
   OTHERWISE
      pstop= 42
ENDCASE
SELECT 1
SET ORDER TO 1
GOTO TOP
count FOR issue_p>=0.and.stk_n<>'REMOVE' to rcnt
LOCATE FOR stk_n<>'REMOVE'

do case
   case mfield20<>0 .and. mfield21=0 .and. mfield22=0
        totpg=rcnt/27
   case mfield20<>0 .and. mfield21<>0 .and. mfield22=0
        totpg=rcnt/25
   case mfield20<>0 .and. mfield21<>0 .and. mfield22<>0
        totpg=rcnt/23
   otherwise
        totpg=rcnt/30
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
      @ row_p+4, 78 SAY mfield01 PICTURE '@!'
      IF LEN(TRIM(mfield09))=0
         @ row_p+5, 15 SAY mfield03 PICTURE '@!'
      ELSE
         @ row_p+5, 15 SAY mfield08 PICTURE '@!'
      ENDIF
      @ row_p+5, 78 SAY cdate
      IF LEN(TRIM(mfield09))=0
         @ row_p+6, 15 SAY TRIM(mfield04)+', '-TRIM(mfield05)
      ELSE
         @ row_p+6, 15 SAY TRIM(mfield09)+', '-TRIM(mfield10)
      ENDIF
      @ row_p+6, 78 SAY mfield02 PICTURE '@!'
      IF mfield14=0
         @ row_p+7 , 78 SAY mfield13 PICTURE '@!'
      ELSE
         @ row_p+7 , 78 SAY RTRIM(TRIM(mfield13))+' '+STR(mfield14,3)+' days'
      ENDIF
      @ row_p+08, 15 SAY trim(mfield11)+" - "+trim(mfield06)
      @ row_p+08, 42 SAY mfield15 PICTURE '@S17'
      @ row_p+08, 78 SAY pg PICTURE '##'
      @ row_p+08, 81 SAY "of"
      @ row_p+08, 84 say totpg pict '##'
      row_p= row_p+13
   ENDIF
   IF .not. EOF()
      stl= stl+t_prys
      @ row_p, 0 SAY  issue_q PICTURE '###,###'
      @ row_p, 8 SAY  issue_u PICTURE '@!'
      @ row_p, 13 SAY lot_n   PICTURE '@!'
      *@ row_p, 29 say qty1L   picture '!!!'
      @ row_p, 29 SAY stk_m PICTURE '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
      IF MONTH(expiry_d)<>0
         IF MONTH(expiry_d)<=9
            @ row_p, 61 SAY '0'+RIGHT(STR(MONTH(expiry_d),2),1)
         ELSE
            @ row_p, 61 SAY MONTH(expiry_d) PICTURE '##'
         ENDIF
         @ row_p, 63 SAY '-'
         @ row_p, 64 SAY RIGHT(STR(YEAR(expiry_d),4),2)
      ENDIF
      if issue_p=0
         @ row_p,68 say '- free -'
      else
         @ row_p, 67 SAY issue_p PICTURE '##,###.##'
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
         @ row_p, 77 SAY mpercent
      ENDIF
      @ row_p, 86 SAY t_prys PICTURE '###,###.##'
      row_p= row_p+1
      CONTINUE
   ENDIF
   IF row_p>pstop.or.EOF()
      @ row_p+0, 85 SAY '-----------'
      if eof()              
         @ row_p+1, 01 say ' Total Amount of this invoice: P'
         @ row_p+1, 34 say ROUND(mfield23,2) picture '###,###.##'
      endif
      set cent off
      @ row_p+1, 52 SAY '['
      @ row_p+1, 53 SAY DATE()
      @ row_p+1, 62 SAY TIME()
      @ row_p+1, 70 SAY ']'
      @ row_p+1, 76 SAY 'TOTAL...'
      @ row_p+1, 85 SAY 'P'
      @ row_p+1, 86 SAY stl PICTURE '###,###.##'
      row_p= row_p+1
      if eof()
         @ row_p+1, 01 say ' Inclusive E-Vat Amount      : P'
         @ row_p+1, 34 say ROUND((mfield23/1.12)*.12,2) picture '###,###.##'
      *row_p= row_p+1
      endif
      gtl= stl
      esw=0
      IF mfield20<>0
         @ row_p+1, 74 SAY STR(mfield20,5,2)+'%'
         @ row_p+1, 86 SAY ROUND((gtl*mfield20/100),2) PICTURE '###,###.##'
         @ row_p+2, 01 say '********************************************'
         @ row_p+2, 85 SAY '-----------'
         gtl= gtl-ROUND((gtl*mfield20/100),2)
         @ row_p+3, 85 SAY 'P'
         @ row_p+3, 86 SAY gtl PICTURE '###,###.##'
         row_p= row_p+3
         esw=1
      ENDIF
      IF mfield21<>0
         @ row_p+1, 74 SAY STR(mfield21,2)+'%'
         @ row_p+1, 86 SAY ROUND((gtl*mfield21/100),2) PICTURE '###,###.##'
         if esw=0
            @ row_p+2, 01 say '********************************************'
            esw=1
         endif
         @ row_p+2, 85 SAY '-----------'
         gtl= gtl-ROUND((gtl*mfield21/100),2)
         @ row_p+3, 85 SAY 'P'
         @ row_p+3, 86 SAY gtl PICTURE '###,###.##'
         row_p= row_p+3
      ENDIF
      IF mfield22<>0
         @ row_p+1, 74 SAY STR(mfield22,2)+'%'
         @ row_p+1, 86 SAY ROUND((gtl*mfield22/100),2) PICTURE '###,###.##'
         if esw=0
            @ row_p+2, 01 say '********************************************'
            esw=1
         endif
         @ row_p+2, 85 SAY '-----------'
         gtl= gtl-ROUND((gtl*mfield22/100),2)
         @ row_p+3, 85 SAY 'P'
         @ row_p+3, 86 SAY gtl PICTURE '###,###.##'
         row_p= row_p+3
      ENDIF
      @ row_p+1, 85 SAY '==========='
      if eof() .and. esw=0
         @ row_p+2, 01 say '********************************************'
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

* program.....: Si8Prn.prg
*             : printing of purchase
* modified    : 03/01/04


*             save screen to atlscreen
*             atlmsg="Module under finalization, please press any key..."
*             atllen=len(atlmsg)
*             set colo to rb/rb
*             @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
*             set colo to +w/rb
*             @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
*             @ 12,41-atllen/2 say atlmsg
*             atlkeypress=inkey(0)
*             restore screen from atlscreen
*             return

stl= 0
pg= 0
row_p= 0
length= 0
cdate= CMONTH(mfield06)+' '+STR(DAY(mfield06),2)+', '+str(year(mfield06),4)
IF mfield12<>0
   length= length+3
ENDIF
IF mfield13<>0
   length= length+3
ENDIF
IF mfield14<>0
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
GOTO TOP
count FOR issue_p>0.and.stk_n<>'REMOVE' to rcnt
LOCATE FOR stk_n<>'REMOVE'

do case
   case mfield12<>0 .and. mfield13=0 .and. mfield14=0
        totpg=rcnt/27
   case mfield12<>0 .and. mfield13<>0 .and. mfield14=0
        totpg=rcnt/25
   case mfield12<>0 .and. mfield13<>0 .and. mfield14<>0
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
      *           1         2         3         4         5         6         7         8
      * 0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
      *                                                              Purchase No.  :  1234567890
      * Supplier    :  [xxxxxxxxxx] xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx            Date :  xxxxx 99, 9999
      *                xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx                      Terms :  xxxxxxxxxx
      * Remarks     :  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx                       Page :  99 of 99
      *
      * ---------------------------------------------------------------------------------------------
      *    Qty Free Unit  Description                      Catalog Discounts    Unit Cost  Sales Amt.
      * ---------------------------------------------------------------------------------------------
      * 99,999  999 xxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 99,999.99 99.99 99 99  99,999.99  999,999.99

      @ row_p+02, 61 say "Purchase No. :"
      @ row_p+02, 78 SAY mfield01 PICTURE '@!'
      @ row_p+03,  0 say "Supplier    :"
      @ row_p+03, 15 SAY "["+trim(mfield02)+"] "+trim(mfield03) PICTURE '@!'
      @ row_p+03, 78 SAY cdate
      @ row_p+04, 15 SAY TRIM(mfield04)+', '-TRIM(mfield05)
      @ row_p+05, 78 SAY RTRIM(TRIM(mfield07))+' '+STR(mfield08,3)+' days'
      @ row_p+06, 42 SAY mfield10 PICTURE '@S17'
      @ row_p+06, 78 SAY pg PICTURE '##'
      @ row_p+06, 81 SAY "of"
      @ row_p+06, 84 say totpg pict '##'
      @ row_p+08, 0  say "---------------------------------------------------------------------------------------------"
      @ row_p+09, 0  say "   Qty Free Unit  Description                      Catalog Discounts    Unit Cost  Sales Amt."
      @ row_p+10, 0  say "---------------------------------------------------------------------------------------------"
      row_p= row_p+11
   ENDIF
   IF .not. EOF()
      stl= stl+t_prys
      @ row_p, 0  SAY issue_q PICTURE '##,###'
      @ row_p, 12 SAY issue_u PICTURE '@!'
      @ row_p, 18 say stk_m picture '@!'
      @ row_p, 49 say issue_cp picture '99,999.99'
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
         @ row_p, 59 SAY mpercent
      ENDIF

      @ row_p, 72 SAY issue_p PICTURE '##,###.##'
      @ row_p, 83 SAY t_prys PICTURE '###,###.##'
      row_p= row_p+1
      CONTINUE
   ENDIF
   IF row_p>pstop.or.EOF()
      @ row_p+0, 81 SAY '------------'
      if eof()              
         @ row_p+1, 01 say ' Total Amount of this purchase: P'
         @ row_p+1, 35 say ROUND(mfield15,2) picture '###,###.##'
      endif
      @ row_p+1, 63 SAY 'TOTAL...'
      @ row_p+1, 80 SAY 'P'
      @ row_p+1, 83 SAY stl PICTURE '###,###.##'
      row_p= row_p+1
      gtl= stl
      IF mfield12<>0
         @ row_p+1, 71 SAY STR(mfield12,5,2)+'%'
         @ row_p+1, 83 SAY ROUND((gtl*mfield12/100),2) PICTURE '###,###.##'
         @ row_p+2, 83 SAY '-----------'
         gtl= gtl-ROUND((gtl*mfield12/100),2)
         @ row_p+3, 80 SAY 'P'
         @ row_p+3, 81 SAY gtl PICTURE '#,###,###.##'
         row_p= row_p+3
      ENDIF
      IF mfield13<>0
         @ row_p+1, 71 SAY STR(mfield13,2)+'%'
         @ row_p+1, 83 SAY ROUND((gtl*mfield13/100),2) PICTURE '###,###.##'
         @ row_p+2, 83 SAY '-----------'
         gtl= gtl-ROUND((gtl*mfield13/100),2)
         @ row_p+3, 80 SAY 'P'
         @ row_p+3, 81 SAY gtl PICTURE '###,###.##'
         row_p= row_p+3
      ENDIF
      IF mfield14<>0
         @ row_p+1, 71 SAY STR(mfield14,2)+'%'
         @ row_p+1, 83 SAY ROUND((gtl*mfield14/100),2) PICTURE '###,###.##'
         @ row_p+2, 83 SAY '-----------'
         gtl= gtl-ROUND((gtl*mfield14/100),2)
         @ row_p+3, 80 SAY 'P'
         @ row_p+3, 81 SAY gtl PICTURE '###,###.##'
         row_p= row_p+3
      ENDIF                    
      if eof()              
         @ row_p+1, 01 say replicate('ð',44)
      endif
      @ row_p+1, 81 SAY '============'
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

RETURN

* Program.....: SrFPrn.prg
*             : printing of sales return

stl= 0
pg= 0
row_p= 0
length= 0
cdate= left(CMONTH(mfield09),3)+'. '+STR(DAY(mfield09),2)+', '+STR(YEAR(mfield09),4)
IF mfield15<>0
    length= length+3
ENDIF
IF mfield16<>0
    length= length+3
ENDIF
IF mfield17<>0
    length= length+3
ENDIF
DO CASE
    CASE length>6
        pstop= 27
    CASE length>0
        pstop= 32
    OTHERWISE
        pstop= 37
ENDCASE
SELECT 1
GOTO TOP
LOCATE FOR issue_p>0.and.stk_n<>'REMOVE'
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
        pg= pg+1
        @ 01,39 say " MARINA TRADING  "
        @ 02,37 say "  Sales Return   "
        @ row_p+5, 1 SAY 'CUSTOMER CODE : '
        @ row_p+5, 17 SAY mfield03 PICTURE '@!'
        @ row_p+5, 50 SAY 'SR NO.      :'
        @ row_p+5, 64 SAY mfield01 PICTURE '@!'
        @ row_p+6, 1 SAY 'NAME          : '
        @ row_p+6, 17 SAY mfield04 PICTURE '@!'
        @ row_p+6, 50 SAY 'REF. SI NO. :'
        @ row_p+6, 64 SAY mfield02 PICTURE '@!'
        @ row_p+7, 1 SAY 'ADDRESS       : '
        @ row_p+7, 17 SAY left((TRIM(mfield05)+', '-TRIM(mfield06)),32)
        @ row_p+7, 50 SAY 'DATE        :'
        @ row_p+7, 64 SAY cdate
        @ row_p+8, 1 SAY 'Territory     : '
        @ row_p+8, 17 SAY mfield08
        @ row_p+8, 50 SAY 'PAGE        :'
        @ row_p+8, 64 SAY pg PICTURE '##'
        @ row_p+9, 1 SAY 'REMARKS       : '
        @ row_p+9, 17 SAY mfield10 PICTURE '@S20'
        @ row_p+10, 1 SAY REPLICATE('=',79)
        @ row_p+11, 3 SAY 'QTY.  BO UNIT  DESCRIPTION                        PRICE  DISCOUNT      AMOUNT'
        @ row_p+12, 1 SAY REPLICATE('=',79)
        row_p= row_p+13
    ENDIF
    IF .not. EOF()
        stl= stl+t_prys
        @ row_p, 1 SAY issue_q PICTURE '##,###'
        @ row_p, 8 SAY issue_fg PICTURE '###'
        @ row_p, 12 SAY issue_u PICTURE '@!'
        @ row_p, 18 SAY stk_m PICTURE '@!'
        @ row_p, 49 SAY issue_p PICTURE '##,###.##'
        mpercent= ' '
        IF dcount1<>0
            mpercent= STR(dcount1,2)
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
        @ row_p, 70 SAY t_prys PICTURE '###,###.##'
        row_p= row_p+1
        CONTINUE
    ENDIF
    IF row_p>pstop.or.EOF()
        @ row_p+0, 69 SAY '-----------'
        if eof()              
           @ row_p+1, 01 say ' Total Amount of Sales Return: P'
           @ row_p+1, 33 say ROUND(mfield18,2) picture '###,###.##'
        endif

        @ row_p+1, 59 SAY 'TOTAL...:'
        @ row_p+1, 69 SAY 'P'
        @ row_p+1, 70 SAY stl PICTURE '###,###.##'
        row_p= row_p+1
        gtl= stl
        IF mfield15<>0
            @ row_p+1, 62 SAY STR(mfield15,2)+'%'
            @ row_p+1, 70 SAY gtl*mfield15/100 PICTURE '###,###.##'
            @ row_p+2, 69 SAY '-----------'
            gtl= gtl-(gtl*mfield15/100)
            @ row_p+3, 69 SAY 'P'
            @ row_p+3, 70 SAY gtl PICTURE '###,###.##'
            row_p= row_p+3
        ENDIF
        IF mfield16<>0
            @ row_p+1, 62 SAY STR(mfield16,2)+'%'
            @ row_p+1, 70 SAY gtl*mfield16/100 PICTURE '###,###.##'
            @ row_p+2, 69 SAY '-----------'
            gtl= gtl-(gtl*mfield16/100)
            @ row_p+3, 69 SAY 'P'
            @ row_p+3, 70 SAY gtl PICTURE '###,###.##'
            row_p= row_p+3
        ENDIF
        IF mfield17<>0
            @ row_p+1, 62 SAY STR(mfield17,2)+'%'
            @ row_p+1, 70 SAY gtl*mfield17/100 PICTURE '###,###.##'
            @ row_p+2, 69 SAY '-----------'
            gtl= gtl-(gtl*mfield17/100)
            @ row_p+3, 69 SAY 'P'
            @ row_p+3, 70 SAY gtl PICTURE '###,###.##'
            row_p= row_p+3
        ENDIF
        if eof()
           @ row_p+1, 01 say '********************************************'
        endif
        @ row_p+1, 69 SAY '==========='
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
            ENDIF
        ENDIF
    ENDIF
    IF EOF()
        GOTO TOP
        row_p= row_p+2
        LOCATE FOR issue_p=0.and.stk_n<>'REMOVE'
        IF .not. EOF().and.row_p<32
            @ row_p+1, 1 SAY REPLICATE('=',78)
            @ row_p+2, 20 SAY 'F  R  E  E      G  O  O  D  S'
            @ row_p+3, 1 SAY REPLICATE('=',78)
            row_p= row_p+4
        ELSE
            row_p= 38
        ENDIF
        DO WHILE .not. EOF()
            IF row_p>37
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
                ENDIF
            ENDIF
            IF row_p=0
                &C_CLEAR
                @ 23, 0
                &C_MESSAGE
                @ 23, 50 SAY '...Printing'
                SET CONSOLE OFF
                SET DEVICE TO PRINTER
                SET PRINTER ON
                ? CHR(27)+'@'
                pg= pg+1
                *@ 01,41 say " MARINA TRADING  "
                @ row_p+1, 72 SAY mfield01 PICTURE '@!'
                @ row_p+3, 62 SAY cdate
                @ row_p+3, 78 SAY SUBSTR(DTOC(mfield09),7,2)
                IF LEN(TRIM(xfield08))=0
                    @ row_p+5, 13 SAY mfield04 PICTURE '@!'
                ELSE
                    @ row_p+5, 13 SAY xfield07 PICTURE '@!'
                ENDIF
                @ row_p+5, 65 SAY mfield03 PICTURE '@!'
                IF LEN(TRIM(xfield08))=0
                    @ row_p+7, 13 SAY TRIM(mfield05)+', '-TRIM(mfield06)
                ELSE
                    @ row_p+7, 13 SAY TRIM(xfield08)+', '-TRIM(xfield09)
                ENDIF
                IF xfield13=0
                    @ row_p+7, 58 SAY xfield12 PICTURE '@!'
                ELSE
                    @ row_p+7, 58 SAY TRIM(xfield12)+' '+STR(xfield13,3)+' days'
                ENDIF
                @ row_p+9, 13 SAY mfield08
                @ row_p+9, 42 SAY mfield10 PICTURE '@S14'
                @ row_p+9, 63 SAY pg PICTURE '##'
                row_p= row_p+13
                @ row_p+1, 1 SAY REPLICATE('=',78)
                @ row_p+2, 20 SAY 'F  R  E  E      G  O  O  D  S'
                @ row_p+3, 1 SAY REPLICATE('=',78)
                row_p= row_p+4
            ENDIF
            IF .not. EOF()
                @ row_p, 4 SAY issue_q PICTURE '###,###'
                @ row_p, 12 SAY issue_u PICTURE '@!'
                @ row_p, 18 SAY stk_m PICTURE '@!'
                row_p= row_p+1
                CONTINUE
            ENDIF
        ENDDO
        EJECT
        SET PRINTER OFF
        SET DEVICE TO SCREEN
        SET CONSOLE ON
        &C_CLEAR
        @ 23, 0
        EXIT
    ENDIF
ENDDO
RETURN
 

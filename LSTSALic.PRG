* program.....: LstSalIC.prg
*             : sales per item per customer
*             : 05/05/2006

DO BRDR2
*                    1         2         3         4         5         6         7
*           12345678901234567890123456789012345678901234567890123456789012345678901234567890
@ 8, 1 SAY 'DATE     SI NO.     CUST-CODE LOT #     QUANTITY     PRICE DISCOUNT      TOTAL'
*           99/99/99 1234567890 123456789 12345678 99,999 xxx 9,999.99 99 99 99 999,999.99   

save screen to atlscreen
atlmsg="generate totals only (y/n)  "
atlopt="N"
atllen=len(atlmsg)
set colo to rb/rb
@ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
set colo to +w/rb
@ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
@ 12,41-atllen/2 say atlmsg
@ 12,40-atllen/2+len(atlmsg) get atlopt pict "Y" valid atlopt$"YyNn"
read
restore screen from atlscreen

if atlopt="Y"
   do lstsaict
   set cent off
   return
endif

SELECT 2
   USE SIFYL INDEX SI_N
SELECT 1
   USE STKREC INDEX SI_ID

DO WHILE .T.
    &C_HEAD
    @ 20, 1 SAY SPACE(78)
    &C_MESSAGE
    @ 21, 20 SAY ' NOTE: Press <Enter> to Return to Main Menu. '
    &C_BODY
    @ 5, 2 SAY 'Stock Code :'
    @ 6, 2 SAY 'Customer   :'
    @ 5, 46 SAY 'Start At Issued Date :'
    @ 6, 46 SAY 'Stop  At Issued Date :'
    DO WHILE .T.
        &C_GET
        mfield03= SPACE(10)
        @ 5, 15 GET mfield03 PICTURE '@!'
        READ
        IF LEN(TRIM(mfield03))=0
            SET CENT ON
            close data
            RETURN
        ENDIF
        SEEK LTRIM(TRIM(mfield03))
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
        ENDIF
        &C_GET
        mfield03= stk_n
        @ 5, 15 SAY mfield03 PICTURE '@!'
        EXIT
    ENDDO
    DO WHILE .T.
        SET CENT ON
        missue_d= CTOD('01/01/2000')
        mfield02= DATE()
        mfield01= issue_d
        mfield04= SPACE(10)
        &C_GET
        @ 6, 15 GET mfield04 PICTURE '@!'
        @ 6, 69 SAY mfield02 PICTURE '99/99/9999'
        @ 5, 69 GET mfield01 PICTURE '@!'
        READ
        SEEK mfield03+STR(YEAR(mfield01),4)+SUBSTR(DTOC(mfield01),1,5)
        IF EOF()
            SEEK mfield03
            DO CASE
                CASE mfield01<issue_d
                    mfield01= issue_d
                    confirm= ' '
                    &C_CLEAR
                    @ 21, 0 CLEAR
                    &C_MESSAGE
                    @ 23, 23 SAY ' Earliest Recorded Date is '+DTOC(mfield01)+'. '
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
                    @ 5, 70 SAY mfield01
                CASE mfield01>issue_d
                    DO WHILE .not. EOF().and.mfield03=stk_n.and.mfield01>=issue_d
                        SKIP
                    ENDDO
                    mfield01= issue_d
                    confirm= ' '
                    &C_CLEAR
                    @ 21, 0 CLEAR
                    &C_MESSAGE
                    @ 23, 23 SAY ' Closest Recorded Date is '+DTOC(mfield01)+'. '
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
                    @ 5, 69 SAY mfield01
            ENDCASE
        ENDIF
        @ 6, 69 GET mfield02 PICTURE '@!'
        READ
        SET CENT OFF
        EXIT
    ENDDO
    SET CENTURY OFF
    choice= 'L'
    DO OPTION8
    IF mfield01>mfield02
        mtemp= mfield01
        mfield01= mfield02
        mfield02= mtemp
    ENDIF
    SEEK mfield03+STR(YEAR(mfield01),4)+SUBSTR(DTOC(mfield01),1,5)
    DO CASE
        CASE choice='L'
            STORE 0.00 TO stl1, stl2, gtl1, gtl2
            &C_CLEAR
            @ 10, 1 CLEAR TO 19, 78
            flag= 1
            row= 9
            DO WHILE .not. EOF().and.issue_d<=mfield02.and.stk_n=mfield03.and.issue_d>=mfield01
                DO CASE
                    CASE LEN(TRIM(mfield04))<>0
                        IF mfield04<>cust_n.or.trans_c<>'S'
                            SKIP
                            LOOP
                        ENDIF
                    OTHERWISE
                        IF trans_c<>'S'
                            SKIP
                            LOOP
                        ENDIF
                ENDCASE
                IF flag=1
                    c_list= c_option
                    flag= 0
                ELSE
                    c_list= c_body
                    flag= 1
                ENDIF
                &C_LIST

*                     1         2         3         4         5         6         7
*            12345678901234567890123456789012345678901234567890123456789012345678901234567890
*@ 8, 1 SAY 'DATE     SI NO.     CUST-CODE LOT #     QUANTITY     PRICE DISCOUNT      TOTAL'
*            99/99/99 1234567890 123456789 12345678 99,999 xxx 9,999.99 99 99 99 999,999.99   

                IF missue_d<>issue_d
                    missue_d= issue_d
                    @ row, 1 SAY issue_d PICTURE '99/99/99'
                ENDIF
                @ row, 10 SAY trans_n PICTURE '@!'
                SELECT 2
                SEEK  stkrec->trans_n
                IF .not. EOF()
                    @ row, 21 SAY left(cust_n,9) PICTURE '@!'
                    @ row, 60 SAY dcount1 PICTURE '##'
                    @ row, 63 SAY dcount2 PICTURE '##'
                    @ row, 66 SAY dcount3 PICTURE '##'
                ENDIF
                SELECT 1
                t_amt= t_prys
                t_amt= t_amt-t_amt* sifyl->dcount1/100
                t_amt= t_amt-t_amt* sifyl->dcount2/100
                t_amt= t_amt-t_amt* sifyl->dcount3/100
                @ row, 31 SAY righ(trim(lot_n),9)  PICTURE '@!'
                @ row, 40 SAY issue_q PICTURE '##,###'
                @ row, 47 SAY left(issue_u,3) PICTURE '@!'
                @ row, 51 SAY issue_p PICTURE '#,###.##'
                @ row, 69 SAY t_amt PICTURE '###,###.##'
                stl1= stl1+issue_q
                gtl1= gtl1+issue_q
                stl2= stl2+t_amt
                gtl2= gtl2+t_amt
                row= row+1
                SKIP
                IF EOF()                &&    6
                    EXIT                && 678901234567890
                ENDIF                   &&  99,999,999.99
                IF row=19
                    &C_HEAD
                    @ 19, 1 SAY SPACE(78)
                    @ 19, 10 SAY 'SUB   TOTAL'
                    @ 19, 37 SAY stl1 PICTURE '#,###,###'
                    @ 19, 66 SAY stl2 PICTURE '##,###,###.##'
                    @ 20, 1 SAY SPACE(78)
                    @ 20, 10 SAY 'GRAND TOTAL'
                    @ 20, 37 SAY gtl1 PICTURE '#,###,###'
                    @ 20, 66 SAY gtl2 PICTURE '##,###,###.##'
                    choice= ' '
                    &C_CLEAR
                    @ 21, 0
                    &C_MESSAGE
                    @ 21, 20 SAY ' Press <A> to Abort, any key to continue.' GET choice PICTURE '!'
                    READ
                    IF choice='A'
                        SET CENTURY Off
                        CLOSE DATA
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
            @ 19, 37 SAY stl1 PICTURE '#,###,###'
            @ 19, 66 SAY stl2 PICTURE '##,###,###.##'
            @ 20, 1 SAY SPACE(78)
            @ 20, 10 SAY 'GRAND TOTAL'
            @ 20, 37 SAY gtl1 PICTURE '#,###,###'
            @ 20, 66 SAY gtl2 PICTURE '##,###,###.##'
        CASE choice='P'
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
                cdate= CMONTH(DATE())+' '+STR(DAY(DATE()),2)+','+STR(YEAR(DATE()),4)
                IF LEN(TRIM(mfield04))=0
                    head= 'Sales Summary of '+LTRIM(TRIM(mfield03))
                ELSE
                    head= 'Sales Summary of '+LTRIM(TRIM(mfield03))+' for Territory = '+LTRIM(TRIM(mfield04))
                ENDIF
                head1= 'from '+DTOC(mfield01)+' to '+DTOC(mfield02)
                @ 3, 1 SAY 'Page '+LTRIM(STR(pg))
                @ 3, (80-LEN(company))/2 SAY company
                @ 4, (80-LEN(head))/2 SAY head
                @ 5, (80-LEN(head1))/2 SAY head1
                @ 7, 2 SAY '---------------------------------------------------------------------------'
                @ 8, 2 SAY 'DATE     SI NO.     CUST-CODE     QUANTITY     PRICE DISCOUNT  TOTAL AMOUNT'
                @ 9, 2 SAY '---------------------------------------------------------------------------'
                row= 9
                DO WHILE .not. EOF().and.issue_d<=mfield02.and.stk_n=mfield03
                    DO CASE
                        CASE LEN(TRIM(mfield04))<>0
                            IF mfield04<>cust_n.or.trans_c<>'S'
                                SKIP
                                LOOP
                            ENDIF
                        OTHERWISE
                            IF trans_c<>'S'
                                SKIP
                                LOOP
                            ENDIF
                    ENDCASE
                    row= row+1
                    IF missue_d<>issue_d
                        missue_d= issue_d
                        @ row, 2 SAY issue_d PICTURE '@!'
                    ENDIF
                    @ row, 11 SAY trans_n PICTURE '@!'
                    SELECT 2
                    SEEK  stkrec->trans_n
                    IF .not. EOF()
                        @ row, 22 SAY cust_n PICTURE '@!'
                    ENDIF
                    SELECT 1
                    t_amt= t_prys
                    t_amt= t_amt-t_amt* sifyl->dcount1/100
                    t_amt= t_amt-t_amt* sifyl->dcount2/100
                    t_amt= t_amt-t_amt* sifyl->dcount3/100
                    @ row, 33 SAY issue_q PICTURE '###,###'
                    @ row, 41 SAY issue_u PICTURE '@!'
                    @ row, 46 SAY issue_p PICTURE '#,###.##'
                    IF  sifyl->dcount1<>0
                        @ row, 55 SAY  sifyl->dcount1 PICTURE '##'
                    ENDIF
                    IF  sifyl->dcount2<>0
                        @ row, 58 SAY  sifyl->dcount2 PICTURE '##'
                    ENDIF
                    IF  sifyl->dcount3<>0
                        @ row, 61 SAY  sifyl->dcount3 PICTURE '##'
                    ENDIF
                    @ row, 64 SAY t_amt PICTURE '##,###,###.##'
                    stl1= stl1+issue_q
                    gtl1= gtl1+issue_q
                    stl2= stl2+t_amt
                    gtl2= gtl2+t_amt
                    SKIP
                    IF row>55
                        row= row+1
                        @ row+1, 30 SAY '----------'
                        @ row+1, 64 SAY '-------------'
                        @ row+2, 30 SAY stl1 PICTURE '##,###,###'
                        @ row+2, 64 SAY stl2 PICTURE '##,###,###.##'
                        @ row+3, 75 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                            SET CENTURY Off
                            CLOSE DATA
                            RETURN
                        ENDIF
                        &C_CLEAR
                        @ 23, 0
                        &C_MESSAGE
                        @ 23, 50 SAY '...Printing'
                        SET CONSOLE OFF
                        SET DEVICE TO PRINTER
                        SET PRINTER ON
                        pg= pg+1
                        STORE 0.00 TO stl1, stl2
                        @ 3, 1 SAY 'Page '+LTRIM(STR(pg))
                        @ 3, (80-LEN(head))/2 SAY head
                        IF LEN(TRIM(mfield03))<>0
                            @ 4, (80-LEN(head1))/2 SAY head1
                        ENDIF
                        @ 6, 2 SAY '-----------------------------------------------------------------------------'
                        @ 7, 2 SAY 'DATE      TRANS. NO. C USER NAME  NAME/CODE        PLUS      MINUS   QUANTITY'
                        @ 8, 2 SAY '-----------------------------------------------------------------------------'
                        row= 8
                    ENDIF
                ENDDO
                IF EOF().or.issue_d>mfield02.or.stk_n<>mfield03
                    IF pg>1
                        @ row+1, 30 SAY '----------'
                        @ row+1, 64 SAY '-------------'
                        @ row+2, 30 SAY stl1 PICTURE '##,###,###'
                        @ row+2, 64 SAY stl2 PICTURE '##,###,###.##'
                        row= row+2
                    ENDIF
                    @ row+1, 30 SAY '=========='
                    @ row+1, 64 SAY '============='
                    @ row+2, 30 SAY gtl1 PICTURE '##,###,###'
                    @ row+2, 64 SAY gtl2 PICTURE '##,###,###.##'
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
            SET CENTURY Off
            CLOSE DATA
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
        @ 9, 1 CLEAR TO 19, 78
        @ 21, 0
        @ 6, 15 SAY SPACE(10)
        row= 9
        LOOP
    ELSE
        set cent off
        CLOSE DATA
        RETURN
    ENDIF
ENDDO
 
CLOSE DATA
set cent off
RETURN

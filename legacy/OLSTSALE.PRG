* program.....: OlStSale.prg
*             : old sales summary per item

SELECT 2
   USE O_SIFYL INDEX OS_SI_N
SELECT 1
   USE O_STKREC INDEX O_SID
DO BRDR2

@ 8, 2 SAY 'DATE     SI NO.     CUST-CODE     QUANTITY     PRICE DISCOUNT        TOTAL'

DO WHILE .T.
    SET CENTURY ON
    &C_HEAD
    @ 20, 1 SAY SPACE(78)
    &C_MESSAGE
    @ 21, 20 SAY ' NOTE: Press <Enter> to Return to Main Menu. '
    &C_BODY
    @ 5, 2 SAY 'Stock Code :'
    @ 6, 2 SAY 'Salesman   :'
    @ 5, 45 SAY 'Start At Issued Date :'
    @ 6, 45 SAY 'Stop  At Issued Date :'
    DO WHILE .T.
        &C_GET
        mfield03= SPACE(10)
        @ 5, 15 GET mfield03 PICTURE '@!'
        READ
        IF LEN(TRIM(mfield03))=0
            SET CENTURY OFF
            CLOSE DATABASE
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
                SET CENTURY OFF
                CLOSE DATABASE
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
        missue_d= CTOD('01/01/1998')
        mfield02= DATE()
        mfield01= issue_d
        mfield04= SPACE(10)
        &C_GET
        @ 6, 15 GET mfield04 PICTURE '@!'
        @ 6, 68 SAY mfield02 PICTURE '99/99/9999'
        @ 5, 68 GET mfield01 PICTURE '99/99/9999'
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
                    @ 5, 68 SAY mfield01 PICTURE '99/99/9999'
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
                    @ 5, 68 SAY mfield01 PICTURE '99/99/9999'
            ENDCASE
        ENDIF
        @ 6, 68 GET mfield02 PICTURE '99/99/9999'
        READ
        EXIT
    ENDDO
    choice= 'L'
    DO OPTION8
    IF mfield01>mfield02
        mtemp= mfield01
        mfield01= mfield02
        mfield02= mtemp
    ENDIF
    SET CENTURY OFF
    SEEK mfield03+STR(YEAR(mfield01),4)+SUBSTR(DTOC(mfield01),1,5)
    DO CASE
        CASE choice='L'
            STORE 0.00 TO stl1, stl2, gtl1, gtl2
            &C_CLEAR
            @ 10, 1 CLEAR TO 19, 78
            flag= 1
            row= 9
            DO WHILE .not. EOF().and.issue_d<=mfield02.and.stk_n=mfield03
                DO CASE
                    CASE LEN(TRIM(mfield04))<>0
                        IF mfield04<>cust_s.or.trans_c<>'S'
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
                IF missue_d<>issue_d
                    missue_d= issue_d
                    @ row, 2 SAY issue_d PICTURE '@!'
                ENDIF
                @ row, 11 SAY trans_n PICTURE '@!'
                SELECT 2
                SEEK  o_stkrec->trans_n
                IF .not. EOF()
                    @ row, 22 SAY cust_n PICTURE '@!'
                    @ row, 55 SAY dcount1 PICTURE '##'
                    @ row, 58 SAY dcount2 PICTURE '##'
                    @ row, 61 SAY dcount3 PICTURE '##'
                ENDIF
                SELECT 1
                t_amt= t_prys
                t_amt= t_amt-t_amt* o_sifyl->dcount1/100
                t_amt= t_amt-t_amt* o_sifyl->dcount2/100
                t_amt= t_amt-t_amt* o_sifyl->dcount3/100
                @ row, 33 SAY issue_q PICTURE '###,###'
                @ row, 41 SAY issue_u PICTURE '@!'
                @ row, 46 SAY issue_p PICTURE '#,###.##'
                @ row, 64 SAY t_amt PICTURE '#,###,###.##'
                stl1= stl1+issue_q
                gtl1= gtl1+issue_q
                stl2= stl2+t_amt
                gtl2= gtl2+t_amt
                row= row+1
                SKIP
                IF EOF()
                    EXIT
                ENDIF
                IF row=19
                    &C_HEAD
                    @ 19, 1 SAY SPACE(78)
                    @ 19, 10 SAY 'SUB   TOTAL'
                    @ 19, 31 SAY stl1 PICTURE '#,###,###'
                    @ 19, 63 SAY stl2 PICTURE '##,###,###.##'
                    @ 20, 1 SAY SPACE(78)
                    @ 20, 10 SAY 'GRAND TOTAL'
                    @ 20, 31 SAY gtl1 PICTURE '#,###,###'
                    @ 20, 63 SAY gtl2 PICTURE '##,###,###.##'
                    choice= ' '
                    &C_CLEAR
                    @ 21, 0
                    &C_MESSAGE
                    @ 21, 20 SAY ' Press <A> to Abort, any key to continue.' GET choice PICTURE '!'
                    READ
                    IF choice='A'
                        CLOSE DATABASE
                        SET CENTURY OFF
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
            @ 19, 31 SAY stl1 PICTURE '#,###,###'
            @ 19, 63 SAY stl2 PICTURE '##,###,###.##'
            @ 20, 1 SAY SPACE(78)
            @ 20, 10 SAY 'GRAND TOTAL'
            @ 20, 31 SAY gtl1 PICTURE '#,###,###'
            @ 20, 63 SAY gtl2 PICTURE '##,###,###.##'
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
                IF LEN(TRIM(mfield04))=0
                    head= 'Sales Summary of '+LTRIM(TRIM(mfield03))
                ELSE
                    head= 'Sales Summary of '+LTRIM(TRIM(mfield03))+' for Salesman = '+LTRIM(TRIM(mfield04))
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
                            IF mfield04<>cust_s.or.trans_c<>'S'
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
                    SEEK  o_stkrec->trans_n
                    IF .not. EOF()
                        @ row, 22 SAY cust_n PICTURE '@!'
                    ENDIF
                    SELECT 1
                    t_amt= t_prys
                    t_amt= t_amt-t_amt* o_sifyl->dcount1/100
                    t_amt= t_amt-t_amt* o_sifyl->dcount2/100
                    t_amt= t_amt-t_amt* o_sifyl->dcount3/100
                    @ row, 33 SAY issue_q PICTURE '###,###'
                    @ row, 41 SAY issue_u PICTURE '@!'
                    @ row, 46 SAY issue_p PICTURE '#,###.##'
                    IF  o_sifyl->dcount1<>0
                        @ row, 55 SAY  o_sifyl->dcount1 PICTURE '##'
                    ENDIF
                    IF  o_sifyl->dcount2<>0
                        @ row, 58 SAY  o_sifyl->dcount2 PICTURE '##'
                    ENDIF
                    IF  o_sifyl->dcount3<>0
                        @ row, 61 SAY  o_sifyl->dcount3 PICTURE '##'
                    ENDIF
                    @ row, 64 SAY t_amt PICTURE '##,###,###.##'
                    stl1= stl1+issue_q
                    gtl1= gtl1+issue_q
                    stl2= stl2+t_amt
                    gtl2= gtl2+t_amt
                    SKIP
                    IF row>50
                        row= row+1
                        @ row+1, 30 SAY '----------'
                        @ row+1, 64 SAY '-------------'
                        @ row+2, 30 SAY stl1 PICTURE '##,###,###'
                        @ row+2, 64 SAY stl2 PICTURE '##,###,###.##'
                        @ row+4, 52 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                            SET CENTURY OFF
                            CLOSE DATABASE
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
            EXIT
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
        EXIT
    ENDIF
ENDDO
SET CENTURY OFF
CLOSE DATABASE
RETURN
 

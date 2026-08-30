* program.....: OlStInv.prg
*             : old invoices

SELECT 2
   USE STKFYL INDEX STK_N
SELECT 1
   USE O_STKREC INDEX O_TID

DO BRDR2
@ 8, 2 SAY 'DATE      TRANS.NO.  C USER NAME  NAME/CODE  BEG.QTY    PLUS   MINUS END QTY'

DO WHILE .T.
    SET CENTURY ON
    &C_HEAD
    @ 20, 1 SAY SPACE(78)
    &C_MESSAGE
    @ 21, 20 SAY ' NOTE: Press <Enter> to Return to Main Menu. '
    &C_BODY
    @ 5, 2 SAY 'Stock Code :'
    @ 6, 2 SAY 'On Hand    :'
    @ 5, 45 SAY 'Start At Issued Date :'
    @ 6, 45 SAY 'Stop  At Issued Date :'
    DO WHILE .T.
        &C_GET
        mfield03= SPACE(10)
        @ 5, 15 GET mfield03 PICTURE '@!'
        READ
        IF LEN(TRIM(mfield03))=0
            CLOSE DATABASE
            SET CENTURY OFF
            RETURN
        ENDIF
        SEEK LTRIM(TRIM(mfield03))
        IF EOF()
            choice= ' '
            &C_CLEAR
            @ 21, 0 CLEAR
            &C_MESSAGE
            @ 23, 18 SAY ' No Recorded Transaction For Such Stock Code. '
            &C_GET
            @ 21, 20 SAY ' Press <A> to Abort, any key to Continue. ' GET choice PICTURE '!'
            READ
            IF choice='A'
                CLOSE DATABASE
                SET CENTURY OFF
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
        mtrans_d= CTOD('01/01/1998')
        mfield02= DATE()
        SELECT 2
        SEEK mfield03
        IF .not. EOF()
            @ 6, 15 SAY qty1 PICTURE '###,###'
            @ 6, 23 SAY qty_u PICTURE '@!'
        ENDIF
        SELECT 1
        mfield01= trans_d
        &C_GET
        @ 6, 68 SAY mfield02
        @ 5, 68 GET mfield01 PICTURE '99/99/9999'
        READ
        SEEK mfield03+STR(YEAR(mfield01),4)+SUBSTR(DTOC(mfield01),1,5)
        *STR(DTOC(mfield01),4)+SUBSTR(DTOC(mfield01),1,5)
        IF EOF()
            SEEK mfield03
            DO CASE
                CASE mfield01<trans_d
                    mfield01= trans_d
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
                CASE mfield01>trans_d
                    DO WHILE .not. EOF().and.mfield03=stk_n.and.mfield01>=trans_d
                        SKIP
                    ENDDO
                    mfield01= trans_d
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
            atlsw= 0
            svqty= 0
            DO WHILE .not. EOF().and.trans_d<=mfield02.and.stk_n=mfield03
                IF flag=1
                    c_list= c_option
                    flag= 0
                ELSE
                    c_list= c_body
                    flag= 1
                ENDIF
                &C_LIST
                IF mtrans_d<>trans_d
                    mtrans_d= trans_d
                    @ row, 2 SAY trans_d PICTURE '@!'
                ENDIF
                @ row, 12 SAY trans_n PICTURE '@!'
                @ row, 23 SAY trans_c PICTURE '@!'
                @ row, 25 SAY user_m PICTURE '@!'
                @ row, 36 SAY cust_n PICTURE '@!'
                IF svqty=qty1
                    @ row, 47 SAY qty1 PICTURE '999,999'
                ELSE
                    @ row, 47 SAY svqty PICTURE '999,999'
                ENDIF
                DO CASE
                    CASE trans_c='P'
                        @ row, 55 SAY issue_q*qty_pq PICTURE '###,###'
                        svqty= qty1+(issue_q*qty_pq)
                        @ row, 71 SAY svqty PICTURE '###,###'
                        stl1= stl1+issue_q*qty_pq
                        gtl1= gtl1+issue_q*qty_pq
                    CASE trans_c='R'
                        @ row, 55 SAY issue_q PICTURE '###,###'
                        svqty= qty1+issue_q
                        @ row, 71 SAY svqty PICTURE '###,###'
                        stl1= stl1+issue_q
                        gtl1= gtl1+issue_q
                    CASE trans_c='B'
                        @ row, 55 SAY issue_q PICTURE '###,###'
                        svqty= qty1+issue_q
                        @ row, 71 SAY svqty PICTURE '###,###'
                        stl1= stl1+issue_q
                        gtl1= gtl1+issue_q
                    CASE trans_c='S'
                        @ row, 63 SAY issue_q PICTURE '###,###'
                        svqty= qty1-issue_q
                        @ row, 71 SAY svqty PICTURE '###,###'
                        stl2= stl2+issue_q
                        gtl2= gtl2+issue_q
                ENDCASE
                row= row+1
                SKIP
                IF EOF()
                    EXIT
                ENDIF
                IF row=19
                    &C_HEAD
                    @ 19, 1 SAY SPACE(78)
                    @ 19, 10 SAY 'SUB   TOTAL'
                    @ 19, 54 SAY stl1 PICTURE '####,###'
                    @ 19, 62 SAY stl2 PICTURE '####,###'
                    @ 20, 1 SAY SPACE(78)
                    @ 20, 10 SAY 'GRAND TOTAL'
                    @ 20, 54 SAY gtl1 PICTURE '####,###'
                    @ 20, 62 SAY gtl2 PICTURE '####,###'
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
            @ 19, 54 SAY stl1 PICTURE '####,###'
            @ 19, 62 SAY stl2 PICTURE '####,###'
            @ 20, 1 SAY SPACE(78)
            @ 20, 10 SAY 'GRAND TOTAL'
            @ 20, 54 SAY gtl1 PICTURE '####,###'
            @ 20, 62 SAY gtl2 PICTURE '####,###'
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
                head= 'Transaction Summary of '+LTRIM(TRIM(mfield03))
                head1= 'from '+DTOC(mfield01)+' to '+DTOC(mfield02)
                @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
                @ 1, (80-LEN(company))/2 SAY company
                @ 2, (80-LEN(head))/2 SAY head
                @ 3, (80-LEN(head1))/2 SAY head1
                @ 5, 2 SAY '-----------------------------------------------------------------------------'
                @ 6, 2 SAY 'DATE      TRANS.NO.  C USER NAME  NAME/CODE  BEG.QTY    PLUS   MINUS END QTY'
                @ 7, 2 SAY '-----------------------------------------------------------------------------'
                row= 7
                DO WHILE .not. EOF().and.trans_d<=mfield02.and.stk_n=mfield03
                    row= row+1
                    IF mtrans_d<>trans_d
                        mtrans_d= trans_d
                        @ row, 2 SAY trans_d PICTURE '@!'
                    ENDIF
                    @ row, 12 SAY trans_n PICTURE '@!'
                    @ row, 23 SAY trans_c PICTURE '@!'
                    @ row, 25 SAY user_m PICTURE '@!'
                    @ row, 36 SAY cust_n PICTURE '@!'
                    IF svqty=qty1
                        @ row, 47 SAY qty1 PICTURE '999,999'
                    ELSE
                        @ row, 47 SAY svqty PICTURE '999,999'
                    ENDIF
                    DO CASE
                        CASE trans_c='P'
                            @ row, 55 SAY issue_q*qty_pq PICTURE '###,###'
                            svqty= qty1+(issue_q*qty_pq)
                            @ row, 71 SAY svqty PICTURE '###,###'
                            stl1= stl1+issue_q*qty_pq
                            gtl1= gtl1+issue_q*qty_pq
                        CASE trans_c='R'
                            @ row, 55 SAY issue_q PICTURE '###,###'
                            svqty= qty1+issue_q
                            @ row, 71 SAY svqty PICTURE '###,###'
                            stl1= stl1+issue_q
                            gtl1= gtl1+issue_q
                        CASE trans_c='B'
                            @ row, 55 SAY issue_q PICTURE '###,###'
                            svqty= qty1+issue_q
                            @ row, 71 SAY svqty PICTURE '###,###'
                            stl1= stl1+issue_q
                            gtl1= gtl1+issue_q
                        CASE trans_c='S'
                            @ row, 63 SAY issue_q PICTURE '###,###'
                            svqty= qty1-issue_q
                            @ row, 71 SAY svqty PICTURE '###,###'
                            stl2= stl2+issue_q
                            gtl2= gtl2+issue_q
                    ENDCASE
                    SKIP
                    IF EOF().or.trans_d>mfield02.or.stk_n<>mfield03
                        IF pg>1
                            @ row+1, 54 SAY '----------'
                            @ row+1, 62 SAY '----------'
                            @ row+2, 54 SAY stl1 PICTURE '##,###,###'
                            @ row+2, 62 SAY stl2 PICTURE '##,###,###'
                            row= row+2
                        ENDIF
                        @ row+1, 54 SAY '=========='
                        @ row+1, 62 SAY '=========='
                        @ row+2, 54 SAY gtl1 PICTURE '##,###,###'
                        @ row+2, 62 SAY gtl2 PICTURE '##,###,###'
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
                    IF row>50
                        row= row+1
                        @ row+1, 54 SAY '----------'
                        @ row+1, 62 SAY '----------'
                        @ row+2, 54 SAY stl1 PICTURE '##,###,###'
                        @ row+2, 62 SAY stl2 PICTURE '##,###,###'
                        @ row+4, 44 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                            CLOSE DATABASE
                            SET CENTURY OFF
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
                        IF LEN(TRIM(mfield03))<>0
                            @ 2, (80-LEN(head1))/2 SAY head1
                        ENDIF
                        @ 4, 2 SAY '-----------------------------------------------------------------------------'
                        @ 5, 2 SAY 'DATE      TRANS.NO.  C USER NAME  NAME/CODE  BEG.QTY    PLUS   MINUS END QTY'
                        @ 6, 2 SAY '-----------------------------------------------------------------------------'
                        row= 6
                    ENDIF
                ENDDO
                IF EOF().or.trans_d>mfield02.or.stk_n<>mfield03
                    EXIT
                ENDIF
            ENDDO
        OTHERWISE
            EXIT
    ENDCASE
    confirm= ' '
    &C_CLEAR
    @ 21, 0
    &C_MESSAGE
    @ 21, 24 SAY ' Return to Previous Menu (y/n). ' GET confirm PICTURE '!'
    READ
    IF confirm='N'
        &C_CLEAR
        @ 9, 1 CLEAR TO 19, 78
        @ 21, 0
        @ 6, 15 SAY SPACE(12)
        row= 9
        LOOP
    ELSE
        SET CENTURY OFF
        CLOSE DATABASE
        RETURN
    ENDIF
ENDDO
CLOSE DATABASE
SET CENTURY OFF
RETURN


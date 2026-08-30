* program.....: LstInvC.prg
*             : inventory control; original
* modified    : to reflect free goods


SELECT 4
   USE PURFYL INDEX PUR_N
SELECT 3
   USE SIFYL INDEX SI_N
SELECT 2
   USE STKFYL INDEX STK_N
SELECT 1
   USE STKREC INDEX TRANS_ID

DO BRDR2
*                    1         2         3         4         5         6         7
*           1234567890123456789012345678901234567890123456789012345678901234567890123456789
@ 8, 1 SAY 'DATE     TRANS.NO.  C USER NAME  NAME/CODE  REMARKS         PLUS  MINUS    QTY'
*                                                       1234567890123 99,999 99,999 99,999
DO WHILE .T.
    &C_HEAD
    @ 20, 1 SAY SPACE(78)
    &C_MESSAGE
    @ 21, 20 SAY ' NOTE: Press <Enter> to Return to Main Menu. '
    &C_BODY
    @ 5, 2  SAY 'Stock Code :'
    @ 6, 2  SAY 'On Hand    :'
    @ 4, 47 SAY 'Last Purchase Date  :'
    @ 5, 47 SAY 'Start At Issued Date:'
    @ 6, 47 SAY 'Stop  At Issued Date:'
    DO WHILE .T.
        SELE 1
        &C_GET
        mfield03= SPACE(10)
        @ 5, 15 GET mfield03 PICTURE '@!'
        READ
        IF LEN(TRIM(mfield03))=0
            CLOSE DATA
            RETURN
        ENDIF
        SEEK LTRIM(TRIM(mfield03))
        IF .NOT. FOUND()
            choice= ' '
            &C_CLEAR
            @ 21, 0
            &C_MESSAGE
            @ 23, 18 SAY ' No Recorded Transaction For Such Stock Code. '
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
        ENDIF
        &C_GET
        mfield03= stk_n
        @ 5, 15 SAY mfield03 PICTURE '@!'
        EXIT
    ENDDO
    DO WHILE .T.
        mtrans_d= CTOD('01/01/1999')
        mfield02= DATE()
        SELECT 2
        SEEK mfield03
        IF .not. EOF()
            mfield01= qty1lu
            mlastpur= stk_lt
            @ 6, 15 SAY qty1 PICTURE '###,###'
            @ 6, 23 SAY qty_u PICTURE '@!'
        ELSE
            mfield01= trans_d
        ENDIF
        SELECT 1
        &C_GET
        SET CENT ON
        STORE MLASTPUR TO MFIELD01
        @ 4, 69 SAY mlastpur picture '99/99/9999'
        @ 5, 69 GET mfield01 PICTURE "99/99/9999"
        @ 6, 69 SAY mfield02 picture "99/99/9999"
        READ
        SEEK mfield03+STR(YEAR(mfield01),4)+SUBSTR(DTOC(mfield01),1,5)
        SET CENT OFF
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
                    SET CENT ON
                    @ 5, 69 SAY mfield01 PICT '99/99/9999'
                    SET CENT OFF
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
                    SET CENT ON
                    @ 5, 69 SAY mfield01 PICT '99/99/9999'
                    SET CENT OFF
            ENDCASE
        ENDIF
        SET CENT ON
        @ 6, 69 GET mfield02 PICTURE '99/99/9999'
        READ
        SET CENT OFF
        EXIT
    ENDDO
    choice= 'L'
    DO OPTION8
    IF mfield01>mfield02
        mtemp= mfield01
        mfield01= mfield02
        mfield02= mtemp
    ENDIF
    SET CENT ON
    SEEK mfield03+STR(YEAR(mfield01),4)+SUBSTR(DTOC(mfield01),1,5)
    SET CENT OFF
    DO CASE
        CASE choice='L'
            STORE 0.00 TO stl1, stl2, gtl1, gtl2
            &C_CLEAR
            @ 10, 1 CLEAR TO 19, 78
            flag= 1
            row= 9
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
                    @ row, 1 SAY trans_d PICTURE '@!'
                ENDIF
                @ row, 10 SAY trans_n PICTURE '@!'
                @ row, 21 SAY trans_c PICTURE '@!'
                @ row, 23 SAY user_m PICTURE '@!'
                @ row, 34 SAY cust_n PICTURE '@!'
                DO CASE
                    CASE trans_c='P'
                        stor trans_n to sv_n
                        sele 4
                        seek sv_n
                        if found()
                           store inv_rem to sv_rem
                        else
                           store " " to sv_rem
                        endif
                        sele 1
                        @ row, 45 SAY LEFT(sv_rem,13) pict "@!"
                        @ row, 59 SAY issue_q*qty_pq+issue_fg*qty_pq PICTURE '##,###'
                        stl1= stl1+issue_q*qty_pq+issue_fg*qty_pq
                        gtl1= gtl1+issue_q*qty_pq+issue_fg*qty_pq
                    CASE trans_c='R'
                        @ row, 59 SAY issue_q PICTURE '##,###'
                        stl1= stl1+issue_q
                        gtl1= gtl1+issue_q
                    CASE trans_c='B'
                        @ row, 59 SAY issue_q PICTURE '##,###'
                        stl1= stl1+issue_q
                        gtl1= gtl1+issue_q
                    CASE trans_c='S'
                        stor trans_n to sv_n
                        sele 3
                        seek sv_n
                        if found()
                           store si_rem to sv_rem
                        else
                           store " " to sv_rem
                        endif
                        sele 1
                        @ row, 45 SAY LEFT(sv_rem,13) pict "@!"
                        @ row, 66 SAY issue_q+issue_fg PICTURE '##,###'
                        stl2= stl2+issue_q+ISSUE_FG
                        gtl2= gtl2+issue_q+ISSUE_FG
                ENDCASE
                @ row, 73 SAY qty1 PICTURE '##,###'
                row= row+1
                SKIP
                IF EOF()
                    EXIT
                ENDIF
                IF row=19
                    &C_HEAD
                    @ 19, 1 SAY SPACE(78)
                    @ 19, 10 SAY 'SUB   TOTAL'
                    @ 19, 59 SAY stl1 PICTURE '##,###'
                    @ 19, 66 SAY stl2 PICTURE '##,###'
                    @ 20, 1 SAY SPACE(78)
                    @ 20, 10 SAY 'GRAND TOTAL'
                    @ 20, 59 SAY gtl1 PICTURE '##,###'
                    @ 20, 66 SAY gtl2 PICTURE '##,###'
                    choice= ' '
                    &C_CLEAR
                    @ 21, 0
                    &C_MESSAGE
                    @ 21, 20 SAY ' Press <A> to Abort, any key to continue.' GET choice PICTURE '!'
                    READ
                    IF choice='A'
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
            @ 19, 59 SAY stl1 PICTURE '##,###'
            @ 19, 66 SAY stl2 PICTURE '##,###'
            @ 20, 1 SAY SPACE(78)
            @ 20, 10 SAY 'GRAND TOTAL'
            @ 20, 59 SAY gtl1 PICTURE '##,###'
            @ 20, 66 SAY gtl2 PICTURE '##,###'
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
                head= 'Transaction Summary of '+LTRIM(TRIM(mfield03))
                head1= 'from '+DTOC(mfield01)+' to '+DTOC(mfield02)
                @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
                @ 1, (80-LEN(company))/2 SAY company
                @ 2, (80-LEN(head))/2 SAY head
                @ 3, (80-LEN(head1))/2 SAY head1
                ? CHR(27)+'@'
                ?? CHR(27)+'M'
                *                   1         2         3         4         5         6         7         8         9
                *          12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345
                @ 5, 2 SAY '---------------------------------------------------------------------------------------------'
                @ 6, 2 SAY 'DATE     TRANS. NO. LOT NO.        EXP.DATE  C  USERNAME  CUST.CODE     PLUS   MINUS QUANTITY'
                @ 7, 2 SAY '---------------------------------------------------------------------------------------------'
                *           99/99/99 xxxxxxxxxx XXXXXXXXXXXXXx 99/99/99  x  xxxxxxxxx xxxxxxxxxx xxx,xxx xxx,xxx  xxx,xxx
                row= 7
                DO WHILE .not. EOF().and.trans_d<=mfield02.and.stk_n=mfield03
                    row= row+1
                    IF mtrans_d<>trans_d
                        mtrans_d= trans_d
                        @ row, 2 SAY trans_d PICTURE '99/99/99'
                    ENDIF
                    @ row, 11 SAY trans_n        PICTURE '@!'
                    @ row, 22 SAY left(lot_n,14) picture '@!'
                    @ row, 37 SAy expiry_d       picture '99/99/99'
                    @ row, 47 SAY trans_c        PICTURE '@!'
                    @ row, 50 SAY left(user_m,7) PICTURE '@!'
                    @ row, 60 SAY cust_n         PICTURE '@!'
                    DO CASE
                        CASE trans_c='P'
                            @ row, 71 SAY issue_q*qty_pq+issue_fg*qty_pq PICTURE '###,###'
                            stl1= stl1+issue_q*qty_pq+issue_fg*qty_pq
                            gtl1= gtl1+issue_q*qty_pq+issue_fg*qty_pq
                        CASE trans_c='R'
                            @ row, 71 SAY issue_q PICTURE '###,###'
                            stl1= stl1+issue_q
                            gtl1= gtl1+issue_q
                        CASE trans_c='B'
                            @ row, 71 SAY issue_q PICTURE '###,###'
                            stl1= stl1+issue_q
                            gtl1= gtl1+issue_q
                        CASE trans_c='S'
                            @ row, 79 SAY issue_q+issue_fg PICTURE '###,###'
                            stl2= stl2+issue_q+issue_fg
                            gtl2= gtl2+issue_q+issue_fg
                    ENDCASE
                    @ row, 88 SAY qty1 PICTURE '###,###'
                    SKIP
                    IF EOF().or.trans_d>mfield02.or.stk_n<>mfield03
                        IF pg>1
                            @ row+1, 71 SAY '-------'
                            @ row+1, 79 SAY '-------'
                            @ row+2, 71 SAY stl1 PICTURE '###,###'
                            @ row+2, 79 SAY stl2 PICTURE '###,###'
                            row= row+2
                        ENDIF
                        @ row+1, 71 SAY '======='
                        @ row+1, 79 SAY '======='
                        @ row+2, 71 SAY gtl1 PICTURE '###,###'
                        @ row+2, 79 SAY gtl2 PICTURE '###,###'
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
                        @ row+1, 71 SAY '-------'
                        @ row+1, 79 SAY '-------'
                        @ row+2, 71 SAY stl1 PICTURE '###,###'
                        @ row+2, 79 SAY stl2 PICTURE '###,###'
                        @ row+4, 71 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                        stl= 0.00
                        ? CHR(27)+'@'
                        ?? CHR(27)+'M'

                        @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
                        @ 1, (80-LEN(head))/2 SAY head
                        IF LEN(TRIM(mfield03))<>0
                            @ 2, (80-LEN(head1))/2 SAY head1
                        ENDIF

                        @ 4, 2 SAY '---------------------------------------------------------------------------------------------'
                        @ 5, 2 SAY 'DATE     TRANS. NO. LOT NO.        EXP.DATE  C  USERNAME  CUST.CODE     PLUS   MINUS QUANTITY'
                        @ 6, 2 SAY '---------------------------------------------------------------------------------------------'
                        row= 6
                    ENDIF
                ENDDO
                IF EOF().or.trans_d>mfield02.or.stk_n<>mfield03
                    EXIT
                ENDIF
            ENDDO
        OTHERWISE
            RETURN
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
        CLOSE DATA
        RETURN
    ENDIF
ENDDO

CLOSE DATA
RETURN
 

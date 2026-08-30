* program.....: Lststk.prg
*             : stock list summary

mtempfyl1= mtempfyl-'.DBF'
mtempfyl2= mtempfyl-'.IDX'
COPY FILE STKFYL.DBF TO &mTEMPFYL1
COPY FILE STK_N.IDX  TO &mTEMPFYL2
SELECT 1
USE &mTEMPFYL INDE &mTEMPFYL EXCL
DO BRDR2
@ 8, 2 SAY 'STOCK CODE  DESCRIPTION                    UNIT'

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
                SET FILTER TO splyr_n=mfield01.and.stk_cat=mfield02.and.stk_dv=mfield03
            CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield02))<>0
                SET FILTER TO splyr_n=mfield01.and.stk_cat=mfield02
            CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield03))<>0
                SET FILTER TO splyr_n=mfield01.and.stk_dv=mfield03
            CASE LEN(TRIM(mfield02))<>0.and.LEN(TRIM(mfield03))<>0
                SET FILTER TO stk_cat=mfield02.and.stk_dv=mfield03
            CASE LEN(TRIM(mfield01))<>0
                SET FILTER TO splyr_n=mfield01
            CASE LEN(TRIM(mfield02))<>0
                SET FILTER TO stk_cat=mfield02
            CASE LEN(TRIM(mfield03))<>0
                SET FILTER TO stk_dv=mfield03
        ENDCASE
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
                close data
                RETURN
            ELSE
                SEEK LTRIM(TRIM(mfield04))
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
                mfield04= stk_n
                @ 4, 68 SAY mfield04
            ENDIF
            @ 5, 68 GET mfield05 PICTURE '@!'
            READ
            IF mfield05=SPACE(10)
                close data
                RETURN
            ELSE
                SEEK LTRIM(TRIM(mfield05))
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
    SEEK mfield04
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
                @ row, 2 SAY stk_n PICTURE '@!'
                @ row, 14 SAY stk_m PICTURE '@!'
                @ row, 45 SAY qty_u PICTURE '@!'
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
                        close data
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
                head= 'Summary of Stock List as of '+cdate
                head1= ' '
                DO CASE
                    CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield02))<>0.and.LEN(TRIM(mfield03))<>0
                        head1= 'for Supplier = '+TRIM(mfield01)+', Category = '+TRIM(mfield02)+' and Division = '+TRIM(mfield03)
                    CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield02))<>0
                        head1= 'for Supplier = '+TRIM(mfield01)+'and Category = '+TRIM(mfield02)
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
                @ 5, 9 SAY REPLICATE('-',60)
                @ 6, 9 SAY 'STOCK CODE        DESCRIPTION                           UNIT'
                @ 7, 9 SAY REPLICATE('-',60)
                row= 7
                DO WHILE .not. EOF().and.stk_n<=mfield05
                    row= row+1
                    @ row, 9 SAY stk_n PICTURE '@!'
                    @ row, 27 SAY stk_m PICTURE '@!'
                    @ row, 65 SAY qty_u PICTURE '@!'
                    SKIP
                    IF EOF().or.stk_n>mfield05
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
                        @ row+2, 46 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                            close data
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
                        @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
                        @ 1, (80-LEN(head))/2 SAY head
                        IF LEN(TRIM(head1))<>0
                            @ 2, (80-LEN(head1))/2 SAY head1
                        ENDIF
                        @ 4, 9 SAY REPLICATE('-',60)
                        @ 5, 9 SAY 'STOCK CODE        DESCRIPTION                           UNIT'
                        @ 6, 9 SAY REPLICATE('-',60)
                        row= 6
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
        row= 9
        LOOP
    ELSE
        close data
        RETURN
    ENDIF
ENDDO
 
close data
return

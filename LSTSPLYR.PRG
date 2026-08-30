* program.....: LstSplyr.prg
*             : supplier listing

SELECT 1
USE SPLYRFYL INDEX SPLYR_N
DO BRDR2
@ 8, 2 SAY 'CODE       NAME                           TEL. NO.              CREDIT LIMIT'

DO WHILE .T.
    &C_BODY
    mfield02= SPACE(10)
    mfield03= SPACE(10)
    @ 5, 2 SAY 'Start At Supplier Code :'
    @ 6, 2 SAY 'Stop  At Supplier Code :'
    DO WHILE .T.
        GOTO BOTTOM
        mfield03= splyr_n
        GOTO TOP
        mfield02= splyr_n
        &C_GET
        @ 6, 27 SAY mfield03
        @ 5, 27 GET mfield02 PICTURE '@!'
        READ
        IF READKEY()=4.or.READKEY()=260
            EXIT
        ENDIF
        IF LEN(TRIM(mfield02))=0
            CLOSE DATABASE
            RETURN
        ELSE
            SEEK LTRIM(TRIM(mfield02))
        ENDIF
        IF EOF()
            choice= ' '
            &C_CLEAR
            @ 21, 0 CLEAR
            &C_MESSAGE
            @ 23, 30 SAY ' No Such Supplier Code. '
            &C_GET
            @ 21, 20 SAY ' Press <A> to Abort, any key to Continue. ' GET choice PICTURE '!'
            READ
            IF choice='A'
                CLOSE DATABASE
                RETURN
            ELSE
                &C_CLEAR
                @ 21, 0
                @ 23, 0
                LOOP
            ENDIF
        ELSE
            mfield02= splyr_n
            @ 5, 27 SAY mfield02
        ENDIF
        @ 6, 27 GET mfield03 PICTURE '@!'
        READ
        IF mfield03=SPACE(10)
            CLOSE DATABASE
            RETURN
        ELSE
            SEEK LTRIM(TRIM(mfield03))
        ENDIF
        IF EOF()
            choice= ' '
            &C_CLEAR
            @ 21, 0 CLEAR
            &C_MESSAGE
            @ 23, 30 SAY ' No Such Supplier Code. '
            &C_GET
            @ 21, 20 SAY ' Press <A> to Abort, any key to Continue. ' GET choice PICTURE '!'
            READ
            IF choice='A'
                CLOSE DATABASE
                RETURN
            ELSE
                &C_CLEAR
                @ 21, 0
                @ 23, 0
                LOOP
            ENDIF
        ELSE
            mfield03= splyr_n
            @ 6, 27 SAY mfield03
        ENDIF
        IF READKEY()=4.or.READKEY()=260
            LOOP
        ENDIF
        EXIT
    ENDDO
    choice= 'L'
    DO OPTION8
    IF mfield02>mfield03.and.mfield03<>SPACE(10)
        mtemp= mfield02
        mfield02= mfield03
        mfield03= mtemp
    ENDIF
    SEEK mfield02
    DO CASE
        CASE choice='L'
            &C_CLEAR
            @ 9, 1 CLEAR TO 19, 78
            flag= 1
            row= 9
            DO WHILE .not. EOF().and.splyr_n<=mfield03
                IF flag=1
                    c_list= c_option
                    flag= 0
                ELSE
                    c_list= c_body
                    flag= 1
                ENDIF
                &C_LIST
                @ row, 2 SAY splyr_n PICTURE '@!'
                @ row, 13 SAY splyr_m PICTURE '@!'
                @ row, 44 SAY splyr_p PICTURE '@!'
                @ row, 66 SAY splyr_cl PICTURE '#,###,###.##'
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
                        CLOSE DATABASE
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
                head= 'Supplier List as of '+cdate
                @ 3, 1 SAY 'Page '+LTRIM(STR(pg))
                @ 3, (80-LEN(company))/2 SAY company
                @ 4, (80-LEN(head))/2 SAY head
                ?? CHR(15)
                @ 7, 1 SAY REPLICATE('-',127)
                @ 8, 1 SAY 'CODE       NAME                           ADDRESS                             TEL. NO.             TERM    CR. LIMIT CONTACT'
                @ 9, 1 SAY REPLICATE('-',127)
                row= 9
                DO WHILE .not. EOF().and.splyr_n<=mfield03
                    row= row+1
                    @ row, 1 SAY splyr_n PICTURE '@!'
                    @ row, 12 SAY splyr_m PICTURE '@!'
                    @ row, 43 SAY splyr_ad PICTURE '@!'
                    @ row, 79 SAY splyr_p PICTURE '@!'
                    @ row, 100 SAY splyr_t PICTURE '@!'
                    @ row, 105 SAY splyr_cl PICTURE '#,###,###.##'
                    @ row, 118 SAY splyr_cp PICTURE '@!'
                    SKIP
                    IF EOF().or.splyr_n>mfield03
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
                        @ row+2, 101 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                        stl= 0.00
                        @ 3, 1 SAY 'Page '+LTRIM(STR(pg))
                        @ 3, (80-LEN(head))/2 SAY head
                        ?? CHR(15)
                        @ 6, 1 SAY REPLICATE('-',127)
                        @ 7, 1 SAY 'CODE       NAME                           ADDRESS                             TEL. NO.             TERM    CR. LIMIT CONTACT'
                        @ 8, 1 SAY REPLICATE('-',127)
                        row= 8
                    ENDIF
                ENDDO
                IF EOF().or.splyr_n>mfield03
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
        EXIT
    ENDIF
ENDDO
CLOSE DATABASE
RETURN
 

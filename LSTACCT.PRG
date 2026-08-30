* program.....: LstAcct.prg

SELECT 1
USE ACCTFYL INDEX ACCT_N
DO BRDR2
@ 8, 2 SAY 'ACCT-CODE  ACCOUNT NAME'
DO WHILE .T.
    &C_BODY
    mfield01= SPACE(10)
    mfield02= SPACE(10)
    @ 5, 2 SAY 'Start At Account Code :'
    @ 6, 2 SAY 'Stop  At Account Code :'
    DO WHILE .T.
        GOTO BOTTOM
        mfield02= acct_n
        GOTO TOP
        mfield01= acct_n
        &C_GET
        @ 6, 26 SAY mfield02
        @ 5, 26 GET mfield01 PICTURE '@!'
        READ
        IF READKEY()=4.or.READKEY()=260
            EXIT
        ENDIF
        IF LEN(TRIM(mfield01))=0
            RETURN
        ELSE
            SEEK LTRIM(TRIM(mfield01))
        ENDIF
        IF EOF()
            choice= ' '
            &C_CLEAR
            @ 21, 0 CLEAR
            &C_MESSAGE
            @ 23, 31 SAY ' No Such Account Code. '
            &C_GET
            @ 21, 20 SAY ' Press <A> to Abort, any key to Continue. ' GET choice PICTURE '!'
            READ
            IF choice='A'
                RETURN
            ELSE
                &C_CLEAR
                @ 21, 0
                @ 23, 0
                LOOP
            ENDIF
        ELSE
            mfield01= acct_n
            @ 5, 26 SAY mfield01
        ENDIF
        @ 6, 26 GET mfield02 PICTURE '@!'
        READ
        IF mfield02=SPACE(10)
            RETURN
        ELSE
            SEEK LTRIM(TRIM(mfield02))
        ENDIF
        IF EOF()
            choice= ' '
            &C_CLEAR
            @ 21, 0 CLEAR
            &C_MESSAGE
            @ 23, 31 SAY ' No Such Account Code. '
            &C_GET
            @ 21, 20 SAY ' Press <A> to Abort, any key to Continue. ' GET choice PICTURE '!'
            READ
            IF choice='A'
                RETURN
            ELSE
                &C_CLEAR
                @ 21, 0
                @ 23, 0
                LOOP
            ENDIF
        ELSE
            mfield02= acct_n
            @ 6, 26 SAY mfield02
        ENDIF
        IF READKEY()=4.or.READKEY()=260
            LOOP
        ENDIF
        EXIT
    ENDDO
    choice= 'L'
    DO OPTION8
    IF mfield01>mfield02.and.mfield02<>SPACE(10)
        mtemp= mfield01
        mfield01= mfield02
        mfield02= mtemp
    ENDIF
    SEEK mfield01
    DO CASE
        CASE choice='L'
            &C_CLEAR
            @ 9, 1 CLEAR TO 19, 78
            flag= 1
            row= 9
            DO WHILE .not. EOF().and.acct_n<=mfield02
                IF flag=1
                    c_list= c_option
                    flag= 0
                ELSE
                    c_list= c_body
                    flag= 1
                ENDIF
                &C_LIST
                @ row, 2 SAY acct_n PICTURE '@!'
                @ row, 13 SAY acct_m PICTURE '@!'
                row= row+1
                SKIP
                IF row>18.and..not. EOF().and.acct_n<=mfield02
                    choice= ' '
                    &C_CLEAR
                    @ 21, 0
                    &C_MESSAGE
                    @ 21, 20 SAY 'Press <A> to Abort, any key to continue.' GET choice PICTURE '!'
                    READ
                    IF choice='A'
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
            row= 56
            DO WHILE .T.
                &C_MESSAGE
                @ 23, 50 SAY '...Printing'
                SET CONSOLE OFF
                SET DEVICE TO PRINTER
                SET PRINTER ON
                ?? CHR(27)+CHR(64)
                ?? CHR(18)
                cdate= CMONTH(DATE())+' '+STR(DAY(DATE()),2)+','+STR(YEAR(DATE()),4)
                head= 'List of Account Code as of '+cdate
                DO WHILE .not. EOF().and.acct_n<=mfield02
                    IF row>51.and..not. EOF().and.acct_n<=mfield02
                        IF pg>1
                            row= row+1
                            @ row+3, 75 SAY '...continued on page '+LTRIM(STR(pg))
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
                        ENDIF
                        @ 3, 1 SAY 'Page '+LTRIM(STR(pg))
                        @ 3, (80-LEN(company))/2 SAY company
                        &pBOLD_ON
                        @ 4, (80-LEN(head))/2 SAY head
                        &pBOLD_OFF
                        @ 7, 17 SAY REPLICATE('-',45)
                        @ 8, 17 SAY 'ACCT-CODE     ACCOUNT NAME'
                        @ 9, 17 SAY REPLICATE('-',45)
                        row= 9
                        pg= pg+1
                    ENDIF
                    row= row+1
                    @ row, 17 SAY acct_n PICTURE '@!'
                    @ row, 32 SAY acct_m PICTURE '@!'
                    SKIP
                ENDDO
                ?
                ?? CHR(18)
                EJECT
                SET PRINTER OFF
                SET DEVICE TO SCREEN
                SET CONSOLE ON
                &C_CLEAR
                @ 23, 0
                EXIT
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
        RETURN
    ENDIF
ENDDO
 

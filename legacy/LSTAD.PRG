* program.....: LstAd.prg

SELECT 1
USE ADFYL INDEX AD_N
DO BRDR2
@ 8, 2 SAY 'ADD. CODE  COMPANY NAME                   TEL. NO.             CONTACT PERSON'
DO WHILE .T.
    &C_BODY
    mfield01= SPACE(10)
    mfield02= SPACE(10)
    mfield03= SPACE(10)
    @ 4, 2 SAY 'Area Code             :'
    @ 5, 2 SAY 'Start At Address Code :'
    @ 6, 2 SAY 'Stop  At Address Code :'
    DO WHILE .T.
        &C_GET
        @ 4, 26 GET mfield01 PICTURE '@!'
        READ
        SET FILTER TO
        DO CASE
            CASE LEN(TRIM(mfield01))<>0
                SET FILTER TO co_ac=mfield01
        ENDCASE
        DO WHILE .T.
            GOTO BOTTOM
            mfield03= ad_n
            GOTO TOP
            mfield02= ad_n
            &C_GET
            @ 6, 26 SAY mfield03
            @ 5, 26 GET mfield02 PICTURE '@!'
            READ
            IF READKEY()=4.or.READKEY()=260
                EXIT
            ENDIF
            IF LEN(TRIM(mfield02))=0
                RETURN
            ELSE
                SEEK LTRIM(TRIM(mfield02))
            ENDIF
            IF EOF()
                choice= ' '
                &C_CLEAR
                @ 21, 0 CLEAR
                &C_MESSAGE
                @ 23, 30 SAY ' No Such Address Code. '
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
                mfield02= ad_n
                @ 5, 26 SAY mfield02
            ENDIF
            @ 6, 26 GET mfield03 PICTURE '@!'
            READ
            IF mfield03=SPACE(10)
                RETURN
            ELSE
                SEEK LTRIM(TRIM(mfield03))
            ENDIF
            IF EOF()
                choice= ' '
                &C_CLEAR
                @ 21, 0 CLEAR
                &C_MESSAGE
                @ 23, 30 SAY ' No Such Address Code. '
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
                mfield03= ad_n
                @ 6, 26 SAY mfield03
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
            DO WHILE .not. EOF().and.ad_n<=mfield03
                IF flag=1
                    c_list= c_option
                    flag= 0
                ELSE
                    c_list= c_body
                    flag= 1
                ENDIF
                &C_LIST
                @ row, 2 SAY ad_n PICTURE '@!'
                @ row, 13 SAY co_m PICTURE '@!'
                @ row, 44 SAY co_p PICTURE '@!'
                @ row, 65 SAY co_cp PICTURE '@!'
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
                        RETURN
                    ENDIF
                    &C_CLEAR
                    @ 9, 1 CLEAR TO 19, 78
                    row= 9
                ENDIF
            ENDDO
        CASE choice='P'
            pg= 1
            DO WHILE .T.
                &C_MESSAGE
                @ 23, 50 SAY '...Printing'
                SET CONSOLE OFF
                SET DEVICE TO PRINTER
                SET PRINTER ON
                ?? CHR(27)+CHR(64)
                ?? CHR(18)
                cdate= CMONTH(DATE())+' '+STR(DAY(DATE()),2)+','+STR(YEAR(DATE()),4)
                head= 'Address List as of '+cdate
                head1= ' '
                DO CASE
                    CASE LEN(TRIM(mfield01))<>0
                        head1= 'for Area Code = '+TRIM(mfield01)
                ENDCASE
                @ 3, 1 SAY 'Page '+LTRIM(STR(pg))
                @ 3, (80-LEN(company))/2 SAY company
                @ 4, (80-LEN(head))/2 SAY head
                IF LEN(TRIM(head1))<>0
                    @ 5, (80-LEN(head1))/2 SAY head1
                ENDIF
                ?? CHR(15)
                @ 7, 1 SAY REPLICATE('-',129)
                @ 8, 1 SAY 'ADD-CODE     COMPANY NAME                      ADDRESS                            AREA CODE    TELEPHONE NO.       CONTACT PERSON'
                @ 9, 1 SAY REPLICATE('-',129)
                row= 9
                DO WHILE .not. EOF().and.ad_n<=mfield03
                    row= row+1
                    @ row, 1 SAY ad_n PICTURE '@!'
                    @ row, 14 SAY co_m PICTURE '@!'
                    @ row, 48 SAY co_ad PICTURE '@!'
                    @ row, 87 SAY co_ac PICTURE '@!'
                    @ row, 96 SAY co_p PICTURE '@!'
                    @ row, 120 SAY co_cp PICTURE '@!'
                    SKIP
                    IF EOF().or.ad_n>mfield03
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
                    IF row>55
                        row= row+1
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
                        @ 21, 20 SAY ' Press <A> to Abort, any key to continue. ' GET choice PICTURE '!'
                        READ
                        IF choice='A'
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
                        @ 3, 1 SAY 'Page '+LTRIM(STR(pg))
                        @ 3, (80-LEN(head))/2 SAY head
                        IF LEN(TRIM(head1))<>0
                            @ 4, (80-LEN(head1))/2 SAY head1
                        ENDIF
                        ?? CHR(15)
                        @ 6, 1 SAY REPLICATE('-',129)
                        @ 7, 1 SAY 'ADD-CODE     COMPANY NAME                      ADDRESS                            AREA CODE    TELEPHONE NO.       CONTACT PERSON'
                        @ 8, 1 SAY REPLICATE('-',129)
                        row= 8
                    ENDIF
                ENDDO
                IF EOF().or.ad_n>mfield03
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
        RETURN
    ENDIF
ENDDO
 

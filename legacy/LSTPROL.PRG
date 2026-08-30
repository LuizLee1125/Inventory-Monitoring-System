* program.....: LstProf.prg
*             : promo list
*             : 08/17/02

mtempfyl1= mtempfyl-'.DBF'
mtempfyl2= mtempfyl-'.IDX'
COPY FILE STKFYL.DBF TO &mTEMPFYL1
USE &mTEMPFYL
INDE ON FORM+SPLYR_N + STK_M TO &mTEMPFYL2
SELECT 1
USE &mTEMPFYL INDE &mTEMPFYL EXCL
DO BRDR2
*                   1         2         3         4         5         6         7
*           2345678901234567890123456789012345678901234567890123456789012345678901234567890
@ 8, 2 SAY 'DESCRIPTION                      PRICE     UNIT'
*           123456789012345678901234567890  9,999.99  12345


DO WHILE .T.

    mfield01= SPACE(5)
    mfield02= "C"

    &C_BODY
    @ 5, 2 SAY 'Stock Form     :' 
    @ 6, 2 SAY 'Price Category :' 
    &C_GET
    @ 5, 19 GET mfield01 picture '@!'
    @ 6, 19 GET mfield02 picture '@!' VALID mfield02$"ABCDE"
    READ
    IF LEN(TRIM(mfield01))=0
        CLOSE DATABASE
        RETURN
    ENDIF
    SEEK TRIM(mfield01)
    IF EOF()
        choice= ' '
        &C_CLEAR
        @ 21, 0 CLEAR
        &C_MESSAGE
        @ 23, 30 SAY ' No Such Form Code. '
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
    ENDIF
    SET COLO TO +W/R
    @ 8, 41 say mfield02
    &C_GET
    mfield01= form
    @ 5, 19 SAY mfield01
    prys= 'PRYS_'+mfield02
    choice= 'L'
    DO OPTION8
    DO CASE
        CASE choice='L'
            &C_CLEAR
            @ 9, 1 CLEAR TO 19, 78
            flag= 1
            row= 9
            DO WHILE .not. EOF().and.form=mfield01
                IF flag=1
                    c_list= c_option
                    flag= 0
                ELSE
                    c_list= c_body
                    flag= 1
                ENDIF
                &C_LIST
                @ row, 2  SAY stk_m PICTURE '@!'
                @ ROW, 34 SAY &PRYS PICTURE '#,###.##'
                @ row, 45 SAY qty_u PICTURE '@!'
                row= row+1
                SKIP
                IF EOF().or.form<>mfield01
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
                head= 'Promo List as of '+cdate
                head1= ' '
                DO CASE
                    CASE LEN(TRIM(mfield01))<>0
                        head1= 'for Promo Form = '+TRIM(mfield01)
                ENDCASE
                @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
                ?? CHR(27)+'E'
                @ 1, (80-LEN(company))/2+2 SAY company
                ?? CHR(27)+'F'
                @ 2, (80-LEN(head))/2 SAY head
                IF LEN(TRIM(head1))<>0
                    @ 3, (80-LEN(head1))/2 SAY head1
                ENDIF
                @ 5,16 SAY '================================================'
                @ 6,16 SAY "DESCRIPTION                      PRICE "+mfield02+"   UNIT"
                @ 7,16 SAY '================================================'
                row= 8
                DO WHILE .not. EOF().and.form=mfield01
                    @ row, 16 SAY stk_m PICTURE '@!'
                    @ ROW, 48 SAY &PRYS PICTURE '#,###.##'
                    @ row, 59 SAY qty_u PICTURE '@!'
                    row= row+1
                    SKIP
                    IF EOF().or.form<>mfield01
                        @ ROW+1, 28 say "**** nothing follows ***"
                        ?
                        ?? CHR(27)+'P'
                        EJECT
                        SET PRINTER OFF
                        SET DEVICE TO SCREEN
                        SET CONSOLE ON
                        &C_CLEAR
                        @ 23, 0
                        EXIT
                    ENDIF
                    IF row>54
                        @ row+2, 50 SAY '...continued on page '+LTRIM(STR(pg+1))
                        ?
                        ?? CHR(27)+'P'
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
                        @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
                        ?? CHR(27)+'E'
                        @ 1, (80-LEN(company))/2+2 SAY company
                        ?? CHR(27)+'F'
                        @ 2, (80-LEN(head))/2 SAY head
                        IF LEN(TRIM(head1))<>0
                            @ 3, (80-LEN(head1))/2 SAY head1
                        ENDIF
                        @ 5,16 SAY '================================================'
                        @ 6,16 SAY "DESCRIPTION                      PRICE "+mfield02+"   UNIT"
                        @ 7,16 SAY '================================================'
                        row= 8
                    ENDIF
                ENDDO
                IF EOF().or.form<>mfield01
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
 

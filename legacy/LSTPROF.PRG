* program.....: LstProf.prg
*             : promo form

mtempfyl1= mtempfyl-'.DBF'
mtempfyl2= mtempfyl-'.IDX'
COPY FILE STKFYL.DBF TO &mTEMPFYL1
USE &mTEMPFYL
INDE ON FORM+SPLYR_N + STK_M TO &mTEMPFYL2
SELECT 1
USE &mTEMPFYL INDE &mTEMPFYL EXCL
DO BRDR2
@ 8, 2 SAY 'DESCRIPTION                    DATE    STOCKS AVAIL.     PRICE'

DO WHILE .T.
    mfield01= SPACE(5)
    mfield02= SPACE(1)

    &C_BODY
    @ 5, 2 SAY 'Stock Form     :' 
    @ 6, 2 SAY 'Price Category :' 

    &C_GET
    @ 5, 19 GET mfield01 picture '@!'
    @ 6, 19 GET mfield02 picture '@!'
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
                @ row, 2 SAY stk_m PICTURE '@!'
                IF expiry_d>CTOD('01/01/01')
                    @ row, 33 SAY expiry_d
                ENDIF
                @ row, 42 SAY qty1 PICTURE '###,###'
                @ row, 50 SAY qty_u PICTURE '@!'
                @ ROW, 55 SAY &PRYS PICTURE '##,###.##'
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
                head= 'Promo Form as of '+cdate
                head1= ' '
                DO CASE
                    CASE LEN(TRIM(mfield01))<>0
                        head1= 'for = '+TRIM(mfield01)
                ENDCASE
                @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
                ?? CHR(27)+'E'
                @ 1, (80-LEN(company))/2 SAY company
                ?? CHR(27)+'F'
                @ 2, (80-LEN(head))/2 SAY head
                IF LEN(TRIM(head1))<>0
                    @ 3, (80-LEN(head1))/2 SAY head1
                ENDIF
                ?? CHR(27)+'M'
                @ 5, 2 SAY REPLICATE('-',93)
                ?? CHR(27)+'E'
                @ 6, 2 SAY 'DESCRIPTION                   EXPIRY-DATE  STOCKS-AVAIL.       PRICE   INVENTORY   ORDER-QTY.'
                ?? CHR(27)+'F'
                @ 7, 2 SAY REPLICATE('-',93)
                row= 7
                DO WHILE .not. EOF().and.form=mfield01
                    row= row+1
                    @ row, 2 SAY stk_m PICTURE '@!'
                    IF expiry_d>CTOD('01/01/01')
                        @ row, 35 SAY expiry_d
                    ENDIF
                    @ row, 46 SAY qty1 PICTURE '###,###'
                    @ row, 54 SAY qty_u PICTURE '@!'
                    @ ROW, 61 SAY &PRYS PICTURE '##,###.##'
                    @ row, 73 SAY '_________'
                    @ row, 85 SAY '_________'
                    SKIP
                    IF EOF().or.form<>mfield01
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
                    IF row>52
                        row= row+1
                        @ row+2, 69 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                        @ 1, (80-LEN(company))/2 SAY company
                        ?? CHR(27)+'F'
                        @ 2, (80-LEN(head))/2 SAY head
                        IF LEN(TRIM(head1))<>0
                            @ 3, (80-LEN(head1))/2 SAY head1
                        ENDIF
                        ?? CHR(27)+'M'
                        @ 5, 2 SAY REPLICATE('-',93)
                        ?? CHR(27)+'E'
                        @ 6, 2 SAY 'DESCRIPTION                   EXPIRY-DATE  STOCKS-AVAIL.       PRICE   INVENTORY   ORDER-QTY.'
                        ?? CHR(27)+'F'
                        @ 7, 2 SAY REPLICATE('-',93)
                        row= 7
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
 

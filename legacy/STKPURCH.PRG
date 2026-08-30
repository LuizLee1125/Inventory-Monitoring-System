* program.....: stkpurch.prg
*             : stocks purchased given a specified date
*             : 08/25/2003

set cent on

DO BRDR2

*                   1         2         3         4         5         6         7
*           234567890123456789012345678901234567890123456789012345678901234567890123456789
@ 8, 2 SAY 'Pur.Date Stock Code Stock Description              QtyPur   Price E  OnHand'
*           99/99/99 xxxxxxxxxx 123456789012345678901234567890 99,999  9,999.99  99,999'

sele 3
     use stkfyl index stk_n
sele 2
     USE STKREC INDEX TRANS_CN
sele 1
     use purfyl index pur_d

DO WHILE .T.
    &C_HEAD
    @ 20, 1 SAY SPACE(78)
    &C_MESSAGE
    @ 21, 20 SAY ' NOTE: Press <Enter> to Return to Main Menu. '
    &C_BODY
    @ 5, 3  SAY 'Start At Issued Date :'
    @ 6, 3  SAY 'Stop  At Issued Date :'
    minv_d= CTOD('01/01/2003')
    GOTO BOTTOM
    mfield2= DATE()
    GOTO TOP
    mfield1= CTOD('  /  /  ')
    &C_GET
    @ 6, 26 SAY mfield2 picture '99/99/9999'
    @ 5, 26 GET mfield1 PICTURE '99/99/9999'
    READ
    IF mfield1=CTOD('  /  /  ')
        close data
        set cent off
        RETURN
    ELSE
        SEEK mfield1
        IF EOF()
            GOTO TOP
            IF mfield1>inv_d
                GOTO BOTTOM
                IF mfield1<inv_d
                    SKIP
                    DO WHILE EOF()
                        mfield1= mfield1+1
                        SEEK mfield1
                    ENDDO
                ENDIF
            ENDIF
            mfield1= inv_d
            confirm= ' '
            &C_CLEAR
            @ 21, 0 CLEAR
            &C_MESSAGE
            @ 23, 23 SAY ' Earliest Recorded Date is '+DTOC(mfield1)+'. '
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
            @ 5, 26 SAY mfield1 picture '99/99/9999'
        ENDIF
    ENDIF
    @ 6, 26 GET mfield2 PICTURE '99/99/9999'
    READ
    SEEK mfield2
    IF EOF()
        GOTO BOTTOM
        mfield2= inv_d
        confirm= ' '
        &C_CLEAR
        @ 21, 0 CLEAR
        &C_MESSAGE
        @ 23, 23 SAY ' Latest Recorded Date is '+DTOC(mfield2)+'. '
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
        @ 6, 26 SAY mfield2
    ENDIF
    SET CENTURY OFF
    choice= 'L'
    DO OPTION8
    IF mfield1>mfield2
        mtemp= mfield1
        mfield1= mfield2
        mfield2= mtemp
    ENDIF
    *suspend
    SEEK mfield1
    *suspend
    &C_HEAD
    SET EXACT ON
    DO CASE
        CASE choice='L'
            STORE 0.00 TO ttl1, ttl2, ttl3, stl1, stl2, stl3, stl4, gtl1, gtl2, gtl3, gtl4
            &C_CLEAR
            @ 10, 1 CLEAR TO 19, 78
            flag= 1
            row= 9
            DO WHILE .not. EOF().and.inv_d<=mfield2
                minv_n= 'P'+inv_n
                STORE 0.00 TO ttl1, ttl2, ttl3
                SELECT 2
                SEEK minv_n

                DO WHILE .not. EOF().and.minv_n=trans_c+trans_n.and.mfield2>=trans_d
                   IF flag=1
                      c_list= c_option
                      flag= 0
                   ELSE
                      c_list= c_body
                      flag= 1
                   ENDIF
                   &C_LIST

                    @ row,  2 SAY trans_d  PICTURE '99/99/99'
                    @ row, 11 SAY stk_n    PICTURE '@!'
                    @ row, 22 SAY stk_m    PICTURE '@!'
                    @ row, 53 SAY issue_q  PICTURE '##,###'
                    stor stk_n to sv_stk_n
                    sele 3
                    seek sv_stk_n
                    @ row, 61 SAY prys_e   PICTURE '#,###.##'
                    @ row, 71 say qty1     picture '##,###'
                    sele 2
                    row= row+1
                    IF row=20
                       choice= ' '
                       &C_CLEAR
                       @ 21, 0
                       &C_MESSAGE
                       @ 21, 20 SAY ' Press <A> to Abort, any key to continue.' GET choice PICTURE '!'
                       READ
                       IF choice='A'
                           close data
                           set cent off
                           RETURN
                       ENDIF
                       &C_CLEAR
                       @ 9, 1 CLEAR TO 19, 78
                       row= 9
                       STORE 0.00 TO stl1, stl2, stl3, stl4
                    ENDIF
                    SKIP
                ENDDO
                sele 1
                SKIP
                IF EOF()
                   EXIT
                ENDIF
                IF row=20
                    choice= ' '
                    &C_CLEAR
                    @ 21, 0
                    &C_MESSAGE
                    @ 21, 20 SAY ' Press <A> to Abort, any key to continue.' GET choice PICTURE '!'
                    READ
                    IF choice='A'
                        close data
                        set cent off
                        RETURN
                    ENDIF
                    &C_CLEAR
                    @ 9, 1 CLEAR TO 19, 78
                    row= 9
                    STORE 0.00 TO stl1, stl2, stl3, stl4
                ENDIF
            ENDDO
        CASE choice='P'
            do testprt
            &C_MESSAGE
            @ 23, 50 SAY '...Printing'
            store 1 to pg
            SET CONSOLE OFF
            SET DEVICE TO PRINTER
            SET PRINTER ON
            ?? CHR(27)+CHR(64)
            ?? CHR(18)
            cdate= CMONTH(DATE())+' '+STR(DAY(DATE()),2)+', '+STR(YEAR(DATE()),4)
            head= 'Stock Purchase List from '+DTOC(mfield1)+' to '+DTOC(mfield2)
            @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
            @ 1, (80-LEN(company))/2 SAY company
            @ 2, (80-LEN(head))/2 SAY head

            *                   1         2         3         4         5         6         7
            *           234567890123456789012345678901234567890123456789012345678901234567890123456789
            @ 4, 2 SAY '---------------------------------------------------------------------------'
            @ 5, 2 SAY 'Pur.Date Stock Code Stock Description              QtyPur   Price E  OnHand'
            @ 6, 2 SAY '---------------------------------------------------------------------------'
            *           99/99/99 xxxxxxxxxx 123456789012345678901234567890 99,999  9,999.99  99,999'
            row= 7
            DO WHILE .not. EOF().and.inv_d<=mfield2
                minv_n= 'P'+inv_n
                STORE 0.00 TO ttl1, ttl2, ttl3
                SELECT 2
                SEEK minv_n

                DO WHILE .not. EOF().and.minv_n=trans_c+trans_n.and.mfield2>=trans_d
                    @ row,  2 SAY trans_d  PICTURE '99/99/99'
                    @ row, 11 SAY stk_n    PICTURE '@!'
                    @ row, 22 SAY stk_m    PICTURE '@!'
                    @ row, 53 SAY issue_q  PICTURE '##,###'
                    stor stk_n to sv_stk_n
                    sele 3
                    seek sv_stk_n
                    @ row, 61 SAY prys_e   PICTURE '#,###.##'
                    @ row, 71 say qty1     picture '##,###'
                    sele 2
                    row= row+1
                    IF row>=53
                       @ row+1, 55 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                          CLOSE DATA
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
                       @ 1, (80-LEN(company))/2 SAY company
                       @ 2, (80-LEN(head))/2 SAY head

                       *                   1         2         3         4         5         6         7
                       *           234567890123456789012345678901234567890123456789012345678901234567890123456789
                       @ 4, 2 SAY '---------------------------------------------------------------------------'
                       @ 5, 2 SAY 'Pur.Date Stock Code Stock Description              QtyPur   Price E  OnHand'
                       @ 6, 2 SAY '---------------------------------------------------------------------------'
                       *           99/99/99 xxxxxxxxxx 123456789012345678901234567890 99,999  9,999.99  99,999'
                       row= 7
                    ENDIF
                    SKIP
                ENDDO
                sele 1
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

        OTHERWISE
            SET CENTURY Off
            CLOSE DATA
            RETURN
    ENDCASE

    sele 1
    SET CENTURY ON
    choice= ' '
    confirm="N"
    &C_CLEAR
    @ 21, 0
    &C_MESSAGE
    @ 21, 24 SAY ' Return to Previous Menu (y/n). ' GET confirm PICTURE '!'
    READ
    IF confirm='N'
        &C_CLEAR
        @ 9, 1 CLEAR TO 19, 78
        @ 21, 0
        row= 9
        LOOP
    ELSE
        CLOSE DATA
        set cent off
        RETURN
    ENDIF
ENDDO
 
CLOSE DATA
RETURN

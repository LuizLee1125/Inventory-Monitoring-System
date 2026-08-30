* program.....: LstSale.prg
*             : 07/25

DO BRDR2
*                    1         2         3         4         5         6         7
*           1234567890123456789012345678901234567890123456789012345678901234567890123456789
@ 8, 1 SAY 'SI DATE  INVOICE #           COMP. NO.  CUST. CODE    VAT AMOUNT    NET AMOUNT'
*           99/99/99 1234567890123456789 9999999999 9999999999 99,999,999.99 99,999,999.99
*                                                                 Start Date: 99/99/9999

save screen to atlscreen

SELECT 1
   USE SIFYL INDEX SI_DINV

DO WHILE .T.
    &C_HEAD
    @ 20, 1 SAY SPACE(78)
    &C_MESSAGE
    @ 21, 20 SAY ' NOTE: Press <Enter> to Return to Main Menu. '
    &C_BODY
    @ 5, 3 SAY 'Start At Reference # :'
    @ 6, 3 SAY 'Stop  At Reference # :'
    @ 5,55 SAY 'Start Date:'
    @ 6,55 SAY '  End Date:'

    SET CENT ON
    MFIELD1=0
    MFIELD2=0
    MFIELD3=CTOD('01/01/2010')
    MFIELD4=DATE()

    &C_GET
    @ 5, 26 GET mfield1 PICTURE '9999999999'
    @ 6, 26 GET mfield2 PICTURE '9999999999'
    @ 5, 67 GET mfield3 PICTURE '99/99/9999'
    @ 6, 67 GET mfield4 PICTURE '99/99/9999'
    READ
    IF MFIELD1<=0
       CLOSE DATA
       SET CENT OFF
       RETURN
    ENDIF

    * filter the database using start reference and ending reference

    copy stru to tmp_sale fields inv_n, cust_n, cust_m, inv_d, si_rem, net_a

   *copy to tmp_sale fields inv_n, cust_n, cust_m, inv_d, si_rem, net_a for (val(si_rem)>=mfield1 .and. val(si_rem)<=mfield2) .AND. INV_D>=CTOD('11/02/2010')
   *set filt to (val(si_rem)>=mfield1 .and. val(si_rem)<=mfield2) .AND. INV_D>=CTOD('11/02/2010')
   *go top
    sele 2
       use tmp_sale
       index on si_rem to tmp_srem
       
    sele 1
    *go 19400
    do while .not. eof()
       if .NOT. (INV_D>=MFIELD3 .AND. INV_D<=MFIELD4)
          skip
          loop
       endif
       if (val(si_rem)>=mfield1 .and. val(si_rem)<=mfield2))
          sele 2
          append blank
          replace inv_n   with sifyl->inv_n
          replace cust_n  with sifyl->cust_n
          replace cust_m  with sifyl->cust_m
          replace inv_d   with sifyl->inv_d
          replace si_rem  with sifyl->si_rem
          replace net_a   with sifyl->net_a
          unlock
       endif
       sele 1
       skip
    enddo
    sele 2
    go top

    choice= 'L'
    DO OPTION8
    DO CASE
        CASE choice='L'
            STORE 0.00 TO stl1, stl2, stl3, stl4, gtl1, gtl2, gtl3, gtl4
            &C_CLEAR
            @ 10, 1 CLEAR TO 19, 78
            flag= 1
            row= 9
            *SUSPEND
            DO WHILE .not. EOF()
                IF flag=1
                    c_list= c_option
                    flag= 0
                ELSE
                    c_list= c_body
                    flag= 1
                ENDIF
                &C_LIST
                stl1= stl1+net_a
                stl2= stl2+ROUND((NET_A/1.12)*.12,2)
                gtl1= gtl1+net_a
                gtl2= gtl2+ROUND((NET_A/1.12)*.12,2)
                set cent off
                @ row,  1 SAY inv_d   PICTURE '99/99/99'
                set cent on
                @ row, 10 SAY left(si_rem,19)  PICTURE '@!'
                @ row, 30 SAY inv_n   PICTURE '@!'
                @ row, 41 SAY cust_n  PICTURE '@!'
                @ row, 52 SAY ROUND((NET_A/1.12)*.12,2) picture '##,###,###.##'
                @ row, 66 SAY net_a   PICTURE '##,###,###.##'
                row= row+1
                SKIP
                IF EOF()
                    EXIT
                ENDIF
                IF row=19
                    &C_HEAD
                    @ 19, 1 SAY SPACE(78)
                    @ 19, 10 SAY 'SUB   TOTAL'
                    @ 19, 52 SAY stl2 PICTURE '##,###,###.##'
                    @ 19, 66 SAY stl1 PICTURE '##,###,###.##'
                    @ 20, 1 SAY SPACE(78)
                    @ 20, 10 SAY 'GRAND TOTAL'
                    @ 20, 52 SAY gtl2 PICTURE '##,###,###.##'
                    @ 20, 66 SAY gtl1 PICTURE '##,###,###.##'
                    choice= ' '
                    &C_CLEAR
                    @ 21, 0
                    &C_MESSAGE
                    @ 21, 20 SAY ' Press <A> to Abort, any key to continue.' GET choice PICTURE '!'
                    READ
                    IF choice='A'
                        SET CENTURY Off
                        CLOSE DATA
                        RETURN
                    ENDIF
                    &C_CLEAR
                    @ 9, 1 CLEAR TO 19, 78
                    row= 9
                    STORE 0.00 TO stl1, stl2, stl3, stl4
                ENDIF
            ENDDO
            &C_HEAD
            @ 19, 1 SAY SPACE(78)
            @ 19, 10 SAY 'SUB   TOTAL'
            @ 19, 52 SAY stl2 PICTURE '##,###,###.##'
            @ 19, 66 SAY stl1 PICTURE '##,###,###.##'
            @ 20, 1 SAY SPACE(78)
            @ 20, 10 SAY 'GRAND TOTAL'
            @ 20, 52 SAY gtl2 PICTURE '##,###,###.##'
            @ 20, 66 SAY gtl1 PICTURE '##,###,###.##'
        CASE choice='P'
            pg= 1
            STORE 0.00 TO stl1, stl2, stl3, stl4, gtl1, gtl2, gtl3, gtl4
            DO WHILE .T.
                &C_MESSAGE
                @ 23, 50 SAY '...Printing'
                SET CONSOLE OFF
                SET DEVICE TO PRINTER
                SET PRINTER ON
                *?? CHR(27)+CHR(64)
                *?? CHR(18)
                cdate= CMONTH(DATE())+' '+STR(DAY(DATE()),2)+','+STR(YEAR(DATE()),4)
                head= 'Sales Summary from Sales Invoice '+ltrim(str(mfield1))+' to '+ltrim(str(mfield2))
                @ 3, 1 SAY 'Page '+LTRIM(STR(pg))
                @ 3, (80-LEN(company))/2 SAY company
                @ 4, (80-LEN(head))/2 SAY head
                *?? CHR(15)
                *              1         2         3         4         5         6         7         8         9         10        110       120
                *           7890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
               *@ 6, 7 SAY '----------------------------------------------------------------------------------------------------------------------'
               *@ 7, 7 SAY 'SI DATE        SI NO.           CUSTOMER CODE       SI AMOUNT         NET AMOUNT         TOTAL COST       GROSS PROFIT'
               *@ 8, 7 SAY '----------------------------------------------------------------------------------------------------------------------'
                *           99/99/99       xxxxxxxxxx       xxxxxxxxxx       9,999,999.99         999,999.99

                @ 6, 1 SAY '------------------------------------------------------------------------------'
                @ 7, 1 SAY 'SI DATE  INVOICE #           COMP. NO.  CUST. CODE    VAT AMOUNT    NET AMOUNT'
                @ 8, 1 SAY '------------------------------------------------------------------------------'
                *           99/99/99  XXXXXXXXXX   XXXXXXXXXXXXXXX   XXXXXXXXXX    9,999,999.99     9,999,999.99     9,999,999.99     9,999,999.99

                row= 9
                DO WHILE .not. EOF()

                   stl1= stl1+net_a
                   stl2= stl2+ROUND((NET_A/1.12)*.12,2)
                   gtl1= gtl1+net_a
                   gtl2= gtl2+ROUND((NET_A/1.12)*.12,2)
                   set cent off
                   @ row,  1 SAY inv_d   PICTURE '99/99/99'
                   set cent on
                   @ row, 10 SAY left(si_rem,19)  PICTURE '@!'
                   @ row, 30 SAY inv_n   PICTURE '@!'
                   @ row, 41 SAY cust_n  PICTURE '@!'
                   @ row, 52 SAY ROUND((NET_A/1.12)*.12,2) picture '##,###,###.##'
                   @ row, 66 SAY net_a   PICTURE '##,###,###.##'
                   row= row+1

                   SKIP
                   IF row>53
                       @ row+1, 52 say '-------------'
                       @ row+1, 66 say '-------------'
                       @ row+2, 10 SAY 'SUB   TOTAL'
                       @ row+2, 52 SAY stl2 PICTURE '##,###,###.##'
                       @ row+2, 66 SAY stl1 PICTURE '##,###,###.##'
                       @ row+4,107 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                        SET CENTURY Off
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
                     @ 3, 1 SAY 'Page '+LTRIM(STR(pg))
                     @ 3, (80-LEN(head))/2 SAY head
                     *?? CHR(15)
                     @ 5, 1 SAY '------------------------------------------------------------------------------'
                     @ 6, 1 SAY 'SI DATE  INVOICE #           COMP. NO.  CUST. CODE    VAT AMOUNT    NET AMOUNT'
                     @ 7, 1 SAY '------------------------------------------------------------------------------'

                     row= 7
                     store 0 to stl1, stl2, stl3, stl4
                  ENDIF
                ENDDO
                IF EOF().or.inv_d>mfield2
                   IF pg>1
                       @ row+1, 52 say '-------------'
                       @ row+1, 66 say '-------------'
                       @ row+2, 10 SAY 'SUB   TOTAL'
                       @ row+2, 52 SAY stl2 PICTURE '##,###,###.##'
                       @ row+2, 66 SAY stl1 PICTURE '##,###,###.##'
                       row= row+2
                   ENDIF
                   @ row+1, 52 say '============='
                   @ row+1, 66 say '============='
                   @ row+2, 10 SAY 'GRAND TOTAL'
                   @ row+2, 52 SAY gtl2 PICTURE '##,###,###.##'
                   @ row+2, 66 SAY gtl1 PICTURE '##,###,###.##'
                   @ row+3, 52 say '============='
                   @ row+3, 66 say '============='
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
        close data
        sele 1
           USE SIFYL INDEX SI_DINV
        LOOP
    ELSE
        CLOSE DATA
        set cent off
        RETURN
    ENDIF
ENDDO
 
CLOSE DATA
RETURN

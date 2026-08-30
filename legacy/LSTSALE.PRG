* program.....: LstSale.prg
*             : 07/25

DO BRDR2
@ 8, 2 SAY 'SI DATE   SI NO.     CUST.CODE     T. AMT.   NET AMT.     T.COST   G.PROFIT'

save screen to atlscreen
atlmsg="generate totals only (y/n)  "
atlopt="N"
atllen=len(atlmsg)
set colo to rb/rb
@ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
set colo to +w/rb
@ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
@ 12,41-atllen/2 say atlmsg
@ 12,40-atllen/2+len(atlmsg) get atlopt pict "Y" valid atlopt$"YyNn"
read
restore screen from atlscreen

if atlopt="Y"
   do lstsalet
   return
endif

SELECT 1
   USE SIFYL INDEX SI_DINV

DO WHILE .T.
    &C_HEAD
    @ 20, 1 SAY SPACE(78)
    &C_MESSAGE
    @ 21, 20 SAY ' NOTE: Press <Enter> to Return to Main Menu. '
    &C_BODY
    @ 5, 3 SAY 'Start At Issued Date :'
    @ 6, 3 SAY 'Stop  At Issued Date :'
    @ 5,43 SAY 'Territory :'
    @ 6,43 SAY '     Area :'
    SET CENT ON
    minv_d= CTOD('01/01/2000')
    GOTO BOTTOM
    mfield2= DATE()
    GOTO TOP
    mfield1= CTOD('  /  /  ')
    &C_GET
    @ 6, 26 SAY mfield2
    @ 5, 26 GET mfield1 PICTURE '@!'
    READ
    IF mfield1=CTOD('  /  /  ')
        CLOSE DATA
        set cent off
        RETURN
    ELSE
        invd_key=str(year(mfield1),4)+SUBSTR(DTOC(mfield1),1,5)
        SEEK invd_key
        IF EOF()
            GOTO TOP
            IF mfield1>inv_d
                GOTO BOTTOM
                IF mfield1<inv_d
                    SKIP
                    DO WHILE EOF()
                        mfield1= mfield1+1
                        invd_key=str(year(mfield1),4)+SUBSTR(DTOC(mfield1),1,5)
                        SEEK invd_key
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
            @ 5, 26 SAY mfield1
        ENDIF
    ENDIF
    @ 6, 26 GET mfield2 PICTURE '@!'
    READ
    invd_key=str(year(mfield2),4)+SUBSTR(DTOC(mfield2),1,5)
    SEEK invd_key
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
    x_terri = space(10)
    x_area  = space(10)
    @ 5,55 get x_terri pict '@!'
    @ 6,55 get x_area  pict '@!'
    read
    SET CENTURY OFF
    choice= 'L'
    DO OPTION8
    IF mfield1>mfield2
        mtemp= mfield1
        mfield1= mfield2
        mfield2= mtemp
    ENDIF
    invd_key=str(year(mfield1),4)+SUBSTR(DTOC(mfield1),1,5)
    SEEK invd_key
    DO CASE
        CASE choice='L'
            STORE 0.00 TO stl1, stl2, stl3, stl4, gtl1, gtl2, gtl3, gtl4
            &C_CLEAR
            @ 10, 1 CLEAR TO 19, 78
            flag= 1
            row= 9
            *SUSPEND
            DO WHILE .not. EOF().and.inv_d<=mfield2
            if cust_s=trim(x_terri) .and. cust_ac=trim(x_area)
                IF flag=1
                    c_list= c_option
                    flag= 0
                ELSE
                    c_list= c_body
                    flag= 1
                ENDIF
                &C_LIST
                stl1= stl1+inv_a
                stl2= stl2+net_a
                stl3= stl3+inv_c
                stl4= stl4+net_a-inv_c
                gtl1= gtl1+inv_a
                gtl2= gtl2+net_a
                gtl3= gtl3+inv_c
                gtl4= gtl4+net_a-inv_c
                @ row,  2 SAY inv_d   PICTURE '99/99/99'
                @ row, 12 SAY inv_n   PICTURE '@!'
                @ row, 23 SAY cust_n  PICTURE '@!'
                @ row, 34 SAY inv_a   PICTURE '###,###.##'
                @ row, 45 SAY net_a   PICTURE '###,###.##'
                if muser="ADMIN" .OR.  muser="BERDY"
                   @ row, 56 SAY inv_c       PICTURE '###,###.##'
                   @ row, 67 SAY net_a-inv_c PICTURE '###,###.##'
                else
                   @ row, 56 say '    --    '
                   @ row, 67 say '    --    '
                endif
                row= row+1
             endif
                SKIP
                IF EOF()
                    EXIT
                ENDIF
                IF row=19
                    &C_HEAD
                    @ 19, 1 SAY SPACE(78)
                    @ 19, 10 SAY 'SUB   TOTAL'
                    @ 19, 34 SAY stl1 PICTURE '#######.##'
                    @ 19, 45 SAY stl2 PICTURE '#######.##'
                    if muser="ADMIN" .OR.  muser="BERDY"
                       @ 19, 56 SAY stl3 PICTURE '#######.##'
                       @ 19, 67 SAY stl4 PICTURE '#######.##'
                    else
                       @ 19, 56 say '    --    '
                       @ 19, 67 say '    --    '
                    endif
                    @ 20, 1 SAY SPACE(78)
                    @ 20, 10 SAY 'GRAND TOTAL'
                    @ 20, 33 SAY gtl1 PICTURE '########.##'
                    @ 20, 44 SAY gtl2 PICTURE '########.##'
                    if muser="ADMIN" .OR.  muser="BERDY"
                       @ 20, 55 SAY gtl3 PICTURE '########.##'
                       @ 20, 66 SAY gtl4 PICTURE '########.##'
                    else
                       @ 20, 56 say '    --    '
                       @ 20, 67 say '    --    '
                    endif
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
            if muser="ADMIN" .OR.  muser="BERDY"
               @ 19, 34 SAY stl1 PICTURE '#######.##'
               @ 19, 45 SAY stl2 PICTURE '#######.##'
               @ 19, 56 SAY stl3 PICTURE '#######.##'
               @ 19, 67 SAY stl4 PICTURE '#######.##'
            else
               @ 19, 34 say stl1 PICTURE '#######.##'
               @ 19, 45 say stl2 PICTURE '#######.##'
               @ 19, 56 say '    --    '
               @ 19, 67 say '    --    '
            endif
            @ 20, 1 SAY SPACE(78)
            @ 20, 10 SAY 'GRAND TOTAL'
            if muser="ADMIN" .OR.  muser="BERDY"
               @ 20, 33 SAY gtl1 PICTURE '########.##'
               @ 20, 44 SAY gtl2 PICTURE '########.##'
               @ 20, 55 SAY gtl3 PICTURE '########.##'
               @ 20, 66 SAY gtl4 PICTURE '########.##'
            else
               @ 20, 33 SAY gtl1 PICTURE '########.##'
               @ 20, 44 SAY gtl2 PICTURE '########.##'
               @ 20, 54 SAY gtl3 PICTURE '    --    '
               @ 20, 65 SAY gtl4 PICTURE '    --    '
            endif
        CASE choice='P'
            pg= 1
            STORE 0.00 TO stl1, stl2, stl3, stl4, gtl1, gtl2, gtl3, gtl4
            DO WHILE .T.
                &C_MESSAGE
                @ 23, 50 SAY '...Printing'
                SET CONSOLE OFF
                SET DEVICE TO PRINTER
                SET PRINTER ON
                ?? CHR(27)+CHR(64)
                ?? CHR(18)
                cdate= CMONTH(DATE())+' '+STR(DAY(DATE()),2)+','+STR(YEAR(DATE()),4)
                head= 'Sales Summary from '+DTOC(mfield1)+' to '+DTOC(mfield2)
                @ 3, 1 SAY 'Page '+LTRIM(STR(pg))
                @ 3, (80-LEN(company))/2 SAY company
                @ 4, (80-LEN(head))/2 SAY head
                ?? CHR(15)
                *              1         2         3         4         5         6         7         8         9         10        110       120
                *           7890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
               *@ 6, 7 SAY '----------------------------------------------------------------------------------------------------------------------'
               *@ 7, 7 SAY 'SI DATE        SI NO.           CUSTOMER CODE       SI AMOUNT         NET AMOUNT         TOTAL COST       GROSS PROFIT'
               *@ 8, 7 SAY '----------------------------------------------------------------------------------------------------------------------'
                *           99/99/99       xxxxxxxxxx       xxxxxxxxxx       9,999,999.99         999,999.99

                @ 6, 7 SAY '----------------------------------------------------------------------------------------------------------------------'
                @ 7, 7 SAY 'SI DATE   COMPUTER #   REMARKS           CUST. CODE       SI AMOUNT       NET AMOUNT       TOTAL COST     GROSS PROFIT'
                @ 8, 7 SAY '----------------------------------------------------------------------------------------------------------------------'
                *           99/99/99  XXXXXXXXXX   XXXXXXXXXXXXXXX   XXXXXXXXXX    9,999,999.99     9,999,999.99     9,999,999.99     9,999,999.99

                row= 8
                DO WHILE .not. EOF().and.inv_d<=mfield2
                  IF cust_s=trim(x_terri) .and. cust_ac=trim(x_area)
                     stl1= stl1+inv_a
                     gtl1= gtl1+inv_a
                     stl2= stl2+net_a
                     gtl2= gtl2+net_a
                     stl3= stl3+inv_c
                     gtl3= gtl3+inv_c
                     stl4= stl4+net_a-inv_c
                     gtl4= gtl4+net_a-inv_c
                     row= row+1
                     IF minv_d<>inv_d
                        minv_d= inv_d
                        @ row, 7 SAY inv_d PICTURE '99/99/99'
                     ENDIF
                     @ row, 17 SAY inv_n PICTURE '@!'
                     @ row, 30 SAY left(si_rem,17) PICTURE '@!'
                     @ row, 48 SAY cust_n PICTURE '@!'
                     @ row, 62 SAY inv_a PICTURE '#,###,###.##'
                     @ row, 79 SAY net_a PICTURE '#,###,###.##'
                     if muser="ADMIN" .OR.  muser="BERDY"
                        @ row, 96 SAY inv_c PICTURE '#,###,###.##'
                        @ row, 113 SAY net_a-inv_c PICTURE '#,###,###.##'
                     else
                        @ row, 96  SAY '    ---     '
                        @ row, 113 SAY '    ---     '
                     endif
                  ENDIF
                  SKIP
                  IF row>53
                     @ row+1, 62 SAY REPLICATE('-',63)
                     @ row+2, 61 SAY stl1 PICTURE '##,###,###.##'
                     @ row+2, 78 SAY stl2 PICTURE '##,###,###.##'
                     if muser="ADMIN" .OR.  muser="BERDY"
                        @ row+2, 95 SAY stl3 PICTURE '##,###,###.##'
                        @ row+2, 112 SAY stl4 PICTURE '##,###,###.##'
                     else
                        @ row+2, 95  SAY '     ---     '
                        @ row+2, 112 SAY '     ---     '
                     endif
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
                     ?? CHR(15)
                    *@ 5, 7 SAY '----------------------------------------------------------------------------------------------------------------------'
                    *@ 6, 7 SAY 'SI DATE        SI NO.           CUSTOMER CODE       SI AMOUNT         NET AMOUNT         TOTAL COST       GROSS PROFIT'
                    *@ 7, 7 SAY '----------------------------------------------------------------------------------------------------------------------'
                     @ 5, 7 SAY '----------------------------------------------------------------------------------------------------------------------'
                     @ 6, 7 SAY 'SI DATE   COMPUTER #   REMARKS           CUST. CODE       SI AMOUNT       NET AMOUNT       TOTAL COST     GROSS PROFIT'
                     @ 7, 7 SAY '----------------------------------------------------------------------------------------------------------------------'
                     row= 7
                     store 0 to stl1, stl2, stl3, stl4
                  ENDIF
                ENDDO
                IF EOF().or.inv_d>mfield2
                   IF pg>1
                        @ row+1, 62 SAY REPLICATE('-',63)
                        @ row+2, 62 SAY stl1 PICTURE '##,###,###.##'
                        @ row+2, 78 SAY stl2 PICTURE '##,###,###.##'
                        if muser="ADMIN" .OR.  muser="BERDY"
                           @ row+2, 95 SAY stl3 PICTURE '##,###,###.##'
                           @ row+2, 112 SAY stl4 PICTURE '##,###,###.##'
                        else
                           @ row+2, 95  SAY '     ---     '
                           @ row+2, 112 SAY '     ---     '
                        endif
                        row= row+2
                   ENDIF
                   @ row+1, 62 SAY REPLICATE('=',63)
                   @ row+2, 62 SAY gtl1 PICTURE '##,###,###.##'
                   @ row+2, 78 SAY gtl2 PICTURE '##,###,###.##'
                   if muser="ADMIN" .OR.  muser="BERDY"
                      @ row+2, 95 SAY gtl3 PICTURE '##,###,###.##'
                      @ row+2, 112 SAY gtl4 PICTURE '##,###,###.##'
                   else
                      @ row+2, 93  SAY '     ---     '
                      @ row+2, 112 SAY '     ---     '
                   endif
                   @ row+3, 62 SAY REPLICATE('=',63)
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
        LOOP
    ELSE
        CLOSE DATA
        set cent off
        RETURN
    ENDIF
ENDDO
 
CLOSE DATA
RETURN

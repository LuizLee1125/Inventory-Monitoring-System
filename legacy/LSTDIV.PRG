* program.....: LstDiv.prg
*             : 05-07-00

DO BRDR2
@ 8, 2 SAY 'SI DATE   SI NO.     CUST.CODE                                     NET AMT.'

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
   do lstDIVT
   return
endif

SELECT 2
   USE STKREC INDEX TRANS_CN
SELECT 1
   USE SIFYL INDEX SI_D

DO WHILE .T.
    &C_HEAD
    @ 20, 1 SAY SPACE(78)
    &C_MESSAGE
    @ 21, 20 SAY ' NOTE: Press <Enter> to Return to Main Menu. '
    &C_BODY
    @ 5, 3 SAY 'Start At Issued Date :'
    @ 6, 3 SAY 'Stop  At Issued Date :'
    @ 5, 43 SAY 'Territory:'
    @ 6, 43 SAY 'Division :'
    SET CENT ON
    minv_d= CTOD('01/01/2000')
    GOTO BOTTOM
    mfield2= DATE()
    GOTO TOP
    mfield1= CTOD('  /  /  ')
    &C_GET
    @ 6, 26 SAY mfield2 PICTURE '99/99/9999'
    @ 5, 26 GET mfield1 PICTURE '99/99/9999'
    READ
    IF mfield1=CTOD('  /  /    ')
        SET CENT OFF
        close data
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
            @ 5, 26 SAY mfield1
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
    SET CENT OFF
    mfield3= SPACE(10)
    mfield4= SPACE(5)
    mfield5= SPACE(5)
    mfield6= SPACE(5)
    mfield7= SPACE(5)
    @ 5, 54 GET mfield3 PICTURE '@!'
    @ 6, 54 GET mfield4 PICTURE '@!'
    @ 6, 60 GET mfield5 PICTURE '@!'
    @ 6, 66 GET mfield6 PICTURE '@!'
    @ 6, 72 GET mfield7 PICTURE '@!'
    READ
    SET CENTURY OFF
    choice= 'L'
    DO OPTION8
    IF mfield1>mfield2
        mtemp= mfield1
        mfield1= mfield2
        mfield2= mtemp
    ENDIF
    SEEK mfield1
    &C_HEAD
    @ 8, 38 SAY mfield4 PICTURE '@!'
    @ 8, 49 SAY mfield5 PICTURE '@!'
    @ 8, 61 SAY mfield6 PICTURE '@!'
    DO CASE
        CASE choice='L'
            STORE 0.00 TO ttl1, ttl2, ttl3, stl1, stl2, stl3, stl4, gtl1, gtl2, gtl3, gtl4
            &C_CLEAR
            @ 10, 1 CLEAR TO 19, 78
            flag= 1
            row= 9
            DO WHILE .not. EOF().and.inv_d<=mfield2
                IF flag=1
                    c_list= c_option
                    flag= 0
                ELSE
                    c_list= c_body
                    flag= 1
                ENDIF
                &C_LIST
                IF LEN(TRIM(mfield3))<>0
                    IF mfield3<>cust_s
                        SKIP
                        LOOP
                    ENDIF
                ENDIF
                @ row, 2 SAY inv_d PICTURE '@!'
                @ row, 12 SAY inv_n PICTURE '@!'
                @ row, 23 SAY cust_n PICTURE '@!'
                @ row, 67 SAY net_a PICTURE '###,###.##'
                minv_n= 'S'+inv_n
                STORE 0.00 TO ttl1, ttl2, ttl3
                SELECT 2
                SEEK minv_n
                DO WHILE .not. EOF().and.minv_n=trans_c+trans_n
                    DO CASE
                        CASE stk_dv=mfield4
                            ttl1= ttl1+t_prys
                        CASE stk_dv=mfield5
                            ttl2= ttl2+t_prys
                        CASE stk_dv=mfield6
                            ttl3= ttl3+t_prys
                    ENDCASE
                    @ row, 34 SAY ttl1 PICTURE '###,###.##'
                    @ row, 45 SAY ttl2 PICTURE '###,###.##'
                    @ row, 56 SAY ttl3 PICTURE '###,###.##'
                    SKIP
                ENDDO
                SELECT 1
                ttl1= ttl1-ttl1*dcount1/100
                ttl1= ttl1-ttl1*dcount2/100
                ttl1= ttl1-ttl1*dcount3/100
                ttl2= ttl2-ttl2*dcount1/100
                ttl2= ttl2-ttl2*dcount2/100
                ttl2= ttl2-ttl2*dcount3/100
                ttl3= ttl3-ttl3*dcount1/100
                ttl3= ttl3-ttl3*dcount2/100
                ttl3= ttl3-ttl3*dcount3/100
                @ row, 34 SAY ttl1 PICTURE '###,###.##'
                @ row, 45 SAY ttl2 PICTURE '###,###.##'
                @ row, 56 SAY ttl3 PICTURE '###,###.##'
                stl1= stl1+ttl1
                stl2= stl2+ttl2
                stl3= stl3+ttl3
                stl4= stl4+net_a
                gtl1= gtl1+ttl1
                gtl2= gtl2+ttl2
                gtl3= gtl3+ttl3
                gtl4= gtl4+net_a
                row= row+1
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
                    @ 19, 56 SAY stl3 PICTURE '#######.##'
                    @ 19, 67 SAY stl4 PICTURE '#######.##'
                    @ 20, 1 SAY SPACE(78)
                    @ 20, 10 SAY 'GRAND TOTAL'
                    @ 20, 34 SAY gtl1 PICTURE '#######.##'
                    @ 20, 45 SAY gtl2 PICTURE '#######.##'
                    @ 20, 56 SAY gtl3 PICTURE '#######.##'
                    @ 20, 67 SAY gtl4 PICTURE '#######.##'
                    choice= ' '
                    &C_CLEAR
                    @ 21, 0
                    &C_MESSAGE
                    @ 21, 20 SAY ' Press <A> to Abort, any key to continue.' GET choice PICTURE '!'
                    READ
                    IF choice='A'
                        SET CENTURY OFF
                        close data
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
            @ 19, 34 SAY stl1 PICTURE '#######.##'
            @ 19, 45 SAY stl2 PICTURE '#######.##'
            @ 19, 56 SAY stl3 PICTURE '#######.##'
            @ 19, 67 SAY stl4 PICTURE '#######.##'
            @ 20, 1 SAY SPACE(78)
            @ 20, 10 SAY 'GRAND TOTAL'
            @ 20, 34 SAY gtl1 PICTURE '#######.##'
            @ 20, 45 SAY gtl2 PICTURE '#######.##'
            @ 20, 56 SAY gtl3 PICTURE '#######.##'
            @ 20, 67 SAY gtl4 PICTURE '#######.##'
        CASE choice='P'
            pg= 1
            STORE 0.00 TO ttl1, ttl2, ttl3, ttl4, stl1, stl2, stl3, stl4, stl5, gtl1, gtl2, gtl3, gtl4, gtl5
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
                IF LEN(TRIM(mfield3))<>0
                    head1= 'For Territory = '+LTRIM(TRIM(mfield3))
                ENDIF
                @ 3, 1 SAY 'Page '+LTRIM(STR(pg))
                @ 3, (80-LEN(company))/2 SAY company
                @ 4, (80-LEN(head))/2 SAY head
                IF LEN(TRIM(mfield3))<>0
                    @ 5, (80-LEN(head1))/2 SAY head1
                ENDIF
                ?? CHR(15)
                @ 7, 7 SAY '--------------------------------------------------------------------------------------------------------------------'
                @ 8, 7 SAY 'SI DATE     SI NO.        CUSTOMER CODE                                                                   NET AMOUNT'
                @ 8, 53 SAY mfield4 PICTURE '@!'
                @ 8, 69 SAY mfield5 PICTURE '@!'
                @ 8, 85 SAY mfield6 PICTURE '@!'
                @ 8, 101 SAY mfield7 PICTURE '@!'
                @ 9, 7 SAY '--------------------------------------------------------------------------------------------------------------------'
                row= 9
                DO WHILE .not. EOF().and.inv_d<=mfield2
                    IF LEN(TRIM(mfield3))<>0
                        IF mfield3<>cust_s
                            SKIP
                            LOOP
                        ENDIF
                    ENDIF
                    row= row+1
                    @ row, 7 SAY inv_d PICTURE '@!'
                    @ row, 19 SAY inv_n PICTURE '@!'
                    @ row, 33 SAY cust_n PICTURE '@!'
                    minv_n= 'S'+inv_n
                    STORE 0.00 TO ttl1, ttl2, ttl3, ttl4
                    SELECT 2
                    SEEK minv_n
                    DO WHILE .not. EOF().and.minv_n=trans_c+trans_n
                        DO CASE
                            CASE stk_dv=mfield4
                                ttl1= ttl1+t_prys
                            CASE stk_dv=mfield5
                                ttl2= ttl2+t_prys
                            CASE stk_dv=mfield6
                                ttl3= ttl3+t_prys
                            CASE stk_dv=mfield7
                                ttl4= ttl4+t_prys
                        ENDCASE
                        SKIP
                    ENDDO
                    SELECT 1
                    ttl1= ttl1-ttl1*dcount1/100
                    ttl1= ttl1-ttl1*dcount2/100
                    ttl1= ttl1-ttl1*dcount3/100
                    ttl2= ttl2-ttl2*dcount1/100
                    ttl2= ttl2-ttl2*dcount2/100
                    ttl2= ttl2-ttl2*dcount3/100
                    ttl3= ttl3-ttl3*dcount1/100
                    ttl3= ttl3-ttl3*dcount2/100
                    ttl3= ttl3-ttl3*dcount3/100
                    ttl4= ttl4-ttl4*dcount1/100
                    ttl4= ttl4-ttl4*dcount2/100
                    ttl4= ttl4-ttl4*dcount3/100
                    @ row, 47 SAY ttl1 PICTURE '#,###,###.##'
                    @ row, 63 SAY ttl2 PICTURE '#,###,###.##'
                    @ row, 79 SAY ttl3 PICTURE '#,###,###.##'
                    @ row, 95 SAY ttl4 PICTURE '#,###,###.##'
                    @ row, 111 SAY net_a PICTURE '#,###,###.##'
                    stl1= stl1+ttl1
                    gtl1= gtl1+ttl1
                    stl2= stl2+ttl2
                    gtl2= gtl2+ttl2
                    stl3= stl3+ttl3
                    gtl3= gtl3+ttl3
                    stl4= stl4+ttl4
                    gtl4= gtl4+ttl4
                    stl5= stl5+net_a
                    gtl5= gtl5+net_a
                    SKIP
                    IF row>55
                        @ row+1, 46 SAY REPLICATE('-',77)
                        @ row+2, 46 SAY stl1 PICTURE '##,###,###.##'
                        @ row+2, 62 SAY stl2 PICTURE '##,###,###.##'
                        @ row+2, 78 SAY stl3 PICTURE '##,###,###.##'
                        @ row+2, 94 SAY stl4 PICTURE '##,###,###.##'
                        @ row+2, 110 SAY stl5 PICTURE '##,###,###.##'
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
                        @ 21, 20 SAY ' Press <A> to Abort, any key to continue.' GET choice PICTURE '!'
                        READ
                        IF choice='A'
                            SET CENTURY OFF
                            close data
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
                        STORE 0.00 TO stl1, stl2, stl3, stl4, stl5
                        @ 3, 1 SAY 'Page '+LTRIM(STR(pg))
                        @ 3, (80-LEN(head))/2 SAY head
                        IF LEN(TRIM(mfield3))<>0
                            @ 4, (80-LEN(head1))/2 SAY head1
                        ENDIF
                        ?? CHR(15)
                        @ 6, 7 SAY '--------------------------------------------------------------------------------------------------------------------'
                        @ 7, 7 SAY 'SI DATE     SI NO.        CUSTOMER CODE                                                                   NET AMOUNT'
                        @ 7, 53 SAY mfield4 PICTURE '@!'
                        @ 7, 69 SAY mfield5 PICTURE '@!'
                        @ 7, 85 SAY mfield6 PICTURE '@!'
                        @ 7, 101 SAY mfield7 PICTURE '@!'
                        @ 8, 7 SAY '--------------------------------------------------------------------------------------------------------------------'
                        row= 8
                    ENDIF
                ENDDO
                IF EOF().or.inv_d>mfield2
                    IF pg>1
                        @ row+1, 46 SAY REPLICATE('-',77)
                        @ row+2, 46 SAY stl1 PICTURE '##,###,###.##'
                        @ row+2, 62 SAY stl2 PICTURE '##,###,###.##'
                        @ row+2, 78 SAY stl3 PICTURE '##,###,###.##'
                        @ row+2, 94 SAY stl4 PICTURE '##,###,###.##'
                        @ row+2, 110 SAY stl5 PICTURE '##,###,###.##'
                        row= row+2
                    ENDIF
                    @ row+1, 46 SAY REPLICATE('=',77)
                    @ row+2, 46 SAY gtl1 PICTURE '##,###,###.##'
                    @ row+2, 62 SAY gtl2 PICTURE '##,###,###.##'
                    @ row+2, 78 SAY gtl3 PICTURE '##,###,###.##'
                    @ row+2, 94 SAY gtl4 PICTURE '##,###,###.##'
                    @ row+2, 110 SAY gtl5 PICTURE '##,###,###.##'
                    @ row+3, 46 SAY REPLICATE('=',77)
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
            SET CENTURY ON
            close data
            RETURN
    ENDCASE
    SET CENTURY ON
    choice= ' '
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
        SET CENT OFF
        close data
        RETURN
    ENDIF
ENDDO

SET CENT OFF
close data
return

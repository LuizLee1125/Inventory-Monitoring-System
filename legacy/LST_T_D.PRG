* program.....: Lst_T_D.prg
*             : 07-13-2004
*             : sales summary per territory, customer

DO BRDR2
*                   1         2         3         4         5         6         7         
*           234567890123456789012345678901234567890123456789012345678901234567890123456789
@ 8, 2 SAY 'CustCode   Customer Name                  Area            Purchase Amt'
*           xxxxxxxxxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx   9   ........  9,999.999.00                  

*save screen to atlscreen
*atlmsg="generate totals only (y/n)  "
*atlopt="N"
*atllen=len(atlmsg)
*set colo to rb/rb
*@ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
*set colo to +w/rb
*@ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
*@ 12,41-atllen/2 say atlmsg
*@ 12,40-atllen/2+len(atlmsg) get atlopt pict "Y" valid atlopt$"YyNn"
*read
*restore screen from atlscreen
*
*if atlopt="Y"
*   *do lst_TTD
*   return
*endif

SELECT 2
   USE CUSTFYL INDEX CUST_N
SELECT 1
   USE SIFYL INDEX SI_D, si_cd

DO WHILE .T.
    &C_HEAD
    @ 20, 1 SAY SPACE(78)
    &C_MESSAGE
    @ 21, 20 SAY ' NOTE: Press <Enter> to Return to Main Menu. '
    &C_BODY
    @ 5, 3 SAY 'Start At Issued Date :'
    @ 6, 3 SAY 'Stop  At Issued Date :'
    @ 5, 43 SAY 'Territory:'
    @ 6, 43 SAY 'Customer :            To'      
    SET CENT ON
    minv_d= CTOD('01/01/2004')
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
    mfield4= SPACE(10)
    mfield5= SPACE(10)
    @ 5, 54 GET mfield3 PICTURE '@!'
    read
    sele 2
    set filt to cust_s=mfield3
    go top
    store cust_n to mfield4
    go bott
    store cust_n to mfield5
    go top
    @ 6, 54 GET mfield4 PICTURE '@!'
    @ 6, 68 GET mfield5 PICTURE '@!'
    READ
    loca for cust_n=mfield4
    SET CENTURY OFF
    choice= 'L'
    sele 1
    DO OPTION8
    IF mfield1>mfield2
        mtemp= mfield1
        mfield1= mfield2
        mfield2= mtemp
    ENDIF
    SEEK mfield1
    &C_HEAD
    DO CASE
        CASE choice='L'
            STORE 0.00 TO ttl1, stl1, gtl1
            &C_CLEAR
            @ 10, 1 CLEAR TO 19, 78
            flag= 1
            row= 9
            SELE 1
            SET ORDER TO 2
            SELE 2
            do while .not. eof() .and. cust_n<=mfield5
               store cust_n to sv_custn
               SELE 1
               STORE 0 TO TTL1
               seek "F"+sv_custn
               DO WHILE .not. EOF().and.cust_n=sv_custn
                  if INV_D>=MFIELD1 .and. INV_D<=MFIELD2
                     ttl1=ttl1+NET_A
                     stl1=stl1+net_a
                     gtl1=gtl1+net_a
                  endif
                  skip
               enddo
               seek "T"+sv_custn
               DO WHILE .not. EOF().and.cust_n=sv_custn
                  if INV_D>=MFIELD1 .and. INV_D<=MFIELD2
                     ttl1=ttl1+NET_A
                     stl1=stl1+net_a
                     gtl1=gtl1+net_a
                  endif
                  skip
               enddo
               IF flag=1
                  c_list= c_option
                  flag= 0
               ELSE
                  c_list= c_body
                  flag= 1
               ENDIF
               &C_LIST

               @ row,  2 say custfyl->cust_n
               @ row, 13 say custfyl->cust_m
               @ row, 46 say custfyl->cust_ac
               @ row, 60 say ttl1 pict '9,999,999.99'
               row= row+1
               sele 2
               SKIP
               IF EOF()
                  EXIT
               ENDIF
               IF row=19
                  &C_HEAD
                  @ 19, 1 SAY SPACE(78)
                  @ 19, 10 SAY 'SUB   TOTAL'
                  @ 19, 59 SAY stl1 PICTURE '##,###,###.##'
                  @ 20, 1 SAY SPACE(78)
                  @ 20, 10 SAY 'GRAND TOTAL'
                  @ 20, 59 SAY gtl1 PICTURE '##,###,###.##'
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
            @ 19, 59 SAY stl1 PICTURE '##,###,###.##'
            @ 20, 1 SAY SPACE(78)
            @ 20, 10 SAY 'GRAND TOTAL'
            @ 20, 59 SAY gtl1 PICTURE '##,###,###.##'

        CASE choice='P'
            do testprt
            pg= 1
            STORE 0.00 TO ttl1, ttl2, ttl3, ttl4, stl1, stl2, stl3, stl4, stl5, gtl1, gtl2, gtl3, gtl4, gtl5
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

            @ 7, 2 SAY '----------------------------------------------------------------------'
            @ 8, 2 SAY 'CustCode   Customer Name                  Area            Purchase Amt'
            @ 9, 2 SAY '----------------------------------------------------------------------'
            row=10

            STORE 0.00 TO ttl1, stl1, gtl1
            &C_CLEAR
            @ 10, 1 CLEAR TO 19, 78
            flag= 1
            SELE 1
            SET ORDER TO 2
            SELE 2
            do while .not. eof() .and. cust_n<=mfield5
               store cust_n to sv_custn
               SELE 1
               STORE 0 TO TTL1
               seek "F"+sv_custn
               DO WHILE .not. EOF().and.cust_n=sv_custn
                  if INV_D>=MFIELD1 .and. INV_D<=MFIELD2
                     ttl1=ttl1+NET_A
                     stl1=stl1+net_a
                     gtl1=gtl1+net_a
                  endif
                  skip
               enddo
               seek "T"+sv_custn
               DO WHILE .not. EOF().and.cust_n=sv_custn
                  if INV_D>=MFIELD1 .and. INV_D<=MFIELD2
                     ttl1=ttl1+NET_A
                     stl1=stl1+net_a
                     gtl1=gtl1+net_a
                  endif
                  skip
               enddo

               @ row,  2 say custfyl->cust_n
               @ row, 13 say custfyl->cust_m
               @ row, 46 say custfyl->cust_ac
               @ row, 60 say ttl1 pict '9,999,999.99'
               row= row+1

               if row>53
                  @ row,   59 SAY '-------------'
                  @ row+1, 59 SAY stl1 PICTURE '##,###,###.##'
                  @ row+3, 55 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                  do testprt
                  pg= pg+1

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

                  @ 7, 2 SAY '----------------------------------------------------------------------'
                  @ 8, 2 SAY 'CustCode   Customer Name                  Area            Purchase Amt'
                  @ 9, 2 SAY '----------------------------------------------------------------------'
                  row=10
               ENDIF

               sele 2
               SKIP
               IF EOF()
                  EXIT
               ENDIF
            ENDDO

            @ row,   59 SAY '-------------'
            @ row+1, 59 SAY stl1 PICTURE '##,###,###.##'
            @ row+2, 59 say '-------------'
            @ row+3, 59 say gtl1 PICTURE '##,###,###.##'
            @ row+4, 59 say '============='
            eject       
        OTHERWISE
            SET CENTURY ON
            close data
            RETURN
    ENDCASE
    SET PRINTER OFF
    SET DEVICE TO SCREEN
    SET CONSOLE ON
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

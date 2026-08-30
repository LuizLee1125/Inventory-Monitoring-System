* program.....: Lst_TSG2.prg
*             : 09-02-2004
*             : sales summary per territory, as PER SUPPLIER, date, reflecting
*               gross sales amount x 1.5%

DO BRDR2
*                   1         2         3         4         5         6         7         
*           234567890123456789012345678901234567890123456789012345678901234567890123456789
@ 8, 2 SAY 'Area Code  Cust.Code   Customer Name                    Gross Sales Amount'
*               x      xxxxxxxxxx  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  99,999,999.99                     
*                                                          Totals:  99,999,999.99
SELECT 3
   SET SAFE OFF
   SET EXCL ON
   USE XSLS_TDS
   INDEX ON CUST_N TO NX_XSTDC
   INDEX ON CUST_AC+CUST_N TO NX_XSTDS
   SET INDEX TO NX_XSTDC, NX_XSTDS
   ZAP
   SET EXCL OFF
   SET SAFE ON
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
   *                        5         6         7
   *             90123456789012345678901234567890123456789
    @ 5, 42 SAY 'Territory : '
    @ 6, 42 SAY 'Supplier  : '
    minv_d= CTOD('01/01/2004')
    GOTO BOTTOM
    mfield2= DATE()
    GOTO TOP
    mfield1= CTOD('  /  /  ')
    set cent on
    &C_GET
    @ 6, 26 SAY mfield2
    @ 5, 26 GET mfield1 PICTURE '@!'
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

    set cent off

    mfield3= SPACE(10)
    mfield4= SPACE(10)
    mfield5= SPACE(5)
    mfield6= SPACE(5)
    sw=0
    do while .t.
       @ 5, 54 GET mfield3 PICTURE '@!'
       read
       if len(trim(mfield3))=0
          save screen to atlscreen2
          atlmsg="Territory must not be blank. Do you want to cancel? "
          atlopt="N"
          atllen=len(atlmsg)
          set colo to rb/rb
          @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+2
          set colo to +w/rb
          @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+2
          @ 12,41-atllen/2 say atlmsg
          @ 12,40-atllen/2+len(atlmsg)+1 get atlopt pict "Y" valid atlopt$"YyNn"
          read
          restore screen from atlscreen2

          if atlopt="Y"
             store 1 to sw
             exit
          endif
       else
          exit
       endif
    enddo
    if sw=1
       exit
    endif

    sw=0
    do while .t.
       @ 6, 54 GET mfield4 PICTURE '@!'
       read
       if len(trim(mfield4))=0
          save screen to atlscreen2
          atlmsg="Supplier must not be blank. Do you want to cancel? "
          atlopt="N"
          atllen=len(atlmsg)
          set colo to rb/rb
          @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+2
          set colo to +w/rb
          @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+2
          @ 12,41-atllen/2 say atlmsg
          @ 12,40-atllen/2+len(atlmsg)+1 get atlopt pict "Y" valid atlopt$"YyNn"
          read
          restore screen from atlscreen2

          if atlopt="Y"
             store 1 to sw
             exit
          endif
       else
          exit
       endif
    enddo
    if sw=1
       exit
    endif

    atlmsg="please enter factor... "
    atlpercent=0.00
    atllen=len(atlmsg)
    set colo to rb/rb
    @ 11,39-atllen/2-2 clear to 13,41-atllen/2+atllen+4
    set colo to +w/rb
    @ 11,39-atllen/2-2 to 13,41-atllen/2+atllen+4
    @ 12,39-atllen/2 say atlmsg
    @ 12,38-atllen/2+len(atlmsg)+1 get atlpercent pict "99.99"
    read

    SET CENTURY OFF
    choice= 'L'
    &C_HEAD

    DO OPTION8
    IF mfield1>mfield2
        mtemp= mfield1
        mfield1= mfield2
        mfield2= mtemp
    ENDIF
    SEEK mfield1
    *suspend
    *SET EXACT ON
    DO CASE
        CASE choice='L'
            STORE 0.00 TO ttl1, ttl2, ttl3
            store 0.00 to stl1, stl2, stl3, stl4
            store 0.00 to gtl1, gtl2, gtl3, gtl4
            &C_CLEAR
            @ 10, 1 CLEAR TO 19, 78
            flag= 1
            row= 9
            atlmsg="Please wait... extracting data....."
            atllen=len(atlmsg)
            set colo to rb/rb
            @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+2
            set colo to +w/rb
            @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+2
            @ 12,41-atllen/2 say atlmsg
            SELE 1
            DO WHILE .not. EOF().and.inv_d<=mfield2
                Select 1
               *IF LEN(TRIM(mfield3))<>0
                    IF mfield3<>cust_s
                        SKIP
                        LOOP
                    ENDIF
               *ENDIF
                minv_n= 'S'+inv_n
                STORE 0.00 TO ttl1, ttl2, ttl3
                SELECT 2
                SEEK minv_n
                DO WHILE .not. EOF().and.minv_n=trans_c+trans_n
                   if splyr_n=trim(mfield4)
                      ttl1=ttl1+issue_q*issue_p
                   endif
                   SKIP
                ENDDO
                store sifyl->cust_n to sv_cust_n
                SET EXACT ON
                sele 3
                SEEK SV_CUST_N
                SET EXACT OFF
                if found() && record alreay exists
                   repl gross with gross+ttl1
                   unlock
                else
                   appe blank
                   repl cust_n with sv_cust_n
                   repl cust_m with sifyl->cust_m
                   repl cust_ac with sifyl->cust_ac
                   repl gross with ttl1
                   unlock
                endif
                sele 1
                skip
            ENDDO
            set colo to
            @ 11,5 clear to 13,75
            sele 3
            set order to 2
            go top
            row=9
            stl1=0
            gtl1=0
            a1=0
            a2=0
            a3=0
            a4=0
            a5=0
            a6=0
            a7=0
            do while.not.eof()
               IF GROSS<>0
                  IF flag=1
                     c_list= c_option
                     flag= 0
                  ELSE
                     c_list= c_body
                     flag= 1
                  ENDIF
                  &C_LIST

                  @ row,06 say cust_ac
                  @ row,13 say cust_n
                  @ row,25 say cust_m
                  @ row,58 say gross*atlpercent   picture "99,999,999.99"
                  stl1=stl1+gross*atlpercent
                  gtl1=gtl1+gross*atlpercent
                  do case
                     case cust_ac="1"
                          a1=a1+gross*atlpercent
                     case cust_ac="2"
                          a2=a2+gross*atlpercent
                     case cust_ac="3"
                          a3=a3+gross*atlpercent
                     case cust_ac="4"
                          a4=a4+gross*atlpercent
                     case cust_ac="5"
                          a5=a5+gross*atlpercent
                     case cust_ac="6"
                          a6=a6+gross*atlpercent
                     other
                          a7=a7+gross*atlpercent
                  endcase
                  row=row+1
               ENDIF
               SKIP
               IF EOF()
                  EXIT
               ENDIF
               IF row=19
                  &C_HEAD
                  @ 19, 1 SAY SPACE(78)
                  @ 19, 10 SAY 'SUB   TOTAL'
                  @ 19, 58 SAY stl1 PICTURE '##,###,###.##'
                  @ 20, 1 SAY SPACE(78)
                  @ 20, 10 SAY 'GRAND TOTAL'
                  @ 20, 58 SAY gtl1 PICTURE '##,###,###.##'
                  choice= ' '
                  &C_CLEAR
                    @ 21, 0
                    &C_MESSAGE
                    @ 21, 20 SAY ' Press <A> to Abort, any key to continue.' GET choice PICTURE '!'
                    READ
                    IF choice='A'
                        set cent off
                        close data
                        RETURN
                    ENDIF
                    &C_CLEAR
                    @ 9, 1 CLEAR TO 19, 78
                    row= 9
                    STORE 0.00 TO stl1
                ENDIF
            ENDDO
            &C_HEAD
            @ 19, 1 SAY SPACE(78)
            @ 19, 10 SAY 'SUB   TOTAL'
            @ 19, 58 SAY stl1 PICTURE '##,###,###.##'
            @ 20, 1 SAY SPACE(78)
            @ 20, 10 SAY 'GRAND TOTAL'
            @ 20, 58 SAY gtl1 PICTURE '##,###,###.##'

            &C_CLEAR
            @ 21, 0
            &C_MESSAGE
            @ 21, 27 SAY 'press any key to continue...'
            atlkey=inkey(0)
            &C_CLEAR
            @ 09,01 clear to 19,78
            @ 21,0  clear to 21,79
            SET COLO TO +G
            @ 11,25 say "area 1  ....................:"
            @ 11,58 say a1 pict '99,999,999.99'
            @ 12,25 say "area 2  ....................:"
            @ 12,58 say a2 pict '99,999,999.99'
            @ 13,25 say "area 3  ....................:"
            @ 13,58 say a3 pict '99,999,999.99'
            @ 14,25 say "area 4  ....................:"
            @ 14,58 say a4 pict '99,999,999.99'
            @ 15,25 say "area 5  ....................:"
            @ 15,58 say a5 pict '99,999,999.99'
            @ 16,25 say "area 6  ....................:"
            @ 16,58 say a6 pict '99,999,999.99'
            @ 17,25 say "no area ....................:"
            @ 17,58 say a7 pict '99,999,999.99'
            &C_HEAD
            @ 20, 1 SAY SPACE(78)
            @ 20, 10 SAY 'GRAND TOTAL'
            @ 20, 58 SAY gtl1 PICTURE '##,###,###.##'

        CASE choice='P'
            atlmsg="Please wait... extracting data....."
            atllen=len(atlmsg)
            set colo to rb/rb
            @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+2
            set colo to +w/rb
            @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+2
            @ 12,41-atllen/2 say atlmsg

            do testprt
            pg= 1
            STORE 0.00 TO ttl1, ttl2, ttl3
            store 0.00 to stl1, stl2, stl3, stl4
            store 0.00 to gtl1, gtl2, gtl3, gtl4
            flag= 1
            row= 10
            SELE 1
            DO WHILE .not. EOF().and.inv_d<=mfield2
                Select 1
                IF mfield3<>cust_s
                   SKIP
                   LOOP
                ENDIF
                minv_n= 'S'+inv_n
                STORE 0.00 TO ttl1, ttl2, ttl3
                SELECT 2
                SEEK minv_n
                DO WHILE .not. EOF().and.minv_n=trans_c+trans_n
                   if splyr_n=trim(mfield4)
                      ttl1=ttl1+issue_q*issue_p
                   endif
                   SKIP
                ENDDO
                store sifyl->cust_n to sv_cust_n
                SET EXACT ON
                sele 3
                SEEK SV_CUST_N
                SET EXACT OFF
                if found() && record alreay exists
                   repl gross with gross+ttl1
                   unlock
                else
                   appe blank
                   repl cust_n with sv_cust_n
                   repl cust_m with sifyl->cust_m
                   repl cust_ac with sifyl->cust_ac
                   repl gross with ttl1
                   unlock
                endif
                sele 1
                skip
            ENDDO
            set colo to
            @ 11,5 clear to 13,75
            sele 3
            set order to 2
            go top
            stl1=0
            gtl1=0
            a1=0
            a2=0
            a3=0
            a4=0
            a5=0
            a6=0
            a7=0
            &C_MESSAGE
            @ 23, 50 SAY '...Printing'
            SET CONSOLE OFF
            SET DEVICE TO PRINTER
            SET PRINTER ON
            ?? CHR(27)+CHR(64)
            ?? CHR(18)
            cdate= CMONTH(DATE())+' '+STR(DAY(DATE()),2)+', '+STR(YEAR(DATE()),4)
            head= 'Sales Summary from '+DTOC(mfield1)+' to '+DTOC(mfield2)
            head1= 'For Territory='+LTRIM(TRIM(mfield3))+" and Supplier="+trim(mfield4)
            @ 3, 1 SAY 'Page '+LTRIM(STR(pg))
            @ 3, (80-LEN(company))/2 SAY company
            @ 4, (80-LEN(head))/2    SAY head
            @ 5, (80-LEN(head1))/2   SAY head1
            @ 7, 2 SAY '=========================================================================='
            @ 8, 2 SAY 'Area Code  Cust.Code   Customer Name                    Gross Sales Amount'
            @ 9, 2 SAY '=========================================================================='

            do while.not.eof()
               IF GROSS<>0
                  @ row,06 say cust_ac
                  @ row,13 say cust_n
                  @ row,25 say cust_m
                  @ row,58 say gross*atlpercent   picture "99,999,999.99"
                  stl1=stl1+gross*atlpercent
                  gtl1=gtl1+gross*atlpercent
                  do case
                     case cust_ac="1"
                          a1=a1+gross*atlpercent
                     case cust_ac="2"
                          a2=a2+gross*atlpercent
                     case cust_ac="3"
                          a3=a3+gross*atlpercent
                     case cust_ac="4"
                          a4=a4+gross*atlpercent
                     case cust_ac="5"
                          a5=a5+gross*atlpercent
                     case cust_ac="6"
                          a6=a6+gross*atlpercent
                     other
                          a7=a7+gross*atlpercent
                  endcase
                  row=row+1
               ENDIF
               SKIP
               IF EOF()
                  EXIT
               ENDIF
               IF ROW>53
                  @ row,   58 SAY '-------------'
                  @ row+1, 44 say 'Sub Totals :'
                  @ row+1, 58 SAY stl1 PICTURE '##,###,###.##'
                  @ row+3, 55 SAY '...continued on page '+LTRIM(STR(pg+1))
                  ?
                  ?? CHR(18)
                  EJECT
                  SET PRINTER OFF
                  SET DEVICE TO SCREEN
                  SET CONSOLE ON
                  &C_CLEAR
                  @ 11,5 clear to 15,76
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
                     close data
                     RETURN
                  ENDIF
                  &C_CLEAR
                  @ 23, 0
                  &C_MESSAGE
                  do testprt
                  @ 23, 50 SAY '...Printing'
                  SET CONSOLE OFF
                  SET DEVICE TO PRINTER
                  SET PRINTER ON
                  pg= pg+1
                  STORE 0.00 TO stl1, stl2, stl3, stl4, stl5
                  @ 3, 1 SAY 'Page '+LTRIM(STR(pg))
                  @ 3, (80-LEN(company))/2 SAY company
                  @ 4, (80-LEN(head))/2    SAY head
                  @ 5, (80-LEN(head1))/2   SAY head1
                  @ 7, 2 SAY '=========================================================================='
                  @ 8, 2 SAY 'Area Code  Cust.Code   Customer Name                    Gross Sales Amount'
                  @ 9, 2 SAY '=========================================================================='
                  STORE 10 TO ROW
               ENDIF
            ENDDO
            @ row,   58 SAY '-------------'
            @ row+1, 44 say 'Sub Totals :'
            @ row+1, 58 SAY stl1 PICTURE '##,###,###.##'
            row=row+3
            if row>45
                  @ row, 55 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                     close data
                     RETURN
                  ENDIF
                  &C_CLEAR
                  @ 23, 0
                  &C_MESSAGE
                  do testprt
                  @ 23, 50 SAY '...Printing'
                  SET CONSOLE OFF
                  SET DEVICE TO PRINTER
                  SET PRINTER ON
                  pg= pg+1
                  STORE 0.00 TO stl1, stl2, stl3, stl4, stl5
                  @ 3, 1 SAY 'Page '+LTRIM(STR(pg))
                  @ 3, (80-LEN(company))/2 SAY company
                  @ 4, (80-LEN(head))/2    SAY head
                  @ 5, (80-LEN(head1))/2   SAY head1
                  @ 7, 2 SAY '=========================================================================='
                  @ 8, 2 SAY 'Area Code  Cust.Code   Customer Name                    Gross Sales Amount'
                  @ 9, 2 SAY '=========================================================================='
                  STORE 10 TO ROW
            ENDIF
            @ row,  25 say "area 1  ....................:"
            @ row,  58 say a1 pict '99,999,999.99'
            @ row+1,25 say "area 2  ....................:"
            @ row+1,58 say a2 pict '99,999,999.99'
            @ row+2,25 say "area 3  ....................:"
            @ row+2,58 say a3 pict '99,999,999.99'
            @ row+3,25 say "area 4  ....................:"
            @ row+3,58 say a4 pict '99,999,999.99'
            @ row+4,25 say "area 5  ....................:"
            @ row+4,58 say a5 pict '99,999,999.99'
            @ row+5,25 say "area 6  ....................:"
            @ row+5,58 say a6 pict '99,999,999.99'
            @ row+6,25 say "no area ....................:"
            @ row+6,58 say a7 pict '99,999,999.99'
            @ row+7,58 say         '============='
            @ row+8,25 say "Grand Totals................:"
            @ row+8,58 say gtl1 pict '99,999,999.99'
            eject
        OTHERWISE
            SET CENTURY Off
            close data
            RETURN
    ENDCASE
    SET EXACT OFF
    SET PRINTER OFF
    SET DEVICE TO SCREEN
    SET CONSOLE ON
    SET CENTURY ON
    @ 23,0 clear to 23,79
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
        CLOSE DATA
        SELECT 3
        SET SAFE OFF
        SET EXCL ON
        USE XSLS_TDS
        INDEX ON CUST_N TO NX_XSTDC
        INDEX ON CUST_AC+CUST_N TO NX_XSTDS
        SET INDEX TO NX_XSTDC, NX_XSTDS
        ZAP
        SET EXCL OFF
        SET SAFE ON
        SELECT 2
        USE STKREC INDEX TRANS_CN
        SELECT 1
        USE SIFYL INDEX SI_D
        LOOP
    ELSE
        close data
        set cent off
        RETURN
    ENDIF
ENDDO
 
close data
set cent off
return


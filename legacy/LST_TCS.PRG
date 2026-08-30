* program.....: Lst_TCS.prg
*             : 07-22-2004
*             : sales summary per territory, customer, PER SUPPLIER

DO BRDR2
*                   1         2         3         4         5         6         7         
*           234567890123456789012345678901234567890123456789012345678901234567890123456789
@ 8, 2 SAY 'Inv.Date Ref. Inv.  Item Code  Item Description     % Discounts  Sales Amt.'
*           99/99/99 xxxxxxxxxx xxxxxxxxxx xxxxxxxxxxxxxxxxxxxx 99.99 99 99  999,999.99                    
*                                                            Cust. Totals: 9,999,999.99
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
    @ 5, 43 SAY 'Customer : '
    @ 6, 43 SAY 'Supplier : '
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
    @ 5, 54 GET mfield3 PICTURE '@!'
    read
    sw=0
    do while .t.
       @ 6, 54 GET mfield4 PICTURE '@!'
       read
       if len(trim(mfield4))=0
          save screen to atlscreen2
          atlmsg="Supplier must not be blank. Do you want to cancel?"
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
    DO CASE
        CASE choice='L'
            STORE 0.00 TO ttl1, ttl2, ttl3
            store 0.00 to stl1, stl2, stl3, stl4
            store 0.00 to gtl1, gtl2, gtl3, gtl4
            &C_CLEAR
            @ 10, 1 CLEAR TO 19, 78
            flag= 1
            row= 9
            DO WHILE .not. EOF().and.inv_d<=mfield2
                Select 1
                IF LEN(TRIM(mfield3))<>0
                    IF mfield3<>cust_n
                        SKIP
                        LOOP
                    ENDIF
                ENDIF
                minv_n= 'S'+inv_n
                mnet_a= net_a
                STORE 0.00 TO ttl1, ttl2, ttl3
                SELECT 2
                SEEK minv_n
                DO WHILE .not. EOF().and.minv_n=trans_c+trans_n
                   if splyr_n=trim(mfield4)
                      IF flag=1
                         c_list= c_option
                         flag= 0
                      ELSE
                         c_list= c_body
                         flag= 1
                      ENDIF

                      &C_LIST
                      set cent off
                      @ row,  2 SAY trans_d  PICTURE '99/99/99'
                      set cent on
                      @ row, 11 SAY trans_n  PICTURE '@!'
                      @ row, 22 SAY stk_n    PICTURE '@!'
                      @ row, 33 SAY left(stk_m,20) PICTURE '@!'
                      @ row, 54 SAY dcount1  PICTURE '99.99'
                      @ row, 60 SAY dcount2  PICTURE '99'
                      @ row, 63 SAY dcount3  PICTURE '99'
                      @ row, 67 SAY t_prys   PICTURE '999,999.99'

                      gtl3=gtl3+t_prys
                      stl3=stl3+t_prys
                      row= row+1
                   endif
                   SKIP
                   IF EOF()
                      EXIT
                   ENDIF
                   IF row=19
                      &C_HEAD
                      @ 19, 1 SAY SPACE(78)
                      @ 19, 24 SAY 'SUB   TOTAL'
                      @ 19, 65 say stl3 picture "#,###,###.99"
                      @ 20, 24 SAY 'GRAND TOTAL'
                      @ 20, 65 say gtl3 picture "#,###,###.99"
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
                sele 1
                skip
            ENDDO
            &C_HEAD
            &C_HEAD
            @ 19, 1 SAY SPACE(78)
            @ 19, 24 SAY 'SUB   TOTAL'
            @ 19, 65 say stl3 picture "##,###,###.99"
            @ 20, 1 SAY SPACE(78)
            @ 20, 24 SAY 'GRAND TOTAL'
            @ 20, 65 say gtl3 picture "##,###,###.99"

        CASE choice='P'
            do testprt
            pg= 1
            STORE 0.00 TO ttl1, ttl2, ttl3
            STORE 0.00 TO stl1, stl2, stl3, stl4
            STORE 0.00 TO gtl1, gtl2, gtl3, gtl4
            &C_MESSAGE
            @ 23, 50 SAY '...Printing'
            SET CONSOLE OFF
            SET DEVICE TO PRINTER
            SET PRINTER ON
            ?? CHR(27)+CHR(64)
            ?? CHR(18)
            cdate= CMONTH(DATE())+' '+STR(DAY(DATE()),2)+', '+STR(YEAR(DATE()),4)
            head= 'Sales Summary from '+DTOC(mfield1)+' to '+DTOC(mfield2)
            head1= 'For Customer='+LTRIM(TRIM(mfield3))+" and Supplier="+trim(mfield4)
            @ 3, 1 SAY 'Page '+LTRIM(STR(pg))
            @ 3, (80-LEN(company))/2 SAY company
            @ 4, (80-LEN(head))/2    SAY head
            @ 5, (80-LEN(head1))/2   SAY head1
            @ 7, 2 SAY '==========================================================================='
            @ 8, 2 SAY 'Inv.Date Ref. Inv.  Item Description                % Discounts  Sales Amt.'
            @ 9, 2 SAY '==========================================================================='

            &C_CLEAR
            @ 10, 1 CLEAR TO 19, 78
            row= 10
            DO WHILE .not. EOF().and.inv_d<=mfield2
                Select 1
                IF LEN(TRIM(mfield3))<>0
                    IF mfield3<>cust_n
                        SKIP
                        LOOP
                    ENDIF
                ENDIF
                minv_n= 'S'+inv_n
                mnet_a= net_a
                STORE 0.00 TO ttl1, ttl2, ttl3
                SELECT 2
                SEEK minv_n
                DO WHILE .not. EOF().and.minv_n=trans_c+trans_n
                   if splyr_n=trim(mfield4)
                      set cent off
                      @ row,  2 SAY trans_d  PICTURE '99/99/99'
                      set cent on
                      @ row, 11 SAY trans_n  PICTURE '@!'
                      @ row, 22 SAY stk_m    PICTURE '@!'
                      @ row, 54 SAY dcount1  PICTURE '99.99'
                      @ row, 60 SAY dcount2  PICTURE '99'
                      @ row, 63 SAY dcount3  PICTURE '99'
                      @ row, 67 SAY t_prys   PICTURE '999,999.99'

                      gtl3=gtl3+t_prys
                      stl3=stl3+t_prys
                      row= row+1
                   endif
                   SKIP
                   IF EOF()
                      EXIT
                   ENDIF
                   IF ROW>53
                      @ row,   65 SAY "------------"
                      @ row+1, 49 SAY "Sub Totals :"
                      @ row+1, 65 SAY stl3 PICTURE '#,###,###.##'
                      @ row+3, 55 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                      @ 7, 2 SAY '==========================================================================='
                      @ 8, 2 SAY 'Inv.Date Ref. Inv.  Item Code  Item Description     % Discounts  Sales Amt.'
                      @ 9, 2 SAY '==========================================================================='
                      STORE 10 TO ROW
                   ENDIF
                ENDDO
                sele 1
                skip
            ENDDO
            @ row  , 65 SAY "------------"
            @ row+1, 49 SAY "Sub Totals  :"
            @ row+1, 65 SAY stl3 PICTURE '#,###,###.##'
            @ row+2, 65 SAY "============"
            @ row+3, 49 SAY "Grand Totals:"
            @ row+3, 65 SAY gtl3 PICTURE '#,###,###.##'
            @ row+4, 65 SAY "============"
            eject
        OTHERWISE
            SET CENTURY Off
            close data
            RETURN
    ENDCASE
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


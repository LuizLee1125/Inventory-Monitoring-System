* program.....: Lst_TCSE.prg
*             : 07-22-2004
*             : sales summary per customer, PER SUPPLIER -> excel file

DO BRDR2
*                   1         2         3         4         5         6         7         
*           234567890123456789012345678901234567890123456789012345678901234567890123456789
@ 8, 2 SAY 'Inv.Date Ref. Inv.  Item Code  Item Description     % Discounts  Sales Amt.'
*           99/99/99 xxxxxxxxxx xxxxxxxxxx xxxxxxxxxxxxxxxxxxxx 99.99 99 99  999,999.99                    
*                                                            Cust. Totals: 9,999,999.99

set excl on
sele 3
     use rpt_ssuc
     set safe off
     zap
     set safe on
set excl off

SELECT 2
   USE STKREC INDEX TRANS_CN
SELECT 1
   USE SIFYL INDEX SI_D

*DO WHILE .T.
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

*    DO OPTION8
    IF mfield1>mfield2
        mtemp= mfield1
        mfield1= mfield2
        mfield2= mtemp
    ENDIF
    SEEK mfield1
    *suspend

atlmsg="please wait, extracting data....."
atllen=len(atlmsg)
set colo to rb/rb
@ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+3
set colo to +w/rb
@ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+3
@ 12,41-atllen/2 say atlmsg
     SET EXACT ON
*    DO CASE
*        CASE choice='L'
            STORE 0.00 TO ttl1, ttl2, ttl3
            store 0.00 to stl1, stl2, stl3, stl4
            store 0.00 to gtl1, gtl2, gtl3, gtl4
            flag= 1
            row= 9
            sele 1
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
                      sele 3
                      appe blank
                      repl trans_n with stkrec->trans_n
                      repl trans_d with stkrec->trans_d
                      repl cust_n  with stkrec->cust_n
                      repl cust_s  with stkrec->cust_s
                      repl stk_n   with stkrec->stk_n
                      repl stk_m   with stkrec->stk_m
                      repl issue_q with stkrec->issue_q
                      repl dcount1 with stkrec->dcount1
                      repl dcount2 with stkrec->dcount2
                      repl dcount3 with stkrec->dcount3
                      repl t_prys  with stkrec->t_prys
                      unlock
                   endif
                   sele 2
                   SKIP
                ENDDO
                sele 1
                skip
            ENDDO

sele 3
set safe off
sort on trans_d, trans_n, stk_n to srt_ssup
set safe on

atlmsg="finished extracting data... File: Srt_SSup.dbf  press any key..."
atllen=len(atlmsg)
set colo to rb/rb
@ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+3
set colo to +w/rb
@ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+3
@ 12,41-atllen/2 say atlmsg
atlkey=inkey(0)
clear
SET EXACT OFF
return



* program.....: Ex_Incen.prg
*             : extraction of data for incentives - ROGEMSON
*             : 08/22/03

set cent on
set safety off
set exclu on
use dumstrec index dm_incen
zap
set exclu off
set safety on
use

sele 1
     use dumstrec index dm_incen
     && index file: dm_incen
     && index key : str(year(trans_d),4)+left(dtoc(trans_d),5)+right(trans_n,1)+left(trans_n,9)+stk_n

sele 2
     use stkrec index trans_cn
sele 3
     use sifyl index si_d

*DO WHILE .T.
    *&C_HEAD
    *@ 20, 1 SAY SPACE(78)
    set colo to
    @ 22,0 clear to 24,79
    &C_MESSAGE
    @ 21, 16 SAY ' NOTE: Press <Enter> to Return to Main Menu. '
    *&C_BODY
    set colo to +w/r
    @ 6, 21 say "  Extract Incentives for Rogemson  "
    set colo to +w/b
    @ 7, 21 clear to 10,55
    @ 8, 21 SAY ' Start At Issued Date :'
    @ 9, 21 SAY ' Stop  At Issued Date :'
    minv_d= CTOD('01/01/2003')
    GOTO BOTTOM
    mfield2= DATE()
    GOTO TOP
    mfield1= CTOD('  /  /  ')
    &C_GET
    @ 9, 45 SAY mfield2 picture '99/99/9999'
    @ 8, 45 GET mfield1 PICTURE '99/99/9999'
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
               close data
               return
            ENDIF
            &C_GET
            @ 8, 45 SAY mfield1
        ENDIF
    ENDIF
    @ 9, 45 GET mfield2 PICTURE '@!'
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
            close data
            return
        ENDIF
        &C_GET
        @ 9, 45 SAY mfield2
    ENDIF
    IF mfield1>mfield2
       mtemp= mfield1
       mfield1= mfield2
       mfield2= mtemp
    ENDIF
    sele 3
    SEEK mfield1
    * start extraction based upon the sales invoice header file
    * filter by paid
    set colo to
    @ 21,0 clear to 21,79

    DO WHILE .not. EOF().and.inv_d<=mfield2    && file is sifyl
       if paid="F"
          skip
          loop
       endif

       * locate corresponding record in stkrec and check if cat="ROGEM"
       * if ROGEM, then add the record to the dummy file

       minv_n= 'S'+inv_n
       select 2
       seek minv_n
       DO WHILE .not. EOF().and.minv_n=trans_c+trans_n
          if stk_cat="ROGEM"
             sele 1
             append blank
             repl trans_n    with stkrec->trans_n
             repl trans_d    with stkrec->trans_d
             repl cust_n     with stkrec->cust_n
             repl stk_n      with stkrec->stk_n
             repl stk_m      with stkrec->stk_m
             * repl splyr_n    with stkrec->splyr_n
             * repl stk_cat    with stkrec->stk_cat
             repl issue_q    with stkrec->issue_q
             repl issue_u    with stkrec->issue_u
             repl issue_p    with stkrec->issue_p
             repl dcount1    with stkrec->dcount1
             repl t_prys     with stkrec->t_prys
             repl incen_disc with 5-(stkrec->dcount1)
             repl incen_amt  with (t_prys*incen_disc)/100
             unlock
          endif
          sele 2
          skip
       enddo
       sele 3
       skip
    enddo
    sele 1
    set safety off
    copy to c:\temp\incentiv
    set safety on
    close data
    set cent off
    atlmsg="completed extracting ROGEMSON records, press any key..."
    atllen=len(atlmsg)
    set colo to rb/rb
    @ 14,41-atllen/2-2 clear to 16,41-atllen/2+atllen+1
    set colo to +w/rb
    @ 14,41-atllen/2-2 to 16,41-atllen/2+atllen+1
    @ 15,41-atllen/2 say atlmsg
    atlkeypress=inkey(0)
    return

    *&C_HEAD
    *@ 8, 38 SAY mfield4 PICTURE '@!'
    *@ 8, 49 SAY mfield5 PICTURE '@!'
    *@ 8, 61 SAY mfield6 PICTURE '@!'
    *DO CASE
    *    CASE choice='L'
    *        STORE 0.00 TO ttl1, ttl2, ttl3, stl1, stl2, stl3, stl4, gtl1, gtl2, gtl3, gtl4
            &C_CLEAR
            @ 10, 1 CLEAR TO 19, 78
            flag= 1
            row= 9
            DO WHILE .not. EOF().and.inv_d<=mfield2
                IF LEN(TRIM(mfield3))<>0
                    IF mfield3<>cust_s
                        SKIP
                        LOOP
                    ENDIF
                ENDIF
                minv_n= 'S'+inv_n
                STORE 0.00 TO ttl1, ttl2, ttl3
                SELECT 2
                SEEK minv_n
                DO WHILE .not. EOF().and.minv_n=trans_c+trans_n
                    if len(trim(mfield4))<>0 .and. stk_cat=trim(mfield4)
                          ttl1=ttl1+t_prys
                    endif
                    if len(trim(mfield5))<>0 .and. stk_cat=trim(mfield5)
                          ttl2=ttl2+t_prys
                    endif
                    if len(trim(mfield6))<>0 .and. stk_cat=trim(mfield6)
                          ttl3=ttl3+t_prys
                    endif
                    SKIP
                ENDDO
                do case
                   && all cat empty, display the invoice
                   case len(trim(mfield4))=0 .and. len(trim(mfield5))=0 .and. len(trim(mfield6))=0
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
                    IF flag=1
                       c_list= c_option
                       flag= 0
                    ELSE
                       c_list= c_body
                       flag= 1
                    ENDIF
                    &C_LIST
                    @ row,  2 SAY inv_d  PICTURE '@!'
                    @ row, 12 SAY inv_n  PICTURE '@!'
                    @ row, 23 SAY cust_n PICTURE '@!'
                    @ row, 68 SAY net_a  PICTURE '###,###.##'
                    @ row, 34 SAY ttl1   PICTURE '###,###.##'
                    @ row, 45 SAY ttl2   PICTURE '###,###.##'
                    @ row, 56 SAY ttl3   PICTURE '###,###.##'
                    stl1= stl1+ttl1
                    stl2= stl2+ttl2
                    stl3= stl3+ttl3
                    stl4= stl4+net_a
                    gtl1= gtl1+ttl1
                    gtl2= gtl2+ttl2
                    gtl3= gtl3+ttl3
                    gtl4= gtl4+net_a
                    row= row+1

                   && ttl1 is not empty
                   case ttl1<>0 
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
                    IF flag=1
                       c_list= c_option
                       flag= 0
                    ELSE
                       c_list= c_body
                       flag= 1
                    ENDIF
                    &C_LIST
                    @ row,  2 SAY inv_d PICTURE '@!'
                    @ row, 12 SAY inv_n PICTURE '@!'
                    @ row, 23 SAY cust_n PICTURE '@!'
                    @ row, 68 SAY net_a PICTURE '###,###.##'
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

                   case ttl2<>0
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
                    IF flag=1
                       c_list= c_option
                       flag= 0
                    ELSE
                       c_list= c_body
                       flag= 1
                    ENDIF
                    &C_LIST
                    @ row,  2 SAY inv_d PICTURE '@!'
                    @ row, 12 SAY inv_n PICTURE '@!'
                    @ row, 23 SAY cust_n PICTURE '@!'
                    @ row, 68 SAY net_a PICTURE '###,###.##'
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

                   case ttl3<>0
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
                    IF flag=1
                       c_list= c_option
                       flag= 0
                    ELSE
                       c_list= c_body
                       flag= 1
                    ENDIF
                    &C_LIST
                    @ row,  2 SAY inv_d PICTURE '@!'
                    @ row, 12 SAY inv_n PICTURE '@!'
                    @ row, 23 SAY cust_n PICTURE '@!'
                    @ row, 68 SAY net_a PICTURE '###,###.##'
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
                other
                    sele 1
                    skip
                    loop
                endcase
                sele 1
                SKIP
                IF EOF()
                   EXIT
                ENDIF
                IF row=19
                    &C_HEAD
                    @ 19, 1 SAY SPACE(78)
                    @ 19, 10 SAY 'SUB   TOTAL'
                    @ 19, 33 SAY stl1 PICTURE '####,###.##'
                    @ 19, 44 SAY stl2 PICTURE '####,###.##'
                    @ 19, 55 SAY stl3 PICTURE '####,###.##'
                    @ 19, 66 SAY stl4 PICTURE '#,###,###.##'
                    @ 20, 1 SAY SPACE(78)
                    @ 20, 10 SAY 'GRAND TOTAL'
                    @ 20, 34 SAY gtl1 PICTURE '#######.##'
                    @ 20, 45 SAY gtl2 PICTURE '#######.##'
                    @ 20, 56 SAY gtl3 PICTURE '#######.##'
                    @ 20, 68 SAY gtl4 PICTURE '#######.##'
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
            &C_HEAD
            @ 19, 1 SAY SPACE(78)
            @ 19, 10 SAY 'SUB   TOTAL'
            @ 19, 34 SAY stl1 PICTURE '#######.##'
            @ 19, 45 SAY stl2 PICTURE '#######.##'
            @ 19, 56 SAY stl3 PICTURE '#######.##'
            @ 19, 66 SAY stl4 PICTURE '#,###,###.##'
            @ 20, 1 SAY SPACE(78)
            @ 20, 10 SAY 'GRAND TOTAL'
            @ 20, 34 SAY gtl1 PICTURE '#######.##'
            @ 20, 45 SAY gtl2 PICTURE '#######.##'
            @ 20, 56 SAY gtl3 PICTURE '#######.##'
            @ 20, 67 SAY gtl4 PICTURE '########.##'
        CASE choice='P'
            do testprt
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
                cdate= CMONTH(DATE())+' '+STR(DAY(DATE()),2)+', '+STR(YEAR(DATE()),4)
                head = 'Sales Summary from '+DTOC(mfield1)+' to '+DTOC(mfield2)
                head1= ''
                IF LEN(TRIM(mfield3))<>0
                    head1= 'For Territory = '+LTRIM(TRIM(mfield3))+' and '
                ENDIF
                head1 = head1+'Category = '+trim(mfield4)
                if len(trim(mfield5))<>0
                   head1 = head1+', '+trim(mfield5)
                endif
                if len(trim(mfield6))<>0
                   head1 = head1+', '+trim(mfield6)
                endif
                if len(trim(mfield7))<>0
                   head1 = head1+', '+trim(mfield7)
                endif
                
                @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
                @ 2, (80-LEN(company))/2 SAY company
                @ 3, (80-LEN(head))/2 SAY head
                *IF LEN(TRIM(mfield3))<>0
                    @ 4, (80-LEN(head1))/2 SAY head1
                *ENDIF
                ?? CHR(15)
                @ 6,  7 SAY '--------------------------------------------------------------------------------------------------------------------'
                @ 7,  7 SAY 'SI DATE     SI NO.        CUSTOMER CODE                                                                   NET AMOUNT'
                @ 7, 53 SAY mfield4 PICTURE '@!'
                @ 7, 69 SAY mfield5 PICTURE '@!'
                @ 7, 85 SAY mfield6 PICTURE '@!'
                @ 7,101 SAY mfield7 PICTURE '@!'
                @ 8,  7 SAY '--------------------------------------------------------------------------------------------------------------------'
                row= 9 
                DO WHILE .not. EOF().and.inv_d<=mfield2
                    IF LEN(TRIM(mfield3))<>0
                        IF mfield3<>cust_s
                            SKIP
                            LOOP
                        ENDIF
                    ENDIF
                    minv_n= 'S'+inv_n
                    STORE 0.00 TO ttl1, ttl2, ttl3, ttl4
                    SELECT 2
                    SEEK minv_n
                    DO WHILE .not. EOF().and.minv_n=trans_c+trans_n
                       if len(trim(mfield4))<>0 .and. stk_cat=trim(mfield4)
                          ttl1=ttl1+t_prys
                       endif
                       if len(trim(mfield5))<>0 .and. stk_cat=trim(mfield5)
                          ttl2=ttl2+t_prys
                       endif
                       if len(trim(mfield6))<>0 .and. stk_cat=trim(mfield6)
                          ttl3=ttl3+t_prys
                       endif
                       if len(trim(mfield7))<>0 .and. stk_cat=trim(mfield7)
                          ttl4=ttl4+t_prys
                       endif
                       SKIP
                    ENDDO
                    select 1
                    do case
                            && all cat empty, display the invoice
                       case len(trim(mfield4))=0 .and. len(trim(mfield5))=0 .and. len(trim(mfield6))=0 .and. len(trim(mfield07))=0
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
                            @ row,  7 SAY inv_d  PICTURE '@!'
                            @ row, 19 SAY inv_n  PICTURE '@!'
                            @ row, 33 SAY cust_n PICTURE '@!'
                            @ row, 47 SAY ttl1   PICTURE '###,###.##'
                            @ row, 63 SAY ttl2   PICTURE '###,###.##'
                            @ row, 79 SAY ttl3   PICTURE '###,###.##'
                            @ row, 95 SAY ttl4   PICTURE '###,###.##'
                            @ row,111 SAY net_a  PICTURE '###,###.##'
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
                            row= row+1
                    IF row>49
                       @ row+0, 46 SAY REPLICATE('-',77)
                       @ row+1, 46 SAY stl1 PICTURE '##,###,###.##'
                       @ row+1, 62 SAY stl2 PICTURE '##,###,###.##'
                       @ row+1, 78 SAY stl3 PICTURE '##,###,###.##'
                       @ row+1, 94 SAY stl4 PICTURE '##,###,###.##'
                       @ row+1, 110 SAY stl5 PICTURE '##,###,###.##'
                       @ row+3, 100 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                       @ 23, 50 SAY '...Printing'
                       SET CONSOLE OFF
                       SET DEVICE TO PRINTER
                       SET PRINTER ON
                       pg= pg+1
                       STORE 0.00 TO stl1, stl2, stl3, stl4, stl5
                       @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
                       @ 1, (80-LEN(head))/2 SAY head
                       *IF LEN(TRIM(mfield3))<>0
                           @ 2, (80-LEN(head1))/2 SAY head1
                       *ENDIF
                       ?? CHR(15)
                       @ 4, 7 SAY '--------------------------------------------------------------------------------------------------------------------'
                       @ 5, 7 SAY 'SI DATE     SI NO.        CUSTOMER CODE                                                                   NET AMOUNT'
                       @ 5, 53 SAY mfield4 PICTURE '@!'
                       @ 5, 69 SAY mfield5 PICTURE '@!'
                       @ 5, 85 SAY mfield6 PICTURE '@!'
                       @ 5, 101 SAY mfield7 PICTURE '@!'
                       @ 6, 7 SAY '--------------------------------------------------------------------------------------------------------------------'
                       row= 7
                    ENDIF


                       case ttl1<>0 
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
                            @ row,  7 SAY inv_d  PICTURE '@!'
                            @ row, 19 SAY inv_n  PICTURE '@!'
                            @ row, 33 SAY cust_n PICTURE '@!'
                            @ row, 47 SAY ttl1   PICTURE '###,###.##'
                            @ row, 63 SAY ttl2   PICTURE '###,###.##'
                            @ row, 79 SAY ttl3   PICTURE '###,###.##'
                            @ row, 95 SAY ttl4   PICTURE '###,###.##'
                            @ row,111 SAY net_a  PICTURE '###,###.##'
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
                            row= row+1
                    IF row>49
                       @ row+0, 46 SAY REPLICATE('-',77)
                       @ row+1, 46 SAY stl1 PICTURE '##,###,###.##'
                       @ row+1, 62 SAY stl2 PICTURE '##,###,###.##'
                       @ row+1, 78 SAY stl3 PICTURE '##,###,###.##'
                       @ row+1, 94 SAY stl4 PICTURE '##,###,###.##'
                       @ row+1, 110 SAY stl5 PICTURE '##,###,###.##'
                       @ row+3, 100 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                       @ 23, 50 SAY '...Printing'
                       SET CONSOLE OFF
                       SET DEVICE TO PRINTER
                       SET PRINTER ON
                       pg= pg+1
                       STORE 0.00 TO stl1, stl2, stl3, stl4, stl5
                       @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
                       @ 1, (80-LEN(head))/2 SAY head
                       *IF LEN(TRIM(mfield3))<>0
                           @ 2, (80-LEN(head1))/2 SAY head1
                       *ENDIF
                       ?? CHR(15)
                       @ 4, 7 SAY '--------------------------------------------------------------------------------------------------------------------'
                       @ 5, 7 SAY 'SI DATE     SI NO.        CUSTOMER CODE                                                                   NET AMOUNT'
                       @ 5, 53 SAY mfield4 PICTURE '@!'
                       @ 5, 69 SAY mfield5 PICTURE '@!'
                       @ 5, 85 SAY mfield6 PICTURE '@!'
                       @ 5, 101 SAY mfield7 PICTURE '@!'
                       @ 6, 7 SAY '--------------------------------------------------------------------------------------------------------------------'
                       row= 7
                    ENDIF

                       case ttl2<>0
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
                            @ row,  7 SAY inv_d  PICTURE '@!'
                            @ row, 19 SAY inv_n  PICTURE '@!'
                            @ row, 33 SAY cust_n PICTURE '@!'
                            @ row, 47 SAY ttl1   PICTURE '###,###.##'
                            @ row, 63 SAY ttl2   PICTURE '###,###.##'
                            @ row, 79 SAY ttl3   PICTURE '###,###.##'
                            @ row, 95 SAY ttl4   PICTURE '###,###.##'
                            @ row,111 SAY net_a  PICTURE '###,###.##'
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
                            row= row+1
                    IF row>49
                       @ row+0, 46 SAY REPLICATE('-',77)
                       @ row+1, 46 SAY stl1 PICTURE '##,###,###.##'
                       @ row+1, 62 SAY stl2 PICTURE '##,###,###.##'
                       @ row+1, 78 SAY stl3 PICTURE '##,###,###.##'
                       @ row+1, 94 SAY stl4 PICTURE '##,###,###.##'
                       @ row+1, 110 SAY stl5 PICTURE '##,###,###.##'
                       @ row+3, 100 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                       @ 23, 50 SAY '...Printing'
                       SET CONSOLE OFF
                       SET DEVICE TO PRINTER
                       SET PRINTER ON
                       pg= pg+1
                       STORE 0.00 TO stl1, stl2, stl3, stl4, stl5
                       @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
                       @ 1, (80-LEN(head))/2 SAY head
                       *IF LEN(TRIM(mfield3))<>0
                           @ 2, (80-LEN(head1))/2 SAY head1
                       *ENDIF
                       ?? CHR(15)
                       @ 4, 7 SAY '--------------------------------------------------------------------------------------------------------------------'
                       @ 5, 7 SAY 'SI DATE     SI NO.        CUSTOMER CODE                                                                   NET AMOUNT'
                       @ 5, 53 SAY mfield4 PICTURE '@!'
                       @ 5, 69 SAY mfield5 PICTURE '@!'
                       @ 5, 85 SAY mfield6 PICTURE '@!'
                       @ 5, 101 SAY mfield7 PICTURE '@!'
                       @ 6, 7 SAY '--------------------------------------------------------------------------------------------------------------------'
                       row= 7
                    ENDIF

                       case ttl3<>0
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
                            @ row,  7 SAY inv_d  PICTURE '@!'
                            @ row, 19 SAY inv_n  PICTURE '@!'
                            @ row, 33 SAY cust_n PICTURE '@!'
                            @ row, 47 SAY ttl1   PICTURE '###,###.##'
                            @ row, 63 SAY ttl2   PICTURE '###,###.##'
                            @ row, 79 SAY ttl3   PICTURE '###,###.##'
                            @ row, 95 SAY ttl4   PICTURE '###,###.##'
                            @ row,111 SAY net_a  PICTURE '###,###.##'
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
                            row= row+1
                    IF row>49
                       @ row+0, 46 SAY REPLICATE('-',77)
                       @ row+1, 46 SAY stl1 PICTURE '##,###,###.##'
                       @ row+1, 62 SAY stl2 PICTURE '##,###,###.##'
                       @ row+1, 78 SAY stl3 PICTURE '##,###,###.##'
                       @ row+1, 94 SAY stl4 PICTURE '##,###,###.##'
                       @ row+1, 110 SAY stl5 PICTURE '##,###,###.##'
                       @ row+3, 100 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                       @ 23, 50 SAY '...Printing'
                       SET CONSOLE OFF
                       SET DEVICE TO PRINTER
                       SET PRINTER ON
                       pg= pg+1
                       STORE 0.00 TO stl1, stl2, stl3, stl4, stl5
                       @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
                       @ 1, (80-LEN(head))/2 SAY head
                       *IF LEN(TRIM(mfield3))<>0
                           @ 2, (80-LEN(head1))/2 SAY head1
                       *ENDIF
                       ?? CHR(15)
                       @ 4, 7 SAY '--------------------------------------------------------------------------------------------------------------------'
                       @ 5, 7 SAY 'SI DATE     SI NO.        CUSTOMER CODE                                                                   NET AMOUNT'
                       @ 5, 53 SAY mfield4 PICTURE '@!'
                       @ 5, 69 SAY mfield5 PICTURE '@!'
                       @ 5, 85 SAY mfield6 PICTURE '@!'
                       @ 5, 101 SAY mfield7 PICTURE '@!'
                       @ 6, 7 SAY '--------------------------------------------------------------------------------------------------------------------'
                       row= 7
                    ENDIF

                       case ttl4<>0
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
                            @ row,  7 SAY inv_d  PICTURE '@!'
                            @ row, 19 SAY inv_n  PICTURE '@!'
                            @ row, 33 SAY cust_n PICTURE '@!'
                            @ row, 47 SAY ttl1   PICTURE '###,###.##'
                            @ row, 63 SAY ttl2   PICTURE '###,###.##'
                            @ row, 79 SAY ttl3   PICTURE '###,###.##'
                            @ row, 95 SAY ttl4   PICTURE '###,###.##'
                            @ row,111 SAY net_a  PICTURE '###,###.##'
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
                            row= row+1
                    IF row>49
                       @ row+0, 46 SAY REPLICATE('-',77)
                       @ row+1, 46 SAY stl1 PICTURE '##,###,###.##'
                       @ row+1, 62 SAY stl2 PICTURE '##,###,###.##'
                       @ row+1, 78 SAY stl3 PICTURE '##,###,###.##'
                       @ row+1, 94 SAY stl4 PICTURE '##,###,###.##'
                       @ row+1, 110 SAY stl5 PICTURE '##,###,###.##'
                       @ row+3, 100 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                       @ 23, 50 SAY '...Printing'
                       SET CONSOLE OFF
                       SET DEVICE TO PRINTER
                       SET PRINTER ON
                       pg= pg+1
                       STORE 0.00 TO stl1, stl2, stl3, stl4, stl5
                       @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
                       @ 1, (80-LEN(head))/2 SAY head
                       *IF LEN(TRIM(mfield3))<>0
                           @ 2, (80-LEN(head1))/2 SAY head1
                       *ENDIF
                       ?? CHR(15)
                       @ 4, 7 SAY '--------------------------------------------------------------------------------------------------------------------'
                       @ 5, 7 SAY 'SI DATE     SI NO.        CUSTOMER CODE                                                                   NET AMOUNT'
                       @ 5, 53 SAY mfield4 PICTURE '@!'
                       @ 5, 69 SAY mfield5 PICTURE '@!'
                       @ 5, 85 SAY mfield6 PICTURE '@!'
                       @ 5, 101 SAY mfield7 PICTURE '@!'
                       @ 6, 7 SAY '--------------------------------------------------------------------------------------------------------------------'
                       row= 7
                    ENDIF

                      other
                            sele 1
                            skip
                            loop
                    endcase
                    sele 1
                    SKIP
                    if eof()
                       exit
                    endif
                    IF row>49
                       @ row+0, 46  SAY REPLICATE('-',77)
                       @ row+1, 46  SAY stl1 PICTURE '##,###,###.##'
                       @ row+1, 62  SAY stl2 PICTURE '##,###,###.##'
                       @ row+1, 78  SAY stl3 PICTURE '##,###,###.##'
                       @ row+1, 94  SAY stl4 PICTURE '##,###,###.##'
                       @ row+1, 110 SAY stl5 PICTURE '##,###,###.##'
                       @ row+3, 100 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                       @ 23, 50 SAY '...Printing'
                       SET CONSOLE OFF
                       SET DEVICE TO PRINTER
                       SET PRINTER ON
                       pg= pg+1
                       STORE 0.00 TO stl1, stl2, stl3, stl4, stl5
                       @ 1, 1 SAY 'Page '+LTRIM(STR(pg))
                       @ 1, (80-LEN(head))/2 SAY head
                       *IF LEN(TRIM(mfield3))<>0
                           @ 2, (80-LEN(head1))/2 SAY head1
                       *ENDIF
                       ?? CHR(15)
                       @ 4, 7 SAY '--------------------------------------------------------------------------------------------------------------------'
                       @ 5, 7 SAY 'SI DATE     SI NO.        CUSTOMER CODE                                                                   NET AMOUNT'
                       @ 5, 53 SAY mfield4 PICTURE '@!'
                       @ 5, 69 SAY mfield5 PICTURE '@!'
                       @ 5, 85 SAY mfield6 PICTURE '@!'
                       @ 5, 101 SAY mfield7 PICTURE '@!'
                       @ 6, 7 SAY '--------------------------------------------------------------------------------------------------------------------'
                       row= 7
                    ENDIF
                ENDDO
                IF EOF().or.inv_d>mfield2
                    IF pg>1
                        @ row+0, 46 SAY REPLICATE('-',77)
                        @ row+1, 46 SAY stl1 PICTURE '##,###,###.##'
                        @ row+1, 62 SAY stl2 PICTURE '##,###,###.##'
                        @ row+1, 78 SAY stl3 PICTURE '##,###,###.##'
                        @ row+1, 94 SAY stl4 PICTURE '##,###,###.##'
                        @ row+1, 110 SAY stl5 PICTURE '##,###,###.##'
                        row= row+1
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
            SET CENTURY Off
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
        close data
        set cent off
        RETURN
    ENDIF
ENDDO
 
close data
set cent off
return



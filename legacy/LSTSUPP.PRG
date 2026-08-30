* program.....: LstSupp.prg
*             : Sales summary per inclusive date, supplier, territory, category and division
*             : modified 02/10/2002

DO BRDR2
*                   1         2         3         4         5         6         7         
*           234567890123456789012345678901234567890123456789012345678901234567890123456789
@ 8, 2 SAY 'SI DATE   SI NO.      CUST.CODE                  Sold Amount  INV. NET AMT.'
*           99/99/99  xxxxxxxxxx  xxxxxxxxxx 99,999,999.99 99,999,999.99  99,999,999.99
*                                              "    Supplier: xxxxxxxxxx"
*                                            Sup: xxxxxxxx 
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
   do lstsuppt
   set cent off
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
   *                        5         6         7
   *             90123456789012345678901234567890123456789
    @ 5, 43 SAY 'Territory: '
    @ 6, 43 SAY 'Supplier : '
    minv_d= CTOD('01/01/2001')
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
   *@ 5, 72 GET mfield5 PICTURE '@!'
   *@ 6, 72 GET mfield6 PICTURE '@!'
   *READ

    SET CENTURY OFF
    choice= 'L'
    &C_HEAD
   *if len(trim(mfield5))=0
   *   if len(trim(mfield6))=0
   *      hd="Supplier: "+trim(mfield4)
   *      @ 8,38 say space(20)
   *      @ 8,62-len(hd) say hd 
   *   else
   *      @ 8,35 say "Sup: "
   *      @ 8,40 say left(mfield4,8)
   *      @ 8,52 say "Cat: "
   *      @ 8,57 say mfield6 pict "@!"
   *   endif
   *else
   *   if len(trim(mfield6))=0
   *      @ 8,35 say "Sup: "
   *      @ 8,40 say left(mfield4,8)
   *      @ 8,52 say "Div: "
   *      @ 8,57 say mfield5 pict "@!"
   *   else
   *      @ 8, 43 SAY mfield5 PICTURE '@!'
   *      @ 8, 57 SAY mfield6 PICTURE '@!'
   *   endif
   *endif

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
                    IF mfield3<>cust_s
                        SKIP
                        LOOP
                    ENDIF
                ENDIF
                minv_n= 'S'+inv_n
                mnet_a= net_a
                STORE 0.00 TO ttl1, ttl2, ttl3
                SELECT 2
                SEEK minv_n
                *SUSPEND
                DO WHILE .not. EOF().and.minv_n=trans_c+trans_n
                    *SUSPEND
                    if splyr_n=trim(mfield4)
                       ttl3=ttl3+t_prys
                      *do case
                         *case len(trim(mfield5))=0 .and. len(trim(mfield6))<>0 && supplier & cat
                         *     if stk_cat=trim(mfield6)
                         *        ttl2=ttl2+t_prys
                         *     endif
                         *case len(trim(mfield5))<>0 .and. len(trim(mfield6))=0 && supplier & cat
                         *     if stk_dv=trim(mfield5)
                         *        ttl1=ttl1+t_prys
                         *     endif
                         *case len(trim(mfield5))<>0 .and. len(trim(mfield6))<>0 && supplier; cat and div
                         *     if stk_cat=trim(mfield6)
                         *        ttl2=ttl2+t_prys
                         *     endif
                         *     if stk_dv=trim(mfield5)
                         *        ttl1=ttl1+t_prys
                         *     endif
                      *endcase
                    endif
                    SKIP
                ENDDO

                IF TTL3=0
                   SELE 1
                   SKIP
                   LOOP
                ENDIF

                IF flag=1
                   c_list= c_option
                   flag= 0
                ELSE
                   c_list= c_body
                   flag= 1
                ENDIF

                select 1
                &C_LIST
                @ row,  2 SAY inv_d  PICTURE '@!'
                @ row, 12 SAY inv_n  PICTURE '@!'
                @ row, 24 SAY cust_n PICTURE '@!'

               *do case
               *   case len(trim(mfield5))=0 .and. len(trim(mfield6))=0 && supplier
                        @ row, 49 say ttl3 picture "##,###,###.99"
                        stl3= stl3+ttl3
                        stl4= stl4+mnet_a
                        gtl3= gtl3+ttl3
                        gtl4= gtl4+mnet_a

               *   case len(trim(mfield5))=0 .and. len(trim(mfield6))<>0 && supplier & cat
               *        @ row, 35 say ttl3 picture "##,###,###.99"
               *        @ row, 49 say ttl2 picture "##,###,###.99"
               *        stl2= stl2+ttl2
               *        stl3= stl3+ttl3
               *        stl4= stl4+mnet_a
               *        gtl2= gtl2+ttl2
               *        gtl3= gtl3+ttl3
               *        gtl4= gtl4+mnet_a

               *   case len(trim(mfield5))<>0 .and. len(trim(mfield6))=0 && supplier & cat
               *        @ row, 35 say ttl3 picture "##,###,###.99"
               *        @ row, 49 say ttl1 picture "##,###,###.99"
               *        stl1= stl1+ttl1
               *        stl3= stl3+ttl3
               *        stl4= stl4+mnet_a
               *        gtl1= gtl1+ttl1
               *        gtl3= gtl3+ttl3
               *        gtl4= gtl4+mnet_a
                
               *   case len(trim(mfield5))<>0 .and. len(trim(mfield6))<>0 && supplier; cat and div
               *        @ row, 35 say ttl1 picture "##,###,###.99"
               *        @ row, 49 say ttl2 picture "##,###,###.99"
               *        stl1= stl1+ttl1
               *        stl2= stl2+ttl2
               *        stl3= stl3+ttl3
               *        stl4= stl4+mnet_a
               *        gtl1= gtl1+ttl1
               *        gtl2= gtl2+ttl2
               *        gtl3= gtl3+ttl3
               *        gtl4= gtl4+mnet_a
                
               *endcase

                @ row, 64 SAY mnet_a PICTURE '##,###,###.##'
                row= row+1
                SKIP
                IF EOF()
                   EXIT
                ENDIF
                IF row=19
                    &C_HEAD
                    @ 19, 1 SAY SPACE(78)
                    @ 19, 24 SAY 'SUB   TOTAL'
                   *do case
                   *   case len(trim(mfield5))=0 .and. len(trim(mfield6))=0 && supplier
                            @ 19, 49 say stl3 picture "##,###,###.99"
                            @ 19, 64 say stl4 picture "##,###,###.99"
                            @ 20, 1 SAY SPACE(78)
                            @ 20, 24 SAY 'GRAND TOTAL'
                            @ 20, 49 say gtl3 picture "##,###,###.99"
                            @ 20, 64 say gtl4 picture "##,###,###.99"

                   *   case len(trim(mfield5))=0 .and. len(trim(mfield6))<>0 && supplier & cat
                   *      @ 19, 35 say stl3 picture "##,###,###.99"
                   *      @ 19, 49 say stl2 picture "##,###,###.99"
                   *      @ 19, 64 say stl4 picture "##,###,###.99"
                   *      @ 20, 1 SAY SPACE(78)
                   *      @ 20, 24 SAY 'GRAND TOTAL'
                   *      @ 20, 35 say gtl3 picture "##,###,###.99"
                   *      @ 20, 49 say gtl2 picture "##,###,###.99"
                   *      @ 20, 64 say gtl4 picture "##,###,###.99"
                    
                   *   case len(trim(mfield5))<>0 .and. len(trim(mfield6))=0 && supplier & cat
                   *      @ 19, 35 say stl3 picture "##,###,###.99"
                   *      @ 19, 49 say stl1 picture "##,###,###.99"
                   *      @ 19, 64 say stl4 picture "##,###,###.99"
                   *      @ 20, 1 SAY SPACE(78)
                   *      @ 20, 24 SAY 'GRAND TOTAL'
                   *      @ 20, 35 say gtl3 picture "##,###,###.99"
                   *      @ 20, 49 say gtl1 picture "##,###,###.99"
                   *      @ 20, 64 say gtl4 picture "##,###,###.99"
                    
                   *   case len(trim(mfield5))<>0 .and. len(trim(mfield6))<>0 && supplier; cat and div
                   *      @ 19, 2  say trim(mfield4)+" Totals:"
                   *      @ 19, 35 say stl1 picture "##,###,###.99"
                   *      @ 19, 49 say stl2 picture "##,###,###.99"
                   *      @ 19, 64 say stl4 picture "##,###,###.99"
                   *      @ 20, 1 SAY SPACE(78)
                   *      @ 20, 2  say gtl3 picture "##,###,###.99"
                   *      @ 20, 24 SAY 'GRAND TOTAL'
                   *      @ 20, 35 say gtl1 picture "##,###,###.99"
                   *      @ 20, 49 say gtl2 picture "##,###,###.99"
                   *      @ 20, 64 say gtl4 picture "##,###,###.99"

                   *endcase

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
           *do case
           *   case len(trim(mfield5))=0 .and. len(trim(mfield6))=0 && supplier
                          &C_HEAD
                          @ 19, 1 SAY SPACE(78)
                          @ 19, 24 SAY 'SUB   TOTAL'
                          @ 19, 49 say stl3 picture "##,###,###.99"
                          @ 19, 64 say stl4 picture "##,###,###.99"
                          @ 20, 1 SAY SPACE(78)
                          @ 20, 24 SAY 'GRAND TOTAL'
                          @ 20, 49 say gtl3 picture "##,###,###.99"
                          @ 20, 64 say gtl4 picture "##,###,###.99"

           *   case len(trim(mfield5))=0 .and. len(trim(mfield6))<>0 && supplier & cat
           *              @ 19, 35 say stl3 picture "##,###,###.99"
           *              @ 19, 49 say stl2 picture "##,###,###.99"
           *              @ 19, 64 say stl4 picture "##,###,###.99"
           *              @ 20, 1 SAY SPACE(78)
           *              @ 20, 24 SAY 'GRAND TOTAL'
           *              @ 20, 35 say gtl3 picture "##,###,###.99"
           *              @ 20, 49 say gtl2 picture "##,###,###.99"
           *              @ 20, 64 say gtl4 picture "##,###,###.99"
           *
           *   case len(trim(mfield5))<>0 .and. len(trim(mfield6))=0 && supplier & cat
           *              @ 19, 35 say stl3 picture "##,###,###.99"
           *              @ 19, 49 say stl1 picture "##,###,###.99"
           *              @ 19, 64 say stl4 picture "##,###,###.99"
           *              @ 20, 1 SAY SPACE(78)
           *              @ 20, 24 SAY 'GRAND TOTAL'
           *              @ 20, 35 say gtl3 picture "##,###,###.99"
           *              @ 20, 49 say gtl1 picture "##,###,###.99"
           *              @ 20, 64 say gtl4 picture "##,###,###.99"

           *   case len(trim(mfield5))<>0 .and. len(trim(mfield6))<>0 && supplier; cat and div
           *              @ 19, 2  say trim(mfield4)+" Totals:"
           *              @ 19, 35 say stl1 picture "##,###,###.99"
           *              @ 19, 49 say stl2 picture "##,###,###.99"
           *              @ 19, 64 say stl4 picture "##,###,###.99"
           *              @ 20, 1 SAY SPACE(78)
           *              @ 20, 24 SAY 'GRAND TOTAL'
           *              @ 20, 2  say gtl3 picture "##,###,###.99"
           *              @ 20, 35 say gtl1 picture "##,###,###.99"
           *              @ 20, 49 say gtl2 picture "##,###,###.99"
           *              @ 20, 64 say gtl4 picture "##,###,###.99"

           *endcase

        CASE choice='P'
            pg= 1
            STORE 0.00 TO ttl1, ttl2, ttl3
            STORE 0.00 TO stl1, stl2, stl3, stl4
            STORE 0.00 TO gtl1, gtl2, gtl3, gtl4
            *DO WHILE .T.
                &C_MESSAGE
                @ 23, 50 SAY '...Printing'
                SET CONSOLE OFF
                SET DEVICE TO PRINTER
                SET PRINTER ON
                ?? CHR(27)+CHR(64)
                ?? CHR(18)
                cdate= CMONTH(DATE())+' '+STR(DAY(DATE()),2)+', '+STR(YEAR(DATE()),4)
                head= 'Sales Summary from '+DTOC(mfield1)+' to '+DTOC(mfield2)
                IF LEN(TRIM(mfield3))<>0
                    head1= 'For Territory='+LTRIM(TRIM(mfield3))+", Supplier="+trim(mfield4)
                else
                    head1= 'For Territory=all, Supplier='+trim(mfield4)
                ENDIF
                if len(trim(mfield5))<>0
                   head1= head1+", Division="+trim(mfield5)
                endif
                if len(trim(mfield6))<>0
                   head1= head1+", Category="+trim(mfield6)
                endif
                @ 3, 1 SAY 'Page '+LTRIM(STR(pg))
                @ 3, (80-LEN(company))/2 SAY company
                @ 4, (80-LEN(head))/2    SAY head
                @ 5, (80-LEN(head1))/2   SAY head1

                do case
                   case len(trim(mfield5))=0 .and. len(trim(mfield6))=0 && supplier
                        @ 7, 2 say '==========================================================================='
                        @ 8, 2 SAY 'SI DATE   SI NO.      CUST.CODE                               INV. NET AMT.'
                        hd="Supplier: "+trim(mfield4)
                        @ 8,62-len(hd) say hd 
                        @ 9, 2 say '==========================================================================='

                        store 0.00 to ttl1, ttl2, ttl3
                        store 0.00 to stl1, stl2, stl3, stl4
                        store 0.00 to gtl1, gtl2, gtl3, gtl4
                        store 10   to row
                        store 0    to atlsw

                        DO WHILE .not. EOF().and.inv_d<=mfield2
                           Select 1
                           IF LEN(TRIM(mfield3))<>0
                              IF mfield3<>cust_s
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
                                 ttl3=ttl3+t_prys
                                 do case
                                    case len(trim(mfield5))=0 .and. len(trim(mfield6))<>0 && supplier & cat
                                         if stk_cat=trim(mfield6)
                                            ttl2=ttl2+t_prys
                                         endif
                                    case len(trim(mfield5))<>0 .and. len(trim(mfield6))=0 && supplier & cat
                                         if stk_dv=trim(mfield5)
                                            ttl1=ttl1+t_prys
                                         endif
                                    case len(trim(mfield5))<>0 .and. len(trim(mfield6))<>0 && supplier; cat and div
                                         if stk_cat=trim(mfield6)
                                            ttl2=ttl2+t_prys
                                         endif
                                         if stk_dv=trim(mfield5)
                                            ttl1=ttl1+t_prys
                                         endif
                                 endcase
                              endif
                              SKIP
                           ENDDO

                           IF TTL3=0
                              SELE 1
                              SKIP
                              LOOP
                           ENDIF

                           select 1
                           @ row,  2 SAY inv_d  PICTURE '@!'
                           @ row, 12 SAY inv_n  PICTURE '@!'
                           @ row, 24 SAY cust_n PICTURE '@!'
                           @ row, 49 say ttl3   picture "##,###,###.99"
                           @ row, 64 SAY mnet_a PICTURE '##,###,###.##'

                           stl3= stl3+ttl3
                           stl4= stl4+mnet_a
                           gtl3= gtl3+ttl3
                           gtl4= gtl4+mnet_a

                           row= row+1
                           SKIP

                           *IF EOF()
                           *   EXIT
                           *ENDIF
                           IF row>53
                              @ row+1, 49 SAY "-------------"
                              @ row+1, 64 SAY "-------------"
                              @ row+2, 49 SAY stl3 PICTURE '##,###,###.##'
                              @ row+2, 64 SAY stl4 PICTURE '##,###,###.##'
                              @ row+4, 55 SAY '...continued on page '+LTRIM(STR(pg+1))
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
                              @ 3, 1 SAY 'Page '+LTRIM(STR(pg))
                              @ 3, (80-LEN(company))/2 SAY company
                              @ 4, (80-LEN(head))/2    SAY head
                              @ 5, (80-LEN(head1))/2   SAY head1
                              @ 7, 2 say '==========================================================================='
                              @ 8, 2 SAY 'SI DATE   SI NO.      CUST.CODE                               INV. NET AMT.'
                              @ 8,62-len(hd) say hd 
                              @ 9, 2 say '==========================================================================='
                              STORE 10 TO ROW
                           ENDIF
                           IF EOF().or.inv_d>mfield2
                              store 1 to atlsw
                              IF pg>1
                                 @ row+1, 49 SAY "-------------"
                                 @ row+1, 64 SAY "-------------"
                                 @ row+2, 49 SAY stl3 PICTURE '##,###,###.##'
                                 @ row+2, 64 SAY stl4 PICTURE '##,###,###.##'
                                 row= row+2
                              ENDIF
                              @ row+1, 49 SAY "============="
                              @ row+1, 64 SAY "============="
                              @ row+2, 49 SAY gtl3 PICTURE '##,###,###.##'
                              @ row+2, 64 SAY gtl4 PICTURE '##,###,###.##'
                              @ row+3, 49 SAY "============="
                              @ row+3, 64 SAY "============="
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
                        if atlsw=0
                           IF pg>1
                              @ row+1, 49 SAY "-------------"
                              @ row+1, 64 SAY "-------------"
                              @ row+2, 49 SAY stl3 PICTURE '##,###,###.##'
                              @ row+2, 64 SAY stl4 PICTURE '##,###,###.##'
                              row= row+2
                           ENDIF
                           @ row+1, 49 SAY "============="
                           @ row+1, 64 SAY "============="
                           @ row+2, 49 SAY gtl3 PICTURE '##,###,###.##'
                           @ row+2, 64 SAY gtl4 PICTURE '##,###,###.##'
                           @ row+3, 49 SAY "============="
                           @ row+3, 64 SAY "============="
                           ?
                           ?? CHR(18)
                           EJECT
                           SET PRINTER OFF
                           SET DEVICE TO SCREEN
                           SET CONSOLE ON
                           &C_CLEAR
                           @ 23, 0

                        endif
                   case len(trim(mfield5))=0 .and. len(trim(mfield6))<>0 && supplier & cat
                        * 
                   case len(trim(mfield5))<>0 .and. len(trim(mfield6))=0 && supplier & div
                        *
                   case len(trim(mfield5))<>0 .and. len(trim(mfield6))<>0 && supplier; cat and div
                        *
                endcase
            *ENDDO
        OTHERWISE
            SET CENTURY Off
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
        close data
        set cent off
        RETURN
    ENDIF
ENDDO
 
close data
set cent off
return


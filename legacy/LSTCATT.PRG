* program.....: LstCatT.prg
*             : 01-30-02
*             : sale summary by category - totals only

set cent on

SELECT 2
   USE STKREC INDEX TRANS_CN
SELECT 1
   USE SIFYL INDEX SI_D

DO BRDR2
@ 8,  2 SAY 'SI DATE   SI NO.     CUST.CODE                                     NET AMT.'
@ 01,01 say 'B] Sales Per Category - Totals only '
DO WHILE .T.
    &C_HEAD
    @ 20, 1 SAY SPACE(78)
    &C_MESSAGE
    @ 21, 20 SAY ' NOTE: Press <Enter> to Return to Main Menu. '
    &C_BODY
    @ 5, 3 SAY 'Start At Issued Date :'
    @ 6, 3 SAY 'Stop  At Issued Date :'
    @ 5, 43 SAY 'Territory:'
    @ 6, 43 SAY 'Category :'
    minv_d= CTOD('01/01/2000')
    GOTO BOTTOM
    mfield2= DATE()
    GOTO TOP
    mfield1= CTOD('  /  /  ')
    &C_GET
    @ 6, 26 SAY mfield2
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
            @ 5, 26 SAY mfield1
        ENDIF
    ENDIF
    @ 6, 26 GET mfield2 PICTURE '@!'
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
    IF mfield1>mfield2
        mtemp= mfield1
        mfield1= mfield2
        mfield2= mtemp
    ENDIF
    SEEK mfield1

    STORE 0.00 TO ttl1, ttl2, ttl3, ttl4, stl1, stl2, stl3, stl4, stl5 
    STORE 0.00 TO gtl1, gtl2, gtl3, gtl4, gtl5
    &C_CLEAR
    @ 10, 1 CLEAR TO 19, 78
    flag= 1
    row= 9

    set color to *+g
    @ 11, 10 SAY 'Please wait, computing...'
    set colo to

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
      *do case
               * all cat empty, display the invoice
      *   case len(trim(mfield4))=0 .and. len(trim(mfield5))=0 .and. len(trim(mfield6))=0 .AND. LEN(TRIM(MFIELD7))=0
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
       
               gtl1= gtl1+ttl1
               gtl2= gtl2+ttl2
               gtl3= gtl3+ttl3
               gtl4= gtl4+ttl4
               gtl5= gtl5+net_a
      *
      *   case ttl1<>0  && ttl1 is not empty
      *        SELECT 1
      *        ttl1= ttl1-ttl1*dcount1/100
      *        ttl1= ttl1-ttl1*dcount2/100
      *        ttl1= ttl1-ttl1*dcount3/100
      *        ttl2= ttl2-ttl2*dcount1/100
      *        ttl2= ttl2-ttl2*dcount2/100
      *        ttl2= ttl2-ttl2*dcount3/100
      *        ttl3= ttl3-ttl3*dcount1/100
      *        ttl3= ttl3-ttl3*dcount2/100
      *        ttl3= ttl3-ttl3*dcount3/100
      *        ttl4= ttl4-ttl4*dcount1/100
      *        ttl4= ttl4-ttl4*dcount2/100
      *        ttl4= ttl4-ttl4*dcount3/100
      *
      *        gtl1= gtl1+ttl1
      *        gtl2= gtl2+ttl2
      *        gtl3= gtl3+ttl3
      *        gtl4= gtl4+ttl4
      *        gtl5= gtl5+net_a
      *
      *   case ttl3<>0
      *        SELECT 1
      *        ttl1= ttl1-ttl1*dcount1/100
      *        ttl1= ttl1-ttl1*dcount2/100
      *        ttl1= ttl1-ttl1*dcount3/100
      *        ttl2= ttl2-ttl2*dcount1/100
      *        ttl2= ttl2-ttl2*dcount2/100
      *        ttl2= ttl2-ttl2*dcount3/100
      *        ttl3= ttl3-ttl3*dcount1/100
      *        ttl3= ttl3-ttl3*dcount2/100
      *        ttl3= ttl3-ttl3*dcount3/100
      **       ttl4= ttl4-ttl4*dcount1/100
      *        ttl4= ttl4-ttl4*dcount2/100
      *        ttl4= ttl4-ttl4*dcount3/100
      *
      *        gtl1= gtl1+ttl1
      *        gtl2= gtl2+ttl2
      *        gtl3= gtl3+ttl3
      *        gtl4= gtl4+ttl4
      *        gtl5= gtl5+net_a
      *
      *   case ttl4<>0
      *        SELECT 1
      *        ttl1= ttl1-ttl1*dcount1/100
      *        ttl1= ttl1-ttl1*dcount2/100
      *        ttl1= ttl1-ttl1*dcount3/100
      *        ttl2= ttl2-ttl2*dcount1/100
      *        ttl2= ttl2-ttl2*dcount2/100
      *        ttl2= ttl2-ttl2*dcount3/100
      *        ttl3= ttl3-ttl3*dcount1/100
      *        ttl3= ttl3-ttl3*dcount2/100
      *        ttl3= ttl3-ttl3*dcount3/100
      *        ttl4= ttl4-ttl4*dcount1/100
      *        ttl4= ttl4-ttl4*dcount2/100
      *        ttl4= ttl4-ttl4*dcount3/100
      *
      *        gtl1= gtl1+ttl1
      *        gtl2= gtl2+ttl2
       *       gtl3= gtl3+ttl3
      *        gtl4= gtl4+ttl4
       *       gtl5= gtl5+net_a
       *
       *  other
      *        sele 1
      *        skip
      *        loop
      *endcase
       sele 1
       SKIP
       IF EOF()
          EXIT
       ENDIF
    ENDDO
    @ 11, 10 say "                          "
    set colo to +g
    row=11
    if len(trim(mfield4))<>0
       @ row, 23 say mfield4
       @ row, 33 say ":"
       @ row, 36 SAY gtl1 PICTURE '###,###,###.##'
       row=row+1
    endif
    if len(trim(mfield5))<>0
       @ row, 23 say mfield5
       @ row, 33 say ":"
       @ row, 36 SAY gtl2 PICTURE '###,###,###.##'
       row=row+1
    endif
    if len(trim(mfield6))<>0
       @ row, 23 say mfield6
       @ row, 33 say ":"
       @ row, 36 SAY gtl3 PICTURE '###,###,###.##'
       row=row+1
    endif
    if len(trim(mfield7))<>0
       @ row, 23 say mfield7
       @ row, 33 say ":"
       @ row, 36 SAY gtl4 PICTURE '###,###,###.##'
       row=row+1
    endif          
   *row=row+1      
   *@ row, 15 say "Total Sales Amount:"
   *@ row, 36 say gtl5 PICTURE '###,###,###.##'

    confirm= 'A'
    &C_CLEAR
    @ 21, 0
    &C_MESSAGE
    do while .t.
       @ 21, 24 SAY ' Return to Previous Menu (y/n). ' GET confirm PICT 'Y'
       READ
       if confirm$"YyNn"
          exit
       endif
    enddo

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

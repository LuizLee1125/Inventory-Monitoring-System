* program.....: LstSaleT.prg
*             : 11/20/01
*             : sales summary total only

SELECT 1
   USE SIFYL INDEX SI_D

DO BRDR2
@ 01,01 say 'A] Sales Summary - Totals only '
@ 8, 2 SAY '                     Tran. Amount     Net Amount     Tran. Cost  Gross Profit'

Do while .t.
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
    minv_d= CTOD('01/01/2001')
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
    x_terri = space(10)
    x_area  = space(10)
    @ 5,55 get x_terri pict '@!'
    @ 6,55 get x_area  pict '@!'
    read
    SET CENTURY OFF
    IF mfield1>mfield2
        mtemp= mfield1
        mfield1= mfield2
        mfield2= mtemp
    ENDIF
    SEEK mfield1
    STORE 0.00 TO stl1, stl2, stl3, stl4, gtl1, gtl2, gtl3, gtl4
    &C_CLEAR
    @ 10, 1 CLEAR TO 19, 78
    flag= 1
    row= 9
    set color to *+g
    @ 11, 10 SAY 'Please wait, computing...'
    set colo to
    DO WHILE .not. EOF().and.inv_d<=mfield2
       DO CASE
          CASE X_TERRI=" "
               IF cust_ac=trim(x_area)
                  stl1= stl1+inv_a
                  stl2= stl2+net_a
                  stl3= stl3+inv_c
                  stl4= stl4+net_a-inv_c
                  gtl1= gtl1+inv_a
                  gtl2= gtl2+net_a
                  gtl3= gtl3+inv_c
                  gtl4= gtl4+net_a-inv_c
               ENDIF
          OTHERWISE     
               SET EXACT ON
               if cust_s=trim(x_terri)
                  SET EXACT OFF
                  IF cust_ac=trim(x_area)
                     stl1= stl1+inv_a
                     stl2= stl2+net_a
                     stl3= stl3+inv_c
                     stl4= stl4+net_a-inv_c
                     gtl1= gtl1+inv_a
                     gtl2= gtl2+net_a
                     gtl3= gtl3+inv_c
                     gtl4= gtl4+net_a-inv_c
                  ENDIF
               endif
       ENDCASE
       SET EXACT OFF
       SKIP
    ENDDO
    @ 11, 10 say "                          "
    @ 14, 1 SAY SPACE(78)
    set colo to +g
    @ 14, 08 SAY 'GRAND TOTAL:'
    if muser="ADMIN" .OR. muser="BERDY"
       @ 14, 22 SAY gtl1 PICTURE '##,###,###.##'
       @ 14, 37 SAY gtl2 PICTURE '##,###,###.##'
       @ 14, 52 SAY gtl3 PICTURE '##,###,###.##'
       @ 14, 66 SAY gtl4 PICTURE '##,###,###.##'
    else
       @ 14, 22 SAY gtl1 PICTURE '##,###,###.##'
       @ 14, 37 SAY gtl2 PICTURE '##,###,###.##'
       @ 14, 52 SAY gtl3 PICTURE '    --    '
       @ 14, 66 SAY gtl4 PICTURE '    --    '
    endif
    confirm= 'N'
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
        CLOSE DATA
        set cent off
        RETURN
    ENDIF
enddo 
CLOSE DATA
RETURN

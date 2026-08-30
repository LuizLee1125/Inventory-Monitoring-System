* program.....: LstSuppT.prg
*             : Totals only - Sales summary per inclusive date, supplier, territory, category and division
*             : modified 02/10/2002

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

    *DO OPTION8
    IF mfield1>mfield2
        mtemp= mfield1
        mfield1= mfield2
        mfield2= mtemp
    ENDIF
    SEEK mfield1

    STORE 0.00 TO ttl1, ttl2, ttl3
    store 0.00 to stl1, stl2, stl3, stl4
    store 0.00 to gtl1, gtl2, gtl3, gtl4

    &C_CLEAR
    @ 10, 1 CLEAR TO 19, 78
    flag= 1

    set color to *+g
    @ 11, 10 say 'Please wait, computing...'
    set color to 

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
              gtl3=gtl3+t_prys
          endif
          SKIP
       ENDDO

       IF TTL3=0
          SELE 1
          SKIP
          LOOP
       ENDIF

       gtl4= gtl4+mnet_a
       sele 1
       skip
    ENDDO

    set colo to
    @ 11,10 clear to 11,50
    set colo to +g
    @ 13, 20 SAY 'GRAND TOTALS:'
    @ 13, 49 say gtl3 picture "##,###,###.99"
    @ 13, 64 say gtl4 picture "##,###,###.99"

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
        LOOP
    ELSE
        close data
        set cent off
        set exact off
        RETURN
    ENDIF
ENDDO
 
close data
set cent off
set exact off
return

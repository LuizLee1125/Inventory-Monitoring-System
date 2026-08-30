* program.....: LstSaict.prg
*             : sales per item per customer -> total
*             : 05/05/2006

SELECT 2
   USE SIFYL INDEX SI_N
SELECT 1
   USE STKREC INDEX SI_ID

DO BRDR2
@ 8, 2 SAY 'DATE     SI NO.     CUST-CODE     QUANTITY     PRICE DISCOUNT        TOTAL'

DO WHILE .T.
    &C_HEAD
    @ 20, 1 SAY SPACE(78)
    &C_MESSAGE
    @ 21, 20 SAY ' NOTE: Press <Enter> to Return to Main Menu. '
    &C_BODY
    @ 5, 2 SAY 'Stock Code :'
    @ 6, 2 SAY 'Customer   :'
    @ 5, 46 SAY 'Start At Issued Date :'
    @ 6, 46 SAY 'Stop  At Issued Date :'
    DO WHILE .T.
        &C_GET
        mfield03= SPACE(10)
        @ 5, 15 GET mfield03 PICTURE '@!'
        READ
        IF LEN(TRIM(mfield03))=0
            SET CENT ON
            close data
            RETURN
        ENDIF
        SEEK LTRIM(TRIM(mfield03))
        IF EOF()
            choice= ' '
            &C_CLEAR
            @ 21, 0 CLEAR
            &C_MESSAGE
            @ 23, 30 SAY ' No Such Stock Code. '
            &C_GET
            @ 21, 20 SAY ' Press <A> to Abort, any key to Continue. ' GET choice PICTURE '!'
            READ
            IF choice='A'
                close data
                RETURN
            ELSE
                &C_CLEAR
                @ 21, 0
                @ 23, 0
                LOOP
            ENDIF
        ENDIF
        &C_GET
        mfield03= stk_n
        @ 5, 15 SAY mfield03 PICTURE '@!'
        EXIT
    ENDDO
    DO WHILE .T.
        SET CENT ON
        missue_d= CTOD('01/01/2000')
        mfield02= DATE()
        mfield01= issue_d
        mfield04= SPACE(10)
        &C_GET
        @ 6, 15 GET mfield04 PICTURE '@!'
        @ 6, 69 SAY mfield02 PICTURE '99/99/9999'
        @ 5, 69 GET mfield01 PICTURE '@!'
        READ
        SEEK mfield03+STR(YEAR(mfield01),4)+SUBSTR(DTOC(mfield01),1,5)
        IF EOF()
            SEEK mfield03
            DO CASE
                CASE mfield01<issue_d
                    mfield01= issue_d
                    confirm= ' '
                    &C_CLEAR
                    @ 21, 0 CLEAR
                    &C_MESSAGE
                    @ 23, 23 SAY ' Earliest Recorded Date is '+DTOC(mfield01)+'. '
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
                    @ 5, 70 SAY mfield01
                CASE mfield01>issue_d
                    DO WHILE .not. EOF().and.mfield03=stk_n.and.mfield01>=issue_d
                        SKIP
                    ENDDO
                    mfield01= issue_d
                    confirm= ' '
                    &C_CLEAR
                    @ 21, 0 CLEAR
                    &C_MESSAGE
                    @ 23, 23 SAY ' Closest Recorded Date is '+DTOC(mfield01)+'. '
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
                    @ 5, 69 SAY mfield01
            ENDCASE
        ENDIF
        @ 6, 69 GET mfield02 PICTURE '@!'
        READ
        SET CENT OFF
        EXIT
    ENDDO
    SET CENTURY OFF
    choice= 'L'
    IF mfield01>mfield02
        mtemp= mfield01
        mfield01= mfield02
        mfield02= mtemp
    ENDIF
    SEEK mfield03+STR(YEAR(mfield01),4)+SUBSTR(DTOC(mfield01),1,5)

    STORE 0.00 TO stl1, stl2, gtl1, gtl2
    &C_CLEAR
    @ 10, 1 CLEAR TO 19, 78
    flag= 1
    row= 9

    set color to *+g
    @ 11, 10 say 'Please wait, computing...'
    set color to 

    DO WHILE .not. EOF().and.issue_d<=mfield02.and.stk_n=mfield03.and.issue_d>=mfield01
       DO CASE
          CASE LEN(TRIM(mfield04))<>0
               IF mfield04<>cust_n.or.trans_c<>'S'
                  SKIP
                  LOOP
               ENDIF
          OTHERWISE
               IF trans_c<>'S'
                  SKIP
                  LOOP
               ENDIF
       ENDCASE
       IF missue_d<>issue_d
          missue_d= issue_d
       *   @ row, 2 SAY issue_d PICTURE '@!'
       ENDIF
       *@ row, 11 SAY trans_n PICTURE '@!'
       SELECT 2
       SEEK  stkrec->trans_n
       *IF .not. EOF()
       *    @ row, 22 SAY cust_n PICTURE '@!'
       *    @ row, 55 SAY dcount1 PICTURE '##'
       *    @ row, 58 SAY dcount2 PICTURE '##'
       *    @ row, 61 SAY dcount3 PICTURE '##'
       *ENDIF
       SELECT 1
       t_amt= t_prys
       t_amt= t_amt-t_amt* sifyl->dcount1/100
       t_amt= t_amt-t_amt* sifyl->dcount2/100
       t_amt= t_amt-t_amt* sifyl->dcount3/100
       *@ row, 33 SAY issue_q PICTURE '###,###'
       *@ row, 41 SAY issue_u PICTURE '@!'
       *@ row, 46 SAY issue_p PICTURE '#,###.##'
       *@ row, 64 SAY t_amt PICTURE '#,###,###.##'
       stl1= stl1+issue_q
       gtl1= gtl1+issue_q
       stl2= stl2+t_amt
       gtl2= gtl2+t_amt
       *row= row+1
       SKIP
    ENDDO
    @ 11, 10 say '                          '
    set colo to +g
    @ 12, 10 SAY 'Total Quantity Sold:'
    @ 14, 10 SAY 'Total Sales Amount :'
    set colo to +bg
    @ 12, 32 SAY gtl1 PICTURE '##,###,###'
    @ 14, 31 SAY gtl2 PICTURE '###,###,###.##'
    choice= ' '
    &C_CLEAR
    @ 21, 0
    &C_MESSAGE
    @ 21, 24 SAY ' Return to Previous Menu (y/n). ' GET confirm PICTURE 'Y' valid confirm$"YyNn"
    READ
    IF confirm='N'
        &C_CLEAR
        @ 9, 1 CLEAR TO 19, 78
        @ 21, 0
        @ 6, 15 SAY SPACE(10)
        row= 9
        LOOP
    ELSE
        set cent off
        CLOSE DATA
        RETURN
    ENDIF
ENDDO
 
CLOSE DATA
set cent off
RETURN

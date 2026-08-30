* program.....: SiFylp.prg

SELECT 3
USE ADFYL INDEX AD_N
SELECT 2
USE CUSTFYL INDEX CUST_N
SELECT 1
USE SIFYL INDEX SI_N, SI_D, SI_CD, SI_DINV
choice= 'S'
DO WHILE choice$'SDA'
    DO BRDR1
    &C_BODY
    @ 4, 4 SAY 'Invoice No.    :'
    @ 5, 4 SAY 'Customer Code  :'
    @ 4, 34 SAY 'Customer  :'
    @ 5, 34 SAY 'Address   :'
    @ 6, 34 SAY 'City      :'
    @ 7, 34 SAY 'Area Code :'
    @ 8, 4 SAY 'Address  Code  :'
    @ 8, 34 SAY 'Company   :'
    @ 9, 34 SAY 'Address   :'
    @ 10, 34 SAY 'City      :'
    @ 11, 4 SAY 'Territory code :'
    @ 12, 4 SAY 'Type / Terms   :           /    days'
    @ 13, 4 SAY 'Status         :'
    @ 14, 4 SAY 'Invoice Date   :'
    @ 15, 4 SAY 'Invoice Cost   :'
    @ 16, 4 SAY 'Invoice Amount :'
    @ 17, 4 SAY 'Discount       :   ,  ,   %'
    @ 18, 4 SAY 'Net Amount     :'
    @ 19, 4 SAY 'Remarks        :'
    @ 14, 50 SAY 'Date Posted :'
    @ 15, 50 SAY 'Adjustments :'
    @ 16, 50 SAY 'Payments    :'
    @ 18, 50 SAY 'Balance     :'
    mfield01= SPACE(10)
    choice= 'F'
    action= 'GET'
    new= .T.
    DO WHILE choice$'FEVNTB'
        IF action='GET'
            key= mfield01
            &C_GET
            @ 4, 21 GET key PICTURE '@!'
            READ
            IF LEN(TRIM(key))=0
                RETURN
            ENDIF
            IF choice='F'.or.key<>mfield01
                DO MODE
                mfield01= key
            ENDIF
        ENDIF
        &C_GET
        IF action='SAY'
            mfield01= inv_n
            mfield02= cust_n
            mfield03= cust_m
            mfield04= cust_ad
            mfield05= cust_ct
            mfield06= cust_ac
            mfield07= ad_n
            mfield08= co_m
            mfield09= co_ad
            mfield10= co_ct
            mfield11= cust_s
            mfield12= cust_tp
            mfield13= cust_t
            mfield14= status
            mfield15= inv_d
            mfield16= inv_c
            mfield17= inv_a
            mfield18= dcount1
            mfield19= dcount2
            mfield20= dcount3
            mfield21= net_a
            mfield22= si_rem
            mfield23= post_d
            mfield24= inv_adj
            mfield25= inv_pay
            mfield26= inv_bal
            mfield27= post_m
        ENDIF
        IF choice='F'
            choice= 'E'
            mfield01= key
            mfield02= SPACE(10)
            mfield03= SPACE(30)
            mfield04= SPACE(30)
            mfield05= SPACE(30)
            mfield06= SPACE(10)
            mfield07= SPACE(10)
            mfield08= SPACE(30)
            mfield09= SPACE(30)
            mfield10= SPACE(30)
            mfield11= SPACE(10)
            mfield12= SPACE(10)
            mfield13= 0
            mfield14= SPACE(1)
            mfield15= DATE()
            mfield16= 0
            mfield17= 0
            mfield18= 0
            mfield19= 0
            mfield20= 0
            mfield21= 0
            mfield22= SPACE(20)
            mfield23= DATE()
            mfield24= 0
            mfield25= 0
            mfield26= 0
            mfield27= muser
        ENDIF
        @ 4, 21 SAY mfield01 PICTURE '@!'
        DO WHILE .T.
            @ 05,21 &ACTION mFIELD02 PICT '@!'
            IF action='GET'
                READ
                IF READKEY()=4.or.READKEY()=261
                    EXIT
                ENDIF
                subkey= mfield02
                SELECT 2
                DO VALID2
                IF EOF()
                    IF confirm='N'
                        LOOP
                    ELSE
                        @ 04,46 &ACTION mFIELD03 PICT '@!'
                        @ 05,46 &ACTION mFIELD04 PICT '@!'
                        @ 06,46 &ACTION mFIELD05 PICT '@!'
                        @ 07,46 &ACTION mFIELD06 PICT '@!'
                        READ
                    ENDIF
                ELSE
                    mfield02= cust_n
                    mfield03= cust_m
                    mfield04= cust_ad
                    mfield05= cust_ct
                    mfield06= cust_ac
                    mfield11= cust_s
                    mfield12= cust_tp
                    mfield13= cust_t
                    @ 5, 21 SAY mfield02 PICTURE '@!'
                    @ 4, 46 SAY mfield03 PICTURE '@!'
                    @ 5, 46 SAY mfield04 PICTURE '@!'
                    @ 6, 46 SAY mfield05 PICTURE '@!'
                    @ 7, 46 SAY mfield06 PICTURE '@!'
                    @ 11, 21 SAY mfield11 PICTURE '@!'
                    @ 12, 21 SAY mfield12 PICTURE '@!'
                    @ 12, 32 SAY mfield13 PICTURE '@Z ###'
                ENDIF
                SELECT 1
            ENDIF
            DO WHILE .T.
                @ 08,21 &ACTION mFIELD07 PICT '@!'
                IF action='GET'
                    READ
                    IF READKEY()=4.or.READKEY()=261
                        EXIT
                    ENDIF
                    subkey= mfield07
                    IF LEN(TRIM(subkey))<>0
                        SELECT 3
                        DO VALID2
                        IF EOF()
                            IF confirm='N'
                                LOOP
                            ELSE
                                @ 08,46 &ACTION mFIELD08 PICT '@!'
                                @ 09,46 &ACTION mFIELD09 PICT '@!'
                                @ 10,46 &ACTION mFIELD10 PICT '@!'
                                READ
                            ENDIF
                        ELSE
                            mfield07= ad_n
                            mfield08= co_m
                            mfield09= co_ad
                            mfield10= co_ct
                            IF READKEY()=5.or.READKEY()=261
                                LOOP
                            ENDIF
                        ENDIF
                    ELSE
                        mfield07= SPACE(10)
                        mfield08= SPACE(30)
                        mfield09= SPACE(30)
                        mfield10= SPACE(30)
                    ENDIF
                    SELECT 1
                ENDIF
                @ 5, 21 SAY mfield02 PICTURE '@!'
                @ 4, 46 SAY mfield03 PICTURE '@!'
                @ 5, 46 SAY mfield04 PICTURE '@!'
                @ 6, 46 SAY mfield05 PICTURE '@!'
                @ 7, 46 SAY mfield06 PICTURE '@!'
                @ 8, 21 SAY mfield07 PICTURE '@!'
                @ 8, 46 SAY mfield08 PICTURE '@!'
                @ 9, 46 SAY mfield09 PICTURE '@!'
                @ 10, 46 SAY mfield10 PICTURE '@!'
                @ 11,21 &ACTION mFIELD11 PICT '@!'
                @ 12,21 &ACTION mFIELD12 PICT '@!'
                @ 12,32 &ACTION mFIELD13 PICT '@Z ###'
                DO CASE
                    CASE mfield14=' '
                        @ 13, 21 SAY 'For Invoicing'
                        mfield23= DATE()
                    CASE mfield14='I'
                        @ 13, 21 SAY 'For Posting  '
                        mfield23= DATE()
                    CASE mfield14='P'
                        @ 13, 21 SAY 'Posted       '
                    CASE mfield14='C'
                        @ 13, 21 SAY 'Cancelled    '
                ENDCASE
                @ 14,21 &ACTION mFIELD15
                @ 15,21 &ACTION mFIELD16 PICT '@Z #,###,###.##'
                @ 16,21 &ACTION mFIELD17 PICT '#,###,###.##'
                @ 17,21 &ACTION mFIELD18 PICT '@Z ##'
                @ 17,24 &ACTION mFIELD19 PICT '@Z ##'
                @ 17,27 &ACTION mFIELD20 PICT '@Z ##'
                @ 19,21 &ACTION mFIELD22 PICT '@!'
                @ 14,64 &ACTION mFIELD23
                @ 15, 64 SAY mfield24 PICTURE '#,###,###.##'
                @ 16, 64 SAY mfield25 PICTURE '#,###,###.##'
                @ 1, 69 SAY mfield27 PICTURE '@!'
                IF action='GET'
                    READ
                    IF READKEY()=4.or.READKEY()=261
                        LOOP
                    ENDIF
                ENDIF
                EXIT
            ENDDO
            IF READKEY()=4.or.READKEY()=261
                LOOP
            ENDIF
            EXIT
        ENDDO
        IF READKEY()=4.or.READKEY()=261
            LOOP
        ENDIF
        mfield21= mfield17
        mfield21= mfield21-(mfield21*mfield18/100)
        mfield21= mfield21-(mfield21*mfield19/100)
        mfield21= mfield21-(mfield21*mfield20/100)
        mfield26= mfield21-mfield24-mfield25
        @ 18, 21 SAY mfield21 PICTURE '#,###,###.##'
        @ 18, 64 SAY mfield26 PICTURE '#,###,###.##'
        DO OPTION1
    ENDDO
    DO CASE
        CASE choice='S'
            mfield14= 'P'
            SELECT 1
            IF new
                APPEND BLANK
            ENDIF
            REPLACE inv_n WITH mfield01, cust_n WITH mfield02, cust_m WITH mfield03, cust_ad WITH mfield04, cust_ct WITH mfield05, cust_ac WITH mfield06
            REPLACE ad_n WITH mfield07, co_m WITH mfield08, co_ad WITH mfield09, co_ct WITH mfield10
            REPLACE cust_s WITH mfield11, cust_tp WITH mfield12, cust_t WITH mfield13, status WITH mfield14
            REPLACE inv_d WITH mfield15, inv_c WITH mfield16, inv_a WITH mfield17, dcount1 WITH mfield18, dcount2 WITH mfield19, dcount3 WITH mfield20, net_a WITH mfield21, si_rem WITH mfield22
            REPLACE post_d WITH mfield23, inv_adj WITH mfield24, inv_pay WITH mfield25, inv_bal WITH mfield26, post_m WITH muser
            IF inv_bal=0
                REPLACE paid WITH 'T'
            ELSE
                REPLACE paid WITH 'F'
            ENDIF
            UNLOCK
            FLUSH
    ENDCASE
ENDDO
 

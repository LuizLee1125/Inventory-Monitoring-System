* program.....: AdFyl.prg

USE ADFYL INDEX AD_N
choice= 'S'
DO WHILE choice$'SDA'
    DO BRDR1
    &C_BODY
    @ 7, 15 SAY 'Address Code   :'
    @ 9, 15 SAY 'Company        :'
    @ 10, 15 SAY 'Address        :'
    @ 11, 15 SAY 'City           :'
    @ 12, 15 SAY 'Area Code      :'
    @ 13, 15 SAY 'Tel. No.       :'
    @ 14, 15 SAY 'Contact Person :'
    mfield01= SPACE(10)
    choice= 'F'
    action= 'GET'
    new= .T.
    DO WHILE choice$'FEVNTB'
        IF action='GET'
            key= mfield01
            &C_GET
            @ 7, 32 GET key PICTURE '@!'
            READ
            IF LEN(TRIM(key))=0
                close data
                RETURN
            ENDIF
            IF choice='F'.or.key<>mfield01
                DO MODE
                mfield01= key
            ENDIF
        ENDIF
        &C_GET
        IF action='SAY'
            mfield01= ad_n
            mfield02= co_m
            mfield03= co_ad
            mfield04= co_ct
            mfield05= co_ac
            mfield06= co_p
            mfield07= co_cp
            mfield08= user_m
        ENDIF
        IF choice='F'
            choice= 'E'
            mfield01= key
            mfield02= SPACE(30)
            mfield03= SPACE(30)
            mfield04= SPACE(30)
            mfield05= SPACE(10)
            mfield06= SPACE(20)
            mfield07= SPACE(10)
            mfield08= muser
        ENDIF
        @ 7, 32 SAY mfield01 PICTURE '@!'
        @ 09,32 &ACTION mFIELD02 PICT '@!'
        @ 10,32 &ACTION mFIELD03 PICT '@!'
        @ 11,32 &ACTION mFIELD04 PICT '@!'
        @ 12,32 &ACTION mFIELD05 PICT '@!'
        @ 13,32 &ACTION mFIELD06 PICT '@!'
        @ 14,32 &ACTION mFIELD07 PICT '@!'
        @ 1, 69 SAY mfield08 PICTURE '@!'
        IF action='GET'
            READ
            IF READKEY()=4.or.READKEY()=260
                LOOP
            ENDIF
        ENDIF
        DO OPTION1
    ENDDO
    IF choice='S'.and.action='GET'
        IF new
            APPEND BLANK
        ENDIF
        REPLACE ad_n WITH mfield01, co_m WITH mfield02, co_ad WITH mfield03, co_ct WITH mfield04, co_ac WITH mfield05, co_p WITH mfield06, co_cp WITH mfield07, user_m WITH muser
        UNLOCK
    ENDIF
ENDDO
 

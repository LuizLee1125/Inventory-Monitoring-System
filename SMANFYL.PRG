
USE SMANFYL INDEX SMAN_N
choice= 'S'
DO WHILE choice$'SDA'
    DO BRDR1
    &C_BODY
    @ 6, 8 SAY "Salesman's Code :"
    @ 8, 8 SAY "Salesman's Name :"
    @ 10, 8 SAY 'Address         :'
    @ 12, 8 SAY 'City            :'
    @ 14, 8 SAY 'Zip Code        :'
    @ 16, 8 SAY 'Telephone No.   :'
    mfield01= SPACE(10)
    choice= 'F'
    action= 'GET'
    new= .T.
    DO WHILE choice$'FEVNTB'
        IF action='GET'
            key= mfield01
            &C_GET
            @ 6, 26 GET key PICTURE '@!'
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
            mfield01= sman_n
            mfield02= sman_m
            mfield03= sman_ad
            mfield04= sman_ct
            mfield05= sman_z
            mfield06= sman_p
            mfield08= user_m
        ENDIF
        IF choice='F'
            choice= 'E'
            mfield01= key
            mfield02= SPACE(30)
            mfield03= SPACE(30)
            mfield04= SPACE(30)
            mfield05= SPACE(4)
            mfield06= SPACE(20)
            mfield08= muser
        ENDIF
        @ 6, 26 SAY mfield01 PICTURE '@!'
        @ 08,26 &ACTION mFIELD02 PICT '@!'
        @ 10,26 &ACTION mFIELD03 PICT '@!'
        @ 12,26 &ACTION mFIELD04 PICT '@!'
        @ 14,26 &ACTION mFIELD05 PICT '@!'
        @ 16,26 &ACTION mFIELD06 PICT '@!'
        @ 1, 69 SAY mfield08 PICTURE '@!'
        IF action='GET'
            READ
            IF READKEY()=4.or.READKEY()=261
                LOOP
            ENDIF
        ENDIF
        DO OPTION1
    ENDDO
    IF choice='S'.and.action='GET'
        IF new
            APPEND BLANK
        ENDIF
        REPLACE sman_n WITH mfield01, sman_m WITH mfield02, sman_ad WITH mfield03, sman_ct WITH mfield04, sman_z WITH mfield05, sman_p WITH mfield06, user_m WITH muser
        UNLOCK
        FLUSH
    ENDIF
ENDDO
 

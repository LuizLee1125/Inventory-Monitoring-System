* program.....: AcctFyl.prg

USE ACCTFYL INDEX ACCT_N
choice= 'S'
DO WHILE choice$'SDA'
    DO BRDR1
    &C_BODY
    @ 10, 8 SAY 'Account Code :'
    @ 12, 8 SAY 'Account Name :'
    mfield01= SPACE(10)
    choice= 'F'
    action= 'GET'
    new= .T.
    DO WHILE choice$'FEVNTB'
        IF action='GET'
            key= mfield01
            &C_GET
            @ 10, 23 GET key PICTURE '@!'
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
            mfield01= acct_n
            mfield02= acct_m
            mfield03= user_m
        ENDIF
        IF choice='F'
            choice= 'E'
            mfield01= key
            mfield02= SPACE(30)
            mfield03= muser
        ENDIF
        @ 10, 23 SAY mfield01 PICTURE '@!'
        @ 12,23 &ACTION mFIELD02 PICT '@!'
        @ 1, 69 SAY mfield03 PICTURE '@!'
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
        REPLACE acct_n WITH mfield01, acct_m WITH mfield02, user_m WITH muser
        UNLOCK
        FLUSH
    ENDIF
ENDDO
 

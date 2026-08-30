* program.....: passfyl.prg

USE PASSFYL INDEX ACCESS_C
choice= 'S'

DO WHILE choice$'SDA'
    DO BRDR1
    &C_BODY
    @ 6, 5 SAY 'Access Code      :'
    @ 8, 5 SAY "User's Name      :"
    @ 10, 5 SAY "User's Password  :"
    @ 5, 40 TO 19, 76
    &C_OPTION
    @ 7, 46 SAY ' A C C E S S   M E N U '
    &C_BODY
    @  9, 43 SAY 'A]  Sales Order'
    @ 10, 43 SAY 'B]  Sales Monitoring'
    @ 11, 43 SAY 'C]  Invoicing System'
    @ 12, 43 SAY 'D]  Inventory Monitoring'
    @ 13, 43 SAY 'E]  Inventory System'
    @ 14, 43 SAY 'F]  Expense Monitoring'
    @ 15, 43 SAY 'G]  Accounts Receivable'
    @ 16, 43 SAY 'H]  Main Menu'
    @ 17, 43 say 'I]  Invoicing/AR'
    @ 18, 43 say 'J]  Inventory System 2'
    mfield01= SPACE(1)
    mfield02= SPACE(10)
    key2= mfield01+mfield02
    choice= 'F'
    action= 'GET'
    new= .T.
    DO WHILE choice$'FEVNTB'
        IF action='GET'
            DO WHILE .T.
                &C_GET
                @ 6, 24 GET mfield01 PICTURE '@!'
                READ
                IF LEN(TRIM(mfield01))=0
                    RETURN
                ENDIF
                IF .not. mfield01$'ABCDEFGHIJ'
                    LOOP
                ELSE
                    @ 8, 24 GET mfield02 PICTURE '@!'
                    READ
                    IF READKEY()=4.or.READKEY()=260
                        LOOP
                    ENDIF
                    EXIT
                ENDIF
            ENDDO
            key= mfield01+mfield02
            IF choice='F'.or.key<>key2
                DO MODE
                key2= key
            ENDIF
        ENDIF
        &C_GET
        IF action='SAY'
            mfield01= access_c
            mfield02= user_m
            mfield03= password
            mfield04= accesmnu
        ENDIF
        IF choice='F'
            choice= 'E'
            mfield03= SPACE(10)
        ENDIF
        @ 6, 24 SAY mfield01 PICTURE '@!'
        @ 8, 24 SAY mfield02 PICTURE '@!'
        @ 10,24 &ACTION mFIELD03 PICT '@!'
        IF action='GET'
            READ
            IF READKEY()=4.or.READKEY()=260
                LOOP
            ENDIF
        ENDIF
        DO OPTION1
    ENDDO
    IF choice='S'.and.action='GET'
        DO CASE
            CASE mfield01='A'
                mfield04= 'MNUSO'
            CASE mfield01='B'
                mfield04= 'MNUSIM'
            CASE mfield01='C'
                mfield04= 'MNUNVCS'
            CASE mfield01='D'
                mfield04= 'MNUINVM'
            CASE mfield01='E'
                mfield04= 'MNUINVS'
            CASE mfield01='F'
                mfield04= 'MNUXPENS'
            CASE mfield01='G'
                mfield04= 'MNUAR'
            CASE mfield01='H'
                mfield04= 'MNUMAIN'
            case mfield01='I'
                mfield04= 'MNUSO2'
            case mfield01='J'
                mfield04= 'MNUINV2'
        ENDCASE
        IF new
            APPEND BLANK
        ENDIF
        REPLACE access_c WITH mfield01, user_m WITH mfield02, password WITH mfield03, accesmnu WITH mfield04
    ENDIF
ENDDO
 

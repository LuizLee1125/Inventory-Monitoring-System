* program.....: DmFyl.prg

SELECT 4
   USE ACCTFYL INDEX ACCT_N
SELECT 3
   USE DMFYL INDEX DM_N, DM_D, DM_CD
SELECT 2
   USE DMREC INDEX DMREC
   COPY STRU TO &mTEMPFYL
SELECT 1
   USE &mTEMPFYL ALIA TEMP EXCL

mtrans_c= 'D'
choice= 'S'
DO WHILE choice$'SDA'
    DO BRDR1
    &C_BODY
    @ 4, 2 SAY 'Debit Memo #  :'
    @ 5, 2 SAY 'Customer Code :'
    @ 6, 2 SAY 'Address  Code :'
    @ 7, 2 SAY 'Salesman      :'
    @ 4, 52 SAY 'Date    :'
    @ 5, 52 SAY 'Remarks :'
    &C_HEAD
    @ 8, 1 SAY SPACE(78)
    @ 8, 5 SAY 'ACCT-CODE  REMARKS\EXPLANATION               AMOUNT'
    SELECT 3
    mfield01= SPACE(10)
    choice= 'F'
    action= 'GET'
    new= .T.
    DO WHILE choice$'FEVNTB'
        &C_GET
        IF action='GET'
            key= mfield01
            @ 4, 18 GET key PICTURE '@!'
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
        IF action='SAY'
            mfield01= inv_n
            mfield02= cust_n
            mfield03= cust_m
            mfield04= cust_ad
            mfield05= cust_ct
            mfield06= cust_z
            mfield07= ad_n
            mfield08= co_m
            mfield09= co_ad
            mfield10= co_ct
            mfield11= co_z
            mfield12= cust_s
            mfield13= inv_d
            mfield14= cust_ac
            mfield15= inv_a
            mfield16= dcount1
            mfield17= dcount2
            mfield18= dcount3
            mfield19= net_a
            mfield20= inv_adj
            mfield21= inv_pay
            mfield22= inv_bal
            mfield23= dm_rem
            mfield24= user_m
        ENDIF
        IF choice='F'
            choice= 'E'
            mfield01= key
            mfield02= SPACE(10)
            mfield03= SPACE(30)
            mfield04= SPACE(30)
            mfield05= SPACE(30)
            mfield06= SPACE(4)
            mfield07= SPACE(10)
            mfield08= SPACE(30)
            mfield09= SPACE(30)
            mfield10= SPACE(30)
            mfield11= SPACE(4)
            mfield12= SPACE(10)
            mfield13= DATE()
            mfield14= SPACE(10)
            mfield15= 0.00
            mfield16= 0
            mfield17= 0
            mfield18= 0
            mfield19= 0.00
            mfield20= 0.00
            mfield21= 0.00
            mfield22= 0.00
            mfield23= SPACE(20)
            mfield24= muser
        ENDIF
        &C_GET
        @ 4, 18 SAY mfield01 PICTURE '@!'
        DO WHILE .T.
            @ 05,18 &ACTION mFIELD02 PICT '@!'
            IF action='GET'
                READ
                IF READKEY()=4.or.READKEY()=261
                    EXIT
                ENDIF
                subkey= mfield02
                SELECT 5
                USE CUSTFYL INDEX CUST_N
                DO VALID2
                IF EOF()
                    IF confirm='N'
                        LOOP
                    ELSE
                        &C_GET
                        @ 4, 29 GET mfield03 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                        @ 5, 29 GET mfield04 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                        @ 6, 29 GET mfield05 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                        READ
                    ENDIF
                ELSE
                    mfield02= cust_n
                    mfield03= cust_m
                    mfield04= cust_ad
                    mfield05= cust_ct
                    mfield12= cust_s
                    mfield14= cust_ac
                    @ 5, 18 SAY mfield02 PICTURE '@!'
                    @ 4, 29 SAY mfield03 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                    @ 5, 29 SAY mfield04 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                    @ 6, 29 SAY mfield05 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                    @ 7, 18 SAY mfield12 PICTURE '@!'
                ENDIF
                USE
                SELECT 3
            ENDIF
            DO WHILE .T.
                @ 06,18 &ACTION mFIELD07 PICT '@!'
                IF action='GET'
                    READ
                    IF READKEY()=4.or.READKEY()=261
                        EXIT
                    ENDIF
                    subkey= mfield07
                    IF LEN(TRIM(subkey))<>0
                        SELECT 5
                        USE ADFYL INDEX AD_N
                        DO VALID2
                        IF EOF()
                            IF confirm='N'
                                LOOP
                            ELSE
                                @ 4, 29 GET mfield08 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                                @ 5, 29 GET mfield09 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                                @ 6, 29 GET mfield10 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                                READ
                            ENDIF
                        ELSE
                            mfield07= ad_n
                            mfield08= co_m
                            mfield09= co_ad
                            mfield10= co_ct
                            @ 6, 18 SAY mfield07 PICTURE '@!'
                            @ 4, 29 SAY mfield08 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                            @ 5, 29 SAY mfield09 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                            @ 6, 29 SAY mfield10 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                            IF READKEY()=4.or.READKEY()=261
                                LOOP
                            ENDIF
                        ENDIF
                        USE
                        SELECT 3
                    ENDIF
                ELSE
                    @ 5, 18 SAY mfield02 PICTURE '@!'
                    @ 4, 29 SAY mfield03 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                    @ 5, 29 SAY mfield04 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                    @ 6, 29 SAY mfield05 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                    IF mfield07<>SPACE(10)
                        @ 6, 18 SAY mfield07 PICTURE '@!'
                        @ 4, 29 SAY mfield08 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                        @ 5, 29 SAY mfield09 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                        @ 6, 29 SAY mfield10 PICTURE '@S20 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                    ENDIF
                ENDIF
                @ 07,18 &ACTION mFIELD12 PICT '@!'
                @ 04,62 &ACTION mFIELD13
                @ 05,62 &ACTION mFIELD23 PICT '@S17'
                @ 1, 69 SAY mfield24 PICTURE '@!'
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
        lkey=  dmfyl->inv_n
        IF action='SAY'
            IF choice$'VNTB'
                &C_CLEAR
                @ 9, 1 CLEAR TO 19, 78
            ENDIF
            &C_CLEAR
            @ 22, 0
            &C_MESSAGE
            @ 23, 50 SAY ' Please wait... '
            SELECT 1
            ZAP
            SELECT 2
            SEEK lkey
            DO WHILE  dmrec->dm_n=lkey
                SELECT 1
                APPEND BLANK
                REPLACE dm_n WITH  dmrec->dm_n, acct_n WITH  dmrec->acct_n, remarks WITH  dmrec->remarks, item_t WITH  dmrec->item_t, user_m WITH  dmrec->user_m
                SELECT 2
                SKIP
            ENDDO
            &C_CLEAR
            @ 23, 0
            SELECT 1
            GOTO TOP
            pg= 0
        ENDIF
        DO WHILE .T.
            SELECT 1
            IF action='GET'.and.RECCOUNT()>0
                pg= INT((RECNO()-2)/10)
                IF RECNO()>pg*10
                    GOTO pg*10+1
                ENDIF
            ENDIF
            row= 9
            DO WHILE row<19
                IF EOF()
                    mitem_n= SPACE(10)
                    mitem_m= SPACE(30)
                    mitem_t= 0
                    muser_m= muser
                ELSE
                    mitem_n= acct_n
                    mitem_m= remarks
                    mitem_t= item_t
                    muser_m= user_m
                ENDIF
                &C_GET
                @ row, 1 SAY RECNO() PICTURE '###'
                DO WHILE .T.
                    @ ROW,05 &ACTION mITEM_N PICT '@!'
                    IF action='GET'
                        READ
                        subkey= mitem_n
                        &C_CLEAR
                        @ 19, 1 SAY SPACE(78)
                        @ 22, 0
                        @ 23, 0
                        &C_GET
                        DO CASE
                            CASE READKEY()>3.and.READKEY()<8
                                DO KEYS
                                IF error
                                    error= .F.
                                    LOOP
                                ELSE
                                    EXIT
                                ENDIF
                            CASE LEN(TRIM(subkey))=0
                                EXIT
                            CASE 'REMOVE'$subkey
                                mitem_n= 'REMOVE    '
                                &C_CLEAR
                                @ row, 5 CLEAR TO row, 78
                                &C_GET
                                EXIT
                            CASE READKEY()=12
                                EXIT
                        ENDCASE
                        SELECT 4
                        DO VALID2
                        IF EOF()
                            IF confirm='N'
                                SELECT 1
                                LOOP
                            ENDIF
                        ELSE
                            mitem_n= acct_n
                            &C_HEAD
                            @ 19, 1 SAY SPACE(78)
                            @ 19, 5 SAY 'ACCOUNT NAME :'
                            @ 19, 20 SAY acct_m
                        ENDIF
                        SELECT 1
                    ENDIF
                    EXIT
                ENDDO
                DO CASE
                    CASE READKEY()=4.or.READKEY()=5
                        LOOP
                    CASE page
                        page= .F.
                        LOOP
                    CASE LEN(TRIM(mitem_n))=0.and.EOF()
                        IF READKEY()=7
                            action= 'GET'
                            LOOP
                        ENDIF
                    CASE READKEY()=12
                        EXIT
                ENDCASE
                &C_GET
                @ row, 5 SAY mitem_n PICTURE '@!'
                IF mitem_n<>'REMOVE'
                    @ ROW,16 &ACTION mITEM_M PICT '@!'
                    IF LEN(TRIM(mitem_n))<>0
                        @ ROW,47 &ACTION mITEM_T PICT '##,###.##'
                    ENDIF
                    IF action='GET'
                        READ
                    ENDIF
                    IF LEN(TRIM(mitem_n))=0.and.LEN(TRIM(mitem_m))=0.and.EOF()
                        &C_CLEAR
                        @ row, 1 SAY SPACE(78)
                        GOTO TOP
                        EXIT
                    ENDIF
                    &C_GET
                ENDIF
                IF action='GET'
                    IF EOF()
                        APPEND BLANK
                    ENDIF
                    REPLACE dm_n WITH mfield01, acct_n WITH mitem_n, remarks WITH mitem_m, item_t WITH mitem_t, user_m WITH muser_m
                ENDIF
                SKIP
                row= row+1
                IF row=19.and.action='GET'
                    pg= pg+1
                    row= 9
                    &C_CLEAR
                    @ 9, 1 CLEAR TO 19, 78
                ENDIF
                IF row=19.and.(READKEY()=6.or.READKEY()=7)
                    action= 'GET'
                    row= row-1
                    SKIP  -1
                    LOOP
                ENDIF
            ENDDO
            IF action='GET'
                SUM FOR acct_n<>'REMOVE' item_t TO mfield15
            ENDIF
            &C_HEAD
            @ 19, 1 SAY SPACE(78)
            @ 19, 27 SAY 'TOTAL DEBIT MEMO'
            @ 19, 44 SAY mfield15 PICTURE '#,###,###.##'
            SELECT 3
            DO OPTION1
            IF choice='P'
                DO WHILE choice='P'
                    &C_MESSAGE
                    @ 23, 50 SAY ' ...Printing '
                    SET CONSOLE OFF
                    SET DEVICE TO PRINTER
                    SET PRINTER ON
                    ?? CHR(27)+'M'
                    SELECT 1
                    LOCATE FOR acct_n<>'REMOVE'
                    SELECT 4
                    SEEK TRIM(acct_n)
                    SELECT 1
                    row_p= 21
                    @ 8, 54 SAY mfield01 PICTURE '@!'
                    @ 11, 5 SAY mfield03 PICTURE '@!'
                    @ 12, 5 SAY mfield04 PICTURE '@!'
                    @ 13, 5 SAY TRIM(mfield05)+'  '+TRIM(mfield06)
                    @ 14, 48 SAY mfield13
                    @ 18, 8 SAY  acctfyl->acct_m PICTURE '@!'
                    DO WHILE .not. EOF()
                        @ row_p, 5 SAY remarks PICTURE '@!'
                        @ row_p, 48 SAY item_t PICTURE '@Z ###,###,###.##'
                        row_p= row_p+1
                        CONTINUE
                    ENDDO
                    @ 44, 48 SAY mfield15 PICTURE '###,###,###.##'
                    ?? CHR(27)+'P'
                    EJECT
                    SET DEVICE TO SCREEN
                    SET PRINTER OFF
                    SET CONSOLE ON
                    &C_CLEAR
                    @ 23, 0
                    SELECT 1
                    SET ORDER TO 0
                    SELECT 3
                    DO OPTION4
                ENDDO
            ENDIF
            IF READKEY()=6.or.READKEY()=7
                SELECT 1
                DO PAGEKEY
                &C_CLEAR
                @ 21, 0
                &C_MESSAGE
                @ 21, 24 SAY ' NOTE: Please type your data. '
                LOOP
            ENDIF
            EXIT
        ENDDO
    ENDDO
    DO CASE
        CASE choice='D'.and..not. new
            SELECT 2
            SEEK  dmfyl->inv_n
            DO WHILE  dmfyl->inv_n= dmrec->dm_n
                SELECT 2
                DELETE
                SKIP
            ENDDO
            FLUSH
        CASE choice='S'.or.choice='M'
            SELECT 1
            GOTO TOP
            IF new
                USE
                SELECT 2
                APPE FROM &mTEMPFYL FOR ACCT_N <> "REMOVE"
                UNLOCK
                SELECT 1
                USE &mTEMPFYL ALIA TEMP EXCL
            ELSE
                SELECT 2
                SEEK  temp->dm_n
                DO WHILE .not. EOF()
                    SELECT 2
                    IF EOF().or.dm_n<> temp->dm_n
                        APPEND BLANK
                    ENDIF
                    IF  temp->acct_n='REMOVE'
                        DELETE
                    ELSE
                        REPLACE dm_n WITH mfield01, dm_n WITH  temp->dm_n, acct_n WITH  temp->acct_n, remarks WITH  temp->remarks, item_t WITH  temp->item_t, user_m WITH muser
                        UNLOCK
                    ENDIF
                    IF mfield01= dmfyl->inv_n
                        SKIP
                    ELSE
                        SEEK  dmfyl->inv_n
                    ENDIF
                    SELECT 1
                    SKIP
                ENDDO
            ENDIF
            mfield19= mfield15
            mfield22= mfield19-mfield20-mfield21
            SELECT 3
            IF new
                APPEND BLANK
            ENDIF
            REPLACE inv_n WITH mfield01, cust_n WITH mfield02, cust_m WITH mfield03, cust_ad WITH mfield04, cust_ct WITH mfield05, cust_z WITH mfield06
            REPLACE ad_n WITH mfield07, co_m WITH mfield08, co_ad WITH mfield09, co_ct WITH mfield10, co_z WITH mfield11
            REPLACE cust_s WITH mfield12, inv_d WITH mfield13, cust_ac WITH mfield14
            REPLACE inv_a WITH mfield15, dcount1 WITH mfield16, dcount2 WITH mfield17, dcount3 WITH mfield18, net_a WITH mfield19, inv_adj WITH mfield20, inv_pay WITH mfield21, inv_bal WITH mfield22
            REPLACE dm_rem WITH mfield23, user_m WITH muser
            IF status=' '
                REPLACE status WITH 'P'
            ENDIF
            IF mfield22=0
                REPLACE paid WITH 'T'
            ELSE
                REPLACE paid WITH 'F'
            ENDIF
            SELECT 5
            USE CUSTFYL INDEX CUST_N
            SEEK mfield02
            IF .not. EOF()
                REPLACE cust_lt WITH mfield13
            ENDIF
            USE
            UNLOCK
            FLUSH
    ENDCASE
    SELECT 1
    ZAP
ENDDO
 
close data
return

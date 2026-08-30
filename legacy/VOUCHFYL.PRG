
SELECT 4
USE ACCTFYL INDEX ACCT_N
SELECT 3
USE VOUCHFYL INDEX VOUCH_N
SELECT 2
USE VOUCHREC INDEX VOUCHREC
COPY STRU TO &mTEMPFYL
SELECT 1
USE &mTEMPFYL ALIA TEMP EXCL
mtrans_c= 'S'
choice= 'S'
DO WHILE choice$'SDA'
    DO BRDR1
    &C_BODY
    @ 4, 2 SAY 'Voucher No.  .:'
    @ 5, 2 SAY 'Name          :'
    @ 6, 2 SAY 'Remarks       :'
    @ 4, 52 SAY 'Date       :'
    &C_HEAD
    @ 8, 1 SAY SPACE(78)
    @ 8, 5 SAY 'ACCT-CODE  REMARKS\EXPLANATION                                    AMOUNT'
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
            mfield14= cust_tp
            mfield15= cust_t
            mfield16= of_n
            mfield17= dr_n
            mfield18= po_n
            mfield19= cust_pc
            mfield20= cust_ac
            mfield21= inv_a
            mfield22= dcount1
            mfield23= dcount2
            mfield24= dcount3
            mfield25= net_a
            mfield26= inv_adj
            mfield27= inv_pay
            mfield28= inv_bal
            mfield29= user_m
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
            mfield15= 30
            mfield16= SPACE(6)
            mfield17= SPACE(6)
            mfield18= SPACE(6)
            mfield19= 'A'
            mfield20= SPACE(10)
            mfield21= 0.00
            mfield22= 0
            mfield23= 0
            mfield24= 0
            mfield25= 0.00
            mfield26= 0.00
            mfield27= 0.00
            mfield28= 0.00
            mfield29= muser
        ENDIF
        &C_GET
        @ 4, 18 SAY mfield01 PICTURE '@!'
        DO WHILE .T.
            @ 05,18 &ACTION mFIELD03 PICT '@!'
            @ 06,18 &ACTION mFIELD04 PICT '@!'
            @ 04,65 &ACTION mFIELD13
            @ 1, 69 SAY mfield29 PICTURE '@!'
            IF action='GET'
                READ
                IF READKEY()=4.or.READKEY()=261
                    LOOP
                ENDIF
            ENDIF
            IF action='GET'
            ENDIF
            EXIT
        ENDDO
        IF READKEY()=4.or.READKEY()=261
            LOOP
        ENDIF
        lkey=  vouchfyl->inv_n
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
            DO WHILE  vouchrec->dm_n=lkey
                SELECT 1
                APPEND BLANK
                REPLACE dm_n WITH  vouchrec->dm_n, acct_n WITH  vouchrec->acct_n, remarks WITH  vouchrec->remarks, item_t WITH  vouchrec->item_t, user_m WITH  vouchrec->user_m
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
                    mitem_m= SPACE(50)
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
                            CASE LEN(TRIM(subkey))=0.and.EOF()
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
                            ELSE
                                @ row, 32 GET mitem_m PICTURE '@S30 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                                READ
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
                        &C_CLEAR
                        @ row, 1 SAY SPACE(78)
                        GOTO TOP
                        EXIT
                    CASE READKEY()=12
                        EXIT
                ENDCASE
                &C_GET
                @ row, 5 SAY mitem_n PICTURE '@!'
                IF mitem_n<>'REMOVE'
                    @ ROW,16 &ACTION mITEM_M PICT '@!'
                    @ ROW,68 &ACTION mITEM_T PICT '###,###.##'
                    IF action='GET'
                        READ
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
                SUM FOR acct_n<>'REMOVE' item_t TO mfield21
            ENDIF
            &C_HEAD
            @ 19, 1 SAY SPACE(78)
            @ 19, 27 SAY 'TOTAL AMOUNT'
            @ 19, 44 SAY mfield21 PICTURE '#,###,###.##'
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
                    SELECT 5
                    USE CUSTREC INDEX CUST_N
                    SEEK mfield02
                    mcust_rcn= cust_rcn
                    mcust_rcd= cust_rcd
                    mcust_rcp= cust_rcp
                    SELECT 1
                    INDE ON LEVEL_M+LEVEL_U TO &mTEMPFYL
                    LOCATE FOR item_n<>'REMOVE'
                    row_p= 23
                    @ 2, 84 SAY mfield01 PICTURE '@!'
                    @ 7, 70 SAY mfield02 PICTURE '@!'
                    @ 7, 84 SAY mfield13
                    @ 11, 5 SAY mfield03 PICTURE '@!'
                    @ 11, 57 SAY mfield08 PICTURE '@!'
                    @ 12, 5 SAY mfield04 PICTURE '@!'
                    @ 12, 57 SAY mfield09 PICTURE '@!'
                    @ 13, 5 SAY TRIM(mfield05)+'  '+TRIM(mfield06)
                    @ 13, 57 SAY TRIM(mfield10)+'  '+TRIM(mfield11)
                    IF mfield13<mcust_rcd+366
                        @ 19, 3 SAY mcust_rcn PICTURE '@!'
                        @ 19, 13 SAY mcust_rcd PICTURE '@!'
                        @ 19, 22 SAY mcust_rcp PICTURE '@!'
                    ELSE
                        @ 19, 3 SAY 'ON FILE'
                    ENDIF
                    @ 19, 33 SAY mfield16 PICTURE '@!'
                    @ 19, 59 SAY mfield18 PICTURE '@!'
                    @ 19, 70 SAY mfield12 PICTURE '@!'
                    IF mfield15<>0
                        mterms= TRIM(mfield14)+' '+STR(mfield15,3)+' days'
                    ELSE
                        mterms= TRIM(mfield14)
                    ENDIF
                    @ 19, 88-LEN(TRIM(mterms))/2 SAY mterms
                    ?? CHR(27)+'P'
                    DO WHILE .not. EOF()
                        @ row_p, 1 SAY item_q PICTURE '###,###'
                        @ row_p, 10 SAY item_u PICTURE '@!'
                        IF item_fg<>0
                            @ row_p, 18 SAY TRIM(item_m)+' +'+STR(item_fg,2)
                        ELSE
                            @ row_p, 18 SAY item_m PICTURE '@!'
                        ENDIF
                        row_p= row_p+1
                        CONTINUE
                    ENDDO
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
            SEEK  vouchfyl->inv_n
            DO WHILE  vouchfyl->inv_n= vouchrec->dm_n
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
                    IF  temp->dm_n='REMOVE'
                        DELETE
                    ELSE
                        REPLACE dm_n WITH mfield01, dm_n WITH  temp->dm_n, acct_n WITH  temp->acct_n, remarks WITH  temp->remarks, item_t WITH  temp->item_t, user_m WITH muser
                        UNLOCK
                    ENDIF
                    IF mfield01= vouchfyl->inv_n
                        SKIP
                    ELSE
                        SEEK  vouchfyl->inv_n
                    ENDIF
                    SELECT 1
                    SKIP
                ENDDO
            ENDIF
            SELECT 3
            IF new
                APPEND BLANK
            ENDIF
            REPLACE inv_n WITH mfield01, cust_n WITH mfield02, cust_m WITH mfield03, cust_ad WITH mfield04, cust_ct WITH mfield05, cust_z WITH mfield06
            REPLACE ad_n WITH mfield07, co_m WITH mfield08, co_ad WITH mfield09, co_ct WITH mfield10, co_z WITH mfield11
            REPLACE cust_s WITH mfield12, inv_d WITH mfield13, cust_tp WITH mfield14, cust_t WITH mfield15, of_n WITH mfield16, dr_n WITH mfield17, po_n WITH mfield18, cust_pc WITH mfield19, cust_ac WITH mfield20
            REPLACE inv_a WITH mfield21, dcount1 WITH mfield22, dcount2 WITH mfield23, dcount3 WITH mfield24, net_a WITH mfield25, inv_adj WITH mfield26, inv_pay WITH mfield27, inv_bal WITH mfield28, user_m WITH muser
            IF status=' '
                REPLACE status WITH 'I'
            ENDIF
            IF mfield28=0
                REPLACE paid WITH 'T'
            ELSE
                REPLACE paid WITH 'F'
            ENDIF
            UNLOCK
            FLUSH
    ENDCASE
    SELECT 1
    ZAP
ENDDO
 

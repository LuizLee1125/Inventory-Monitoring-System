* program.....: Password.prg

SELECT 1
USE PASSFYL INDEX ACCESS_C
&C_CLEAR
CLEAR
&C_BRDR
@ 0, 15 TO 3, 64 DOUBLE
&C_HEAD
@ 1, 16 SAY SPACE(48)
@ 1, 16 SAY SPACE((48-LEN(company))/2)+company
@ 2, 16 SAY '      C O M P U T E R I Z E   S Y S T E M       '
SET COLOR TO B/B
@ 9, 22 CLEAR TO 15, 58
SET COLOR TO +G/B
@ 9, 22 TO 15, 58
SET COLOR TO +W/B
@ 11, 26 SAY 'user name.....:'
@ 13, 26 SAY 'password......:'
SET COLOR TO +rb/+rb
@ 11, 43 CLEAR TO 11, 55
@ 13, 43 CLEAR TO 13, 55
SET COLOR TO n/b
@ 11, 56 SAY CHR(220)
@ 12, 44 SAY REPLICATE(CHR(223),13)
@ 13, 56 SAY CHR(220)
@ 14, 44 SAY REPLICATE(CHR(223),13)
try= 0
DO WHILE .T.
    muser= SPACE(10)
    mpassword= SPACE(10)
    SET COLOR TO ,+w/+rb
    @ 11, 44 GET muser PICTURE '@!'
    READ
    IF LEN(TRIM(muser))=0
        SET COLOR TO 
        QUIT
    ENDIF
    mpass= ''
    mcol= 44
    SET COLOR TO 
    @ 13, 44 SAY ''
    DO WHILE .T.
        i= INKEY(0)
        IF i=13
            EXIT
        ENDIF
        IF (i=127.or.i=19).and.LEN(mpass)<>0
            mpass= LEFT(mpass,LEN(mpass)-1)
            SET COLOR TO +rb/+rb
            @ 13, 43 CLEAR TO 13, 55
            SET COLOR TO +gr/+rb
            @ 13, 44 SAY REPLICATE('*',LEN(mpass))
            mcol= mcol-1
        ENDIF
        IF i<32.or.i>126
            LOOP
        ENDIF
        IF LEN(mpass)>=10
            LOOP
        ENDIF
        mpass= mpass+UPPER(CHR(i))
        SET COLOR TO +gr/+rb
        @ 13, mcol SAY '*'
        mcol= mcol+1
    ENDDO
    mpassword= TRIM(mpass)
    SET EXAC ON
    LOCATE FOR user_m=muser.and.password=mpassword
    SET EXAC OFF
    IF EOF()
        IF try=3
            SET COLOR TO 
            QUIT
        ENDIF
        &C_CLEAR
        @ 21, 0
        @ 22, 0
        confirm= ' '
        SET COLOR TO +*w/r
        @ 21, 23 SAY ' Uh-uh! You must be getting old!!! '
        SET COLOR TO +bg
        @ 22, 23 SAY '    Press any key to continue...   '
        keypress= INKEY(0)
        SET COLOR TO 
        @ 21, 23 CLEAR TO 24, 79
        SET COLOR TO +rb/+rb
        @ 11, 43 CLEAR TO 11, 55
        @ 13, 43 CLEAR TO 13, 55
    ELSE
        maccesmnu= accesmnu
        SELECT 1
        CLOSE DATABASE
        RETURN
    ENDIF
    try= try+1
ENDDO
 

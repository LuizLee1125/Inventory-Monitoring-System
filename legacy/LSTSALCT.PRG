* program.....: LstsAlcT.prg

DO BRDR2
@ 8, 2 SAY '                     Tran. Amount     Net Amount     Tran. Cost  Gross Profit'
@ 1, 1 SAY 'B] Sales Per Customer - Totals only '

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
   @ 5, 52 SAY 'Customer Code :'
   SET CENTURY ON
   MINV_D= CTOD('01/01/2000')
   GOTO BOTTOM
   MFIELD2= DATE()
   GOTO TOP
   MFIELD1= CTOD('  /  /  ')
   &C_GET
   @ 6, 26 SAY MFIELD2
   @ 5, 26 GET MFIELD1 PICTURE '@!'
   READ
   IF MFIELD1=CTOD('  /  /  ')
      CLOSE DATABASE
      SET CENTURY OFF
      RETURN
   ELSE
      SEEK MFIELD1
      IF EOF()
         GOTO TOP
         IF MFIELD1>INV_D
            GOTO BOTTOM
            IF MFIELD1<INV_D
               SKIP
               DO WHILE EOF()
                  MFIELD1= MFIELD1+1
                  SEEK MFIELD1
               ENDDO
            ENDIF
         ENDIF
         MFIELD1= INV_D
         CONFIRM= ' '
         &C_CLEAR
         @ 21, 0 CLEAR
         &C_MESSAGE
         @ 23, 23 SAY ' Earliest Recorded Date is '+DTOC(MFIELD1)+'. '
         &C_GET
         @ 21, 20 SAY ' Press <A> to Abort, any key to Continue.' GET CONFIRM PICTURE '!'
         READ
         &C_CLEAR
         @ 21, 0
         @ 23, 0
         IF CONFIRM='A'
            LOOP
         ENDIF
         &C_GET
         @ 5, 26 SAY MFIELD1
      ENDIF
   ENDIF
   @ 6, 26 GET MFIELD2 PICTURE '@!'
   READ
   SEEK MFIELD2
   IF EOF()
      GOTO BOTTOM
      MFIELD2= INV_D
      CONFIRM= ' '
      &C_CLEAR
      @ 21, 0 CLEAR
      &C_MESSAGE
      @ 23, 23 SAY ' Latest Recorded Date is '+DTOC(MFIELD2)+'. '
      &C_GET
      @ 21, 20 SAY ' Press <A> to Abort, any key to Continue.' GET CONFIRM PICTURE '!'
      READ
      &C_CLEAR
      @ 21, 0
      @ 23, 0
      IF CONFIRM='A'
         LOOP
      ENDIF
      &C_GET
      @ 6, 26 SAY MFIELD2
   ENDIF
   MFIELD3= SPACE(10)
   @ 5, 68 GET MFIELD3 PICTURE '@!'
   READ
   SET CENTURY OFF
   IF MFIELD1>MFIELD2
      MTEMP= MFIELD1
      MFIELD1= MFIELD2
      MFIELD2= MTEMP
   ENDIF
   SEEK MFIELD1
   STORE 0.00 TO STL1, STL2, STL3, STL4, GTL1, GTL2, GTL3, GTL4
   &C_CLEAR
   @ 10, 1 CLEAR TO 19, 78
   FLAG= 1
   ROW= 9
   SET COLOR TO *+g
   @ 11, 10 SAY 'Please wait, computing...'
   SET COLOR TO 
   DO WHILE .not. EOF().and.INV_D<=MFIELD2
      IF LEN(TRIM(MFIELD3))<>0
         IF MFIELD3<>CUST_N
            SKIP
            LOOP
         ENDIF
      ENDIF
      GTL1= GTL1+INV_A
      GTL2= GTL2+NET_A
      GTL3= GTL3+INV_C
      GTL4= GTL4+NET_A-INV_C
      SKIP
   ENDDO
   @ 11, 10 SAY '                          '
   @ 14, 1 SAY SPACE(78)
   SET COLOR TO +g
   @ 14, 8 SAY 'GRAND TOTAL:'
   IF MUSER='ADMIN'.or.MUSER='BERDY'
      @ 14, 22 SAY GTL1 PICTURE '##,###,###.##'
      @ 14, 37 SAY GTL2 PICTURE '##,###,###.##'
      @ 14, 52 SAY GTL3 PICTURE '##,###,###.##'
      @ 14, 66 SAY GTL4 PICTURE '##,###,###.##'
   ELSE
      @ 14, 22 SAY GTL1 PICTURE '##,###,###.##'
      @ 14, 37 SAY GTL2 PICTURE '##,###,###.##'
      @ 14, 52 SAY GTL3 PICTURE '    --    '
      @ 14, 66 SAY GTL4 PICTURE '    --    '
   ENDIF
   CONFIRM= 'A'
   &C_CLEAR
   @ 21, 0
   &C_MESSAGE
   DO WHILE .T.
      @ 21, 24 SAY ' Return to Previous Menu (y/n). ' GET CONFIRM PICTURE 'Y'
      READ
      IF CONFIRM$'YyNn'
         EXIT
      ENDIF
   ENDDO
   IF CONFIRM='N'
      &C_CLEAR
      @ 9, 1 CLEAR TO 19, 78
      @ 21, 0
      ROW= 9
      LOOP
   ELSE
      CLOSE DATABASE
      SET CENTURY OFF
      RETURN
   ENDIF
ENDDO
CLOSE DATABASE
RETURN
 

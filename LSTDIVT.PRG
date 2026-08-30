* program.....: LstDivT.prg

SELECT 2
   USE STKREC INDEX TRANS_CN
SELECT 1
   USE SIFYL INDEX SI_D

DO BRDR2
@ 8, 2 SAY 'SI DATE   SI NO.     CUST.CODE                                     NET AMT.'
@ 1, 1 SAY 'B] Sales Per Division - Totals only '

DO WHILE .T.
   &C_HEAD
   @ 20, 1 SAY SPACE(78)
   &C_MESSAGE
   @ 21, 20 SAY ' NOTE: Press <Enter> to Return to Main Menu. '
   &C_BODY
   @ 5, 3 SAY 'Start At Issued Date :'
   @ 6, 3 SAY 'Stop  At Issued Date :'
   @ 5, 43 SAY 'Territory:'
   @ 6, 43 SAY 'Division :'
   SET CENTURY ON
   MINV_D= CTOD('01/01/2000')
   GOTO BOTTOM
   MFIELD2= DATE()
   GOTO TOP
   MFIELD1= CTOD('  /  /  ')
   &C_GET
   @ 6, 26 SAY MFIELD2 PICTURE '99/99/9999'
   @ 5, 26 GET MFIELD1 PICTURE '99/99/9999'
   READ
   IF MFIELD1=CTOD('  /  /    ')
      SET CENTURY OFF
      CLOSE DATABASE
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
   @ 6, 26 GET MFIELD2 PICTURE '99/99/9999'
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
   SET CENTURY OFF
   MFIELD3= SPACE(10)
   MFIELD4= SPACE(4)
   MFIELD5= SPACE(4)
   MFIELD6= SPACE(4)
   MFIELD7= SPACE(4)
   MFIELD8= SPACE(4)
   @ 5, 54 GET MFIELD3 PICTURE '@!'
   * 5     6         7         
   * 45678901234567890123456789
   * xxxx xxxx xxxx xxxx xxxx
   @ 6, 54 GET MFIELD4 PICTURE '@!'
   @ 6, 59 GET MFIELD5 PICTURE '@!'
   @ 6, 64 GET MFIELD6 PICTURE '@!'
   @ 6, 69 GET MFIELD7 PICTURE '@!'
   @ 6, 74 GET MFIELD8 PICTURE '@!'

   READ
   *SET CENTURY OFF
   IF MFIELD1>MFIELD2
      MTEMP= MFIELD1
      MFIELD1= MFIELD2
      MFIELD2= MTEMP
   ENDIF
   SEEK MFIELD1
   STORE 0.00 TO TTL1, TTL2, TTL3, TTL4, TTL5
   STORE 0.00 TO GTL1, GTL2, GTL3, GTL4, GTL5, GTL6
   &C_CLEAR
   @ 10, 1 CLEAR TO 19, 78
   ROW= 9
   SET COLOR TO *+g
   @ 11, 10 SAY 'Please wait, computing...'
   SET COLOR TO 
   DO WHILE .not. EOF().and.INV_D<=MFIELD2
      IF LEN(TRIM(MFIELD3))<>0
         IF MFIELD3<>CUST_S
            SKIP
            LOOP
         ENDIF
      ENDIF
      MINV_N= 'S'+INV_N
      STORE 0.00 TO TTL1, TTL2, TTL3, TTL4, TTL5
      SELECT 2
      SEEK MINV_N
      DO WHILE .not. EOF().and.MINV_N=TRANS_C+TRANS_N
         DO CASE
            CASE STK_DV=MFIELD4
               TTL1= TTL1+T_PRYS
            CASE STK_DV=MFIELD5
               TTL2= TTL2+T_PRYS
            CASE STK_DV=MFIELD6
               TTL3= TTL3+T_PRYS
            CASE STK_DV=MFIELD7
               TTL4= TTL4+T_PRYS
            CASE STK_DV=MFIELD8
               TTL5= TTL5+T_PRYS
         ENDCASE
         SKIP
      ENDDO
      SELECT 1
      TTL1= TTL1-TTL1*DCOUNT1/100
      TTL1= TTL1-TTL1*DCOUNT2/100
      TTL1= TTL1-TTL1*DCOUNT3/100
      TTL2= TTL2-TTL2*DCOUNT1/100
      TTL2= TTL2-TTL2*DCOUNT2/100
      TTL2= TTL2-TTL2*DCOUNT3/100
      TTL3= TTL3-TTL3*DCOUNT1/100
      TTL3= TTL3-TTL3*DCOUNT2/100
      TTL3= TTL3-TTL3*DCOUNT3/100
      TTL4= TTL4-TTL4*DCOUNT1/100
      TTL4= TTL4-TTL4*DCOUNT2/100
      TTL4= TTL4-TTL4*DCOUNT3/100
      TTL5= TTL5-TTL5*DCOUNT1/100
      TTL5= TTL5-TTL5*DCOUNT2/100
      TTL5= TTL5-TTL5*DCOUNT3/100
      *
      GTL1= GTL1+TTL1
      GTL2= GTL2+TTL2
      GTL3= GTL3+TTL3
      GTL4= GTL4+TTL4
      GTL5= GTL5+TTL5
      GTL6= GTL6+NET_A
      
      SKIP
   ENDDO
   @ 11, 10 SAY '                          '
   SET COLOR TO +g
   ROW= 11
   IF LEN(TRIM(MFIELD4))<>0
      @ ROW, 23 SAY MFIELD4
      @ ROW, 33 SAY ':'
      @ ROW, 36 SAY GTL1 PICTURE '###,###,###.##'
      ROW= ROW+1
   ENDIF
   IF LEN(TRIM(MFIELD5))<>0
      @ ROW, 23 SAY MFIELD5
      @ ROW, 33 SAY ':'
      @ ROW, 36 SAY GTL2 PICTURE '###,###,###.##'
      ROW= ROW+1
   ENDIF
   IF LEN(TRIM(MFIELD6))<>0
      @ ROW, 23 SAY MFIELD6
      @ ROW, 33 SAY ':'
      @ ROW, 36 SAY GTL3 PICTURE '###,###,###.##'
      ROW= ROW+1
   ENDIF
   IF LEN(TRIM(MFIELD7))<>0
      @ ROW, 23 SAY MFIELD7
      @ ROW, 33 SAY ':'
      @ ROW, 36 SAY GTL4 PICTURE '###,###,###.##'
      ROW= ROW+1
   ENDIF
   IF LEN(TRIM(MFIELD8))<>0
      @ ROW, 23 SAY MFIELD8
      @ ROW, 33 SAY ':'
      @ ROW, 36 SAY GTL5 PICTURE '###,###,###.##'
      ROW= ROW+1
   ENDIF
   ROW= ROW+1
   @ ROW, 15 SAY 'Total Sales Amount:'
   @ ROW, 36 SAY GTL6 PICTURE '###,###,###.##'
   CONFIRM= 'N'
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
SET CENTURY OFF
RETURN

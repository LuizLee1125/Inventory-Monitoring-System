* program.....: LstSlCdT.prg

DO BRDR2
@ 8, 2 SAY 'SI DATE   SI NO.     CUST.CODE                                     NET AMT.'
@ 1, 1 SAY 'B] Sales Per Cust/Div - Totals only * UNDER CONSTRUCTION * press any key...'
ATLPRESS= INKEY(0)
RETURN
SELECT 2
USE STKREC INDEX TRANS_CN
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
   @ 5, 43 SAY 'Customer :'
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
   MFIELD4= SPACE(5)
   MFIELD5= SPACE(5)
   MFIELD6= SPACE(5)
   MFIELD7= SPACE(5)
   @ 5, 54 GET MFIELD3 PICTURE '@!'
   @ 6, 54 GET MFIELD4 PICTURE '@!'
   @ 6, 60 GET MFIELD5 PICTURE '@!'
   @ 6, 66 GET MFIELD6 PICTURE '@!'
   @ 6, 72 GET MFIELD7 PICTURE '@!'
   READ
   SET CENTURY OFF
   CHOICE= 'L'
   DO OPTION8
   IF MFIELD1>MFIELD2
      MTEMP= MFIELD1
      MFIELD1= MFIELD2
      MFIELD2= MTEMP
   ENDIF
   SEEK MFIELD1
   &C_HEAD
   @ 8, 28 SAY MFIELD4 PICTURE '@!'
   @ 8, 39 SAY MFIELD5 PICTURE '@!'
   @ 8, 50 SAY MFIELD6 PICTURE '@!'
   @ 8, 61 SAY MFIELD7 PICTURE '@!'
   DO CASE
      CASE CHOICE='L'
         STORE 0.00 TO TTL1, TTL2, TTL3, STL1, STL2, STL3, STL4, GTL1, GTL2, GTL3, GTL4
         &C_CLEAR
         @ 10, 1 CLEAR TO 19, 78
         FLAG= 1
         ROW= 9
         DO WHILE .not. EOF().and.INV_D<=MFIELD2
            IF FLAG=1
               C_LIST= C_OPTION
               FLAG= 0
            ELSE
               C_LIST= C_BODY
               FLAG= 1
            ENDIF
            &C_LIST
            IF LEN(TRIM(MFIELD3))<>0
               IF MFIELD3<>CUST_N
                  SKIP
                  LOOP
               ENDIF
            ENDIF
            @ ROW, 2 SAY INV_D PICTURE '@!'
            @ ROW, 12 SAY INV_N PICTURE '@!'
            @ ROW, 67 SAY NET_A PICTURE '###,###.##'
            MINV_N= 'S'+INV_N
            STORE 0.00 TO TTL1, TTL2, TTL3, TTL4
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
               ENDCASE
               @ ROW, 23 SAY TTL1 PICTURE '###,###.##'
               @ ROW, 34 SAY TTL2 PICTURE '###,###.##'
               @ ROW, 45 SAY TTL3 PICTURE '###,###.##'
               @ ROW, 56 SAY TTL4 PICTURE '###,###.##'
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
            @ ROW, 23 SAY TTL1 PICTURE '###,###.##'
            @ ROW, 34 SAY TTL2 PICTURE '###,###.##'
            @ ROW, 45 SAY TTL3 PICTURE '###,###.##'
            @ ROW, 56 SAY TTL4 PICTURE '###,###.##'
            STL1= STL1+TTL1
            STL2= STL2+TTL2
            STL3= STL3+TTL3
            STL4= STL4+NET_A
            GTL1= GTL1+TTL1
            GTL2= GTL2+TTL2
            GTL3= GTL3+TTL3
            GTL4= GTL4+NET_A
            ROW= ROW+1
            SKIP
            IF EOF()
               EXIT
            ENDIF
            IF ROW=19
               &C_HEAD
               @ 19, 1 SAY SPACE(78)
               @ 19, 10 SAY 'SUB   TOTAL'
               @ 19, 34 SAY STL1 PICTURE '#######.##'
               @ 19, 45 SAY STL2 PICTURE '#######.##'
               @ 19, 56 SAY STL3 PICTURE '#######.##'
               @ 19, 67 SAY STL4 PICTURE '#######.##'
               @ 20, 1 SAY SPACE(78)
               @ 20, 10 SAY 'GRAND TOTAL'
               @ 20, 34 SAY GTL1 PICTURE '#######.##'
               @ 20, 45 SAY GTL2 PICTURE '#######.##'
               @ 20, 56 SAY GTL3 PICTURE '#######.##'
               @ 20, 67 SAY GTL4 PICTURE '#######.##'
               CHOICE= ' '
               &C_CLEAR
               @ 21, 0
               &C_MESSAGE
               @ 21, 20 SAY ' Press <A> to Abort, any key to continue.' GET CHOICE PICTURE '!'
               READ
               IF CHOICE='A'
                  SET CENTURY OFF
                  CLOSE DATABASE
                  RETURN
               ENDIF
               &C_CLEAR
               @ 9, 1 CLEAR TO 19, 78
               ROW= 9
               STORE 0.00 TO STL1, STL2, STL3, STL4
            ENDIF
         ENDDO
         &C_HEAD
         @ 19, 1 SAY SPACE(78)
         @ 19, 10 SAY 'SUB   TOTAL'
         @ 19, 34 SAY STL1 PICTURE '#######.##'
         @ 19, 45 SAY STL2 PICTURE '#######.##'
         @ 19, 56 SAY STL3 PICTURE '#######.##'
         @ 19, 67 SAY STL4 PICTURE '#######.##'
         @ 20, 1 SAY SPACE(78)
         @ 20, 10 SAY 'GRAND TOTAL'
         @ 20, 34 SAY GTL1 PICTURE '#######.##'
         @ 20, 45 SAY GTL2 PICTURE '#######.##'
         @ 20, 56 SAY GTL3 PICTURE '#######.##'
         @ 20, 67 SAY GTL4 PICTURE '#######.##'
      CASE CHOICE='P'
         PG= 1
         STORE 0.00 TO TTL1, TTL2, TTL3, TTL4, STL1, STL2, STL3, STL4, STL5, GTL1, GTL2, GTL3, GTL4, GTL5
         DO WHILE .T.
            &C_MESSAGE
            @ 23, 50 SAY '...Printing'
            SET CONSOLE OFF
            SET DEVICE TO PRINTER
            SET PRINTER ON
            ?? CHR(27)+CHR(64)
            ?? CHR(18)
            CDATE= CMONTH(DATE())+' '+STR(DAY(DATE()),2)+','+STR(YEAR(DATE()),4)
            HEAD= 'Sales Summary from '+DTOC(MFIELD1)+' to '+DTOC(MFIELD2)
            IF LEN(TRIM(MFIELD3))<>0
               HEAD1= 'For Territory = '+LTRIM(TRIM(MFIELD3))
            ENDIF
            @ 3, 1 SAY 'Page '+LTRIM(STR(PG))
            @ 3, (80-LEN(COMPANY))/2 SAY COMPANY
            @ 4, (80-LEN(HEAD))/2 SAY HEAD
            IF LEN(TRIM(MFIELD3))<>0
               @ 5, (80-LEN(HEAD1))/2 SAY HEAD1
            ENDIF
            ?? CHR(15)
            @ 7, 7 SAY '--------------------------------------------------------------------------------------------------------------------'
            @ 8, 7 SAY 'SI DATE     SI NO.        CUSTOMER CODE                                                                   NET AMOUNT'
            @ 8, 53 SAY MFIELD4 PICTURE '@!'
            @ 8, 69 SAY MFIELD5 PICTURE '@!'
            @ 8, 85 SAY MFIELD6 PICTURE '@!'
            @ 8, 101 SAY MFIELD7 PICTURE '@!'
            @ 9, 7 SAY '--------------------------------------------------------------------------------------------------------------------'
            ROW= 9
            DO WHILE .not. EOF().and.INV_D<=MFIELD2
               IF LEN(TRIM(MFIELD3))<>0
                  IF MFIELD3<>CUST_S
                     SKIP
                     LOOP
                  ENDIF
               ENDIF
               ROW= ROW+1
               @ ROW, 7 SAY INV_D PICTURE '@!'
               @ ROW, 19 SAY INV_N PICTURE '@!'
               @ ROW, 33 SAY CUST_N PICTURE '@!'
               MINV_N= 'S'+INV_N
               STORE 0.00 TO TTL1, TTL2, TTL3, TTL4
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
               @ ROW, 47 SAY TTL1 PICTURE '#,###,###.##'
               @ ROW, 63 SAY TTL2 PICTURE '#,###,###.##'
               @ ROW, 79 SAY TTL3 PICTURE '#,###,###.##'
               @ ROW, 95 SAY TTL4 PICTURE '#,###,###.##'
               @ ROW, 111 SAY NET_A PICTURE '#,###,###.##'
               STL1= STL1+TTL1
               GTL1= GTL1+TTL1
               STL2= STL2+TTL2
               GTL2= GTL2+TTL2
               STL3= STL3+TTL3
               GTL3= GTL3+TTL3
               STL4= STL4+TTL4
               GTL4= GTL4+TTL4
               STL5= STL5+NET_A
               GTL5= GTL5+NET_A
               SKIP
               IF ROW>55
                  @ ROW+1, 46 SAY REPLICATE('-',77)
                  @ ROW+2, 46 SAY STL1 PICTURE '##,###,###.##'
                  @ ROW+2, 62 SAY STL2 PICTURE '##,###,###.##'
                  @ ROW+2, 78 SAY STL3 PICTURE '##,###,###.##'
                  @ ROW+2, 94 SAY STL4 PICTURE '##,###,###.##'
                  @ ROW+2, 110 SAY STL5 PICTURE '##,###,###.##'
                  @ ROW+3, 75 SAY '...continued on page '+LTRIM(STR(PG+1))
                  ?
                  ?? CHR(18)
                  EJECT
                  SET PRINTER OFF
                  SET DEVICE TO SCREEN
                  SET CONSOLE ON
                  &C_CLEAR
                  @ 23, 0
                  CHOICE= ' '
                  &C_CLEAR
                  @ 23, 0
                  @ 21, 0
                  &C_MESSAGE
                  @ 21, 20 SAY ' Press <A> to Abort, any key to continue.' GET CHOICE PICTURE '!'
                  READ
                  IF CHOICE='A'
                     SET CENTURY OFF
                     CLOSE DATABASE
                     RETURN
                  ENDIF
                  &C_CLEAR
                  @ 23, 0
                  &C_MESSAGE
                  @ 23, 50 SAY '...Printing'
                  SET CONSOLE OFF
                  SET DEVICE TO PRINTER
                  SET PRINTER ON
                  PG= PG+1
                  STORE 0.00 TO STL1, STL2, STL3, STL4, STL5
                  @ 3, 1 SAY 'Page '+LTRIM(STR(PG))
                  @ 3, (80-LEN(HEAD))/2 SAY HEAD
                  IF LEN(TRIM(MFIELD3))<>0
                     @ 4, (80-LEN(HEAD1))/2 SAY HEAD1
                  ENDIF
                  ?? CHR(15)
                  @ 6, 7 SAY '--------------------------------------------------------------------------------------------------------------------'
                  @ 7, 7 SAY 'SI DATE     SI NO.        CUSTOMER CODE                                                                   NET AMOUNT'
                  @ 7, 53 SAY MFIELD4 PICTURE '@!'
                  @ 7, 69 SAY MFIELD5 PICTURE '@!'
                  @ 7, 85 SAY MFIELD6 PICTURE '@!'
                  @ 7, 101 SAY MFIELD7 PICTURE '@!'
                  @ 8, 7 SAY '--------------------------------------------------------------------------------------------------------------------'
                  ROW= 8
               ENDIF
            ENDDO
            IF EOF().or.INV_D>MFIELD2
               IF PG>1
                  @ ROW+1, 46 SAY REPLICATE('-',77)
                  @ ROW+2, 46 SAY STL1 PICTURE '##,###,###.##'
                  @ ROW+2, 62 SAY STL2 PICTURE '##,###,###.##'
                  @ ROW+2, 78 SAY STL3 PICTURE '##,###,###.##'
                  @ ROW+2, 94 SAY STL4 PICTURE '##,###,###.##'
                  @ ROW+2, 110 SAY STL5 PICTURE '##,###,###.##'
                  ROW= ROW+2
               ENDIF
               @ ROW+1, 46 SAY REPLICATE('=',77)
               @ ROW+2, 46 SAY GTL1 PICTURE '##,###,###.##'
               @ ROW+2, 62 SAY GTL2 PICTURE '##,###,###.##'
               @ ROW+2, 78 SAY GTL3 PICTURE '##,###,###.##'
               @ ROW+2, 94 SAY GTL4 PICTURE '##,###,###.##'
               @ ROW+2, 110 SAY GTL5 PICTURE '##,###,###.##'
               @ ROW+3, 46 SAY REPLICATE('=',77)
               ?
               ?? CHR(18)
               EJECT
               SET PRINTER OFF
               SET DEVICE TO SCREEN
               SET CONSOLE ON
               &C_CLEAR
               @ 23, 0
               EXIT
            ENDIF
         ENDDO
      OTHERWISE
         SET CENTURY ON
         CLOSE DATABASE
         RETURN
   ENDCASE
   SET CENTURY ON
   CHOICE= ' '
   &C_CLEAR
   @ 21, 0
   &C_MESSAGE
   @ 21, 24 SAY ' Return to Previous Menu (y/n). ' GET CONFIRM PICTURE '!'
   READ
   IF CONFIRM='N'
      &C_CLEAR
      @ 9, 1 CLEAR TO 19, 78
      @ 21, 0
      ROW= 9
      LOOP
   ELSE
      SET CENTURY OFF
      CLOSE DATABASE
      RETURN
   ENDIF
ENDDO
SET CENTURY OFF
CLOSE DATABASE
RETURN
 

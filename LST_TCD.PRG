* program.....: Lst_TCD.prg
*             : sale summary per territory, all customers, all sales amount of
*             : all division, inclusive dates
*             : 08/05/04

SELE 4
   SET EXCL ON
   USE SLS_TCD INDEX S_TCD_CN
   ZAP
   SET EXCL OFF
SELECT 3
   USE CUSTFYL INDEX CUST_N
SELECT 2
   USE STKREC INDEX TRANS_CN
SELECT 1
   USE SIFYL INDEX SI_D

DO BRDR2
@ 8, 2 SAY 'SI DATE   SI NO.     CUST.CODE                                     NET AMT.'
*@ 1, 1 SAY 'B] Sales Per Division - Totals only '

   &C_HEAD
   @ 20, 1 SAY SPACE(78)
   &C_MESSAGE
   @ 21, 20 SAY ' NOTE: Press <Enter> to Return to Main Menu. '
   &C_BODY
   @ 5, 3 SAY 'Start At Issued Date :'
   @ 6, 3 SAY 'Stop  At Issued Date :'
   @ 5, 43 SAY 'Territory:'
   *@ 6, 43 SAY 'Division :'
   SET CENTURY ON
   MINV_D= CTOD('01/01/2004')
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
   READ
   IF MFIELD1>MFIELD2
      MTEMP= MFIELD1
      MFIELD1= MFIELD2
      MFIELD2= MTEMP
   ENDIF
   SEEK MFIELD1

   &C_CLEAR
   @ 10, 1 CLEAR TO 19, 78
   atlmsg="please wait, extracting data....."
   atllen=len(atlmsg)
   set colo to rb/rb
   @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+3
   set colo to +w/rb
   @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+3
   @ 12,41-atllen/2 say atlmsg

   SELE 3
   go top
   DO WHILE .NOT. EOF()
      if trim(cust_s)=trim(mfield3)
         sele 4
         appe blan
         repl cust_n    with custfyl->cust_n
         repl cust_m    with custfyl->cust_m
         repl area_code with custfyl->cust_ac
         unlock
      endif
      sele 3
      skip
   enddo

   sele 1
   DO WHILE .not. EOF().and.INV_D<=MFIELD2
      IF MFIELD3<>CUST_S
         SKIP
         LOOP
      ENDIF
      MINV_N= 'S'+INV_N
      STOR CUST_N TO SV_CUST_N
      SELECT 2
      SEEK MINV_N
      DO WHILE .not. EOF().and.MINV_N=TRANS_C+TRANS_N
         DO CASE
            CASE STK_DV="PH1"
                 SELE 4
                 SEEK SV_CUST_N
                 REPL PH1 WITH (PH1+STKREC->T_PRYS)
                 UNLOCK
            CASE STK_DV="PH2"
                 SELE 4
                 SEEK SV_CUST_N
                 REPL PH2 WITH (PH2+STKREC->T_PRYS)
                 UNLOCK
            CASE STK_DV="PH3"
                 SELE 4
                 SEEK SV_CUST_N
                 REPL PH3 WITH (PH3+STKREC->T_PRYS)
                 UNLOCK
            CASE STK_DV="PH4"
                 SELE 4
                 SEEK SV_CUST_N
                 REPL PH4 WITH (PH4+STKREC->T_PRYS)
                 UNLOCK
            CASE STK_DV="CON"
                 SELE 4
                 SEEK SV_CUST_N
                 REPL CONS WITH (CONS+STKREC->T_PRYS)
                 UNLOCK
         ENDCASE
         SELE 2
         SKIP
      ENDDO
      SELECT 1
      SKIP
   ENDDO

sele 4
set safe off
sort on area_code, cust_n to srt_stcd
set safe on

atlmsg="finished extracting data... File: Srt_STCD.dbf  press any key..."
atllen=len(atlmsg)
set colo to rb/rb
@ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+3
set colo to +w/rb
@ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+3
@ 12,41-atllen/2 say atlmsg
atlkey=inkey(0)
clear
close data
return


* program.....: LstPurSG.prg
*             : purchase summary; TOTALS ONLY; GROSS
*             : 08/10/04

DO BRDR2
@ 8, 2 SAY 'SI DATE   SI NO.     SUPPLIER    TYPE OF TERM     GROSS AMT.'

SELE 2
   USE STKREC INDEX TRANS_CN
SELECT 1
   USE PURFYL INDEX PUR_D

DO WHILE .T.
   SET CENTURY ON
   &C_HEAD
   @ 20, 1 SAY SPACE(78)
   &C_MESSAGE
   @ 21, 20 SAY ' NOTE: Press <Enter> to Return to Main Menu. '
   &C_BODY
   @ 5, 3 SAY 'Start At Issued Date :'
   @ 6, 3 SAY 'Stop  At Issued Date :'
   @ 5, 52 SAY 'Supplier Code :'
   minv_d= CTOD('01/01/2001')
   GOTO BOTTOM
   mfield2= DATE()
   GOTO TOP
   mfield1= CTOD('  /  /  ')
   &C_GET
   @ 6, 26 SAY mfield2 PICTURE '99/99/9999'
   @ 5, 26 GET mfield1 PICTURE '99/99/9999'
   READ
   IF mfield1=CTOD('  /  /  ')
      CLOSE DATA
      SET CENTURY OFF
      RETURN
   ELSE
      SEEK mfield1
      IF EOF()
         GOTO TOP
         IF mfield1>inv_d
            GOTO BOTTOM
            IF mfield1<inv_d
               SKIP
               DO WHILE EOF()
                  mfield1= mfield1+1
                  SEEK mfield1
               ENDDO
            ENDIF
         ENDIF
         mfield1= inv_d
         confirm= ' '
         &C_CLEAR
         @ 21, 0 CLEAR
         &C_MESSAGE
         @ 23, 23 SAY ' Earliest Recorded Date is '+DTOC(mfield1)+'. '
         &C_GET
         @ 21, 20 SAY ' Press <A> to Abort, any key to Continue.' GET confirm PICTURE '!'
         READ
         &C_CLEAR
         @ 21, 0
         @ 23, 0
         IF confirm='A'
            LOOP
         ENDIF
         &C_GET
         @ 5, 26 SAY mfield1 PICT '99/99/9999'
      ENDIF
   ENDIF
   stor recno() to atl_recno
   @ 6, 26 GET mfield2 PICTURE '99/99/9999'
   READ
   SEEK mfield2
   IF EOF()
         GOTO atl_recno
         do while .t. .and. .not.eof()
            IF inv_d>mfield2
               exit
            endif
               SKIP
         enddo
         skip -1
         mfield2= inv_d
         confirm= ' '
         &C_CLEAR
         @ 21, 0 CLEAR
         &C_MESSAGE
         @ 23, 23 SAY ' Last Recorded Date is '+DTOC(mfield2)+'. '
         &C_GET
         @ 21, 20 SAY ' Press <A> to Abort, any key to Continue.' GET confirm PICTURE '!'
         READ
         &C_CLEAR
         @ 21, 0
         @ 23, 0
         IF confirm='A'
            LOOP
         ENDIF
         &C_GET
         @ 6, 26 SAY mfield2 PICT '99/99/9999'
   ENDIF

   mfield3= SPACE(10)
   @ 5, 68 GET mfield3 PICTURE '@!'
   READ
   SET CENTURY OFF
   IF mfield1>mfield2
      mtemp= mfield1
      mfield1= mfield2
      mfield2= mtemp
   ENDIF
   SEEK mfield1

         STORE 0.00 TO stl1, gtl1
         &C_CLEAR
         @ 10, 1 CLEAR TO 19, 78
         row= 9
         DO WHILE .not. EOF().and.inv_d<=mfield2
            IF LEN(TRIM(mfield3))<>0
               IF mfield3<>splyr_n
                  SKIP
                  LOOP
               ENDIF
            ENDIF
            stor trim(inv_n) to sv_inv_n
            pkey="P"+sv_inv_n
            sele 2
            seek pkey
            if found()
               do while .not. eof() .and. trans_n=sv_inv_n
                  gtl1=gtl1+issue_q*issue_cp
                  skip
               enddo
            endif
            sele 1
            SKIP
         ENDDO
         set colo to +g
         @ 14, 10 SAY 'GRAND TOTAL:'
         @ 14, 49 SAY gtl1 PICTURE '##,###,###.##'

   choice= ' '
   &C_CLEAR
   @ 21, 0
   &C_MESSAGE
   @ 21, 24 SAY ' Return to Previous Menu (y/n). ' GET confirm PICTURE '!'
   READ
   IF confirm='N'
      &C_CLEAR
      @ 9, 1 CLEAR TO 19, 78
      @ 21, 0
      row= 9
      LOOP
   ELSE
      EXIT
   ENDIF
ENDDO

SET CENTURY OFF
CLOSE DATA
RETURN

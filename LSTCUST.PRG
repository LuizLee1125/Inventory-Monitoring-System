* program.....: LstCust.prg
*             : customer list

SELECT 1
   USE CUSTFYL INDEX CUST_N
DO BRDR2
  *                    1         2         3         4         5         6         7         8         9
  *            234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
   @ 8, 2 SAY 'CODE       NAME                      AREA  TEL. NO.       PRICE TERMS'
  *            1234567890 1234567890123456789012345 12345 123456789012345678 E 30 SPD

DO WHILE .T.
   &C_BODY
   mfield01= SPACE(10)
   mfield02= SPACE(10)
   mfield03= SPACE(1)
   mfield04= SPACE(10)
   mfield05= SPACE(10)
   @ 4, 02 SAY 'Territory Code :'
   @ 5, 02 SAY 'Area Code      :'
   @ 6, 02 SAY 'Price Category :'
   @ 4, 43 SAY 'Start At Customer Code :'
   @ 5, 43 SAY 'Stop  At Customer Code :'
   DO WHILE .T.
      &C_GET
      @ 4, 19 GET mfield01 PICTURE '@!'
      @ 5, 19 GET mfield02 PICTURE '@!'
      @ 6, 19 GET mfield03 PICTURE '@!'
      READ
      SET FILTER TO
      DO CASE
         CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield02))<>0.and.LEN(TRIM(mfield03))<>0
            SET FILTER TO cust_s=mfield01.and.cust_ac=mfield02.and.cust_pc=mfield03
         CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield02))<>0
            SET FILTER TO cust_s=mfield01.and.cust_ac=mfield02
         CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield03))<>0
            SET FILTER TO cust_s=mfield01.and.cust_pc=mfield03
         CASE LEN(TRIM(mfield02))<>0.and.LEN(TRIM(mfield03))<>0
            SET FILTER TO cust_ac=mfield02.and.cust_pc=mfield03
         CASE LEN(TRIM(mfield01))<>0
            SET FILTER TO cust_s=mfield01
         CASE LEN(TRIM(mfield02))<>0
            SET FILTER TO cust_ac=mfield02
         CASE LEN(TRIM(mfield03))<>0
            SET FILTER TO cust_pc=mfield03
      ENDCASE
      DO WHILE .T.
         GOTO BOTTOM
         mfield05= cust_n
         GOTO TOP
         mfield04= cust_n
         &C_GET
         @ 5, 68 SAY mfield05
         @ 4, 68 GET mfield04 PICTURE '@!'
         READ
         IF READKEY()=4.or.READKEY()=260
            EXIT
         ENDIF
         IF LEN(TRIM(mfield04))=0
            CLOSE DATA
            RETURN
         ELSE
            SEEK LTRIM(TRIM(mfield04))
         ENDIF
         IF EOF()
            choice= ' '
            &C_CLEAR
            @ 21, 0 CLEAR
            &C_MESSAGE
            @ 23, 30 SAY ' No Such Customer Code. '
            &C_GET
            @ 21, 20 SAY ' Press <A> to Abort, any key to Continue. ' GET choice PICTURE '!'
            READ
            IF choice='A'
               CLOSE DATA
               RETURN
            ELSE
               &C_CLEAR
               @ 21, 0
               @ 23, 0
               LOOP
            ENDIF
            mfield04= cust_n
            @ 4, 68 SAY mfield04
         ENDIF
         @ 5, 68 GET mfield05 PICTURE '@!'
         READ
         IF mfield05=SPACE(10)
            CLOSE DATA
            RETURN
         ELSE
            SEEK LTRIM(TRIM(mfield05))
         ENDIF
         IF EOF()
            choice= ' '
            &C_CLEAR
            @ 21, 0 CLEAR
            &C_MESSAGE
            @ 23, 30 SAY ' No Such Customer Code. '
            &C_GET
            @ 21, 20 SAY ' Press <A> to Abort, any key to Continue. ' GET choice PICTURE '!'
            READ
            IF choice='A'
               CLOSE DATA
               RETURN
            ELSE
               &C_CLEAR
               @ 21, 0
               @ 23, 0
               LOOP
            ENDIF
            mfield05= cust_n
            @ 5, 68 SAY mfield05
         ENDIF
         IF READKEY()=4.or.READKEY()=260
            LOOP
         ENDIF
         EXIT
      ENDDO
      IF READKEY()=4.or.READKEY()=260
         LOOP
      ENDIF
      EXIT
   ENDDO
   choice= 'L'
   DO OPTION8
   IF mfield04>mfield05.and.mfield05<>SPACE(10)
      mtemp= mfield04
      mfield04= mfield05
      mfield05= mtemp
   ENDIF
   SEEK mfield04
   DO CASE
      CASE choice='L'
         &C_CLEAR
         @ 9, 1 CLEAR TO 19, 78
         flag= 1
         row= 9
         DO WHILE .not. EOF().and.cust_n<=mfield05
            IF flag=1
               c_list= c_option
               flag= 0
            ELSE
               c_list= c_body
               flag= 1
            ENDIF
            &C_LIST
            @ row,  2 SAY cust_n  PICTURE '@!'
            @ row, 13 SAY cust_m  PICTURE '@S25'
            @ row, 39 SAY cust_ac PICTURE '@S5'
            @ row, 45 SAY cust_p  PICTURE '@S18'
            @ row, 64 SAY cust_pc PICTURE '@!'
            IF CUST_T <> 0
               CTERMS = LTRIM(STR(CUST_T))+" "+CUST_TP
            ELSE
               CTERMS = TRIM(CUST_TP)
            ENDIF

            @ row, 66 SAY cTERMS
            row= row+1
            SKIP
            IF EOF()
               EXIT
            ENDIF
            IF row=19
               choice= ' '
               &C_CLEAR
               @ 21, 0
               &C_MESSAGE
               @ 21, 20 SAY 'Press <A> to Abort, any key to continue.' GET choice PICTURE '!'
               READ
               IF choice='A'
                  CLOSE DATA
                  RETURN
               ENDIF
               &C_CLEAR
               @ 9, 1 CLEAR TO 19, 78
               row= 9
            ENDIF
         ENDDO
      CASE choice='P'
         do testprt
         pg= 1
         DO WHILE .T.
            &C_MESSAGE
            @ 23, 50 SAY '...Printing'
            SET CONSOLE OFF
            SET DEVICE TO PRINTER
            SET PRINTER ON
            ?? CHR(27)+CHR(64)
            ?? CHR(18)
            cdate= CMONTH(DATE())+' '+STR(DAY(DATE()),2)+', '+STR(YEAR(DATE()),4)
            head= 'Customer List as of '+cdate
            head1= ' '
            DO CASE
               CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield02))<>0.and.LEN(TRIM(mfield03))<>0
                  head1= 'for Territory = '+TRIM(mfield01)+', Area Code = '+TRIM(mfield02)+' and Price Category = '+TRIM(mfield03)
               CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield02))<>0
                  head1= 'for Territory = '+TRIM(mfield01)+' and Area Code = '+TRIM(mfield02)
               CASE LEN(TRIM(mfield01))<>0.and.LEN(TRIM(mfield03))<>0
                  head1= 'for Territory = '+TRIM(mfield01)+' and Price Category = '+TRIM(mfield03)
               CASE LEN(TRIM(mfield02))<>0.and.LEN(TRIM(mfield03))<>0
                  head1= 'for Area Code = '+TRIM(mfield02)+' and Price Category = '+TRIM(mfield03)
               CASE LEN(TRIM(mfield01))<>0
                  head1= 'for Territory = '+TRIM(mfield01)
               CASE LEN(TRIM(mfield02))<>0
                  head1= 'for Area Code = '+TRIM(mfield02)
               CASE LEN(TRIM(mfield03))<>0
                  head1= 'for Price Category = '+TRIM(mfield03)
            ENDCASE
            @ 3, 1 SAY 'Page '+LTRIM(STR(pg))
            @ 3, (80-LEN(company))/2 SAY company
            @ 4, (80-LEN(head))/2 SAY head
            IF LEN(TRIM(head1))<>0
               @ 5, (80-LEN(head1))/2 SAY head1
            ENDIF
            ?? CHR(15)
            @ 7, 3 SAY REPLICATE('-',126)
           *@ 8, 3 SAY 'CODE        NAME                           ADDRESS                         AREA CODE   TEL. NO.             PC TERM TERRITORY'

           *                   1         2         3         4         5         6         7         8         9         10        11        12       13
           *          12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123457890
            @ 8, 3 SAY 'CODE        NAME                           ADDRESS                          AREA CODE   TEL. NO.             PRICE  TERMS'
           *            1234567890  123456789012345678901234567890 123456789012345678901234567890   1234567890  12345678901234567890     1  99 SPDC
            @ 9, 3 SAY REPLICATE('-',126)
            row= 9
            DO WHILE .not. EOF().and.cust_n<=mfield05
               row= row+1
               @ row, 03  SAY cust_n  PICTURE '@!'
               @ row, 15  SAY cust_m  PICTURE '@!'
               @ row, 46  SAY cust_ad PICTURE '@!'
               @ row, 79  SAY cust_ac PICTURE '@!'
               @ row, 91  SAY cust_p  PICTURE '@!'
               @ row, 116 SAY cust_pc PICTURE '@!'
               IF CUST_T <> 0
                  CTERMS = LTRIM(STR(CUST_T))+" "+CUST_TP
               ELSE
                  CTERMS = TRIM(CUST_TP)
               ENDIF
               @ row, 119 SAY CTERMS  PICTURE '@!'
               row=row+1
               @ row, 46  SAY cust_ct picture '@!'
               SKIP
               IF EOF().or.cust_n>mfield05
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
               IF row>52
                  row= row+1
                  @ row+2, 104 SAY '...continued on page '+LTRIM(STR(pg+1))
                  ?
                  ?? CHR(18)
                  EJECT
                  SET PRINTER OFF
                  SET DEVICE TO SCREEN
                  SET CONSOLE ON
                  &C_CLEAR
                  @ 23, 0
                  choice= ' '
                  &C_CLEAR
                  @ 23, 0
                  @ 21, 0
                  &C_MESSAGE
                  @ 21, 20 SAY ' Press <A> to Abort, any key to continue. ' GET choice PICTURE '!'
                  READ
                  IF choice='A'
                     CLOSE DATA
                     RETURN
                  ENDIF
                  do testprt
                  &C_CLEAR
                  @ 23, 0
                  &C_MESSAGE
                  @ 23, 50 SAY '...Printing'
                  SET CONSOLE OFF
                  SET DEVICE TO PRINTER
                  SET PRINTER ON
                  pg= pg+1
                  stl= 0.00
                  @ 3, 1 SAY 'Page '+LTRIM(STR(pg))
                  @ 3, (80-LEN(head))/2 SAY head
                  IF LEN(TRIM(head1))<>0
                     @ 4, (80-LEN(head1))/2 SAY head1
                  ENDIF
                  ?? CHR(15)
                  @ 6, 3 SAY REPLICATE('-',126)
                  @ 7, 3 SAY 'CODE        NAME                           ADDRESS                          AREA CODE   TEL. NO.             PRICE  TERMS'
                  @ 8, 3 SAY REPLICATE('-',126)
                  row= 8
               ENDIF
            ENDDO
            IF EOF().or.cust_n>mfield05
               EXIT
            ENDIF
         ENDDO
   ENDCASE
   &C_CLEAR
   @ 21, 0
   &C_MESSAGE
   confirm= ' '
   DO WHILE .not. confirm$'YN'
      @ 21, 24 SAY ' Return to Previous Menu (y/n). ' GET confirm PICTURE '!'
      READ
   ENDDO
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

CLOSE DATA
RETURN

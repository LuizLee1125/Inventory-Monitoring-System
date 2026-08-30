* program.....: modulem.prg
* modified....: 04/13/99; up, down, page-up and page-down keys (invoicing)

PROCEDURE reclock1
confirm= ' '
DO WHILE .not. RLOCK()
   &C_CLEAR
   @ 21, 0
   &C_GET
   DO WHILE .not. confirm$'Y,N'
      @ 21, 15 SAY 'Record is being use by another user, Retry (Y/N)? ' GET confirm PICTURE '!'
      READ
   ENDDO
   IF confirm='N'
      &C_CLEAR
      @ 21, 0
      choice= 'A'
      RETURN
   ENDIF
ENDDO
RETURN

PROCEDURE valid1
&C_MESSAGE
@ 23, 50 SAY ' Searching... '
subkey= LTRIM(TRIM(subkey))
IF LEN(subkey)=0
   GOTO BOTTOM
   SKIP
ELSE
   SEEK subkey
ENDIF
&C_CLEAR
@ 23, 0
IF EOF()
   &C_CLEAR
   @ 21, 0
   ?? CHR(7)
   confirm= ' '
   &C_MESSAGE
   @ 21, 18 SAY ' No such record. Press any key to continue. ' GET confirm
   READ
   &C_CLEAR
   @ 21, 0
   &C_MESSAGE
   @ 21, 24 SAY ' NOTE: Please type your data. '
ENDIF
&C_GET
RETURN

PROCEDURE valid2
&C_MESSAGE
@ 23, 50 SAY ' Searching... '
subkey= LTRIM(TRIM(subkey))
IF LEN(subkey)=0
   GOTO BOTTOM
   SKIP
ELSE
   SEEK subkey
ENDIF
&C_CLEAR
@ 23, 0
IF EOF()
   &C_CLEAR
   @ 21, 0
   confirm= ' '
   &C_GET
   DO WHILE .not. confirm$'Y,N'
      @ 21, 20 SAY ' No such record. Continue anyway (Y/N)? ' GET confirm PICTURE '!'
      READ
   ENDDO
   &C_CLEAR
   @ 21, 0
   &C_MESSAGE
   @ 21, 24 SAY ' NOTE: Please type your data. '
ENDIF
&C_GET
RETURN

PROCEDURE mode
&C_MESSAGE
@ 23, 50 SAY ' Searching... '
recno= RECNO()
tkey= LTRIM(TRIM(key))
SEEK tkey
&C_CLEAR
@ 23, 0
IF EOF()
   IF choice='F'
      &C_CLEAR
      @ 22, 0
      new= .T.
      action= 'GET'
   ENDIF
   IF .not. new
      GOTO recno
   ENDIF
ELSE
   DO RECLOCK1
   IF confirm='N'
      RETURN
   ENDIF
   new= .F.
   action= 'SAY'
   IF recno=RECNO().and.choice='E'
      action= 'GET'
   ENDIF
   choice= 'E'
ENDIF
RETURN

PROCEDURE mode2
&C_MESSAGE
@ 23, 50 SAY ' Searching... '
recno= RECNO()
tkey= LTRIM(TRIM(key))
SEEK tkey
&C_CLEAR
@ 23, 0
IF EOF()
   IF choice='F'
      &C_CLEAR
      @ 22, 0
      new= .T.
      action= 'GET'
   ENDIF
   IF .not. new
      GOTO recno
   ENDIF
ELSE
   DO RECLOCK1
   IF confirm='N'
      RETURN
   ENDIF
   new= .F.
   action= 'SAY'
   IF recno=RECNO().and.choice='E'
      action= 'GET'
   ENDIF
   choice= 'N'
ENDIF
RETURN

PROCEDURE brdr1
&C_CLEAR
CLEAR
&C_HEAD
@ 01,01 SAY &PRG
@ 1, 62 SAY 'USER : '+muser
&C_BRDR
@ 0, 0 TO 2, 79
@ 3, 0 TO 20, 79 DOUBLE
&C_CLEAR
@ 21, 0
&C_MESSAGE
@ 21, 24 SAY ' NOTE: Please type your data. '
@ 22, 24 SAY ' Press <ENTER> to  Main Menu. '
RETURN

PROCEDURE brdr2
&C_CLEAR
CLEAR
&C_HEAD
@ 01,01 SAY &PRG
@ 1, 62 SAY 'USER : '+muser
@ 8, 1 SAY SPACE(78)
&C_BRDR
@ 0, 0 TO 2, 79
@ 3, 0 TO 20, 79 DOUBLE
&C_HEAD
RETURN

PROCEDURE menu3c
CLEAR TYPE
DO WHILE .T.
   choice= ' '
   prg= 'PRG'+STR(m_x,1)+CHR(m_y+64)
   &C_CHOICE
   @ M_ROW+M_Y,M_COL SAY &PRG
   @ m_row+m_y, m_col+2 GET choice PICTURE '@!'
   READ
   &C_OPTION
   @ M_ROW+M_Y,M_COL SAY &PRG
   &C_CLEAR
   @ 24, 0
   DO CASE
      CASE READKEY()=4.or.READKEY()=5
         m_y= IIF(READKEY()=4,m_y-1,m_y+1)
         m_y= IIF(m_y=0,m_y_max,m_y)
         m_y= IIF(m_y>m_y_max,1,m_y)
         LOOP
      CASE READKEY()=15
         choice= 'PRG'+STR(m_x,1)+CHR(m_y+64)
         EXIT
      CASE READKEY()=0.or.READKEY()=1
         m_x= IIF(READKEY()=0,m_x-1,m_x+1)
         m_x= IIF(m_x=0,m_x_max,m_x)
         m_x= IIF(m_x>m_x_max,1,m_x)
      CASE (ASC(choice)>48.and.ASC(choice)-49<m_y_col3).and.m_x_max>2
         m_x= 3
         m_y= ASC(choice)-48
      CASE (ASC(choice)>77.and.ASC(choice)-78<m_y_col2).and.m_x_max>1
         m_x= 2
         m_y= ASC(choice)-77
      CASE ASC(choice)>64.and.ASC(choice)-65<m_y_col1
         m_x= 1
         m_y= ASC(choice)-64
      OTHERWISE
         &C_MESSAGE
         @ 24, 24 SAY ' '+choice+' is not an available choice. '
         ?? CHR(7)
   ENDCASE
   DO CASE
      CASE m_x=1
         m_col= m_col1
         m_y_max= m_y_col1
      CASE m_x=2
         m_col= m_col2
         m_y_max= m_y_col2
      CASE m_x=3
         m_col= m_col3
         m_y_max= m_y_col3
   ENDCASE
   IF READKEY()=0.or.READKEY()=1
      m_y= IIF(m_y>m_y_max,m_y_max,m_y)
   ENDIF
ENDDO
&C_CLEAR
CLEAR
&C_MESSAGE
@ 23, 50 SAY ' Loading Programs ... '
RETURN

PROCEDURE menuopt
* SUSPEND
IF action='GET'
   o_x= 1
   o_col= o_cola
ELSE
   IF choice='T'
      choice= 'N'
   ENDIF
   IF choice='B'
      choice= 'V'
   ENDIF
   o_x= AT(choice,o_choice)
   o_col= 'O_COL'+CHR(o_x+64)
   O_COL=&O_COL
ENDIF
DO WHILE .T.
   &C_CLEAR
   @ 22, 0
   DO WHILE .T.
      choice= ' '
      opt= 'OPT'+CHR(o_x+64)
      &C_CHOICE
      @ O_ROW,O_COL SAY &OPT
      @ o_row, o_col GET choice PICTURE '@!'
      READ
      &C_OPTION
      @ O_ROW,O_COL SAY &OPT
      @ 23, 0
      @ 24, 0
      DO CASE
         CASE AT(choice,o_choice)>0
            EXIT
         CASE READKEY()=0.or.READKEY()=1
            o_x= IIF(READKEY()=0,o_x-1,o_x+1)
            o_x= IIF(o_x=0,o_x_max,o_x)
            o_x= IIF(o_x>o_x_max,1,o_x)
            o_col= 'O_COL'+CHR(o_x+64)
            O_COL=&O_COL
         CASE READKEY()=15
            choice= SUBSTR(o_choice,o_x,1)
            EXIT
         CASE READKEY()=2.or.READKEY()=3
            IF READKEY()=2
               choice= 'T'
            ELSE
               choice= 'B'
            ENDIF
            EXIT
         CASE READKEY()=5
            LOOP
         CASE READKEY()=6.or.READKEY()=7
            EXIT
         OTHERWISE
            &C_MESSAGE
            @ 24, 24 SAY ' '+choice+' is not an available choice. '
            ?? CHR(7)
      ENDCASE
   ENDDO
   DO CASE
      CASE choice='S'
         IF new
            &C_MESSAGE
            @ 23, 50 SAY ' Validating... '
            recno= RECNO()
            tkey= LTRIM(TRIM(key))
            SEEK tkey
            &C_CLEAR
            @ 23, 0
            IF .not. EOF()
               &C_CLEAR
               @ 21, 0
               confirm= ' '
               &C_GET
               @ 21, 12 SAY ' Please change Key Field, press any key to continue. ' GET confirm
               READ
               action= 'GET'
               choice= 'E'
               &C_CLEAR
               @ 21, 0
               &C_MESSAGE
               @ 21, 24 SAY ' NOTE: Please type your data. '
            ENDIF
         ENDIF
      CASE choice='E'
         if mUser="ADMIN"
            action= 'GET'
            &C_CLEAR
            @ 21, 0
            &C_MESSAGE
            @ 21, 21 SAY ' NOTE: Please type your new data. '
         else
            *action="SAY"
            save screen to atlscreen
            atlmsg="you are not authorized for this facility!!! press any key to continue..."
            atllen=len(atlmsg)
            set colo to rb/rb
            @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
            set colo to +w/rb
            @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
            @ 12,41-atllen/2 say atlmsg
            atlkeypress=inkey(0)
            restore screen from atlscreen
         endif
      CASE choice='D'
       IF MUSER="ADMIN"
         confirm= ' '
         &C_GET
         DO WHILE .not. confirm$'Y,N'
            @ 23, 25 SAY ' Delete this record (Y/N)? ' GET confirm PICTURE '!'
            READ
         ENDDO
         IF confirm='Y'
            IF new
                  choice= 'A'
            ELSE
                  DELETE
                  UNLOCK
            ENDIF
         ELSE
            &C_CLEAR
            @ 23, 0
            LOOP
         ENDIF
       ELSE
         save screen to atlscreen
         atlmsg="you are not authorized for this facility!!! press any key to continue..."
         atllen=len(atlmsg)
         set colo to rb/rb
         @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
         set colo to +w/rb
         @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
         @ 12,41-atllen/2 say atlmsg
         atlkeypress=inkey(0)
         restore screen from atlscreen
       ENDIF
      CASE choice$'VNTB'
         IF action='GET'
            &C_MESSAGE
            IF new
               @ 22, 19 SAY ' Warning, this record is not yet saved. '
            ELSE
               @ 22, 14 SAY ' Warning, changes in this record is not yet saved. '
            ENDIF
            confirm= ' '
            &C_GET
            DO WHILE .not. confirm$'Y,N'
               @ 23, 27 SAY ' Continue anyway (Y/N)? ' GET confirm PICTURE '!'
               READ
            ENDDO
            &C_CLEAR
            @ 22, 0
            @ 23, 0
            IF confirm='N'
               LOOP
            ELSE
               action= 'SAY'
               new= .F.
            ENDIF
         ENDIF
         DO CASE
            CASE choice='V'
               IF .not. BOF()
                  SKIP  -1
                  DO RECLOCK1
                  IF confirm='N'
                     RETURN
                  ENDIF
               ENDIF
               IF BOF()
                  &C_MESSAGE
                  @ 23, 26 SAY ' Top of file encountered. '
                  ?? CHR(7)
                  GOTO TOP
                  LOOP
               ENDIF
            CASE choice='N'
               IF .not. EOF()
                  SKIP
                  DO RECLOCK1
                  IF confirm='N'
                     RETURN
                  ENDIF
               ENDIF
               IF EOF()
                  &C_MESSAGE
                  @ 23, 26 SAY ' End of file encountered. '
                  ?? CHR(7)
                  GOTO BOTTOM
                  LOOP
               ENDIF
            CASE choice='T'
               GOTO TOP
               DO RECLOCK1
            CASE choice='B'
               GOTO BOTTOM
               DO RECLOCK1
         ENDCASE
   ENDCASE
   RETURN
ENDDO

PROCEDURE menuopt1
* SUSPEND
IF action='GET'
   o_x= 1
   o_col= o_cola
ELSE
   IF choice='T'
      choice= 'N'
   ENDIF
   IF choice='B'
      choice= 'V'
   ENDIF
   o_x= AT(choice,o_choice)
   o_col= 'O_COL'+CHR(o_x+64)
   O_COL=&O_COL
ENDIF
DO WHILE .T.
   &C_CLEAR
   @ 22, 0
   DO WHILE .T.
      choice= ' '
      opt= 'OPT'+CHR(o_x+64)
      &C_CHOICE
      @ O_ROW,O_COL SAY &OPT
      @ o_row, o_col GET choice PICTURE '@!'
      READ
      &C_OPTION
      @ O_ROW,O_COL SAY &OPT
      @ 23, 0
      @ 24, 0
      DO CASE
         CASE AT(choice,o_choice)>0
            EXIT
         CASE READKEY()=0.or.READKEY()=1
            o_x= IIF(READKEY()=0,o_x-1,o_x+1)
            o_x= IIF(o_x=0,o_x_max,o_x)
            o_x= IIF(o_x>o_x_max,1,o_x)
            o_col= 'O_COL'+CHR(o_x+64)
            O_COL=&O_COL
         CASE READKEY()=15
            choice= SUBSTR(o_choice,o_x,1)
            EXIT
         CASE READKEY()=2.or.READKEY()=3
            IF READKEY()=2
               choice= 'T'
            ELSE
               choice= 'B'
            ENDIF
            EXIT
         CASE READKEY()=5
            LOOP
         CASE READKEY()=6.or.READKEY()=7
            EXIT
         OTHERWISE
            &C_MESSAGE
            @ 24, 24 SAY ' '+choice+' is not an available choice. '
            ?? CHR(7)
      ENDCASE
   ENDDO
   DO CASE
      CASE choice='S'
         IF new
            &C_MESSAGE
            @ 23, 50 SAY ' Validating... '
            recno= RECNO()
            tkey= LTRIM(TRIM(key))
            SEEK tkey
            &C_CLEAR
            @ 23, 0
            IF .not. EOF()
               &C_CLEAR
               @ 21, 0
               confirm= ' '
               &C_GET
               @ 21, 12 SAY ' Please change Key Field, press any key to continue. ' GET confirm
               READ
               action= 'GET'
               choice= 'E'
               &C_CLEAR
               @ 21, 0
               &C_MESSAGE
               @ 21, 24 SAY ' NOTE: Please type your data. '
            ENDIF
         ENDIF
      CASE choice='E'
      CASE choice='D'
      CASE choice$'VNTB'
         IF action='GET'
            &C_MESSAGE
            IF new
               @ 22, 19 SAY ' Warning, this record is not yet saved. '
            ELSE
               @ 22, 14 SAY ' Warning, changes in this record is not yet saved. '
            ENDIF
            confirm= ' '
            &C_GET
            DO WHILE .not. confirm$'Y,N'
               @ 23, 27 SAY ' Continue anyway (Y/N)? ' GET confirm PICTURE '!'
               READ
            ENDDO
            &C_CLEAR
            @ 22, 0
            @ 23, 0
            IF confirm='N'
               LOOP
            ELSE
               action= 'SAY'
               new= .F.
            ENDIF
         ENDIF
         DO CASE
            CASE choice='V'
               IF .not. BOF()
                  SKIP  -1
                  DO RECLOCK1
                  IF confirm='N'
                     RETURN
                  ENDIF
               ENDIF
               IF BOF()
                  &C_MESSAGE
                  @ 23, 26 SAY ' Top of file encountered. '
                  ?? CHR(7)
                  GOTO TOP
                  LOOP
               ENDIF
            CASE choice='N'
               IF .not. EOF()
                  SKIP
                  DO RECLOCK1
                  IF confirm='N'
                     RETURN
                  ENDIF
               ENDIF
               IF EOF()
                  &C_MESSAGE
                  @ 23, 26 SAY ' End of file encountered. '
                  ?? CHR(7)
                  GOTO BOTTOM
                  LOOP
               ENDIF
            CASE choice='T'
               GOTO TOP
               DO RECLOCK1
            CASE choice='B'
               GOTO BOTTOM
               DO RECLOCK1
         ENDCASE
   ENDCASE
   RETURN
ENDDO

PROCEDURE menuopt3
IF action='GET'
   o_x= 1
   o_col= o_cola
ELSE
   *IF choice='T'
   *   choice= 'N'
   *ENDIF
   *IF choice='B'
   *   choice= 'V'
   *ENDIF
   o_x= AT(choice,o_choice)
   o_col= 'O_COL'+CHR(o_x+64)
   O_COL=&O_COL
ENDIF
DO WHILE .T.
   &C_CLEAR
   @ 22, 0
   DO WHILE .T.
      choice= ' '
      opt= 'OPT'+CHR(o_x+64)
      &C_CHOICE
      @ O_ROW,O_COL SAY &OPT
      @ o_row, o_col GET choice PICTURE '@!'
      READ
      &C_OPTION
      @ O_ROW,O_COL SAY &OPT
      @ 23, 0
      @ 24, 0
      DO CASE
         CASE AT(choice,o_choice)>0
            EXIT
         CASE READKEY()=0.or.READKEY()=1
            o_x= IIF(READKEY()=0,o_x-1,o_x+1)
            o_x= IIF(o_x=0,o_x_max,o_x)
            o_x= IIF(o_x>o_x_max,1,o_x)
            o_col= 'O_COL'+CHR(o_x+64)
            O_COL=&O_COL
         CASE READKEY()=15
            choice= SUBSTR(o_choice,o_x,1)
            EXIT
         CASE READKEY()=2.or.READKEY()=3
            IF READKEY()=2
               choice= 'T'
            ELSE
               choice= 'B'
            ENDIF
            EXIT
         CASE READKEY()=5
            LOOP
         CASE READKEY()=6.or.READKEY()=7
            EXIT
         OTHERWISE
            &C_MESSAGE
            @ 24, 24 SAY ' '+choice+' is not an available choice. '
            ?? CHR(7)
      ENDCASE
   ENDDO
   RETURN
ENDDO

PROCEDURE menuopt4
IF action='GET'
   o_x= 1
   o_col= o_cola
ELSE
   *IF choice='T'
   *   choice= 'N'
   *ENDIF
   *IF choice='B'
   *   choice= 'V'
   *ENDIF
   o_x= AT(choice,o_choice)
   o_col= 'O_COL'+CHR(o_x+64)
   O_COL=&O_COL
ENDIF
DO WHILE .T.
   &C_CLEAR
   @ 22, 0
   DO WHILE .T.
      choice= ' '
      opt= 'OPT'+CHR(o_x+64)
      &C_CHOICE
      @ O_ROW,O_COL SAY &OPT
      @ o_row, o_col GET choice PICTURE '@!'
      READ
      &C_OPTION
      @ O_ROW,O_COL SAY &OPT
      @ 23, 0
      @ 24, 0
      DO CASE
         CASE AT(choice,o_choice)>0
            EXIT
         CASE READKEY()=0.or.READKEY()=1
            o_x= IIF(READKEY()=0,o_x-1,o_x+1)
            o_x= IIF(o_x=0,o_x_max,o_x)
            o_x= IIF(o_x>o_x_max,1,o_x)
            o_col= 'O_COL'+CHR(o_x+64)
            O_COL=&O_COL
         CASE READKEY()=15
            choice= SUBSTR(o_choice,o_x,1)
            EXIT
         CASE READKEY()=2.or.READKEY()=3
            IF READKEY()=2
               choice= 'T'
            ELSE
               choice= 'B'
            ENDIF
            EXIT
         CASE READKEY()=5
            LOOP
         CASE READKEY()=6.or.READKEY()=7
            EXIT
         OTHERWISE
            &C_MESSAGE
            @ 24, 24 SAY ' '+choice+' is not an available choice. '
            ?? CHR(7)
      ENDCASE
   ENDDO
   RETURN
ENDDO

PROCEDURE option1
opta= ' Save '
optb= ' Edit '
optc= ' Delete '
optd= ' preV '
opte= ' Next '
optf= ' Abort '
o_cola= 24
o_colb= 30
o_colc= 36
o_cold= 44
o_cole= 50
o_colf= 56
o_row= 21
o_x_max= 6
o_choice= 'SEDVNA'
&C_CLEAR
@ o_row, 0
&C_OPTION
@ o_row, 15 SAY 'OPTIONS:  Save  Edit  Delete  preV  Next  Abort '
DO MENUOPT
RETURN

PROCEDURE option3
opta= ' Save '
optb= ' Edit '
optc= ' Delete '
optd= ' preV '
opte= ' Next '
optf= ' Abort '
optg= ' Print '
o_cola= 21
o_colb= 27
o_colc= 33
o_cold= 41
o_cole= 47
o_colf= 53
o_colg= 60
o_row= 21
o_x_max= 7
o_choice= 'SEDVNAP'
&C_CLEAR
@ o_row, 0
&C_OPTION
@ o_row, 12 SAY 'OPTIONS:  Save  Edit  Delete  preV  Next  Abort  Print '
DO MENUOPT1
RETURN

PROCEDURE option4
opta= ' Save '
optb= ' Edit '
optc= ' Delete '
optd= ' preV '
opte= ' Next '
optf= ' Abort '
optg= ' Print '
o_cola= 21
o_colb= 27
o_colc= 33
o_cold= 41
o_cole= 47
o_colf= 53
o_colg= 60
o_row= 21
o_x_max= 7
o_choice= 'SEDVNAP'
&C_CLEAR
@ o_row, 0
&C_OPTION
@ o_row, 12 SAY 'OPTIONS:  Save  Edit  Delete  preV  Next  Abort  Print '
DO MENUOPT
RETURN

PROCEDURE option6

*   @ 21,13 prompt " Top "
*   @ 21,18 prompt " Bottom "
*   @ 21,26 prompt " Next "
*   @ 21,32 prompt " Prev "
*   @ 21,38 prompt " Find "
*   @ 21,44 prompt " Add "
*   @ 21,49 prompt " Edit "
*   @ 21,55 prompt " Delete "
*   @ 21,63 prompt " Quit "

opta= ' Top '
optb= ' Bottom '
optc= ' Next '
optd= ' preV '
opte= ' Find '
optf= ' Add '
optg= ' Edit '
opth= ' Delete '
opti= ' Quit '
o_cola= 13
o_colb= 18
o_colc= 26
o_cold= 32
o_cole= 38
o_colf= 44
o_colg= 49
o_colh= 55
o_coli= 63
o_row = 21
o_x_max= 9
o_choice= 'TBNVFAEDQ'
&C_CLEAR
@ o_row, 0
&C_OPTION
@ o_row,14 SAY 'Top  Bottom  Next  preV  Find  Add  Edit  Delete  Quit'
DO MENUOPT3
RETURN

PROCEDURE option8
opta= ' dispLay '
optb= ' Print '
optc= ' Abort '
o_cola= 32
o_colb= 41
o_colc= 48
o_row= 21
o_x_max= 3
o_choice= 'LPA'
&C_CLEAR
@ o_row, 0
&C_OPTION
@ o_row, 23 SAY 'OPTIONS:  dispLay  Print  Abort '
DO MENUOPT
RETURN

PROCEDURE option2
opta= ' Print '
optb= ' Abort '
o_cola= 36
o_colb= 43
o_row= 21
o_x_max= 2
o_choice= 'PA'
&C_CLEAR
@ o_row, 0
&C_OPTION
@ o_row, 27 SAY 'OPTIONS:  Print  Abort '
DO MENUOPT
RETURN

PROCEDURE option9
opta= ' preV '
optb= ' Next '
optc= ' Abort '
o_cola= 34
o_colb= 40
o_colc= 46
o_row= 21
o_x_max= 3
o_choice= 'VNA'
&C_CLEAR
@ o_row, 0
&C_OPTION
@ o_row, 25 SAY 'OPTIONS:  preV  Next  Abort '
DO MENUOPT
RETURN

PROCEDURE option10
opta= ' Top '
optb= ' Bottom '
optc= ' Next '
optd= ' preV '
opte= ' Find '
optf= ' Move '
optg= ' Recall '
opth= ' Quit '
o_cola= 21
o_colb= 26
o_colc= 34
o_cold= 40
o_cole= 46
o_colf= 52
o_colg= 58
o_colh= 66
o_row= 21
o_x_max= 8
o_choice= 'TBNVFMRQ'
&C_CLEAR
@ o_row, 0   &&  1       2         3         4         5         6         7
&C_OPTION    &&  23456789012345678901234567890123456789012345678901234567890123456789
@ o_row, 12 SAY 'OPTIONS:  Top  Bottom  Next  preV  Find  Move  Recall  Quit'
DO MENUOPT3
RETURN

PROCEDURE option11
opta= ' Top '
optb= ' Bottom '
optc= ' Next '
optd= ' preV '
opte= ' Add '
optf= ' Edit '
optg= ' Del '
opth= ' Recall '
opti= ' Save/repl '
optj= ' Quit '
o_cola= 07
o_colb= 12
o_colc= 20
o_cold= 26
o_cole= 32
o_colf= 37
o_colg= 43
o_colh= 48
o_coli= 56
o_colj= 67
o_row= 21
o_x_max= 10
o_choice= 'TBNVAEDRSQ'
&C_CLEAR
@ o_row, 0   &&      1         2         3         4         5         6         7
&C_OPTION    &&  67890123456789012345678901234567890123456789012345678901234567890123456789
@ o_row, 08 SAY   'Top  Bottom  Next  preV  Add  Edit  Del  Recall  Save/repl  Quit'
DO MENUOPT3
RETURN

PROCEDURE option12
opta= ' Top '
optb= ' Bottom '
optc= ' Next '
optd= ' preV '
opte= ' Find '
optf= ' Remarks '
optg= ' Date '
opth= ' Quit '
o_cola= 15
o_colb= 20
o_colc= 28
o_cold= 34
o_cole= 40
o_colf= 46
o_colg= 55
o_colh= 61
o_row= 21
o_x_max= 8
o_choice= 'TBNVFRDQ'
&C_CLEAR
@ o_row, 0   &&      1         2         3         4         5         6         7
&C_OPTION    &&  67890123456789012345678901234567890123456789012345678901234567890123456789
@ o_row, 16 SAY           'Top  Bottom  Next  preV  Find  Remarks  Date  Quit'
DO MENUOPT3
RETURN

PROCEDURE option13
opta= ' Save '
optb= ' preV '
optc= ' Next '
optd= ' Abort '
o_cola= 30
o_colb= 36
o_colc= 42
o_cold= 48
o_row= 21
o_x_max= 7
o_choice= 'SVNA'
&C_CLEAR
@ o_row, 0
&C_OPTION
*                1         2         3         4         5
*                01234567890123456789012345678901234567890
@ o_row, 21 SAY            'OPTIONS:  Save  preV  Next  Abort '
DO MENUOPT4
RETURN

PROCEDURE keys
error= .F.
DO CASE
   CASE READKEY()=4
      IF row>9
         row= row-1
         SKIP  -1
         if bof()
            row=9
            go top
         endif
      else
           row=9
      ENDIF
   CASE READKEY()=5
      IF .not. EOF().and.row<18
         row= row+1
         SKIP
      ENDIF
   CASE READKEY()=6                  && page up
      &C_CLEAR
      @ 23, 0
      IF pg>0
         action= 'SAY'
         page= .T.
         pg= pg-1
         row= 9
         GOTO pg*10+1
         &C_CLEAR
         @ 9, 1 CLEAR TO 19, 78
      ELSE
         error= .T.
         &C_MESSAGE
         @ 23, 26 SAY ' Top of Page encountered. '
         pg=0
      ENDIF
   CASE READKEY()=7            && page down
      &C_CLEAR
      @ 23, 0
      IF pg*10+11<=RECCOUNT()
         action= 'SAY'
         page= .T.
         pg= pg+1
         row= 9
         GOTO pg*10+1
         &C_CLEAR
         @ 9, 1 CLEAR TO 19, 78
      ELSE
         error= .T.
         &C_MESSAGE
         @ 23, 26 SAY ' Last page encountered. '
         pg=int((reccount()-1)/10)
      ENDIF
ENDCASE
RETURN

PROCEDURE pagekey
IF READKEY()=6               && page-up
   action= 'GET'
   IF pg>0
      action= 'SAY'
      page= .T.
      pg= pg-1
      row= 9
      GOTO pg*10+1
      &C_CLEAR
      @ 9, 1 CLEAR TO 19, 78
   ENDIF
ELSE
   action= 'GET'
   IF pg*10+11<=RECCOUNT()
      action= 'SAY'
      page= .T.
      pg= pg+1
      row= 9
      GOTO pg*10+1
      &C_CLEAR
      @ 9, 1 CLEAR TO 19, 78
   ENDIF
ENDIF
choice= 'S'
RETURN

PROCEDURE err_fix
PARAMETER errnum, mess, curr_prg
DO CASE
   CASE errnum=130
      if type(field(1))<>"C"
         if type(field(2))<>"C"
            rec_m= FIELD(3)
         else
            rec_m= Field(2)
         endif
      else
         rec_m=field(1)
      endif

      &C_CLEAR
      @ 23, 0
      &C_MESSAGE
      DO WHILE .T.
         time= 0
         DO WHILE .not. RLOCK().and.time<2001
            time= time+1
            @ 23,40 SAY " No. of Attempts to Process " + TRIM(&REC_M) + ": " + LTRI(STR(TIME))
         ENDDO
         IF time<2001
            &C_CLEAR
            @ 23, 0
            &C_MESSAGE
            @ 23,50 SAY "Processing " + &REC_M
            RETRY
         ENDIF
         &C_CLEAR
         @ 21, 0
         @ 23, 0
         confirm= ' '
         &C_GET
         @ 21, 8 SAY ' Record is being use by another user, press any key to retry. ' GET confirm
         READ
      ENDDO
   CASE errnum=109
      rec_m= FIELD(1)
      &C_CLEAR
      @ 23, 0
      &C_MESSAGE
      DO WHILE .T.
         time= 0
         DO WHILE .not. RLOCK().and.time<2001
            time= time+1
            @ 23,40 SAY " No. of Attempts to Process " + TRIM(&REC_M) + ": " + LTRI(STR(TIME))
         ENDDO
         IF time<2001
            RETRY
         ENDIF
         &C_CLEAR
         @ 21, 0
         @ 23, 0
         confirm= ' '
         &C_GET
         @ 21, 8 SAY ' Record is being use by another user, press any key to retry. ' GET confirm
         READ
      ENDDO
   CASE errnum=1706.or.errnum=108
      &C_CLEAR
      @ 21, 0
      @ 23, 0
      &C_MESSAGE
      @ 21, 20 SAY ' File is exclusively use by other user. '
      confirm= ' '
      &C_GET
      DO WHILE .not. confirm$'YN'
         @ 23, 30 SAY ' Try again ( Y/N )? ' GET confirm PICTURE '!'
         READ
      ENDDO
      IF confirm='Y'
         RETRY
      ELSE
         error= .T.
         RETURN
      ENDIF
   CASE ERRNUM=1115
      RETURN
   OTHERWISE
      SAVE SCREEN TO TMPSCRN
      ? ERROR()
      ? MESS()
      ?
      ? 'Please press <ESC> and take note of the error. Contact admin!'
      ? 'Thank you.'
      ?
      WAIT
      RESTORE SCREEN FROM TMPSCRN
ENDCASE
RETURN

procedure TestPrt
if sys(13)="OFFLINE"
   SAVE SCREEN TO TMPSCRN
   atlsw2=0
   DO WHILE .T.
      if atlsw2=0
         set colo to b/b
         @ 12,11 clear to 15,69
         set colo to +gr/b
         @ 12,11 to 15,69
         set colo to +w/b,+gr/rb
         @ 13,14 say "   Printer is OFFLINE or currently Out of Paper...   "
         @ 14,14 say "     Fix the problem & press Enter to continue...    "
         atlsw2=1
      else
         set colo to rb/rb
         @ 12,11 clear to 15,69
         set colo to +gr/rb
         @ 12,11 to 15,69
         set colo to +w/rb,+gr/rb
         @ 13,14 say "   Printer is OFFLINE or currently Out of Paper...   "
         @ 14,14 say "     Fix the problem & press Enter to continue...    "
         atlsw2=0
      endif
      do while .t.
         keypress=inkey(0)
         if keypress=13
            exit
         endif
      enddo
      restore screen from tmpscrn
      if sys(13)<>"OFFLINE"
         exit
      endif
   enddo
endif
return         

*PROCEDURE option6
*
**   @ 21,13 prompt " Top "
**   @ 21,18 prompt " Bottom "
**   @ 21,26 prompt " Next "
**   @ 21,32 prompt " Prev "
**   @ 21,38 prompt " Find "
**   @ 21,44 prompt " Add "
**   @ 21,49 prompt " Edit "
**   @ 21,55 prompt " Delete "
**   @ 21,63 prompt " Quit "
*
*opta= ' Save '
*optb= ' Edit '
*optc= ' Remove '
*optd= ' Insert '
*opte= ' Copy '
*optf= ' Delete '
*optg= ' preV '
*opth= ' Next '
*opti= ' Abort '
*optj= ' Print '
*o_cola= 10
*o_colb= 16
*o_colc= 22
*o_cold= 30
*o_cole= 38
*o_colf= 44
*o_colg= 52
*o_colh= 58
*o_coli= 64
*o_colj= 71
*o_row= 21
*o_x_max= 10
*o_choice= 'SERICDVNAP'
*&C_CLEAR
*@ o_row, 0
*&C_OPTION
*@ o_row, 1 SAY 'OPTIONS:  Save  Edit  Remove  Insert  Copy  Delete  preV  Next  Abort  Print '
*DO MENUOPT
*RETURN


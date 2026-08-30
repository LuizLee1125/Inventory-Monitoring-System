* program.....: MnuAr.prg
* module......: accounts receivable
* revised.....: 03/19/99

PRIVATE ALL LIKE PRG??
PRIVATE ALL LIKE M_*

prg1a= 'A. Sales Invoice       '
*prg1b= 'B. Credit Memo         '
prg1b= 'B. Collections         '
prg1c= 'C. Sales Return        '
prg1d= 'D. Check Concerns      '
prg2a= 'N. Customer List       '
prg2b= 'O. Sales Summary       '
prg2c= 'P. Sales Ret. Summary  '
prg2d= 'Q. Collection Summary  '
prg2e= 'R. Accts. Receivable   '
prg3a= '1. Exit                '
prg3b= '2. Set Date            '
prg3c= '3. Set Exact           '
prg3d= '4. Set Printer         '

m_y_col1= 4
m_y_col2= 5
m_y_col3= 4
m_col1= 4
m_col2= 29
m_col3= 54
m_x= 1
m_y= 1
m_col= m_col1
m_row= 8
m_x_max= 3
m_y_max= m_y_col1

DO WHILE .T.
   &C_CLEAR
   CLEAR
   &C_BRDR
   @ 0, 15 TO 3, 64 DOUBLE
   * &C_HEAD
   set colo to +w/rb
   @ 1, 16 SAY SPACE(48)
   @ 1, 16 SAY SPACE((48-LEN(company))/2)+company
   @ 2, 16 SAY '      ACCOUNTS RECEIVABLE MONITORING SYSTEM     '
   &C_BRDR
   @ 4, 2 TO 23, 78
   @ 6, 3 TO 22, 27
   @ 5, 4 TO 7, 26 DOUBLE
   &C_HEAD
   @ 6, 5 SAY '    TRANSACTIONS     '
   &C_BRDR
   @ 6, 28 TO 22, 52
   @ 5, 29 TO 7, 51 DOUBLE
   &C_HEAD

   @ 6, 30 SAY '      REPORTS        '
   &C_BRDR
   @ 6, 53 TO 22, 77
   @ 5, 54 TO 7, 76 DOUBLE
   &C_HEAD
   @ 6, 55 SAY '        OTHERS       '
   &C_OPTION
   @  9,  4 SAY prg1a
   @ 10,  4 SAY prg1b
   @ 11,  4 SAY prg1c
   @ 12,  4 SAY prg1d
   @  9, 29 SAY prg2a
   @ 10, 29 SAY prg2b
   @ 11, 29 SAY prg2c
   @ 12, 29 SAY prg2d
   @ 13, 29 SAY prg2e
   @  9, 54 SAY prg3a
   @ 10, 54 SAY prg3b
   @ 11, 54 SAY prg3c
   @ 12, 54 SAY prg3d
   DO MENU3C
   prg= choice
   DO CASE
      CASE choice='PRG1A'
         DO SIFYLP
     *CASE choice='PRG1B'
     *   DO CMFYL
      CASE choice='PRG1B'
         DO COLCFYL
      CASE choice='PRG1C'
         DO SRFYL
      CASE choice='PRG1D'
         DO MNUCHKS

      CASE choice='PRG2A'
         DO MNUCUSTR
      CASE choice='PRG2B'
         DO MNUSALER
      CASE choice='PRG2C'
         DO MNUSR
      CASE choice='PRG2D'
         DO MNUCOLR
      CASE choice='PRG2E'
         DO MNUAR1
      CASE choice='PRG3A'
         CLOSE DATABASE
         SELECT 1
         RETURN
      CASE choice='PRG3B'
         RUN DATEUPD
      CASE choice='PRG3C'
         DO SETEXACT
      CASE choice='PRG3D'
         DO SETPRINT
   ENDCASE
   CLOSE DATABASE
   SELECT 1
ENDDO
 

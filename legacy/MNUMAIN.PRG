* program.....: MnuMain.prg
*             : menu for password maintenance;
*             : individual rebuilding of indeces
*             : 11/05/99

PRIVATE ALL LIKE PRG??
PRIVATE ALL LIKE M_*
prg1a= 'A] Password File       '
prg1b= 'B] Rebuild  File       '
prg1c= 'C] Exit                '
m_y_col1= 3
m_y_col2= 0
m_y_col3= 0
m_col1= 29
m_x= 1
m_y= 1
m_col= m_col1
m_row= 8
m_x_max= 1
m_y_max= m_y_col1

DO WHILE .T.
   &C_CLEAR
   CLEAR
   &C_BRDR
   @ 6, 28 TO 18, 52 DOUBLE
   @ 5, 29 TO 7, 51 DOUBLE
   &C_HEAD
   @ 6, 30 SAY '      MAIN MENU      '
   &C_OPTION
   @ 9, 29  SAY prg1a
   @ 10, 29 SAY prg1b
   @ 11, 29 SAY prg1c
   DO MENU3C
   prg= choice
   DO CASE
      CASE choice='PRG1A'
         DO PASSFYL
      CASE choice='PRG1B'
         DO MNURBILD
      CASE choice='PRG1C'
         RETURN
   ENDCASE
   CLOSE DATABASE
   SELECT 1
ENDDO
 
RETURN

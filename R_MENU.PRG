* program.....: R_MENU.PRG
*             : submenu for REACTIVATION
*             : 05/14/11

PRIVATE ALL LIKE PRG??
PRIVATE ALL LIKE M_*
prg1a= 'A] Reactivate Stocks   '
prg1b= 'B] Reactivate Customer '
prg1c= 'C] Reactivate Supplier '
prg1d= 'D] Reactivate S.R.     '
prg1e= 'E] Exit                '
m_y_col1= 5
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
   @ 6, 30 SAY '  ARCHIVED RECORDS   '
   &C_OPTION
   @  9, 29 SAY prg1a
   @ 10, 29 SAY prg1b
   @ 11, 29 SAY prg1c
   @ 12, 29 SAY prg1d
   @ 13, 29 SAY prg1e
  *@ 14, 29 SAY prg1f
  *@ 15, 29 SAY prg1g
  *@ 16, 29 SAY prg1h
   DO MENU3C
   prg= choice
   DO CASE
      CASE choice='PRG1A'
         DO R_STKFYL
      CASE choice='PRG1B'
         DO R_CUSFYL
      CASE choice='PRG1C'
         DO R_SPLYR
      CASE choice='PRG1D'
      CASE choice='PRG1E'
         RETURN
   ENDCASE
   CLOSE DATABASE
   SELECT 1
ENDDO
 

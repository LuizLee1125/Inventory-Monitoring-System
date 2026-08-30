* program.....: MnuColR.prg
*               called from Accts. Receivable; collection reports

PRIVATE ALL LIKE PRG??
PRIVATE ALL LIKE M_*
prg1a= 'A] Col. per Customer   '
prg1b= 'B] Col. per Territory  '
prg1c= 'C] %Per Territory/Cust '
prg1d= 'D] %Per Customer only  '
prg1e= 'E] Col. Percentage     '
prg1f= 'F] Col. Percentage GZT '
prg1g= 'G] Checks for Deposit  '
prg1h= 'H] Cash Collection     '
prg1i= 'I] Exit                '
m_y_col1= 9
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
   @ 6, 30 SAY '  COLLECTION SUMMARY '
   &C_OPTION
   @ 9,  29 SAY prg1a
   @ 10, 29 SAY prg1b
   @ 11, 29 SAY prg1c
   @ 12, 29 SAY prg1d
   @ 13, 29 SAY prg1e
   @ 14, 29 SAY prg1f
   @ 15, 29 say prg1g
   @ 16, 29 say prg1h
   @ 17, 29 say prg1i
   DO MENU3C
   prg= choice
   DO CASE
      CASE choice='PRG1A'
         DO LSTCOLC
      CASE choice='PRG1B'
         DO LSTCOLS
      CASE choice='PRG1C'
         DO LSTCOL%2
      CASE choice='PRG1D'
         DO LSTCOL%4
      CASE choice='PRG1E'
         DO LSTCOL%1
      CASE choice='PRG1F'
         DO LSTCOL%5
      CASE choice='PRG1G'
         DO LSTCHKS
      case choice='PRG1H'
         do lstcash
      CASE choice='PRG1I'
         RETURN
   ENDCASE
   CLOSE DATABASE
   SELECT 1
ENDDO

return

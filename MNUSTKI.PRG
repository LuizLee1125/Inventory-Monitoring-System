* program.....: MnuStkI.prg
*             : submenu of Stock inquiry; called from MnuInvs.prg

PRIVATE ALL LIKE PRG??
PRIVATE ALL LIKE M_*
prg1a= 'A] Stock List          '
prg1b= 'B] Transfer List       '
prg1c= 'C] Re-order List       '
prg1d= 'D] Promo -  Form       '
prg1e= 'E] Promo -  List       '
prg1f= 'F] Purchase Form       '
prg1g= 'G] Inventory Control   '
prg1h= 'H] Exit                '

m_y_col1= 8
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
   @ 6, 30 SAY '    STOCK INQUIRY    '
   &C_OPTION
   @ 9, 29 SAY prg1a
   @ 10, 29 SAY prg1b
   @ 11, 29 SAY prg1c
   @ 12, 29 SAY prg1d
   @ 13, 29 SAY prg1e
   @ 14, 29 SAY prg1f
   @ 15, 29 SAY prg1g
   @ 16, 29 SAY prg1h
   DO MENU3C
   prg= choice
   DO CASE
      CASE choice='PRG1A'
         DO LSTSTK
      CASE choice='PRG1B'
         DO LSTTRAN
      CASE choice='PRG1C'
         DO LSTLSTK
      CASE choice='PRG1D'
         DO LSTPROF
      CASE choice='PRG1E'
         DO LSTPROL
      CASE choice='PRG1F'
         DO LSTPURF
      CASE choice='PRG1G'
         DO LSTINVC
      CASE choice='PRG1H'
         RETURN
   ENDCASE
   CLOSE DATABASE
   SELECT 1
ENDDO
 

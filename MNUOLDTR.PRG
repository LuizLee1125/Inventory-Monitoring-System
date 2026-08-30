* program.....: MnuOldTr.prg
*             : submenu for old transactions
*             : 12/14/99; modified 07/26/06 - old sales/item/cust

PRIVATE ALL LIKE PRG??
PRIVATE ALL LIKE M_*
prg1a= 'A] Old Stock File      '
prg1b= 'B] Old Sales Invoice   '
prg1c= 'C] Old Sales/Item/Cust '
prg1d= 'D] Old Purchases       '
prg1e= 'E] Old Customers       '
prg1f= 'F] Old Suppliers       '
prg1g= 'G] Reactivate Records  '
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
   @ 6, 30 SAY '  ARCHIVED RECORDS   '
   &C_OPTION
   @  9, 29 SAY prg1a
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
         DO O_STKFYL
      CASE choice='PRG1B'
         DO O_SIFYL
      CASE choice='PRG1C'
         Do Lstosic2
      CASE choice='PRG1D'
         DO O_PURFYL
      CASE choice='PRG1E'
         DO O_CUST
      CASE choice='PRG1F'
         DO O_SUPP
      CASE choice='PRG1G'
         DO R_MENU
      CASE choice='PRG1H'
         RETURN
   ENDCASE
   CLOSE DATABASE
   SELECT 1
ENDDO
 

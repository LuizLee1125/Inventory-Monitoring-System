* program.....: MnuInvs.prg
*             : main menu of inventory for admin
*             : 07/25/99

PRIVATE ALL LIKE PRG??
PRIVATE ALL LIKE M_*

prg1a= 'A. Customer File       '
prg1b= 'B. Invoice Maintenance '
prg1c= 'C. Sales Return        '
prg1d= 'D. Collections         '
prg1e= 'E. Archived Records    '

prg2a= 'N. Price Inquiry       '
prg2b= 'O. Stock Inquiry       '
prg2c= 'P. Inventory           '
prg2d= 'Q. Customer List       '
prg2e= 'R. Sales Summary       '
prg2f= 'S. Purchased Items     '
prg2g= 'T. Sales Return Summ.  '
prg2h= 'U. Accounts Receivable '
prg2i= 'V. Collection Summary  '
prg2j= 'W. Inactive Customers  '

prg3a= '1. Exit                '
prg3b= '2. Expiration Inquiry  '
prg3c= '3. Depleted Stocks     '
prg3d= '4. Archive Inquiry     '
prg3e= '5. Set Printer Mode    '

m_y_col1= 05
m_y_col2= 10
m_y_col3= 05
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
   SET COLO TO +w/+RB
   @ 1, 16 SAY SPACE(48)
   @ 1, 16 SAY SPACE((48-LEN(company))/2)+company
   @ 2, 16 SAY '           Inventory Monitoring System          '
   &C_BRDR
   @ 4, 2 TO 23, 78
   @ 6, 3 TO 22, 27
   @ 5, 4 TO 7, 26 DOUBLE
   &C_HEAD
   @ 6, 5 SAY '    Transactions     '
   &C_BRDR
   @ 6, 28 TO 22, 52
   @ 5, 29 TO 7, 51 DOUBLE
   &C_HEAD
   @ 6, 30 SAY '      Reports        '
   &C_BRDR
   @ 6, 53 TO 22, 77
   @ 5, 54 TO 7, 76 DOUBLE
   &C_HEAD
   @ 6, 55 SAY '    Maintenance      '
   &C_OPTION
   @  9,  4 SAY prg1a
   @ 10,  4 SAY prg1b
   @ 11,  4 SAY prg1c
   @ 12,  4 SAY prg1d
   @ 13,  4 SAY prg1e
   @  9, 29 SAY prg2a
   @ 10, 29 SAY prg2b
   @ 11, 29 SAY prg2c
   @ 12, 29 SAY prg2d
   @ 13, 29 SAY prg2e
   @ 14, 29 SAY prg2f
   @ 15, 29 SAY prg2g
   @ 16, 29 SAY prg2h
   @ 17, 29 SAY prg2i
   @ 18, 29 SAY prg2j
   @  9, 54 SAY prg3a
   @ 10, 54 SAY prg3b
   @ 11, 54 SAY prg3c
   @ 12, 54 SAY prg3d
   @ 13, 54 SAY prg3e
   DO MENU3C
   prg= choice
   DO CASE
      CASE choice='PRG1A'
         DO CUSTFYL
      CASE choice='PRG1B'
         DO SIFYL2
      CASE choice='PRG1C'
         DO SRFYL
      CASE choice='PRG1D'
         DO COLCFYL
      CASE choice='PRG1E'
         DO MNUOLDT2
      CASE choice='PRG2A'
         DO MNUPRYSI
      CASE choice='PRG2B'
         DO MNUSTKI
      CASE choice='PRG2C'
         DO MNUINVR
      CASE choice='PRG2D'
         DO LSTCUST
      CASE choice='PRG2E'
         DO MNUSALER
      CASE choice='PRG2F'
         DO STKPURCH
      CASE choice='PRG2G'
         DO MNUSR2
      CASE choice='PRG2H'
         DO MNUAR1
      CASE choice='PRG2I'
         DO MNUCOLR
      case choice='PRG2J'
         DO LSTAR2
      CASE choice='PRG3A'
         CLOSE DATABASE
         SELECT 1
         RETURN
      CASE choice='PRG3B'
         DO LSTEXP
      CASE CHOICE='PRG3C'
         DO LSTDEP
      CASE CHOICE='PRG3D'
         DO MNUARCH2
      CASE CHOICE='PRG3E'
         DO SETPRINT


   ENDCASE
   CLOSE DATABASE
   SELECT 1
ENDDO

RETURN

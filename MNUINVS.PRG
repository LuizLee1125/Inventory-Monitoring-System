* program.....: MnuInvs.prg
*             : main menu of inventory for admin
*             : 07/25/99

PRIVATE ALL LIKE PRG??
PRIVATE ALL LIKE M_*

prg1a= 'A. Stock File          '
prg1b= 'B. Customer File       '
prg1c= 'C. Supplier File       '
prg1d= 'D. Invoice Maintenance '
prg1e= 'E. Purchase Invoice    '
*prg1f= 'F. Purchase Invoice 2  '
prg1f= 'F. Sales Return        '
prg1g= 'G. Collections         '
prg1h= 'H. Archived Records    '
prg1i= 'I. Bad Accounts        '

prg2a= 'N. Price Inquiry       '
prg2b= 'O. Stock Inquiry       '
prg2c= 'P. Inventory           '
prg2d= 'Q. Customer List       '
prg2e= 'R. Supplier List       '
prg2f= 'S. Sales Summary       '
prg2g= 'T. Purchase Summary    '
prg2h= 'U. Purchased Items     '
prg2i= 'V. Sales Return Summ.  '
prg2j= 'W. Accounts Receivable '
prg2k= 'X. Collection Summary  '
prg2l= 'Y. Inactive Customers  '

*prg3b= '2. Set Date            '
*prg3c= '3. Set Exact           '
*prg3d= '4. Set Printer         '

prg3a= '1. Exit                '
prg3b= '2. Purging of Records  '
prg3c= '3. Code Revisions      '
prg3d= '4. ReIndex Files       '
prg3e= '5. Back-up Files       '
prg3f= '6. Expiration Inquiry  '
prg3g= '7. Depleted Stocks     '
prg3h= '8. Archive Inquiry     '
prg3i= '9. Set Printer Mode    '

m_y_col1= 08
m_y_col2= 12
m_y_col3= 09
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
   @ 14,  4 SAY prg1f
   @ 15,  4 SAY prg1g
   @ 16,  4 SAY prg1h
  *@ 17,  4 say prg1i
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
   @ 19, 29 say prg2k
   @ 20, 29 SAY prg2l
   @  9, 54 SAY prg3a
   @ 10, 54 SAY prg3b
   @ 11, 54 SAY prg3c
   @ 12, 54 SAY prg3d
   @ 13, 54 SAY prg3e
   @ 14, 54 SAY prg3f
   @ 15, 54 SAY prg3g
   @ 16, 54 SAY prg3h
   @ 17, 54 SAY prg3i
   DO MENU3C
   prg= choice
   DO CASE
      CASE choice='PRG1A'
         DO MNUSTK
      CASE choice='PRG1B'
         DO CUSTFYL
      CASE choice='PRG1C'
         DO SPLYRFYL
      CASE choice='PRG1D'
         DO SIFYL2
      CASE choice='PRG1E'
         DO PURFYL
      case choice='PRG1F'
         DO SRFYL
      CASE choice='PRG1G'
         DO COLCFYL
      CASE choice='PRG1H'
         DO MNUOLDTR
      CASE choice='PRG2A'
         DO MNUPRYSI
      CASE choice='PRG2B'
         DO MNUSTKI
      CASE choice='PRG2C'
         DO MNUINVR
      CASE choice='PRG2D'
         DO LSTCUST
      CASE choice='PRG2E'
         DO LSTSPLYR
      CASE choice='PRG2F'
         DO MNUSALER
      CASE choice='PRG2G'
         DO MNUPURS
      CASE choice='PRG2H'
         DO STKPURCH
      CASE choice='PRG2I'
         DO MNUSR
      CASE choice='PRG2J'
         DO MNUAR1
      CASE choice='PRG2K'
         DO MNUCOLR
      case choice='PRG2L'
         DO LSTAR2
      CASE choice='PRG3A'
         CLOSE DATABASE
         SELECT 1
         RETURN
      CASE choice='PRG3B'
     *   RUN DATEUPD
     *CASE choice='PRG3C'
     *   DO SETEXACT
     *CASE choice='PRG3D'
     *   DO SETPRINT
     *CASE choice='PRG3E'
         DO MNUPURGE
      CASE choice='PRG3C'
         DO MNU_CREV
      CASE CHOICE='PRG3D'
         DO RBILDALL
      CASE CHOICE='PRG3E'
         DO BACKDATA
      CASE CHOICE='PRG3F'
         DO LSTEXP
      CASE CHOICE='PRG3G'
         DO LSTDEP
      CASE CHOICE='PRG3H'
         DO MNUARCH
      CASE CHOICE='PRG3I'
         DO SETPRINT


   ENDCASE
   CLOSE DATABASE
   SELECT 1
ENDDO

RETURN

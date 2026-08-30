* program.....: MnuPurge.prg

PRIVATE ALL LIKE PRG??
PRIVATE ALL LIKE M_*
prg1a= 'A] Purge Stocks        '
prg1b= 'B] Purge Customers     '
prg1c= 'C] Purge Suppliers     '
prg1d= 'D] Purge Transactions  '
prg1e= 'E] Purge Sales Return  '
prg1f= 'F] Exit                '
m_y_col1= 6
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
    @ 6, 30 SAY '  SALES ORDER MENU   '
    &C_OPTION
    @  9, 29 SAY prg1a
    @ 10, 29 SAY prg1b
    @ 11, 29 SAY prg1c
    @ 12, 29 SAY prg1d
    @ 13, 29 SAY prg1e
    @ 14, 29 say prg1f
    *@ 15, 29 say prg1g
    DO MENU3C
    prg= choice
    DO CASE
        CASE choice='PRG1A'
            DO STKMPURG
        CASE choice='PRG1B'
            DO CUSPURGE
        CASE choice='PRG1C'
            DO SPLYRPUR
        CASE choice='PRG1D'
            DO STKPURGE
        CASE choice='PRG1E'
            DO SRPURGE
        CASE choice='PRG1F'
        *    DO EX_INCEN
        *otherwise
            RETURN
    ENDCASE
    CLOSE DATABASE
ENDDO
 

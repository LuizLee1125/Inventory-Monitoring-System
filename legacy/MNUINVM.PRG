* program.....: MnuInvM.prg

PRIVATE ALL LIKE PRG??
PRIVATE ALL LIKE M_*
prg1a= 'A] Inventory Adjustment'
prg1b= 'B] Bodega Requisition  '
prg1c= 'C] Bodega Transfer     '
prg2a= 'N] Price Inquiry       '
prg2b= 'O] Stock Inquiry       '
prg2c= 'P] Inventory           '
prg3a= '1] Exit                '
prg3b= '2] Set Date            '
prg3c= '3] Set Exact           '
m_y_col1= 3
m_y_col2= 3
m_y_col3= 3
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
    &C_HEAD
    @ 1, 16 SAY SPACE(48)
    @ 1, 16 SAY SPACE((48-LEN(company))/2)+company
    @ 2, 16 SAY '            INVENTORY MONITORING MENU           '
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
    @ 6, 53 TO 18, 77
    @ 5, 54 TO 7, 76 DOUBLE
    &C_HEAD
    @ 6, 55 SAY '    MAINTENANCE      '
    &C_OPTION
    @ 9, 4 SAY prg1a
    @ 10, 4 SAY prg1b
    @ 11, 4 SAY prg1c
    @ 9, 29 SAY prg2a
    @ 10, 29 SAY prg2b
    @ 11, 29 SAY prg2c
    @ 9, 54 SAY prg3a
    @ 10, 54 SAY prg3b
    @ 11, 54 SAY prg3c
    DO MENU3C
    prg= choice
    DO CASE
        CASE choice='PRG1A'
            DO INVADJ
        CASE choice='PRG1B'
            DO BODGAREQ
        CASE choice='PRG1C'
            DO BODGAFYL
        CASE choice='PRG2A'
            DO MNUPRYSI
        CASE choice='PRG2B'
            DO MNUSTKI
        CASE choice='PRG2C'
            DO MNUINVR
        CASE choice='PRG3A'
            CLOSE DATABASE
            SELECT 1
            RETURN
        CASE choice='PRG3B'
            DO REBUILD
    ENDCASE
    CLOSE DATABASE
    SELECT 1
ENDDO
 

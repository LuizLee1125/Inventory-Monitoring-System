* program.....: MnuSiM.prg

PRIVATE ALL LIKE PRG??
PRIVATE ALL LIKE M_*
prg1a= 'A] Sales Order         '
prg1b= 'B] Process Sales Order '
prg1c= 'C] Sales Invoice       '
prg1d= 'D] Sales Return        '
prg1e= 'E] Inventory Adjustment'
prg2a= 'N] Sales Summary       '
prg2b= 'O] Sales per Customer  '
prg2c= 'P] Sales per Territory '
prg2d= 'Q] Sales per Item      '
prg3a= '1] Exit                '
prg3b= '2] Set Date            '
prg3c= '3] Set Exact           '
m_y_col1= 5
m_y_col2= 4
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
    @ 2, 16 SAY '              SALES MONITORING MENU             '
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
    @ 12, 4 SAY prg1d
    @ 13, 4 SAY prg1e
    @ 9, 29 SAY prg2a
    @ 10, 29 SAY prg2b
    @ 11, 29 SAY prg2c
    @ 12, 29 SAY prg2d
    @ 9, 54 SAY prg3a
    @ 10, 54 SAY prg3b
    @ 11, 54 SAY prg3c
    DO MENU3C
    prg= choice
    DO CASE
        CASE choice='PRG1A'
            DO MNUSO
        CASE choice='PRG1B'
            DO MNUPROSO
        CASE choice='PRG1C'
            DO SIFYL1
        CASE choice='PRG1D'
        CASE choice='PRG1E'
            DO INVADJ
        CASE choice='PRG2A'
            DO LSTSALE
        CASE choice='PRG2B'
            DO LSTSALEC
        CASE choice='PRG2C'
            DO LSTSALES
        CASE choice='PRG2D'
            DO LSTSALEI
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
 

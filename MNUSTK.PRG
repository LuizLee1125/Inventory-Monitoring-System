* program.....: MnuStk.prg

PRIVATE ALL LIKE PRG??
PRIVATE ALL LIKE M_*
prg1a= 'A] Stock File          '
prg1b= 'B] Price Adjustment    '
prg1c= 'C] Inventory Adjustment'
prg1d= 'D] Exit                '
m_y_col1= 4
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
    @ 6, 30 SAY '     STOCK FILE      '
    &C_OPTION
    @ 9, 29 SAY prg1a
    @ 10, 29 SAY prg1b
    @ 11, 29 SAY prg1c
    @ 12, 29 SAY prg1d
    DO MENU3C
    prg= choice
    DO CASE
        CASE choice='PRG1A'
            DO STKFYL
        CASE choice='PRG1B'
            DO PRYSADJ
        CASE choice='PRG1C'
            DO INVADJ
        CASE choice='PRG1D'
            RETURN
    ENDCASE
    CLOSE DATABASE
    SELECT 1
ENDDO
 

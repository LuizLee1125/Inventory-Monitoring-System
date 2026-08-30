* program.....: MnuInvR.prg

PRIVATE ALL LIKE PRG??
PRIVATE ALL LIKE M_*
prg1a= 'A] Inventory Summary   '
prg1b= 'B] Inventory Bodega 1  '
prg1c= 'C] Inventory Bodega 2  '
prg1d= 'D] Inventory Bodega 3  '
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
    @ 6, 30 SAY '  INVENTORY SUMMARY  '
    &C_OPTION
    @ 9, 29 SAY prg1a
    @ 10, 29 SAY prg1b
    @ 11, 29 SAY prg1c
    @ 12, 29 SAY prg1d
    @ 13, 29 SAY prg1e
    DO MENU3C
    prg= choice
    DO CASE
        CASE choice='PRG1A'
            DO LSTINV
        CASE choice='PRG1B'
            DO LSTINV1
        CASE choice='PRG1C'
            DO LSTINV1
        CASE choice='PRG1D'
            DO LSTINV1
        CASE choice='PRG1E'
            RETURN
    ENDCASE
    CLOSE DATABASE
    SELECT 1
ENDDO
 

* program.....: MnuArch.prg
*             : submenu of archive - reports

PRIVATE ALL LIKE PRG??
PRIVATE ALL LIKE M_*
prg1a= 'A] Inventory Control   '
prg1b= 'B] Purchase Summary    '
prg1c= 'C] Sales Summary       '
prg1d= 'D] Sales Per Category  '
prg1e= 'E] Sales Per Division  '
prg1f= 'F] Sales Per Item      '
prg1g= 'G] Sales Per Customer  '
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
    @ 6, 28 TO 19, 52 DOUBLE
    @ 5, 29 TO 7, 51 DOUBLE
    &C_HEAD
    @ 6, 30 SAY '  INQUIRY - ARCHIVE  '
    &C_OPTION
    @ 9, 29 SAY prg1a
    @ 10, 29 SAY prg1b
    @ 11, 29 SAY prg1c
    @ 12, 29 SAY prg1d
    @ 13, 29 SAY prg1e
    @ 14, 29 say prg1f
    @ 15, 29 say prg1g
    @ 16, 29 say prg1h
    DO MENU3C
    prg= choice
    DO CASE
        CASE choice='PRG1A'
            DO OLSTINV
        CASE choice='PRG1B'
            DO OLDPURS
        CASE choice='PRG1C'
            DO OLDSSUM
        CASE choice='PRG1D'
            DO OLDSCAT
        CASE choice='PRG1E'
            DO OLDSDIV
        CASE choice='PRG1F'
            DO OLSTSALE
        CASE choice='PRG1G'
            DO OLDSCUST
        CASE choice='PRG1H'
            RETURN
    ENDCASE
    CLOSE DATABASE
    SELECT 1
ENDDO
 

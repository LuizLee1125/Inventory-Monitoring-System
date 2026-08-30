* program.....: MnuCRev.prg

PRIVATE ALL LIKE PRG??
PRIVATE ALL LIKE M_*

prg1a= 'A] Change Invoice No.  '
prg1b= 'B] Change Rem/Date/Paid'
prg1c= 'C] Change Discounts    '
prg1d= 'D] Exit                '

m_y_col1= 4
m_y_col2= 0
m_y_col3= 0
m_col1= 29
m_x= 1
m_y= 1
m_col= m_col1
m_row= 7
m_x_max= 1
m_y_max= m_y_col1
DO WHILE .T.
    &C_CLEAR
    CLEAR
    &C_BRDR
    @ 5, 28 TO 13, 52 DOUBLE
    @ 4, 29 TO 6, 51 DOUBLE
    &C_HEAD
    @ 5, 30 SAY ' S.I. REVISION MENU  '
    &C_OPTION
    @  8, 29 SAY prg1a
    @  9, 29 SAY prg1b
    @ 10, 29 SAY prg1c
    @ 11, 29 SAY prg1d
    DO MENU3C
    prg= choice
    DO CASE
        CASE choice='PRG1A'
            DO REP_INV
        CASE choice='PRG1B'
            DO sifylp2
        CASE choice='PRG1C'
            DO SIFYL3
        case choice='PRG1D'
            RETURN
    ENDCASE
    CLOSE DATABASE
ENDDO
 

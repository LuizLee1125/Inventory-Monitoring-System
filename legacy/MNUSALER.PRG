* program.....: MnuSaleR.prg
*             : 07/21/2000

PRIVATE ALL LIKE PRG??
PRIVATE ALL LIKE M_*
prg1a= 'A] Sales Summary       '
prg1b= 'B] Sales Summary - Ref '
prg1c= 'C] Sales Per Category  '
prg1d= 'D] Sales Per Division  '
prg1e= 'E] Sales Per Customer  '
prg1f= 'F] Sales Per Supplier  '
prg1g= 'G] Sales Per Item      '
prg1h= 'H] Sales Per Item/Cust '
prg1i= 'I] Sales by  Customer  '
prg1j= 'J] Sales Per Territory '
prg1k= 'K] Sales Per TMarketer '
prg1l= 'L] Exit                '
m_y_col1= 12
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
    @ 6, 28 TO 20, 52 DOUBLE
    @ 5, 29 TO 7, 51 DOUBLE
    &C_HEAD
    @ 6, 30 SAY '    SALES SUMMARY    '
    &C_OPTION
    @ 8,  29 SAY prg1a
    @ 9,  29 SAY prg1b
    @ 10, 29 SAY prg1c
    @ 11, 29 SAY prg1d
    @ 12, 29 SAY prg1e
    @ 13, 29 SAY prg1f
    @ 14, 29 SAY prg1g
    @ 15, 29 say prg1h
    @ 16, 29 say prg1i
    @ 17, 29 say prg1j
    @ 18, 29 say prg1k
    @ 19, 29 say prg1l
    DO MENU3C
    prg= choice
    DO CASE
        CASE choice='PRG1A'
            DO LSTSALE
        CASE choice='PRG1B'
            DO LSTSALE2
        CASE choice='PRG1C'
            DO LSTCAT
        CASE choice='PRG1D'
            DO LSTDIV
        CASE choice='PRG1E'
            DO LSTSALEC
        CASE choice='PRG1F'
            DO MNUSLSUP
            *DO LSTSUPP
        CASE choice='PRG1G'
            DO LSTSALEI
        CASE choice='PRG1H'
            DO LstSalic
        CASE choice='PRG1I'
            DO LSTSALBC
        CASE choice='PRG1J'
            DO MNUSALTE
        CASE choice='PRG1K'
            DO LSTSALEM
        CASE choice='PRG1L'
            RETURN
    ENDCASE
    CLOSE DATABASE
    SELECT 1
ENDDO
 
return

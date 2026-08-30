* program.....: Mnuso.prg

PRIVATE ALL LIKE PRG??
PRIVATE ALL LIKE M_*
prg1a= 'A] Print Sales Invoice '
prg1b= 'B] View Purchases      '
prg1c= 'C] Exit                '
m_y_col1= 3
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
    @ 9, 29 SAY prg1a
    @ 10,29 SAY prg1b
    @ 11,29 say prg1c
    DO MENU3C
    prg= choice
    DO CASE
        CASE choice='PRG1A'
            DO SIFYL
        CASE choice='PRG1B'
            Do StkPurch
        otherwise
            RETURN
    ENDCASE
    CLOSE DATABASE
ENDDO
 

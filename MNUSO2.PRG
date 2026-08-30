* program.....: Mnuso2.prg
*               contains invoicing and accounts receivables

PRIVATE ALL LIKE PRG??
PRIVATE ALL LIKE M_*
prg1a= 'A] Print Sales Invoice '
prg1b= 'B] Stock Purchase List '
prg1c= 'C] Sales Return Entry  '
prg1d= 'D] Statements of Accts '
prg1e= 'E] Aging of AR         '
prg1f= 'F] Sales Per Item/Cust '
prg1g= 'G] Archive Records     '
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
    @ 6, 28 TO 18, 52 DOUBLE
    @ 5, 29 TO 7, 51 DOUBLE
    &C_HEAD
    @ 6, 30 SAY '  SALES / AR  MENU   '
    &C_OPTION
    @ 9, 29 SAY prg1a
    @ 10,29 SAY prg1b
    @ 11,29 say prg1c
    @ 12,29 say prg1d
    @ 13,29 say prg1e
    @ 14,29 say prg1f
    @ 15,29 say prg1g
    @ 16,29 say prg1h
    DO MENU3C
    prg= choice
    DO CASE
        CASE choice='PRG1A'
            DO SIFYL
        CASE choice='PRG1B'
            Do StkPurch
        case choice='PRG1C'
            Do SRFyl
        case choice='PRG1D'
            Do LstSa
        case choice='PRG1E'
            Do LstAR
        case choice='PRG1F'
            Do LstSalic
        case choice='PRG1G'
            Do MnuOldT2
        case choice='PRG1H'
            RETURN
    ENDCASE
    CLOSE DATABASE
ENDDO
 

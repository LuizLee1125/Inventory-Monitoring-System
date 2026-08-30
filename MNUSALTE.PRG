* program.....: MnuSalTe.prg
*             : submenu of menu of sales summ per territory
*             : 07/10/2004

PRIVATE ALL LIKE PRG??
PRIVATE ALL LIKE M_*
prg1a= 'A] Per Cust. / Annual  '
prg1b= 'B] Per Cust. / Div.    '
prg1c= 'C] Per Cust/Inclusive  '
prg1d= 'D] Per Supplier/Gross  '
prg1e= 'E] Per Supplier/Gross 2'
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
    @ 6, 30 SAY '    SALES SUMMARY    '
    &C_OPTION
    @ 9,  29 SAY prg1a
    @ 10, 29 SAY prg1b
    @ 11, 29 SAY prg1c
    @ 12, 29 SAY prg1d
    @ 13, 29 say prg1e
    @ 14, 29 say prg1f
    DO MENU3C
    prg= choice
    DO CASE
        CASE choice='PRG1A'
             DO LST_TCM
        CASE choice='PRG1B'
             DO LST_TCD
        CASE choice='PRG1C'
             do LST_T_D
        CASE choice='PRG1D'
             do LST_TSG
        CASE choice='PRG1E'
             do LST_TSG2
        CASE choice='PRG1F'
            RETURN
    ENDCASE
    CLOSE DATABASE
    SELECT 1
ENDDO
 
return

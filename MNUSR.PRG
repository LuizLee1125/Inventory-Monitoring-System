* program.....: MnuSr.prg

PRIVATE ALL LIKE PRG??
PRIVATE ALL LIKE M_*
prg1a= 'A] Sales Ret. Summary  '
prg1b= 'B] Sales Ret./Category '
prg1c= 'C] Sales Ret./Division '
prg1d= 'D] Sales Ret./Customer '
prg1e= 'E] Sales Ret./Item     '
prg1f= 'F] C.M. - Applied      '
prg1g= 'G] C.M. - Unapplied    '
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
    @ 6, 30 SAY 'SALES RETURN SUMMARY'
    &C_OPTION
    @  9, 29 SAY prg1a
    @ 10, 29 SAY prg1b
    @ 11, 29 SAY prg1c
    @ 12, 29 SAY prg1d
    @ 13, 29 SAY prg1e
    @ 14, 29 SAY prg1f
    @ 15, 29 say prg1g
    @ 16, 29 say prg1h
    DO MENU3C
    prg= choice
    DO CASE
        CASE choice='PRG1A'
            DO LSTSRS
        CASE choice='PRG1B'
            DO LSTSRCAT
        CASE choice='PRG1C'
            DO LSTSRDIV
        CASE choice='PRG1D'
            DO LSTSRC
        CASE choice='PRG1E'
            DO LSTSRI
        case choice='PRG1F'
            DO SR_Aplyd
        case choice='PRG1G'
            DO SR_UnApl
        CASE choice='PRG1H'
            RETURN
    ENDCASE
    CLOSE DATABASE
    SELECT 1
ENDDO
 

* program.....: MnuXpens.prg

PRIVATE ALL LIKE PRG??
PRIVATE ALL LIKE M_*
prg1a= 'A] Customer File       '
prg1b= 'B] Accounts File       '
prg1c= 'C] Voucher             '
prg1d= 'D] Credit Memo         '
prg1e= 'E] Debit  Memo         '
prg2a= 'N] List of Accounts    '
prg2b= 'O] Voucher Summary     '
prg3a= '1] Exit                '
prg3b= '2] Set Date            '
prg3c= '3] Set Exact           '
prg3d= '4] Set Printer         '
m_y_col1= 5
m_y_col2= 2
m_y_col3= 4
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
    @ 2, 16 SAY '            EXPENSE MONITORING SYSTEM           '
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
    @ 6, 55 SAY '        OTHERS       '
    &C_OPTION
    @ 9, 4 SAY prg1a
    @ 10, 4 SAY prg1b
    @ 11, 4 SAY prg1c
    @ 12, 4 SAY prg1d
    @ 13, 4 SAY prg1e
    @ 9, 29 SAY prg2a
    @ 10, 29 SAY prg2b
    @ 9, 54 SAY prg3a
    @ 10, 54 SAY prg3b
    @ 11, 54 SAY prg3c
    @ 12, 54 SAY prg3d
    DO MENU3C
    prg= choice
    DO CASE
        CASE choice='PRG1A'
            DO CUSTFYL
        CASE choice='PRG1B'
            DO ACCTFYL
        CASE choice='PRG1C'
            DO VOUCHFYL
        CASE choice='PRG1D'
            DO CMFYL
        CASE choice='PRG1E'
            DO DMFYL
        CASE choice='PRG2A'
            DO LSTACCT
        CASE choice='PRG2B'
        CASE choice='PRG3A'
            CLOSE DATABASE
            SELECT 1
            RETURN
        CASE choice='PRG3B'
            RUN DATEUPD
        CASE choice='PRG3C'
            DO SETEXACT
        CASE choice='PRG3C'
            DO SETPRINT
    ENDCASE
    CLOSE DATABASE
    SELECT 1
ENDDO
 

* program.....: MnuCRev.prg

PRIVATE ALL LIKE PRG??
PRIVATE ALL LIKE M_*

* old codes
*prg1a= 'A] Change Stock Codes  '
*prg1b= 'B] Change Customer     '
*prg1c= 'C] Change Supplier     '
*prg1d= 'D] Change Division     '
*prg1e= 'E] Change Category     '
*prg1f= 'F] Change Territory    '
*prg1g= 'G] Change Invoice No.  '
*prg1h= 'H] Change Rem/Date/Paid'
*prg1i= 'I] Change Discounts    '
*prg1j= 'J] Change Purchase No. '
*prg1k= 'K] Change Sales Return '
*prg1l= 'L] Change Collection # '
*prg1m= 'M] Change Coll. Dates  '
*prg1n= 'N] Change Blanks       '
*prg1o= 'O] Exit                '

* new codes - 08/27-2018
prg1a= 'A] Change Stock Codes  '
prg1b= 'B] Change Customer     '
prg1c= 'C] Change Supplier     '
prg1d= 'D] Change Division     '
prg1e= 'E] Change Category     '
prg1f= 'F] Change Territory    '
prg1g= 'G] Change Sales Invoice'
prg1h= 'H] Change Purchase No. '
prg1i= 'I] Change Sales Return '
prg1j= 'J] Change Collection # '
prg1k= 'K] Change Coll. Dates  '
prg1l= 'L] Change Blanks       '
prg1m= 'M] Exit                '


m_y_col1= 13
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
    @ 5, 28 TO 22, 52 DOUBLE
    @ 4, 29 TO 6, 51 DOUBLE
    &C_HEAD
    @ 5, 30 SAY ' CODE REVISION MENU  '
    &C_OPTION
    @  8, 29 SAY prg1a
    @  9, 29 SAY prg1b
    @ 10, 29 SAY prg1c
    @ 11, 29 SAY prg1d
    @ 12, 29 SAY prg1e
    @ 13, 29 say prg1f
    @ 14, 29 say prg1g
    @ 15, 29 say prg1h
    @ 16, 29 say prg1i
    @ 17, 29 say prg1j
    @ 18, 29 say prg1k
    @ 19, 29 say prg1l
    @ 20, 29 say prg1m
    save screen to sub_atlscrn
    DO MENU3C
    prg= choice
    DO CASE
        CASE choice='PRG1A'
            DO REP_STKN
        CASE choice='PRG1B'
            DO REP_CUSN
        CASE choice='PRG1C'
            DO mnu_rspl            
        CASE choice='PRG1D'
            DO MNU_RDIV           
        CASE choice='PRG1E'
            DO MNU_RCAT
        CASE choice='PRG1F'
            DO REP_SMAN
        CASE choice='PRG1G'
            DO RSCR_SI
        CASE choice='PRG1H'
            DO REP_PUR
        CASE choice='PRG1I'
            DO RSCR_SR
        case choice='PRG1J'
            DO REP_COLC
        case choice='PRG1K'
            DO REP_COLD
        case choice='PRG1L'
            @ 23, 00 clear to 23,79
            restore screen from sub_atlscrn
            set color to +w/b
            @ 20, 29 say prg1m
            set color to +bg,+w/r
            @ 16, 55 to 21,76
            @ 17, 56 prompt "1. blank collections"
            @ 18, 56 prompt "2. blank stocks     "
           *@ 19, 56 prompt "3. cust no. in coll."
            @ 19, 56 prompt "3. blank invoices   "
            @ 20, 56 prompt "4. exit             "
            menu to sub_atl
            do case
               case sub_atl=1
                    DO Rep_Bcol
               case sub_atl=2
                    DO Rep_Stk2
               case sub_atl=3
                   *DO rep_coll
                   DO Rep_Stk3
              *case sub_atl=4
                    
               otherwise
                    loop
            endcase
        case choice='PRG1M'
            RETURN
    ENDCASE
    CLOSE DATABASE
ENDDO
 

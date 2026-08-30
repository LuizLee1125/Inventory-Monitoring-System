* program.....: LstSalbC.prg
*             : 09/06
*             : sales summary by customer

*save screen to atlscreen
*atlmsg="generate totals only (y/n)  "
*atlopt="N"
*atllen=len(atlmsg)
*set colo to rb/rb
*@ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
*set colo to +w/rb
*@ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
*@ 12,41-atllen/2 say atlmsg
*@ 12,40-atllen/2+len(atlmsg) get atlopt pict "Y" valid atlopt$"YyNn"
*read
*restore screen from atlscreen

*if atlopt="Y"
*   do lstsalct
*   return
*endif

DO BRDR2
*                   1         2         3         4         5         6         7
*           234567890123456789012345678901234567890123456789012345678901234567890123456789
@ 8, 2 SAY 'Cust Code  Customer Name                                         Sales Amt.'
*           1234567890 123456789012345678901234567890 99/99/99 1234567890 99,999,999.99
                                                      
SELECT 1
   USE SIFYL

store ctod(' ') to mfield1
store date()    to mfield2

DO WHILE .T.
    &C_HEAD
    @ 20, 1 SAY SPACE(78)
    &C_MESSAGE
    @ 21, 20 SAY ' NOTE: Press <Enter> to Return to Main Menu. '
    &C_BODY
    @ 5, 3 SAY 'Start At Invoice Date:'
    @ 6, 3 SAY 'Stop  At Invoice Date:'
    * @ 5, 52 SAY 'Customer Code :'
    &C_GET
    SET CENT ON
    @ 5, 26 GET mfield1 PICTURE '99/99/9999'
    @ 6, 26 GET mfield2 picture '99/99/9999'
    READ
    IF mfield1=CTOD('  /  /  ')
        CLOSE DATA
        set cent off
        RETURN
    ENDIF
    SET CENTURY OFF
    choice= 'L'
    DO OPTION8
    save screen to atlscreen
    atlmsg="please wait, filtering/extracting data..."
    atllen=len(atlmsg)
    set colo to rb/rb
    @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
    set colo to +w/rb
    @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
    @ 12,41-atllen/2 say atlmsg
    SORT ON CUST_N, INV_D TO TMPSLCUS FOR (INV_D>=MFIELD1.AND.INV_D<=MFIELD2) FIELDS CUST_N, CUST_M, INV_D, INV_N, NET_A
    restore screen from atlscreen
    USE TMPSLCUS
    DO CASE
        CASE choice='L'
            STORE 0.00 TO stl1, stl2, gtl1
            &C_CLEAR
            @ 10, 1 CLEAR TO 19, 78
            flag= 1
            row= 9
            
            DO WHILE .not. EOF()
                IF flag=1
                    c_list= c_option
                    flag= 0
                ELSE
                    c_list= c_body
                    flag= 1
                ENDIF
                &C_LIST
                @ row, 2 say Cust_n
                @ row,13 say Cust_m
                @ row,44 say '....................'
                stor cust_n to sv_custn
                do while .not. eof() .and. sv_custn=cust_n
                  * @ row,44 SAY inv_d PICTURE '99/99/99'
                  * @ row,53 SAY inv_n PICTURE '@!'
                  * @ row,64 SAY net_a PICTURE '99,999,999.99'
                   stl1= stl1+net_a
                   stl2= stl2+net_a
                   gtl1= gtl1+net_a
                  * row= row+1
                   SKIP
                  * IF row=19
                  *    &C_HEAD
                  *    @ 19, 1 SAY SPACE(78)
                  *    @ 19, 10 SAY 'SUB   TOTAL'
                  *    @ 19, 64 SAY stl2 PICTURE '##,###,###.##'
                  *    @ 20, 1 SAY SPACE(78)
                  *    @ 20, 10 SAY 'GRAND TOTAL'
                  *    @ 20, 64 SAY gtl1 PICTURE '##,###,###.##'
                  *    choice= ' '
                  *    &C_CLEAR
                  *    @ 21, 0
                  *    &C_MESSAGE
                  *    @ 21, 20 SAY ' Press <A> to Abort, any key to continue.' GET choice PICTURE '!'
                  *    READ
                  *    IF choice='A'
                  *       SET CENTURY Off
                  *       CLOSE DATA
                  *       RETURN
                  *    ENDIF
                  *    &C_CLEAR
                  *    @ 9, 1 CLEAR TO 19, 78
                  *    row= 9
                  *    STORE 0.00 TO stl1 
                  * ENDIF
                ENDDO
                *set colo to +bg
                *@ row, 2 say Cust_n
                *@ row,13 say Cust_m
                *@ row,44 say "total sales amount:"
                @ row,64 say stl1 picture '99,999,999.99'
                &C_HEAD
                @ 19, 1 SAY SPACE(78)
                @ 19, 10 SAY 'SUB   TOTAL'
                @ 19, 64 SAY stl2 PICTURE '##,###,###.##'
                @ 20, 1 SAY SPACE(78)
                @ 20, 10 SAY 'GRAND TOTAL'
                @ 20, 64 SAY gtl1 PICTURE '##,###,###.##'
                store 0 to stl1
                row=row+1
                if eof()
                   exit
                endif
                IF row=19
                   &C_HEAD
                   @ 19, 1 SAY SPACE(78)
                   @ 19, 10 SAY 'SUB   TOTAL'
                   @ 19, 64 SAY stl2 PICTURE '##,###,###.##'
                   @ 20, 1 SAY SPACE(78)
                   @ 20, 10 SAY 'GRAND TOTAL'
                   @ 20, 64 SAY gtl1 PICTURE '##,###,###.##'
                   choice= ' '
                   &C_CLEAR
                   @ 21, 0
                   &C_MESSAGE
                   @ 21, 20 SAY ' Press <A> to Abort, any key to continue.' GET choice PICTURE '!'
                   READ
                   IF choice='A'
                      SET CENTURY Off
                      CLOSE DATA
                      RETURN
                   ENDIF
                   &C_CLEAR
                   @ 9, 1 CLEAR TO 19, 78
                   row= 9
                   STORE 0.00 TO stl2 
                ENDIF
            enddo
        CASE choice='P'
            do testprt
            store 1 to pg
            STORE 0.00 TO stl1, stl2, gtl1
            &C_CLEAR
            @ 10, 1 CLEAR TO 19, 78
            flag= 1
            row= 9
            SET CONSOLE OFF
            SET DEVICE TO PRINTER
            SET PRINTER ON
            ?? CHR(27)+CHR(64)
            ?? CHR(18)
            cdate= CMONTH(DATE())+' '+STR(DAY(DATE()),2)+','+STR(YEAR(DATE()),4)
            head= 'Sales Summary by Customer from '+DTOC(mfield1)+' to '+DTOC(mfield2)
            @ 3, 1 SAY 'Page '+LTRIM(STR(pg))
            @ 3, (80-LEN(company))/2 SAY company
            @ 4, (80-LEN(head))/2 SAY head
            @ 6, 2 SAY '---------------------------------------------------------------------------'
            @ 7, 2 SAY 'Cust Code  Customer Name                                         Sales Amt.'
            @ 8, 2 SAY '---------------------------------------------------------------------------'
            DO WHILE .not. EOF()
                @ row, 2 say Cust_n
                @ row,13 say Cust_m
                stor cust_n to sv_custn
                do while .not. eof() .and. sv_custn=cust_n
                   stl1= stl1+net_a
                   stl2= stl2+net_a
                   gtl1= gtl1+net_a
                   SKIP
                ENDDO
                @ row,64 say stl1 picture '99,999,999.99'
                store 0 to stl1
                row=row+1
                if eof()
                   exit
                endif
                IF row>55
                   @ row+1, 50 SAY '  SUB TOTAL:'
                   @ row+1, 64 SAY stl2 PICTURE '##,###,###.##'
                   @ row+3, 55 SAY '...continued on page '+LTRIM(STR(pg+1))
                   ?
                   ?? CHR(18)
                   EJECT
                   SET PRINTER OFF
                   SET DEVICE TO SCREEN
                   SET CONSOLE ON
                   &C_CLEAR
                   @ 23, 0
                   choice= ' '
                   &C_CLEAR
                   @ 23, 0
                   @ 21, 0
                   &C_MESSAGE
                   @ 21, 20 SAY ' Press <A> to Abort, any key to continue.' GET choice PICTURE '!'
                   READ
                   IF choice='A'
                      SET CENTURY Off
                      CLOSE DATA
                      RETURN
                   ENDIF
                   DO TESTPRT
                   &C_CLEAR
                   @ 23, 0
                   &C_MESSAGE
                   @ 23, 50 SAY '...Printing'
                   SET CONSOLE OFF
                   SET DEVICE TO PRINTER
                   SET PRINTER ON
                   pg= pg+1
                   stl= 0.00
                   @ 3, 1 SAY 'Page '+LTRIM(STR(pg))
                   @ 3, (80-LEN(head))/2 SAY head
                   @ 5, 2 SAY '---------------------------------------------------------------------------'
                   @ 6, 2 SAY 'Cust Code  Customer Name                                         Sales Amt.'
                   @ 7, 2 SAY '---------------------------------------------------------------------------'
                   store 8 to row
                   store 0 to stl2
                ENDIF
            enddo
            @ row+1, 50 SAY '  SUB TOTAL:'
            @ row+1, 64 SAY stl2 PICTURE '##,###,###.##'
            @ row+2, 50 SAY 'GRAND TOTAL:'
            @ row+2, 64 SAY gtl1 PICTURE '##,###,###.##'
            EJECT
            SET PRINTER OFF
            SET DEVICE TO SCREEN
            SET CONSOLE ON
            &C_CLEAR
            @ 23, 0
        OTHERWISE
            SET CENTURY Off
            CLOSE DATA
            RETURN
    ENDCASE
    choice= ' '
    &C_CLEAR
    @ 21, 0
    &C_MESSAGE
    @ 21, 24 SAY ' Return to Previous Menu (y/n). ' GET confirm PICTURE '!'
    READ
    IF confirm='N'
        &C_CLEAR
        @ 9, 1 CLEAR TO 19, 78
        @ 21, 0
        row= 9
        close database
        sele 1
           use sifyl
        LOOP
    ELSE
        CLOSE DATA
        set cent off
        RETURN
    ENDIF
ENDDO

SET CENT OFF
CLOSE DATA
RETURN

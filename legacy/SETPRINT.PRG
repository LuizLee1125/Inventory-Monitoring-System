
DO BRDR1
&C_CLEAR
@ 21, 0
@ 22, 0
&C_CHOICE
@ 9, 30 SAY ' CHANGE PRINT MODE '
&C_MESSAGE
@ 14, 16 SAY ' Note :  Set Print On  - print outs are directed '
@ 15, 16 SAY '                         to the printer.         '
@ 16, 16 SAY '         Set Print Off - print outs are directed '
@ 17, 16 SAY "                         to 'TEMP' file.         "
@ 18, 16 SAY '         Default value - set exact on.           '
confirm= ' '
&C_GET
DO WHILE .not. confirm$'NF'
    @ 21, 20 SAY 'Press <N> to turn On, <F> to turn Off.' GET confirm PICTURE '!'
    READ
ENDDO
IF confirm='N'
    SET PRINTER TO
ELSE
    SET PRINTER TO TEMP
ENDIF
RETURN
 

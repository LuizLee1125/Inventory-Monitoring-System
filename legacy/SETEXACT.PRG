
DO BRDR1
&C_CLEAR
@ 21, 0
@ 22, 0
&C_CHOICE
@ 9, 30 SAY ' CHANGE EXACT MODE '
&C_MESSAGE
@ 14, 16 SAY ' Note :  Set Exact On  - code should be exactly '
@ 15, 16 SAY '                         the same to match.     '
@ 16, 16 SAY '         Set Exact Off - search for the first   '
@ 17, 16 SAY '                         occurrence of data.    '
@ 18, 16 SAY '         Default value - set exact off.         '
confirm= ' '
&C_GET
DO WHILE .not. confirm$'NF'
    @ 21, 20 SAY 'Press <N> to turn On, <F> to turn Off.' GET confirm PICTURE '!'
    READ
ENDDO
IF confirm='N'
    SET EXAC ON
ELSE
    SET EXAC OFF
ENDIF
RETURN
 

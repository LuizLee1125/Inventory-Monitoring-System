
CLEAR
@ 23, 50 SAY ' Please  Wait  ... '
CLEAR ALL
CLOSE ALL
SET BELL OFF
SET COLOR TO 
SET CONFIRM OFF
SET DELETED ON
SET DEVICE TO SCREEN
SET PRINTER OFF
SET PROC TO MODULEM
SET SAFETY OFF
SET SCORE OFF
SET STATUS OFF
SET TALK OFF
ON ERROR    DO ERR_FIX WITH ERROR(),MESSAGE(),SYS(16)
PUBLIC c_brdr, c_body, c_choice, c_clear, c_get, c_head, c_hidden, c_message, c_option
colored= .T.
IF colored
    STORE 'SET COLO TO BG+/N' TO c_brdr
    STORE 'SET COLO TO G+/N' TO c_body
    STORE 'SET COLO TO W+/B*,W+/B*' TO c_choice
    STORE 'SET COLO TO ' TO c_clear
    STORE 'SET COLO TO W+/BG+,W+/BG+' TO c_get
    STORE 'SET COLO TO W+/R' TO c_head
    STORE 'SET COLO TO X/X,X/X' TO c_hidden
    STORE 'SET COLO TO W+/R' TO c_message
    STORE 'SET COLO TO GR+/N' TO c_option
ELSE
    STORE 'SET COLO TO W' TO c_brdr
    STORE 'SET COLO TO W' TO c_body
    STORE 'SET COLO TO W+/U,W+/U' TO c_choice
    STORE 'SET COLO TO ' TO c_clear
    STORE 'SET COLO TO W/I,W/I' TO c_get
    STORE 'SET COLO TO W+/I' TO c_head
    STORE 'SET COLO TO X/X,X/X' TO c_hidden
    STORE 'SET COLO TO W/I' TO c_message
    STORE 'SET COLO TO W' TO c_option
ENDIF
PUBLIC action, choice, company, confirm, error, new, page, pg
PUBLIC maccesmnu, mtempfyl, muser
PUBLIC pbold_on, pbold_off
action= ' '
choice= ' '
company= 'MARINA TRADING'
confirm= ' '
error= .F.
new= .F.
page= .F.
pg= 0
maccesmnu= SPACE(8)
mtempfyl= SPACE(8)
muser= SPACE(10)
pbold_on= '?? CHR(27)+CHR(69)'
pbold_off= '?? CHR(27)+CHR(70)'
 

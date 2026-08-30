* program.....: Procsi.prg

SET DELETED ON
SELECT 6
USE PURFYL INDEX PUR_N, PUR_D
SELECT 5
USE SRFYL INDEX SR_N, SR_D, SR_CD
SELECT 4
USE STKFYL INDEX STK_N
SELECT 3
USE SIFYL INDEX SI_N, SI_D, SI_CD
SELECT 2
USE STKREC INDEX TRANS_CN, TRANS_ID, SI_ID
SELECT 1
USE TSTKREC
DO WHILE .not. EOF()
    SELECT 4
    SEEK  tstkrec->stk_n
    IF .not. EOF()
        DO CASE
            CASE  tstkrec->trans_c='S'
                REPLACE qty1 WITH qty1- tstkrec->issue_q
            CASE  tstkrec->trans_c='R'
                REPLACE qty1 WITH qty1+ tstkrec->issue_q
            CASE  tstkrec->trans_c='P'
                REPLACE qty1 WITH qty1+ tstkrec->issue_q
        ENDCASE
    ENDIF
    SELECT 1
    SKIP
ENDDO
USE
SELECT 2
APPEND FROM TSTKREC
SELECT 3
APPEND FROM TSIFYL
SELECT 5
APPEND FROM TSRFYL
SELECT 6
APPEND FROM TPURFYL
 

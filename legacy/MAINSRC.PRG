* program.....: MainSrc.prg
* purpose.....: Reconstructed source for MAIN.FOX.
*
* The original MAIN.PRG source was lost; only the 229-byte compiled MAIN.FOX
* survives. This file rebuilds it from the literals and symbol table held in
* that object:  INITENV, PASSWORD, &C_CLEAR, &C_MESSAGE,
*               ' Loading Programs ... ', DO &mACCESMNU,
*               symbols MACCESMNU / MTEMPFYL / MUSER.
*
* MAIN.FOX remains the authoritative entry point - this is kept separate so it
* never shadows it. Run it with:  DO MAINSRC
*
* KNOWN GAP: the original assigned mTEMPFYL a per-workstation scratch-table
* name (SIFYL.PRG does COPY STRU TO &mTEMPFYL, so two clerks must never share
* one). The exact expression is not recoverable from the object file; the
* derivation below is a working substitute, not the original.

DO INITENV
DO PASSWORD

* --- per-workstation scratch table --------------------------------------
* Give every station a distinct 8-character name so concurrent invoicing
* does not collide. Override by setting IMSTMP in the DOS environment.
mtempfyl = TRIM(GETENV('IMSTMP'))
IF LEN(mtempfyl) = 0
    mtempfyl = 'TMP' + RIGHT('00000' + LTRIM(STR(VAL(SYS(0)))), 5)
ENDIF
IF LEN(TRIM(mtempfyl)) = 0
    mtempfyl = 'TMPSI1'
ENDIF

&C_CLEAR
CLEAR
&C_MESSAGE
@ 23, 50 SAY ' Loading Programs ... '

DO &mACCESMNU

&C_CLEAR
CLEAR
CLOSE DATABASES
CLOSE ALL
QUIT

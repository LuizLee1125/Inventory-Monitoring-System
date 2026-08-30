set talk off
set scor off

SET CONSOLE OFF
SET DEVICE TO PRINTER
SET PRINTER ON

?? CHR(27)+CHR(64)
?? chr(27)+chr(48)
?? CHR(18)

@ 1,38 say "LBP MALACANANG      T2(GRACE C. MONT)"
@ 2,38 say "04-15-2010  14:30 Trxn. Seq. #: 17165"
@ 3,38 say "BIR-ON COLL            CASH Payment"
@ 4,38 say "Clrng. Acct. No.         9942-2277-33"
@ 5,38 say "TINBCCDrw/cash       000381857000CASH"
@ 6,38 say "RDOATTTFT                  032CIT1702"
@ 7,38 say "QMMDDYY                       0123109"
@ 8,38 say "Amount                      41,651.14"
@ 9,38 say ""
@10,38 say ""
@25,38 say ""
set console on
set device to screen
set print off

return


















return
? 'please wait...'

sele 1
     use stkrec index trans_cn, trans_id, si_id
sele 2
     use bad_si

sele 1
seek "S"
do while .not. eof() .and. trans_c="S"
   if trans_c="S" .and. cust_s='HOUSE2' .and. .not. eof()
      stor cust_n to sv_cust_n
      sele 2
      loca for cust_n = sv_cust_n
      if found()
         sele 1
         repl qty1l with "BD"
      endif
   endif
   SELE 1
   skip
enddo


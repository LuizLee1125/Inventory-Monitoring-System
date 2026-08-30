* program....: rep_atl.prg
*              match transaction records with header file and mark it for
*              transfer

set talk on
set stat on
set scor off

clear prog

sele 1
   use sifyl index si_n
sele 2
   use stkrec index trans_cn

seek "S"

do while .not. eof() .and. trans_c="S"
   store trans_n to sv_inv_n
   sele 1
   seek sv_inv_n
   if .not. found()
      sele 2
      repl qty1l with "U"
   endif
   sele 2
   skip
enddo

close data

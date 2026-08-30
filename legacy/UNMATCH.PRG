* program.....: unmatch.prg
*             : 08/14/04
*             : validation for tran file; checks if records matches the header

set talk off
set stat on
set scor off

clear prog

sele 1
   use sifyl index si_n
sele 2
   use purfyl index pur_n
sele 3
   use srfyl index sr_n
sele 4
   use stkrec

do while .not. eof()
   do case
      case trans_c="S"
           stor trans_n to sv_trans_n
           sele 1
           seek sv_trans_n
           if .not. found()
              sele 4
              repl qty1l with "unm"
           endif
      case trans_c="P"
           stor trans_n to sv_trans_n
           sele 2
           seek sv_trans_n
           if .not. found()
              sele 4
              repl qty1l with "unm"
           endif
      case trans_c="R"
           stor trans_n to sv_trans_n
           sele 3
           seek sv_trans_n
           if .not. found()
              sele 4
              repl qty1l with "unm"
           endif
   endc
   sele 4
   skip
enddo

close data

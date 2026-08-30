* program....: rep_atl.prg
*              match transaction records with header file and mark it for
*              transfer

set talk on
set stat on
set scor off

clear prog

sele 1
   use srfylx
sele 2
   use stkrec index trans_cn


sele 1

do while .not. eof()
   store inv_n to sv_inv_n
   sele 2
   seek "R"+sv_inv_n
   if found()
      do while trans_n=sv_inv_n .and. .not. eof()
         repl qty1l with "M"
         skip
      enddo
   endif
   sele 1
   skip
enddo

close data

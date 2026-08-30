* PROGRAM....: Validate.prg
*            : match sifyl  with stkrec and vice-versa
*              match purfyl with stkrec and vice-versa
*              match srfyl  with stkrec and vice-versa

*set talk off
*set stat off
*set scor off
clear prog

sele 1
   use sifyl index si_n
sele 2
   use purfyl index pur_n
sele 3
   use srfyl index sr_n
sele 4
   use stkrec index trans_cn

sele 1
do while .not. eof()
   stor inv_n to sv_inv_n
   sele 4
   seek "S"+trim(sv_inv_n)
   if .not. found() && invalid record -> no matching detail
      sele 1
      dele
   endif
   sele 1
   skip
enddo

sele 2
do while .not. eof()
   stor inv_n to sv_inv_n
   sele 4
   seek "P"+trim(sv_inv_n)
   if .not. found() && invalid record -> no matching detail
      sele 2
      dele
   endif
   sele 2
   skip
enddo

sele 3
do while .not. eof()
   stor inv_n to sv_inv_n
   sele 4
   seek "R"+trim(sv_inv_n)
   if .not. found() && invalid record -> no matching detail
      sele 3
      dele
   endif
   sele 3
   skip
enddo

CLOSE ALL
RETURN

sele 4
seek "P"
do while .not. eof() .and. trans_c="P"
   stor trans_n to sv_trans_n
   sele 2
   seek sv_trans_n
   if .not. found() && invalid record -> no matching in the header
      sele 4
      dele
   endif
   sele 4
   skip
enddo

sele 4
seek "R"
do while .not. eof() .and. trans_c="R"
   stor trans_n to sv_trans_n
   sele 3
   seek sv_trans_n
   if .not. found() && invalid record -> no matching in the header
      sele 4
      dele
   endif
   sele 4
   skip
enddo

sele 4
seek "S"
do while .not. eof() .and. trans_c="S"
   stor trans_n to sv_trans_n
   sele 1
   seek sv_trans_n
   if .not. found() && invalid record -> no matching in the header
      sele 4
      dele
   endif
   sele 4
   skip
enddo

close data


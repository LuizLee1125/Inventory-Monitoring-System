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

sele 4
seek "SJ"
do while .not. eof() .and. trans_c="S"
   if left(trans_n,1)<>"J"
      exit
   endif
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


* program.....: Validat4.prg

set talk off
set scor off

sele 1
   use sifyl index si_n
sele 2
   use xx

do while .not. eof()
   stor trans_n to sv_transn
   sele 1
   seek sv_transn
   if found()
      if paid="T"
         sele 2
         dele
      endif
   endif
   sele 2
   skip
enddo

close data

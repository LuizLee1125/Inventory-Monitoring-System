* program....: RemSpace.prg

clear prog
set talk off
set scor off
*set stat off
set excl on

use stkfyl

do while .not. eof()
   if " "$trim(stk_n)
      ctr=1
      new_stk_n=""
      do while ctr<=10
         if substr(stk_n,ctr,1)<>" "
            new_stk_n=new_stk_n+subst(stk_n,ctr,1)
         endif
         ctr=ctr+1
      enddo
      replace stk_n with new_stk_n
   endif
   skip
enddo

use o_stkrec

do while .not. eof()
   if " "$trim(stk_n)
      ctr=1
      new_stk_n=""
      do while ctr<=10
         if substr(stk_n,ctr,1)<>" "
            new_stk_n=new_stk_n+subst(stk_n,ctr,1)
         endif
         ctr=ctr+1
      enddo
      replace stk_n with new_stk_n
   endif
   skip
enddo

use O_stkfyl

do while .not. eof()
   if " "$trim(stk_n)
      ctr=1
      new_stk_n=""
      do while ctr<=10
         if substr(stk_n,ctr,1)<>" "
            new_stk_n=new_stk_n+subst(stk_n,ctr,1)
         endif
         ctr=ctr+1
      enddo
      replace stk_n with new_stk_n
   endif
   skip
enddo

use stkrec

do while .not. eof()
   if " "$trim(stk_n)
      ctr=1
      new_stk_n=""
      do while ctr<=10
         if substr(stk_n,ctr,1)<>" "
            new_stk_n=new_stk_n+subst(stk_n,ctr,1)
         endif
         ctr=ctr+1
      enddo
      replace stk_n with new_stk_n
   endif
   skip
enddo


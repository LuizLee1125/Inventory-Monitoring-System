* program.....: StkXSply.prg
*             : extraction of pricelist based on supplier

save screen to atlscrn
set colo to
clear
set colo to b/b
@ 10,15 clear to 13,69
set colo to +w/rb
@ 09,15 say "                Extract data from StkFyl               "
set colo to w/b
@ 11,16 say "supplier 1: [          ]  file: [        ]  price [ ] "
@ 12,16 say "supplier 2: [          ]  file: [        ]  price [ ] "

store space(10) to spl1, spl2
store space (8) to fyl1, fyl2
store space (1) to prc1, prc2

@ 11,29 get spl1 picture "@!"
@ 11,49 get fyl1 picture "@!"
@ 11,67 get prc1 picture "!"  valid prc1$"ABCDE"
@ 12,29 get spl2 picture "@!" valid spl2<>spl1
@ 12,49 get fyl2 picture "@!" valid fyl2<>fyl1
@ 12,67 get prc2 picture "!"  valid prc2$"ABCDE"
read

div1ctr=0
div2ctr=0

set colo to +g
@ 15,26 say "processing the file, please wait..."

set colo to
@ 16,0 clear to 24,79

if upper(GETENV('BKUP'))='C:\TEMP'    && local drive is C

   set colo to +g/b

   use stkfyl
   copy stru to C:\TEMP\&fyl1 fields stk_m, prys_&prc1, qty_u
   if spl2<>" "
      copy stru to C:\TEMP\&fyl2 fields stk_m, prys_&prc2, qty_u
   endif
   close data

   sele 3
   use C:\TEMP\&fyl1
   if spl2<>" "
      sele 2
      use C:\TEMP\&fyl2
   endif
   sele 1
   use stkfyl index stk_n

   set colo to b/b
   @ 11,60 clear to 12,68

   do while .not. eof()
      set colo to +g/b
      if splyr_n=trim(spl1)
         div1ctr=div1ctr+1
         @11,62 say div1ctr pict "9,999"
         store stk_m       to mstk_m
         store qty_u       to mqty_u
         store prys_&prc1  to mprys
         sele 3
         appe blank
         repl stk_m      with mstk_m
         repl qty_u      with mqty_u
         repl prys_&prc1 with mprys
         unlock
         sele 1
      endif
      if spl2<>" "
         if splyr_n=trim(spl2)
            div2ctr=div2ctr+1
            @12,62 say div2ctr pict "9,999"
            store stk_m   to mstk_m
            store qty_u   to mqty_u
            store prys_&prc2  to mprys
            sele 2
            appe blank
            repl stk_m      with mstk_m
            repl qty_u      with mqty_u
            repl prys_&prc2 with mprys
            unlock
            sele 1
         endif
      endif
      set colo to
      @ 15,0 clear to 24,79
      skip
   enddo 
else
   use stkfyl
   copy stru to D:\TEMP\&fyl1 fields stk_m,  prys_&prc1, qty_u
   if spl2<>" "
      copy stru to D:\TEMP\&fyl2 fields stk_m, prys_&prc2, qty_u
   endif
   close data

   sele 3
   use D:\TEMP\&fyl1
   if spl2<>" "
      sele 2
      use D:\TEMP\&fyl2
   endif
   sele 1
   use stkfyl index stk_n

   set colo to b/b
   @ 11,60 clear to 12,68

   do while .not. eof()
      set colo to +g/b
      if splyr_n=trim(spl1)
         div1ctr=div1ctr+1
         @11,62 say div1ctr pict "9,999"
         store stk_m       to mstk_m
         store qty_u       to mqty_u
         store prys_&prc1  to mprys
         sele 3
         appe blank
         repl stk_m      with mstk_m
         repl qty_u      with mqty_u
         repl prys_&prc1 with mprys
         unlock
         sele 1
      endif
      if spl2<>" "
         if splyr_n=trim(spl2)
            div2ctr=div2ctr+1
            @12,62 say div2ctr pict "9,999"
            store stk_m       to mstk_m
            store qty_u       to mqty_u
            store prys_&prc2  to mprys
            sele 2
            appe blank
            repl stk_m      with mstk_m
            repl qty_u      with mqty_u
            repl prys_&prc2 with mprys
            unlock
            sele 1
         endif
      endif
      set colo to
      @ 16,0 clear to 24,79
      skip
   enddo 

endif

set colo to
@ 15,0 clear to 15,79
set colo to b/b
@ 16,12 clear to 18,71
set colo to +gr/b
@ 16,12 to 18,71
set colo to +w/b,+gr/rb
@ 17,14 say "  Completed filtering each division.  Press any key...  "
keypress=inkey(0)
restore screen from atlscrn
close data
return

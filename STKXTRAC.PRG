* program.....: StkXtrac.prg
* modified....: oct. 7, 2002

set colo to
clear

set colo to rb/rb
@11,24 clear to 13,55
set colo to +w/rb, +gr/b
@11,24 to 13,55
@12,26 prompt " Per Division "
@12,40 prompt " Per Supplier "
menu to atlopt
if atlopt=2
   do stkxsply
   return
endif

save screen to atlscrn
set color to
clear

set colo to +g
@ 14,23 say "Extracting all divisions, please wait..."
set colo to
@ 15,0 clear to 24,79

div1ctr=0
div2ctr=0
div3ctr=0
div4ctr=0
div5ctr=0

if upper(GETENV('BKUP'))='C:\TEMP'    && local drive is C
   use stkfyl
   copy stru to C:\TEMP\ph1  fields stk_cat, stk_m, prys_e, qty_u
   copy stru to C:\TEMP\ph2  fields stk_cat, stk_m, prys_e, qty_u
   copy stru to C:\TEMP\ph3  fields stk_cat, stk_m, prys_e, qty_u
   copy stru to C:\TEMP\ph4  fields stk_cat, stk_m, prys_e, qty_u
   copy stru to C:\TEMP\cons fields stk_cat, stk_m, prys_e, qty_u
   close data

   sele 6
      use C:\TEMP\ph1
   sele 5
      use C:\TEMP\ph2
   sele 4
      use C:\TEMP\ph3
   sele 3
      use C:\TEMP\ph4
   sele 2
      use C:\TEMP\CONS
   sele 1
      use stkfyl index stk_n

      *1         2         3         4         5         6         7
      *0123456789012345678901234567890123456789012345678901234567890123456789
      *                      division PH1:  [9,999]

   @  8,32 say "division PH1:  [     ]"
   @  9,41 say "PH2:  [     ]"
   @ 10,41 say "PH3:  [     ]"
   @ 11,41 say "PH4:  [     ]"
   @ 12,41 say "CON:  [     ]"

   do while .not. eof()
      set colo to +g/b
      do case
         case stk_dv="PH1"
              div1ctr=div1ctr+1
              @ 8,48 say div1ctr pict "9,999"
              store stk_cat to mstk_cat
              store stk_m   to mstk_m
              store qty_u   to mqty_u
              store prys_e  to mprys_e
              sele 6
              appe blank
              repl stk_cat with mstk_cat
              repl stk_m   with mstk_m
              repl qty_u   with mqty_u
              repl prys_e  with mprys_e
              unlock
              sele 1
         case stk_dv="PH2"
              div2ctr=div2ctr+1
              @ 9,48 say div2ctr pict "9,999"
              store stk_cat to mstk_cat
              store stk_m   to mstk_m
              store qty_u   to mqty_u
              store prys_e  to mprys_e
              sele 5
              appe blank
              repl stk_cat with mstk_cat
              repl stk_m   with mstk_m
              repl qty_u   with mqty_u
              repl prys_e  with mprys_e
              unlock
              sele 1
         case stk_dv="PH3"
              div3ctr=div3ctr+1
              @ 10,48 say div3ctr pict "9,999"
              store stk_cat to mstk_cat
              store stk_m   to mstk_m
              store qty_u   to mqty_u
              store prys_e  to mprys_e
              sele 4
              appe blank
              repl stk_cat with mstk_cat
              repl stk_m   with mstk_m
              repl qty_u   with mqty_u
              repl prys_e  with mprys_e
              unlock
              sele 1
         case stk_dv="PH4"
              div4ctr=div4ctr+1
              @ 11,48 say div4ctr pict "9,999"
              store stk_cat to mstk_cat
              store stk_m   to mstk_m
              store qty_u   to mqty_u
              store prys_e  to mprys_e
              sele 3
              appe blank
              repl stk_cat with mstk_cat
              repl stk_m   with mstk_m
              repl qty_u   with mqty_u
              repl prys_e  with mprys_e
              unlock
              sele 1
         case stk_dv="CON"
              div5ctr=div5ctr+1
              @ 12,48 say div5ctr pict "9,999"
              store stk_cat to mstk_cat
              store stk_m   to mstk_m
              store qty_u   to mqty_u
              store prys_e  to mprys_e
              sele 2
              appe blank
              repl stk_cat with mstk_cat
              repl stk_m   with mstk_m
              repl qty_u   with mqty_u
              repl prys_e  with mprys_e
              unlock
              sele 1
      endcase
      skip
   enddo

else

   use stkfyl
   copy stru to D:\TEMP\ph1  fields stk_cat, stk_m, prys_e, qty_u
   copy stru to D:\TEMP\ph2  fields stk_cat, stk_m, prys_e, qty_u
   copy stru to D:\TEMP\ph3  fields stk_cat, stk_m, prys_e, qty_u
   copy stru to D:\TEMP\ph4  fields stk_cat, stk_m, prys_e, qty_u
   copy stru to D:\TEMP\cons fields stk_cat, stk_m, prys_e, qty_u
   close data

   sele 6
      use D:\TEMP\ph1
   sele 5
      use D:\TEMP\ph2
   sele 4
      use D:\TEMP\ph3
   sele 3
      use D:\TEMP\ph4
   sele 2
      use D:\TEMP\CONS
   sele 1
      use stkfyl index stk_n

   @  8,32 say "division PH1:  [     ]"
   @  9,41 say "PH2:  [     ]"
   @ 10,41 say "PH3:  [     ]"
   @ 11,41 say "PH4:  [     ]"
   @ 12,41 say "CON:  [     ]"

   do while .not. eof()
      set colo to +g/b
      do case
         case stk_dv="PH1"
              div1ctr=div1ctr+1
              @ 8,48 say div1ctr pict "9,999"
              store stk_cat to mstk_cat
              store stk_m   to mstk_m
              store qty_u   to mqty_u
              store prys_e  to mprys_e
              sele 6
              appe blank
              repl stk_cat with mstk_cat
              repl stk_m   with mstk_m
              repl qty_u   with mqty_u
              repl prys_e  with mprys_e
              unlock
              sele 1
         case stk_dv="PH2"
              div2ctr=div2ctr+1
              @ 9,48 say div2ctr pict "9,999"
              store stk_cat to mstk_cat
              store stk_m   to mstk_m
              store qty_u   to mqty_u
              store prys_e  to mprys_e
              sele 5
              appe blank
              repl stk_cat with mstk_cat
              repl stk_m   with mstk_m
              repl qty_u   with mqty_u
              repl prys_e  with mprys_e
              unlock
              sele 1
         case stk_dv="PH3"
              div3ctr=div3ctr+1
              @ 10,48 say div3ctr pict "9,999"
              store stk_cat to mstk_cat
              store stk_m   to mstk_m
              store qty_u   to mqty_u
              store prys_e  to mprys_e
              sele 4
              appe blank
              repl stk_cat with mstk_cat
              repl stk_m   with mstk_m
              repl qty_u   with mqty_u
              repl prys_e  with mprys_e
              unlock
              sele 1
         case stk_dv="PH4"
              div4ctr=div4ctr+1
              @ 11,48 say div4ctr pict "9,999"
              store stk_cat to mstk_cat
              store stk_m   to mstk_m
              store qty_u   to mqty_u
              store prys_e  to mprys_e
              sele 3
              appe blank
              repl stk_cat with mstk_cat
              repl stk_m   with mstk_m
              repl qty_u   with mqty_u
              repl prys_e  with mprys_e
              unlock
              sele 1
         case stk_dv="CON"
              div5ctr=div5ctr+1
              @ 12,48 say div5ctr pict "9,999"
              store stk_cat to mstk_cat
              store stk_m   to mstk_m
              store qty_u   to mqty_u
              store prys_e  to mprys_e
              sele 2
              appe blank
              repl stk_cat with mstk_cat
              repl stk_m   with mstk_m
              repl qty_u   with mqty_u
              repl prys_e  with mprys_e
              unlock
              sele 1
      endcase
      skip
   enddo
endif

set colo to
@ 20,0 clear to 22,79
set colo to b/b
@ 14,11 clear to 16,70
set colo to +gr/b
@ 14,11 to 16,70
set colo to +w/b,+gr/rb
@ 15,13 say "  Completed filtering each division.  Press any key...  "
keypress=inkey(0)
restore screen from atlscrn
close data
return

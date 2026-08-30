* program.....: Rep_Spl3.prg
*             : 04/22/2001
*             : replacement of supplier by using category as key

set safe off
SET EXCLU ON

sele 3
   use splyrfyl
sele 1
   use Stkfyl  
sele 2
   use Rep_Cat
   zap

set colo to
clear

set colo to b/b
@ 08,22 clear to 17,58
set colo to +g/b
@ 08,22 to 17,58 double
@ 10,22 say chr(204)
@ 10,58 say chr(185)
@ 10,23 to 10,57 double
set colo to +gr/b
@ 09,28 say "Supplier Code Replacement"
set colo to +w/b
@ 12,25 say "category code  : [     ]"
*@ 13,25 say "[                              ]"
@ 14,25 say "old supplier   : [          ]"
@ 15,25 say "new supplier   : [          ]"

store 0 to sw

action="SAY"
choice="T"

do while .t.
   sele 2
   set colo to +bg/b
   @ 12,43 say Stk_CAT1    pict "@!"
  *@ 13,26 say Stk_M    pict "@!"
   @ 14,43 say splyr_n1 pict "@!"
   @ 15,43 say splyr_n2 pict "@!"

   set colo to +bg/n,+w/r
  * @ 23,09 prom " Add "
  * @ 23,14 prom " Edit "
   if deleted()
      set colo to gr/b
      @ 11,43 say  "* deleted *"
  *    set colo to +bg/n,+w/r
  *    @ 23,20 prom " Recall "
   else
      set colo to b/b
      @ 11,43 say  "           "
  *    set colo to +bg/n,+w/r
  *    @ 23,20 prom " Delete "
   endif
  * @ 23,28 prom " Top "
  * @ 23,33 prom " Bott "
  * @ 23,39 prom " Next "
  * @ 23,45 prom " Prev "
  * @ 23,51 prom " Save-Repl "
  * @ 23,62 prom " Quit "
  * menu to atlbar
   set colo to

   do option11
   atlbar=choice

   do case
      case atlbar = "A" && add
           stor space(5) to m_stkn
           save screen    to atlscrn
           stor recno()   to atlrecno
           stor 0         to atlsw
           do while .t.
              @ 12,43 get m_stkn pict "@!"
              read
              if m_stkn=" "
                 stor 1 to atlsw
                 exit
              endif
              sele 1
              loca for stk_cat=trim(m_stkn)
              if .not. found()
                  save screen to scrn_err
                  txtdata="Category does not exist! Press any key to continue..."
                  set colo to rb/rb
                  @ 17,39-len(txtdata)/2-2 clear to 19,39+len(txtdata)/2+1
                  set colo to +gr/rb
                  @ 17,39-len(txtdata)/2-2 to 19,39+len(txtdata)/2+1
                  set colo to +w/rb
                  @ 18,39-len(txtdata)/2 say txtdata
                  keypress=inkey(0)
                  set colo to
                  @17,39-len(txtdata)/2-2 clear to 19,39+len(txtdata)/2+1
                  rest screen from scrn_err
                  loop
              endif
              set colo to n/w
              @ 12,43 say stk_cat
              store stk_cat to m_stkn
             *store stk_n   to m_stkn
             *store stk_m   to sv_stk_m
              store splyr_n to sv_splyr_n
              sele 2
              if reccount()<>0
                 svrecno=recno()
                 loca for stk_cat1=trim(m_stkn)
                 if found()
                    save screen to scrn_err
                    txtdata="Duplicate entry! Press any key to continue..."
                    set colo to rb/rb
                    @ 17,39-len(txtdata)/2-2 clear to 19,39+len(txtdata)/2+1
                    set colo to +gr/rb
                    @ 17,39-len(txtdata)/2-2 to 19,39+len(txtdata)/2+1
                    set colo to +w/rb
                    @ 18,39-len(txtdata)/2 say txtdata
                    keypress=inkey(0)
                    set colo to
                    @17,39-len(txtdata)/2-2 clear to 19,39+len(txtdata)/2+1
                    go svrecno
                    sele 1
                    rest screen from scrn_err
                    loop
                 endif
              endif
              set colo to +bg/b
              *@ 13,26 say sv_Stk_M   pict "@!"
              @ 14,43 say sv_splyr_n pict "@!"
              exit
           enddo
           if atlsw=1
              sele 2
              if reccoun()<>0
                 go atlrecno
              endif
              rest screen from atlscrn
              loop
           endif
           store space(10) to m_splyr_n
           do while .t.
              @ 15,43 get m_splyr_n pict "@!"
              read
              if m_splyr_n=" "
                 store 1 to atlsw
                 exit
              endif
              sele 3
              loca for splyr_n=trim(m_splyr_n)
              if .not. found()
                  save screen to scrn_err
                  txtdata="Supplier Code does not exist! Press any key to continue..."
                  set colo to rb/rb
                  @ 17,39-len(txtdata)/2-2 clear to 19,39+len(txtdata)/2+1
                  set colo to +gr/rb
                  @ 17,39-len(txtdata)/2-2 to 19,39+len(txtdata)/2+1
                  set colo to +w/rb
                  @ 18,39-len(txtdata)/2 say txtdata
                  keypress=inkey(0)
                  set colo to
                  @17,39-len(txtdata)/2-2 clear to 19,39+len(txtdata)/2+1
                  rest screen from scrn_err
                  loop
              endif
              exit
           enddo
           if atlsw=1
              sele 2
              if reccoun()<>0
                 go atlrecno
              endif
              rest screen from atlscrn
              loop
           endif

           sele 2
           appe blan
           replace stk_cat1 with m_stkn
           *replace stk_m   with sv_stk_m
           replace splyr_n1 with sv_splyr_n
           replace splyr_n2 with m_splyr_n

      case atlbar = "E" && edit
           if splyr_n2 = " "
              loop
           endif
           stor splyr_n2 to m_splyr_n
           @ 15,43 get m_splyr_n pict "@!"
           read
           if m_splyr_n=" "
              loop
           endif
           replace splyr_n2 with m_splyr_n

     case  atlbar = "D" && delete
           if .not. deleted()
              delete
           endif

      case atlbar= "R"
           if deleted()
              recall
           endif

      case atlbar = "T" && top
           go top
      case atlbar = "B" && bott
           go bott
      case atlbar = "N" && next
           if eof() .and. bof()
              loop
           endif
           skip
           if eof()
              go bott
           endif
      case atlbar = "V" && prev
           if eof() .and. bof()
              loop
           endif
           skip -1
           if bof()
              go top
           endif
      case atlbar = "S" && save-repl
           if recc()<>0
              stor 0 to sw
              exit
           else
              txtdata="Insufficient data! Press any key to continue..."
              set colo to rb/rb
              @ 17,39-len(txtdata)/2-2 clear to 19,39+len(txtdata)/2+1
              set colo to +gr/rb
              @ 17,39-len(txtdata)/2-2 to 19,39+len(txtdata)/2+1
              set colo to +w/rb
              @ 18,39-len(txtdata)/2 say txtdata
              keypress=inkey(0)
              set colo to
              @17,39-len(txtdata)/2-2 clear to 19,39+len(txtdata)/2+1
              loop
           endif
      case atlbar = "Q" && quit
           store 1 to sw
           exit
   endcase
enddo

if sw=1
   close data
   set color to
   SET EXCLU OFF
   set exact off
   return
endif

set exact on

set colo to bg/bg
@ 12,27 clear to 16,70
set colo to n/bg
@ 12,27 to 17,70 double
set colo to n/bg
@ 13,29 say "Replacing records in:"
set colo to +w/bg
@ 15,30 say "Stock Master :[       ] of [         ]"
*@16,30 say "Transaction  :[       ] of [         ]"
@ 16,30 say "Old Trans.   :[       ] of [         ]"

sele 1
set index to 
ctr1=0
ctr2=0
go top
@ 15,58 say reccount() pict "99,999"

sele 1
go top
do while .not. eof()
   SELE 2
   go top
   do while .not. eof()
      store stk_cat1 to m_stkn
      store splyr_n2 to sv_splyr_n
      sele 1
      if stk_CAT=m_stkn
         repl splyr_n with sv_splyr_n
         ctr1=ctr1+1
         @15,45 say ctr1 pict "999,999"
      endif
      sele 2
      skip
   enddo
   sele 1
   skip
enddo

sele 4
   use o_stkfyl
@ 16,58 say reccount() pict "99,999"

ctr1=0
ctr2=0

do while .not. eof()
   SELE 2
   go top
   do while .not. eof()
      store stk_cat1 to m_stkn
      store splyr_n2 to sv_splyr_n
      sele 4
      if stk_CAT=m_stkn
         repl splyr_n with sv_splyr_n
         ctr2=ctr2+1
         @16,45 say ctr2 pict "999,999"
      endif
      sele 2
      skip
   enddo
   sele 4
   skip
enddo


txtdata="Replacement finished! Press any key to continue..."
set colo to r/r
@ 19,39-len(txtdata)/2-2 clear to 21,39+len(txtdata)/2+1
set colo to +gr/r
@ 19,39-len(txtdata)/2-2 to 21,39+len(txtdata)/2+1
set colo to +w/r
@ 20,39-len(txtdata)/2 say txtdata
keypress=inkey(0)
set colo to
*@14,39-len(txtdata)/2-2 clear to 19,39+len(txtdata)/2+1
clear
close data

SET EXCLU OFF
set exact off
return

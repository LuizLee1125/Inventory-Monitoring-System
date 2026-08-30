* program.....: Rep_Div.prg
*             : replace stock division --> reflecting all file
*             : 11/13/00


SET EXCLU ON
set exact on

sele 1
   use Stkfyl index Stk_N
sele 2
   use Rep_Stk
   zap

set colo to
clear

set colo to b/b
@ 08,22 clear to 15,56
set colo to +g/b
@ 08,22 to 15,56 double
@ 10,22 say chr(204)
@ 10,56 say chr(185)
@ 10,23 to 10,55 double
set colo to +gr/b
@ 09,27 say "Stock Division Replacement"
set colo to +w/b
@ 12,25 say "old stock division :  [     ]"
@ 13,25 say "new stock division :  [     ]"

*         1         2         3         4         5         6         7
*12345678901234567890123456789012345678901234567890123456789012345678901234567890
*08                   +---------------------------------+
*09                   :    Stock Category Replacement   :
*10                   : --------------------------------:
*11                   :                                 :
*12                   :  old stock category :  [xxxxx]  :
*13                   :  new stock category :  [xxxxx]  :
*14                   :                                 :
*15                   :---------------------------------+
*16
*17
*23    Add  Edit  Delete  Top  Bott  Next  Prev  Save-Repl  Quit

store 0 to sw
choice="T"
action="SAY"

do while .t.
   sele 2
   set colo to +bg/b
   @ 12,48 say O_Stk_N pict "!!!!!"
   @ 13,48 say N_Stk_N pict "!!!!!"

   set colo to +bg/n,+w/r
   *@ 23,09 prom " Add "
   *@ 23,14 prom " Edit "
   if deleted()
      set colo to gr/b
      @ 11,43 say  "* deleted *"
   *   set colo to +bg/n,+w/r
   *   @ 23,20 prom " Recall "
   else
      set colo to b/b
      @ 11,43 say  "           "
   *   set colo to +bg/n,+w/r
   *   @ 23,20 prom " Delete "
   endif
   *@ 23,28 prom " Top "
   *@ 23,33 prom " Bott "
   *@ 23,39 prom " Next "
   *@ 23,45 prom " Prev "
   *@ 23,51 prom " Save-Repl "
   *@ 23,62 prom " Quit "
   *menu to atlbar
   set colo to

   do option11
   atlbar=choice

   do case
      case atlbar = "A" && add
           stor space(5) to m_ostkn, m_nstkn
           save screen    to atlscrn
           stor recno()   to atlrecno
           stor 0         to atlsw
           sele 1
           do while .t.
              @ 12,48 get m_ostkn pict "@!"
              read
              if m_ostkn=" "
                 stor 1 to atlsw
                 exit
              endif
              loca for stk_dv=trim(m_ostkn)
              if .not. found()
                  txtdata="Stock Div. does not exist! Press any key to continue..."
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
              else
                  sele 2
                  if reccount()<>0
                     svrecno=recno()
                     loca for O_stk_n=trim(m_ostkn)
                     if found()
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
                        loop
                     endif
                  endif
                  exit
              endif
           enddo
           if atlsw=1
              sele 2
              if reccoun()<>0
                 go atlrecno
              endif
              rest screen from atlscrn
              loop
           endif
           do while .t.
              @ 13,48 get m_nstkn pict "@!"
              read
              if m_nstkn=" "
                 stor 1 to atlsw
                 exit
              endif
              SELE 1
              loca for stk_dv=trim(m_nstkn)
              if found()
                 txtdata="Div. already used! Press any key to continue..."
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
              else
                 exit
              endif
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
           repl O_Stk_N with M_OStkN
           repl N_Stk_N with M_NStkN

      case atlbar = "E" && edit
           stor O_Stk_N to m_ostkn
           stor N_Stk_N to m_nostkn
           if O_Stk_n=" "
              loop
           endif
           save screen    to atlscrn
           stor recno()   to atlrecno
           stor 0         to atlsw
           sele 1
           do while .t.
              @ 12,48 get m_ostkn pict "@!"
              read
              if m_ostkn=" "
                 stor 1 to atlsw
                 exit
              endif
              loca for stk_div=trim(m_ostkn)
              if .not. found()
                 txtdata="Stock Div. does not exist! Press any key to continue..."
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
              else
                 exit
              endif
           enddo
           if atlsw=1
              sele 2
              go atlrecno
              rest screen from atlscrn
              loop
           endif
           do while .t.
              @ 13,48 get m_nstkn pict "@!"
              read
              if m_nstkn=" "
                 stor 1 to atlsw
                 exit
              endif
              loca for stk_dv=trim(m_nstkn)
              if found()
                 txtdata="Div. already used! Press any key to continue..."
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
              else
                 exit
              endif
           enddo
           if atlsw=1
              sele 2
              go atlrecno
              rest screen from atlscrn
              loop
           endif
           sele 2
           repl O_Stk_N with M_OStkN
           repl N_Stk_N with M_NStkN

      case atlbar = "D" && delete
           if .not. deleted()
              delete
           *else
           *   recall
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

set colo to bg/bg
@ 12,27 clear to 18,70
set colo to n/bg
@ 12,27 to 18,70 double
set colo to n/bg
@ 13,29 say "Replacing records in:"
set colo to +w/bg
@ 15,30 say "Stock Master: [       ] of [         ]"
@ 16,30 say "Transaction : [       ] of [         ]"
@ 17,30 say "Old Trans   : [       ] of [         ]"

sele 1
set index to 
ctr1=0
ctr2=0
go top
do while .not. eof()
   store stk_dv to m_stkn
   sele 2
   go top
   do while .not. eof()
      if O_Stk_N=trim(m_Stkn) && matching record
         stor n_stk_n to sv_stkn
         sele 1
         repl stk_dv with sv_stkn
         ctr1=ctr1+1
         @15,45 say ctr1 pict "999,999"
         sele 2
         exit
      endif
      sele 2
      skip
   enddo
   ctr2=ctr2+1
   @ 15,58 say ctr2 pict "9,999,999"
   sele 1
   skip
enddo

ctr1=0
ctr2=0
sele 3
   use Stkrec
do while .not. eof()
   store stk_dv to m_stkn
   sele 2
   go top
   do while .not. eof()
      if O_Stk_N=trim(m_Stkn) && matching record
         stor n_stk_n to sv_stkn 
         sele 3
         repl stk_dv with sv_stkn
         ctr1=ctr1+1
         @16,45 say ctr1 pict "999,999"
         sele 2
         exit
      endif
      sele 2
      skip
   enddo
   ctr2=ctr2+1
   @ 16,58 say ctr2 pict "9,999,999"
   sele 3
   skip
enddo

ctr1=0
ctr2=0
sele 4
   use O_Stkrec
do while .not. eof()
   store stk_dv to m_stkn
   sele 2
   go top
   do while .not. eof()
      if O_Stk_N=trim(m_Stkn) && matching record
         stor n_stk_n to sv_stkn 
         sele 4
         repl stk_dv with sv_stkn
         ctr1=ctr1+1
         @17,45 say ctr1 pict "999,999"
         sele 2
         exit
      endif
      sele 2
      skip
   enddo
   ctr2=ctr2+1
   @ 17,58 say ctr2 pict "9,999,999"
   sele 4
   skip
enddo

txtdata="Replacement finished! Press any key to continue..."
set colo to r/r
@ 14,39-len(txtdata)/2-2 clear to 16,39+len(txtdata)/2+1
set colo to +gr/r
@ 14,39-len(txtdata)/2-2 to 16,39+len(txtdata)/2+1
set colo to +w/r
@ 15,39-len(txtdata)/2 say txtdata
keypress=inkey(0)
set colo to
*@14,39-len(txtdata)/2-2 clear to 19,39+len(txtdata)/2+1
CLEAR
close data

SET EXCLU OFF
set exact off
return

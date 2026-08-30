* program.....: Rep_ckdt.prg
*             : replacement of checks' dates

set safe off
SET EXCLU ON

sele 1
   use Colecrec
   set index to colec_n, colec_d, csi_n, chk_dd
   set order to 0
sele 2
   use Rep_Chk
   zap

set colo to
clear

set colo to b/b
@ 08,22 clear to 17,61
set colo to +g/b
@ 08,22 to 17,61 double
@ 10,22 say chr(204)
@ 10,58 say chr(185)
@ 10,23 to 10,60 double
set colo to +gr/b
@ 09,30 say " Check's Date Replacement "
set colo to +w/b
*                 3         4         5
*            567890123456789012345678901234567
@ 12,25 say "check # : [                    ]"
@ 13,25 say "customer: [          ] [          ]"
@ 14,25 say "old date: [          ]"
@ 15,25 say "new date: [          ]"

store 0 to sw
choice="T"
action="SAY"

do while .t.
   sele 2
   set colo to +bg/b
   @ 12,36 say Chk_N    pict "@!"
   SET CENT ON
   @ 13,36 say cust_n   pict "@!"
   @ 13,49 say amount   pict "999,999.99"
   @ 14,36 say o_date   pict "99/99/9999"
   @ 15,36 say n_date   pict "99/99/9999"
   SET CENT OFF
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
           stor space(20) to m_chk_n
           save screen    to atlscrn
           stor recno()   to atlrecno
           stor 0         to atlsw
           do while .t.
              @ 12,36 get m_chk_n pict "@!"
              read
              if m_chk_n=" "
                 stor 1 to atlsw
                 exit
              endif
              sele 1
              loca for chk_n=trim(m_chk_n)
              if .not. found()
                  save screen to scrn_err
                  txtdata="Check Number does not exist! Press any key to continue..."
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
              m_chk_n=chk_n

              @ 12,36 say m_chk_n
              store cust_n          to m_cust_n
             *store ctod(colec_rem) to m_o_date
              store chk_d           to m_o_date
              store chk_a           to m_amount
              sele 2
              if reccount()<>0
                 svrecno=recno()
                 loca for chk_n=trim(m_chk_n)
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
              @ 13,36 say m_cust_n   pict "@!"
              @ 13,49 say m_amount   pict "999,999.99"
              SET CENT ON
              @ 14,36 say m_o_date   pict "99/99/9999"
              SET CENT OFF
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
           store date() to m_n_date
           SET CENT ON
           @ 15,36 get m_n_date pict "99/99/9999"
           read
           SET CENT OFF
           sele 2
           appe blan
           replace cust_n   with m_cust_n
           replace chk_n    with m_chk_n
           replace o_date   with m_o_date  
           replace n_date   with m_n_date
           replace amount   with m_amount

      case atlbar = "E" && edit
           stor n_date   to m_n_date
           set cent on
           @ 15,36 get m_n_date pict "99/99/9999"
           read
           replace n_date   with m_n_date
           set cent off

      case atlbar = "D" && delete
           if .not. deleted()
              delete
           *else
           *   recall
           endif
      case atlbar = "R" && recall
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

*set colo to bg/bg
*@ 12,27 clear to 18,70
*set colo to n/bg
*@ 12,27 to 18,70 double
*set colo to n/bg
*@ 13,29 say "Replacing records in:"
*set colo to +w/bg
*@ 15,30 say "Stock Master :[       ] of [         ]"
*@ 16,30 say "Transaction  :[       ] of [         ]"
*@ 17,30 say "Old Trans.   :[       ] of [         ]"

save screen to atlscreen
atlmsg= 'please wait, updating all records...'
atllen= LEN(atlmsg)
set color to rb/rb
@ 11, 41-atllen/2-2 clear to 13, 41-atllen/2+atllen+1
set color to +w/rb
@ 11, 41-atllen/2-2 to 13, 41-atllen/2+atllen+1
@ 12, 41-atllen/2 say atlmsg

sele 2
ctr1=0
ctr2=0
go top
do while .not. eof()
   store chk_n to m_chk_n
   sele 1
   loca for chk_n=m_chk_n
   if found()
      repl chk_d with rep_chk->n_date
      unlock
   *   ctr1=ctr1+1
   endif
   sele 2
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
clear
close data

SET EXCLU OFF
set exact off
return


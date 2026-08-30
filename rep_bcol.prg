* program.....: Rep_BCol.prg
*             : allow editing of blank collection files.
*             : 01-21-09


SELECT 2
   USE CUSTFYL INDEX CUST_N
SELECT 1
   USE COLECFYL INDEX OR_N, OR_CD

DO BRDR1
&C_BODY

*            1         2         3         4         5         6         7
*   123456789012345678901234567890123456789012345678901234567890123456789012345678
* 9                  Collection No.    : xxxxxxxxxx
* 10                 Collection Date   : 99/99/9999
* 11                 --------------------------------------------------
* 12                 Customer Code     : xxxxxxxxxx
* 13                 Customer Name     : xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
* 14                 --------------------------------------------------
* 15                 Check/Cash Amount : 9,999,999.99
* 16

@ 9, 18 SAY 'Collection No.    :'
@10, 18 SAY 'Collection Date   :'
@11, 18 SAY '--------------------------------------------------'
@12, 18 SAY 'Customer Code     :'
@13, 18 SAY 'Customer Name     :'
@14, 18 SAY '--------------------------------------------------'
@15, 18 SAY 'Check/Cash Amount :'

set colo to
@ 21,00 clear to 24,79
choice= 'T'
action= 'SAY'


DO WHILE .T.

   sele 1
   SET COLO TO +W/BG
   @ 09,38 SAY COLEC_N    PICTURE '@!'
   set cent on
   @ 10,38 SAY COLEC_D    PICTURE '99/99/9999'
   set cent off 
   @ 12,38 SAY CUST_N     PICTURE '@!'
   if cust_m<>" "
      @ 13,38 SAY CUST_M  PICTURE '@!'
   else
      store cust_n to sv_cust_n
      sele 2
      seek sv_cust_n
      if .not. found()
         store space(30) to sv_cust_m
      else
         store cust_m to sv_cust_m
      endif
      @ 13,38 SAY SV_CUST_M  PICTURE '@!'
   endif
   sele 1
   set cent on
   @ 15,38 SAY TCHK_A     PICTURE '9,999,999.99'
   set cent off

   set colo to +gr, +*w/b
   do option6
   atlbar=choice

   do case
      case atlbar = "T" && top
           go top
      case atlbar = "B" && bottom
           go bott
      case atlbar = "N" && next
           skip
           if eof()
              save screen to atlscreen
              atlmsg="this is the last record, press any key..."
              atllen=len(atlmsg)
              set colo to rb/rb
              @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
              set colo to +w/rb
              @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
              @ 12,41-atllen/2 say atlmsg
              atlkeypress=inkey(0)
              restore screen from atlscreen
              go bott
              loop
           endif
      case atlbar = "V" && prev
           skip -1
           if bof()
              save screen to atlscreen
              atlmsg="this is the first record, press any key..."
              atllen=len(atlmsg)
              set colo to rb/rb
              @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
              set colo to +w/rb
              @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
              @ 12,41-atllen/2 say atlmsg
              atlkeypress=inkey(0)
              restore screen from atlscreen
              go top
              loop
           endif
      case atlbar = "F"  && find
           set exact off
           store space(10) to mSv_Sin
           store recno()   to mRecno
           set colo to ,+gr/r
           @ 9,38 get mSv_Sin pict '@!'
           read
           if mSv_Sin=" "
              set exact on
              loop
           endif
           seek trim(mSv_SiN)
           if .not. found()
              save screen to atlscreen
              atlmsg="collection # "+trim(mSv_Sin)+" not found! press any key to continue..."
              atllen=len(atlmsg)
              set colo to rb/rb
              @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
              set colo to +w/rb
              @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
              @ 12,41-atllen/2 say atlmsg
              atlkeypress=inkey(0)
              restore screen from atlscreen
              go mRecno
           endif
           set exact on
      case atlbar = "E"   && edit invoice no. and cust no.
           save screen to atlscreen
           store recno()   to mRecno
           mcolec_n= colec_n
           mcust_n = cust_n
           mcolec_d= colec_d 

           SET CENT ON
           set colo to ,+gr/r
           @ 09,38 get mcolec_n  PICTURE '@!'
           read

           seek mcolec_n
           if found()
              txtdata="Collection No. already used! Press any key to continue..."
              set colo to rb/rb
              @ 17,39-len(txtdata)/2-2 clear to 19,39+len(txtdata)/2+1
              set colo to +gr/rb
              @ 17,39-len(txtdata)/2-2 to 19,39+len(txtdata)/2+1
              set colo to +w/rb
              @ 18,39-len(txtdata)/2 say txtdata
              keypress=inkey(0)
              set colo to
              @17,39-len(txtdata)/2-2 clear to 19,39+len(txtdata)/2+1
              goto mrecno
              loop
           endif

           goto mrecno
           @ 10,38 get mcolec_d  PICTURE '99/99/9999'
           @ 12,38 get mcust_n   PICTURE '@!'
           read
           SET CENT OFF
           save screen to atlscreen2
           sele 2
           seek mcust_n
           if found()
              store cust_m to sv_cust_m
           else
              store space(30) to sv_cust_m
           endif
           sele 1
           @ 13,38 say sv_cust_m
           atlmsg="Post "+trim(mcolec_n)+" to the Collection (y/n)?"
           atllen=len(atlmsg)
           set colo to rb/rb
           @ 15,41-atllen/2-2 clear to 17,41-atllen/2+atllen+3
           set colo to +w/rb
           @ 15,41-atllen/2-2 to 17,41-atllen/2+atllen+3
           atloption=space(1)
           @ 16,41-atllen/2 say atlmsg
           @ 16,41-atllen/2+len(atlmsg)+1 get atloption pict '!' valid atloption$'YN' 
           read
           if atloption="Y"
              repl colec_n with mcolec_n
              repl colec_d with mcolec_d
              repl cust_n  with mcust_n
              repl cust_m  with sv_cust_m
              unlock
              restore screen from atlscreen2
           else
              restore screen from atlscreen
              go mRecno
              loop
           endif
      case atlbar = "D"   && delete the record
           if deleted()
              recall
           else
              delete
           endif
      case atlbar = "A"   && Edit remarks
      case atlbar = "Q"  && quit
           exit

   endcase
enddo

close data
set exact off
set cent off
return

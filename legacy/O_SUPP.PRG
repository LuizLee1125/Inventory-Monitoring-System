* program.....: O_Supp.prg
*             : old supplier file maintenance

SET CENTURY ON
SET EXACT ON
USE O_SPLYR INDEX O_SPLYRN

DO BRDR1
&C_BODY
@  6, 5  SAY 'Supplier Code    :'     
@  7, 5  SAY 'Supplier Name    :'
@  8, 5  SAY 'Supplier Address :'
@  9, 5  SAY 'Supplier City    :'
@ 10, 5  SAY 'Area Code        :'
@ 11, 5  SAY 'Supplier Tel No. :'
@ 13, 5  SAY 'Type / Terms     :           /   days'
@ 14, 5  SAY 'Credit Limit     :'
@ 15, 5  SAY 'Contact Person   :'
@ 16, 5  SAY 'Remarks          :'
@ 12, 46 SAY 'Last Purchase :'
@ 13, 46 SAY 'Purchases     :'
@ 14, 46 SAY 'Charges       :'
@ 15, 46 SAY 'Payments      :'
@ 16, 46 SAY 'Balance       :'
set colo to
@ 21,00 clear to 24,79

action="SAY"
choice="T"

DO WHILE .T.

   SET COLO TO +W/BG
   @ 6, 24 SAY Splyr_N   PICT '@!'
   @ 07,24 SAY Splyr_M   PICT '@!'
   @ 08,24 SAY Splyr_Ad  PICT '@!'
   @ 09,24 SAY Splyr_Ct  PICT '@!'
   @ 10,24 SAY Splyr_Ac  PICT '@!'
   @ 11,24 SAY Splyr_P   PICT '@!'
   @ 13,24 SAY Splyr_Tp  PICT '@!'
   @ 13,35 SAY Splyr_T   PICT '###'
   @ 14,24 SAY Splyr_Cl  PICT '#,###,###.##'
   @ 15,24 SAY Splyr_Cp  PICT '@!'
   @ 16,24 SAY Splyr_Rem PICT '@!'
   @ 12,62 SAY Splyr_Lt  PICT '99/99/9999'
   @ 13,62 SAY Splyr_Pur PICT '###,###,###.##'
   @ 14,64 SAY Splyr_Crg PICT '#,###,###.##'
   @ 15,62 SAY Splyr_Pay PICT '###,###,###.##'
   @ 1, 69 SAY User_M    PICT '@!'
   @ 16,64 SAY Splyr_Pur+Splyr_Crg-Splyr_Pay PICTURE '#,###,###.##'

*  set colo to +gr, +*w/b
*  @ 21,13 prompt " Top "
*  @ 21,18 prompt " Bottom "
*  @ 21,26 prompt " Next "
*  @ 21,32 prompt " Prev "
*  @ 21,38 prompt " Find "
*  @ 21,44 prompt " Add "
*  @ 21,49 prompt " Edit "
*  @ 21,55 prompt " Delete "
*  @ 21,63 prompt " Quit "
*  menu to atlbar

   do option6
   atlbar=choice

   do case
      case atlbar = "T"
           go top
      case atlbar = "B"
           go bott
      case atlbar = "N"
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
      case atlbar = "V"
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
      case atlbar = "F" && find
           set exact off
           atlrecno=recno()
           save screen to atlscrn2
           atlStkN=space(10)
           set colo to ,+gr/r
           @ 6,24 get atlStkN pict "@!"
           read
           if atlStkN=" "
              set exact on
              restore screen from atlscrn2
              loop
           endif
           atlStkN=trim(atlStkN)
           seek atlStkN
           if .not. found()
              set colo to b/b
              @ 12,11 clear to 14,69
              set colo to +gr/b
              @ 12,11 to 14,69
              set colo to +w/b,+gr/rb
              @ 13,13 say "Supplier Code not found! Press any key to continue..."
              keypress=inkey(0)
              rest screen from atlscrn2
              go atlrecno
              set exact on
              loop
           endif
           set exact on

      case atlbar = "A"  && add
           store space(10) to mSplyr_N
           store recno()   to mRecno
           set colo to ,+gr/b
           @ 6,24 get mSplyr_N pict '@!'
           read
           if mSplyr_N=" "
              loop
           endif
           seek trim(mSplyr_N)
           if found()
              save screen to atlscreen
              atlmsg="supplier code "+trim(mCust_n)+" already exists, press any key..."
              atllen=len(atlmsg)
              set colo to rb/rb
              @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
              set colo to +w/rb
              @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
              @ 12,41-atllen/2 say atlmsg
              atlkeypress=inkey(0)
              restore screen from atlscreen
              go mRecno
              loop
           endif
           mSplyr_M   = space(30)
           mSplyr_Ad  = space(30)
           mSplyr_Ct  = space(30)
           mSplyr_Ac  = space(10)
           mSplyr_P   = space(20)
           mSplyr_Tp  = space(10)
           mSplyr_T   = 0
           mSplyr_Cl  = 0
           mSplyr_Cp  = space(10)
           mSplyr_Rem = space(20)
           mSplyr_Lt  = ctod('  /  /    ')
           mSplyr_Pur = 0
           mSplyr_Crg = 0
           mSplyr_Pay = 0

           set colo to ,+w/bg
           @ 07,24 GET mSplyr_M   PICT '@!'
           @ 08,24 GET mSplyr_Ad  PICT '@!'
           @ 09,24 GET mSplyr_Ct  PICT '@!'
           @ 10,24 GET mSplyr_Ac  PICT '@!'
           @ 11,24 GET mSplyr_P   PICT '@!'
           @ 13,24 GET mSplyr_Tp  PICT '@!'
           @ 13,35 GET mSplyr_T   PICT '###'
           @ 14,24 GET mSplyr_Cl  PICT '#,###,###.##'      
           @ 15,24 GET mSplyr_Cp  PICT '@!'
           @ 16,24 GET mSplyr_Rem PICT '@!'
           @ 12,62 GET mSplyr_Lt  PICT '99/99/9999'
           @ 13,62 GET mSplyr_Pur PICT '###,###,###.##'
           @ 14,64 GET mSplyr_Crg PICT '#,###,###.##'
           @ 15,62 GET mSplyr_Pay PICT '###,###,###.##'
           read
           @ 16,64 SAY mSplyr_Pur+mSplyr_Crg-mSplyr_Pay PICTURE '#,###,###.##'

           save screen to atlscreen
           atlmsg="Add "+trim(mSplyr_n)+" to the master file (y/n)?"
           atllen=len(atlmsg)
           set colo to rb/rb
           @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+3
           set colo to +w/rb
           @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+3
           atloption=space(1)
           @ 12,41-atllen/2 say atlmsg
           @ 12,41-atllen/2+len(atlmsg)+1 get atloption pict '!' valid atloption$'YN'
           read
           if atloption="Y"
              append blank
              repl Splyr_M   with mSplyr_M 
              repl Splyr_Ad  with mSplyr_Ad
              repl Splyr_Ad  with mSplyr_Ad
              repl Splyr_Ac  with mSplyr_Ac
              repl Splyr_P   with mSplyr_P 
              repl Splyr_P   with mSplyr_P 
              repl Splyr_T   with mSplyr_T 
              repl Splyr_Cl  with mSplyr_Cl
              repl Splyr_Cp  with mSplyr_Cp
              repl Splyr_Rem with mSplyr_Rem 
              repl Splyr_Lt  with mSplyr_Lt  
              repl Splyr_Pur with mSplyr_Pur 
              repl Splyr_Crg with mSplyr_Crg 
              repl Splyr_Pay with mSplyr_Pay
              repl Splyr_Bal with mSplyr_Pur+mSplyr_Crg-mSplyr_Pay
              unlock
              restore screen from atlscreen
           else
              restore screen from atlscreen
              go mRecno
              loop
           endif

      case atlbar = "E" && edit
           store Splyr_N to mSplyr_N
           store recno() to mRecno
           set colo to ,+gr/b
           @ 6,24 get mSplyr_N pict '@!'
           read
           if mSplyr_N=" "
              loop
           endif
           seek trim(mSplyr_N)
           if found() .and. recno()<>mRecno
              save screen to atlscreen
              atlmsg="supplier code "+trim(mCust_n)+" already exists, press any key..."
              atllen=len(atlmsg)
              set colo to rb/rb
              @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
              set colo to +w/rb
              @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
              @ 12,41-atllen/2 say atlmsg
              atlkeypress=inkey(0)
              restore screen from atlscreen
              go mRecno
              loop
           endif
           mSplyr_M   = Splyr_M
           mSplyr_Ad  = Splyr_Ad
           mSplyr_Ct  = Splyr_Ct
           mSplyr_Ac  = Splyr_Ac
           mSplyr_P   = Splyr_P 
           mSplyr_Tp  = Splyr_Tp
           mSplyr_T   = Splyr_T 
           mSplyr_Cl  = Splyr_Cl
           mSplyr_Cp  = Splyr_Cp  
           mSplyr_Rem = Splyr_Rem
           mSplyr_Lt  = Splyr_Lt 
           mSplyr_Pur = Splyr_Pur
           mSplyr_Crg = Splyr_Crg
           mSplyr_Pay = Splyr_Pay

           set colo to ,+w/bg
           @ 07,24 GET mSplyr_M   PICT '@!'
           @ 08,24 GET mSplyr_Ad  PICT '@!'
           @ 09,24 GET mSplyr_Ct  PICT '@!'
           @ 10,24 GET mSplyr_Ac  PICT '@!'
           @ 11,24 GET mSplyr_P   PICT '@!'
           @ 13,24 GET mSplyr_Tp  PICT '@!'
           @ 13,35 GET mSplyr_T   PICT '###'
           @ 14,24 GET mSplyr_Cl  PICT '#,###,###.##'      
           @ 15,24 GET mSplyr_Cp  PICT '@!'
           @ 16,24 GET mSplyr_Rem PICT '@!'
           @ 12,62 GET mSplyr_Lt  PICT '99/99/9999'
           @ 13,62 GET mSplyr_Pur PICT '###,###,###.##'
           @ 14,64 GET mSplyr_Crg PICT '#,###,###.##'
           @ 15,62 GET mSplyr_Pay PICT '###,###,###.##'
           read
           @ 16,64 SAY mSplyr_Pur+mSplyr_Crg-mSplyr_Pay PICTURE '#,###,###.##'
           save screen to atlscreen
           atlmsg="Post edited "+trim(mSplyr_n)+" to the master file (y/n)?"
           atllen=len(atlmsg)
           set colo to rb/rb
           @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+3
           set colo to +w/rb
           @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+3
           atloption=space(1)
           @ 12,41-atllen/2 say atlmsg
           @ 12,41-atllen/2+len(atlmsg)+1 get atloption pict '!' valid atloption$'YN' 
           read
           if atloption="Y"
              repl Splyr_M   with mSplyr_M 
              repl Splyr_Ad  with mSplyr_Ad
              repl Splyr_Ad  with mSplyr_Ad
              repl Splyr_Ac  with mSplyr_Ac
              repl Splyr_P   with mSplyr_P 
              repl Splyr_P   with mSplyr_P 
              repl Splyr_T   with mSplyr_T 
              repl Splyr_Cl  with mSplyr_Cl
              repl Splyr_Cp  with mSplyr_Cp
              repl Splyr_Rem with mSplyr_Rem 
              repl Splyr_Lt  with mSplyr_Lt  
              repl Splyr_Pur with mSplyr_Pur 
              repl Splyr_Crg with mSplyr_Crg 
              repl Splyr_Pay with mSplyr_Pay
              repl Splyr_Bal with mSplyr_Pur+mSplyr_Crg-mSplyr_Pay
              unlock
              restore screen from atlscreen
           else
              restore screen from atlscreen
              go mRecno
              loop
           endif

      case atlbar = "D"  && delete
           save screen to atlscreen
           stor recno() to mrecno1
           stor Splyr_N to mSplyr_N
           skip -1
           if .not. bof()
              store recno() to mrecno2
           else
              go top
              skip
              store recno() to mrecno2
           endif
           go mrecno1

           atlmsg="Are you sure you want to delete "+trim(mSplyr_N)+" (y/n)?"
           atllen=len(atlmsg)
           set colo to rb/rb
           @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+3
           set colo to +w/rb
           @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+3
           atloption=space(1)
           @ 12,41-atllen/2 say atlmsg
           @ 12,41-atllen/2+len(atlmsg)+1 get atloption pict '!' valid atloption$'YN'
           read
           if atloption="Y"
              dele
              restore screen from atlscreen
              go mrecno2
           else
              restore screen from atlscreen
              go mRecno1
              loop
           endif   
      case atlbar = "Q"  && quit
           exit

   endcase
enddo

close data
set century off
set exact off
return


* program.....: CustFyl.prg

SET CENTURY ON
SET EXACT ON
USE O_CUSFYL INDEX O_CUST_N

DO BRDR1
&C_BODY
@  4, 4  SAY 'Customer Code       :'
@  5, 4  SAY 'Customer Name       :'
@  6, 4  SAY 'Customer Address    :'
@  7, 4  SAY 'Customer City       :'
@  8, 4  SAY 'Area Code           :'
@  9, 4  SAY 'Customer Tel No.    :'
@  9, 47 SAY 'Last Purchase :'
@ 10, 4  SAY 'Start Date          :'
@ 10, 47 SAY 'Purchases     :'
@ 11, 4  SAY 'Price Category      :'
@ 11, 47 SAY 'Charges       :'
@ 12, 4  SAY 'Type / Terms        :           /   days'
@ 12, 47 SAY 'Payments      :'
@ 13, 4  SAY 'Credit Limit        :'
@ 13, 47 SAY 'Unclear Checks:'
@ 14, 4  SAY 'Contact Person      :'
@ 14, 47 SAY 'Balance       :'
@ 15, 4  SAY 'Salesman            :'
@ 16, 4  SAY 'Proprietor Name     :'
@ 17, 4  SAY 'Proprietor Address  :'
@ 18, 4  SAY 'Proprietor Tel. No. :'
@ 19, 4  SAY 'Remarks             :'
set colo to
@ 21,00 clear to 24,79

action="SAY"
choice="T"

DO WHILE .T.

   SET COLO TO +W/BG
   @ 1, 69 say User_M   PICTURE '@!'
   @ 4, 26 say Cust_N   PICT '@!'
   @ 05,26 say Cust_M   PICT '@!'
   @ 06,26 say Cust_Ad  PICT '@!'
   @ 07,26 say Cust_Ct  PICT '@!'
   @ 08,26 say Cust_Ac  PICT '@!'
   @ 09,26 say Cust_P   PICT '@!'
   @ 09,63 say Cust_Lt  PICT '99/99/9999'
   @ 10,26 say Cust_Sd  PICT '99/99/9999'
   @ 10,63 say Cust_Pur PICT '###,###,###.##'
   @ 11,26 say Cust_Pc  PICT '@!'
   @ 11,65 say Cust_Crg PICT '#,###,###.##'
   @ 12,26 say Cust_Tp  PICT '@!'
   @ 12,37 say Cust_T   PICT '###'
   @ 12,63 say Cust_Pay PICT '###,###,###.##'
   @ 13,26 say Cust_Cl  PICT '#,###,###.##'
   @ 13,65 say Cust_Flt PICT '#,###,###.##'
   @ 14,26 say Cust_Cp  PICT '@!'
   @ 14,65 say Cust_Pur+Cust_Crg-Cust_Pay PICT '#,###,###.##'
   @ 15,26 say Cust_S   PICT '@!'
   @ 16,26 say Prop_M   PICT '@!'
   @ 17,26 say Prop_Ad  PICT '@!'
   @ 18,26 say Prop_P   PICT '@!'
   @ 19,26 say Cust_Rem PICT '@!'

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
      case atlbar = "F"  && find
           set exact off
           store space(10) to mCust_N
           store recno()   to mRecno
           set colo to ,+gr/r
           @ 4,26 get mCust_N pict '@!'
           read
           if mCust_N=" "
              set exact on
              loop
           endif
           seek trim(mCust_N)
           if .not. found()
              save screen to atlscreen
              atlmsg="customer code "+trim(mCust_n)+" not found! press any key to continue..."
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
      case atlbar = "A"  && add
              save screen to atlscreen
              atlmsg="sorry, ADD functionality is not feasible, press any key..."
              atllen=len(atlmsg)
              set colo to rb/rb
              @ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+1
              set colo to +w/rb
              @ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+1
              @ 12,41-atllen/2 say atlmsg
              atlkeypress=inkey(0)
              restore screen from atlscreen
              loop

      case atlbar = "E"  && edit
           store Cust_n to mcust_N
           store recno()   to mRecno
           set colo to ,+gr/r
           @ 4,26 get mCust_N pict '@!'
           read
           if mCust_N=" "
              loop
           endif
           seek trim(mCust_N)
           if found() .and. recno()<>mRecno
              save screen to atlscreen
              atlmsg="Customer code "+trim(mCust_n)+" already exists, press any key..."
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
           mCust_N   = Cust_N
           mCust_M   = Cust_M
           mCust_Ad  = Cust_Ad 
           mCust_Ct  = Cust_Ct 
           mCust_Ac  = Cust_Ac 
           mCust_P   = Cust_P  
           mCust_Sd  = Cust_Sd 
           mCust_Pc  = Cust_Pc 
           mCust_Tp  = Cust_Tp 
           mCust_T   = Cust_T  
           mCust_Cl  = Cust_Cl 
           mCust_Cp  = Cust_Cp 
           mCust_s   = Cust_S  
           mProp_M   = Prop_M  
           mProp_Ad  = Prop_Ad 
           mProp_P   = Prop_P  
           mCust_Rem = Cust_Rem
           mCust_Lt  = Cust_Lt 
           mCust_Pur = Cust_Pur
           mCust_Crg = Cust_Crg
           mCust_Pay = Cust_Pay
           mCust_Flt = Cust_Flt
           set colo to ,+w/bg
           @ 05,26 get mCust_M   PICT '@!'
           @ 06,26 get mCust_Ad  PICT '@!'
           @ 07,26 get mCust_Ct  PICT '@!'
           @ 08,26 get mCust_Ac  PICT '@!'
           @ 09,26 get mCust_P   PICT '@!'
           @ 09,63 get mCust_Lt  PICT '99/99/9999'
           @ 10,26 get mCust_Sd  PICT '99/99/9999'
           @ 11,26 get mCust_Pc  PICT '@!'
           @ 12,26 get mCust_Tp  PICT '@!'
           @ 12,37 get mCust_T   PICT '###'
           @ 13,26 get mCust_Cl  PICT '#,###,###.##'
           @ 14,26 get mCust_Cp  PICT '@!'
           @ 15,26 get mCust_S   PICT '@!'
           @ 16,26 get mProp_M   PICT '@!'
           @ 17,26 get mProp_Ad  PICT '@!'
           @ 18,26 get mProp_P   PICT '@!'
           @ 19,26 get mCust_Rem PICT '@!'
           @ 10,63 get mCust_Pur PICT '###,###,###.##'
           @ 11,65 get mCust_Crg PICT '#,###,###.##'
           @ 12,63 get mCust_Pay PICT '###,###,###.##'
           @ 13,65 get mCust_Flt PICT '#,###,###.##'
           read
           save screen to atlscreen
           atlmsg="Post edited "+trim(mCust_n)+" to the master file (y/n)?"
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
              repl Cust_N   with mCust_N
              repl Cust_M   with mCust_M
              repl Cust_Ad  with mCust_Ad 
              repl Cust_Ct  with mCust_Ct 
              repl Cust_Ac  with mCust_Ac 
              repl Cust_P   with mCust_P  
              repl Cust_Sd  with mCust_Sd 
              repl Cust_Pc  with mCust_Pc 
              repl Cust_Tp  with mCust_Tp 
              repl Cust_T   with mCust_T  
              repl Cust_Cl  with mCust_Cl 
              repl Cust_Cp  with mCust_Cp 
              repl Cust_s   with mCust_S  
              repl Prop_M   with mProp_M  
              repl Prop_Ad  with mProp_Ad 
              repl Prop_P   with mProp_P  
              repl Cust_Rem with mCust_Rem
              repl Cust_Lt  with mCust_Lt 
              repl Cust_Pur with mCust_Pur
              repl Cust_Crg with mCust_Crg
              repl Cust_Pay with mCust_Pay
              repl Cust_Flt with mCust_Flt
              repl Cust_Bal with mCust_Pur+mCust_Crg-mCust_Pay
              repl User_M   with mUser
              unlock
              restore screen from atlscreen
           else
              restore screen from atlscreen
              go mRecno
              loop
           endif

       case atlbar = "D" && delete
           save screen to atlscreen
           stor recno() to mrecno1
           stor cust_n to mCust_n
           skip -1
           if .not. bof()
              store recno() to mrecno2
           else
              go top
              skip
              store recno() to mrecno2
           endif
           go mrecno1

           atlmsg="Are you sure you want to delete "+trim(mCust_n)+" (y/n)?"
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
set exact off
return


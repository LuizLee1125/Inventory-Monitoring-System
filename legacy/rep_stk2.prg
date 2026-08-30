* program.....: Rep_Stk2.prg
*             : allows editing of blank stk codes in transaction file 
*             : 07-30-10

SELECT 3
   USE CUSTFYL INDEX CUST_N
SELECT 2
   USE STKFYL INDEX STK_N
SELECT 1
   USE Stkrec index Trans_id, Trans_cn, Si_id
   set order to 2
   seek "SA"
   SET ORDER TO 1
DO BRDR1
&C_BODY

*            1         2         3         4         5         6         7
*   123456789012345678901234567890123456789012345678901234567890123456789012345678
* 9                  Invoice Number    : xxxxxxxxxx
* 10                 Invoice Date      : 99/99/9999
* 11                 Customer Code     : xxxxxxxxxx
* 12                 Customer Name     : xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
* 13                 --------------------------------------------------
* 14                 Stock Code        : 9,999,999.99
* 15                 Stock Description : xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
* 16                 Quantity Ordered  : 9,999 XXXXX

@ 9, 18 SAY 'Invoice Number    :'
@10, 18 SAY 'Invoice Date      :'
@11, 18 SAY 'Customer Code     :'
@12, 18 SAY 'Customer Name     :'
@13, 18 SAY '--------------------------------------------------'
@14, 18 SAY 'Stock Code        :'
@15, 18 SAY 'Stock Description :'
@16, 18 SAY 'Quantity Ordered  :'

set colo to
@ 21,00 clear to 24,79
choice= 'T'
action= 'SAY'


DO WHILE .T.
         
   SELE 1
   SET COLO TO +W/BG
   @ 09,38 SAY TRANS_N    PICTURE '@!'
   set cent on
   @ 10,38 SAY TRANS_D    PICTURE '99/99/9999'
   set cent off 
   @ 11,38 SAY CUST_N     PICTURE '@!'
   mcust_n = cust_n
   sele 3
   seek mcust_n
   if found()
      mcust_m = cust_m
   else
      mcust_m = space(15)
   endif
   sele 1
   @ 12,38 SAY mCUST_M    PICTURE '@!'
   @ 14,38 SAY STK_N      PICTURE '@!'
   @ 15,38 SAY STK_M      PICTURE '@!'
   @ 16,38 SAY ISSUE_Q    PICTURE '9,999'
   @ 16,44 SAY ISSUE_U    PICTURE '@!'

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
           loop
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
           mStk_n = stk_n
           mStk_m = stk_m

           set colo to ,+gr/r
           @ 14,38 get mStk_n  PICTURE '@!'
           read

           sele 2
           seek mStk_n
           if found()
              if stk_m<>mStk_m
                 txtdata="Code does not match description. Press any key to continue..."
                 set colo to rb/rb
                 @ 17,39-len(txtdata)/2-2 clear to 19,39+len(txtdata)/2+1
                 set colo to +gr/rb
                 @ 17,39-len(txtdata)/2-2 to 19,39+len(txtdata)/2+1
                 set colo to +w/rb
                 @ 18,39-len(txtdata)/2 say txtdata
                 keypress=inkey(0)
                 set colo to
                 @17,39-len(txtdata)/2-2 clear to 19,39+len(txtdata)/2+1
                 sele 1
                 goto mrecno
                 loop
               endif
           endif
           sele 1
           goto mrecno
           @ 14,38 say mStk_n
           atlmsg="Post "+trim(mStk_n)+" to this Invoice...(y/n)?"
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
              repl stk_n   with mStk_n  
              unlock
              restore screen from atlscreen
              go top
           else
              restore screen from atlscreen
              go mRecno
              loop
           endif
      case atlbar = "D"   && delete the record
           loop
           if deleted()
              recall
           else
              delete
           endif
      case atlbar = "A"   && Edit remarks
           loop
      case atlbar = "Q"  && quit
           exit

   endcase
enddo

close data
set exact off
set cent off
return

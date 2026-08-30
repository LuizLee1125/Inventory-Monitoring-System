* program.....: Lst_TCM.prg
*             : extract data per territory, per customer monthly sales summary
*             : 07/10/2004


sele 1
     use custfyl inde cust_n
sele 2
     use sifyl index si_dinv
set excl on
SET SAFE OFF
sele 3
     SET SAFE OFF
     use rpt_stc index rpi_stc   && index on cust_n to rpi_stc
     zap
SET SAFE ON
set excl off

inc_yr=2004
atlmsg="enter inclusive year..."
atllen=len(atlmsg)
set colo to rb/rb
@ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+6
set colo to +w/rb
@ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+6
@ 12,41-atllen/2 say atlmsg
@ 12,41-atllen/2+len(atlmsg)+1 get inc_yr pict '9999'
read
atlmsg="please wait, extracting data....."
atllen=len(atlmsg)
set colo to rb/rb
@ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+3
set colo to +w/rb
@ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+3
@ 12,41-atllen/2 say atlmsg

sele 1
do while .not. eof()
   sele 3
   appe blan
   repl cust_n   with custfyl->cust_n
   repl cust_m   with custfyl->cust_m
   repl cust_ad  with custfyl->cust_ad
   repl cust_ct  with custfyl->cust_ct
   repl cust_ac  with custfyl->cust_ac
   repl cust_s   with custfyl->cust_s
   repl cust_p   with custfyl->cust_p
   repl cust_tp  with custfyl->cust_tp
   repl cust_t   with custfyl->cust_t
   repl cust_cp  with custfyl->cust_cp
   repl prop_m   with custfyl->prop_m
   repl tin      with custfyl->tin
   repl lto      with custfyl->lto
   repl lto_exp  with custfyl->lto_exp
   repl calls    with custfyl->calls
   repl ndays    with custfyl->ndays
   repl cust_cl  with custfyl->cust_cl
   repl mtarget  with custfyl->mtarget
   repl check_e  with custfyl->check_e
   repl prop_ad  with custfyl->prop_ad
   repl prop_ad2 with custfyl->prop_ad2
   repl prop_p   with custfyl->prop_p
   repl cust_lt  with custfyl->cust_lt
   repl cust_sd  with custfyl->cust_sd
   repl eval_rem with custfyl->eval_rem
   repl cust_rem with custfyl->cust_rem
   repl inv_a_1  with 0
   repl inv_a_2  with 0
   repl inv_a_3  with 0
   repl inv_a_4  with 0
   repl inv_a_5  with 0
   repl inv_a_6  with 0
   repl inv_a_7  with 0
   repl inv_a_8  with 0
   repl inv_a_9  with 0
   repl inv_a_10 with 0
   repl inv_a_11 with 0
   repl inv_a_12 with 0
   unlock
   sele 1
   skip
enddo

sele 2
seek str(inc_yr,4)

SET EXACT ON
do while .not. eof() .and. year(inv_d)=inc_yr
   stor cust_n to sv_cust_n
   sele 3
   seek sv_cust_n
   do case
      case month(sifyl->inv_d)=1
           repl inv_a_1 with inv_a_1+sifyl->net_a
      case month(sifyl->inv_d)=2
           repl inv_a_2 with inv_a_2+sifyl->net_a
      case month(sifyl->inv_d)=3
           repl inv_a_3 with inv_a_3+sifyl->net_a
      case month(sifyl->inv_d)=4
           repl inv_a_4 with inv_a_4+sifyl->net_a
      case month(sifyl->inv_d)=5
           repl inv_a_5 with inv_a_5+sifyl->net_a
      case month(sifyl->inv_d)=6
           repl inv_a_6 with inv_a_6+sifyl->net_a
      case month(sifyl->inv_d)=7
           repl inv_a_7 with inv_a_7+sifyl->net_a
      case month(sifyl->inv_d)=8
           repl inv_a_8 with inv_a_8+sifyl->net_a
      case month(sifyl->inv_d)=9
           repl inv_a_9 with inv_a_9+sifyl->net_a
      case month(sifyl->inv_d)=10
           repl inv_a_10 with inv_a_10+sifyl->net_a
      case month(sifyl->inv_d)=11
           repl inv_a_11 with inv_a_11+sifyl->net_a
      case month(sifyl->inv_d)=12
           repl inv_a_12 with inv_a_12+sifyl->net_a
   endcase
   unlock
   sele 2
   skip
enddo

sele 3
set safe off
sort on cust_s, cust_n to srt_stc
set safe on

atlmsg="finished extracting data... File: Srt_STC.dbf  press any key..."
atllen=len(atlmsg)
set colo to rb/rb
@ 11,41-atllen/2-2 clear to 13,41-atllen/2+atllen+3
set colo to +w/rb
@ 11,41-atllen/2-2 to 13,41-atllen/2+atllen+3
@ 12,41-atllen/2 say atlmsg
atlkey=inkey(0)
clear
close data
SET EXACT OFF
return

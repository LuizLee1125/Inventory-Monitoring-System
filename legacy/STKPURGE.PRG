* program.....: StkPurge.prg
* module......: Inventory; purging of records
* modified....: 04/01/99

set exclusive on
set deleted on

&C_CLEAR
CLEAR
&C_BRDR
@ 0, 15 TO 3, 64 DOUBLE
&C_HEAD
@ 1, 16 SAY SPACE(48)
@ 1, 16 SAY SPACE((48-LEN(company))/2)+company
@ 2, 16 SAY '           INVENTORY MONITORING SYSTEM          '

atloption=" "
set colo to +W/RB
@ 10,16 say " Proceed to archive the transaction file (y/n)   " 
set colo to b
@ 10,65 say chr(220)
@ 11,17 say repl(chr(223),49)
@ 10,63 get atloption pict "Y"
read

if atloption="N"
   set exclu off
   set delet on
   return
endif

set colo to +W/B
@ 10,16 say " reindexing the Sales & Purchases file first !!! "
set colo to bg
@ 10,65 say chr(220)
@ 11,17 say repl(chr(223),49)
set colo to *gr
@ 24,65 say "please wait..."

use O_sifyl
copy stru to O_sitmp
use

sele 7
   use O_sitmp

sele 6
   use O_sifyl index Os_si_d, Os_si_n, Os_si_cd

sele 5
   use O_Purfyl index Op_pur_d, Op_pur_n

sele 4
   use Sifyl
   INDEX ON inv_n TO SI_N
   INDEX ON inv_d TO SI_D
   INDEX ON paid+cust_n+STR(YEAR(inv_d),4)+SUBSTR(DTOC(inv_d),1,5) TO SI_CD
   set index to SI_D, SI_N, SI_CD

sele 3
   USE PURFYL
   INDEX ON inv_n TO PUR_N
   INDEX ON inv_d TO PUR_D
   set index to Pur_d, Pur_N

set colo to +w/b
@ 10,16 say "   reindexing the stock transaction file now !!!  "

set colo to bg
@ 24,31 say "This might take a longer period."

sele 2
   use O_Stkrec index O_Tid, O_Sid, O_Cn

sele 1
   use Stkrec && index trans_cd, trans_cn, trans_id, si_id

   SET CENTURY OFF
   INDEX ON trans_c+STR(YEAR(trans_d),4)+SUBSTR(DTOC(trans_d),1,5) to TRANS_CD
   SET CENTURY ON
   set index to trans_cd, trans_cn, trans_id, si_id

seek "S"
sdate=trans_d
go bott
edate=date()

set colo to
@ 10,0 clear to 24,79
set colo to b/b
@ 07,24 clear to 12,54
set colo to +w/rb
@ 06,24 say "   Purge Transaction Records   "
set colo to bg/b
@ 08,26 say "starting date: [          ]"
@ 09,26 say "ending date  : [          ]"
set colo to n/w,n/w
@ 08,42 say sdate pict "99/99/9999"
@ 09,42 get edate pict "99/99/9999"
read

set century off

atl_opt=" "
set colo to bg/b
@ 11,26 say "are you sure (y/n)?"
set colo to n/w
@ 11,46 get atl_opt pict "Y"
read

set colo to

if atl_opt="N"
   set century off
   set deleted on
   close data
   clear
   return
endif

Seek "I"
set colo to b/b
@ 07,24 clear to 12,54
set colo to +bg/b
@ 08,26 say chr(254)+" Inventory Adjustments"
set colo to bg/b
@ 09,28 say "# records copied:"
ctr=0
do while .not. eof() .and. trans_c="I" .and. trans_d <= edate
      ctr=ctr+1
      @ 09,46 say ctr pict "999,999"
      dele
      sele 2
      appe blank
      repl trans_c  with stkrec->trans_c
      repl trans_n  with stkrec->trans_n
      repl trans_d  with stkrec-> trans_d
      repl cust_n   with stkrec-> cust_n
      repl cust_s   with stkrec-> cust_s
      repl stk_n    with stkrec-> stk_n
      repl stk_m    with stkrec-> stk_m
      repl stk_pc   with stkrec-> stk_pc
      repl stk_ac   with stkrec-> stk_ac
      repl qty_s    with stkrec-> qty_s
      repl qty_pq   with stkrec-> qty_pq
      repl qty_pu   with stkrec-> qty_pu
      repl qty1     with stkrec-> qty1
      repl qty2     with stkrec-> qty2
      repl qty3     with stkrec-> qty3
      repl qty1L    with stkrec-> qty1L
      repl stk_dv   with stkrec-> stk_dv
      repl stk_cat  with stkrec-> stk_cat
      repl issue_d  with stkrec-> issue_d
      repl issue_q  with stkrec-> issue_q
      repl issue_fg with stkrec-> issue_fg
      repl issue_u  with stkrec-> issue_u
      repl issue_cp with stkrec-> issue_cp
      repl issue_p  with stkrec-> issue_p
      repl dcount1  with stkrec-> dcount1
      repl dcount2  with stkrec-> dcount2
      repl dcount3  with stkrec-> dcount3
      repl t_prys   with stkrec-> t_prys
      repl t_ac     with stkrec-> t_ac
      repl t_pc     with stkrec-> t_pc
      repl lot_n    with stkrec-> lot_n
      repl expiry_d with stkrec-> expiry_d
      repl user_m   with stkrec-> user_m
      sele 1
      skip
enddo
@ 09,46 say ctr pict "999,999"

Seek "R"
set colo to +bg/b
@ 10,26 say chr(254)+" Sales Returns"
set colo to bg/b
@ 11,28 say "# records copied:"
ctr=0
do while .not. eof() .and. trans_c="R" .and. trans_d <= edate
      ctr=ctr+1
      @ 11,46 say ctr pict "999,999"
      dele
      sele 2
      appe blank
      repl trans_c  with stkrec->trans_c
      repl trans_n  with stkrec->trans_n
      repl trans_d  with stkrec-> trans_d
      repl cust_n   with stkrec-> cust_n
      repl cust_s   with stkrec-> cust_s
      repl stk_n    with stkrec-> stk_n
      repl stk_m    with stkrec-> stk_m
      repl stk_pc   with stkrec-> stk_pc
      repl stk_ac   with stkrec-> stk_ac
      repl qty_s    with stkrec-> qty_s
      repl qty_pq   with stkrec-> qty_pq
      repl qty_pu   with stkrec-> qty_pu
      repl qty1     with stkrec-> qty1
      repl qty2     with stkrec-> qty2
      repl qty3     with stkrec-> qty3
      repl qty1L    with stkrec-> qty1L
      repl stk_dv   with stkrec-> stk_dv
      repl stk_cat  with stkrec-> stk_cat
      repl issue_d  with stkrec-> issue_d
      repl issue_q  with stkrec-> issue_q
      repl issue_fg with stkrec-> issue_fg
      repl issue_u  with stkrec-> issue_u
      repl issue_cp with stkrec-> issue_cp
      repl issue_p  with stkrec-> issue_p
      repl dcount1  with stkrec-> dcount1
      repl dcount2  with stkrec-> dcount2
      repl dcount3  with stkrec-> dcount3
      repl t_prys   with stkrec-> t_prys
      repl t_ac     with stkrec-> t_ac
      repl t_pc     with stkrec-> t_pc
      repl lot_n    with stkrec-> lot_n
      repl expiry_d with stkrec-> expiry_d
      repl user_m   with stkrec-> user_m
      sele 1
      skip
enddo

seek "P"
set colo to b/b
@ 07,24 clear to 12,54
set colo to +bg/b
@ 08,26 say chr(254)+" Purchases"
set colo to bg/b
@ 09,28 say "# records copied:"
ctr=0
do while .not. eof() .and. trans_c="P" .and. trans_d <= edate
      ctr=ctr+1
      @ 09,46 say ctr pict "999,999"
      dele
      sele 2
      appe blank
      repl trans_c  with stkrec->trans_c
      repl trans_n  with stkrec->trans_n
      repl trans_d  with stkrec-> trans_d
      repl cust_n   with stkrec-> cust_n
      repl cust_s   with stkrec-> cust_s
      repl stk_n    with stkrec-> stk_n
      repl stk_m    with stkrec-> stk_m
      repl stk_pc   with stkrec-> stk_pc
      repl stk_ac   with stkrec-> stk_ac
      repl qty_s    with stkrec-> qty_s
      repl qty_pq   with stkrec-> qty_pq
      repl qty_pu   with stkrec-> qty_pu
      repl qty1     with stkrec-> qty1
      repl qty2     with stkrec-> qty2
      repl qty3     with stkrec-> qty3
      repl qty1L    with stkrec-> qty1L
      repl stk_dv   with stkrec-> stk_dv
      repl stk_cat  with stkrec-> stk_cat
      repl issue_d  with stkrec-> issue_d
      repl issue_q  with stkrec-> issue_q
      repl issue_fg with stkrec-> issue_fg
      repl issue_u  with stkrec-> issue_u
      repl issue_cp with stkrec-> issue_cp
      repl issue_p  with stkrec-> issue_p
      repl dcount1  with stkrec-> dcount1
      repl dcount2  with stkrec-> dcount2
      repl dcount3  with stkrec-> dcount3
      repl t_prys   with stkrec-> t_prys
      repl t_ac     with stkrec-> t_ac
      repl t_pc     with stkrec-> t_pc
      repl lot_n    with stkrec-> lot_n
      repl expiry_d with stkrec-> expiry_d
      repl user_m   with stkrec-> user_m
      sele 1
      skip
enddo

***
sele 4
go top
set colo to +bg/b
@ 10,26 say chr(254)+" Sales Master File"
set colo to bg/b
@ 11,28 say "# records copied:"
ctr=0
do while .not. eof() .and. inv_d <= edate
   if paid="T"
      ctr=ctr+1
      @ 11,46 say ctr pict "999,999"
      sele 4
      dele
      sele 7
      appe blank
      repl inv_n    with sifyl->inv_n
      repl cust_n   with sifyl->cust_n
      repl cust_m   with sifyl->cust_m
      repl cust_ad  with sifyl->cust_ad
      repl cust_ct  with sifyl->cust_ct
      repl cust_ac  with sifyl->cust_ac
      repl ad_n     with sifyl->ad_n
      repl co_m     with sifyl->co_m
      repl co_ad    with sifyl->co_ad
      repl co_ct    with sifyl->co_ct
      repl cust_s   with sifyl->cust_s
      repl inv_d    with sifyl->inv_d
      repl cust_tp  with sifyl->cust_tp
      repl cust_t   with sifyl->cust_t
      repl si_rem   with sifyl->si_rem
      repl cust_pc  with sifyl->cust_pc
      repl inv_c    with sifyl->inv_c
      repl inv_pc   with sifyl->inv_pc
      repl inv_a    with sifyl->inv_a
      repl dcount1  with sifyl->dcount1
      repl dcount2  with sifyl->dcount2
      repl dcount3  with sifyl->dcount3
      repl net_a    with sifyl->net_a
      repl user_m   with sifyl->user_m
      repl status   with sifyl->status
      repl post_d   with sifyl->post_d
      repl inv_adj  with sifyl->inv_adj
      repl inv_pay  with sifyl->inv_pay
      repl inv_bal  with sifyl->inv_bal
      repl paid     with sifyl->paid
      repl sr_n     with sifyl->sr_n
      repl post_m   with sifyl->post_m
      sele 6
      appe blank
      repl inv_n    with sifyl->inv_n
      repl cust_n   with sifyl->cust_n
      repl cust_m   with sifyl->cust_m
      repl cust_ad  with sifyl->cust_ad
      repl cust_ct  with sifyl->cust_ct
      repl cust_ac  with sifyl->cust_ac
      repl ad_n     with sifyl->ad_n
      repl co_m     with sifyl->co_m
      repl co_ad    with sifyl->co_ad
      repl co_ct    with sifyl->co_ct
      repl cust_s   with sifyl->cust_s
      repl inv_d    with sifyl->inv_d
      repl cust_tp  with sifyl->cust_tp
      repl cust_t   with sifyl->cust_t
      repl si_rem   with sifyl->si_rem
      repl cust_pc  with sifyl->cust_pc
      repl inv_c    with sifyl->inv_c
      repl inv_pc   with sifyl->inv_pc
      repl inv_a    with sifyl->inv_a
      repl dcount1  with sifyl->dcount1
      repl dcount2  with sifyl->dcount2
      repl dcount3  with sifyl->dcount3
      repl net_a    with sifyl->net_a
      repl user_m   with sifyl->user_m
      repl status   with sifyl->status
      repl post_d   with sifyl->post_d
      repl inv_adj  with sifyl->inv_adj
      repl inv_pay  with sifyl->inv_pay
      repl inv_bal  with sifyl->inv_bal
      repl paid     with sifyl->paid
      repl sr_n     with sifyl->sr_n
      repl post_m   with sifyl->post_m
   endif
   sele 4
   skip
enddo

***
sele 1
set order to 2
set colo to b/b
@ 07,24 clear to 12,54
set colo to +bg/b
@ 08,26 say chr(254)+" Sales Records"
set colo to bg/b
@ 09,28 say "# records copied:"
ctr=0
sele 7
go top
do while .not. eof() && .and. trans_c="S" .and. trans_d <= edate
   store inv_n to sv_inv_n
   sele 1
   seek "S"+trim(sv_inv_n)
   do while trans_n=trim(sv_inv_n) .and. .not. eof()
      ctr=ctr+1
      @ 09,46 say ctr pict "999,999"
      dele
      sele 2
      appe blank
      repl trans_c  with stkrec->trans_c
      repl trans_n  with stkrec->trans_n
      repl trans_d  with stkrec-> trans_d
      repl cust_n   with stkrec-> cust_n
      repl cust_s   with stkrec-> cust_s
      repl stk_n    with stkrec-> stk_n
      repl stk_m    with stkrec-> stk_m
      repl stk_pc   with stkrec-> stk_pc
      repl stk_ac   with stkrec-> stk_ac
      repl qty_s    with stkrec-> qty_s
      repl qty_pq   with stkrec-> qty_pq
      repl qty_pu   with stkrec-> qty_pu
      repl qty1     with stkrec-> qty1
      repl qty2     with stkrec-> qty2
      repl qty3     with stkrec-> qty3
      repl qty1L    with stkrec-> qty1L
      repl stk_dv   with stkrec-> stk_dv
      repl stk_cat  with stkrec-> stk_cat
      repl issue_d  with stkrec-> issue_d
      repl issue_q  with stkrec-> issue_q
      repl issue_fg with stkrec-> issue_fg
      repl issue_u  with stkrec-> issue_u
      repl issue_cp with stkrec-> issue_cp
      repl issue_p  with stkrec-> issue_p
      repl dcount1  with stkrec-> dcount1
      repl dcount2  with stkrec-> dcount2
      repl dcount3  with stkrec-> dcount3
      repl t_prys   with stkrec-> t_prys
      repl t_ac     with stkrec-> t_ac
      repl t_pc     with stkrec-> t_pc
      repl lot_n    with stkrec-> lot_n
      repl expiry_d with stkrec-> expiry_d
      repl user_m   with stkrec-> user_m
      sele 1
      skip
   enddo
   sele 7
   skip
enddo

sele 3
go top
set colo to +bg/b
@ 10,26 say chr(254)+" Purchase Master File"
set colo to bg/b
@ 11,28 say "# records copied:"
ctr=0
do while .not. eof() .and. inv_d <= edate
      ctr=ctr+1
      @ 11,46 say ctr pict "999,999"
      dele
      sele 5
      appe blank
      repl inv_n    with purfyl->inv_n
      repl splyr_n  with purfyl->splyr_n
      repl splyr_m  with purfyl->splyr_m
      repl splyr_ad with purfyl->splyr_ad
      repl splyr_ct with purfyl->splyr_ct
      repl inv_d    with purfyl->inv_d
      repl splyr_tp with purfyl->splyr_tp
      repl splyr_t  with purfyl->splyr_t
      repl trans_to with purfyl->trans_to
      repl inv_rem  with purfyl->inv_rem
      repl inv_a    with purfyl->inv_a
      repl dcount1  with purfyl->dcount1
      repl dcount2  with purfyl->dcount2
      repl dcount3  with purfyl->dcount3
      repl net_a    with purfyl->net_a
      repl user_m   with purfyl->user_m
      sele 3
      skip
enddo

set colo to
?
?
set colo to +g
? "cleaning-up the Stock Transaction file..."
set colo to g
sele 1
set talk on
pack

set talk off
set colo to
?
?
set colo to +g
? "cleaning-up the Sales Invoice & Purchase file..."
set talk off
sele 4
set colo to g
set talk on
pack
set talk off
sele 3
set talk on
pack

set talk off
set deleted on
set century off
set exclusive off
close data
return

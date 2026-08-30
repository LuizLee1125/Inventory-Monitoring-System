* program.....: Upd_acct.prg
*             : recomputes, updates the amt purchased, paid, etc. per cust.
*             : starts with the year 2004
*             : 01/21/2006

set talk off
set scor off

sele 1
   use sifyl  
sele 2
   use sifyl_1
sele 3
   use custfyl index cust_n

sele 1
go 49766
do while .not. eof()
   store cust_n to sv_cust_n
   sele 3
   seek sv_cust_n
   if found()
      sele 1
      do case
         case year(inv_d)=2004
              store net_a   to sv_net_a
              store inv_pay to sv_inv_pay
              store inv_adj to sv_inv_adj
              store inv_bal to sv_inv_bal
              sele 3
              repl cust_pur with cust_pur+sv_net_a
              repl cust_pay with cust_pay+sv_inv_pay+sv_inv_adj
              repl cust_bal with cust_bal+sv_inv_bal
         case year(inv_d)=2005
              store net_a   to sv_net_a
              store inv_pay to sv_inv_pay
              store inv_adj to sv_inv_adj
              store inv_bal to sv_inv_bal
              sele 3
              repl lstyrsale with lstyrsale+sv_net_a
              repl cust_pur  with cust_pur+sv_net_a
              repl cust_pay  with cust_pay+sv_inv_pay+sv_inv_adj
              repl cust_bal  with cust_bal+sv_inv_bal
         case year(inv_d)=2006
              store net_a   to sv_net_a
              store inv_pay to sv_inv_pay
              store inv_adj to sv_inv_adj
              store inv_bal to sv_inv_bal
              store month(inv_d) to sv_month
              sele 3
              repl cust_pur  with cust_pur+sv_net_a
              repl cust_pay  with cust_pay+sv_inv_pay+sv_inv_adj
              repl cust_bal  with cust_bal+sv_inv_bal
              do case
                 case sv_month=1
                      repl jan with jan+sv_net_a
                 case sv_month=2
                      repl feb with feb+sv_net_a
                 case sv_month=3
                      repl mar with mar+sv_net_a
                 case sv_month=4
                      repl apr with apr+sv_net_a
                 case sv_month=5
                      repl may with may+sv_net_a
                 case sv_month=6
                      repl jun with jun+sv_net_a
                 case sv_month=7
                      repl jul with jul+sv_net_a
                 case sv_month=8
                      repl aug with aug+sv_net_a
                 case sv_month=9
                      repl sep with sep+sv_net_a
                 case sv_month=10
                      repl oct with oct+sv_net_a
                 case sv_month=11
                      repl nov with nov+sv_net_a
                 case sv_month=12
                      repl dec with dec+sv_net_a
              endcase
      endcase
   endif
   sele 1
   skip
enddo

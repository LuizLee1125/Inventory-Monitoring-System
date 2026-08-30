* program.....: RbildAll.prg
*               rebuilding of indeces
*               11/04/99

SET CENT ON
SET EXCL ON
SET COLO TO
SET DELE OFF

clear
set colo to +gr
? "Reindexing INVENTORY FILES:"

set colo to +g
?
? "Stock Master File...."

set talk on
USE STKFYL
  PACK
  INDEX ON stk_n TO STK_N

set talk off
save screen to atlscrn
set colo to bg/bg
@ 8,13 clear to 12,67
set colo to +g/bg
@ 8,13 to 12,67
set colo to +w/bg,+n/w
store " " to atl
@ 10,15 say "Remove deleted records in Transaction File (y/n)?" get atl pict "Y"
read
set colo to
clear
&C_BODY
restore screen from atlscrn
@ 5,0 say ""

? "Transaction File..."
set talk on
use StkRec
   if upper(atl)="Y"
      ? "   checking for deleted records, please wait....."
      set talk off
      count for deleted() to del_ctr
      if del_ctr>0
         ? "      backing up deleted records...."
         set talk on
         if SYS(0)='AUGUST' &&file("d:\back-up\data\temp\checklst.dbf")
            fyl="d:\BACK-UP\DATA\TEMP\"+left(dtoc(date()),2)+subs(dtoc(date()),4,2)+left(time(),2)+subs(time(),4,2)
            copy to &fyl for deleted()
            ? "   removing deleted records....."
            pack
         else
            fyl="c:\TEMP\"+left(dtoc(date()),2)+subs(dtoc(date()),4,2)+left(time(),2)+subs(time(),4,2)
            copy to &fyl for deleted()
            ? "   removing deleted records....."
            pack
         endif
      else
         ? "   no deleted records exist....."
      endif
      set talk off
   endif
   close data
   SET TALK OFF

? "   please wait, validating records in transaction file..."

*****
set dele on

sele 1
   use stkfyl && index stk_n
sele 2
   use sifyl  index si_n
sele 3
   use stkrec && index trans_id, trans_cn, si_id
   * set order to 0

do while .not. eof()
   if stk_n=" "
      sv_stk_m=stk_m
      sele 1
      loca for stk_m=sv_stk_m
      if found()
         sele 3
         repl stk_n with stkfyl->stk_n
         unlock
      endif
   endif
   SELE 3
   if trans_c="S" .and. dtoc(trans_d)=" "
      stor trans_n to sv_trans_n
      sele 2
      seek sv_trans_n
      if found()
         sele 3
         repl trans_d with sifyl->inv_d
         unlock
      endif
   endif
   sele 3
   skip
enddo

set dele off
close data

? "   reindexing the transaction records..."
*****
use stkrec
   set talk on
   INDEX ON stk_n+STR(YEAR(issue_d),4)+SUBSTR(DTOC(issue_d),1,5)+TAYM TO SI_ID
   set talk off
   close data

use stkrec
   set talk on
   INDEX ON trans_c+trans_n TO TRANS_CN
   set talk off
   close data

use stkrec
   set talk on
   INDEX ON stk_n+STR(YEAR(trans_d),4)+SUBSTR(DTOC(trans_d),1,5)+TAYM TO TRANS_ID
   set talk off
   close data

? "Sales Invoice File..."
set talk on
USE SIFYL
   * PACK
   replace paid with "T" for inv_bal<=0
   INDEX ON inv_n TO SI_N
   INDEX ON inv_d TO SI_D
   INDEX ON str(year(inv_d),4)+SUBSTR(DTOC(inv_d),1,5)+inv_n TO SI_DINV
   *INDEX ON right(dtoc(inv_d),4)+left(dtoc(inv_d),2)+subs(dtoc(inv_d),4,2)+inv_n to si_dinv
   INDEX ON paid+cust_n+STR(YEAR(inv_d),4)+SUBSTR(DTOC(inv_d),1,5) TO SI_CD
   INDEX ON TRIM(CUST_S)+TRIM(CUST_N)+STR(YEAR(INV_D),4)+SUBSTR(DTOC(INV_D),1,5) TO COLEC_X

set talk off
? "Purchase File..."
set talk on
USE PURFYL
   * PACK
   INDEX ON inv_n TO PUR_N
   INDEX ON inv_d TO PUR_D

?
set talk off
? "Sales Return File..."
set talk on
USE SRFYL
   * PACK
   replace paid with "T" for inv_bal<=0
   INDEX ON inv_n TO SR_N
   INDEX ON inv_d TO SR_D
   INDEX ON paid+cust_n+STR(YEAR(inv_d),4)+SUBSTR(DTOC(inv_d),1,5) TO SR_CD

?
set colo to +gr
? "Reindexing ACCOUNTING FILES:"
?
set colo to +g
? "Customer File..."

set talk on
USE CUSTFYL
   PACK
   INDEX ON cust_n TO CUST_N
   set talk off

* ? "Address File..."
* set talk on
* USE ADFYL
* PACK
* INDEX ON ad_n TO AD_N
* set talk off

? "Supplier File..."
set talk on
USE SPLYRFYL
   PACK
   INDEX ON splyr_n TO SPLYR_N
   set talk off

* ? "Territory File..."
* set talk on
* USE SMANFYL
* PACK
* INDEX ON sman_n TO SMAN_N
* set talk off

*? "Accounts File..."
*set talk on
*USE ACCTFYL
*   PACK
*   INDEX ON acct_n TO ACCT_N

   set talk off
? "Collection File..."
set talk on
use COLECFYL
   * PACK
   INDEX ON colec_n TO OR_N
   INDEX ON paid+cust_n+STR(YEAR(colec_d),4)+SUBSTR(DTOC(colec_d),1,5) TO OR_CD

USE COLECREC
   * PACK
   INDEX ON colec_n TO COLEC_N
   INDEX ON colec_d TO COLEC_D
   INDEX ON inv_n TO CSI_N
   INDEX ON chk_dd TO CHK_DD
   set talk off

*? "Bodega File..."
*set talk on
*USE BODGAFYL
*PACK
*INDEX ON inv_n TO BODGA_N
*set talk off
*? "Back-Order Files..."
*set talk on
*USE BOFYL
*PACK
*INDEX ON inv_n TO BOFYL
*USE BOREC
*PACK
*INDEX ON trans_c+trans_n TO BOREC
*INDEX ON stk_n+SUBSTR(DTOC(issue_d),7,2)+SUBSTR(DTOC(issue_d),1,5) TO BO_ID
*USE BOFYL1
*ZAP
*INDEX ON inv_n TO BOFYL1
*USE BOREC1
*ZAP
*INDEX ON trans_c+trans_n TO BOREC1

*? "Debit Memo File..."
*set talk on
*USE DMFYL
*PACK
*INDEX ON inv_n TO DM_N
*INDEX ON inv_d TO DM_D
* *INDEX ON paid+cust_n+SUBSTR(DTOC(inv_d),7,2)+SUBSTR(DTOC(inv_d),1,5) TO DM_CD
*INDEX ON paid+cust_n+STR(YEAR(inv_d),4)+SUBSTR(DTOC(inv_d),1,5) TO DM_CD

*USE DMREC
*PACK
*INDEX ON dm_n TO DMREC
*set talk off

*? "Credit Memo File..."
*set talk on
*USE CMFYL
*PACK
*INDEX ON inv_n TO CM_N
*INDEX ON inv_d TO CM_D
* *INDEX ON paid+cust_n+SUBSTR(DTOC(inv_d),7,2)+SUBSTR(DTOC(inv_d),1,5) TO CM_CD
*INDEX ON paid+cust_n+STR(YEAR(inv_d),4)+SUBSTR(DTOC(inv_d),1,5) TO CM_CD

*USE CMREC
*PACK
*INDEX ON dm_n TO CMREC
*set talk off

*? "Voucher File..."
*set talk on
*USE VOUCHFYL
*PACK
*INDEX ON inv_n TO VOUCH_N

*USE VOUCHREC
*PACK
*INDEX ON dm_n TO VOUCHREC

SET TALK OFF
?
set colo to *+bg
? 'Rebuild and reindex completed! Press any key to continue...'
set colo to
SET EXCLUSIVE OFF
CLOSE DATABASE
SET CENT OFF
SET DELE ON
return

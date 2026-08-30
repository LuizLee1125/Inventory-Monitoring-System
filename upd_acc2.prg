* program.....: upd_acc2.prg
*             : sales movement --> current year to prev year of sales

set talk off
set stat off
set scor off

sele 2
   use sifyl

sele 1
   use custfyl index cust_n

*do while .not. eof()
*   repl mar2 with mar
*   repl apr2 with apr
*   repl may2 with may
*   repl jun2 with jun
*   repl jul2 with jul
*   repl aug2 with aug
*   repl sep2 with sep
*   repl oct2 with oct
*   repl nov2 with nov
*   repl dec2 with dec
*   repl jan2 with 0
*   repl feb2 with 0
*   repl jan with 0
*   repl feb with 0
 *  repl mar with 0
 *  repl apr with 0
*   repl may with 0
*   repl jun with 0
*   repl jul with 0
*   repl aug with 0
*   repl sep with 0
*   repl oct with 0
*   repl nov with 0
*   repl dec with 0
*   skip
*enddo

sele 2

do while .not. eof()
   stor cust_n to svcust_n
   stor net_a  to svnet_a
   do case
      case month(inv_d)=01 .and. year(inv_d)=2006
           sele 1
           seek svcust_n
           if found()
              repl jan2 with jan2+svnet_a
           endif

      case month(inv_d)=02 .and. year(inv_d)=2006
           sele 1
           seek svcust_n
           if found()
              repl feb2 with feb2+svnet_a
           endif

      case month(inv_d)=01 .and. year(inv_d)=2007
           sele 1
           seek svcust_n
           if found()
              repl jan with jan+svnet_a
           endif

      case month(inv_d)=02 .and. year(inv_d)=2007
           sele 1
           seek svcust_n
           if found()
              repl feb with feb+svnet_a
           endif
   endcase
   sele 2
   skip
enddo

close data

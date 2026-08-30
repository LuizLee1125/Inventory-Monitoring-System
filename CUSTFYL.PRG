* program.....: custfyl.prg

set century on
set exac on

use CUSTFYL index CUST_N

do BRDR1
*          1         2         3         4         5         6         7
* 123456789012345678901234567890123456789012345678901234567890123456789012456789
*
*4   Customer Code       : 088                             Splash :
*5   Customer Name       : 088 PHARMACY & G. MDSE          Bodega :
*6   Customer Address    : E-24 F.SEVILLA ST.,
*7   Customer City       : MALABON                          Route :
*8   Territory Code      : CAMANAVA             Area Code     :          3
*9   Customer Tel No.    : 448-39-74            Last Purchase : 07/18/2005
*10  Start Date          : 07/18/2005           Purchases     :           0.00
*11  Price Category      : A                    Charges       :           0.00
*12  Type/Terms (splash) : CASH      /  0days   Payments      :           0.00
*13  Type/Terms (pharma) : CASH      /  0days   Unclear Checks:           0.00
*14  Credit Limit        :         0.00         Balance       :           0.00
*15  Contact Person      : GLYVIN
*16  Tax ID Number       : LTO RDI-MM-DS-6957
*17  Proprietor Name     : AMOR TROPICO
*18  Proprietor Address  : E-24 F.SEVILLA BLVD TA¥ONG MALABON
*19  Proprietor Tel. No. :                      Remarks :

*          1         2         3         4         5         6         7
* 123456789012345678901234567890123456789012345678901234567890123456789012456789
*4 Customer Code   : xxxxx              Bodega : 99         Status: Active     
*5 Customer Name   : 123456789012345678901234567890      Territory: 1
*6 Customer Address: 123456789012345678901234567890           Area: 1
*7                 : 123456789012345678901234567890  *       Calls: 99        
*8 Customer Phone/s: 12345678901234567890                Price Cat: A
*9 Evaluation Rem. : 12345678901234567890                     Type: 1234567890
*10Remarks         : 12345678901234567890                    Terms: 999 days 
*11Business Style  : 123456789012345678901234567890  *Credit Limit:  9,999,999
*12Tax ID Number   : 12345678901234567890            * Mon. Target:  9,999,999
*13L.T.O. Number   : 12345678901234567890            *  Check Eval: 1234567890
*14------------------------------------------------  *   # of Days: 99      
*15Contact Person  : 1234567890                              Start: 99/99/99
*16proprietor Name : 1234567890                          LastPurch: 99/99/9
*17Proprietor Addr.: 12345678901234567890123456789012345  YtDPurch: 99,999,999
*18Proprietor Phone: 12345678901234567890                    YtdSR: 99,999,999
*19Remarks         : 12345678901234567890

*4
*5                                  Current Purchases       Current Returns
*6                                jan : 99,999,999.99    jan : 9,999,999.99
*7                                feb : 99,999,999.99    feb : 9,999,999.99
*8                                mar : 99,999,999.99    mar : 9,999,999.99
*9                                apr : 99,999,999.99    apr : 9,999,999.99
*10                               may : 99,999,999.99    may : 9,999,999.99
*11                               jun : 99,999,999.99    jun : 9,999,999.99
*12                               jul : 99,999,999.99    jul : 9,999,999.99
*13                               aug : 99,999,999.99    aug : 9,999,999.99
*14  year 9999 statistics:        sep : 99,999,999.99    sep : 9,999,999.99
*15                               oct : 99,999,999.99    oct : 9,999,999.99
*16    sales: 99,999,999.99       nov : 99,999,999.99    nov : 9,999,999.99
*17  returns:  9,999,999.99       dec : 99,999,999.99    dec : 9,999,999.99
*18                            totals : 99,999,999.99          9,999,999.99

&C_BODY
@  4, 2 say 'Customer Code   :'
@  5, 2 say 'Customer Name   :'
@  5,57 say 'Territory:'
@  6, 2 say 'Customer Address:'
@  6,62 say 'Area:'
@  7,18 say ':'
@  7,60 say 'Calls:'
@  8, 2 say 'Customer Phone/s:'
@  8,57 say 'Price Cat:'
@  9, 2 say 'Evaluation Rem. :'
@  9,62 say 'Type:'
@ 10, 2 say 'Remarks         :'
@ 10,61 say 'Terms:'
@ 10,72 say 'Days'
@ 11, 2 say 'Business Style  :'
@ 11,56 say 'Cr. Limit:'
@ 12, 2 say 'TAX ID Number   :'
@ 12,42 say 'LTO Expiry'
@ 12,54 say 'Mon. Target:'
@ 13, 2 say 'L.T.O. Number   :'
@ 13,55 say 'Check Eval:'
@ 14,56 say '# of Days:'
@ 15, 2 say 'Contact Person  :'
@ 15,61 say 'Start:'
@ 16, 2 say 'Proprietor Name :'
@ 16,57 say 'LastPurch:'
@ 17, 2 say 'Proprietor Addr.:'
@ 17,58 say 'YtdPurch:'
@ 18,61 say 'YtdSR:'
@ 19, 2 say 'Proprietor Phone:'

set colo to gr
@ 14,02 to 14,54
set color to 
@ 21, 0 clear to 24, 79

action="SAY"
choice="T"

do while .T.
    set color to +W/BG
    @  1, 69 say user_m     picture '@!'
    @  4, 20 say cust_n     picture '@!'
    @  5, 20 say cust_m     picture '@!'
    @  6, 20 say cust_ad    picture '@!'
    @  7, 20 say cust_ct    picture '@!'
    @  8, 20 say cust_p     picture '@!'
    @  9, 20 say eval_rem   picture '@!'
    @ 10, 20 say cust_rem   picture '@!'
    @ 11, 20 say bus_style  picture '@!'
    @ 12, 20 say tin        picture '999-999-999-99999'
    @ 13, 20 say lto        picture '@!'
    @ 13, 42 say lto_exp    picture '99/99/9999'
    @ 15, 20 say cust_cp    picture '@!'
    @ 16, 20 say prop_m     picture '@!'
    @ 17, 20 say prop_ad    picture '@!'
    @ 18, 20 say prop_ad2   picture '@!'
    @ 19, 20 say prop_p     picture '@!'

    @  5, 68 say cust_s     picture "@!"
    @  6, 68 say cust_ac    picture "@!"
    @  7, 68 say calls      picture "99"
    @  8, 68 say cust_pc    picture '!'
    @  9, 68 say cust_tp    picture '@!'
    @ 10, 68 say cust_t     picture '###'
    @ 11, 69 say cust_cl    picture '9,999,999'
    @ 12, 69 say mtarget    picture '9,999,999'
    @ 13, 68 say check_e    picture '@!'
    @ 14, 68 say ndays      picture '9999'
    curpurch=jan+feb+mar+apr+may+jun+jul+aug+sep+oct+nov+dec
    @ 15, 68 say cust_sd    picture '99/99/9999'
    @ 16, 68 say cust_lt    picture '99/99/9999'
    @ 17, 68 say curpurch   picture '##,###,###'
    @ 18, 69 say cust_sr    picture '#,###,###'

    *set color to +gr, +*w/b
    *@ 21, 09 prompt ' Top '
    *@ 21, 14 prompt ' Bottom '
    *@ 21, 22 prompt ' Next '
    *@ 21, 28 prompt ' Prev '
    *@ 21, 34 prompt ' Find '
    *@ 21, 40 prompt ' Add '
    *@ 21, 45 prompt ' Edit '
    *@ 21, 51 prompt ' Delete '
    *@ 21, 59 prompt ' Status '
    *@ 21, 67 prompt ' Quit '
    *menu to atlbar
    do option14
    atlbar=choice

    do case
        case atlbar="T" && 1
            goto top
        case atlbar="B" && 2
            goto bottom
        case atlbar="N" && 3
            skip
            if EOF()
                save screen to atlscreen
                atlmsg= 'this is the last record, press any key...'
                atllen= LEN(atlmsg)
                set color to rb/rb
                @ 11, 41-atllen/2-2 clear to 13, 41-atllen/2+atllen+1
                set color to +w/rb
                @ 11, 41-atllen/2-2 to 13, 41-atllen/2+atllen+1
                @ 12, 41-atllen/2 say atlmsg
                atlkeypres= INKEY(0)
                restore screen from atlscreen
                goto bottom
                loop
            endif
        case atlbar="V" && 4
            skip  -1
            if BOF()
                save screen to atlscreen
                atlmsg= 'this is the first record, press any key...'
                atllen= LEN(atlmsg)
                set color to rb/rb
                @ 11, 41-atllen/2-2 clear to 13, 41-atllen/2+atllen+1
                set color to +w/rb
                @ 11, 41-atllen/2-2 to 13, 41-atllen/2+atllen+1
                @ 12, 41-atllen/2 say atlmsg
                atlkeypres= INKEY(0)
                restore screen from atlscreen
                goto top
                loop
            endif
        case atlbar="F" && 5
            set exac off
            store SPACE(10) to mcust_n
            store RECNO() to mrecno
            set color to ,+gr/r
            @ 4, 20 get mcust_n picture '@!'
            read
            if mcust_n=' '
                set exac on
                loop
            endif
            seek TRIM(mcust_n)
            if .not. FOUND()
                save screen to atlscreen
                atlmsg= 'customer code '+TRIM(mcust_n)+' not found! press any key to continue...'
                atllen= LEN(atlmsg)
                set color to rb/rb
                @ 11, 41-atllen/2-2 clear to 13, 41-atllen/2+atllen+1
                set color to +w/rb
                @ 11, 41-atllen/2-2 to 13, 41-atllen/2+atllen+1
                @ 12, 41-atllen/2 say atlmsg
                atlkeypres= INKEY(0)
                restore screen from atlscreen
                goto mrecno
            endif
            set exac on
        case atlbar="A" && 6 add
            store SPACE(10) to mcust_n
            store RECNO() to mrecno
            set color to ,+gr/b
            @ 4, 20 get mcust_n picture '@!'
            read
            if mcust_n=' '
                loop
            endif
            seek TRIM(mcust_n)
            if FOUND()
                save screen to atlscreen
                atlmsg= 'cust. code '+TRIM(mcust_n)+' already exists, press any key...'
                atllen= LEN(atlmsg)
                set color to rb/rb
                @ 11, 41-atllen/2-2 clear to 13, 41-atllen/2+atllen+1
                set color to +w/rb
                @ 11, 41-atllen/2-2 to 13, 41-atllen/2+atllen+1
                @ 12, 41-atllen/2 say atlmsg
                atlkeypres= INKEY(0)
                restore screen from atlscreen
                goto mrecno
                loop
            endif
            mspl_cn= SPACE(10)
            mcust_m= SPACE(35)
            mbodega= SPACE(2)
            mcust_ad= SPACE(30)
            mcust_ct= SPACE(30)
            mroute= SPACE(10)
            mcust_ac= SPACE(10)
            mcust_p= SPACE(30)
            mcust_sd= DATE()
            mcust_pc= 'A'
            mcust_tp= SPACE(10)
            mcust_t= 0
            mcust_tp2=space(10)
            mcust_t2=0
            mcust_cl= 0
            mcust_cp= SPACE(35)
            mcust_s= SPACE(10)
            mprop_m= SPACE(35)
            mprop_ad= SPACE(35)
            mprop_ad2=space(35)
            mprop_p= SPACE(30)
            mcust_rem= SPACE(20)
            mcust_lt= ctod('')
            mcust_pur= 0
            mcust_crg= 0
            mcust_pay= 0
            mcust_flt= 0
            mtin=space(20)
            mlto=space(20)
            mlto_exp=ctod(' ')
            mbus_style=space(35)
            meval_rem=space(35)
            mcust_stat="A"
            mcred_code=space(1)
            mcalls=0
            mndays=0
            mmtarget=0
            mcheck_e=space(10)
            set color to +w/bg
            @ 15, 68 say '  /  /    '
            @ 16, 68 say '  /  /    '

            set color to ,+w/bg
            @  5, 20 get mcust_m    picture '@!'
            @  6, 20 get mcust_ad   picture '@!'
            @  7, 20 get mcust_ct   picture '@!'
            @  8, 20 get mcust_p    picture '@!'
            @  9, 20 get meval_rem  picture '@!'
            @ 10, 20 get mcust_rem  picture '@!'
            @ 11, 20 get mbus_style picture '@!'
            @ 12, 20 get mtin       picture '999-999-999-99999'
            @ 13, 20 get mlto       picture '@!'
            @ 13, 42 get mlto_exp   picture '99/99/9999'

            @  5, 68 get mcust_s    picture '@!'
            @  6, 68 get mcust_ac   picture '@!'
            @  7, 68 get mcalls     picture "99"
            @  8, 68 get mcust_pc   picture '@!'
            @  9, 68 get mcust_tp   picture '@!'
            @ 10, 68 get mcust_t    picture '###'
            @ 11, 69 get mcust_cl   picture '9,999,999'
            @ 12, 69 get mmtarget   picture '9,999,999'
            @ 13, 68 get mcheck_e   picture '@!'
            @ 14, 68 get mndays     picture '9999'
            @ 15, 68 get mcust_sd   picture '99/99/9999'

            @ 15, 20 get mcust_cp   picture '@!'
            @ 16, 20 get mprop_m    picture '@!'
            @ 17, 20 get mprop_ad   picture '@!'
            @ 18, 20 get mprop_ad2  picture '@!'
            @ 19, 20 get mprop_p    picture '@!'

            read

            save screen to atlscreen
            atlmsg= 'Add '+TRIM(mcust_n)+' to the master file (y/n)?'
            atllen= LEN(atlmsg)
            set color to rb/rb
            @ 11, 41-atllen/2-2 clear to 13, 41-atllen/2+atllen+3
            set color to +w/rb
            @ 11, 41-atllen/2-2 to 13, 41-atllen/2+atllen+3
            atloption= SPACE(1)
            @ 12, 41-atllen/2 say atlmsg
            @ 12, 41-atllen/2+LEN(atlmsg)+1 get atloption picture '!' valid atloption$'YN'
            read
            if atloption='Y'
                append blank
                replace cust_n    with mcust_n
                replace cust_m    with mcust_m
                replace cust_ad   with mcust_ad
                replace cust_ct   with mcust_ct
                replace cust_ac   with mcust_ac
                replace cust_p    with mcust_p
                replace eval_rem  with meval_rem
                replace cust_s    with mcust_s
                replace bus_style with mbus_style
                replace tin       with mtin
                replace lto       with mlto
                replace lto_exp   with mlto_exp
                replace cust_sd   with mcust_sd
                replace cust_pc   with mcust_pc
                replace cust_tp   with mcust_tp
                replace cust_t    with mcust_t
                replace cust_cp   with mcust_cp
                replace prop_m    with mprop_m
                replace prop_ad   with mprop_ad
                replace prop_ad2  with mprop_ad2
                replace prop_p    with mprop_p
                replace cust_rem  with mcust_rem
                replace cust_lt   with mcust_lt
                replace user_m    with muser
                replace calls     with mcalls
                replace cust_cl   with mcust_cl
                replace mtarget   with mmtarget
                replace check_e   with mcheck_e
                replace ndays     with mndays
                unlock
                restore screen from atlscreen
            else
                restore screen from atlscreen
                goto mrecno
                loop
            endif
        case atlbar="E" && 7 edit
            store cust_n to mcust_n
            store RECNO() to mrecno
            set color to ,+gr/r
            @ 4, 20 get mcust_n picture '@!'
            read
            if mcust_n=' '
                loop
            endif
            seek TRIM(mcust_n)
            if FOUND().and.RECNO()<>mrecno
                save screen to atlscreen
                atlmsg= 'Customer code '+TRIM(mcust_n)+' already exists, press any key...'
                atllen= LEN(atlmsg)
                set color to rb/rb
                @ 11, 41-atllen/2-2 clear to 13, 41-atllen/2+atllen+1
                set color to +w/rb
                @ 11, 41-atllen/2-2 to 13, 41-atllen/2+atllen+1
                @ 12, 41-atllen/2 say atlmsg
                atlkeypres= INKEY(0)
                restore screen from atlscreen
                goto mrecno
                loop
            endif
            mcust_n    = cust_n
            mcust_m    = cust_m
            mcust_ad   = cust_ad
            mcust_ct   = cust_ct
            mcust_p    = cust_p
            meval_rem  = eval_rem
            mcust_s    = cust_s
            mcust_ac   = cust_ac
            mbus_style = bus_style
            mtin       = tin
            mlto       = lto
            mlto_exp   = lto_exp
            mcust_pc   = cust_pc
            mcust_tp   = cust_tp
            mcust_t    = cust_t
            mcust_cp   = cust_cp
            mprop_m    = prop_m
            mprop_ad   = prop_ad
            mprop_ad2  = prop_ad2
            mprop_p    = prop_p
            mcust_rem  = cust_rem
            mcust_sd   = cust_sd
            mcust_lt   = cust_lt
            mcalls     = calls
            mcust_cl   = cust_cl
            mmtarget   = mtarget
            mcheck_e   = check_e
            mndays     = ndays
            set color to ,+w/bg

            @  5, 20 get mcust_m    picture '@!'
            @  6, 20 get mcust_ad   picture '@!'
            @  7, 20 get mcust_ct   picture '@!'
            @  8, 20 get mcust_p    picture '@!'
            @  9, 20 get meval_rem  picture '@!'
            @ 10, 20 get mcust_rem  picture '@!'
            @ 11, 20 get mbus_style picture '@!'
            @ 12, 20 get mtin       picture '999-999-999-99999'
            @ 13, 20 get mlto       picture '@!'
            @ 13, 42 get mlto_exp   picture '99/99/9999'

            @  5, 68 get mcust_s    picture '@!'
            @  6, 68 get mcust_ac   picture '@!'
            @  7, 68 get mcalls     picture "99"
            @  8, 68 get mcust_pc   picture '@!'
            @  9, 68 get mcust_tp   picture '@!'
            @ 10, 68 get mcust_t    picture '###'
            @ 11, 69 get mcust_cl   picture '9,999,999'
            @ 12, 69 get mmtarget   picture '9,999,999'
            @ 13, 68 get mcheck_e   picture '@!'
            @ 14, 68 get mndays     picture '9999'
            @ 15, 68 get mcust_sd   picture '99/99/9999'
            @ 16, 68 get mcust_lt   picture '99/99/9999'

            @ 15, 20 get mcust_cp   picture '@!'
            @ 16, 20 get mprop_m    picture '@!'
            @ 17, 20 get mprop_ad   picture '@!'
            @ 18, 20 get mprop_ad2  picture '@!'
            @ 19, 20 get mprop_p    picture '@!'

            read
            save screen to atlscreen
            atlmsg= 'Post edited '+TRIM(mcust_n)+' to the master file (y/n)?'
            atllen= LEN(atlmsg)
            set color to rb/rb
            @ 11, 41-atllen/2-2 clear to 13, 41-atllen/2+atllen+3
            set color to +w/rb
            @ 11, 41-atllen/2-2 to 13, 41-atllen/2+atllen+3
            atloption= SPACE(1)
            @ 12, 41-atllen/2 say atlmsg
            @ 12, 41-atllen/2+LEN(atlmsg)+1 get atloption picture '!' valid atloption$'YN'
            read
            if atloption='Y'
                replace cust_n    with mcust_n
                replace cust_m    with mcust_m
                replace cust_ad   with mcust_ad
                replace cust_ct   with mcust_ct
                replace cust_ac   with mcust_ac
                replace cust_p    with mcust_p
                replace eval_rem  with meval_rem
                replace cust_s    with mcust_s
                replace bus_style with mbus_style
                replace tin       with mtin
                replace lto       with mlto
                replace lto_exp   with mlto_exp
                replace cust_sd   with mcust_sd
                replace cust_pc   with mcust_pc
                replace cust_tp   with mcust_tp
                replace cust_t    with mcust_t
                replace cust_cp   with mcust_cp
                replace prop_m    with mprop_m
                replace prop_ad   with mprop_ad
                replace prop_ad2  with mprop_ad2
                replace prop_p    with mprop_p
                replace cust_rem  with mcust_rem
                replace cust_lt   with mcust_lt
                replace user_m    with muser
                replace calls     with mcalls
                replace cust_cl   with mcust_cl
                replace mtarget   with mmtarget
                replace check_e   with mcheck_e
                replace ndays     with mndays
                unlock
                restore screen from atlscreen
            else
                restore screen from atlscreen
                goto mrecno
                loop
            endif
        case atlbar="D" && DELETE 8
            if Muser="ADMIN" 
               save screen to atlscreen
               store RECNO() to mrecno1
               store cust_n to mcust_n
               skip  -1
               if .not. BOF()
                   store RECNO() to mrecno2
               else
                   goto top
                   skip
                   store RECNO() to mrecno2
               endif
               goto mrecno1
               atlmsg= 'Are you sure you want to delete '+TRIM(mcust_n)+' (y/n)?'
               atllen= LEN(atlmsg)
               set color to rb/rb
               @ 11, 41-atllen/2-2 clear to 13, 41-atllen/2+atllen+3
               set color to +w/rb
               @ 11, 41-atllen/2-2 to 13, 41-atllen/2+atllen+3
               atloption= SPACE(1)
               @ 12, 41-atllen/2 say atlmsg
               @ 12, 41-atllen/2+LEN(atlmsg)+1 get atloption picture '!' valid atloption$'YN'
               read
               if atloption='Y'
                  delete
                  restore screen from atlscreen
                  Goto mrecno2
               else
                  restore screen from atlscreen
                  goto mrecno1
                  loop
               endif
            endif
        case atlbar="S" && 9 status
            save screen to atlscreen
            set colo to +w/rb
            @ 5,29 clear to 18,76
            set colo to +gr/rb
            @ 14,3 clear to 18,26
            set colo to +w/r
            @ 5,29 clear to 5,76
            @ 14,3 clear to 14,26
            @ 5,35 say "Current Purchases"
            @ 5,59 say "Current Returns"
            set colo to +g/rb
            @ 6,33 say "Jan :"
            @ 7,33 say "Feb :"
            @ 8,33 say "Mar :"
            @ 9,33 say "Apr :"
            @10,33 say "May :"
            @11,33 say "Jun :"
            @12,33 say "Jul :"
            @13,33 say "Aug :"
            @14,33 say "Sep :"
            @15,33 say "Oct :"
            @16,33 say "Nov :"
            @17,33 say "Dec :"
            @ 6,56 say "Jan :"
            @ 7,56 say "Feb :"
            @ 8,56 say "Mar :"
            @ 9,56 say "Apr :"
            @10,56 say "May :"
            @11,56 say "Jun :"
            @12,56 say "Jul :"
            @13,56 say "Aug :"
            @14,56 say "Sep :"
            @15,56 say "Oct :"
            @16,56 say "Nov :"
            @17,56 say "Dec :"
            set colo to +w/rb
            @18,30 say "Totals :"
            set colo to +w/r
            @14,4 say "Year"
            set colo to +bg/r
            @14,9 say year(date())-1 pict "9999"
            set colo to +w/r
            @14,14 say "Statistics:"
            set color to +w/rb
            @16,6  say "Sales:"
            @17,4  say "Returns:"
            set colo to +bg/rb
            @ 6,39 say jan pict '99,999,999.99'
            @ 7,39 say feb pict '99,999,999.99'
            @ 8,39 say mar pict '99,999,999.99'
            @ 9,39 say apr pict '99,999,999.99'
            @10,39 say may pict '99,999,999.99'
            @11,39 say jun pict '99,999,999.99'
            @12,39 say jul pict '99,999,999.99'
            @13,39 say aug pict '99,999,999.99'
            @14,39 say sep pict '99,999,999.99'
            @15,39 say oct pict '99,999,999.99'
            @16,39 say nov pict '99,999,999.99'
            @17,39 say dec pict '99,999,999.99'
            @ 6,62 say jan_sr pict '9,999,999.99'
            @ 7,62 say feb_sr pict '9,999,999.99'
            @ 8,62 say mar_sr pict '9,999,999.99'
            @ 9,62 say apr_sr pict '9,999,999.99'
            @10,62 say may_sr pict '9,999,999.99'
            @11,62 say jun_sr pict '9,999,999.99'
            @12,62 say jul_sr pict '9,999,999.99'
            @13,62 say aug_sr pict '9,999,999.99'
            @14,62 say sep_sr pict '9,999,999.99'
            @15,62 say oct_sr pict '9,999,999.99'
            @16,62 say nov_sr pict '9,999,999.99'
            @17,62 say dec_sr pict '9,999,999.99'
            set colo to +gr/rb
            curpurch=jan+feb+mar+apr+may+jun+jul+aug+sep+oct+nov+dec
            @18,39 say curpurch pict '99,999,999.99'
            @18,62 say cust_sr  pict '9,999,999.99'
            @16,13 say lstyrsale pict '99,999,999.99'
            @17,14 say lstyrsr  pict '9,999,999.99'
            atl=inkey(0)
            rest screen from atlscreen

        case atlbar="Q" && 10 QUIT
            exit
    endcase
enddo
set century off
close database
set exac off
return
 

* program.....: StkMPurge.prg
*             : stock master file purging to O_StkFyl.dbf

SET CENTURY ON
USE STKFYL INDEX STK_N
DO BRDR1
&C_HEAD
@ 14, 21 SAY ' QUANTITY LOC. L.UPD. '
@ 14, 59 SAY ' PRICE    MARK UP '
&C_BODY
@ 4, 5  SAY 'Stock Code      :'
@ 5, 5  SAY 'Description     :'
@ 6, 5  SAY 'Size            :'
@ 7, 5  SAY 'Lot Number      :'
@ 8, 5  SAY 'Expiry Date     :'
@ 9, 5  SAY 'Div./Category   :       -'
@ 10, 5 SAY 'Re-order Level  :'
@ 11, 5 SAY 'Maintain Level  :'
@ 12, 5 SAY 'Unit            :'
@ 13, 5 SAY 'Pkg. (Qty/Unit) :       /'
@ 15, 5 SAY 'On Hand         :'
@ 16, 5 SAY 'Bodega 2        :'
@ 17, 5 SAY 'Bodega 3        :'
@ 19, 5 SAY 'Remarks         :'
@ 6, 40 SAY 'Form             :'
@ 7, 40 SAY 'Last Purchase    :'
@ 8, 40 SAY 'Supplier Code    :'
@ 9, 40 SAY 'Purchase Cost    :'
@ 10, 40 SAY 'Ave. Purc. Cost  :'
@ 11, 40 SAY 'Catalog Price    :'
@ 12, 40 SAY 'Price Update     :'
@ 13, 40 SAY 'For Price Update :'
@ 15, 55 SAY 'A :'
@ 16, 55 SAY 'B :'
@ 17, 55 SAY 'C :'
@ 18, 55 SAY 'D :'
@ 19, 55 SAY 'E :'

action="SAY"
choice="T"

do while .t.
   set colo to
   @ 21,0 clear to 24,79
   if tobemoved
      set colo to +gr/n
      @ 4,59 say "* to be moved"
   else
      set colo to
      @ 4,59 say "             "
   endif
   &C_GET
   @ 4, 23 SAY Stk_N     PICTURE '@!'
   @ 05,23 SAY Stk_M     PICT '@!'
   @ 06,23 SAY Qty_S     PICT '@!'
   @ 07,23 SAY Lot_N     PICT '@!'
   @ 08,23 SAY Expiry_D  PICT '99/99/9999'
   *if mOption="D"
   *   &C_HEAD
      @ 09,23 SAY Stk_Dv    PICT '@!'
   *   &C_GET
   *else
   *   &C_GET
   *   @ 09,23 SAY Stk_Dv    PICT '@!'
   *endif
   *if mOption="C"
   *   &C_HEAD
      @ 09,31 SAY Stk_Cat   PICT '@!'
   *   &C_GET
   *else
   *   &C_GET
   *   @ 09,31 SAY Stk_Cat   PICT '@!'
   *endif
   @ 10,23 SAY Qty_R     PICT '###,###'
   @ 11,23 SAY Qty_M     PICT '###,###'
   @ 12,23 SAY Qty_U     PICT '@!'
   @ 13,23 SAY Qty_Pq    PICT '#,###'
   @ 13,31 SAY Qty_Pu    PICT '@!'
   @ 15,23 SAY Qty1      PICT '###,###'
   @ 15,31 SAY Qty1L     PICT '@!'
   @ 15,35 SAY Qty1LU  
   @ 16,23 SAY Qty2      PICT '###,###'
   @ 16,31 SAY Qty2L     PICT '@!'
   @ 16,35 SAY Qty2Lu  
   @ 17,23 SAY Qty3      PICT '###,###'
   @ 17,31 SAY Qty3L     PICT '@!'
   @ 17,35 SAY Qty3LU  
   @ 19,23 SAY Stk_Rem   PICT '@!'
   @ 06,59 SAY Form      PICT '@!'
   @ 07,59 SAY Stk_Lt
   *if mOption="S"
   *   &C_HEAD
      @ 08,59 SAY Splyr_N   PICT '@!'
   *   m&C_GET
   *else
   *   &C_GET
   *   @ 08,59 SAY Splyr_N   PICT '@!'
   *endif
   @ 09,59 SAY Stk_PC    PICT '##,###.##'
   @ 10,59 SAY Stk_AC    PICT '##,###.##'
   @ 11,59 SAY Stk_CP    PICT '##,###.##'
   @ 12,59 SAY Prys_UD   
   @ 13,59 SAY Prys_CH   PICT 'L'
   @ 15,59 SAY Prys_A    PICT '@Z ##,###.##'
   @ 15,70 SAY MarkUp_A1 PICT '@Z ###'
   @ 15,74 SAY MarkUP_A2 PICT '@Z ###'
   @ 16,59 SAY Prys_B    PICT '@Z ##,###.##'
   @ 16,70 SAY MarkUp_B1 PICT '@Z ###'
   @ 16,74 SAY MarkUP_B2 PICT '@Z ###'
   @ 17,59 SAY Prys_C    PICT '@Z ##,###.##'
   @ 17,70 SAY MarkUp_C1 PICT '@Z ###'
   @ 17,74 SAY MarkUp_C2 PICT '@Z ###'
   @ 18,59 SAY Prys_D    PICT '@Z ##,###.##'
   @ 18,70 SAY MarkUp_D1 PICT '@Z ###'
   @ 18,74 SAY MarkUp_D2 PICT '@Z ###'
   @ 19,59 SAY Prys_E    PICT '@Z ##,###.##'
   @ 19,70 SAY MarkUp_E1 PICT '@Z ###'
   @ 19,74 SAY MarkUp_E2 PICT '@Z ###'
   @ 1, 69 SAY User_M    PICTURE '@!'
   &C_HEAD               
   @ 18, 5 SAY 'TOTAL           :'
   &C_GET
   @ 18, 22 SAY Qty1+Qty2+Qty3 PICTURE '####,###'

   *set colo to +w/b, +gr/r
   *@ 22, 18 prompt " Next "
   *@ 22, 25 prompt " Prev "
   *@ 22, 32 prompt " Top "
   *@ 22, 38 prompt " Bott "
   *@ 22, 45 prompt " Find "
   *if .not. tobemoved
   *   @ 22, 52 prompt " Move "
   *else
   *   @ 22, 52 prompt " Reca "
   *endif
   *@ 22, 59 prompt " Quit "
   *menu to atlbar

   do option10
   atlbar=choice

   do case
      case atlbar="N" && next - 1
           skip
           if eof()
              set colo to +w/rb
              @ 23, 22 say "end of file encountered. press any key..."
              keypress=inkey(0)
              set colo to
              @ 23, 22 clear to 23,79
              go bott
           endif

      case atlbar="V" && previous - 2
           skip -1
           if bof()
              set colo to +w/rb
              @ 23, 18 say "beginning of file encountered. press any key..."
              keypress=inkey(0)
              set colo to
              @ 23, 18 clear to 23,79
              go top
           endif
      case atlbar="T" && top - 3
           go top
      case atlbar="B" && bottom - 4
           go bott
      case atlbar="F" && find - 5
           atlrecno=recno()
           save screen to atlscrn2
           atlStkN=space(10)
           @ 4,23 get atlStkN pict "@!"
           read
           if atlStkN=" "
              restore screen from atlscrn2
              loop
           endif
           atlStkN=trim(atlStkN)
           seek atlStkN
           if .not. found()
              set colo to b/b
              @ 12,11 clear to 15,69
              set colo to +gr/b
              @ 12,11 to 15,69
              set colo to +w/b,+gr/rb
              @ 13,14 say "Stock no. does not exists or not within the filter..."
              @ 14,14 say "             Press any key to continue...            "
              keypress=inkey(0)
              rest screen from atlscrn2
              go atlrecno
              loop
           endif
      case atlbar="M" && move - 6
              repl tobemoved with .t.
      case atlbar="R"
              repl tobemoved with .f.
      case atlbar="Q"
           exit
   endcase
enddo

set colo to b/b
@ 12,11 clear to 14,69
set colo to +gr/b
@ 12,11 to 14,69
set colo to +w/b,+gr/rb
@ 13,13 say "    please wait... verifying stocks to be moved...   "
count for tobemoved to atlctr

if atlctr>=1
   set colo to b/b
   @ 12,11 clear to 14,69
   set colo to +gr/b
   @ 12,11 to 14,69
   set colo to +w/b,+gr/rb
   @ 13,13 say "  moving stock records to archive... please wait...  "

   SELE 1
      use o_stkfyl index o_stk_n
   SELE 2
      USE STKFYL INDEX STK_N

   do while .not. eof()
     if tobemoved
      store STK_N      to   x_stk_n
      store STK_M      to   x_stk_m
      store STK_DV     to   x_STK_DV
      store STK_CAT    to   x_STK_CAT
      store LOT_N      to   x_LOT_N
      store EXPIRY_D   to   x_EXPIRY_D
      store QTY_R      to   x_QTY_R
      store QTY_M      to   x_QTY_M
      store QTY_U      to   x_QTY_U
      store QTY_S      to   x_QTY_S
      store QTY_PQ     to   x_QTY_PQ
      store QTY_PU     to   x_QTY_PU
      store QTY1       to   x_QTY1
      store QTY1L      to   x_QTY1L
      store QTY1LU     to   x_QTY1LU
      store QTY2       to   x_QTY2
      store QTY2L      to   x_QTY2L
      store QTY2LU     to   x_QTY2LU
      store QTY3       to   x_QTY3
      store QTY3L      to   x_QTY3L
      store QTY3LU     to   x_QTY3LU
      store STK_REM    to   x_STK_REM
      store STK_LT     to   x_STK_LT
      store SPLYR_N    to   x_SPLYR_N
      store STK_PC     to   x_STK_PC
      store STK_AC     to   x_STK_AC
      store STK_CP     to   x_STK_CP
      store PRYS_UD    to   x_PRYS_UD
      store PRYS_CH    to   x_PRYS_CH
      store PRYS_A     to   x_PRYS_A
      store MARKUP_A1  to   xMarkup_A1
      store MARKUP_A2  to   xMarkup_A2
      store PRYS_B     to   x_PRYS_B
      store MARKUP_B1  to   xMarkup_B1
      store MARKUP_B2  to   xMarkup_B2
      store PRYS_C     to   x_PRYS_C
      store MARKUP_C1  to   xMarkup_C1
      store MARKUP_C2  to   xMarkup_C2
      store PRYS_D     to   x_PRYS_D
      store MARKUP_D1  to   xMarkup_D1
      store MARKUP_D2  to   xMarkup_D2
      store PRYS_E     to   x_PRYS_E
      store MARKUP_E1  to   xMarkup_E1
      store MARKUP_E2  to   xMarkup_E2
      store USER_M     to   x_USER_M
      store FORM       to   x_FORM
      if rlock()
         dele
         unlock
      endif

      sele 1
      if flock()
         appe blank
         replace STK_N      with   x_stk_n
         replace STK_M      with   x_stk_m
         replace STK_DV     with   x_STK_DV
         replace STK_CAT    with   x_STK_CAT
         replace LOT_N      with   x_LOT_N
         replace EXPIRY_D   with   x_EXPIRY_D
         replace QTY_R      with   x_QTY_R
         replace QTY_M      with   x_QTY_M
         replace QTY_U      with   x_QTY_U
         replace QTY_S      with   x_QTY_S
         replace QTY_PQ     with   x_QTY_PQ
         replace QTY_PU     with   x_QTY_PU
         replace QTY1       with   x_QTY1
         replace QTY1L      with   x_QTY1L
         replace QTY1LU     with   x_QTY1LU
         replace QTY2       with   x_QTY2
         replace QTY2L      with   x_QTY2L
         replace QTY2LU     with   x_QTY2LU
         replace QTY3       with   x_QTY3
         replace QTY3L      with   x_QTY3L
         replace QTY3LU     with   x_QTY3LU
         replace STK_REM    with   x_STK_REM
         replace STK_LT     with   x_STK_LT
         replace SPLYR_N    with   x_SPLYR_N
         replace STK_PC     with   x_STK_PC
         replace STK_AC     with   x_STK_AC
         replace STK_CP     with   x_STK_CP
         replace PRYS_UD    with   x_PRYS_UD
         replace PRYS_CH    with   x_PRYS_CH
         replace PRYS_A     with   x_PRYS_A
         replace MARKUP_A1  with   xMarkup_A1
         replace MARKUP_A2  with   xMarkup_A2
         replace PRYS_B     with   x_PRYS_B
         replace MARKUP_B1  with   xMarkup_B1
         replace MARKUP_B2  with   xMarkup_B2
         replace PRYS_C     with   x_PRYS_C
         replace MARKUP_C1  with   xMarkup_C1
         replace MARKUP_C2  with   xMarkup_C2
         replace PRYS_D     with   x_PRYS_D
         replace MARKUP_D1  with   xMarkup_D1
         replace MARKUP_D2  with   xMarkup_D2
         replace PRYS_E     with   x_PRYS_E
         replace MARKUP_E1  with   xMarkup_E1
         replace MARKUP_E2  with   xMarkup_E2
         replace USER_M     with   x_USER_M
         replace FORM       with   x_FORM
         replace TOBEMOVED  with   .F.
         unlock
      endif
    endif
    sele 2
    skip
   enddo

*  set colo to b/b
*  @ 12,11 clear to 14,69
*  set colo to +gr/b
*  @ 12,11 to 14,69
*  set colo to +w/b,+gr/rb
*  @ 13,13 say " Performing clean-up maintenance in the stock file..."
*  use stkfyl index stk_n
*  do while .not. eof()
*     if tobemoved
*        lock
*        dele
*        unlock
*     endif
*     skip
*  enddo
*  pack
   set colo to b/b
   @ 12,11 clear to 14,69
   set colo to +gr/b
   @ 12,11 to 14,69
   set colo to +w/b,+gr/rb
   @ 13,13 say " Finished processing!!! Press any key to continue ..."
   keypress=inkey(0)
endif

close data
set century off
return

* program.....: PrysAdj.prg

SET CENTURY ON
USE STKFYL INDEX STK_N
choice= 'S'
DO WHILE choice$'SDA'
    DO BRDR1
    &C_HEAD
    @ 14, 23 SAY 'OLD PRICE  MARK UP'
    @ 14, 59 SAY 'NEW PRICE  MARK UP'
    &C_BODY
    @ 4, 5 SAY 'Stock Code      :'
    @ 5, 5 SAY 'Description     :'
    @ 6, 5 SAY 'Size            :'
    @ 7, 5 SAY 'Lot Number      :'
    @ 8, 5 SAY 'Expiry Date     :'
    @ 9, 5 SAY 'Div./Category   :       -'
    @ 10, 5 SAY 'Re-order Level  :'
    @ 11, 5 SAY 'Maintain Level  :'
    @ 12, 5 SAY 'Unit            :'
    @ 13, 5 SAY 'Pkg. (Qty/Unit) :       /'
    @ 15, 5 SAY '              A :'
    @ 16, 5 SAY '              B :'
    @ 17, 5 SAY '              C :'
    @ 18, 5 SAY '              D :'
    @ 19, 5 SAY '              E :'
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
    mfield01= SPACE(10)
    choice= 'F'
    action= 'GET'
    new= .T.
    DO WHILE choice$'FEVNTB'
        IF action='GET'
            key= mfield01
            &C_GET
            @ 4, 23 GET key PICTURE '@!'
            READ
            IF LEN(TRIM(key))=0
                SET CENTURY OFF
                CLOSE DATABASE
                RETURN
            ENDIF
            IF choice='F'.or.key<>mfield01
                DO MODE
                mfield01= key
            ENDIF
        ENDIF
        &C_GET
        IF action='SAY'
            mfield01= stk_n
            mfield02= stk_m
            mfield03= qty_s
            mfield04= lot_n
            mfield05= expiry_d
            mfield06= stk_dv
            mfield07= stk_cat
            mfield08= qty_r
            mfield09= qty_m
            mfield10= qty_u
            mfield11= qty_pq
            mfield12= qty_pu
            mfield13= prys_a
            mfield14= markup_a1
            mfield15= markup_a2
            mfield16= prys_b
            mfield17= markup_b1
            mfield18= markup_b2
            mfield19= prys_c
            mfield20= markup_c1
            mfield21= markup_c2
            mfield22= prys_d
            mfield23= markup_d1
            mfield24= markup_d2
            mfield25= prys_e
            mfield26= markup_e1
            mfield27= markup_e2
            mfield28= stk_rem
            mfield29= stk_lt
            mfield30= splyr_n
            mfield31= stk_pc
            mfield32= stk_ac
            mfield33= stk_cp
            mfield34= prys_ud
            mfield35= prys_ch
            IF prys_a=0.or.qty_pq=0
                mfield36= prys_a
            ELSE
                mfield36= stk_cp/qty_pq
                mfield36= mfield36+(mfield36*markup_a1/100)
                mfield36= mfield36+(mfield36*markup_a2/100)
            ENDIF
            mfield37= markup_a1
            mfield38= markup_a2
            IF prys_b=0.or.qty_pq=0
                mfield39= prys_b
            ELSE
                mfield39= stk_cp/qty_pq
                mfield39= mfield39+(mfield39*markup_b1/100)
                mfield39= mfield39+(mfield39*markup_b2/100)
            ENDIF
            mfield40= markup_b1
            mfield41= markup_b2
            IF prys_c=0.or.qty_pq=0
                mfield42= prys_c
            ELSE
                mfield42= stk_cp/qty_pq
                mfield42= mfield42+(mfield42*markup_c1/100)
                mfield42= mfield42+(mfield42*markup_c2/100)
            ENDIF
            mfield43= markup_c1
            mfield44= markup_c2
            IF prys_d=0.or.qty_pq=0
                mfield45= prys_d
            ELSE
                mfield45= stk_cp/qty_pq
                mfield45= mfield45+(mfield45*markup_d1/100)
                mfield45= mfield45+(mfield45*markup_d2/100)
            ENDIF
            mfield46= markup_d1
            mfield47= markup_d2
            IF prys_e=0.or.qty_pq=0
                mfield48= prys_e
            ELSE
                mfield48= stk_cp/qty_pq
                mfield48= mfield48+(mfield48*markup_e1/100)
                mfield48= mfield48+(mfield48*markup_e2/100)
            ENDIF
            mfield49= markup_e1
            mfield50= markup_e2
            mfield51= user_m
        ENDIF
        IF choice='F'
            choice= 'E'
            mfield01= key
            mfield02= SPACE(30)
            mfield03= SPACE(10)
            mfield04= SPACE(15)
            mfield05= CTOD('  /  /    ')
            mfield06= SPACE(5)
            mfield07= SPACE(5)
            mfield08= 0
            mfield09= 0
            mfield10= SPACE(4)
            mfield11= 0
            mfield12= SPACE(4)
            mfield13= 0
            mfield14= 0
            mfield15= 0
            mfield16= 0
            mfield17= 0
            mfield18= 0
            mfield19= 0
            mfield20= 0
            mfield21= 0
            mfield22= 0
            mfield23= 0
            mfield24= 0
            mfield25= 0
            mfield26= 0
            mfield27= 0
            mfield28= SPACE(30)
            mfield29= DATE()
            mfield30= SPACE(10)
            mfield31= 0
            mfield32= 0
            mfield33= 0
            mfield34= DATE()
            mfield35= 'N'
            mfield36= 0
            mfield37= 0
            mfield38= 0
            mfield39= 0
            mfield40= 0
            mfield41= 0
            mfield42= 0
            mfield43= 0
            mfield44= 0
            mfield45= 0
            mfield46= 0
            mfield47= 0
            mfield48= 0
            mfield49= 0
            mfield50= 0
            mfield51= muser
        ENDIF
        @ 4, 23 SAY mfield01 PICTURE '@!'
        @ 5, 23 SAY mfield02 PICTURE '@!'
        @ 6, 23 SAY mfield03 PICTURE '@!'
        @ 7, 23 SAY mfield04 PICTURE '@!'
        @ 8, 23 SAY mfield05 PICTURE '99/99/9999'
        @ 9, 23 SAY mfield06 PICTURE '@!'
        @ 9, 31 SAY mfield07 PICTURE '@!'
        @ 10, 23 SAY mfield08 PICTURE '###,###'
        @ 11, 23 SAY mfield09 PICTURE '###,###'
        @ 12, 23 SAY mfield10 PICTURE '@!'
        @ 13, 23 SAY mfield11 PICTURE '#,###'
        @ 13, 31 SAY mfield12 PICTURE '@!'
        @ 15, 23 SAY mfield13 PICTURE '@Z ##,###.##'
        @ 15, 34 SAY mfield14 PICTURE '@Z ###'
        @ 15, 38 SAY mfield15 PICTURE '@Z ###'
        @ 16, 23 SAY mfield16 PICTURE '@Z ##,###.##'
        @ 16, 34 SAY mfield17 PICTURE '@Z ###'
        @ 16, 38 SAY mfield18 PICTURE '@Z ###'
        @ 17, 23 SAY mfield19 PICTURE '@Z ##,###.##'
        @ 17, 34 SAY mfield20 PICTURE '@Z ###'
        @ 17, 38 SAY mfield21 PICTURE '@Z ###'
        @ 18, 23 SAY mfield22 PICTURE '@Z ##,###.##'
        @ 18, 34 SAY mfield23 PICTURE '@Z ###'
        @ 18, 38 SAY mfield24 PICTURE '@Z ###'
        @ 19, 23 SAY mfield25 PICTURE '@Z ##,###.##'
        @ 19, 34 SAY mfield26 PICTURE '@Z ###'
        @ 19, 38 SAY mfield27 PICTURE '@Z ###'
        @ 07,59 &ACTION mFIELD29 PICT "99/99/9999"
        @ 08,59 &ACTION mFIELD30 PICT '@!'
        @ 09,59 &ACTION mFIELD31 PICT '##,###.##'
        @ 10,59 &ACTION mFIELD32 PICT '##,###.##'
        @ 11,59 &ACTION mFIELD33 PICT '##,###.##'
        @ 12,59 &ACTION mFIELD34 PICT "99/99/9999"
        @ 13,59 &ACTION mFIELD35 PICT 'L'
        @ 15,59 &ACTION mFIELD36 PICT '@Z ##,###.##'
        @ 15,70 &ACTION mFIELD37 PICT '@Z ###'
        @ 15,74 &ACTION mFIELD38 PICT '@Z ###'
        @ 16,59 &ACTION mFIELD39 PICT '@Z ##,###.##'
        @ 16,70 &ACTION mFIELD40 PICT '@Z ###'
        @ 16,74 &ACTION mFIELD41 PICT '@Z ###'
        @ 17,59 &ACTION mFIELD42 PICT '@Z ##,###.##'
        @ 17,70 &ACTION mFIELD43 PICT '@Z ###'
        @ 17,74 &ACTION mFIELD44 PICT '@Z ###'
        @ 18,59 &ACTION mFIELD45 PICT '@Z ##,###.##'
        @ 18,70 &ACTION mFIELD46 PICT '@Z ###'
        @ 18,74 &ACTION mFIELD47 PICT '@Z ###'
        @ 19,59 &ACTION mFIELD48 PICT '@Z ##,###.##'
        @ 19,70 &ACTION mFIELD49 PICT '@Z ###'
        @ 19,74 &ACTION mFIELD50 PICT '@Z ###'
        @ 1, 69 SAY mfield51 PICTURE '@!'
        IF action='GET'
            READ
            IF READKEY()=4.or.READKEY()=260
                LOOP
            ENDIF
        ENDIF
        DO OPTION1
    ENDDO
    IF choice='S'
        IF new
            APPEND BLANK
        ENDIF
        REPLACE stk_n WITH mfield01
        REPLACE stk_rem WITH mfield28, stk_lt WITH mfield29, splyr_n WITH mfield30, stk_pc WITH mfield31, stk_ac WITH mfield32, stk_cp WITH mfield33, prys_ud WITH DATE(), prys_ch WITH 'N'
        REPLACE prys_a WITH mfield36, markup_a1 WITH mfield37, markup_a2 WITH mfield38, prys_b WITH mfield39, markup_b1 WITH mfield40, markup_b2 WITH mfield41, prys_c WITH mfield42, markup_c1 WITH mfield43, markup_c2 WITH mfield44
        REPLACE prys_d WITH mfield45, markup_d1 WITH mfield46, markup_d2 WITH mfield47, prys_e WITH mfield48, markup_e1 WITH mfield49, markup_e2 WITH mfield50, user_m WITH muser
        UNLOCK
    ENDIF
ENDDO
SET CENTURY OFF
CLOSE DATABASE
RETURN
 

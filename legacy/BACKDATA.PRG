* program.....: BackData.prg
*             : program to back-up database and index files in 6 days period

PRIVATE ALL LIKE PRG??
PRIVATE ALL LIKE M_*

prg1a= '     A. Monday         '
prg1b= '     B. Tuesday        '
prg1c= '     C. Wednesday      '
prg1d= '     D. Thursday       '
prg1e= '     E. Friday         '
prg1f= '     F. Saturday       '
prg1g= '     G. Exit           '
set cent on
today=cdow(date())+', '+cmonth(date())+' '+substr(dtoc(date()),4,2)+', '+str(year(date()),4)
set cent off
m_y_col1= 7
m_y_col2= 0
m_y_col3= 0
m_col1= 29
m_x= 1
do case
   case dow(date())=2 && mon
        m_y= 1
   case dow(date())=3 && tue
        m_y= 2
   case dow(date())=4 && wed
        m_y= 3
   case dow(date())=5 && thu
        m_y= 4
   case dow(date())=6 && fri
        m_y= 5
   case dow(date())=7 && sat
        m_y= 6
   othe
        m_y= 6
endcase
m_col= m_col1
m_row= 8
m_x_max= 1
m_y_max= m_y_col1

DO WHILE .T.
   &C_CLEAR
   CLEAR
   set colo to +w
   @ 20,41-(len(today)/2) say today
   &C_BRDR
   @ 6, 28 TO 18, 52 DOUBLE
   @ 5, 29 TO 7, 51 DOUBLE
   &C_HEAD
   @ 6, 30 SAY '    BACK-UP FILES    '
   &C_OPTION
   @ 9,  29 SAY prg1a
   @ 10, 29 SAY prg1b
   @ 11, 29 SAY prg1c
   @ 12, 29 SAY prg1d
   @ 13, 29 SAY prg1e
   @ 14, 29 SAY prg1f
   @ 15, 29 SAY prg1g
   DO MENU3C
   prg= choice
   if choice="PRG1G"
      &C_CLEAR
      CLEAR
      exit
   endif

   &C_CLEAR
   CLEAR
   set colo to +g
   ? 'deleting temporary files first...'
   set colo to bg
   set safe off
   if file('admin.dbf')
      ? '  - admin'
      dele file admin.dbf
      if file('admin.idx')
         dele file admin.idx
      endif
   endif
   if file('alona.dbf')
      ? '  - alona'
      dele file alona.dbf
      if file('alona.idx')
         dele file alona.idx
      endif
   endif
   if file('berdie.dbf')
      ? '  - berdie'
      dele file berdie.dbf
      if file('berdie.idx')
         dele file berdie.idx
      endif
   endif
   if file('cora.dbf')
      ? '  - cora'
      dele file cora.dbf
      if file('cora.idx')
         dele file cora.idx
      endif
   endif
   if file('berdy.dbf')
      ? '  - berdy'
      dele file berdy.dbf
      if file('berdy.idx')
         dele file berdy.idx
      endif
   endif
   if file('beth.dbf')
      ? '  - beth'
      dele file beth.dbf
      if file('beth.idx')
         dele file beth.idx
      endif
   endif
   if file('nelia.dbf')
      ? '  - nelia'
      dele file nelia.dbf
      if file('nelia.idx')
         dele file nelia.idx
      endif
   endif
   if file('jpd.dbf')
      ? '  - jpd'
      dele file jpd.dbf
      if file('jpd.idx')
         dele file jpd.idx
      endif
   endif
   if file('john.dbf')
      ? '  - john'
      dele file john.dbf
      if file('john.idx')
         dele file john.idx
      endif
   endif
   if file('edwin.dbf')
      ? '  - edwin'
      dele file edwin.dbf
      if file('edwin.idx')
         dele file edwin.idx
      endif
   endif
   if file('lindsay.dbf')
      ? '  - lindsay'
      dele file lindsay.dbf
      if file('lindsay.idx')
         dele file lindsay.idx
      endif
   endif
   if file('austine.dbf')
      ? '  - austine'
      dele file austine.dbf
      if file('austine.idx')
         dele file austine.idx
      endif
   endif

   if file('maribel.dbf')
      ? '  - maribel'
      dele file maribel.dbf
      if file('maribel.idx')
         dele file maribel.idx
      endif
   endif
   if file('leonila.dbf')
      ? '  - leonila'
      dele file leonila.dbf
      if file('leonila.idx')
         dele file leonila.idx
      endif
   endif
   if file('marife.dbf')
      ? '  - marife'
      dele file marife.dbf
      if file('marife.idx')
         dele file marife.idx
      endif
   endif
   if file('darleen.dbf')
      ? '  - darleen'
      dele file darleen.dbf
      if file('darleen.idx')
         dele file darleen.idx
      endif
   endif
   if file('imelda.dbf')
      ? '  - imelda'
      dele file imelda.dbf
      if file('imelda.idx')
         dele file imelda.idx
      endif
   endif
   if file('rechel.dbf')
      ? '  - rechel'
      dele file rechel.dbf
      if file('rechel.idx')
         dele file rechel.idx
      endif
   endif

   if file('angela.dbf')
      ? '  - angela'
      dele file angela.dbf
      if file('angela.idx')
         dele file angela.idx
      endif
   endif

   if file('edil.dbf')
      ? '  - edil'
      dele file edil.dbf
      if file('edil.idx')
         dele file edil.idx
      endif
   endif

   ?
   DO CASE
      CASE choice='PRG1A'
           if UPPER(GETENV('BKUP'))<>'C:\TEMP'
              ! pkzip -u d:\back-up\data\1-mon *.dbf *.idx
           else
              ! pkzip -u c:\temp\backup\1-mon *.dbf *.idx
           endif
           ?
           set colo to +bg
           ? "finished backing-up the files!!! press any key to continue..."
           i=inkey(0)
      CASE choice='PRG1B'
           if UPPER(GETENV('BKUP'))<>'C:\TEMP'
              ! pkzip -u d:\back-up\data\2-tue *.dbf *.idx
           else
              ! pkzip -u c:\temp\backup\2-tue *.dbf *.idx
           endif
           ?
           set colo to +bg
           ? "finished backing-up the files!!! press any key to continue..."
           i=inkey(0)
      CASE choice='PRG1C'
           if UPPER(GETENV('BKUP'))<>'C:\TEMP'
              ! pkzip -u d:\back-up\data\3-wed *.dbf *.idx
           else 
              ! pkzip -u c:\temp\backup\3-wed *.dbf *.idx
           endif
           ?
           set colo to +bg
           ? "finished backing-up the files!!! press any key to continue..."
           i=inkey(0)
      CASE choice='PRG1D'
           if UPPER(GETENV('BKUP'))<>'C:\TEMP'
              ! pkzip -u d:\back-up\data\4-thu *.dbf *.idx
           else
              ! pkzip -u c:\temp\backup\4-thu *.dbf *.idx
           endif
           ?
           set colo to +bg
           ? "finished backing-up the files!!! press any key to continue..."
           i=inkey(0)
      CASE choice='PRG1E'
           if UPPER(GETENV('BKUP'))<>'C:\TEMP'
              ! pkzip -u d:\back-up\data\5-fri *.dbf *.idx
           else
              ! pkzip -u c:\temp\backup\5-fri *.dbf *.idx
           endif
           ?
           set colo to +bg
           ? "finished backing-up the files!!! press any key to continue..."
           i=inkey(0)
      CASE choice='PRG1F'
           if UPPER(GETENV('BKUP'))<>'C:\TEMP'
              ! pkzip -u d:\back-up\data\6-sat *.dbf *.idx
           else
              ! pkzip -u c:\temp\backup\6-sat *.dbf *.idx
           endif
           ?
           set colo to +bg
           ? "finished backing-up the files!!! press any key to continue..."
           i=inkey(0)
      otherwise
          RETURN
   ENDCASE
ENDDO

return

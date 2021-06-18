' Copyright (c) 2020-2021 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For Colour Maximite 2, MMBasic 5.07

Option Explicit On
Option Default None

#Include "../system.inc"
#Include "../txtwm.inc"

Cls

Option Console Serial
Print Chr$(27) "[?25l"; ' hide cursor

'boxes()
'End

'moses()
'End

twm.init(5, 13000)
Dim win0% = twm.new_win%( 0,  0, 100, 50)
Dim win1% = twm.new_win%( 3,  3,  10, 40)
Dim win2% = twm.new_win%(19, 16,  33, 10)
Dim win3% = twm.new_win%(61, 11,  10, 28)
Dim win4% = twm.new_win%(45, 28,  10, 20)

Dim i%

'Dim t% = Timer

twm.switch(win0%)
twm.box( 0,  0, 100, 50)
twm.box( 2,  2,  12, 42)
twm.box(18, 15,  35, 12)
twm.box(60, 10,  12, 30)
twm.box(44, 27,  12, 22)

'twm.print_at(0, 0, Str$(Timer - t%))
'End

twm.switch(win1%)
twm.foreground(twm.RED%)
twm.print_at(0, 37, "    ||    ")
twm.print_at(0, 38, "    ||    ")
twm.print_at(0, 39, "   /**\   ")
twm.print_at(0, 40, "  /****\  ")

twm.switch(win3%)
twm.foreground(twm.YELLOW%)
twm.inverse(1)
twm.print_at(0, 24, "    ||    ")
twm.print_at(0, 25, "    ||    ")
twm.print_at(0, 26, "   /**\   ")
twm.print_at(0, 27, "  /****\  ")
twm.inverse(0)

twm.switch(win4%)
twm.foreground(twm.GREEN%)
twm.print_at(0, 0, "  \****/  ")
twm.print_at(0, 1, "   \**/   ")
twm.print_at(0, 2, "    ||    ")
twm.print_at(0, 3, "    ||    ")

twm.switch(win2%)
twm.bold(1)
twm.print_at(0, 0)

For i% = 1 To 255
  twm.switch(win2%)
  twm.foreground(1 + i% Mod 6)
  twm.print("Moses supposes his toeses are roses, but moses supposes erroneously.")
  twm.print(" For nobody's toeses are roses as moses supposes his toeses to be. ")
  twm.switch(win1%)
  twm.scroll_up(1)
  twm.switch(win3%)
  twm.scroll_up(1)
  twm.switch(win4%)
  twm.scroll_down(1)
'  Pause 500
Next

Sub boxes()
  twm.init(1, 10007)
  Local win1% = twm.new_win%(0, 0, 100, 50)
  twm.switch(win1%)
  twm.box(0, 0, 100, 50)
  Local i%, x%, y%, w%, h%
  For i% = 1 To 20
'    Do While Inkey$ <> "" : Loop
'    Do While Inkey$ = "" : Loop
    x% = Int(Rnd * 96)
    y% = Int(Rnd * 46)
    w% = Max(4, Int(Rnd * (100 - x%)))
    h% = Max(4, Int(Rnd * (50 - y%)))
    twm.box(x%, y%, w%, h%)
  Next
  Do : Loop
End Sub

Sub moses()
  twm.init(2, 10000)
  Local win1% = twm.new_win%(1, 1, 20, 20)
  Local i%
  twm.switch(win1%)
  twm.border()
  twm.print_at(0, 0)
  For i% = 1 To 255
    twm.at% = i%
    twm.print("Moses supposes his toeses are roses, but moses supposes eroneously.")
    twm.print(" For nobody's toeses are roses as moses supposes his toeses to be. ")
  Next
End Sub

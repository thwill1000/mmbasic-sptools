' Copyright (c) 2020-2021 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For Colour Maximite 2, MMBasic 5.07

Option Explicit On
Option Default None
Option Base InStr(Mm.CmdLine$, "--base=1") > 0

#Include "../system.inc"
#Include "../array.inc"
#Include "../list.inc"
#Include "../math.inc"
#Include "../string.inc"
#Include "../file.inc"
#Include "../vt100.inc"
#Include "../../sptest/unittest.inc"

Const BASE% = Mm.Info(Option Base)

add_test("test_pseudo_rnd")

If InStr(Mm.CmdLine$, "--base") Then run_tests() Else run_tests("--base=1")

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Sub test_pseudo_rnd()
  Local x% = math.pseudo_rnd%(-7) ' seed the random number generator.

  ' Assert that first 10 generated values are as expected.
  Local i%
  Local expected%(base% + 9) = (6,4,4,7,10,2,10,10,3,4)
  For i% = 0 To 9
    assert_int_equals(expected%(BASE% + i%), math.pseudo_rnd%(10))
  Next

  ' Assert that calling the Sub 1000 times generates each number 1..10 at least once.
  Local count%(10)
  For i% = 1 To 1000
    x% = math.pseudo_rnd%(10)
    Inc count%(x%)
  Next

  If BASE% = 0 Then assert_int_equals(0, count%(0))
  For i% = 1 To 10
    assert_int_equals(1, count%(i%) > 0)
  Next
End Sub

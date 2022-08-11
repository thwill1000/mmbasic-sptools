' Copyright (c) 2021 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For Colour Maximite 2, MMBasic 5.07

Option Explicit On
Option Default None
Option Base InStr(Mm.CmdLine$, "--base=1") > 0

#Include "../system.inc"
#Include "../array.inc"
#Include "../list.inc"
#Include "../map.inc"
#Include "../string.inc"
#Include "../file.inc"
#Include "../vt100.inc"
#Include "../bits.inc"
#Include "../../sptest/unittest.inc"

Const BASE% = Mm.Info(Option Base)

add_test("test_set")
add_test("test_clear")
add_test("test_get")

run_tests(Choice(InStr(Mm.CmdLine$, "--base"), "", "--base=1"))

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Sub test_set()
  Local x% = &b11010000

  bits.set(x%, 0)
  bits.set(x%, 2)
  bits.set(x%, 4)
  bits.set(x%, 6)

  assert_hex_equals(&b11010101, x%)
End Sub

Sub test_clear()
  Local x% = &b11010000

  bits.clear(x%, 0)
  bits.clear(x%, 2)
  bits.clear(x%, 4)
  bits.clear(x%, 6)

  assert_hex_equals(&b10000000, x%)
End Sub

Sub test_get()
  Local i%, x%

  x% = &b11010000
  assert_true (bits.get%(x%, 7))
  assert_true (bits.get%(x%, 6))
  assert_false(bits.get%(x%, 5))
  assert_true (bits.get%(x%, 4))
  assert_false(bits.get%(x%, 3))
  assert_false(bits.get%(x%, 2))
  assert_false(bits.get%(x%, 1))
  assert_false(bits.get%(x%, 0))

  x% = &hFFFFFFFFFFFFFFFF
  For i% = 0 To 63
    assert_true(bits.get%(x%, i%))
  Next

  x% = 0
  For i% = 0 To 63
    assert_false(bits.get%(x%, i%))
  Next
End Sub

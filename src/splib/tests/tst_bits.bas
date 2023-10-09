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
add_test("test_set_given_out_of_bnds")
add_test("test_clear")
add_test("test_clear_given_out_of_bnds")
add_test("test_get")
add_test("test_get_given_out_of_bnds")
add_test("test_fill")
add_test("test_fill_given_invalid")
add_test("test_big_set")
add_test("test_big_set_given_out_of_bnds")
add_test("test_big_clear")
add_test("test_big_clear_given_out_of_bnds")
add_test("test_big_get")
add_test("test_big_get_given_out_of_bnds")
add_test("test_big_fill")
add_test("test_big_fill_given_invalid")

run_tests(Choice(InStr(Mm.CmdLine$, "--base"), "", "--base=1"))

End

Sub test_set()
  Local x% = &b11010000

  bits.set(x%, 0)
  bits.set(x%, 2)
  bits.set(x%, 4)
  bits.set(x%, 6)

  assert_hex_equals(&b11010101, x%)
End Sub

Sub test_set_given_out_of_bnds()
  Local x%

  On Error Ignore
  bits.set(x%, -1)
  assert_raw_error("Index out of bounds")

  On Error Ignore
  bits.set(x%, 64)
  assert_raw_error("Index out of bounds")
End Sub

Sub test_clear()
  Local x% = &b11010000

  bits.clear(x%, 0)
  bits.clear(x%, 2)
  bits.clear(x%, 4)
  bits.clear(x%, 6)

  assert_hex_equals(&b10000000, x%)
End Sub

Sub test_clear_given_out_of_bnds()
  Local x%

  On Error Ignore
  bits.clear(x%, -1)
  assert_raw_error("Index out of bounds")

  On Error Ignore
  bits.clear(x%, 64)
  assert_raw_error("Index out of bounds")
End Sub

Sub test_get()
  Local i%, x% = &b11010000

  For i% = 0 To 63
    Select Case i%
      Case 4, 6, 7
        assert_true(bits.get%(x%, i%))
      Case Else
        assert_false(bits.get%(x%, i%))
    End Select
  Next

  x% = &hFFFFFFFFFFFFFFFF
  For i% = 0 To 63
    assert_true(bits.get%(x%, i%))
  Next

  x% = 0
  For i% = 0 To 63
    assert_false(bits.get%(x%, i%))
  Next
End Sub

Sub test_get_given_out_of_bnds()
  Local actual%, x%

  On Error Ignore
  actual% = bits.get%(x%, -1)
  assert_raw_error("Index out of bounds")

  On Error Ignore
  actual% = bits.get%(x%, 64)
  assert_raw_error("Index out of bounds")
End Sub

Sub test_fill()
  Local i%, x%

  bits.fill(x%, 1)
  assert_int_equals(&hFFFFFFFFFFFFFFFF, x%)

  bits.fill(x%, 0)
  assert_int_equals(&h0, x%)
End Sub

Sub test_fill_given_invalid()
  Local x%
  On Error Ignore
  bits.fill(x%, 2)
  assert_raw_error("Invalid bit value")
End Sub

Sub test_big_set()
  Local x%(array.new%(4))
  bits.big_set(x%(), 0)
  bits.big_set(x%(), 63)
  bits.big_set(x%(), 64)
  bits.big_set(x%(), 126)
  bits.big_set(x%(), 129)
  bits.big_set(x%(), 255)

  Local expected%(array.new%(4))
  expected%(BASE%) = &h8000000000000001
  expected%(BASE% + 1) = &h4000000000000001
  expected%(BASE% + 2) = &h0000000000000002
  expected%(BASE% + 3) = &h8000000000000000
  assert_int_array_equals(expected%(), x%(), 1)
End Sub

Sub test_big_set_given_out_of_bnds()
  Local x%(array.new%(4))

  On Error Ignore
  bits.big_set(x%(), -1)
  assert_raw_error("Index out of bounds")

  On Error Ignore
  bits.big_set(x%(), 256)
  assert_raw_error("Index out of bounds")
End Sub

Sub test_big_clear()
  Local x%(array.new%(4))
  x%(BASE%) = &h8011000000000001
  x%(BASE% + 1) = &h40000AA000000001
  x%(BASE% + 2) = &h0000000BB0000002
  x%(BASE% + 3) = &h8000000000000000
  bits.big_clear(x%(), 0)
  bits.big_clear(x%(), 63)
  bits.big_clear(x%(), 64)
  bits.big_clear(x%(), 126)
  bits.big_clear(x%(), 129)
  bits.big_clear(x%(), 255)

  Local expected%(array.new%(4))
  expected%(BASE%) = &h0011000000000000
  expected%(BASE% + 1) = &h00000AA000000000
  expected%(BASE% + 2) = &h0000000BB0000000
  expected%(BASE% + 3) = &h0000000000000000
  assert_int_array_equals(expected%(), x%(), 1)
End Sub

Sub test_big_clear_given_out_of_bnds()
  Local x%(array.new%(4))

  On Error Ignore
  bits.big_clear(x%(), -1)
  assert_raw_error("Index out of bounds")

  On Error Ignore
  bits.big_clear(x%(), 256)
  assert_raw_error("Index out of bounds")
End Sub

Sub test_big_get()
  Local i%, x%(array.new%(4))
  x%(BASE%) = &h8011000000000001
  x%(BASE% + 1) = &h40000AA000000001
  x%(BASE% + 2) = &h0000000BB0000002
  x%(BASE% + 3) = &h8000000000000000

  For i% = 0 To 4 * 64 - 1
    Select Case i%
      Case 0, 48, 52, 63, 64, 101, 103, 105, 107, 126, 129, 156, 157, 159, 160, 161, 163, 255
        assert_true(bits.big_get%(x%(), i%))
      Case Else
        assert_false(bits.big_get%(x%(), i%))
    End Select
  Next
End Sub

Sub test_big_get_given_out_of_bnds()
  Local actual%, x%(array.new%(4))

  On Error Ignore
  actual% = bits.big_get%(x%(), -1)
  assert_raw_error("Index out of bounds")

  On Error Ignore
  actual% = bits.big_get%(x%(), 256)
  assert_raw_error("Index out of bounds")
End Sub

Sub test_big_fill()
  Local i%, x%(array.new%(4)), expected%(array.new%(4))

  bits.big_fill(x%(), 1)
  For i% = BASE% To BASE% + 3 : expected%(i%) = &hFFFFFFFFFFFFFFFF : Next
  assert_int_array_equals(expected%(), x%(), 1)

  bits.big_fill(x%(), 0)
  For i% = BASE% To BASE% + 3 : expected%(i%) = &h0 : Next
  assert_int_array_equals(expected%(), x%(), 1)
End Sub

Sub test_big_fill_given_invalid()
  Local x%(array.new%(4))
  On Error Ignore
  bits.big_fill(x%(), 2)
  assert_raw_error("Invalid bit value")
End Sub

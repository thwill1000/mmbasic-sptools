' Copyright (c) 2021 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For Colour Maximite 2, MMBasic 5.07

Option Explicit On
Option Default None
Option Base InStr(Mm.CmdLine$, "--base=1") > 0

#Include "../src/splib/system.inc"
#Include "../src/splib/array.inc"
#Include "../src/splib/list.inc"
#Include "../src/splib/string.inc"
#Include "../src/splib/file.inc"
#Include "../src/splib/vt100.inc"
#Include "../src/sptest/unittest.inc"

Const base% = Mm.Info(Option Base)

add_test("test_min_given_ints")
add_test("test_min_given_floats")
add_test("test_max_given_ints")
add_test("test_max_given_floats")

run_tests()
'If InStr(Mm.CmdLine$, "--base") Then run_tests() Else run_tests("--base=1")

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Sub test_min_given_ints()
  assert_int_equals(5, Min(5))
  assert_int_equals(-5, Min(-5))

  assert_int_equals(5, Min(5, 10))
  assert_int_equals(5, Min(10, 5))
  assert_int_equals(-5, Min(5, -5))
  assert_int_equals(5, Min(5, 5))

  assert_int_equals(5, Min(10000, 50, 5, 20))
End Sub

Sub test_min_given_floats()
  assert_int_equals(3.412, Min(3.412))
  assert_int_equals(-3.412, Min(-3.412))

  assert_float_equals(3.412, Min(3.412, 6.02214086e23))
  assert_float_equals(3.412, Min(6.02214086e23, 3.412))
  assert_float_equals(-3.412, Min(3.412, -3.412))
  assert_float_equals(6.02214086e23, Min(6.02214086e23, 6.02214086e23))

  assert_float_equals(-6.02214086e23, Min(6.02214086e23, -3.412, -6.02214086e23, 3.412))
End Sub

Sub test_max_given_ints()
  assert_int_equals(5, Max(5))
  assert_int_equals(-5, Max(-5))

  assert_int_equals(10, Max(5, 10))
  assert_int_equals(10, Max(10, 5))
  assert_int_equals(5, Max(5, -5))
  assert_int_equals(5, Max(5, 5))

  assert_int_equals(10000, Max(10000, 50, 5, 20))
End Sub

Sub test_max_given_floats()
  assert_int_equals(3.412, Max(3.412))
  assert_int_equals(-3.412, Max(-3.412))

  assert_float_equals(6.02214086e23, Max(3.412, 6.02214086e23))
  assert_float_equals(6.02214086e23, Max(6.02214086e23, 3.412))
  assert_float_equals(3.412, Max(3.412, -3.412))
  assert_float_equals(6.02214086e23, Max(6.02214086e23, 6.02214086e23))

  assert_float_equals(6.02214086e23, Max(6.02214086e23, -3.412, -6.02214086e23, 3.412))
End Sub


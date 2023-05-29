' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

Option Explicit On
Option Default Integer

#Include "../../splib/system.inc"
#Include "../../splib/array.inc"
#Include "../../splib/list.inc"
#Include "../../splib/string.inc"
#Include "../../splib/file.inc"
#Include "../../splib/set.inc"
#Include "../../splib/vt100.inc"
#Include "../../sptest/unittest.inc"
#Include "../defines.inc"

add_test("test_define_given_undefined")
add_test("test_define_given_defined")
add_test("test_define_given_invalid")
add_test("test_define_given_too_long")
add_test("test_define_given_too_many")
add_test("test_define_case_insensitive")
add_test("test_undefine_given_defined")
add_test("test_undefine_given_undefined")
add_test("test_undefine_case_insensitive")
add_test("test_always_defined_values")
add_test("test_always_undefined_values")
add_test("test_define_fixed_value")
add_test("test_undefine_fixed_value")

run_tests()

End

Sub setup_test()
  def.init()
End Sub

Sub test_define_given_undefined()
  assert_int_equals(0, set.size%(def.defines$()))

  def.define("foo")

  assert_no_error()
  assert_int_equals(1, def.is_defined%("foo"))
  assert_int_equals(0, def.is_defined%("bar"))
End Sub

Sub test_define_given_defined()
  def.define("foo")
  def.define("foo")

  assert_error("'foo' is already defined")
End Sub

Sub test_define_given_invalid()
  sys.err$ = ""
  def.define("")
  assert_error("invalid identifier")

  sys.err$ = ""
  def.define(" ")
  assert_error("invalid identifier")

  sys.err$ = ""
  def.define("?")
  assert_error("invalid identifier")

  sys.err$ = ""
  def.define("1hello")
  assert_error("invalid identifier")
End Sub

Sub test_define_given_too_long()
  def.define("flag567890123456789012345678901234567890123456789012345678901234")
  assert_no_error()

  def.define("flag5678901234567890123456789012345678901234567890123456789012345")
  assert_error("identifier too long, max 64 chars")
End Sub

Sub test_define_given_too_many()
  Local i%
  For i% = 1 To 10
    def.define("item" + Str$(i%))
  Next

  def.define("sausage")
  assert_error("too many defines")
End Sub

Sub test_define_case_insensitive()
  def.define("foo")
  def.define("bar")

  assert_int_equals(1, def.is_defined%("FOO"))
  assert_int_equals(1, def.is_defined%("BAR"))
End Sub

Sub test_undefine_given_defined()
  def.define("foo")
  def.define("bar")

  def.undefine("foo")
  assert_int_equals(0, def.is_defined%("foo"))
  assert_int_equals(1, def.is_defined%("bar"))

  def.undefine("bar")
  assert_int_equals(0, def.is_defined%("bar"))
End Sub

Sub test_undefine_given_undefined()
  def.undefine("foo")
  assert_no_error()

  def.undefine("BAR")
  assert_no_error()
End Sub

Sub test_undefine_case_insensitive()
  def.define("foo")
  def.define("bar")

  def.undefine("FOO")
  assert_int_equals(0, def.is_defined%("FOO"))
  assert_int_equals(1, def.is_defined%("BAR"))

  def.undefine("BAR")
  assert_int_equals(0, def.is_defined%("BAR"))
End Sub

Sub test_always_defined_values()
  Local values$(4) = ("1", "true", "TRUE", "on", "ON")
  Local i%
  For i% = Bound(values$(), 0) To Bound(values$(), 1)
    assert_int_equals(1, def.is_defined%(values$(i%)))
    assert_no_error()
  Next
End Sub

Sub test_always_undefined_values()
  Local values$(4) = ("0", "false", "FALSE", "off", "OFF")
  Local i%
  For i% = Bound(values$(), 0) To Bound(values$(), 1)
    assert_int_equals(0, def.is_defined%(values$(i%)))
    assert_no_error()
  Next
End Sub

Sub test_define_fixed_value()
  Local values$(9) = ("1", "true", "TRUE", "on", "ON", "0", "false", "FALSE", "off", "OFF")
  Local i%
  For i% = Bound(values$(), 0) To Bound(values$(), 1)
    def.define(values$(i%))
    assert_error("'" + values$(i%) + "' cannot be defined")
  Next
End Sub

Sub test_undefine_fixed_value()
  Local values$(9) = ("1", "true", "TRUE", "on", "ON", "0", "false", "FALSE", "off", "OFF")
  Local i%
  For i% = Bound(values$(), 0) To Bound(values$(), 1)
    def.undefine(values$(i%))
    assert_error("'" + values$(i%) + "' cannot be undefined")
  Next
End Sub

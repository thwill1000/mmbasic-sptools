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

add_test("test_set_flag")
add_test("test_set_flag_given_already_set")
add_test("test_set_flag_given_invalid")
add_test("test_set_flag_given_too_long")
add_test("test_set_flag_given_too_many")
add_test("test_set_flag_case_insensitive")
add_test("test_clear_flag_given_set")
add_test("test_clear_flag_given_unset")
add_test("test_clear_flag_case_insensitive")
add_test("test_always_set_flag")
add_test("test_always_clear_flag")
add_test("test_set_fixed_flag")
add_test("test_clear_fixed_flag")

run_tests()

End

Sub setup_test()
  def.init()
End Sub

Sub test_set_flag()
  assert_int_equals(0, set.size%(def.flags$()))

  def.set_flag("foo")

  assert_no_error()
  assert_int_equals(1, def.is_flag_set%("foo"))
  assert_int_equals(0, def.is_flag_set%("bar"))
End Sub

Sub test_set_flag_given_already_set()
  def.set_flag("foo")
  def.set_flag("foo")

  assert_error("flag 'foo' is already set")
End Sub

Sub test_set_flag_given_invalid()
  sys.err$ = ""
  def.set_flag("")
  assert_error("invalid flag")

  sys.err$ = ""
  def.set_flag(" ")
  assert_error("invalid flag")

  sys.err$ = ""
  def.set_flag("?")
  assert_error("invalid flag")

  sys.err$ = ""
  def.set_flag("1hello")
  assert_error("invalid flag")
End Sub

Sub test_set_flag_given_too_long()
  def.set_flag("flag567890123456789012345678901234567890123456789012345678901234")
  assert_no_error()

  def.set_flag("flag5678901234567890123456789012345678901234567890123456789012345")
  assert_error("flag too long, max 64 chars")
End Sub

Sub test_set_flag_given_too_many()
  Local i%
  For i% = 1 To 10
    def.set_flag("item" + Str$(i%))
  Next

  def.set_flag("sausage")
  assert_error("too many flags")
End Sub

Sub test_set_flag_case_insensitive()
  def.set_flag("foo")
  def.set_flag("bar")

  assert_int_equals(1, def.is_flag_set%("FOO"))
  assert_int_equals(1, def.is_flag_set%("BAR"))
End Sub

Sub test_clear_flag_given_set()
  def.set_flag("foo")
  def.set_flag("bar")

  def.clear_flag("foo")
  assert_int_equals(0, def.is_flag_set%("foo"))
  assert_int_equals(1, def.is_flag_set%("bar"))

  def.clear_flag("bar")
  assert_int_equals(0, def.is_flag_set%("bar"))
End Sub

Sub test_clear_flag_given_unset()
  def.clear_flag("foo")
  assert_error("flag 'foo' is not set")

  def.clear_flag("BAR")
  assert_error("flag 'BAR' is not set")
End Sub

Sub test_clear_flag_case_insensitive()
  def.set_flag("foo")
  def.set_flag("bar")

  def.clear_flag("FOO")
  assert_int_equals(0, def.is_flag_set%("FOO"))
  assert_int_equals(1, def.is_flag_set%("BAR"))

  def.clear_flag("BAR")
  assert_int_equals(0, def.is_flag_set%("BAR"))
End Sub

Sub test_always_set_flag()
  Local flags$(4) = ("1", "true", "TRUE", "on", "ON")
  Local i%
  For i% = Bound(flags$(), 0) To Bound(flags$(), 1)
    assert_int_equals(1, def.is_flag_set%(flags$(i%)))
    assert_no_error()
  Next
End Sub

Sub test_always_clear_flag()
  Local flags$(4) = ("0", "false", "FALSE", "off", "OFF")
  Local i%
  For i% = Bound(flags$(), 0) To Bound(flags$(), 1)
    assert_int_equals(0, def.is_flag_set%(flags$(i%)))
    assert_no_error()
  Next
End Sub

Sub test_set_fixed_flag()
  Local flags$(9) = ("1", "true", "TRUE", "on", "ON", "0", "false", "FALSE", "off", "OFF")
  Local i%
  For i% = Bound(flags$(), 0) To Bound(flags$(), 1)
    def.set_flag(flags$(i%))
    assert_error("flag '" + flags$(i%) + "' cannot be set")
  Next
End Sub

Sub test_clear_fixed_flag()
  Local flags$(9) = ("1", "true", "TRUE", "on", "ON", "0", "false", "FALSE", "off", "OFF")
  Local i%
  For i% = Bound(flags$(), 0) To Bound(flags$(), 1)
    def.clear_flag(flags$(i%))
    assert_error("flag '" + flags$(i%) + "' cannot be cleared")
  Next
End Sub

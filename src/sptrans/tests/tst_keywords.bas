' Copyright (c) 2020-2022 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07.07

Option Explicit On
Option Default Integer

#Include "../../splib/system.inc"
#Include "../../splib/array.inc"
#Include "../../splib/list.inc"
#Include "../../splib/string.inc"
#Include "../../splib/file.inc"
#Include "../../splib/map.inc"
#Include "../../splib/set.inc"
#Include "../../splib/vt100.inc"
#Include "../../sptest/unittest.inc"
#Include "../../common/sptools.inc"
#Include "../keywords.inc"

add_test("test_init")
add_test("test_contains")
add_test("test_get")

run_tests()

End

Sub test_init()
  keywords.init()

  assert_int_equals(455, map.size%(keywords$()))
  ' TODO: PEEK into keywords$() to assert LENGTH = 14
End Sub

Sub test_contains()
  assert_true(keywords.contains%("PRINT"))
  assert_true(keywords.contains%("print"))
  assert_false(keywords.contains%("WOMBAT"))
  assert_false(keywords.contains%("wombat"))
End Sub

Sub test_get()
  assert_string_equals("Print", keywords.get$("PRINT"))
  assert_string_equals("Print", keywords.get$("print"))
  assert_string_equals(sys.NO_DATA$, keywords.get$("wombat"))
End Sub

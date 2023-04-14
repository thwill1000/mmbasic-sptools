' Copyright (c) 2022 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMB4L 2022.01.00

Option Explicit On
Option Default None
Option Base InStr(Mm.CmdLine$, "--base=1") > 0

#Include "../../splib/system.inc"
#Include "../../splib/array.inc"
#Include "../../splib/map.inc"
#Include "../../splib/string.inc"
#Include "../../splib/inifile.inc"
#Include "../../splib/list.inc"
#Include "../../splib/file.inc"
#Include "../../splib/vt100.inc"
#Include "../../sptest/unittest.inc"
#Include "../history.inc"
#Include "../console.inc"
#Include "../spsh.inc"
#Include "../gonzo.inc"

Const BASE% = Mm.Info(Option Base)
Const TMPDIR$ = sys.string_prop$("tmpdir") + "/tst_gonzo"

add_test("test_parse_cl_given_empty")
add_test("test_parse_cl_given_0_args")
add_test("test_parse_cl_given_1_arg")
add_test("test_parse_cl_given_10_args")
add_test("test_parse_cl_given_11_args")
add_test("test_parse_cl_given_bang")
add_test("test_parse_cl_ignores_star")
add_test("test_parse_cl_ignores_xs_ws")

If InStr(Mm.CmdLine$, "--base") Then run_tests() Else run_tests("--base=1")

End

Sub setup_test()
  If file.exists%(TMPDIR$) Then
    If file.delete%(TMPDIR$, 1) <> sys.SUCCESS Then Error "Failed to delete directory '" + TMPDIR$ + "'"
  EndIf
  MkDir TMPDIR$
End Sub

Sub teardown_test()
  If file.delete%(TMPDIR$, 1) <> sys.SUCCESS Then Error "Failed to delete directory '" + TMPDIR$ + "'"
End Sub

Sub test_parse_cl_given_empty()
  Local cmd$, argc%, argv$(array.new%(10))

  gonzo.parse_cmd_line("", cmd$, argc%, argv$())

  assert_string_equals("", cmd$)
  assert_int_equals(0, argc%)
  Local expected$(array.new%(10))
  assert_string_array_equals(expected$(), argv$())
End Sub

Sub test_parse_cl_given_0_args()
  Local cmd$, argc%, argv$(array.new%(10))

  gonzo.parse_cmd_line("foo", cmd$, argc%, argv$())

  assert_string_equals("foo", cmd$)
  assert_int_equals(0, argc%)
  Local expected$(array.new%(10))
  assert_string_array_equals(expected$(), argv$())
End Sub

Sub test_parse_cl_given_1_arg()
  Local cmd$, argc%, argv$(array.new%(10))

  gonzo.parse_cmd_line("foo bar", cmd$, argc%, argv$())

  assert_string_equals("foo", cmd$)
  assert_int_equals(1, argc%)
  Local expected$(array.new%(10)) = ("bar", "", "", "", "", "", "", "", "", "")
  assert_string_array_equals(expected$(), argv$())
End Sub

Sub test_parse_cl_given_10_args()
  Local cmd$, argc%, argv$(array.new%(10))

  gonzo.parse_cmd_line("foo 1 2 3 4 5 6 7 8 9 10", cmd$, argc%, argv$())

  assert_string_equals("foo", cmd$)
  assert_int_equals(10, argc%)
  Local expected$(array.new%(10)) = ("1", "2", "3", "4", "5", "6", "7", "8", "9", "10")
  assert_string_array_equals(expected$(), argv$())
End Sub

Sub test_parse_cl_given_11_args()
  Local cmd$, argc%, argv$(array.new%(10))

  gonzo.parse_cmd_line("foo 1 2 3 4 5 6 7 8 9 10 11", cmd$, argc%, argv$())

  assert_string_equals("foo", cmd$)
  assert_int_equals(10, argc%)
  Local expected$(array.new%(10)) = ("1", "2", "3", "4", "5", "6", "7", "8", "9", "10")
  assert_string_array_equals(expected$(), argv$())
End Sub

Sub test_parse_cl_given_bang()
  Local cmd$, argc%, argv$(array.new%(10))

  gonzo.parse_cmd_line("!66", cmd$, argc%, argv$())

  assert_string_equals("!", cmd$)
  assert_int_equals(1, argc%)
  Local expected$(array.new%(10)) = ("66", "", "", "", "", "", "", "", "", "")
  assert_string_array_equals(expected$(), argv$())
End Sub

Sub test_parse_cl_ignores_star()
  Local cmd$, argc%, argv$(array.new%(10))

  gonzo.parse_cmd_line("*foo bar", cmd$, argc%, argv$())

  assert_string_equals("foo", cmd$)
  assert_int_equals(1, argc%)
  Local expected$(array.new%(10)) = ("bar", "", "", "", "", "", "", "", "", "")
  assert_string_array_equals(expected$(), argv$())
End Sub

Sub test_parse_cl_ignores_xs_ws()
  Local cmd$, argc%, argv$(array.new%(10))

  gonzo.parse_cmd_line("   foo   bar   ", cmd$, argc%, argv$())

  assert_string_equals("foo", cmd$)
  assert_int_equals(1, argc%)
  Local expected$(array.new%(10)) = ("bar", "", "", "", "", "", "", "", "", "")
  assert_string_array_equals(expected$(), argv$())
End Sub

' Copyright (c) 2020-2021 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For Colour Maximite 2, MMBasic 5.07

Option Explicit On
Option Default None
Option Base InStr(Mm.CmdLine$, "--base=1") > 0

#Include "../system.inc"
#Include "../array.inc"
#Include "../list.inc"
#Include "../string.inc"
#Include "../file.inc"
#Include "../vt100.inc"
#Include "../../sptest/unittest.inc"

add_test("test_colour")
add_test("test_colour_case_insensitive")
add_test("test_colour_given_unknown")

If InStr(Mm.CmdLine$, "--base") Then run_tests() Else run_tests("--base=1")

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Sub test_colour()
  assert_string_equals(Chr$(27) + "[30m", vt100.colour$("BLACK"))
  assert_string_equals(Chr$(27) + "[31m", vt100.colour$("RED"))
  assert_string_equals(Chr$(27) + "[32m", vt100.colour$("GREEN"))
  assert_string_equals(Chr$(27) + "[33m", vt100.colour$("YELLOW"))
  assert_string_equals(Chr$(27) + "[34m", vt100.colour$("BLUE"))
  assert_string_equals(Chr$(27) + "[35m", vt100.colour$("MAGENTA"))
  assert_string_equals(Chr$(27) + "[35m", vt100.colour$("PURPLE"))
  assert_string_equals(Chr$(27) + "[36m", vt100.colour$("CYAN"))
  assert_string_equals(Chr$(27) + "[37m", vt100.colour$("WHITE"))
  assert_string_equals(Chr$(27) + "[0m",  vt100.colour$("RESET"))
End Sub

Sub test_colour_case_insensitive()
  assert_string_equals(Chr$(27) + "[30m", vt100.colour$("black"))
  assert_string_equals(Chr$(27) + "[31m", vt100.colour$("ReD"))
  assert_string_equals(Chr$(27) + "[32m", vt100.colour$("GREEN"))
  assert_string_equals(Chr$(27) + "[33m", vt100.colour$("yellow"))
  assert_string_equals(Chr$(27) + "[34m", vt100.colour$("BLue"))
  assert_string_equals(Chr$(27) + "[35m", vt100.colour$("MAgeNTA"))
  assert_string_equals(Chr$(27) + "[35m", vt100.colour$("PuRPlE"))
  assert_string_equals(Chr$(27) + "[36m", vt100.colour$("CyaN"))
  assert_string_equals(Chr$(27) + "[37m", vt100.colour$("white"))
  assert_string_equals(Chr$(27) + "[0m",  vt100.colour$("ReSeT"))
End Sub

Sub test_colour_given_unknown()
  On Error Skip 2
  Local s$ = vt100.colour$("wombat")
  assert_raw_error("Unknown VT100 colour: wombat")
End Sub

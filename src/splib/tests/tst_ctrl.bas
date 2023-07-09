' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

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
#Include "../ctrl.inc"

add_test("test_open_driver")
add_test("test_close_driver")

run_tests(Choice(InStr(Mm.CmdLine$, "--base"), "", "--base=1"))

End

Sub setup_test()
  ctrl.open_drivers$ = ""
End Sub

Sub test_open_driver()
  ctrl.open_driver("atari_a")
  assert_string_equals("atari_a,", ctrl.open_drivers$)
  ctrl.open_driver("nes_b")
  assert_string_equals("atari_a,nes_b,", ctrl.open_drivers$)
End Sub

Sub test_close_driver()
  ctrl.open_driver("one")
  ctrl.open_driver("two")
  ctrl.open_driver("three")
  ctrl.open_driver("four")
  ctrl.open_driver("five")

  ' Remove first element
  ctrl.close_driver("one")
  assert_string_equals("two,three,four,five,", ctrl.open_drivers$)

  ' Remove last element
  ctrl.close_driver("five")
  assert_string_equals("two,three,four,", ctrl.open_drivers$)

  ' Remove middle element
  ctrl.close_driver("three")
  assert_string_equals("two,four,", ctrl.open_drivers$)

  ctrl.close_driver("four")
  assert_string_equals("two,", ctrl.open_drivers$)

  ' Close last element
  ctrl.close_driver("two")
  assert_string_equals("", ctrl.open_drivers$)
End Sub

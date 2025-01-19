' Copyright (c) 2023-2025 Thomas Hugo Williams
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

add_test("test_add_driver")
add_test("test_remove_driver")

run_tests(Choice(InStr(Mm.CmdLine$, "--base"), "", "--base=1"))

End

Sub setup_test()
  ctrl.driver_list$ = ""
End Sub

Sub test_add_driver()
  ctrl.add_driver("atari_a")
  assert_string_equals("atari_a,", ctrl.driver_list$)
  ctrl.add_driver("nes_b")
  assert_string_equals("atari_a,nes_b,", ctrl.driver_list$)
End Sub

Sub test_remove_driver()
  ctrl.add_driver("one")
  ctrl.add_driver("two")
  ctrl.add_driver("three")
  ctrl.add_driver("four")
  ctrl.add_driver("five")

  ' Remove first element
  ctrl.remove_driver("one")
  assert_string_equals("two,three,four,five,", ctrl.driver_list$)

  ' Remove last element
  ctrl.remove_driver("five")
  assert_string_equals("two,three,four,", ctrl.driver_list$)

  ' Remove middle element
  ctrl.remove_driver("three")
  assert_string_equals("two,four,", ctrl.driver_list$)

  ctrl.remove_driver("four")
  assert_string_equals("two,", ctrl.driver_list$)

  ' Close last element
  ctrl.remove_driver("two")
  assert_string_equals("", ctrl.driver_list$)
End Sub

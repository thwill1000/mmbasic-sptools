:' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default None

If InStr(Mm.CmdLine$, "--base=1") Then
  Option Base 1
Else
  Option Base 0
EndIf

#Include "../system.inc"
#Include "../array.inc"
#Include "../list.inc"
#Include "../string.inc"
#Include "../file.inc"
#Include "../vt100.inc"
#Include "../../sptest/unittest.inc"

add_test("test_provides")
add_test("test_provides_given_duplicates")
add_test("test_provides_given_too_many")
add_test("test_requires")
add_test("test_firmware_version")
add_test("test_pseudo")

If InStr(Mm.CmdLine$, "--base") Then run_tests() Else run_tests("--base=1")

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Sub test_provides()
  Local i%
  For i% = 1 To sys.MAX_INCLUDES% : sys.includes$(i%) = "" : Next

  sys.provides("foo")
  sys.provides("bar")

  assert_no_error()
  If Mm.Info(Option Base) = 0 Then assert_string_equals("", sys.includes$(0))
  assert_string_equals("foo", sys.includes$(1))
  assert_string_equals("bar", sys.includes$(2))
  For i% = 3 To sys.MAX_INCLUDES% : assert_string_equals("", sys.includes$(i%)) : Next
End Sub

Sub test_provides_given_duplicates()
  Local i%
  For i% = 1 To sys.MAX_INCLUDES% : sys.includes$(i%) = "" : Next
  sys.provides("list")
  sys.provides("set")
  assert_no_error()

  sys.provides("list")
  assert_error("file already included: list.inc")
End Sub

Sub test_provides_given_too_many()
  Local i%
  For i% = 1 To sys.MAX_INCLUDES% : sys.includes$(i%) = "foo" + Str$(i%) : Next
  assert_no_error()

  sys.provides("wombat")
  assert_error("too many includes")
End Sub

Sub test_requires()
  Local i%
  sys.includes$(1) = "foo"
  sys.includes$(2) = "bar"
  For i% = 3 To sys.MAX_INCLUDES% : sys.includes$(i%) = "" : Next

  sys.requires("bar")
  assert_no_error()

  sys.requires("wombat")
  assert_error("required file(s) not included: wombat.inc")

  sys.requires("snafu")
  assert_error("required file(s) not included: snafu.inc")

  sys.requires("wombat", "snafu")
  assert_error("required file(s) not included: wombat.inc, snafu.inc")
End Sub

Sub test_firmware_version()
  assert_equals(50605, sys.firmware_version%("5.06.05"))
  assert_equals(50600, sys.firmware_version%("5.06"))
'  assert_equals(50506, sys.firmware_version%())
  assert_equals(12345678, sys.firmware_version%("12.34.5.678"))
End Sub

Sub test_pseudo()
  Local base% = Mm.Info(Option Base)
  Local x% = sys.pseudo%(-7) ' seed the random number generator.

  ' Assert that first 10 generated values are as expected.
  Local i%
  Local expected%(base% + 9) = (6,4,4,7,10,2,10,10,3,4)
  For i% = base% To base% + 9
    assert_equals(expected%(i%), sys.pseudo%(10))
  Next

  ' Assert that calling the Sub 1000 times generates each number 1..10 at least once.
  Local count%(10)
  For i% = 1 To 1000
    x% = sys.pseudo%(10)
    count%(x%) = count%(x%) + 1
  Next

  If base% = 0 Then assert_equals(0, count%(0))
  For i% = 1 To 10
    assert_equals(1, count%(i%) > 0)
  Next
End Sub

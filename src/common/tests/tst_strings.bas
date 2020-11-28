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
#Include "../strings.inc"
#Include "../file.inc"
#Include "../set.inc"
#Include "../../sptest/unittest.inc"

add_test("test_centre")
add_test("test_join")
add_test("test_lpad")
add_test("test_next_token")
add_test("test_rpad")
add_test("test_tokenise")

If InStr(Mm.CmdLine$, "--base") Then run_tests() Else run_tests("--base=1")

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Sub test_centre()
  assert_string_equals("     hello     ", str.centre$("hello", 15))
  assert_string_equals("     hello      ", str.centre$("hello", 16))
  assert_string_equals("hello", str.centre$("hello", 2))
End Sub

Sub test_join()
  Local elements$(list.new%(4))

  assert_string_equals("", str.join$(elements$(), ","))

  list.add(elements$(), "one")

  assert_string_equals("one", str.join$(elements$(), ","))

  list.add(elements$(), "two")
  list.add(elements$(), "three")
  list.add(elements$(), "four")

  assert_string_equals("one,two,three,four", str.join$(elements$(), ","))
  assert_string_equals("one, two, three, four", str.join$(elements$(), ", ")) 
End Sub

Sub test_lpad()
  assert_string_equals("     hello", str.lpad$("hello", 10))
  assert_string_equals("hello", str.lpad$("hello", 2))
End Sub

Sub test_next_token()
  Local s$ = "  foo    bar wombat$  "

  assert_string_equals("foo", str.next_token$(s$))
  assert_string_equals("bar", str.next_token$(s$))
  assert_string_equals("wombat$", str.next_token$(s$))
  assert_string_equals("", str.next_token$(s$))
  assert_string_equals("", s$)
End Sub

Sub test_rpad()
  assert_string_equals("hello     ", str.rpad$("hello", 10))
  assert_string_equals("hello", str.rpad$("hello", 2))
End Sub

Sub test_tokenise()
  Local base% = Mm.Info(Option Base)
  Local elements$(list.new%(20))

  str.tokenise("one,two,three,four", ",", elements$())

  assert_equals(4, list.size%(elements$()))
  assert_string_equals("one",   elements$(base% + 0))
  assert_string_equals("two",   elements$(base% + 1))
  assert_string_equals("three", elements$(base% + 2))
  assert_string_equals("four",  elements$(base% + 3))
  assert_string_equals("",      elements$(base% + 4))
End Sub

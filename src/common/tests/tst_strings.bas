:' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

#Include "../error.inc"
#Include "../file.inc"
#Include "../list.inc"
#Include "../set.inc"
#Include "../strings.inc"
#Include "../../sptest/unittest.inc"

add_test("test_centre")
add_test("test_join")
add_test("test_lpad")
add_test("test_next_token")
add_test("test_rpad")
add_test("test_tokenise")

run_tests()

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Function test_centre()
  assert_string_equals("     hello     ", str.centre$("hello", 15))
  assert_string_equals("     hello      ", str.centre$("hello", 16))
  assert_string_equals("hello", str.centre$("hello", 2))
End Function

Function test_join()
  Local elements$(3) = ("one", "two", "three", "four")

  assert_string_equals("one,two,three,four", str.join$(elements$(), 4, ","))
  assert_string_equals("one, two, three, four", str.join$(elements$(), 4, ", "))
  assert_string_equals("", str.join$(elements$(), 0, ","))
  assert_string_equals("one", str.join$(elements$(), 1, ","))
End Function

Function test_lpad()
  assert_string_equals("     hello", str.lpad$("hello", 10))
  assert_string_equals("hello", str.lpad$("hello", 2))
End Function

Function test_next_token()
  Local s$ = "  foo    bar wombat$  "

  assert_string_equals("foo", str.next_token$(s$))
  assert_string_equals("bar", str.next_token$(s$))
  assert_string_equals("wombat$", str.next_token$(s$))
  assert_string_equals("", str.next_token$(s$))
  assert_string_equals("", s$)
End Function

Function test_rpad()
  assert_string_equals("hello     ", str.rpad$("hello", 10))
  assert_string_equals("hello", str.rpad$("hello", 2))
End Function

Function test_tokenise()
  Local elements$(19), sz

  str.tokenise("one,two,three,four", ",", elements$(), sz)

  assert_equals(4, sz)
  assert_string_equals("one", elements$(0))
  assert_string_equals("two", elements$(1))
  assert_string_equals("three", elements$(2))
  assert_string_equals("four",  elements$(3))
  assert_string_equals("", elements$(4))
End Function

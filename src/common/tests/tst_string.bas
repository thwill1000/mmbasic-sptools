' Copyright (c) 2020 Thomas Hugo Williams

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

add_test("test_centre")
add_test("test_join")
add_test("test_lpad")
add_test("test_next_token")
add_test("test_quote")
add_test("test_rpad")

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
  Local base% = Mm.Info(Option Base)
  Local a$(array.new%(4)) = ("one", "two", "three", "four")

  assert_string_equals("one,two,three,four", str.join$(a$(), ","))
  assert_string_equals("one, two, three, four", str.join$(a$(), ", "))
  assert_string_equals("one", str.join$(a$(), ",", , 1))
  assert_string_equals("one,two", str.join$(a$(), ",", , 2))
  assert_string_equals("three,four", str.join$(a$(), ",", base% + 2, 2))
  assert_string_equals("two,three,four", str.join$(a$(), ",", base% + 1))
End Sub

Sub test_lpad()
  assert_string_equals("     hello", str.lpad$("hello", 10))
  assert_string_equals("hello", str.lpad$("hello", 2))
End Sub

Sub test_next_token()
  Local test$ = "!foo !@bar !!  wombat$ @@snafu@! @"

  ' Default space separator and no empty tokens.
  assert_string_equals("!foo", str.next_token$(test$))
  assert_string_equals("!@bar", str.next_token$())
  assert_string_equals("!!", str.next_token$())
  assert_string_equals("wombat$", str.next_token$())
  assert_string_equals("@@snafu@!", str.next_token$())
  assert_string_equals("@", str.next_token$())
  assert_string_equals(sys.NO_DATA$, str.next_token$())

  ' ! separator keeping empty tokens.
  assert_string_equals("", str.next_token$(test$, "!"))
  assert_string_equals("foo ", str.next_token$())
  assert_string_equals("@bar ", str.next_token$())
  assert_string_equals("", str.next_token$())
  assert_string_equals("  wombat$ @@snafu@", str.next_token$())
  assert_string_equals(" @", str.next_token$())
  assert_string_equals(sys.NO_DATA$, str.next_token$())

  ' ! separator skipping empty tokens.
  assert_string_equals("foo ", str.next_token$(test$, "!", 1))
  assert_string_equals("@bar ", str.next_token$())
  assert_string_equals("  wombat$ @@snafu@", str.next_token$())
  assert_string_equals(" @", str.next_token$())
  assert_string_equals(sys.NO_DATA$, str.next_token$())

  ' @ separator keeping empty tokens.
  assert_string_equals("!foo !", str.next_token$(test$, "@"))
  assert_string_equals("bar !!  wombat$ ", str.next_token$())
  assert_string_equals("", str.next_token$())
  assert_string_equals("snafu", str.next_token$())
  assert_string_equals("! ", str.next_token$())
  assert_string_equals("", str.next_token$())
  assert_string_equals(sys.NO_DATA$, str.next_token$())

  ' @ separator skipping empty tokens.
  assert_string_equals("!foo !", str.next_token$(test$, "@", 1))
  assert_string_equals("bar !!  wombat$ ", str.next_token$())
  assert_string_equals("snafu", str.next_token$())
  assert_string_equals("! ", str.next_token$())
  assert_string_equals(sys.NO_DATA$, str.next_token$())

  ' @ or ! separators keeping empty tokens.
  assert_string_equals("", str.next_token$(test$, "@!"))
  assert_string_equals("foo ", str.next_token$())
  assert_string_equals("", str.next_token$())
  assert_string_equals("bar ", str.next_token$())
  assert_string_equals("", str.next_token$())
  assert_string_equals("  wombat$ ", str.next_token$())
  assert_string_equals("", str.next_token$())
  assert_string_equals("snafu", str.next_token$())
  assert_string_equals("", str.next_token$())
  assert_string_equals(" ", str.next_token$())
  assert_string_equals("", str.next_token$())
  assert_string_equals(sys.NO_DATA$, str.next_token$())

  ' @ or ! separators skipping empty tokens.
  assert_string_equals("foo ", str.next_token$(test$, "@!", 1))
  assert_string_equals("bar ", str.next_token$())
  assert_string_equals("  wombat$ ", str.next_token$())
  assert_string_equals("snafu", str.next_token$())
  assert_string_equals(" ", str.next_token$())
  assert_string_equals(sys.NO_DATA$, str.next_token$())

  ' Tokenise the empty string, keeping empty tokens.
  assert_string_equals(sys.NO_DATA$, str.next_token$("", "@", 1))

  ' Tokenise the empty string, skipping empty tokens.
  assert_string_equals("", str.next_token$("", "@", 0))
  assert_string_equals(sys.NO_DATA$, str.next_token$())
End Sub

Sub test_quote()
  Const QU$ = Chr$(34)
  assert_string_equals(QU$ + "hello" + QU$, str.quote$("hello"))
  assert_string_equals(QU$ + "hello world" + QU$, str.quote$("hello world"))
  assert_string_equals(QU$ + QU$ + "hello world" + QU$ + QU$, str.quote$(str.quote$("hello world")))

  assert_string_equals("'hello'", str.quote$("hello", "'"))
  assert_string_equals("'hello world'", str.quote$("hello world", "'"))
  assert_string_equals("''hello world''", str.quote$(str.quote$("hello world", "'"), "'"))

  assert_string_equals("{hello}", str.quote$("hello", "{", "}"))
  assert_string_equals("{hello world}", str.quote$("hello world", "{", "}"))
  assert_string_equals("<{hello world}>", str.quote$(str.quote$("hello world", "{", "}"), "<", ">"))
End Sub

Sub test_rpad()
  assert_string_equals("hello     ", str.rpad$("hello", 10))
  assert_string_equals("hello", str.rpad$("hello", 2))
End Sub

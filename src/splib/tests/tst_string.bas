' Copyright (c) 2020-2021 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.06

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
add_test("test_equals_ignore_case")
add_test("test_lpad")
add_test("test_next_token")
add_test("test_quote")
add_test("test_rpad")
add_test("test_trim")
add_test("test_unquote")

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

Sub test_equals_ignore_case()
  assert_true(str.equals_ignore_case%("", ""))
  assert_true(str.equals_ignore_case%("foo", "FOO"))
  assert_true(str.equals_ignore_case%("fOo", "foO"))
  assert_false(str.equals_ignore_case%("foo", "BAR"))
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

  ' Tokenising the empty string only works if the previous tokenisation returned sys.NO_DATA$
  ' otherise using "" as the first argument will just continue that previous tokenisation.
  assert_string_equals(sys.NO_DATA$, str.next_token$(sys.NO_DATA$, " ", 0))
  assert_string_equals(sys.NO_DATA$, str.next_token$(sys.NO_DATA$, " ", 1))
  assert_string_equals(sys.NO_DATA$, str.next_token$(sys.NO_DATA$, "@", 0))
  assert_string_equals(sys.NO_DATA$, str.next_token$(sys.NO_DATA$, "@", 1))
  assert_string_equals(sys.NO_DATA$, str.next_token$("", " ", 0))
  assert_string_equals(sys.NO_DATA$, str.next_token$("", " ", 1))
  assert_string_equals(sys.NO_DATA$, str.next_token$("", "@", 0))
  assert_string_equals(sys.NO_DATA$, str.next_token$("", "@", 1))
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

Sub test_trim()
  assert_string_equals("f", str.trim$("f"))
  assert_string_equals("f", str.trim$(" f"))
  assert_string_equals("f", str.trim$("f "))
  assert_string_equals("f", str.trim$(" f "))
  assert_string_equals("foo", str.trim$("  foo"))
  assert_string_equals("foo", str.trim$("foo   "))
  assert_string_equals("foo", str.trim$("  foo   "))
  assert_string_equals("foo bar", str.trim$(" foo bar  "))
  assert_string_equals("", str.trim$(""))
  assert_string_equals("", str.trim$(" "))
  assert_string_equals("", str.trim$("  "))
  assert_string_equals("", str.trim$("   "))

End Sub

Sub test_unquote()
  Const QU$ = Chr$(34)
  assert_string_equals("foo", str.unquote$(QU$ + "foo" + QU$))
  assert_string_equals(QU$ + "foo", str.unquote$(QU$ + "foo"))
  assert_string_equals("foo" + QU$, str.unquote$("foo" + QU$))
  assert_string_equals(" " + QU$ + "foo" + QU$, str.unquote$(" " + QU$ + "foo" + QU$))
  assert_string_equals(QU$ + "foo" + QU$ + " ", str.unquote$(QU$ + "foo" + QU$ + " "))
End Sub

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

add_test("test_centre")
add_test("test_equals_ignore_case")
add_test("test_lpad")
add_test("test_is_plain_ascii")
add_test("test_next_token")
add_test("test_next_token_given_quotes")
add_test("test_quote")
add_test("test_replace")
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
  assert_string_equals("      hello     ", str.centre$("hello", 16))
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

Sub test_is_plain_ascii()
  Local i%
  For i% = 0 To 8 : assert_false(str.is_plain_ascii%("foo" + Chr$(i%) + "bar")) : Next
  assert_true(str.is_plain_ascii%("foo" + Chr$(9) + "bar"))   ' Tab
  assert_true(str.is_plain_ascii%("foo" + Chr$(10) + "bar"))  ' Line Feed
  assert_false(str.is_plain_ascii%("foo" + Chr$(11) + "bar")) ' Vertical Tab
  assert_false(str.is_plain_ascii%("foo" + Chr$(12) + "bar")) ' Form Feed
  assert_true(str.is_plain_ascii%("foo" + Chr$(13) + "bar"))  ' Carriage Return
  For i% = 14 To 31 : assert_false(str.is_plain_ascii%("foo" + Chr$(i%) + "bar")) : Next
  For i% = 32 To 126 : assert_true(str.is_plain_ascii%("foo" + Chr$(i%) + "bar")) : Next
  assert_false(str.is_plain_ascii%("foo" + Chr$(127))) ' Delete
End Sub

Sub test_next_token()
  Local in$ = "!foo !@bar !!  wombat$ @@snafu@! @"

  ' Default space separator and no empty tokens.
  assert_string_equals("!foo", str.next_token$(in$))
  assert_string_equals("!@bar", str.next_token$())
  assert_string_equals("!!", str.next_token$())
  assert_string_equals("wombat$", str.next_token$())
  assert_string_equals("@@snafu@!", str.next_token$())
  assert_string_equals("@", str.next_token$())
  assert_string_equals(sys.NO_DATA$, str.next_token$())

  ' ! separator keeping empty tokens.
  assert_string_equals("", str.next_token$(in$, "!"))
  assert_string_equals("foo ", str.next_token$())
  assert_string_equals("@bar ", str.next_token$())
  assert_string_equals("", str.next_token$())
  assert_string_equals("  wombat$ @@snafu@", str.next_token$())
  assert_string_equals(" @", str.next_token$())
  assert_string_equals(sys.NO_DATA$, str.next_token$())

  ' ! separator skipping empty tokens.
  assert_string_equals("foo ", str.next_token$(in$, "!", 1))
  assert_string_equals("@bar ", str.next_token$())
  assert_string_equals("  wombat$ @@snafu@", str.next_token$())
  assert_string_equals(" @", str.next_token$())
  assert_string_equals(sys.NO_DATA$, str.next_token$())

  ' @ separator keeping empty tokens.
  assert_string_equals("!foo !", str.next_token$(in$, "@"))
  assert_string_equals("bar !!  wombat$ ", str.next_token$())
  assert_string_equals("", str.next_token$())
  assert_string_equals("snafu", str.next_token$())
  assert_string_equals("! ", str.next_token$())
  assert_string_equals("", str.next_token$())
  assert_string_equals(sys.NO_DATA$, str.next_token$())

  ' @ separator skipping empty tokens.
  assert_string_equals("!foo !", str.next_token$(in$, "@", 1))
  assert_string_equals("bar !!  wombat$ ", str.next_token$())
  assert_string_equals("snafu", str.next_token$())
  assert_string_equals("! ", str.next_token$())
  assert_string_equals(sys.NO_DATA$, str.next_token$())

  ' @ or ! separators keeping empty tokens.
  assert_string_equals("", str.next_token$(in$, "@!"))
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
  assert_string_equals("foo ", str.next_token$(in$, "@!", 1))
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

Sub test_next_token_given_quotes()
  Local in$ = str.replace$("@token1@ @token 2@", "@", Chr$(34))
  assert_string_equals(Chr$(34) + "token1" + Chr$(34), str.next_token$(in$))
  assert_string_equals(Chr$(34) + "token 2" + Chr$(34), str.next_token$())
  assert_string_equals(sys.NO_DATA$, str.next_token$())

  in$ = str.replace$("@token1", "@", Chr$(34))
  assert_string_equals(in$, str.next_token$(in$))
  assert_string_equals(sys.NO_DATA$, str.next_token$())

  in$ = str.replace$("token1@", "@", Chr$(34))
  assert_string_equals(in$, str.next_token$(in$))
  assert_string_equals(sys.NO_DATA$, str.next_token$())

  in$ = Chr$(34)
  assert_string_equals(in$, str.next_token$(in$))
  assert_string_equals(sys.NO_DATA$, str.next_token$())

  in$ = Chr$(34) + Chr$(34)
  assert_string_equals(in$, str.next_token$(in$))
  assert_string_equals(sys.NO_DATA$, str.next_token$())

  in$ = Chr$(34) + Chr$(34) + Chr$(34)
  assert_string_equals(in$, str.next_token$(in$))
  assert_string_equals(sys.NO_DATA$, str.next_token$())

  in$ =  Chr$(34) + Chr$(34) + Chr$(34) + Chr$(34)
  assert_string_equals(in$, str.next_token$(in$))
  assert_string_equals(sys.NO_DATA$, str.next_token$())

  in$ = str.replace$("@\@\@\@\@@", "@", Chr$(34))
  assert_string_equals(in$, str.next_token$(in$))
  assert_string_equals(sys.NO_DATA$, str.next_token$())

  in$ = str.replace$("foo@bar", "@", Chr$(34))
  assert_string_equals(in$, str.next_token$(in$))

  in$ = str.replace$("@foo@bar@", "@", Chr$(34))
  assert_string_equals(in$, str.next_token$(in$))

  in$ = str.replace$("@foo\@bar@", "@", Chr$(34))
  assert_string_equals(in$, str.next_token$(in$))

  in$ = str.replace$("rcmd @RUN \@foo bar.bas\@@", "@", Chr$(34))
  assert_string_equals("rcmd", str.next_token$(in$))
  assert_string_equals(Chr$(34) + "RUN \" + Chr$(34) + "foo bar.bas\" + Chr$(34) + Chr$(34), str.next_token$())
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

Sub test_replace()
  assert_string_equals("", str.replace$("", "foo", "bar"))
  assert_string_equals("Hello World", str.replace$("Hello World", "foo", "bar"))
  assert_string_equals("Goodbye World", str.replace$("Hello World", "Hello", "Goodbye"))
  assert_string_equals("Hello Goodbye", str.replace$("Hello World", "World", "Goodbye"))
  assert_string_equals("He**o Wor*d", str.replace$("Hello World", "l", "*"))
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
  assert_string_equals(QU$, str.unquote$(QU$))
End Sub

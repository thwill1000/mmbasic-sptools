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
add_test("test_decode")
add_test("test_encode")
add_test("test_wwrap")
add_test("test_wwrap_given_empty")
add_test("test_wwrap_given_just_spaces")
add_test("test_wwrap_given_space_at_len")
add_test("test_wwrap_given_cr_at_len")
add_test("test_wwrap_given_lf_at_len")
add_test("test_wwrap_given_crlf_at_len")
add_test("test_wwrap_given_space_at_len_plus_1", "test_wwrap_given_space_at_lenp1")
add_test("test_wwrap_given_cr_at_len_plus_1", "test_wwrap_given_cr_at_lenp1")
add_test("test_wwrap_given_lf_at_len_plus_1", "test_wwrap_given_lf_at_lenp1")
add_test("test_wwrap_given_crlf_at_len_plus_1", "test_wwrap_given_crlf_at_lenp1")
add_test("test_wwrap_given_crlf_at_len_minus_1", "test_wwrap_given_crlf_at_lenm1")
add_test("test_wwrap_given_word_too_long")
add_test("test_wwrap_given_space_at_start")
add_test("test_wwrap_given_cr_at_start")
add_test("test_wwrap_given_lf_at_start")
add_test("test_wwrap_given_crlf_at_start")
add_test("test_wwrap_given_space_at_end")
add_test("test_wwrap_given_cr_at_end")
add_test("test_wwrap_given_lf_at_end")
add_test("test_wwrap_given_crlf_at_end")
add_test("test_wwrap_given_broken_spaces")

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

Sub test_decode()
  Local decoded$, encoded$
  Restore decode_encode_data
  Do While read_encoded_decoded%(encoded$, decoded$) = sys.SUCCESS
    assert_string_equals(decoded$, str.decode$(encoded$))
  Loop

  Restore decode_only_data
  Do While read_encoded_decoded%(encoded$, decoded$) = sys.SUCCESS
    assert_string_equals(decoded$, str.decode$(encoded$))
  Loop

  ' C-style escape for double-quote.
  assert_string_equals(Chr$(34), str.decode$("\" + Chr$(34)))
End Sub

Function read_encoded_decoded%(encoded$, decoded$)
  Local x%
  Read encoded$
  If encoded$ = "<END>" Then
    read_encoded_decoded% = -1
  Else
    decoded$ = ""
    Do
      Read x%
      If x% <> -1 Then Cat decoded$, Chr$(x%)
    Loop Until x% = -1
  EndIf
End Function

Sub test_encode()
  Local decoded$, encoded$
  Restore decode_encode_data
  Do While read_encoded_decoded%(encoded$, decoded$) = sys.SUCCESS
    assert_string_equals(encoded$, str.encode$(decoded$))
  Loop
End Sub

decode_encode_data:
Data "a", &h61, -1, "A", &h41, -1, "z", &h7A, -1, "Z", &h5A, -1
Data "\0", &h00, -1, "\x01", &h01, -1, "\x7F", &h7F, -1
Data "\a", &h07, -1, "\b", &h08, -1, "\e", &h1B, -1, "\f", &h0C, -1
Data "\n", &h0A, -1, "\r", &h0D, -1, "\t", &h09, -1, "\v", &h0B, -1
Data "\\", &h5C, -1, "\'", &h27, -1, "\q", &h22, -1, "\?", &h3F, -1
Data "b\n", &h62, &h0A, -1
Data "hello world", &h68, &h65, &h6C, &h6C, &h6F, &h20, &h77, &h6F, &h72, &h6C, &h64, -1
Data "<END>"

decode_only_data:
Data "\", &h5C, -1
Data "c\", &h63, &h5C, -1
Data "\x00", &h00, -1
Data "\x", &h5C, &h78, -1
Data "\x1", &h5C, &h78, &h31, -1
Data "\xz", &h5C, &h78, &h7A, -1
Data "\x1z", &h5C, &h78, &h31, &h7A, -1
Data "\m", &h5C, &h6D, -1
Data "\X01", &h5C, &h58, &h30, &h31, -1
Data "<END>"

Sub test_wwrap()
  Local p% = 1, s$ = "Moses supposes his toeses are roses\r"
  Cat s$, "But moses supposes erroneously\r\n"
  Cat s$, "For nobodies toeses are roses\n"
  Cat s$, "As moses supposes his toeses to be"
  s$ = str.decode$(s$)

  assert_string_equals("Moses supposes his ", str.wwrap$(s$, p%, 20))
  assert_string_equals("toeses are roses", str.wwrap$(s$, p%, 20))
  assert_string_equals("But moses supposes ", str.wwrap$(s$, p%, 20))
  assert_string_equals("erroneously", str.wwrap$(s$, p%, 20))
  assert_string_equals("For nobodies toeses ", str.wwrap$(s$, p%, 20))
  assert_string_equals("are roses", str.wwrap$(s$, p%, 20))
  assert_string_equals("As moses supposes ", str.wwrap$(s$, p%, 20))
  assert_string_equals("his toeses to be", str.wwrap$(s$, p%, 20))
End Sub

Sub test_wwrap_given_empty()
  Local p% = 1, s$ = ""
  assert_string_equals("", str.wwrap$(s$, p%, 1))
  assert_int_equals(1, p%)
  assert_string_equals("", str.wwrap$(s$, p%, 10))
  assert_int_equals(1, p%)
End Sub

Sub test_wwrap_given_just_spaces()
  Local p% = 1, s$ = "                "
  assert_string_equals("      ", str.wwrap$(s$, p%, 6))
  assert_int_equals(8, p%) ' One space is swallowed.
End Sub

Sub test_wwrap_given_space_at_len()
  Local p% = 1, s$ = "Moses Supposes"
  assert_string_equals("Moses ", str.wwrap$(s$, p%, 6))
  assert_int_equals(7, p%)
End Sub

Sub test_wwrap_given_cr_at_len()
  Local p% = 1, s$ = str.decode$("Moses\rSupposes")
  assert_string_equals("Moses", str.wwrap$(s$, p%, 6))
  assert_int_equals(7, p%)
End Sub

Sub test_wwrap_given_lf_at_len()
  Local p% = 1, s$ = str.decode$("Moses\nSupposes")
  assert_string_equals("Moses", str.wwrap$(s$, p%, 6))
  assert_int_equals(7, p%)
End Sub

Sub test_wwrap_given_crlf_at_len()
  Local p% = 1, s$ = str.decode$("Moses\r\nSupposes")
  assert_string_equals("Moses", str.wwrap$(s$, p%, 6))
  assert_int_equals(8, p%)
End Sub

Sub test_wwrap_given_space_at_lenp1()
  Local p% = 1, s$ = "Moses Supposes"
  assert_string_equals("Moses", str.wwrap$(s$, p%, 5))
  assert_int_equals(7, p%)
End Sub

Sub test_wwrap_given_cr_at_lenp1()
  Local p% = 1, s$ = str.decode$("Moses\rSupposes")
  assert_string_equals("Moses", str.wwrap$(s$, p%, 5))
  assert_int_equals(7, p%)
End Sub

Sub test_wwrap_given_lf_at_lenp1()
  Local p% = 1, s$ = str.decode$("Moses\nSupposes")
  assert_string_equals("Moses", str.wwrap$(s$, p%, 5))
  assert_int_equals(7, p%)
End Sub

Sub test_wwrap_given_crlf_at_lenp1()
  Local p% = 1, s$ = str.decode$("Moses\r\nSupposes")
  assert_string_equals("Moses", str.wwrap$(s$, p%, 5))
  assert_int_equals(8, p%)
End Sub

Sub test_wwrap_given_crlf_at_lenm1()
  Local p% = 1, s$ = str.decode$("Moses\r\nSupposes")
  assert_string_equals("Moses", str.wwrap$(s$, p%, 7))
  assert_int_equals(8, p%)
End Sub

Sub test_wwrap_given_word_too_long()
  Local p% = 1, s$ = "Moses supposes"
  assert_string_equals("Mos", str.wwrap$(s$, p%, 3))
  assert_int_equals(4, p%)

  p% = 6
  assert_string_equals(" su", str.wwrap$(s$, p%, 3))
  assert_int_equals(9, p%)
End Sub

Sub test_wwrap_given_space_at_start()
  Local p% = 1, s$ = str.decode$("  Moses Supposes")
  assert_string_equals("  Moses", str.wwrap$(s$, p%, 7))
  assert_int_equals(9, p%)
End Sub

Sub test_wwrap_given_cr_at_start()
  Local p% = 1, s$ = str.decode$("\rMoses Supposes")
  assert_string_equals("", str.wwrap$(s$, p%, 7))
  assert_int_equals(2, p%)
End Sub

Sub test_wwrap_given_lf_at_start()
  Local p% = 1, s$ = str.decode$("\nMoses Supposes")
  assert_string_equals("", str.wwrap$(s$, p%, 7))
  assert_int_equals(2, p%)
End Sub

Sub test_wwrap_given_crlf_at_start()
  Local p% = 1, s$ = str.decode$("\r\nMoses Supposes")
  assert_string_equals("", str.wwrap$(s$, p%, 7))
  assert_int_equals(3, p%)
End Sub

Sub test_wwrap_given_space_at_end()
  Local p% = 1, s$ = str.decode$("Moses supposes  ")
  assert_string_equals("Moses supposes  ", str.wwrap$(s$, p%, 30))
  assert_int_equals(17, p%)
End Sub

Sub test_wwrap_given_cr_at_end()
  Local p% = 1, s$ = str.decode$("Moses supposes\r")
  assert_string_equals("Moses supposes", str.wwrap$(s$, p%, 30))
  assert_int_equals(16, p%)
End Sub

Sub test_wwrap_given_lf_at_end()
  Local p% = 1, s$ = str.decode$("Moses supposes\n")
  assert_string_equals("Moses supposes", str.wwrap$(s$, p%, 30))
  assert_int_equals(16, p%)
End Sub

Sub test_wwrap_given_crlf_at_end()
  Local p% = 1, s$ = str.decode$("Moses supposes\r\n")
  assert_string_equals("Moses supposes", str.wwrap$(s$, p%, 30))
  assert_int_equals(17, p%)
End Sub

Sub test_wwrap_given_broken_spaces()
  Local p% = 1, s$ = str.decode$("Moses    supposes")
  assert_string_equals("Moses  ", str.wwrap$(s$, p%, 7))
  assert_int_equals(9, p%)
End Sub

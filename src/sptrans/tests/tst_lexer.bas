' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

Option Explicit On
Option Default Integer

#Include "../../splib/system.inc"
#Include "../../splib/array.inc"
#Include "../../splib/list.inc"
#Include "../../splib/string.inc"
#Include "../../splib/file.inc"
#Include "../../splib/map.inc"
#Include "../../splib/set.inc"
#Include "../../splib/vt100.inc"
#Include "../../sptest/unittest.inc"
#Include "../../common/sptools.inc"
#Include "../keywords.inc"
#Include "../lexer.inc"

keywords.init()

add_test("test_binary_literals")
add_test("test_comments")
add_test("test_directives")
add_test("test_directive_given_comments")
add_test("test_directive_given_not_first")
add_test("test_replace_directives")
add_test("test_hexadecimal_literals")
add_test("test_identifiers")
add_test("test_includes")
add_test("test_integer_literals")
add_test("test_integer_literals_with_e")
add_test("test_keywords")
add_test("test_octal_literals")
add_test("test_real_literals")
add_test("test_string_literals")
add_test("test_string_no_closing_quote")
add_test("test_symbols")
add_test("test_extended_symbols")
add_test("test_labels")
add_test("test_get_number")
add_test("test_get_string")
add_test("test_get_directive")
add_test("test_get_token_lc")
add_test("test_old_tokens_cleared")
add_test("test_parse_command_line")
add_test("test_csub")
add_test("test_define_font")
add_test("test_hash_bang")
add_test("test_insert_token")
add_test("test_remove_token")
add_test("test_replace_token")
add_test("test_set_space_before")
add_test("test_set_space_after")

run_tests()

End

Sub test_binary_literals()
  expect_parse_succeeds("&b1001001", 1, TK_NUMBER, "&b1001001")

  ' Because the lexer accepts BBC micro-style hex numbers this is
  ' not considered a syntax error, and nor does it result in two
  ' separate tokens "&B01" and "23456789".
  expect_parse_succeeds("&B0123456789", 1, TK_NUMBER, "&B0123456789")
End Sub

Sub test_comments()
  expect_parse_succeeds("' This is a comment", 1, TK_COMMENT, "' This is a comment")
  expect_parse_succeeds("REM This is also a comment", 1, TK_COMMENT, "REM This is also a comment");
End Sub

Sub test_directives()
  expect_parse_succeeds("'!comment_if foo", 2)
  expect_token(0, TK_DIRECTIVE, "'!comment_if")
  expect_token(1, TK_IDENTIFIER, "foo")

  expect_parse_succeeds("'!empty-lines off", 2)
  expect_token(0, TK_DIRECTIVE, "'!empty-lines")
  expect_token(1, TK_KEYWORD, "off")

  expect_parse_succeeds("'!ifdef foo", 2)
  expect_token(0, TK_DIRECTIVE, "'!ifdef")
  expect_token(1, TK_IDENTIFIER, "foo")

  expect_parse_succeeds("'!ifndef foo", 2)
  expect_token(0, TK_DIRECTIVE, "'!ifndef")
  expect_token(1, TK_IDENTIFIER, "foo")

  expect_parse_succeeds("'!elif", 1, TK_DIRECTIVE, "'!elif")

  expect_parse_succeeds("'!endif", 1, TK_DIRECTIVE, "'!endif")

  expect_parse_succeeds("'!info defined foo", 3)
  expect_token(0, TK_DIRECTIVE, "'!info")
  expect_token(1, TK_IDENTIFIER, "defined")
  expect_token(2, TK_IDENTIFIER, "foo")
End Sub

Sub test_directive_given_comments()
  expect_parse_succeeds("'!endif ' my comment", 2)
  expect_token(0, TK_DIRECTIVE, "'!endif")
  expect_token(1, TK_COMMENT, "' my comment")
End Sub

' A directive should only be recognised as such if it is the first token on a line
Sub test_directive_given_not_first()
  expect_parse_succeeds("PRINT '!ifdef FOO", 2)
  expect_token(0, TK_KEYWORD, "PRINT")
  expect_token(1, TK_COMMENT, "'!ifdef FOO")
End Sub

Sub test_replace_directives()
  expect_parse_succeeds("'!replace DEF Sub", 3)
  expect_token(0, TK_DIRECTIVE, "'!replace")
  expect_token(1, TK_KEYWORD,   "DEF")
  expect_token(2, TK_KEYWORD,   "Sub")

  expect_parse_succeeds("'!replace ENDPROC { End Sub }", 6)
  expect_token(0, TK_DIRECTIVE, "'!replace")
  expect_token(1, TK_KEYWORD,   "ENDPROC")
  expect_token(2, TK_SYMBOL,    "{")
  expect_token(3, TK_KEYWORD,   "End")
  expect_token(4, TK_KEYWORD,   "Sub")
  expect_token(5, TK_SYMBOL,    "}")

  expect_parse_succeeds("'!replace { THEN ENDPROC } { Then Exit Sub }", 10)
  expect_token(0, TK_DIRECTIVE, "'!replace")
  expect_token(1, TK_SYMBOL,    "{")
  expect_token(2, TK_KEYWORD,   "THEN")
  expect_token(3, TK_KEYWORD,   "ENDPROC")
  expect_token(4, TK_SYMBOL,    "}")
  expect_token(5, TK_SYMBOL,    "{")
  expect_token(6, TK_KEYWORD,   "Then")
  expect_token(7, TK_KEYWORD,   "Exit")
  expect_token(8, TK_KEYWORD,   "Sub")
  expect_token(9, TK_SYMBOL,    "}")

  expect_parse_succeeds("'!replace GOTO%d { Goto %1 }", 6)
  expect_token(0, TK_DIRECTIVE, "'!replace")
  expect_token(1, TK_KEYWORD,   "GOTO%d")
  expect_token(2, TK_SYMBOL,    "{")
  expect_token(3, TK_KEYWORD,   "Goto")
  expect_token(4, TK_KEYWORD,   "%1")
  expect_token(5, TK_SYMBOL,    "}")

  expect_parse_succeeds("'!replace { THEN %d } { Then Goto %1 }", 10)
  expect_token(0, TK_DIRECTIVE, "'!replace")
  expect_token(1, TK_SYMBOL,    "{")
  expect_token(2, TK_KEYWORD,   "THEN")
  expect_token(3, TK_KEYWORD,   "%d")
  expect_token(4, TK_SYMBOL,    "}")
  expect_token(5, TK_SYMBOL,    "{")
  expect_token(6, TK_KEYWORD,   "Then")
  expect_token(7, TK_KEYWORD,   "Goto")
  expect_token(8, TK_KEYWORD,   "%1")
  expect_token(9, TK_SYMBOL,    "}")

  ' Apostrophes inside directives are accepted as identifier characters.
  expect_parse_succeeds("'!replace '%% { CRLF %1 }", 6)
  expect_token(0, TK_DIRECTIVE, "'!replace")
  expect_token(1, TK_KEYWORD,   "'%%")
  expect_token(2, TK_SYMBOL,    "{")
  expect_token(3, TK_KEYWORD,   "CRLF")
  expect_token(4, TK_KEYWORD,   "%1")
  expect_token(5, TK_SYMBOL,    "}")

  ' REM commands inside directives are treated as keywords not as the prefix of a comment.
  expect_parse_succeeds("'!replace REM foo", 3)
  expect_token(0, TK_DIRECTIVE, "'!replace")
  expect_token(1, TK_KEYWORD,   "REM")
  expect_token(2, TK_KEYWORD,   "foo")
End Sub

Sub test_includes()
  expect_parse_succeeds("#Include " + str.quote$("foo.inc"), 2)
  expect_token(0, TK_KEYWORD, "#Include")
  expect_token(1, TK_STRING, str.quote$("foo.inc"))
End Sub

Sub test_hexadecimal_literals()
  expect_parse_succeeds("&hABCDEF", 1, TK_NUMBER, "&hABCDEF")

  expect_parse_succeeds("&Habcdefghijklmn", 2)
  expect_token(0, TK_NUMBER, "&Habcdef")
  expect_token(1, TK_IDENTIFIER, "ghijklmn")

  ' To facilitate transpiling BBC Basic source code the lexer accepts
  ' hex numbers which begin just & instead of &h.
  expect_parse_succeeds("&ABCDEF", 1, TK_NUMBER, "&ABCDEF")
End Sub

Sub test_identifiers()
  expect_parse_succeeds("xx s$ foo.bar wom.bat$ a! b%", 6)
  expect_token(0, TK_IDENTIFIER, "xx")
  expect_token(1, TK_IDENTIFIER, "s$")
  expect_token(2, TK_IDENTIFIER, "foo.bar")
  expect_token(3, TK_IDENTIFIER, "wom.bat$")
  expect_token(4, TK_IDENTIFIER, "a!")
  expect_token(5, TK_IDENTIFIER, "b%")
End Sub

Sub test_integer_literals()
  expect_parse_succeeds("421", 1, TK_NUMBER, "421")
End Sub

Sub test_integer_literals_with_e()
  ' If there is just a trailing E then it is part of the number literal.
  expect_parse_succeeds("12345E", 1, TK_NUMBER, "12345E")

  ' Otherwise it is the start of a separate identifier.
  expect_parse_succeeds("12345ENDPROC", 2)
  expect_token(0, TK_NUMBER,     "12345")
  expect_token(1, TK_IDENTIFIER, "ENDPROC")
End Sub

Sub test_keywords()
  expect_parse_succeeds("For Next Do Loop Chr$", 5)
  expect_token(0, TK_KEYWORD, "For")
  expect_token(1, TK_KEYWORD, "Next")
  expect_token(2, TK_KEYWORD, "Do")
  expect_token(3, TK_KEYWORD, "Loop")
  expect_token(4, TK_KEYWORD, "Chr$")

  expect_parse_succeeds("  #gps @ YELLOW  ", 3)
  expect_token(0, TK_KEYWORD, "#gps")
  expect_token(1, TK_KEYWORD, "@")
  expect_token(2, TK_KEYWORD, "YELLOW")
End Sub

Sub test_octal_literals()
  expect_parse_succeeds("&O1234", 1, TK_NUMBER, "&O1234")

  expect_parse_succeeds("&O123456789", 2)
  expect_token(0, TK_NUMBER, "&O1234567")
  expect_token(1, TK_NUMBER, "89")
End Sub

Sub test_real_literals()
  expect_parse_succeeds("3.421", 1, TK_NUMBER, "3.421")
  expect_parse_succeeds("3.421e5", 1, TK_NUMBER, "3.421e5")
  expect_parse_succeeds("3.421e-17", 1, TK_NUMBER, "3.421e-17")
  expect_parse_succeeds("3.421e+17", 1, TK_NUMBER, "3.421e+17")
  expect_parse_succeeds(".3421", 1, TK_NUMBER, ".3421")
End Sub

Sub test_string_literals()
  expect_parse_succeeds(str.quote$("This is a string"), 1, TK_STRING, str.quote$("This is a string"))
End Sub

Sub test_string_no_closing_quote()
  expect_parse_error(Chr$(34) + "String literal with no closing quote", "No closing quote")
End Sub

Sub test_symbols()
  expect_parse_succeeds("a=b/c*d\e<=f=<g>=h=>i:j;k,l<m>n", 27)
  expect_token(0, TK_IDENTIFIER, "a")
  expect_token(1, TK_SYMBOL, "=")
  expect_token(2, TK_IDENTIFIER, "b")
  expect_token(3, TK_SYMBOL, "/")
  expect_token(4, TK_IDENTIFIER, "c")
  expect_token(5, TK_SYMBOL, "*")
  expect_token(6, TK_IDENTIFIER, "d")
  expect_token(7, TK_SYMBOL, "\")
  expect_token(8, TK_IDENTIFIER, "e")
  expect_token(9, TK_SYMBOL, "<=")
  expect_token(10, TK_IDENTIFIER, "f")
  expect_token(11, TK_SYMBOL, "=<")
  expect_token(12, TK_IDENTIFIER, "g")
  expect_token(13, TK_SYMBOL, ">=")
  expect_token(14, TK_IDENTIFIER, "h")
  expect_token(15, TK_SYMBOL, "=>")
  expect_token(16, TK_IDENTIFIER, "i")
  expect_token(17, TK_SYMBOL, ":")
  expect_token(18, TK_IDENTIFIER, "j")
  expect_token(19, TK_SYMBOL, ";")
  expect_token(20, TK_IDENTIFIER, "k")
  expect_token(21, TK_SYMBOL, ",")
  expect_token(22, TK_IDENTIFIER, "l")
  expect_token(23, TK_SYMBOL, "<")
  expect_token(24, TK_IDENTIFIER, "m")
  expect_token(25, TK_SYMBOL, ">")
  expect_token(26, TK_IDENTIFIER, "n")

  expect_parse_succeeds("a$(i + 1)", 6)
  expect_token(0, TK_IDENTIFIER, "a$")
  expect_token(1, TK_SYMBOL, "(")
  expect_token(2, TK_IDENTIFIER, "i")
  expect_token(3, TK_SYMBOL, "+")
  expect_token(4, TK_NUMBER, "1")
  expect_token(5, TK_SYMBOL, ")")

  expect_parse_succeeds("xx=xx+1", 5)
  expect_token(0, TK_IDENTIFIER, "xx")
  expect_token(1, TK_SYMBOL, "=")
  expect_token(2, TK_IDENTIFIER, "xx")
  expect_token(3, TK_SYMBOL, "+")
  expect_token(4, TK_NUMBER, "1")
End Sub

Sub test_extended_symbols()
  expect_parse_succeeds("&& ||", 2)
  expect_token(0, TK_SYMBOL, "&&")
  expect_token(1, TK_SYMBOL, "||")
End Sub

Sub test_labels()
  expect_parse_succeeds("  label:", 1, TK_LABEL, "label:")

  expect_parse_succeeds("  label: not_a_label:", 3)
  expect_token(0, TK_LABEL,      "label:")
  expect_token(1, TK_IDENTIFIER, "not_a_label")
  expect_token(2, TK_SYMBOL,     ":")

  expect_parse_succeeds("  not_a_label : not_a_label:", 4)
  expect_token(0, TK_IDENTIFIER, "not_a_label")
  expect_token(1, TK_SYMBOL,     ":")
  expect_token(2, TK_IDENTIFIER, "not_a_label")
  expect_token(3, TK_SYMBOL,     ":")

  expect_parse_succeeds("  1234: ' label", 2)
  expect_token(0, TK_LABEL,   "1234:")
  expect_token(1, TK_COMMENT, "' label")

  expect_parse_succeeds("  1234 ' not a label", 2)
  expect_token(0, TK_NUMBER,  "1234")
  expect_token(1, TK_COMMENT, "' not a label")

  expect_parse_succeeds("  foo 1234: ' not a label", 4)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_NUMBER,     "1234")
  expect_token(2, TK_SYMBOL,     ":")
  expect_token(3, TK_COMMENT,    "' not a label")
End Sub

Sub test_get_number()
  expect_parse_succeeds("1 2 3.14 3.14e-15", 4)
  assert_float_equals(1, lx.number!(0))
  assert_float_equals(2, lx.number!(1))
  assert_float_equals(3.14, lx.number!(2))
  assert_float_equals(3.14e-15, lx.number!(3))
End Sub

Sub test_get_string()
  expect_parse_succeeds(str.quote$("foo") + " " + str.quote$("wom bat"), 2)
  assert_string_equals("foo", lx.string$(0))
  assert_string_equals("wom bat", lx.string$(1))
End Sub

Sub test_get_directive()
  expect_parse_succeeds("'!foo", 1)
  assert_string_equals("!foo", lx.directive$(0))
End Sub

Sub test_get_token_lc()
  expect_parse_succeeds("FOO '!BAR 1E7", 2)
  assert_string_equals("foo", lx.token_lc$(0))
  assert_string_equals("'!bar 1e7", lx.token_lc$(1))
End Sub

Sub test_parse_command_line()
  ' assert_int_equals(sys.SUCCESS, lx.parse_command_line%("--foo -bar /wombat"))
  assert_int_equals(sys.SUCCESS, lx.parse_command_line%("--foo -bar"))
  assert_string_equals("--foo", lx.token_lc$(0))
  assert_string_equals("foo", lx.option$(0))
  assert_string_equals("-bar", lx.token_lc$(1))
  assert_string_equals("bar", lx.option$(1))
  ' assert_string_equals("/wombat", lx.token_lc$(2))
  ' assert_string_equals("wombat", lx.option$(2))

  assert_int_equals(sys.FAILURE, lx.parse_command_line%("--"))
  assert_error("Illegal command-line option format: --")

  assert_int_equals(sys.FAILURE, lx.parse_command_line%("-"))
  assert_error("Illegal command-line option format: -")

  ' assert_int_equals(sys.FAILURE, lx.parse_command_line%("/"))
  ' assert_error("Illegal command-line option format: /")

  assert_int_equals(sys.FAILURE, lx.parse_command_line%("--foo@ bar"))
  assert_error("Illegal command-line option format: --foo@")

  ' Given hyphen in unquoted argument.
  assert_int_equals(sys.SUCCESS, lx.parse_command_line%("foo-bar.bas"))
  assert_string_equals("foo-bar.bas", lx.token$(0))
  assert_int_equals(TK_IDENTIFIER, lx.type(0))

  ' Given forward slash in unquoted argument.
  assert_int_equals(sys.SUCCESS, lx.parse_command_line%("foo/bar.bas"))
  assert_string_equals("foo/bar.bas", lx.token$(0))
  assert_int_equals(TK_IDENTIFIER, lx.type(0))
End Sub

Sub test_old_tokens_cleared()
  expect_parse_succeeds("Dim s$(20) Length 20", 7)

  expect_parse_succeeds("' comment", 1)
  Local i
  For i = 1 To 10
    assert_int_equals(0, lx.type(i))
    assert_int_equals(0, lx.start(i))
    assert_int_equals(0, lx.len(i))
  Next i
End Sub

Sub test_csub()
  ' Within the confines of the CSUB we expect numbers to be treated as identifiers.
  expect_parse_succeeds("CSub foo() 00000000 00AABBCC 0.7 &hFF &b0101 &o1234 FFFFFFFF End CSub", 13)
  expect_token(0, TK_KEYWORD,    "CSub")
  expect_token(1, TK_IDENTIFIER, "foo")
  expect_token(2, TK_SYMBOL,     "(")
  expect_token(3, TK_SYMBOL,     ")")
  expect_token(4, TK_IDENTIFIER, "00000000")
  expect_token(5, TK_IDENTIFIER, "00AABBCC")
  expect_token(6, TK_IDENTIFIER, "0.7")
  expect_token(7, TK_IDENTIFIER, "&hFF")
  expect_token(8, TK_IDENTIFIER, "&b0101")
  expect_token(9, TK_IDENTIFIER, "&o1234")
  expect_token(10, TK_IDENTIFIER, "FFFFFFFF")
  expect_token(11, TK_KEYWORD,    "End")
  expect_token(12, TK_KEYWORD,    "CSub")

  ' But once we get outside the CSUB numbers and identifiers are distinct again.
  expect_parse_succeeds("0.12345 00AABBCC", 3)
  expect_token(0, TK_NUMBER,     "0.12345")
  expect_token(1, TK_NUMBER,     "00")
  expect_token(2, TK_IDENTIFIER, "AABBCC")

  ' It should also work when the CSUB is split over multiple lines.
  expect_parse_succeeds("CSub foo() ' comment", 5)
  expect_token(0, TK_KEYWORD,    "CSub")
  expect_token(1, TK_IDENTIFIER, "foo")
  expect_token(2, TK_SYMBOL,     "(")
  expect_token(3, TK_SYMBOL,     ")")
  expect_token(4, TK_COMMENT,    "' comment")

  expect_parse_succeeds("  00000000", 1, TK_IDENTIFIER, "00000000")

  expect_parse_succeeds("  00AABBCC 0.7 &hFF &b0101 &o1234 FFFFFFFF", 6)
  expect_token(0, TK_IDENTIFIER, "00AABBCC")
  expect_token(1, TK_IDENTIFIER, "0.7")
  expect_token(2, TK_IDENTIFIER, "&hFF")
  expect_token(3, TK_IDENTIFIER, "&b0101")
  expect_token(4, TK_IDENTIFIER, "&o1234")
  expect_token(5, TK_IDENTIFIER, "FFFFFFFF")

  expect_parse_succeeds("End CSub", 2)
  expect_token(0, TK_KEYWORD, "End")
  expect_token(1, TK_KEYWORD, "CSub")

  expect_parse_succeeds("0.12345 00AABBCC", 3)
  expect_token(0, TK_NUMBER,     "0.12345")
  expect_token(1, TK_NUMBER,     "00")
  expect_token(2, TK_IDENTIFIER, "AABBCC")
End Sub

Sub test_define_font()
  ' Within the confines of the DEFINEFONT we expect numbers to be treated as identifiers.
  expect_parse_succeeds("DefineFont 9 00000000 00AABBCC 0.7 &hFF &b0101 &o1234 FFFFFFFF End DefineFont", 11))
  expect_token(0, TK_KEYWORD,    "DefineFont")
  expect_token(1, TK_IDENTIFIER, "9")
  expect_token(2, TK_IDENTIFIER, "00000000")
  expect_token(3, TK_IDENTIFIER, "00AABBCC")
  expect_token(4, TK_IDENTIFIER, "0.7")
  expect_token(5, TK_IDENTIFIER, "&hFF")
  expect_token(6, TK_IDENTIFIER, "&b0101")
  expect_token(7, TK_IDENTIFIER, "&o1234")
  expect_token(8, TK_IDENTIFIER, "FFFFFFFF")
  expect_token(9, TK_KEYWORD,    "End")
  expect_token(10, TK_KEYWORD,    "DefineFont")

  ' But once we get outside the DEFINEFONT numbers and identifiers are distinct again.
  expect_parse_succeeds("0.12345 00AABBCC", 3)
  expect_token(0, TK_NUMBER,     "0.12345")
  expect_token(1, TK_NUMBER,     "00")
  expect_token(2, TK_IDENTIFIER, "AABBCC")

  ' It should also work when the DEFINEFONT is split over multiple lines.
  expect_parse_succeeds("DefineFont 9 ' comment", 3)
  expect_token(0, TK_KEYWORD,    "DefineFont")
  expect_token(1, TK_IDENTIFIER, "9")
  expect_token(2, TK_COMMENT,    "' comment")

  expect_parse_succeeds("  00000000", 1, TK_IDENTIFIER, "00000000")

  expect_parse_succeeds("  00AABBCC 0.7 &hFF &b0101 &o1234 FFFFFFFF", 6)
  expect_token(0, TK_IDENTIFIER, "00AABBCC")
  expect_token(1, TK_IDENTIFIER, "0.7")
  expect_token(2, TK_IDENTIFIER, "&hFF")
  expect_token(3, TK_IDENTIFIER, "&b0101")
  expect_token(4, TK_IDENTIFIER, "&o1234")
  expect_token(5, TK_IDENTIFIER, "FFFFFFFF")

  expect_parse_succeeds("End DefineFont", 2)
  expect_token(0, TK_KEYWORD, "End")
  expect_token(1, TK_KEYWORD, "DefineFont")

  expect_parse_succeeds("0.12345 00AABBCC", 3)
  expect_token(0, TK_NUMBER,     "0.12345")
  expect_token(1, TK_NUMBER,     "00")
  expect_token(2, TK_IDENTIFIER, "AABBCC")
End Sub

Sub test_hash_bang()
  expect_parse_succeeds("#!/foo/bar", 1, TK_COMMENT, "#!/foo/bar")
End Sub

Sub test_insert_token()
  ' Test insertion into an empty line.
  expect_parse_succeeds("", 0)
  lx.insert_token(0, "foo", TK_IDENTIFIER)
  assert_string_equals("foo", lx.line$)
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "foo", 1)

  ' Test insertion into a line only containing whitespace.
  expect_parse_succeeds("  ", 0)
  lx.insert_token(0, "foo", TK_IDENTIFIER)
  assert_string_equals("  foo", lx.line$)
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "foo", 3)

  ' Test insertion before the first token.
  expect_parse_succeeds("  foo", 1)
  lx.insert_token(0, "bar", TK_IDENTIFIER)
  assert_string_equals("  bar foo", lx.line$)
  expect_token_count(2)
  expect_token(0, TK_IDENTIFIER, "bar", 3)
  expect_token(1, TK_IDENTIFIER, "foo", 7)

  ' Test insertion after the last token.
  expect_parse_succeeds("  foo", 1)
  lx.insert_token(1, "bar", TK_IDENTIFIER)
  assert_string_equals("  foo bar", lx.line$)
  expect_token_count(2)
  expect_token(0, TK_IDENTIFIER, "foo", 3)
  expect_token(1, TK_IDENTIFIER, "bar", 7)

  ' Test insertion between two tokens.
  expect_parse_succeeds("  foo  bar", 2)
  lx.insert_token(1, "wombat", TK_IDENTIFIER)
  assert_string_equals("  foo wombat  bar", lx.line$)
  expect_token_count(3)
  expect_token(0, TK_IDENTIFIER, "foo", 3)
  expect_token(1, TK_IDENTIFIER, "wombat", 7)
  expect_token(2, TK_IDENTIFIER, "bar", 15)
End Sub

Sub test_remove_token()
  ' Test removing the first (index = 0) token.
  expect_parse_succeeds("  token1 token2  token3", 3)
  lx.remove_token(0)
  assert_string_equals("  token2  token3", lx.line$)
  expect_token_count(2)
  expect_token(0, TK_IDENTIFIER, "token2", 3)
  expect_token(1, TK_IDENTIFIER, "token3", 11)

  ' Test removing the last token.
  expect_parse_succeeds("  token1 token2  token3", 3)
  lx.remove_token(2)
  assert_string_equals("  token1 token2", lx.line$)
  expect_token_count(2)
  expect_token(0, TK_IDENTIFIER, "token1", 3)
  expect_token(1, TK_IDENTIFIER, "token2", 10)

  ' Test removing an intermediate token.
  expect_parse_succeeds("  token1 token2  token3", 3)
  lx.remove_token(1)
  assert_string_equals("  token1  token3", lx.line$)
  expect_token_count(2)
  expect_token(0, TK_IDENTIFIER, "token1", 3)
  expect_token(1, TK_IDENTIFIER, "token3", 11)

  ' Test removing the only token.
  expect_parse_succeeds("  token1  ", 1)
  lx.remove_token(0)
  assert_string_equals("  ", lx.line$)
  expect_token_count(0)

  ' Test something more interesting.
  expect_parse_succeeds("let y(3) = (" + str.quote$("foo") + ", " + str.quote$("bar") + ")", 11)
  lx.remove_token(2)
  lx.remove_token(2)
  lx.remove_token(2)
  assert_string_equals("let y = (" + str.quote$("foo") + ", " + str.quote$("bar") + ")", lx.line$)
  expect_token_count(8)
  expect_token(0, TK_KEYWORD, "let", 1)
  expect_token(1, TK_IDENTIFIER, "y", 5)
  expect_token(2, TK_SYMBOL, "=", 7)
  expect_token(3, TK_SYMBOL, "(", 9)
  expect_token(4, TK_STRING, str.quote$("foo"), 10)
  expect_token(5, TK_SYMBOL, ",", 15)
  expect_token(6, TK_STRING, str.quote$("bar"), 17)
  expect_token(7, TK_SYMBOL, ")", 22)
End Sub

Sub test_replace_token()
  ' Test replacing the first (index = 0) token.
  expect_parse_succeeds(" one  two   three", 3)
  lx.replace_token(0, "wombat", TK_KEYWORD)
  assert_string_equals(" wombat  two   three", lx.line$)
  expect_token_count(3)
  expect_token(0, TK_KEYWORD, "wombat", 2)
  expect_token(1, TK_IDENTIFIER, "two", 10)
  expect_token(2, TK_IDENTIFIER, "three", 16)

  ' Test replacing an intermediate token.
  expect_parse_succeeds(" one  two   three", 3)
  lx.replace_token(1, "wombat", TK_KEYWORD)
  assert_string_equals(" one  wombat   three", lx.line$)
  expect_token_count(3)
  expect_token(0, TK_IDENTIFIER, "one", 2)
  expect_token(1, TK_KEYWORD, "wombat", 7)
  expect_token(2, TK_IDENTIFIER, "three", 16)

  ' Test replacing the last token.
  expect_parse_succeeds(" one  two   three", 3)
  lx.replace_token(2, "wombat", TK_KEYWORD)
  assert_string_equals(" one  two   wombat", lx.line$)
  expect_token_count(3)
  expect_token(0, TK_IDENTIFIER, "one", 2)
  expect_token(1, TK_IDENTIFIER, "two", 7)
  expect_token(2, TK_KEYWORD, "wombat", 13)

  ' Test replacing the only token.
  expect_parse_succeeds("  token1  ", 1)
  lx.replace_token(0, "wombat", TK_KEYWORD)
  assert_string_equals("  wombat  ", lx.line$)
  expect_token_count(1)
  expect_token(0, TK_KEYWORD, "wombat", 3)
End Sub

Sub test_set_space_before()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("Print 200"))

  assert_int_equals(sys.SUCCESS, lx.set_space_before%(0, 4))
  assert_string_equals("    Print 200", lx.line$)
  assert_int_equals(2, lx.num)
  expect_token(0, TK_KEYWORD, "Print", 5)
  expect_token(1, TK_NUMBER, "200", 11)

  assert_int_equals(sys.SUCCESS, lx.set_space_before%(1, 4))
  assert_string_equals("    Print    200", lx.line$)
  assert_int_equals(2, lx.num)
  expect_token(0, TK_KEYWORD, "Print", 5)
  expect_token(1, TK_NUMBER, "200", 14)

  assert_int_equals(sys.SUCCESS, lx.set_space_before%(0, 1))
  assert_string_equals(" Print    200", lx.line$)
  assert_int_equals(2, lx.num)
  expect_token(0, TK_KEYWORD, "Print", 2)
  expect_token(1, TK_NUMBER, "200", 11)

  assert_int_equals(sys.SUCCESS, lx.set_space_before%(1, 0))
  assert_string_equals(" Print200", lx.line$)
  assert_int_equals(2, lx.num)
  expect_token(0, TK_KEYWORD, "Print", 2)
  expect_token(1, TK_NUMBER, "200", 7)

  assert_int_equals(sys.FAILURE, lx.set_space_before%(-1, 1))
  assert_error("Invalid token index: -1")

  assert_int_equals(sys.FAILURE, lx.set_space_before%(2, 1))
  assert_error("Invalid token index: 2")

  assert_int_equals(sys.FAILURE, lx.set_space_before%(0, -2))
  assert_error("Invalid number of spaces: -2")
End Sub

Sub test_set_space_after()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("Print 200"))

  assert_int_equals(sys.SUCCESS, lx.set_space_after%(0, 4))
  assert_string_equals("Print    200", lx.line$)
  assert_int_equals(2, lx.num)
  expect_token(0, TK_KEYWORD, "Print", 1)
  expect_token(1, TK_NUMBER, "200", 10)

  assert_int_equals(sys.SUCCESS, lx.set_space_after%(1, 4))
  assert_string_equals("Print    200    ", lx.line$)
  assert_int_equals(2, lx.num)
  expect_token(0, TK_KEYWORD, "Print", 1)
  expect_token(1, TK_NUMBER, "200", 10)

  assert_int_equals(sys.SUCCESS, lx.set_space_after%(0, 0))
  assert_string_equals("Print200    ", lx.line$)
  assert_int_equals(2, lx.num)
  expect_token(0, TK_KEYWORD, "Print", 1)
  expect_token(1, TK_NUMBER, "200", 6)

  assert_int_equals(sys.SUCCESS, lx.set_space_after%(1, 0))
  assert_string_equals("Print200", lx.line$)
  assert_int_equals(2, lx.num)
  expect_token(0, TK_KEYWORD, "Print", 1)
  expect_token(1, TK_NUMBER, "200", 6)

  assert_int_equals(sys.FAILURE, lx.set_space_after%(-1, 1))
  assert_error("Invalid token index: -1")

  assert_int_equals(sys.FAILURE, lx.set_space_after%(2, 1))
  assert_error("Invalid token index: 2")

  assert_int_equals(sys.FAILURE, lx.set_space_after%(0, -2))
  assert_error("Invalid number of spaces: -2")
End Sub

Sub expect_parse_succeeds(line$, expected_count%, type0%, txt0$)
  If lx.parse_basic%(line$) = sys.SUCCESS Then
    If lx.num = expected_count% Then
      If (lx.num > 0) And (type0% > 0) Then expect_token(0, type0%, txt0$)
    Else
      assert_fail("Expected " + Str$(expected_count%) + " tokens, found " + Str$(lx.num))
    EndIf
  Else
    assert_fail("Parse failed: " + line$)
  EndIf
  assert_no_error()
End Sub

Sub expect_token_count(num)
  assert_true(lx.num = num, "Expected " + Str$(num) + " tokens, found " + Str$(lx.num))
  assert_no_error()
End Sub

Sub expect_token(i%, type%, txt$, start%)
  Local ok% = (lx.type(i) = type%)
  ok% = ok% And (lx.token$(i) = txt$)
  ok% = ok% And (lx.len(i%) = Len(txt$))
  If start% Then ok% = ok% And (lx.start%(i%) = start%)
  If Not ok% Then
    Local msg$ = "expected " + token_to_string$(type%, txt$, Len(txt$), start%)
    Cat msg$, ", found " + token_to_string$(lx.type(i), lx.token$(i), lx.len(i), lx.start(i))
    assert_fail(msg$)
  EndIf
End Sub

Function token_to_string$(type%, txt$, len%, start%)
  Local s$
  Cat s$, Str$(type%)
  Cat s$, ", " + txt$
  Cat s$, ", " + Str$(len%)
  If start% Then Cat s$, ", " + Str$(start%)
  token_to_string$ = "{ " + s$ + " }"
End Function

Sub expect_parse_error(line$, msg$)
  Local result% = lx.parse_basic%(line$)
  If result% = sys.FAILURE Then
    assert_error(msg$)
  Else
    assert_fail("Parser did not return ERROR, result = " + Str$(result%) + " : " + line$)
  EndIf
End Sub

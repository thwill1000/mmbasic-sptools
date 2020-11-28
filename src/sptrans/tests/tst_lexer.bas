' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

#Include "../../common/system.inc"
#Include "../../common/array.inc"
#Include "../../common/list.inc"
#Include "../../common/string.inc"
#Include "../../common/file.inc"
#Include "../../common/set.inc"
#Include "../../common/vt100.inc"
#Include "../../sptest/unittest.inc"
#Include "../lexer.inc"

lx.load_keywords("\sptools\resources\keywords.txt")

add_test("test_binary_literals")
add_test("test_comments")
add_test("test_directives")
add_test("test_hexadecimal_literals")
add_test("test_identifiers")
add_test("test_includes")
add_test("test_integer_literals")
add_test("test_keywords")
add_test("test_octal_literals")
add_test("test_real_literals")
add_test("test_string_literals")
add_test("test_string_no_closing_quote")
add_test("test_symbols")
add_test("test_get_number")
add_test("test_get_string")
add_test("test_get_directive")
add_test("test_get_token_lc")
add_test("test_old_tokens_cleared")
add_test("test_parse_command_line")

run_tests()

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Sub test_binary_literals()
  lx.parse_basic("&b1001001")

  expect_success(1)
  expect_tk(0, TK_NUMBER, "&b1001001")

  lx.parse_basic("&B0123456789")

  expect_success(2)
  expect_tk(0, TK_NUMBER, "&B01")
  expect_tk(1, TK_NUMBER, "23456789")
End Sub

Sub test_comments()
  lx.parse_basic("' This is a comment")

  expect_success(1)
  expect_tk(0, TK_COMMENT, "' This is a comment");
End Sub

Sub test_directives()
  lx.parse_basic("'!comment_if foo")

  expect_success(2)
  expect_tk(0, TK_DIRECTIVE, "'!comment_if")
  expect_tk(1, TK_IDENTIFIER, "foo")

  lx.parse_basic("'!empty-lines off")
  expect_success(2)
  expect_tk(0, TK_DIRECTIVE, "'!empty-lines")
  expect_tk(1, TK_KEYWORD, "off")
End Sub

Sub test_includes()
  lx.parse_basic("#Include " + Chr$(34) + "foo.inc" + Chr$(34))

  expect_success(2)
  expect_tk(0, TK_KEYWORD, "#Include")
  expect_tk(1, TK_STRING, Chr$(34) + "foo.inc" + Chr$(34))
End Sub

Sub test_hexadecimal_literals()
  lx.parse_basic("&hABCDEF")

  expect_success(1)
  expect_tk(0, TK_NUMBER, "&hABCDEF")

  lx.parse_basic("&Habcdefghijklmn")

  expect_success(2)
  expect_tk(0, TK_NUMBER, "&Habcdef")
  expect_tk(1, TK_IDENTIFIER, "ghijklmn")
End Sub

Sub test_identifiers()
  lx.parse_basic("xx s$ foo.bar wom.bat$ a! b%")

  expect_success(6)
  expect_tk(0, TK_IDENTIFIER, "xx")
  expect_tk(1, TK_IDENTIFIER, "s$")
  expect_tk(2, TK_IDENTIFIER, "foo.bar")
  expect_tk(3, TK_IDENTIFIER, "wom.bat$")
  expect_tk(4, TK_IDENTIFIER, "a!")
  expect_tk(5, TK_IDENTIFIER, "b%")
End Sub

Sub test_integer_literals()
  lx.parse_basic("421")

  expect_success(1)
  expect_tk(0, TK_NUMBER, "421")
End Sub

Sub test_keywords()
  lx.parse_basic("For Next Do Loop Chr$")

  expect_success(5)
  expect_tk(0, TK_KEYWORD, "For")
  expect_tk(1, TK_KEYWORD, "Next")
  expect_tk(2, TK_KEYWORD, "Do")
  expect_tk(3, TK_KEYWORD, "Loop")
  expect_tk(4, TK_KEYWORD, "Chr$")

  lx.parse_basic("  #gps @ YELLOW  ")
  expect_success(3)
  expect_tk(0, TK_KEYWORD, "#gps")
  expect_tk(1, TK_KEYWORD, "@")
  expect_tk(2, TK_KEYWORD, "YELLOW")
End Sub

Sub test_octal_literals()
  lx.parse_basic("&O1234")

  expect_success(1)
  expect_tk(0, TK_NUMBER, "&O1234")

  lx.parse_basic("&O123456789")

  expect_success(2)
  expect_tk(0, TK_NUMBER, "&O1234567")
  expect_tk(1, TK_NUMBER, "89")
End Sub

Sub test_real_literals()
  lx.parse_basic("3.421")

  expect_success(1)
  expect_tk(0, TK_NUMBER, "3.421")

  lx.parse_basic("3.421e5")

  expect_success(1)
  expect_tk(0, TK_NUMBER, "3.421e5")

  lx.parse_basic("3.421e-17")

  expect_success(1)
  expect_tk(0, TK_NUMBER, "3.421e-17")

  lx.parse_basic("3.421e+17")

  expect_success(1)
  expect_tk(0, TK_NUMBER, "3.421e+17")

  lx.parse_basic(".3421")

  expect_success(1)
  expect_tk(0, TK_NUMBER, ".3421")
End Sub

Sub test_string_literals()
  lx.parse_basic(Chr$(34) + "This is a string" + Chr$(34))

  expect_success(1)
  expect_tk(0, TK_STRING, Chr$(34) + "This is a string" + Chr$(34))
End Sub

Sub test_string_no_closing_quote()
  lx.parse_basic(Chr$(34) + "String literal with no closing quote")

  assert_error("No closing quote")
End Sub

Sub test_symbols()
  lx.parse_basic("a=b/c*d\e<=f=<g>=h=>i:j;k,l<m>n")

  expect_success(27)
  expect_tk(0, TK_IDENTIFIER, "a")
  expect_tk(1, TK_SYMBOL, "=")
  expect_tk(2, TK_IDENTIFIER, "b")
  expect_tk(3, TK_SYMBOL, "/")
  expect_tk(4, TK_IDENTIFIER, "c")
  expect_tk(5, TK_SYMBOL, "*")
  expect_tk(6, TK_IDENTIFIER, "d")
  expect_tk(7, TK_SYMBOL, "\")
  expect_tk(8, TK_IDENTIFIER, "e")
  expect_tk(9, TK_SYMBOL, "<=")
  expect_tk(10, TK_IDENTIFIER, "f")
  expect_tk(11, TK_SYMBOL, "=<")
  expect_tk(12, TK_IDENTIFIER, "g")
  expect_tk(13, TK_SYMBOL, ">=")
  expect_tk(14, TK_IDENTIFIER, "h")
  expect_tk(15, TK_SYMBOL, "=>")
  expect_tk(16, TK_IDENTIFIER, "i")
  expect_tk(17, TK_SYMBOL, ":")
  expect_tk(18, TK_IDENTIFIER, "j")
  expect_tk(19, TK_SYMBOL, ";")
  expect_tk(20, TK_IDENTIFIER, "k")
  expect_tk(21, TK_SYMBOL, ",")
  expect_tk(22, TK_IDENTIFIER, "l")
  expect_tk(23, TK_SYMBOL, "<")
  expect_tk(24, TK_IDENTIFIER, "m")
  expect_tk(25, TK_SYMBOL, ">")
  expect_tk(26, TK_IDENTIFIER, "n")

  lx.parse_basic("a$(i + 1)")
  expect_success(6)
  expect_tk(0, TK_IDENTIFIER, "a$")
  expect_tk(1, TK_SYMBOL, "(")
  expect_tk(2, TK_IDENTIFIER, "i")
  expect_tk(3, TK_SYMBOL, "+")
  expect_tk(4, TK_NUMBER, "1")
  expect_tk(5, TK_SYMBOL, ")")

  lx.parse_basic("xx=xx+1")
  expect_success(5)
  expect_tk(0, TK_IDENTIFIER, "xx")
  expect_tk(1, TK_SYMBOL, "=")
  expect_tk(2, TK_IDENTIFIER, "xx")
  expect_tk(3, TK_SYMBOL, "+")
  expect_tk(4, TK_NUMBER, "1")

End Sub

Sub test_get_number()
  lx.parse_basic("1 2 3.14 3.14e-15")
  assert_float_equals(1, lx.number(0))
  assert_float_equals(2, lx.number(1))
  assert_float_equals(3.14, lx.number(2))
  assert_float_equals(3.14e-15, lx.number(3))
End Sub

Sub test_get_string()
  lx.parse_basic(Chr$(34) + "foo" + Chr$(34) + " " + Chr$(34) + "wom bat" + Chr$(34))
  assert_string_equals("foo", lx.string$(0))
  assert_string_equals("wom bat", lx.string$(1))
End Sub

Sub test_get_directive()
  lx.parse_basic("'!foo '!bar '!wombat")
  assert_string_equals("!foo", lx.directive$(0))
  assert_string_equals("!bar", lx.directive$(1))
  assert_string_equals("!wombat", lx.directive$(2))
End Sub

Sub test_get_token_lc()
  lx.parse_basic("FOO '!BAR 1E7")
  assert_string_equals("foo", lx.token_lc$(0))
  assert_string_equals("'!bar", lx.token_lc$(1))
  assert_string_equals("1e7", lx.token_lc$(2))
End Sub

Sub test_parse_command_line()
  lx.parse_command_line("--foo -bar /wombat")
  assert_string_equals("--foo", lx.token_lc$(0))
  assert_string_equals("foo", lx.option$(0))
  assert_string_equals("-bar", lx.token_lc$(1))
  assert_string_equals("bar", lx.option$(1))
  assert_string_equals("/wombat", lx.token_lc$(2))
  assert_string_equals("wombat", lx.option$(2))

  lx.parse_command_line("--")
  assert_error("Illegal command-line option format: --")

  lx.parse_command_line("-")
  assert_error("Illegal command-line option format: -")

  lx.parse_command_line("/")
  assert_error("Illegal command-line option format: /")

  lx.parse_command_line("--foo@ bar")
  assert_error("Illegal command-line option format: --foo@")
End Sub

Sub test_old_tokens_cleared()
  Local i

  lx.parse_basic("Dim s$(20) Length 20")
  assert_equals(7, lx.num)

  lx.parse_basic("' comment")
  assert_equals(1, lx.num)
  For i = 1 To 10
    assert_equals(0, lx.type(i))
    assert_equals(0, lx.start(i))
    assert_equals(0, lx.len(i))
  Next i
End Sub

Sub expect_success(num)
  assert_no_error()
  assert_true(lx.num = num, "expected " + Str$(num) + " tokens, found " + Str$(lx.num))
End Sub

Sub expect_tk(i, type, s$)
  assert_true(lx.type(i) = type, "expected type " + Str$(type) + ", found " + Str$(lx.type(i)))
  Local actual$ = lx.token$(i)
  assert_true(actual$ = s$, "excepted " + s$ + ", found " + actual$)
End Sub

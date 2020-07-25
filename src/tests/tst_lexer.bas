' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

#Include "unittest.inc"
#Include "../lexer.inc"
#Include "../set.inc"

Cls

lx_load_keywords("\mbt\resources\keywords.txt")

add_test("test_tokenise")
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
add_test("test_parse_command_line")

run_tests()

End

Function test_tokenise()
  lx_tokenise("  foo    bar/wom " + Chr$(34) + "bat" + Chr$(34) + "   ")

  expect_success(3)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_IDENTIFIER, "bar/wom")
  expect_tk(2, TK_IDENTIFIER, Chr$(34) + "bat" + Chr$(34))
End Function

Function test_binary_literals()
  lx_parse_basic("&b1001001")

  expect_success(1)
  expect_tk(0, TK_NUMBER, "&b1001001")

  lx_parse_basic("&B0123456789")

  expect_success(2)
  expect_tk(0, TK_NUMBER, "&B01")
  expect_tk(1, TK_NUMBER, "23456789")
End Function

Function test_comments()
  lx_parse_basic("' This is a comment")

  expect_success(1)
  expect_tk(0, TK_COMMENT, "' This is a comment");
End Function

Function test_directives()
  lx_parse_basic("'!comment_if foo")

  expect_success(2)
  expect_tk(0, TK_DIRECTIVE, "'!comment_if")
  expect_tk(1, TK_IDENTIFIER, "foo")

  lx_parse_basic("'!empty-lines off")
  expect_success(2)
  expect_tk(0, TK_DIRECTIVE, "'!empty-lines")
  expect_tk(1, TK_KEYWORD, "off")
End Function

Function test_includes()
  lx_parse_basic("#Include " + Chr$(34) + "foo.inc" + Chr$(34))

  expect_success(2)
  expect_tk(0, TK_KEYWORD, "#Include")
  expect_tk(1, TK_STRING, Chr$(34) + "foo.inc" + Chr$(34))
End Function

Function test_hexadecimal_literals()
  lx_parse_basic("&hABCDEF")

  expect_success(1)
  expect_tk(0, TK_NUMBER, "&hABCDEF")

  lx_parse_basic("&Habcdefghijklmn")

  expect_success(2)
  expect_tk(0, TK_NUMBER, "&Habcdef")
  expect_tk(1, TK_IDENTIFIER, "ghijklmn")
End Function

Function test_identifiers()
  lx_parse_basic("xx s$ foo.bar wom.bat$")

  expect_success(4)
  expect_tk(0, TK_IDENTIFIER, "xx")
  expect_tk(1, TK_IDENTIFIER, "s$")
  expect_tk(2, TK_IDENTIFIER, "foo.bar")
  expect_tk(3, TK_IDENTIFIER, "wom.bat$")
End Function

Function test_integer_literals()
  lx_parse_basic("421")

  expect_success(1)
  expect_tk(0, TK_NUMBER, "421")
End Function

Function test_keywords()
  lx_parse_basic("For Next Do Loop Chr$")

  expect_success(5)
  expect_tk(0, TK_KEYWORD, "For")
  expect_tk(1, TK_KEYWORD, "Next")
  expect_tk(2, TK_KEYWORD, "Do")
  expect_tk(3, TK_KEYWORD, "Loop")
  expect_tk(4, TK_KEYWORD, "Chr$")

  lx_parse_basic("  #gps @ YELLOW  ")
  expect_success(3)
  expect_tk(0, TK_KEYWORD, "#gps")
  expect_tk(1, TK_KEYWORD, "@")
  expect_tk(2, TK_KEYWORD, "YELLOW")
End Function

Function test_octal_literals()
  lx_parse_basic("&O1234")

  expect_success(1)
  expect_tk(0, TK_NUMBER, "&O1234")

  lx_parse_basic("&O123456789")

  expect_success(2)
  expect_tk(0, TK_NUMBER, "&O1234567")
  expect_tk(1, TK_NUMBER, "89")
End Function

Function test_real_literals()
  lx_parse_basic("3.421")

  expect_success(1)
  expect_tk(0, TK_NUMBER, "3.421")

  lx_parse_basic("3.421e5")

  expect_success(1)
  expect_tk(0, TK_NUMBER, "3.421e5")

  lx_parse_basic("3.421e-17")

  expect_success(1)
  expect_tk(0, TK_NUMBER, "3.421e-17")

  lx_parse_basic("3.421e+17")

  expect_success(1)
  expect_tk(0, TK_NUMBER, "3.421e+17")

  lx_parse_basic(".3421")

  expect_success(1)
  expect_tk(0, TK_NUMBER, ".3421")
End Function

Function test_string_literals()
  lx_parse_basic(Chr$(34) + "This is a string" + Chr$(34))

  expect_success(1)
  expect_tk(0, TK_STRING, Chr$(34) + "This is a string" + Chr$(34))
End Function

Function test_string_no_closing_quote()
  lx_parse_basic(Chr$(34) + "String literal with no closing quote")

  expect_error("No closing quote")
End Function

Function test_symbols()
  lx_parse_basic("a=b/c*d\e<=f=<g>=h=>i:j;k,l<m>n")

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

  lx_parse_basic("a$(i + 1)")
  expect_success(6)
  expect_tk(0, TK_IDENTIFIER, "a$")
  expect_tk(1, TK_SYMBOL, "(")
  expect_tk(2, TK_IDENTIFIER, "i")
  expect_tk(3, TK_SYMBOL, "+")
  expect_tk(4, TK_NUMBER, "1")
  expect_tk(5, TK_SYMBOL, ")")

  lx_parse_basic("xx=xx+1")
  expect_success(5)
  expect_tk(0, TK_IDENTIFIER, "xx")
  expect_tk(1, TK_SYMBOL, "=")
  expect_tk(2, TK_IDENTIFIER, "xx")
  expect_tk(3, TK_SYMBOL, "+")
  expect_tk(4, TK_NUMBER, "1")

End Function

Function test_get_number()
  lx_parse_basic("1 2 3.14 3.14e-15")
  assert_float_equals(1, lx_number(0))
  assert_float_equals(2, lx_number(1))
  assert_float_equals(3.14, lx_number(2))
  assert_float_equals(3.14e-15, lx_number(3))
End Function

Function test_get_string()
  lx_parse_basic(Chr$(34) + "foo" + Chr$(34) + " " + Chr$(34) + "wom bat" + Chr$(34))
  assert_string_equals("foo", lx_string$(0))
  assert_string_equals("wom bat", lx_string$(1))
End Function

Function test_get_directive()
  lx_parse_basic("'!foo '!bar '!wombat")
  assert_string_equals("!foo", lx_directive$(0))
  assert_string_equals("!bar", lx_directive$(1))
  assert_string_equals("!wombat", lx_directive$(2))
End Function

Function test_get_token_lc()
  lx_parse_basic("FOO '!BAR 1E7")
  assert_string_equals("foo", lx_token_lc$(0))
  assert_string_equals("'!bar", lx_token_lc$(1))
  assert_string_equals("1e7", lx_token_lc$(2))
End Function

Function test_parse_command_line()
  lx_parse_command_line("--foo -bar /wombat")
  assert_string_equals("--foo", lx_token_lc$(0))
  assert_string_equals("foo", lx_option$(0))
  assert_string_equals("-bar", lx_token_lc$(1))
  assert_string_equals("bar", lx_option$(1))
  assert_string_equals("/wombat", lx_token_lc$(2))
  assert_string_equals("wombat", lx_option$(2))

  lx_parse_command_line("--")
  assert_string_equals("Illegal command-line option format: --", lx_error$)

  lx_parse_command_line("-")
  assert_string_equals("Illegal command-line option format: -", lx_error$)

  lx_parse_command_line("/")
  assert_string_equals("Illegal command-line option format: /", lx_error$)

  lx_parse_command_line("--foo@ bar")
  assert_string_equals("Illegal command-line option format: --foo@", lx_error$)
End Function

Sub expect_success(num)
  assert_true(lx_error$ = "", "unexpected lexer error: " + lx_error$)
  assert_true(lx_num = num, "expected " + Str$(num) + " tokens, found " + Str$(lx_num))
End Sub

Sub expect_tk(i, type, s$)
  assert_true(lx_type(i) = type, "expected type " + Str$(type) + ", found " + Str$(lx_type(i)))
  Local actual$ = lx_token$(i)
  assert_true(actual$ = s$, "excepted " + s$ + ", found " + actual$)
End Sub

Sub expect_error(msg$)
  assert_true(lx_error$ = msg$, "missing expected error: " + msg$)
End Sub

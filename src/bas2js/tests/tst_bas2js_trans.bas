' Copyright (c) 2022-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

Option Explicit On
Option Default Integer

Const MAX_NUM_FILES = 5
Dim in.num_open_files = 1

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
#Include "../../sptrans/keywords.inc"
#Include "../../sptrans/lexer.inc"
#Include "../bas2js_trans.inc"

keywords.init()

add_test("test_insert_token")
add_test("test_remove_next_token")
add_test("test_comments")
add_test("test_do")
add_test("test_identifiers")
add_test("test_if")
add_test("test_functions")
add_test("test_loop")
add_test("test_next")
add_test("test_subs")

run_tests()

End

Sub test_insert_token()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  token1 token2"))
  tr.current% = 0
  tr.insert_token("tokenA", TK_IDENTIFIER)

  assert_string_equals("  token1 tokenA token2", lx.line$)
  expect_num_tokens(3)
  expect_token(0, TK_IDENTIFIER, "token1", 3)
  expect_token(1, TK_IDENTIFIER, "tokenA", 10)
  expect_token(2, TK_IDENTIFIER, "token2", 17)

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  token1 token2"))
  tr.current% = 1
  tr.insert_token("tokenA", TK_IDENTIFIER)

  assert_string_equals("  token1 token2 tokenA", lx.line$)
  expect_num_tokens(3)
  expect_token(0, TK_IDENTIFIER, "token1", 3)
  expect_token(1, TK_IDENTIFIER, "token2", 10)
  expect_token(2, TK_IDENTIFIER, "tokenA", 17)
End Sub

Sub test_remove_next_token()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  token1 token2"))
  tr.current% = 0
  tr.remove_next_token()

  expect_num_tokens(1)
  expect_token(0, TK_IDENTIFIER, "token1", 3)
End Sub

Sub test_comments()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("' The simplest possible comment"))
  tr.transpile()
  expect_num_tokens(1)
  expect_token(0, TK_COMMENT, "// The simplest possible comment", 1)

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  ' Comment with leading whitespace"))
  tr.transpile()
  expect_num_tokens(1)
  expect_token(0, TK_COMMENT, "// Comment with leading whitespace", 3)

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  Print ' Comment with leading statement"))
  tr.transpile()
  expect_num_tokens(2)
  expect_token(0, TK_KEYWORD, "Print", 3)
  expect_token(1, TK_COMMENT, "// Comment with leading statement", 9)
End Sub

Sub test_do()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  Do"))
  tr.transpile()
  assert_string_equals("  do {", lx.line$)
  expect_num_tokens(2)
  expect_token(0, TK_KEYWORD, "do", 3)
  expect_token(1, TK_SYMBOL, "{", 6)

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  Exit Do"))
  tr.transpile()
  assert_string_equals("  break", lx.line$)
  expect_num_tokens(1)
  expect_token(0, TK_KEYWORD, "break", 3)
End Sub

Sub test_identifiers()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("Dim i% = 1"))
  tr.transpile()
  assert_string_equals("Dim i = 1", lx.line$)
  expect_num_tokens(4)
  expect_token(0, TK_KEYWORD, "Dim", 1)
  expect_token(1, TK_IDENTIFIER, "i", 5)
  expect_token(2, TK_SYMBOL, "=", 7)
  expect_token(3, TK_NUMBER, "1", 9)
End Sub

Sub test_if()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  IF foo THEN bar"))
  tr.transpile()
  assert_string_equals("  if (foo { bar", lx.line$)
  expect_num_tokens(5)
  expect_token(0, TK_KEYWORD, "if", 3)
  expect_token(1, TK_SYMBOL, "(", 6)
  expect_token(2, TK_IDENTIFIER, "foo", 7)
  expect_token(3, TK_SYMBOL, "{", 11)
  expect_token(4, TK_IDENTIFIER, "bar", 13)

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  ELSEIF foo THEN"))
  tr.transpile()
  assert_string_equals("  } else if (foo {", lx.line$)
  expect_num_tokens(6)
  expect_token(0, TK_SYMBOL, "}", 3)
  expect_token(1, TK_KEYWORD, "else", 5)
  expect_token(2, TK_KEYWORD, "if", 10)
  expect_token(3, TK_SYMBOL, "(", 13)
  expect_token(4, TK_IDENTIFIER, "foo", 14)
  expect_token(5, TK_SYMBOL, "{", 18)

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  ELSE bar"))
  tr.transpile()
  assert_string_equals("  } else { bar", lx.line$)
  expect_num_tokens(4)
  expect_token(0, TK_SYMBOL, "}", 3)
  expect_token(1, TK_KEYWORD, "else", 5)
  expect_token(2, TK_SYMBOL, "{", 10)
  expect_token(3, TK_IDENTIFIER, "bar", 12)

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  ENDIF"))
  tr.transpile()
  assert_string_equals("  }", lx.line$)
  expect_num_tokens(1)
  expect_token(0, TK_SYMBOL, "}", 3)
End Sub

Sub test_functions()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  FUNCTION foo()"))
  tr.transpile()
  assert_string_equals("  function foo()", lx.line$)
  expect_num_tokens(4)
  expect_token(0, TK_KEYWORD, "function", 3)
  expect_token(1, TK_IDENTIFIER, "foo", 12)
  expect_token(2, TK_SYMBOL, "(", 15)
  expect_token(3, TK_SYMBOL, ")", 16)

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  END FUNCTION"))
  tr.transpile()
  assert_string_equals("  }", lx.line$)
  expect_num_tokens(1)
  expect_token(0, TK_SYMBOL, "}", 3)

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  EXIT FUNCTION"))
  tr.transpile()
  assert_string_equals("  return", lx.line$)
  expect_num_tokens(1)
  expect_token(0, TK_KEYWORD, "return", 3)
End Sub

Sub test_loop()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  Loop"))
  tr.transpile()
  assert_string_equals("  }", lx.line$)
  expect_num_tokens(1)
  expect_token(0, TK_SYMBOL, "}", 3)
End Sub

Sub test_next()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  Next"))
  tr.transpile()
  assert_string_equals("  }", lx.line$)
  expect_num_tokens(1)
  expect_token(0, TK_SYMBOL, "}", 3)
End Sub

Sub test_subs()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  SUB foo()"))
  tr.transpile()
  assert_string_equals("  function foo()", lx.line$)
  expect_num_tokens(4)
  expect_token(0, TK_KEYWORD, "function", 3)
  expect_token(1, TK_IDENTIFIER, "foo", 12)
  expect_token(2, TK_SYMBOL, "(", 15)
  expect_token(3, TK_SYMBOL, ")", 16)

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  END SUB"))
  tr.transpile()
  assert_string_equals("  }", lx.line$)
  expect_num_tokens(1)
  expect_token(0, TK_SYMBOL, "}", 3)

  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  EXIT SUB"))
  tr.transpile()
  assert_string_equals("  return", lx.line$)
  expect_num_tokens(1)
  expect_token(0, TK_KEYWORD, "return", 3)
End Sub

Sub expect_num_tokens(num%)
  assert_no_error()
  assert_true(lx.num = num%, "expected " + Str$(num%) + " tokens, found " + Str$(lx.num))
End Sub

Sub expect_token(i%, type%, s$, start%)
  assert_true(lx.type(i%) = type%, "expected type " + Str$(type%) + ", found " + Str$(lx.type(i)))
  assert_string_equals(s$, lx.token$(i))
  If start% > 0 Then assert_int_equals(start%, lx.start(i%))
  assert_int_equals(Len(s$), lx.len(i%))
End Sub

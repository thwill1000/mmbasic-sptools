' Copyright (c) 2022 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07.05

Option Explicit On
Option Default Integer

Const QU$ = Chr$(34)
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

keywords.load()

add_test("test_insert_token")
add_test("test_remove_token")
add_test("test_replace_token")
If 0 Then
add_test("test_chr")
add_test("test_comments")
add_test("test_dim")
add_test("test_directives")
add_test("test_do")
add_test("test_end")
add_test("test_identifiers")
add_test("test_if")
add_test("test_functions")
add_test("test_loop")
add_test("test_mode")
add_test("test_next")
add_test("test_option")
add_test("test_subs")
EndIf
run_tests()

End

Sub setup_test()
'  set.clear(tr.flags$())
'  map.clear(tr.replace$())
End Sub

Sub teardown_test()
End Sub

Sub test_insert_token()
  ' Test insertion into empty line.
  lx.parse_basic("")
  tr.insert_token(0, "foo", TK_IDENTIFIER)
  assert_string_equals("foo", lx.line$)
  expect_num_tokens(1)
  expect_token(0, TK_IDENTIFIER, "foo", 1)

  ' Test insertion into line only containing whitespace.
  lx.parse_basic("  ")
  tr.insert_token(0, "foo", TK_IDENTIFIER)
  assert_string_equals("  foo", lx.line$)
  expect_num_tokens(1)
  expect_token(0, TK_IDENTIFIER, "foo", 3)

  ' Test insertion before first token.
  lx.parse_basic("  foo")
  tr.insert_token(0, "bar", TK_IDENTIFIER)
  lx.dump()
  assert_string_equals("  bar foo", lx.line$)
  expect_num_tokens(2)
  expect_token(0, TK_IDENTIFIER, "bar", 3)
  expect_token(1, TK_IDENTIFIER, "foo", 7)

  ' Test insertion after last token.
  lx.parse_basic("  foo")
  tr.insert_token(1, "bar", TK_IDENTIFIER)
  assert_string_equals("  foo bar", lx.line$)
  expect_num_tokens(2)
  expect_token(0, TK_IDENTIFIER, "foo", 3)
  expect_token(1, TK_IDENTIFIER, "bar", 7)

  ' Test insertion between two token.
  lx.parse_basic("  foo  bar")
  tr.insert_token(1, "wombat", TK_IDENTIFIER)
  lx.dump()
  assert_string_equals("  foo wombat  bar", lx.line$)
  expect_num_tokens(3)
  expect_token(0, TK_IDENTIFIER, "foo", 3)
  expect_token(1, TK_IDENTIFIER, "wombat", 7)
  expect_token(2, TK_IDENTIFIER, "bar", 15)
Exit Sub
  assert_string_equals("  token1 tokenA token2", lx.line$)
  expect_num_tokens(3)
  expect_token(0, TK_IDENTIFIER, "token1", 3)
  expect_token(1, TK_IDENTIFIER, "tokenA", 10)
  expect_token(2, TK_IDENTIFIER, "token2", 17)


  lx.parse_basic("  token1 token2")
  tr.current% = 0
  tr.insert_token("tokenA", TK_IDENTIFIER)

  assert_string_equals("  token1 tokenA token2", lx.line$)
  expect_num_tokens(3)
  expect_token(0, TK_IDENTIFIER, "token1", 3)
  expect_token(1, TK_IDENTIFIER, "tokenA", 10)
  expect_token(2, TK_IDENTIFIER, "token2", 17)

  lx.parse_basic("  token1 token2")
  tr.current% = 1
  tr.insert_token("tokenA", TK_IDENTIFIER)

  assert_string_equals("  token1 token2 tokenA", lx.line$)
  expect_num_tokens(3)
  expect_token(0, TK_IDENTIFIER, "token1", 3)
  expect_token(1, TK_IDENTIFIER, "token2", 10)
  expect_token(2, TK_IDENTIFIER, "tokenA", 17)
End Sub

Sub test_remove_token()
  lx.parse_basic("  token1 token2")

  tr.remove_token(0)

  assert_string_equals("  token2", lx.line$)
  expect_num_tokens(1)
  expect_token(0, TK_IDENTIFIER, "token2", 3)

  lx.parse_basic("  token1 token2")

  tr.remove_token(1)

  assert_string_equals("  token1", lx.line$)
  expect_num_tokens(1)
  expect_token(0, TK_IDENTIFIER, "token1", 3)

  lx.parse_basic("  one two three")
  tr.remove_token(1)

  assert_string_equals("  one three", lx.line$)
  expect_num_tokens(2)
  expect_token(0, TK_IDENTIFIER, "one", 3)
  expect_token(1, TK_IDENTIFIER, "three", 7)
  
  lx.parse_basic("let y(3) = (" + str.quote$("foo") + ", " + str.quote$("bar") + ")")
  tr.remove_token(2)
  'lx.dump()
  tr.remove_token(2)
  'lx.dump()
  tr.remove_token(2)
  'lx.dump()
  Exit Sub
  assert_string_equals("let y() = (" + str.quote$("foo") + ", " + str.quote$("bar") + ")", lx.line$)
  expect_num_tokens(10)
  expect_token(0, TK_KEYWORD, "let", 1)
  expect_token(1, TK_IDENTIFIER, "y", 5)
  expect_token(2, TK_SYMBOL, "(", 6)
  expect_token(3, TK_SYMBOL, ")", 7)
  expect_token(4, TK_SYMBOL, "=", 9)
  expect_token(5, TK_SYMBOL, "(", 11)
  expect_token(6, TK_STRING, str.quote$("foo"), 12)
  expect_token(7, TK_SYMBOL, ",", 17)
  expect_token(8, TK_STRING, str.quote$("bar"), 19)
  expect_token(9, TK_SYMBOL, ")", 24)
End Sub

Sub test_replace_token()
  ' Test replacing the first token.
  lx.parse_basic(" one  two   three")

  tr.replace_token(0, "wombat", TK_KEYWORD)

  assert_string_equals(" wombat  two   three", lx.line$)
  expect_num_tokens(3)
  expect_token(0, TK_KEYWORD, "wombat", 2)
  expect_token(1, TK_IDENTIFIER, "two", 10)
  expect_token(2, TK_IDENTIFIER, "three", 16)

  ' Test replacing an intermediate token.
  lx.parse_basic(" one  two   three")

  tr.replace_token(1, "wombat", TK_KEYWORD)

  assert_string_equals(" one  wombat   three", lx.line$)
  expect_num_tokens(3)
  expect_token(0, TK_IDENTIFIER, "one", 2)
  expect_token(1, TK_KEYWORD, "wombat", 7)
  expect_token(2, TK_IDENTIFIER, "three", 16)

  ' Test replacing last token.
  lx.parse_basic(" one  two   three")

  tr.replace_token(2, "wombat", TK_KEYWORD)

  assert_string_equals(" one  two   wombat", lx.line$)
  expect_num_tokens(3)
  expect_token(0, TK_IDENTIFIER, "one", 2)
  expect_token(1, TK_IDENTIFIER, "two", 7)
  expect_token(2, TK_KEYWORD, "wombat", 13)
End Sub

Sub test_chr()
  lx.parse_basic("  Chr$(125) + Chr$(&hFE)")

  tr.transpile()

  assert_string_equals("  String.fromCharCode(125) + String.fromCharCode(&hFE)", lx.line$)
End Sub

Sub test_comments()
  lx.parse_basic("' The simplest possible comment")
  tr.transpile()
  expect_num_tokens(1)
  expect_token(0, TK_COMMENT, "// The simplest possible comment", 1)

  lx.parse_basic("  ' Comment with leading whitespace")
  tr.transpile()
  expect_num_tokens(1)
  expect_token(0, TK_COMMENT, "// Comment with leading whitespace", 3)

  lx.parse_basic("  Print ' Comment with leading statement")
  tr.transpile()
  expect_num_tokens(2)
  expect_token(0, TK_KEYWORD, "Print", 3)
  expect_token(1, TK_COMMENT, "// Comment with leading statement", 9)
End Sub

Sub test_dim()
  lx.parse_basic("  Dim x% = 1")
  tr.transpile()

  assert_string_equals("  let x = 1", lx.line$)
  expect_num_tokens(4)
  expect_token(0, TK_KEYWORD, "let", 3)
  expect_token(1, TK_IDENTIFIER, "x", 7)
  expect_token(2, TK_SYMBOL, "=", 9)
  expect_token(3, TK_NUMBER, "1", 11)

  lx.parse_basic("  Dim y$(3) = (" + str.quote$("foo") + ", " + str.quote$("bar") + ")")
  tr.transpile()

  assert_string_equals("  let y = [" + str.quote$("foo") + ", " + str.quote$("bar") + "]", lx.line$)
  expect_num_tokens(8)
  expect_token(0, TK_KEYWORD, "let", 3)
  expect_token(1, TK_IDENTIFIER, "y", 7)
  expect_token(2, TK_SYMBOL, "=", 9)
  expect_token(3, TK_SYMBOL, "[", 11)
  expect_token(4, TK_STRING, str.quote$("foo"), 12)
  expect_token(5, TK_SYMBOL, ",", 17)
  expect_token(6, TK_STRING, str.quote$("bar"), 19)
  expect_token(7, TK_SYMBOL, "]", 24)
End Sub

Sub test_directives()
  lx.parse_basic("  '!remove_if CONSOLE_ONLY")
  tr.transpile()
  assert_string_equals("  // '!remove_if CONSOLE_ONLY", lx.line$)
  expect_num_tokens(1)
  expect_token(0, TK_COMMENT, "// '!remove_if CONSOLE_ONLY", 3)

  lx.parse_basic("  '!endif")
  tr.transpile()
  assert_string_equals("  // '!endif", lx.line$)
  expect_num_tokens(1)
  expect_token(0, TK_COMMENT, "// '!endif", 3)
End Sub

Sub test_do()
  lx.parse_basic("  Do")
  tr.transpile()
  assert_string_equals("  do {", lx.line$)
  expect_num_tokens(2)
  expect_token(0, TK_KEYWORD, "do", 3)
  expect_token(1, TK_SYMBOL, "{", 6)

  lx.parse_basic("  Exit Do")
  tr.transpile()
  assert_string_equals("  break", lx.line$)
  expect_num_tokens(1)
  expect_token(0, TK_KEYWORD, "break", 3)

  lx.parse_basic("  Loop Until 1")
  tr.transpile()
  assert_string_equals("  } while (!(1))", lx.line$)
End Sub

Sub test_end()
  lx.parse_basic("  End")

  tr.transpile()

  assert_string_equals("  // exit(0)", lx.line$)
End Sub

Sub test_identifiers()
  lx.parse_basic("  i% = 1")
  tr.transpile()
  assert_string_equals("  i = 1", lx.line$)
  expect_num_tokens(3)
  expect_token(0, TK_IDENTIFIER, "i", 3)
  expect_token(1, TK_SYMBOL, "=", 5)
  expect_token(2, TK_NUMBER, "1", 7)
End Sub

Sub test_if()
  lx.parse_basic("  IF foo THEN bar")
  tr.transpile()
  assert_string_equals("  if (foo { bar", lx.line$)
  expect_num_tokens(5)
  expect_token(0, TK_KEYWORD, "if", 3)
  expect_token(1, TK_SYMBOL, "(", 6)
  expect_token(2, TK_IDENTIFIER, "foo", 7)
  expect_token(3, TK_SYMBOL, "{", 11)
  expect_token(4, TK_IDENTIFIER, "bar", 13)

  lx.parse_basic("  ELSEIF foo THEN")
  tr.transpile()
  assert_string_equals("  } else if (foo {", lx.line$)
  expect_num_tokens(6)
  expect_token(0, TK_SYMBOL, "}", 3)
  expect_token(1, TK_KEYWORD, "else", 5)
  expect_token(2, TK_KEYWORD, "if", 10)
  expect_token(3, TK_SYMBOL, "(", 13)
  expect_token(4, TK_IDENTIFIER, "foo", 14)
  expect_token(5, TK_SYMBOL, "{", 18)

  lx.parse_basic("  ELSE bar")
  tr.transpile()
  assert_string_equals("  } else { bar", lx.line$)
  expect_num_tokens(4)
  expect_token(0, TK_SYMBOL, "}", 3)
  expect_token(1, TK_KEYWORD, "else", 5)
  expect_token(2, TK_SYMBOL, "{", 10)
  expect_token(3, TK_IDENTIFIER, "bar", 12)

  lx.parse_basic("  ENDIF")
  tr.transpile()
  assert_string_equals("  }", lx.line$)
  expect_num_tokens(1)
  expect_token(0, TK_SYMBOL, "}", 3)
End Sub

Sub test_functions()
  lx.parse_basic("  FUNCTION foo()")
  tr.transpile()
  assert_string_equals("  function foo() {", lx.line$)
  expect_num_tokens(5)
  expect_token(0, TK_KEYWORD, "function", 3)
  expect_token(1, TK_IDENTIFIER, "foo", 12)
  expect_token(2, TK_SYMBOL, "(", 15)
  expect_token(3, TK_SYMBOL, ")", 16)
  expect_token(4, TK_SYMBOL, "{", 18)

  lx.parse_basic("  END FUNCTION")
  tr.transpile()
  assert_string_equals("  }", lx.line$)
  expect_num_tokens(1)
  expect_token(0, TK_SYMBOL, "}", 3)

  lx.parse_basic("  EXIT FUNCTION")
  tr.transpile()
  assert_string_equals("  return", lx.line$)
  expect_num_tokens(1)
  expect_token(0, TK_KEYWORD, "return", 3)
End Sub

Sub test_loop()
  lx.parse_basic("  Loop")
  tr.transpile()
  assert_string_equals("  }", lx.line$)
  expect_num_tokens(1)
  expect_token(0, TK_SYMBOL, "}", 3)
End Sub

Sub test_mode()
  lx.parse_basic("  Mode 2")
  tr.transpile()
  assert_string_equals("  // Mode 2", lx.line$)
  expect_num_tokens(1)
  expect_token(0, TK_COMMENT, "// Mode 2", 3)
End Sub

Sub test_next()
  lx.parse_basic("  Next")
  tr.transpile()
  assert_string_equals("  }", lx.line$)
  expect_num_tokens(1)
  expect_token(0, TK_SYMBOL, "}", 3)
End Sub

Sub test_option()
  lx.parse_basic("  Option Base")
  tr.transpile()
  assert_string_equals("  // Option Base", lx.line$)
  expect_num_tokens(1)
  expect_token(0, TK_COMMENT, "// Option Base", 3)
End Sub

Sub test_subs()
  lx.parse_basic("  SUB foo()")
  tr.transpile()
  assert_string_equals("  function foo() {", lx.line$)
  expect_num_tokens(5)
  expect_token(0, TK_KEYWORD, "function", 3)
  expect_token(1, TK_IDENTIFIER, "foo", 12)
  expect_token(2, TK_SYMBOL, "(", 15)
  expect_token(3, TK_SYMBOL, ")", 16)
  expect_token(4, TK_SYMBOL, "{", 18)

  lx.parse_basic("  END SUB")
  tr.transpile()
  assert_string_equals("  }", lx.line$)
  expect_num_tokens(1)
  expect_token(0, TK_SYMBOL, "}", 3)

  lx.parse_basic("  EXIT SUB")
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

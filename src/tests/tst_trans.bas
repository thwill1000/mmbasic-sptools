' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

Const MAX_NUM_FILES = 5
Dim num_files = 1

#Include "unittest.inc"
#Include "../lexer.inc"
#Include "../map.inc"
#Include "../trans.inc"
#Include "../set.inc"

Cls

lx_load_keywords("\mbt\resources\keywords.txt")

ut_add_test("test_replace")

ut_run_tests()

End

Function test_replace()
  map_clear(replace$(), with$(), replace_sz)
  transpile("'!replace x      y")
  transpile("'!replace &hFFFF z")

  transpile("Dim x = &hFFFF ' comment")

  expect_tokens(5)
  expect_tk(0, TK_KEYWORD, "Dim")
  expect_tk(1, TK_IDENTIFIER, "y")
  expect_tk(2, TK_SYMBOL, "=")
  expect_tk(3, TK_IDENTIFIER, "z")
  expect_tk(4, TK_COMMENT, "' comment")
  ut_assert_string_equals("Dim y = z ' comment", lx_line$)
End Function

Sub expect_tokens(num)
  ut_assert(lx_error$ = "", "unexpected lexer error: " + lx_error$)
  ut_assert(lx_num = num, "expected " + Str$(num) + " tokens, found " + Str$(lx_num))
End Sub

Sub expect_tk(i, type, s$)
  ut_assert(lx_type(i) = type, "expected type " + Str$(type) + ", found " + Str$(lx_type(i)))
  ut_assert_string_equals(s$, lx_token$(i))
End Sub


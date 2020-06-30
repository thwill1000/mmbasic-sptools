' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

#Include "../unittest.inc"
#Include "../lexer.inc"
#Include "../replace.inc"

Cls

lx_load_keywords()

ut_add_test("test_one_replacement")
ut_add_test("test_two_replacements")

ut_run_tests()

End

Function test_one_replacement()
  lx_parse_line("foo")
  rp_add("foo", "bar")
  rp_apply()

  expect_tokens(1)
  expect_tk(0, LX_IDENTIFIER, "bar")
End Function

Function test_two_replacements()
  lx_parse_line("Dim x = &hFFFF ' comment")
  rp_add("x", "y")
  rp_add("&hFFFF", "z")
  rp_apply()

  expect_tokens(5)
  expect_tk(0, LX_KEYWORD, "Dim")
  expect_tk(1, LX_IDENTIFIER, "y")
  expect_tk(2, LX_SYMBOL, "=")
  expect_tk(3, LX_IDENTIFIER, "z")
  expect_tk(4, LX_COMMENT, "' comment")
  ut_assert_string_equals("Dim y = z ' comment", lx_line$)
End Function

Sub expect_tokens(num)
  ut_assert(lx_error$ = "", "unexpected lexer error: " + lx_error$)
  ut_assert(lx_num = num, "expected " + Str$(num) + " tokens, found " + Str$(lx_num))
End Sub

Sub expect_tk(i, type, s$)
  ut_assert(lx_type(i) = type, "expected type " + Str$(type) + ", found " + Str$(lx_type(i)))
  Local actual$ = lx_get_token$(i)
  ut_assert(actual$ = s$, "excepted " + s$ + ", found " + actual$)
End Sub


' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

#Include "unittest.inc"
#Include "lexer.inc"

Cls

lx_init()

ut_add_test("test_include")
ut_add_test("test_directive")
ut_add_test("test_cardinal")
ut_add_test("test_reals")

ut_run_tests()

End

Function test_include()
  lx_parse_line("#Include " + Chr$(34) + "foo.inc" + Chr$(34))

  expect_success(2)
  expect_tk(0, LX_KEYWORD, "#Include")
  expect_tk(1, LX_STRING, Chr$(34) + "foo.inc" + Chr$(34))
End Function

Function test_directive()
  lx_parse_line("'!comment_if foo")

  expect_success(2)
  expect_tk(0, LX_DIRECTIVE, "'!comment_if")
  expect_tk(1, LX_IDENTIFIER, "foo")
End Function

Function test_cardinal()
  lx_parse_line("421")

  expect_success(1)
  expect_tk(0, LX_NUMBER, "421")
End Function

Function test_reals()
  lx_parse_line("3.421")

  expect_success(1)
  expect_tk(0, LX_NUMBER, "3.421")

  lx_parse_line("3.421e5")

  expect_success(1)
  expect_tk(0, LX_NUMBER, "3.421e5")

End Function

Sub expect_success(num)
  ut_assert(lx_error$ = "", "unexpected lexer error: " + lx_error$)
  ut_assert(lx_num = num, "expected " + Str$(num) + " tokens, found " + Str$(lx_num))
End Sub

Sub expect_tk(i, type, s$)
  ut_assert(lx_type(i) = type, "expected type " + Str$(type) + ", found " + Str$(lx_type(i)))
  Local actual$ = lx_get_token$(i)
  ut_assert(actual$ = s$, "excepted " + s$ + ", found " + actual$)
End Sub


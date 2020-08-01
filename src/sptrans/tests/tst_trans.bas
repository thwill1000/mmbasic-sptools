' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

Const MAX_NUM_FILES = 5
Dim in_files_sz = 1

#Include "../lexer.inc"
#Include "../trans.inc"
#Include "../../common/error.inc"
#Include "../../common/list.inc"
#Include "../../common/map.inc"
#Include "../../common/set.inc"
#Include "../../sptest/unittest.inc"

lx_load_keywords("\sptools\resources\keywords.txt")

add_test("test_replace")

run_tests()

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Function test_replace()
  map_clear(replace$(), with$(), replace_sz)
  lx_parse_basic("'!replace x      y") : transpile()
  lx_parse_basic("'!replace &hFFFF z") : transpile()
  lx_parse_basic("Dim x = &hFFFF ' comment") : transpile()

  expect_tokens(5)
  expect_tk(0, TK_KEYWORD, "Dim")
  expect_tk(1, TK_IDENTIFIER, "y")
  expect_tk(2, TK_SYMBOL, "=")
  expect_tk(3, TK_IDENTIFIER, "z")
  expect_tk(4, TK_COMMENT, "' comment")
  assert_string_equals("Dim y = z ' comment", lx_line$)
End Function

Sub expect_tokens(num)
  assert_no_error()
  assert_true(lx_num = num, "expected " + Str$(num) + " tokens, found " + Str$(lx_num))
End Sub

Sub expect_tk(i, type, s$)
  assert_true(lx_type(i) = type, "expected type " + Str$(type) + ", found " + Str$(lx_type(i)))
  assert_string_equals(s$, lx_token$(i))
End Sub


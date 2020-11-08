' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

Const MAX_NUM_FILES = 5
Dim in.num_open_files = 1

#Include "../../common/error.inc"
#Include "../../common/file.inc"
#Include "../../common/list.inc"
#Include "../../common/map.inc"
#Include "../../common/set.inc"
#Include "../../sptest/unittest.inc"
#Include "../lexer.inc"
#Include "../trans.inc"

lx.load_keywords("\sptools\resources\keywords.txt")

add_test("test_replace")

run_tests()

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Function test_replace()
  map.clear(replace$())
  lx.parse_basic("'!replace x      y") : transpile()
  lx.parse_basic("'!replace &hFFFF z") : transpile()
  lx.parse_basic("Dim x = &hFFFF ' comment") : transpile()

  expect_tokens(5)
  expect_tk(0, TK_KEYWORD, "Dim")
  expect_tk(1, TK_IDENTIFIER, "y")
  expect_tk(2, TK_SYMBOL, "=")
  expect_tk(3, TK_IDENTIFIER, "z")
  expect_tk(4, TK_COMMENT, "' comment")
  assert_string_equals("Dim y = z ' comment", lx.line$)
End Function

Sub expect_tokens(num)
  assert_no_error()
  assert_true(lx.num = num, "expected " + Str$(num) + " tokens, found " + Str$(lx.num))
End Sub

Sub expect_tk(i, type, s$)
  assert_true(lx.type(i) = type, "expected type " + Str$(type) + ", found " + Str$(lx.type(i)))
  assert_string_equals(s$, lx.token$(i))
End Sub


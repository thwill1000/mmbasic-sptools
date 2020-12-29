' Copyright (c) 2020-2021 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.06

Option Explicit On
Option Default Integer

Const MAX_NUM_FILES = 5
Dim in.num_open_files = 1

#Include "../../common/system.inc"
#Include "../../common/array.inc"
#Include "../../common/list.inc"
#Include "../../common/string.inc"
#Include "../../common/file.inc"
#Include "../../common/map.inc"
#Include "../../common/set.inc"
#Include "../../common/vt100.inc"
#Include "../../sptest/unittest.inc"
#Include "../keywords.inc"
#Include "../lexer.inc"
#Include "../trans.inc"

keywords.load("\sptools\resources\keywords.txt")

add_test("test_replace")

run_tests()

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Sub test_replace()
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
End Sub

Sub expect_tokens(num)
  assert_no_error()
  assert_true(lx.num = num, "expected " + Str$(num) + " tokens, found " + Str$(lx.num))
End Sub

Sub expect_tk(i, type, s$)
  assert_true(lx.type(i) = type, "expected type " + Str$(type) + ", found " + Str$(lx.type(i)))
  assert_string_equals(s$, lx.token$(i))
End Sub


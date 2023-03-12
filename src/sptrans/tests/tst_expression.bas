' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

Option Explicit On
Option Default Integer

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
#Include "../keywords.inc"
#Include "../lexer.inc"
#Include "../defines.inc"
#Include "../expression.inc"

const SUCCESS = 0

keywords.init()

add_test("test_eval_fundamentals")
add_test("test_eval_and")
add_test("test_eval_or")
add_test("test_eval_not")
add_test("test_eval_xor")
add_test("test_eval_operator_precedence")
add_test("test_eval_brackets")
add_test("test_eval_syntax_errors")

run_tests()

End

Sub setup_test()
  def.init()
End Sub

Sub test_eval_fundamentals()
  run_eval_tests("eval_fundamentals")
End Sub

eval_fundamentals:
  Data "1", 1
  Data "true", 1
  Data "on", 1
  Data "defined true", 1
  Data "0", 0
  Data "false", 0
  Data "off", 0
  Data "defined false", 0
  Data "", -1

Sub run_eval_tests(label$)
  Local i%
  Local num_tests% = count_data%(label$)
  Local expr$(num_tests% - 1), expected%(num_tests% - 1)
  read_data(label$, expr$(), expected%())

  For i% = 0 To num_tests% - 1
    run_eval_test(expr$(i%), expected%(i%))
  Next
End Sub

Function count_data%(label$)
  Restore label$
  Local s$, x%
  Do
    Read s$, x%
    Inc count_data%, s$ <> ""
  Loop While s$ <> ""
End Function

Sub read_data(label$, expr$(), expected%())
  Restore label$
  Local i%
  For i% = 0 To Bound(expr$(), 1)
    Read expr$(i%), expected%(i%)
  Next
End Sub

Sub run_eval_test(expr$, expected%)
  Local result%
  assert_int_equals(SUCCESS, lx.parse_basic%("'!if " + expr$))
  If expected% = -1 Then
    assert_int_equals(-1, ex.eval%(1, result%))
    assert_error("Invalid expression syntax")
  Else
    assert_int_equals(SUCCESS, ex.eval%(1, result%))
    Local msg$ = "Expected { " + expr$ + " } to evaluate to " + Str$(expected%)
    Cat msg$, ", but was " + Str$(result%))
    assert_true(result% = expected%, msg$)
  EndIf
End Sub

Sub test_eval_and()
  run_eval_tests("eval_and")
End Sub

eval_and:
  Data "true && 1", 1
  Data "true and true", 1
  Data "false && 0", 0
  Data "false and false", 0
  Data "true && 0", 0
  Data "true and false", 0
  Data "false && 1", 0
  Data "false and true", 0
  Data "", -1

Sub test_eval_or()
  run_eval_tests("eval_or")
End Sub

eval_or:
  Data "true || 1", 1
  Data "true or true", 1
  Data "false || 0", 0
  Data "false or false", 0
  Data "true || 0", 1
  Data "true or false", 1
  Data "false || 1", 1
  Data "false or true", 1
  Data "", -1

Sub test_eval_not()
  run_eval_tests("eval_not")
End Sub

eval_not:
  Data "!true", 0
  Data "not true", 0
  Data "!false", 1
  Data "not false", 1
  Data "", -1

Sub test_eval_xor()
  run_eval_tests("eval_xor")
End Sub

eval_xor:
  Data "true xor true", 0
  Data "false xor false", 0
  Data "true xor false", 1
  Data "false xor true", 1
  Data "", -1

Sub test_eval_operator_precedence()
  run_eval_tests("eval_operator_precedence")
End Sub

eval_operator_precedence:
  Data "true && !false", 1
  Data "true And Not false", 1
  Data "true || !false", 1
  Data "true Or Not false", 1
  Data "true && true || false", 1
  Data "true And true Or false", 1
  Data "true && false || true", 1
  Data "true And false Or true", 1
  Data "false && true || false", 0
  Data "false And true Or false", 0
  Data "false && false || true", 1
  Data "false And false Or true", 1
  Data "Not false And true", 1
  Data "Not false Or true", 1
  Data "false Or true And False", 0
  Data "false And true Or False", 0

  Data "", -1

Sub test_eval_brackets()
  run_eval_tests("eval_brackets")
End Sub

eval_brackets:
  Data "(true)", 1
  Data "(false)", 0
  Data "(true || (false))", 1
  Data "(false) || (true)", 1
  Data "(true and false) or true", 1
  Data "true and (false or true)", 1
  Data "defined(true)", 1
  Data "defined(false)", 0
  Data "Not (false And true)", 1
  Data "Not (false Or true)", 0
  Data "", -1

Sub test_eval_syntax_errors()
  run_eval_tests("eval_syntax_errors")
End Sub

eval_syntax_errors:
  Data " ", -1 ' No expression.
  Data "true &&", -1
  Data "(true", -1
  Data "defined", -1
  Data "defined defined", -1
  Data "a + b", -1
  Data "", -1

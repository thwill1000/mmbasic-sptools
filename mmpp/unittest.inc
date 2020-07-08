' Copyright (c) 2020 Thomas Hugo Williams

Dim ut_tests$(19)
Dim ut_num_tests = 0
Dim ut_errors$(19)
Dim ut_num_errors = 0

Sub ut_add_test(test$)
  ut_tests$(ut_num_tests) = test$
  ut_num_tests = ut_num_tests + 1
End Sub

Sub ut_add_error(msg$)
  ut_errors$(ut_num_errors) = msg$
  ut_num_errors = ut_num_errors + 1
End Sub

Sub ut_assert(z, msg$)
  If Not z Then ut_add_error(msg$)
End Sub

Sub ut_assert_real_equals(expected, actual)
  If expected <> actual Then
    Local s$ = "Assert equals failed, expected " + Str$(expected)
    s$ = s$ + " but actually " + Str$(actual)
    ut_add_error(s$)
  EndIf
End Sub

Sub ut_assert_string_equals(expected$, actual$)
  If expected$ <> actual$ Then
    Local s$ = "Assert equals failed, expected " + Chr$(34) + expected$ + Chr$(34)
    s$ = s$ + " but actually " + Chr$(34) + actual$ + Chr$(34) + "."
    ut_add_error(s$)
  EndIf
End Sub

Sub ut_run_tests()
  Local i, j, _

  For i = 0 To ut_num_tests - 1
    Print ut_tests$(i); ":"
    ut_num_errors = 0
    _ = Eval(ut_tests$(i) + "()")
    If ut_num_errors = 0 Then
      Print "  PASS"
    Else
      For j = 0 To ut_num_errors - 1
        Print "  FAIL: " + ut_errors$(j)
      Next j
    EndIf
  Next i
End Sub


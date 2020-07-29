' Copyright (c) 2020 Thomas Hugo Williams

Dim ut_tests$(100) Length 40
Dim ut_tests_sz = 0
Dim ut_failures$(100)
Dim ut_failures_sz = 0
Dim ut_asserts_count

Sub add_test(test$)
  ut_tests$(ut_tests_sz) = test$
  ut_tests_sz = ut_tests_sz + 1
End Sub

Sub fail(msg$)
  ut_asserts_count = ut_asserts_count + 1
  ut_add_failure(msg$)
End Sub

Sub assert_true(z, msg$)
  ut_asserts_count = ut_asserts_count + 1
  If Not z Then ut_add_failure(msg$)
End Sub

Sub ut_add_failure(msg$)
  ut_failures$(ut_failures_sz) = Str$(ut_asserts_count) + ": " + msg$
  ut_failures_sz = ut_failures_sz + 1
End Sub

Sub assert_equals(expected As Integer, actual As Integer)
  ut_asserts_count = ut_asserts_count + 1
  If expected <> actual Then
    Local s$ = "Assert equals failed, expected " + Str$(expected)
    s$ = s$ + " but actually " + Str$(actual)
    ut_add_failure(s$)
  EndIf
End Sub

Sub assert_float_equals(expected As Float, actual As float)
  ut_asserts_count = ut_asserts_count + 1
  If expected <> actual Then
    Local s$ = "Assert equals failed, expected " + Str$(expected)
    s$ = s$ + " but actually " + Str$(actual)
    ut_add_failure(s$)
  EndIf
End Sub

Sub assert_string_equals(expected$, actual$)
  ut_asserts_count = ut_asserts_count + 1
  If expected$ <> actual$ Then
    Local s$ = "Assert equals failed, expected " + Chr$(34) + expected$ + Chr$(34)
    s$ = s$ + " but actually " + Chr$(34) + actual$ + Chr$(34)
    ut_add_failure(s$)
  EndIf
End Sub

Sub assert_no_error()
  ut_asserts_count = ut_asserts_count + 1
  If err$ <> "" Then
    Local s$ = "Expected no error, but actually " + Chr$(34) + err$ + Chr$(34)
    ut_add_failure(s$)
  EndIf
End Sub

Sub assert_error(expected$)
  ut_asserts_count = ut_asserts_count + 1
  If err$ <> expected$ Then
    Local s$ = "Expected Error " + Chr$(34) + expected$ + Chr$(34)
    s$ = s$ + ", but actually " + Chr$(34) + err$ + Chr$(34)
    ut_add_failure(s$)
  EndIf
End Sub

Sub run_tests()
  Local i, j, _

  Print Mm.Info$(Current)
  For i = 0 To ut_tests_sz - 1
    Print "  " + ut_tests$(i); ":"; Space$(35 - Len(ut_tests$(i)));

    ut_asserts_count = 0
    ut_failures_sz = 0

    setup_test()
    _ = Eval(ut_tests$(i) + "()")
    teardown_test()

    If ut_failures_sz = 0 Then
      Print "PASS ("; Str$(ut_asserts_count); "/"; Str$(ut_asserts_count); ")"
    Else If ut_failures_sz > 0 Then
      Print "FAIL ("; Str$(ut_failures_sz); "/"; Str$(ut_asserts_count); ")"
      For j = 0 To ut_failures_sz - 1
        Print "  "; ut_failures$(j)
      Next j
    EndIf

  Next i

  If Mm.CmdLine$ = "--all" Then run_next_test_file()
End Sub

Sub run_next_test_file()
  Const MAX_NUM_TEST_FILES = 20
  Local test_files$(MAX_NUM_TEST_FILES - 1) Length 40
  Local test_files_sz = 0
  Local f$, i, old$

  On Error Skip 1
  set_init(test_files$(), MAX_NUM_TEST_FILES)
  If Mm.ErrNo <> 0 Then Error "requires 'set.inc'"

  ' If there is a "tests/" directory then we look there for "tst_*" files,
  ' otherwise we look in the current working directory.
  f$ = Dir$("tests", Dir)
  If f$ <> "" Then old$ = Cwd$ : ChDir f$

  ' Get alphabetic list of all "tst_*.bas" files.
  f$ = Dir$("tst*.bas", All)
  Do While f$ <> ""
    set_put(test_files$(), test_files_sz, f$)
    f$ = Dir$()
  Loop

  If old$ <> "" Then ChDir old$

  If test_files_sz = 0 Then
    Print "No tests found"
    Exit Sub
  EndIf

  ' Lookup the index of the current file and run the next one.
  ' Note that if the current file was "sptest.bas" then the lookup returns -1
  ' and thus the first "tst_*.bas" file will be run.
  Local current$ = fi_current_name$()
  i = set_get(test_files$(), test_files_sz, current$)
  If i < test_files_sz - 1 Then
    If old$ = "" Then f$ = "" Else f$ = "tests/"
    f$ = f$ + test_files$(i + 1)
    Execute "Run " + Chr$(34) + f$ + Chr$(34) + ", --all"
  EndIf
End Sub

Function fi_current_name$()
  Local i
  Local f$ = Mm.Info$(Current) ' full path
  For i = Len(f$) To 1 Step -1
    If Mid$(f$, i, 1) = "/" Then Exit For
  Next i
  fi_current_name$ = Mid$(f$, i + 1)
End Function

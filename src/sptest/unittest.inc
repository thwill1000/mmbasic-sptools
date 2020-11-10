' Copyright (c) 2020 Thomas Hugo Williams

check_included("file")
check_included("list")
check_included("set")

Dim ut.tests$(list.new%(100)) Length 40
Dim ut.failures$(list.new%(100))
Dim ut.asserts_count%

list.init(ut.tests$())
list.init(ut.failures$())

Sub add_test(test$)
  list.add(ut.tests$(), test$)
End Sub

Sub fail(msg$)
  ut.asserts_count% = ut.asserts_count% + 1
  ut.add_failure(msg$)
End Sub

Sub assert_true(z%, msg$)
  ut.asserts_count% = ut.asserts_count% + 1
  If Not z% Then ut.add_failure(msg$)
End Sub

Sub ut.add_failure(msg$)
  list.add(ut.failures$(), Str$(ut.asserts_count%) + ": " + msg$)
End Sub

Sub assert_equals(expected%, actual%)
  ut.asserts_count% = ut.asserts_count% + 1
  If expected% <> actual% Then
    Local s$ = "Assert equals failed, expected " + Str$(expected%)
    s$ = s$ + " but actually " + Str$(actual%)
    ut.add_failure(s$)
  EndIf
End Sub

Sub assert_float_equals(expected!, actual!)
  ut.asserts_count% = ut.asserts_count% + 1
  If expected! <> actual! Then
    Local s$ = "Assert equals failed, expected " + Str$(expected!)
    s$ = s$ + " but actually " + Str$(actual!)
    ut.add_failure(s$)
  EndIf
End Sub

Sub assert_string_equals(expected$, actual$)
  ut.asserts_count% = ut.asserts_count% + 1
  If expected$ <> actual$ Then
    Local s$ = "Assert equals failed, expected " + Chr$(34) + expected$ + Chr$(34)
    s$ = s$ + " but actually " + Chr$(34) + actual$ + Chr$(34)
    ut.add_failure(s$)
  EndIf
End Sub

Sub assert_no_error()
  ut.asserts_count% = ut.asserts_count% + 1
  If err$ <> "" Then
    Local s$ = "Expected no error, but actually " + Chr$(34) + err$ + Chr$(34)
    ut.add_failure(s$)
  EndIf
End Sub

Sub assert_error(expected$)
  ut.asserts_count% = ut.asserts_count% + 1
  If err$ <> expected$ Then
    Local s$ = "Expected Error " + Chr$(34) + expected$ + Chr$(34)
    s$ = s$ + ", but actually " + Chr$(34) + err$ + Chr$(34)
    ut.add_failure(s$)
  EndIf
End Sub

Sub assert_raw_error(expected$)
  ut.asserts_count% = ut.asserts_count% + 1
  If InStr(Mm.ErrMsg$, expected$) < 1 Then
    Local s$ = "Expected Error " + Chr$(34) + expected$ + Chr$(34)
    s$ = s$ + ", but actually " + Chr$(34) + Mid$(Mm.ErrMsg$, 3) + Chr$(34)
    ut.add_failure(s$)
  EndIf
End Sub

' @param  repeat$  if this is not empty then after running the test suite the program
'                  should run itself again appending 'repeat$' to its command line.
Sub run_tests(repeat$)
  Local base% = Mm.Info(Option Base)
  Local i%, j%, num_failures%, ub%

  Print Mm.Info$(Current) + " " + Mm.CmdLine$
  ub% = base% + list.size%(ut.tests$()) - 1
  For i% = base% To ub%
    Print "  " + ut.tests$(i%); ":"; Space$(35 - Len(ut.tests$(i%)));

    ut.asserts_count% = 0
    list.clear(ut.failures$())

    err$ = ""
    setup_test()
    Call ut.tests$(i%)
    teardown_test()

    num_failures% = list.size%(ut.failures$())
    If num_failures% = 0 Then
      Print "PASS ("; Str$(ut.asserts_count%); "/"; Str$(ut.asserts_count%); ")"
    Else If num_failures% > 0 Then
      Print "FAIL ("; Str$(num_failures%); "/"; Str$(ut.asserts_count%); ")"
      For j% = base% To base% + num_failures% - 1
        Print "  "; ut.failures$(j)
      Next j%
    EndIf

  Next i%

  If repeat$ <> "" Then
    run_same_test_file(repeat$)
  ElseIf InStr(Mm.CmdLine$, "--all") Then
    run_next_test_file()
  EndIf
End Sub

' Runs the current test file again appending 'cmd$' to its command line.
Sub run_same_test_file(cmd$)
  Local tgt$ = "Run " + Chr$(34) + Mm.Info(Current) + Chr$(34) + ", "
  If Mm.CmdLine$ <> "" Then tgt$ = tgt$ + Mm.CmdLine$ + " "
  tgt$ = tgt$ + cmd$
  Execute tgt$
End Sub

Sub run_next_test_file()
  Local test_files$(set.new%(20)) Length 40
  Local f$, old$

  set.init(test_files$())

  ' If there is a "tests/" directory then we look there for "tst_*" files,
  ' otherwise we look in the current working directory.
  f$ = Dir$("tests", Dir)
  If f$ <> "" Then old$ = Cwd$ : ChDir f$

  ' Get alphabetic list of all "tst_*.bas" files.
  f$ = Dir$("tst*.bas", All)
  Do While f$ <> ""
    set.put(test_files$(), f$)
    f$ = Dir$()
  Loop

  If old$ <> "" Then ChDir old$

  If set.size%(test_files$()) = 0 Then
    Print "No tests found"
    Exit Sub
  EndIf

  ' Lookup the index of the current file and run the next one.
  ' Note that if the current file was "sptest.bas" then the lookup returns -1
  ' and thus the first "tst_*.bas" file will be run.
  Local i% = set.get%(test_files$(), fil.get_name$(Mm.Info$(Current)))

  ' This was the last test.
  If i% >= Mm.Info(Option Base) + set.size%(test_files$()) - 1 Then Exit Sub

  If old$ = "" Then f$ = "" Else f$ = "tests/"
  f$ = f$ + test_files$(i% + 1)
  Execute "Run " + Chr$(34) + f$ + Chr$(34) + ", --all"
End Sub

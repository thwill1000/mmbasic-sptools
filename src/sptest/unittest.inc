' Copyright (c) 2020 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.06

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("file", "list", "vt100")
sys.provides("unittest")
If sys.err$ <> "" Then Error sys.err$

Dim ut.test_names$(list.new%(100)) Length 128
Dim ut.test_subs$(list.new%(100)) Length 40
Dim ut.failures$(list.new%(100))
Dim ut.asserts_count%

list.init(ut.test_names$())
list.init(ut.test_subs$())
list.init(ut.failures$())

Sub add_test(name$, sub$)
  list.add(ut.test_names$(), name$)
  list.add(ut.test_subs$(), Choice(sub$ = "", name$, sub$))
End Sub

Sub assert_fail(msg$)
  Inc ut.asserts_count%
  ut.add_failure(msg$)
End Sub

Sub assert_false(z%, msg$)
  Inc ut.asserts_count%
  If z% Then
    If msg$ = "" Then ut.add_failure("assert_false() failed") Else ut.add_failure(msg$)
  EndIf
End Sub

Sub assert_true(z%, msg$)
  Inc ut.asserts_count%
  If Not z% Then
    If msg$ = "" Then ut.add_failure("assert_true() failed") Else ut.add_failure(msg$)
  EndIf
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

Sub assert_string_equals(expected_$, actual_$)
  Local expected$ = Chr$(34) + expected_$ + Chr$(34)
  Local actual$ = Chr$(34) + actual_$ + Chr$(34)
  If Len(expected_$) = 1 Then expected$ = "Chr$(" + Str$(Asc(expected_$)) + ")"
  If Len(actual_$) = 1 Then actual$ = "Chr$(" + Str$(Asc(actual_$)) + ")"
  Inc ut.asserts_count%
  If expected$ <> actual$ Then
    Local s$ = "Assert equals failed, expected " + expected$
    Cat s$, " but actually " + actual$
    ut.add_failure(s$)
  EndIf
End Sub

Sub assert_array_equals(expected%(), actual%())
  Local base% = Mm.Info(Option Base)
  Local fail% = 0

  Inc ut.asserts_count%

  If Bound(expected%(), 1) = Bound(actual%(), 1) Then
    Local i%, lb%, ub%
    lb% = base%
    ub% = Bound(expected%(), 1)
    For i% = lb% To ub%
      If expected%(i%) <> actual%(i%) Then fail% = 1 : Exit For
    Next
  Else
    fail% = 1
  EndIf

  If fail% Then
    Local s$ = "Assert array equals failed, expected:" + sys.CRLF$ + "      "
    For i% = base% To Bound(expected%(), 1)
      If i% <> base% Then Cat s$, ", "
      Cat s$, Str$(expected%(i%))
    Next
    Cat s$, sys.CRLF$ + "    but actually: " + sys.CRLF$ + "      "
    For i% = base% To Bound(actual%(), 1)
      If i% <> base% Then Cat s$, ", "
      Cat s$, Str$(actual%(i%))
    Next
    ut.add_failure(s$)
  EndIf
End Sub

Sub assert_string_array_equals(expected$(), actual$())
  Local base% = Mm.Info(Option Base)
  Local fail% = 0

  Inc ut.asserts_count%

  If Bound(expected$(), 1) = Bound(actual$(), 1) Then
    Local i%, lb%, ub%
    lb% = base%
    ub% = Bound(expected$(), 1)
    For i% = lb% To ub%
      If expected$(i%) <> actual$(i%) Then fail% = 1 : Exit For
    Next
  Else
    fail% = 1
  EndIf

  If fail% Then
    Local s$ = "Assert array equals failed, expected:" + sys.CRLF$ + "      "
    For i% = base% To Bound(expected$(), 1)
      If i% <> base% Then Cat s$, ", "
      Cat s$, Chr$(34) + expected$(i%) + Chr$(34)
    Next
    Cat s$, sys.CRLF$ + "    but actually: " + sys.CRLF$ + "      "
    For i% = base% To Bound(actual$(), 1)
      If i% <> base% Then Cat s$, ", "
      Cat s$, Chr$(34) + actual$(i%) + Chr$(34)
    Next
    ut.add_failure(s$)
  EndIf
End Sub

Sub assert_no_error()
  ut.asserts_count% = ut.asserts_count% + 1
  If sys.err$ <> "" Then
    Local s$ = "Expected no error, but actually " + Chr$(34) + sys.err$ + Chr$(34)
    ut.add_failure(s$)
  EndIf
End Sub

Sub assert_error(expected$)
  ut.asserts_count% = ut.asserts_count% + 1
  If sys.err$ <> expected$ Then
    Local s$ = "Expected Error " + Chr$(34) + expected$ + Chr$(34)
    s$ = s$ + ", but actually " + Chr$(34) + sys.err$ + Chr$(34)
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
  Local catch_errors% = ut.is_catch_errors%()
  Local i%, j%, num_failed_asserts%, num_failed_tests%, ub%

  Local test$ = Mm.Info$(Current) + " " + Mm.CmdLine$;
  Print test$;
  Local t% = Timer
  ub% = base% + list.size%(ut.test_names$()) - 1
  For i% = base% To ub%

    If ut.is_verbose%() Then
      If i% = base% Then Print
      Print "  " + ut.test_names$(i%); ":"; Space$(Max(0, 50 - Len(ut.test_names$(i%))));
    EndIf

    ut.asserts_count% = 0
    list.clear(ut.failures$())

    If catch_errors% Then On Error Ignore
    sys.err$ = ""
    setup_test()
    Call ut.test_subs$(i%)
    teardown_test()
    If catch_errors% Then
      If Mm.ErrNo <> 0 Then add_mmbasic_error()
      On Error Abort
    EndIf

    num_failed_asserts% = list.size%(ut.failures$())
    If num_failed_asserts% > 0 Then Inc num_failed_tests%

    If ut.is_verbose%() Then
      If num_failed_asserts% = 0 Then
        ut.print_colour("green")
        Print "PASS ("; Str$(ut.asserts_count%); "/"; Str$(ut.asserts_count%); ")";
      Else If num_failed_asserts% > 0 Then
        ut.print_colour("red")
        Print "FAIL ("; Str$(num_failed_asserts%); "/"; Str$(ut.asserts_count%); ")";
        For j% = base% To base% + num_failed_asserts% - 1
          Print
          Print "    "; ut.failures$(j%);
        Next j%
      EndIf
      ut.print_colour("reset")
      Print
    EndIf

  Next i%

  If ut.is_verbose%() Then
    Print "  Execution time: " Str$((Timer - t%) / 1000) " s"
    Print "  ";
  Else
    Print Space$(85 - Len(test$));
  EndIf

  Local num_tests% = list.size%(ut.test_names$())
  If num_failed_tests% = 0 Then
    ut.print_colour("green")
    Print "PASS (" Str$(num_tests%) "/" Str$(num_tests%) ")";
  Else
    ut.print_colour("red")
    Print "FAIL (" Str$(num_failed_tests%) "/" Str$(num_tests%) ")";
  EndIf
  ut.print_colour("reset")
  Print

  If repeat$ <> "" Then
    ut.run_same(repeat$)
  ElseIf InStr(Mm.CmdLine$, "--all") Then
    ut.run_next()
  EndIf
End Sub

' Should verbose output be generated?
Function ut.is_verbose%()
  ut.is_verbose% = InStr(" " + Mm.CmdLine$ + " ", " --all ") < 1 
  If Not ut.is_verbose% Then ut.is_verbose% = InStr(" " + Mm.CmdLine$ + " ", " --verbose ") > 0 
End Function

' Should MMBasic errors be caught and reported as assertion failures?
Function ut.is_catch_errors%()
  ut.is_catch_errors% = InStr(" " + Mm.CmdLine$ + " ", " --catch-errors ")
End Function

Sub add_mmbasic_error()
  Local i% = InStr(Mm.ErrMsg$, "Error")
  ut.add_failure("MMBasic " + Mid$(Mm.ErrMsg$, i%))
End Sub

' First:  creates the file "/tmp/sptest.list" containing the full paths (one per line)
'         of each sptest suite/file found by walking the file-system from the current
'         working directory.
' Second: executes the first sptest suite/file found.

Sub ut.run_first()
  Print "Building list of tests ..."
  Open "/tmp/sptest.lst" For Output As #1
  Local f$ = fil.find$(Cwd$, "*st*.bas", "file")
  Local first$
  Do While f$ <> ""
    If ut.is_test_file%(f$) Then
      Print #1, f$
      If first$ = "" Then first$ = f$
    EndIf
    f$ = fil.find$()
  Loop
  Close #1

  If first$ = "" Then
    Print "No tests found."
    End
  Else
    Print "Executing tests ..."
    Local cmd$ = "Run " + Chr$(34) + first$ + Chr$(34) + ", --all"
    If InStr(" " + Mm.CmdLine$ + " ", " --catch-errors") Then Cat cmd$, " --catch-errors"
    If InStr(" " + Mm.CmdLine$ + " ", " --verbose ")     Then Cat cmd$, " --verbose"
    Execute cmd$
  EndIf
End Sub

Function ut.is_test_file%(f$)
  Local name$ = fil.get_name$(f$)

  ' Check name matches pattern for sptest files.
  If fil.fnmatch%("test_*.bas", name$) Then ut.is_test_file% = 1
  If fil.fnmatch%("tst_*.bas", name$) Then ut.is_test_file% = 1
  If fil.fnmatch%("*_test.bas", name$) Then ut.is_test_file% = 1
  If fil.fnmatch%("*_tst*.bas", name$) Then ut.is_test_file% = 1

  If Not ut.is_test_file% Then Exit Function

  ' Scan first 50 lines of file for #Include of "unittest.inc".
  Local i%, s$
  ut.is_test_file% = 0
  Open f$ For Input As #2
  For i% = 1 To 50
    If Eof(#2) Then Exit For
    Line Input #2, s$
    If fil.fnmatch%("*#include*unittest.inc*", s$) Then ut.is_test_file% = 1 : Exit For
  Next
  Close #2

End Function

Sub ut.run_next()
  Local f$
  Open "/tmp/sptest.lst" For Input As #1

  Do
    Line Input #1, f$
    If f$ = Mm.Info$(Current) Then Exit Do
  Loop While Not Eof(#1)

  If Eof(#1) Then
    Close #1
  Else
    Line Input #1, f$
    Close #1
    Local cmd$ = "Run " + Chr$(34) + f$ + Chr$(34) + ", --all"
    If ut.is_catch_errors%() Then Cat cmd$, " --catch-errors"
    If ut.is_verbose%()      Then Cat cmd$, " --verbose"
    Execute cmd$
  EndIf
End Sub

' Runs the current test file again appending 'cmd$' to its command line.
Sub ut.run_same(cmd$)
  Local tgt$ = "Run " + Chr$(34) + Mm.Info(Current) + Chr$(34) + ", "
  If Mm.CmdLine$ <> "" Then tgt$ = tgt$ + Mm.CmdLine$ + " "
  tgt$ = tgt$ + cmd$
  Execute tgt$
End Sub

Sub ut.print_colour(c$)
  Option Console Serial
  Print vt100.colour$(c$);

  ' TODO: Should really restore the previous value of "Option Console",
  '       but currently that cannot be read.
  Option Console Both

  Select Case c$
    Case "green" : Colour(RGB(Green))
    Case "red"   : Colour(RGB(Red))
    Case "reset" : Colour(RGB(White))
    Case Else    : Error "unsupported colour: " + c$
  End Select
End Sub

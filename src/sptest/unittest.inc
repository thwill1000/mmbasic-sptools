' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.requires("array", "file", "list", "string", "vt100")
sys.provides("unittest")
If sys.err$ <> "" Then Error sys.err$
'!endif

If sys.is_platform%("mmb4w") Then Option Console Both

Const TMPDIR$ = ut.get_tmp_dir$() ' Test specific temporary directory.

Const ut.MAX_FAILURES% = 20 ' Maximum number of failures reported per test method.
Const ut.MAX_TESTS% = 100
Const ut.MAX_ARRAY_DIFFS% = 5

Dim ut.asserts_count%
Dim ut.failure_count%
Dim ut.failure_len%(array.new%(ut.MAX_FAILURES%))
Dim ut.failure_start%(array.new%(ut.MAX_FAILURES%))
Dim ut.failure_txt%(1000)
Dim ut.test_names$(list.new%(ut.MAX_TESTS%)) Length 128
Dim ut.test_subs$(list.new%(ut.MAX_TESTS%)) Length 40

list.init(ut.test_names$())
list.init(ut.test_subs$())

Function ut.get_tmp_dir$()
  Const stem$ = Choice(InStr(Mm.CmdLine$, "--drive=b"), "B:/tmp", sys.TMPDIR$())
  Const name$ = file.trim_extension$(file.get_name$(Mm.Info(Current)))
  ut.get_tmp_dir$ = stem$ + file.SEPARATOR + name$
End Function

Sub add_test(name$, sub$)
  list.add(ut.test_names$(), name$)
  list.add(ut.test_subs$(), Choice(sub$ = "", name$, sub$))
End Sub

Sub ut.add_failure(msg$)
  Inc ut.failure_count%
  If ut.failure_count% <= ut.MAX_FAILURES% Then
    ut.failure_start%(ut.failure_count% + Mm.Info(Option Base) - 1) = LLen(ut.failure_txt%()) + 1
    LongString Append ut.failure_txt%(), Str$(ut.asserts_count%) + ": " + msg$
    ut.update_failure()
  EndIf
End Sub

Sub ut.update_failure()
  If ut.failure_count% <= ut.MAX_FAILURES% Then
    Local i% = ut.failure_count% + Mm.Info(Option Base) - 1
    ut.failure_len%(i%) = LLen(ut.failure_txt%()) - ut.failure_start%(i%) + 1
  EndIf
End Sub

Sub assert_fail(msg$)
  Inc ut.asserts_count%
  ut.add_failure(msg$)
End Sub

Sub assert_false(z%, msg$)
  Inc ut.asserts_count%
  If z% Then ut.add_failure(Choice(msg$ = "", "assert_false() failed", msg$))
End Sub

Sub assert_true(z%, msg$)
  Inc ut.asserts_count%
  If Not z% Then ut.add_failure(Choice(msg$ = "", "assert_true() failed", msg$))
End Sub

Sub assert_hex_equals(expected%, actual%, chars%)
  Inc ut.asserts_count%
  If expected% <> actual% Then
    Local s$
    Cat s$, "Assert equals failed, expected &h"
    Cat s$, Hex$(expected%, chars%)
    Cat s$, " but actually &h"
    Cat s$, Hex$(actual%, chars%)
    ut.add_failure(s$)
  EndIf
End Sub

Sub assert_int_equals(expected%, actual%)
  Inc ut.asserts_count%
  If expected% <> actual% Then
    Local s$ = "Assert equals failed, expected " + Str$(expected%)
    s$ = s$ + " but actually " + Str$(actual%)
    ut.add_failure(s$)
  EndIf
End Sub

Sub assert_int_neq(unexpected%, actual%)
  Inc ut.asserts_count%
  If unexpected% = actual% Then
    Local s$ = "Assert not equals failed, did not expect " + Str$(unexpected%)
    ut.add_failure(s$)
  EndIf
End Sub

Sub assert_float_equals(expected!, actual!, delta!)
  Inc ut.asserts_count%
  If Not equals_float%(expected!, actual!, delta!) Then
    Local s$ = "Assert equals failed, expected " + Str$(expected!)
    s$ = s$ + " but actually " + Str$(actual!)
    ut.add_failure(s$)
  EndIf
End Sub

Function equals_float%(a!, b!, delta!)
  equals_float% = (a! >= b! - delta!) And (a! <= b! + delta!)
End Function

Sub assert_string_equals(expected_$, actual_$)
  Inc ut.asserts_count%
  If expected_$ <> actual_$ Then
    Local expected$ = str.quote$(expected_$)
    Local actual$ = str.quote$(actual_$)
    If Len(expected_$) = 1 Then expected$ = "Chr$(" + Str$(Asc(expected_$)) + ")"
    If Len(actual_$) = 1 Then actual$ = "Chr$(" + Str$(Asc(actual_$)) + ")"

    ut.add_failure("Assert equals failed, expected ")
    LongString Append ut.failure_txt%(), ut.sanitise_string$(expected$)
    LongString Append ut.failure_txt%(), " but actually "
    LongString Append ut.failure_txt%(), ut.sanitise_string$(actual$)
    ut.update_failure()
  EndIf
End Sub

Function ut.sanitise_string$(s$)
  Local c%, i%, s2$
  For i% = 1 To Len(s$)
    c% = Peek(Var s$, i%)
    Cat s2$, Choice(c% < 32 Or c% > 126, "<" + Str$(c%) + ">", Chr$(c%))
  Next
  ut.sanitise_string$ = s2$
End Function

Sub assert_string_neq(unexpected$, actual$)
  Inc ut.asserts_count%
  If unexpected$ = actual$ Then
    Const s$ = Choice(Len(actual$) = 1, "Chr$(" + Str$(Asc(actual$)) + ")", str.quote$(actual$))
    ut.add_failure("Assert not equals failed, did not expect ")
    LongString Append ut.failure_txt%(), ut.sanitise_string$(s$)
    ut.update_failure()
  EndIf
End Sub

Sub assert_int_array_equals(expected%(), actual%(), use_hex%)
  Inc ut.asserts_count%

  If Bound(expected%(), 1) <> Bound(actual%(), 1) Then
    ut.add_array_size_failure(Bound(expected%(), 1), Bound(actual%(), 1))
    Exit Sub
  EndIf

  Local count%, i%, j% = Mm.Info(Option Base)
  Local indexes%(array.new%(ut.MAX_ARRAY_DIFFS%))
  Local e$(array.new%(ut.MAX_ARRAY_DIFFS%))
  Local a$(array.new%(ut.MAX_ARRAY_DIFFS%))

  For i% = Bound(expected%(), 0) To Bound(expected%(), 1)
    If expected%(i%) = actual%(i%) Then Continue For
    Inc count%
    If count% > ut.MAX_ARRAY_DIFFS% Then Continue For
    indexes%(j%) = i%
    e$(j%) = Choice(use_hex%, "&h" + Hex$(expected%(i%), 16), Str$(expected%(i%)))
    a$(j%) = Choice(use_hex%, "&h" + Hex$(actual%(i%), 16), Str$(actual%(i%)))
    Inc j%
  Next

  If count% > 0 Then ut.add_array_content_failure(count%, indexes%(), e$(), a$())
End Sub

Sub ut.add_array_size_failure(expected_size%, actual_size%)
  Local msg$ = "Assert array equals failed, expected size "
  Cat msg$, Str$(expected_size%)
  Cat msg$, " but was "
  Cat msg$, Str$(actual_size%)
  ut.add_failure(msg$)
End Sub

Sub ut.add_array_content_failure(count%, indexes%(), e$(), a$())
  Local i%, width%
  Local lb% = Bound(indexes%(), 0)
  Local ub% = Min(count% + lb% - 1, Bound(indexes%(), 1))
  For i% = lb% To ub%
    width% = Max(width%, Len(Str$(indexes%(i%))))
  Next

  ut.add_failure("Assert array equals failed, expected:")
  For i% = lb% To ub%
    ut.array_diff(width%, indexes%(i%), e$(i%))
  Next
  ut.and_more(count%)

  LongString Append ut.failure_txt%(), sys.CRLF$ + "    but actually:")
  For i% = lb% To ub%
    ut.array_diff(width%, indexes%(i%), a$(i%))
  Next
  ut.and_more(count%)

  ut.update_failure()
End Sub

Sub ut.array_diff(width%, index%, value$)
  LongString Append ut.failure_txt%(), sys.CRLF$
  LongString Append ut.failure_txt%(), Format$(index%, "      [%" + Str$(width%) + ".0f] ")
  LongString Append ut.failure_txt%(), value$
End Sub

Sub ut.and_more(count%)
  If count% <= ut.MAX_ARRAY_DIFFS% Then Exit Sub
  LongString Append ut.failure_txt%(), sys.CRLF$
  LongString Append ut.failure_txt%(), "      ... and "
  LongString Append ut.failure_txt%(), Str$(count% - ut.MAX_ARRAY_DIFFS%)
  LongString Append ut.failure_txt%(), " more"
End Sub

Sub assert_float_array_equals(expected!(), actual!(), delta!())
  Inc ut.asserts_count%

  If Bound(expected!(), 1) <> Bound(actual!(), 1) Then
    ut.add_array_size_failure(Bound(expected!(), 1), Bound(actual!(), 1))
    Exit Sub
  EndIf

  Local count%, i%, j% = Mm.Info(Option Base)
  Local indexes%(array.new%(ut.MAX_ARRAY_DIFFS%))
  Local e$(array.new%(ut.MAX_ARRAY_DIFFS%))
  Local a$(array.new%(ut.MAX_ARRAY_DIFFS%))

  For i% = Bound(expected!(), 0) To Bound(expected!(), 1)
    If equals_float%(expected!(i%), actual!(i%), delta!(i%)) Then Continue For
    Inc count%
    If count% > ut.MAX_ARRAY_DIFFS% Then Continue For
    indexes%(j%) = i%
    e$(j%) = Str$(expected!(i%))
    a$(j%) = Str$(actual!(i%))
    Inc j%
  Next

  If count% > 0 Then ut.add_array_content_failure(count%, indexes%(), e$(), a$())
End Sub

Sub assert_string_array_equals(expected$(), actual$())
  Inc ut.asserts_count%

  If Bound(expected$(), 1) <> Bound(actual$(), 1) Then
    ut.add_array_size_failure(Bound(expected$(), 1), Bound(actual$(), 1))
    Exit Sub
  EndIf

  Local count%, i%, j% = Mm.Info(Option Base)
  Local indexes%(array.new%(ut.MAX_ARRAY_DIFFS%))
  Local e$(array.new%(ut.MAX_ARRAY_DIFFS%))
  Local a$(array.new%(ut.MAX_ARRAY_DIFFS%))

  For i% = Bound(expected$(), 0) To Bound(expected$(), 1)
    If expected$(i%) = actual$(i%) Then Continue For
    Inc count%
    If count% > ut.MAX_ARRAY_DIFFS% Then Continue For
    indexes%(j%) = i%
    e$(j%) = str.quote$(ut.sanitise_string$(expected$(i%)))
    a$(j%) = str.quote$(ut.sanitise_string$(actual$(i%)))
    Inc j%
  Next

  If count% > 0 Then ut.add_array_content_failure(count%, indexes%(), e$(), a$())
End Sub

Sub assert_no_error()
  Inc ut.asserts_count%
  If sys.err$ <> "" Then
    ut.add_failure("Expected no error, but actually sys.err$ = " + str.quote$(sys.err$))
  EndIf

  ' CMM2 file operations set Mm.ErrMsg$ = "Success " including a space when they succeed.
  If Mm.ErrNo <> 0 Then
    ut.add_failure("Expected no error, but actually Mm.ErrMsg$ = " + str.quote$(Mm.ErrMsg$))
  EndIf
End Sub

Sub assert_error(expected$)
  Inc ut.asserts_count%
  If sys.err$ <> expected$ Then
    Local s$ = "Expected Error " + str.quote$(expected$) + ", but actually " + str.quote$(sys.err$)
    ut.add_failure(s$)
  EndIf
End Sub

Sub assert_raw_error(expected$)
  Inc ut.asserts_count%
  Local s$
  If Mm.ErrMsg$ = expected$ Then
    If Mm.ErrNo = 0 And expected$ <> "" Then
      Cat s$, "Expected Error " + str.quote$(expected$)
      Cat s$, ", but Mm.ErrNo = 0"
    EndIf
  Else If Not InStr(Mm.ErrMsg$, expected$) Then
    Cat s$, "Expected Error " + str.quote$(expected$)
    Cat s$, ", but actually " + str.quote$(Mm.ErrMsg$)
  EndIf
  If s$ <> "" Then ut.add_failure(s$)
End Sub

' Runs all the tests.
'
' If find$ is not empty then once complete the tests will be
' re-run with modified command line args, @see ut.run_same().
Sub run_tests(find$, replace$)
  Local num_failed_tests% = 0
  Local num_tests% = list.size%(ut.test_names$())
  Local test$ = Mm.Info$(Current) + " " + Mm.CmdLine$;

  Print test$;
  If ut.is_verbose%() Then Print

  Local t% = Timer

  Local i%
  Local lb% = Mm.Info(Option Base)
  Local ub% = lb% + num_tests% - 1
  For i% = lb% To ub%
    If Not ut.run_single_test%(i%) Then Inc num_failed_tests%
  Next

  If ut.is_verbose%() Then
    Print "  Execution time: " Str$((Timer - t%) / 1000) " s"
    Print "  ";
  Else
    Print Space$(Max(1, 85 - Len(test$)));
  EndIf

  If num_tests% = 0 Then
    ut.print_colour("magenta")
    Print "NO TESTS";
  Else If num_failed_tests% = 0 Then
    ut.print_colour("green")
    Print "PASS (" Str$(num_tests%) "/" Str$(num_tests%) ")";
  Else
    ut.print_colour("red")
    Print "FAIL (" Str$(num_failed_tests%) "/" Str$(num_tests%) ")";
  EndIf
  ut.print_colour("reset")
  Print

  If Len(find$) Then
    ut.run_same(find$, replace$)
  ElseIf InStr(Mm.CmdLine$, "--all") Then
    ut.run_next()
  EndIf
End Sub

' @return 1 if the test passes, 0 if it fails.
Function ut.run_single_test%(idx%)
  Local catch_errors% = ut.is_catch_errors%()

  If ut.is_verbose%() Then
    Print "  " + ut.test_names$(idx%); ":"; Space$(Max(1, 50 - Len(ut.test_names$(idx%))));
  EndIf

  ut.asserts_count% = 0
  ut.failure_count% = 0
  LongString Clear ut.failure_txt%()

  ' Cache working directory and change drive.
  Const OLD_DIR = Cwd$
  If sys.is_platform%("pm*") And Mm.Info(Device X) <> "MMB4L" Then
    Const OLD_DRIVE = Mm.Info(Drive)
    Const NEW_DRIVE = Choice(InStr(Mm.CmdLine$, "--drive=b"), "B:", "A:")
    If Mm.Info$(Drive) <> NEW_DRIVE Then Drive NEW_DRIVE
  EndIf

  ' Remove TMPDIR if left behind by previous failure.
  If file.exists%(TMPDIR$) Then
    If file.delete%(TMPDIR$, 20) <> sys.SUCCESS Then Error sys.err$
  EndIf

  On Error Skip 1 ' Skip error caused by missing optional setup_test() function.
  setup_test()

  On Error Clear
  If catch_errors% Then On Error Ignore
  sys.err$ = ""
  Call ut.test_subs$(idx%)
  If catch_errors% And Mm.ErrNo <> 0 Then add_mmbasic_error()
  On Error Abort

  On Error Skip 1 ' Skip error caused by missing optional teardown_test() function.
  teardown_test()

  If ut.is_verbose%() Then
    If ut.asserts_count% = 0 Then
      ut.print_colour("magenta")
      Print "NO ASSERTIONS";
    Else If ut.failure_count% = 0 Then
      ut.print_colour("green")
      Print "PASS ("; Str$(ut.asserts_count%); "/"; Str$(ut.asserts_count%); ")";
    Else If ut.failure_count% > 0 Then
      ut.print_colour("red")
      Print "FAIL ("; Str$(ut.failure_count%); "/"; Str$(ut.asserts_count%); ")";
      Local i%, j%
      Local lb% = Mm.Info(Option Base)
      Local ub% = lb% + Min(ut.failure_count%, ut.MAX_FAILURES%) - 1
      For i% = lb% To ub%
        Print
        Print "    ";
        j% = ut.failure_start%(i%)
        Do
          Print LGetStr$(ut.failure_txt%(), j%, Min(255, ut.failure_len%(i%)));
          Inc j%, ut.failure_len%(i%)
        Loop While j% < ut.failure_len%(i%)
      Next
      If ut.failure_count% > ut.MAX_FAILURES% Then
        Print
        Print "    +" Str$(ut.failure_count% - ut.MAX_FAILURES%) + " more";
      EndIf
    EndIf
    ut.print_colour("reset")
    Print
  EndIf

  ' Cleanup TMPDIR.
  If file.exists%(TMPDIR$) Then
    If file.delete%(TMPDIR$, 20) <> sys.SUCCESS Then Error sys.err$
  EndIf

  ' Restore working directory and drive.
  If sys.is_platform%("pm*") And Mm.Info(Device X) <> "MMB4L" Then
    If Mm.Info(Drive) <> OLD_DRIVE Then Drive OLD_DRIVE
  EndIf
  If Cwd$ <> OLD_DIR Then ChDir OLD_DIR

  ut.run_single_test% = ut.failure_count% = 0
End Function

' Should verbose output be generated?
Function ut.is_verbose%()
  Local cmdline$ = " " + Mm.CmdLine$ + " "
  ut.is_verbose% = Not InStr(cmdline$, " --quiet ") And Not InStr(cmdline$, " -q ")
End Function

' Should MMBasic errors be caught and reported as assertion failures?
Function ut.is_catch_errors%()
  ut.is_catch_errors% = InStr(" " + Mm.CmdLine$ + " ", " --catch-errors ")
End Function

Sub add_mmbasic_error()
  Inc ut.asserts_count%
  ut.add_failure("MMBasic " + Mid$(Mm.ErrMsg$, InStr(Mm.ErrMsg$, "Error")))
End Sub

' First:  creates the file "/tmp/sptest.list" containing the full paths (one per line)
'         of each sptest suite/file found by walking the file-system from the current
'         working directory.
' Second: executes the first sptest suite/file found.

Sub ut.run_first()
  Print "Building list of tests ..."
  Open sys.TMPDIR$() + "/sptest.lst" For Output As #1
  Print #1, Time$
  Local f$ = file.find$(Cwd$, "*st*.bas", "file")
  Local first$
  Do While f$ <> ""
    If ut.is_test_file%(f$) Then
      Print #1, file.get_canonical$(f$)
      If first$ = "" Then first$ = f$
    EndIf
    f$ = file.find$()
  Loop
  Close #1

  If first$ = "" Then
    Print "No tests found."
    End
  Else
    Print "Executing tests ..."
    Local cmd$ = "Run " + str.quote$(first$) + ", --all"
    If InStr(" " + Mm.CmdLine$ + " ", " --catch-errors") Then Cat cmd$, " --catch-errors"
    If Not InStr(" " + Mm.CmdLine$ + " ", " --verbose ") Then Cat cmd$, " -q"
    Execute cmd$
  EndIf
End Sub

Function ut.is_test_file%(f$)
  Local name$ = file.get_name$(f$)

  ' Check name matches pattern for sptest files.
  If file.fnmatch%("test_*.bas", name$) Then ut.is_test_file% = 1
  If file.fnmatch%("tst_*.bas", name$) Then ut.is_test_file% = 1
  If file.fnmatch%("*_test.bas", name$) Then ut.is_test_file% = 1
  If file.fnmatch%("*_tst*.bas", name$) Then ut.is_test_file% = 1

  If Not ut.is_test_file% Then Exit Function

  ' Scan first 50 lines of file for #Include of "unittest.inc".
  Local i%, s$
  ut.is_test_file% = 0
  Open f$ For Input As #2
  For i% = 1 To 50
    If Eof(#2) Then Exit For
    Line Input #2, s$
    If file.fnmatch%("*#include*unittest.inc*", s$) Then ut.is_test_file% = 1 : Exit For
  Next
  Close #2

End Function

Function ut.parse_time%(t$)
  Inc ut.parse_time%, Val(Mid$(t$, 1, 2)) * 60 * 60
  Inc ut.parse_time%, Val(Mid$(t$, 4, 2)) * 60
  Inc ut.parse_time%, Val(Mid$(t$, 7, 2))
End Function

Sub ut.run_next()
  Local f$, start_time$
  Open sys.TMPDIR$() + "/sptest.lst" For Input As #1
  Line Input #1, start_time$

  Do
    Line Input #1, f$
    If f$ = file.get_canonical$(Mm.Info$(Current)) Then Exit Do
  Loop While Not Eof(#1)

  If Eof(#1) Then
    Close #1
    Local start% = ut.parse_time%(start_time$)
    Local end% = ut.parse_time%(Time$)
    Print "Total execution time: " + Str$(end% - start%) + " s"
  Else
    Line Input #1, f$
    Close #1
    Local cmd$ = "Run " + str.quote$(f$) + ", --all"
    If ut.is_catch_errors%() Then Cat cmd$, " --catch-errors"
    If Not ut.is_verbose%()  Then Cat cmd$, " -q"
    Execute cmd$
  EndIf
End Sub

' Re-runs the test program with modified command line args.
'
' If replace$ is not empty then replaces instances of find$ in Mm.CmdLine$ with
' replace$. If there are no instances then appends replace$ to Mm.CmdLine$.
' If replace$ is empty then appends find$ to Mm.CmdLine$.
Sub ut.run_same(find$, replace$)
  Local cmdline$ = Mm.CmdLine$
  If Len(replace$) Then
    cmdline$ = str.replace$(cmdline$, find$, replace$)
    If Not InStr(cmdline$, replace$) Then
      If Len(cmdline$) Then Cat cmdline$, " "
      Cat cmdline$, replace$
    EndIf
  Else
    If Len(cmdline$) Then Cat cmdline$, " "
    Cat cmdline$, find$
  EndIf

  If sys.is_platform%("cmm2*") Then
    Execute "Run " + str.quote$(Mm.Info$(Current)) + ", " + cmdline$
  Else
    Run Mm.Info$(Current), cmdline$
  EndIf
End Sub

Sub ut.print_colour(c$)
  If sys.is_platform%("pm*") Then
    Print vt100.colour$(c$);
    Exit Sub
  EndIf

  ' Serial / ANSI colour.
  Local old_console$ = Mm.Info(Option Console)
  If LCase$(old_console$) <> "serial" Then Option Console Serial
  Print vt100.colour$(c$);
  Select Case LCase$(old_console$)
    Case "both"   : Option Console Both
    Case "screen" : Option Console Screen
  End Select

  ' Screen / VGA colour.
  Select Case c$
    Case "green"   : Colour(RGB(Green))
    Case "magenta" : Colour(RGB(Magenta))
    Case "red"     : Colour(RGB(Red))
    Case "reset"   : Colour(RGB(White))
    Case Else      : Error "unsupported colour: " + c$
  End Select
End Sub

' Creates an empty file.
Sub ut.create_file(f$, fnbr%)
  Local fnbr_% = Choice(fnbr%, fnbr%, 1)
  Open f$ For Output As fnbr_%
  Close fnbr_%
End Sub

' Writes the contents of DATA to a file.
'
' @param  filename$    The file to write.
' @param  data_label$  Label from which to start reading DATA.
Sub ut.write_data_file(filename$, data_label$)
  Local s$, type$
  Read Save
  Restore data_label$
  Read type$
  Open filename$ For Output As #1
  Select Case type$
    Case "text/crlf", "text/lf", "text/json"
      Do
        Read s$
        If Right$(s$, 5) = "<EOF>" Then
          Print #1, Left$(s$, Len(s$) - 5);
          Exit Do
        ElseIf type$ = "text/crlf" Then
          Print #1, s$ + Chr$(13) + Chr$(10);
        ElseIf type$ = "text/lf" Then
          Print #1, s$ + Chr$(10);
        ElseIf type$ = "text/json" Then
          s$ = str.replace$(s$, "'", Chr$(34)) ' Convert single to double quotes.
          Print #1, s$ + Chr$(10);
        Else
          Error "Unknown text data type '" + type$ + "'"
        EndIf
      Loop
    Case Else
      Error "Unknown data type '" + type$ + "'"
  End Select
  Close #1
  Read Restore
End Sub

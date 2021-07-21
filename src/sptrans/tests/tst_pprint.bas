' Copyright (c) 2020-2021 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For Colour Maximite 2, MMBasic 5.07

Option Explicit On
Option Default Integer

Const MAX_NUM_FILES = 5
Dim in.num_open_files = 1

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
#Include "../options.inc"

' Stub "../output.inc"
Dim out.buf$

Sub out.endl()
  out.print(sys.CRLF$)
End Sub

Sub out.print(s$)
  If out.buf$ = Chr$(0) Then out.buf$ = ""
  Cat out.buf$, s$
End Sub

sys.provides("output")

#Include "../pprint.inc"

Dim expected$(19)
Dim in$(19)
Dim out$(19)

keywords.load()

add_test("Indenting - multi-line IF THEN increases", "test_indentation_1")
add_test("Indenting - single-line IF THEN does not change", "test_indentation_2")
add_test("Indenting - CONTINUE FOR does not change", "test_indentation_3")
add_test("Indenting - END SUB decreases", "test_indentation_4")
add_test("Indenting - END FUNCTION decreases", "test_indentation_5")
add_test("Indenting - EXIT FOR does not change", "test_indentation_6")
add_test("Indenting - EXIT FUNCTION does not change", "test_indentation_7")
add_test("Indenting - EXIT SUB does not change", "test_indentation_8")
add_test("Indenting - SELECT CASE increases", "test_indentation_9")
add_test("Indenting - body of CSUB is indented", "test_indentation_10")
add_test("Indenting - line numbers not indented", "test_indentation_11")
add_test("Omission of comments", "test_comments_1")
add_test("Spacing - preserve option", "test_preserve_spacing")
add_test("Spacing - minimal option", "test_minimal_spacing")
add_test("Spacing - compact option", "test_compact_spacing")
add_test("Spacing - generous option", "test_generous_spacing")
add_test("Spacing - before comments", "test_comment_spacing")
add_test("Keyword capitalisation", "test_keyword_capitalisation")
add_test("Syntax highlighting - CSUBs", "test_syntax_highlight_1")
add_test("Syntax highlighting - comments", "test_syntax_highlight_2")
add_test("Empty lines - preserve if empty-lines option is -1", "test_empty_lines_1")
add_test("Empty lines - ignore if empty-lines option is 0", "test_empty_lines_2")

run_tests()

End

Sub setup_test()
  opt.init()
  out.buf$ = ""
  pp.indent_lvl = 0
  Local i%
  For i% = Bound(in$(), 0) To Bound(in$(), 1)
    expected$(i%) = ""
    in$(i%) = ""
    out$(i%) = ""
  Next
End Sub

Sub teardown_test()
End Sub

Sub parse_lines()
  Local i%, j% = Mm.Info(Option Base)
  pp.previous = 0
  pp.indent_lvl = 0
  For i% = Bound(in$(), 0) To Bound(in$(), 1)
    out.buf$ = Chr$(0)
    lx.parse_basic(in$(i%))
    pp.print_line()
    If out.buf$ <> Chr$(0) Then
      out$(j%) = out.buf$
      ' Trim trailing CRLF.
      If Right$(out$(j%), 2) = sys.CRLF$ Then out$(j%) = Left$(out$(j%), Len(out$(j%)) - 2)
      Inc j%
    EndIf
  Next
End Sub

' Test omission of comments.
Sub test_comments_1()
  in$(0) = "' comment 1"
  in$(1) = "  ' comment 2"
  in$(2) = "If a = b Then REM comment 3"
  in$(3) = "  Print c ' comment 4"
  in$(4) = "EndIf ' comment 5"
  in$(5) = "REM comment 6"

  opt.comments = 0
  parse_lines()

  expected$(0) = ""
  expected$(1) = ""
  expected$(2) = "If a = b Then"
  expected$(3) = "  Print c"
  expected$(4) = "EndIf"
  expected$(5) = ""
  assert_string_array_equals(expected$(), out$())
End Sub

' Test multi-line IF THEN increases indent level.
Sub test_indentation_1()
  in$(0) = "If a = b Then"
  in$(1) = "Print c"
  in$(2) = "EndIf"

  opt.indent_sz = 2
  parse_lines()

  expected$(0) = "If a = b Then"
  expected$(1) = "  Print c"
  expected$(2) = "EndIf"
  assert_string_array_equals(expected$(), out$())
End Sub

' Test single-line IF THEN does not change indent level.
Sub test_indentation_2()
  in$(0) = "If a = b Then c = d"
  in$(1) = "Print c"

  opt.indent_sz = 2
  parse_lines()

  expected$(0) = "If a = b Then c = d"
  expected$(1) = "Print c"
  assert_string_array_equals(expected$(), out$())
End Sub

' Test CONTINUE FOR does not change indent level.
Sub test_indentation_3()
  in$(0) = "If 1 Then"
  in$(1) = "If a = b Then"
  in$(2) = "Continue For"
  in$(3) = "EndIf"
  in$(4) = "EndIf"

  opt.indent_sz = 2
  parse_lines()

  expected$(0) = "If 1 Then"
  expected$(1) = "  If a = b Then"
  expected$(2) = "    Continue For"
  expected$(3) = "  EndIf"
  expected$(4) = "EndIf"
  assert_string_array_equals(expected$(), out$())
End Sub

' Test END SUB decreases indent level.
Sub test_indentation_4()
  in$(0) = "Sub foo()"
  in$(1) = "Print a"
  in$(2) = "End Sub"
  in$(3) = "Print b"

  opt.indent_sz = 2
  parse_lines()

  expected$(0) = "Sub foo()"
  expected$(1) = "  Print a"
  expected$(2) = "End Sub"
  expected$(3) = "Print b"
  assert_string_array_equals(expected$(), out$())
End Sub

' Test END FUNCTION decreases indent level.
Sub test_indentation_5()
  in$(0) = "Function foo()"
  in$(1) = "Print a"
  in$(2) = "End Function"
  in$(3) = "Print b"

  opt.indent_sz = 2
  parse_lines()

  expected$(0) = "Function foo()"
  expected$(1) = "  Print a"
  expected$(2) = "End Function"
  expected$(3) = "Print b"
  assert_string_array_equals(expected$(), out$())
End Sub

' Test EXIT FOR does not change indent level.
Sub test_indentation_6()
  in$(0) = "If 1 Then"
  in$(1) = "If a = b Then"
  in$(2) = "Exit For"
  in$(3) = "EndIf"
  in$(4) = "EndIf"

  opt.indent_sz = 2
  parse_lines()

  expected$(0) = "If 1 Then"
  expected$(1) = "  If a = b Then"
  expected$(2) = "    Exit For"
  expected$(3) = "  EndIf"
  expected$(4) = "EndIf"
  assert_string_array_equals(expected$(), out$())
End Sub

' Test EXIT FUNCTION does not change indent level.
Sub test_indentation_7()
  in$(0) = "If 1 Then"
  in$(1) = "If a = b Then"
  in$(2) = "Exit Function"
  in$(3) = "EndIf"
  in$(4) = "EndIf"

  opt.indent_sz = 2
  parse_lines()

  expected$(0) = "If 1 Then"
  expected$(1) = "  If a = b Then"
  expected$(2) = "    Exit Function"
  expected$(3) = "  EndIf"
  expected$(4) = "EndIf"
  assert_string_array_equals(expected$(), out$())
End Sub

' Test EXIT SUB does not change indent level.
Sub test_indentation_8()
  in$(0) = "If 1 Then"
  in$(1) = "If a = b Then"
  in$(2) = "Exit Sub"
  in$(3) = "EndIf"
  in$(4) = "EndIf"

  opt.indent_sz = 2
  parse_lines()

  expected$(0) = "If 1 Then"
  expected$(1) = "  If a = b Then"
  expected$(2) = "    Exit Sub"
  expected$(3) = "  EndIf"
  expected$(4) = "EndIf"
  assert_string_array_equals(expected$(), out$())
End Sub

' Test SELECT CASE increases indent level.
Sub test_indentation_9()
  in$(0)  = "If 1 Then"
  in$(1)  = "Select Case a"
  in$(2)  = "Case 1"
  in$(3)  = "Print 1"
  in$(4)  = "Case 2 : Print 2"
  in$(5)  = "Case 3"
  in$(6)  = "Print 3"
  in$(7)  = "Case Else"
  in$(8)  = "Print 4"
  in$(9)  = "Case Else : Print 5" ' Not actually legal BASIC to have two Case Else's
  in$(10) = "End Select"
  in$(11) = "EndIf"

  opt.indent_sz = 2
  parse_lines()

  expected$(0)  = "If 1 Then"
  expected$(1)  = "  Select Case a"
  expected$(2)  = "    Case 1"
  expected$(3)  = "      Print 1"
  expected$(4)  = "    Case 2 : Print 2"
  expected$(5)  = "    Case 3"
  expected$(6)  = "      Print 3"
  expected$(7)  = "    Case Else"
  expected$(8)  = "      Print 4"
  expected$(9)  = "    Case Else : Print 5"
  expected$(10) = "  End Select"
  expected$(11) = "EndIf"
  assert_string_array_equals(expected$(), out$())
End Sub

' Test indentation of CSUB structure.
Sub test_indentation_10()
  in$(0) = "CSub foo()"
  in$(1) = "00000000"
  in$(2) = "00AABBCC FFFFFFFF"
  in$(3) = "End CSub"
  in$(4) = "x = x + 1 ' something at global level"

  opt.indent_sz = 2
  parse_lines()

  expected$(0) = "CSub foo()"
  expected$(1) = "  00000000"
  expected$(2) = "  00AABBCC FFFFFFFF"
  expected$(3) = "End CSub"
  expected$(4) = in$(4)
  assert_string_array_equals(expected$(), out$())
End Sub

' Test indentation of line numbers.
Sub test_indentation_11()

  ' Line numbers left-padded to 6 characters.
  in$(0) = "1 foo"
  in$(1) = "12 foo"
  in$(2) = "1234 foo"
  in$(3) = "12345 foo"
  in$(4) = "123456 foo"
  in$(5) = "1234567 foo"

  opt.indent_sz = 2
  parse_lines()

  expected$(0) = "     1 foo"
  expected$(1) = "    12 foo"
  expected$(2) = "  1234 foo"
  expected$(3) = " 12345 foo"
  expected$(4) = "123456 foo"
  expected$(5) = "1234567 foo"
  assert_string_array_equals(expected$(), out$())

  ' Line numbers not indented, but subsequent tokens are.
  setup_test()

  in$(0) = "10 For i% = 1 To 5"
  in$(1) = "20 If a% = b% Then
  in$(2) = "30 foo"
  in$(3) = "40 EndIf"
  in$(4) = "50 Next"

  opt.indent_sz = 2
  parse_lines()

  expected$(0) = "    10 For i% = 1 To 5"
  expected$(1) = "    20   If a% = b% Then
  expected$(2) = "    30     foo"
  expected$(3) = "    40   EndIf"
  expected$(4) = "    50 Next"
  assert_string_array_equals(expected$(), out$())
End Sub

' Test preserve spacing option.
Sub test_preserve_spacing()
  opt.spacing = -1
  setup_spacing_test()

  parse_lines()

  expected$(0) = "Dim  a  =  -5"
  expected$(1) = "If  a  >  -1  Then"
  expected$(2) = "If  a  <  -1  Then"
  expected$(3) = "If  a  <>  -1  Then"
  expected$(4) = "If  (a  <  0)  Or  (b  >  1)  Then"
  expected$(5) = "ElseIf  (a  <  0)  And  (b  >  1)  Then"
  expected$(6) = "x  =  myfun(a)    ' comment"
  expected$(7) = "    ' comment"
  expected$(8) = "myfun(a,  ,  b)"
  expected$(9) = "Dim  a(4)  =  (-2,  -1,  0,  1,  2)"
  expected$(10) = "For  i%  =  5  To  1  Step  -1"
  expected$(11) = "Loop Until  (  -a  >  -b  )"
  expected$(12) = "label: foo  :  bar"
  assert_string_array_equals(expected$(), out$())
End Sub

Sub setup_spacing_test()
  in$(0) = "Dim  a  =  -5"
  in$(1) = "If  a  >  -1  Then"
  in$(2) = "If  a  <  -1  Then"
  in$(3) = "If  a  <>  -1  Then"
  in$(4) = "If  (a  <  0)  Or  (b  >  1)  Then"
  in$(5) = "ElseIf  (a  <  0)  And  (b  >  1)  Then"
  in$(6) = "x  =  myfun(a)    ' comment"
  in$(7) = "    ' comment"
  in$(8) = "myfun(a,  ,  b)"
  in$(9) = "Dim  a(4)  =  (-2,  -1,  0,  1,  2)"
  in$(10) = "For  i%  =  5  To  1  Step  -1"
  in$(11) = "Loop Until  (  -a  >  -b  )"
  in$(12) = "label: foo  :  bar"
End Sub

' Test minimal spacing option.
Sub test_minimal_spacing()
  opt.spacing = 0
  setup_spacing_test()

  parse_lines()

  expected$(0) = "Dim a=-5"
  expected$(1) = "If a>-1 Then"
  expected$(2) = "If a<-1 Then"
  expected$(3) = "If a<>-1 Then"
  expected$(4) = "If(a<0)Or(b>1)Then"
  expected$(5) = "ElseIf(a<0)And(b>1)Then"
  expected$(6) = "x=myfun(a)    ' comment"
  expected$(7) = "    ' comment"
  expected$(8) = "myfun(a,,b)"
  expected$(9) = "Dim a(4)=(-2,-1,0,1,2)"
  expected$(10) = "For i%=5 To 1 Step-1"
  expected$(11) = "Loop Until(-a>-b)"
  expected$(12) = "label: foo:bar"
  assert_string_array_equals(expected$(), out$())
End Sub

' Test compact spacing option.
Sub test_compact_spacing()
  opt.spacing = 1
  setup_spacing_test()

  parse_lines()

  expected$(0) = "Dim a=-5"
  expected$(1) = "If a>-1 Then"
  expected$(2) = "If a<-1 Then"
  expected$(3) = "If a<>-1 Then"
  expected$(4) = "If (a<0) Or (b>1) Then"
  expected$(5) = "ElseIf (a<0) And (b>1) Then"
  expected$(6) = "x=myfun(a)    ' comment"
  expected$(7) = "    ' comment"
  expected$(8) = "myfun(a,,b)"
  expected$(9) = "Dim a(4)=(-2,-1,0,1,2)"
  expected$(10) = "For i%=5 To 1 Step -1"
  expected$(11) = "Loop Until (-a>-b)"
  expected$(12) = "label: foo : bar"
  assert_string_array_equals(expected$(), out$())
End Sub

' Test generous spacing option.
Sub test_generous_spacing()
  opt.spacing = 2
  setup_spacing_test()

  parse_lines()

  expected$(0) = "Dim a = -5"
  expected$(1) = "If a > -1 Then"
  expected$(2) = "If a < -1 Then"
  expected$(3) = "If a <> -1 Then"
  expected$(4) = "If (a < 0) Or (b > 1) Then"
  expected$(5) = "ElseIf (a < 0) And (b > 1) Then"
  expected$(6) = "x = myfun(a)    ' comment"
  expected$(7) = "    ' comment"
  expected$(8) = "myfun(a, , b)"
  expected$(9) = "Dim a(4) = (-2, -1, 0, 1, 2)"
  expected$(10) = "For i% = 5 To 1 Step -1"
  expected$(11) = "Loop Until (-a > -b)"
  expected$(12) = "label: foo : bar"
  assert_string_array_equals(expected$(), out$())
End Sub

Sub test_comment_spacing()
  in$(0) = "foo'comment1"
  in$(1) = "bar    ' comment2"

  opt.spacing = -1
  parse_lines()
  expected$(0) = "foo'comment1"
  expected$(1) = "bar    ' comment2"
  assert_string_array_equals(expected$(), out$())

  opt.spacing = 0
  parse_lines()
  expected$(0) = "foo'comment1"
  expected$(1) = "bar    ' comment2"
  assert_string_array_equals(expected$(), out$())

  opt.spacing = 1
  parse_lines()
  expected$(0) = "foo 'comment1"
  expected$(1) = "bar    ' comment2"
  assert_string_array_equals(expected$(), out$())

  opt.spacing = 2
  parse_lines()
  expected$(0) = "foo 'comment1"
  expected$(1) = "bar    ' comment2"
  assert_string_array_equals(expected$(), out$())
End Sub

' Test keyword capitalisation.
Sub test_keyword_capitalisation()
  in$(0) = "FOr i=20 TO 1 StEP -2"

  opt.keywords = -1 ' preserve capitalisation.
  parse_lines()
  expected$(0) = "FOr i=20 TO 1 StEP -2"
  assert_string_array_equals(expected$(), out$())

  opt.keywords = 0 ' lower-case.
  parse_lines()
  expected$(0) = "for i=20 to 1 step -2"
  assert_string_array_equals(expected$(), out$())

  opt.keywords = 1 ' pascal-case.
  parse_lines()
  expected$(0) = "For i=20 To 1 Step -2"
  assert_string_array_equals(expected$(), out$())

  opt.keywords = 2 ' upper-case.
  parse_lines()
  expected$(0) = "FOR i=20 TO 1 STEP -2"
  assert_string_array_equals(expected$(), out$())
End Sub

' Test syntax highlighting within CSUB.
Sub test_syntax_highlight_1()
  in$(0) = "CSub abcdef()"
  in$(1) = "  00000000"
  in$(2) = "  00AABBCC FFFFFFFF"
  in$(3) = "  ' comment"
  in$(5) = "  not_valid = 5"
  in$(6) = "  not_valid_either = " + Chr$(34) + "wombat" + Chr$(34)
  in$(7) = "End CSub"

  opt.colour = 1
  parse_lines()

  Const cy$ = vt100.colour$("cyan")
  Const gr$ = vt100.colour$("green")
  Const ma$ = vt100.colour$("magenta")
  Const rs$ = vt100.colour$("reset")
  Const wh$ = vt100.colour$("white")
  Const ye$ = vt100.colour$("yellow")
  expected$(0) = cy$ + "CSub " + wh$ + "abcdef" + wh$ +"(" + wh$ + ")" + rs$
  expected$(1) = "  " + gr$ + "00000000" + rs$
  expected$(2) = "  " + gr$ + "00AABBCC " + gr$ + "FFFFFFFF" + rs$
  expected$(3) = "  " + ye$ + "' comment" + rs$
  expected$(5) = "  " + wh$ + "not_valid " + wh$ + "= " + gr$ + "5" + rs$
  expected$(6) = "  " + wh$ + "not_valid_either " + wh$ + "= " + ma$ + Chr$(34) + "wombat" + Chr$(34) + rs$
  expected$(7) = cy$ + "End " + cy$ + "CSub" + rs$
  assert_string_array_equals(expected$(), out$())
End Sub

' Test syntax highlighting of comments.
Sub test_syntax_highlight_2()
  in$(0) = "' Comment 1"
  in$(1) = "foo 'Comment2"
  in$(2) = "bar REM Comment 3"

  opt.colour = 1
  parse_lines()

  Const rs$ = vt100.colour$("reset")
  Const wh$ = vt100.colour$("white")
  Const ye$ = vt100.colour$("yellow")
  expected$(0) = ye$ + "' Comment 1" + rs$
  expected$(1) = wh$ + "foo " + ye$ + "'Comment2" + rs$
  expected$(2) = wh$ + "bar " + ye$ + "REM Comment 3" + rs$
  assert_string_array_equals(expected$(), out$())
End Sub

' Empty lines - preserve if empty-lines option is -1.
Sub test_empty_lines_1()
  in$(0) = ""
  in$(1) = "foo"
  in$(2) = ""
  in$(3) = ""
  in$(4) = "bar"
  in$(5) = ""

  opt.empty_lines = -1
  parse_lines()

  expected$(0) = ""
  expected$(1) = "foo"
  expected$(2) = ""
  expected$(3) = ""
  expected$(4) = "bar"
  expected$(5) = ""
  assert_string_array_equals(expected$(), out$())
End Sub

' Empty lines - ignore if empty-lines option is 0.
Sub test_empty_lines_2()
  in$(0) = ""
  in$(1) = "foo"
  in$(2) = ""
  in$(3) = ""
  in$(4) = "bar"
  in$(5) = ""

  opt.empty_lines = 0
  parse_lines()

  expected$(0) = "foo"
  expected$(1) = "bar"
  assert_string_array_equals(expected$(), out$())
End Sub

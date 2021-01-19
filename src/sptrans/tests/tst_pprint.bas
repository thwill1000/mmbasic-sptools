' Copyright (c) 2020-2021 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.06

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
#Include "../keywords.inc"
#Include "../lexer.inc"
#Include "../options.inc"

' Stub "../output.inc"
Dim out.buf$

Sub out.endl()
  Cat out.buf$, sys.CRLF$
End Sub

Sub out.print(s$)
  Cat out.buf$, s$
End Sub

sys.provides("output")

#Include "../pprint.inc"

Dim expected$(19)
Dim in$(19)
Dim out$(19)

keywords.load("\sptools\resources\keywords.txt")

add_test("Multi-line IF THEN increases indent level", "test_indentation_1")
add_test("Single-line IF THEN does not change indent level", "test_indentation_2")
add_test("CONTINUE FOR does not change indent level", "test_indentation_3")
add_test("END SUB decreases indent level", "test_indentation_4")
add_test("END FUNCTION decreases indent level", "test_indentation_5")
add_test("EXIT FOR does not change indent level", "test_indentation_6")
add_test("EXIT FUNCTION does not change indent level", "test_indentation_7")
add_test("EXIT SUB does not change indent level", "test_indentation_8")
add_test("Omission of comments", "test_comments_1")
add_test("SELECT CASE increases indent level", "test_indentation_9")
add_test("Preserve spacing option", "test_preserve_spacing")
add_test("Minimal spacing option", "test_minimal_spacing")
add_test("Compact spacing option", "test_compact_spacing")
add_test("Generous spacing option", "test_generous_spacing")
add_test("Keyword capitalisation", "test_keyword_capitalisation")

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
  Local i
  pp.previous = 0
  pp.indent_lvl = 0
  For i = Bound(in$(), 0) To Bound(in$(), 1)
    out.buf$ = ""
    lx.parse_basic(in$(i))
    pp.print_line()
    out$(i) = out.buf$

    ' Trim trailing CRLF.
    If Right$(out$(i), 2) = sys.CRLF$ Then out$(i) = Left$(out$(i), Len(out$(i)) - 2)
  Next
End Sub

' Test omission of comments.
Sub test_comments_1()
  in$(0) = "' comment 1"
  in$(1) = "  ' comment 2"
  in$(2) = "If a = b Then ' comment 3"
  in$(3) = "  Print c ' comment 4"
  in$(4) = "EndIf ' comment 5"

  opt.comments = 0
  parse_lines()

  expected$(0) = ""
  expected$(1) = ""
  expected$(2) = "If a = b Then"
  expected$(3) = "  Print c"
  expected$(4) = "EndIf"
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

' Test compact spacing option.
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

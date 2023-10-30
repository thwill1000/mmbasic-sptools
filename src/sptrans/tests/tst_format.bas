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
#Include "../options.inc"
#Include "../format.inc"

Const NUM_LINES = 50
Dim expected$(NUM_LINES) Length 64, in$(NUM_LINES) Length 64, out$(NUM_LINES) Length 64

keywords.init()

add_test("Indenting - multi-line IF THEN", "test_indent_multi_line_if_then")
add_test("Indenting - single-line IF THEN", "test_indent_single_line_if_then")
add_test("Indenting - CONTINUE FOR", "test_indent_continue_for")
add_test("Indenting - SUB", "test_indent_sub")
add_test("Indenting - FUNCTION", "test_indent_function")
add_test("Indenting - EXIT FOR", "test_indent_exit_for")
add_test("Indenting - EXIT FUNCTION", "test_indent_exit_function")
add_test("Indenting - EXIT SUB", "test_indent_exit_sub")
add_test("Indenting - SELECT CASE", "test_indent_select_case")
add_test("Indenting - CSUB", "test_indent_csub")
add_test("Indenting - line numbers", "test_indent_line_numbers")
add_test("Spacing - preserve option", "test_preserve_spacing")
add_test("Spacing - minimal option", "test_minimal_spacing")
add_test("Spacing - compact option", "test_compact_spacing")
add_test("Spacing - generous option", "test_generous_spacing")
add_test("Keyword capitalisation", "test_keyword_capitalisation")
add_test("Empty lines - preserve if option is -1", "test_preserve_empty_lines")
add_test("Empty lines - ignore if option is 0", "test_ignore_empty_lines")
add_test("Empty lines - before FUNCTION/SUB if option is 1", "test_insert_empty_lines")
add_test("Empty lines - respects leading comment before function", "test_empty_lines_given_comment")
add_test("Omit comments", "test_omit_comments")
add_test("Preserve comments", "test_preserve_comments")

run_tests()

End

Sub setup_test()
  opt.init()
  fmt.indent_lvl% = 0
  Local i%
  For i% = Bound(in$(), 0) To Bound(in$(), 1)
    expected$(i%) = ""
    in$(i%) = ""
    out$(i%) = ""
  Next
End Sub

Sub format_lines()
  Local i%, j% = Mm.Info(Option Base), result%
  fmt.previous% = 0
  fmt.indent_lvl% = 0
  For i% = Bound(in$(), 0) To Bound(in$(), 1)
    assert_int_equals(sys.SUCCESS, lx.parse_basic%(in$(i%)))
    result% = fmt.format%()
    assert_true(result% >= 0)
    assert_no_error()
    If result% = fmt.EMPTY_LINE_BEFORE Then
      out$(j%) = ""
      Inc j%
    EndIf
    If result% <> fmt.OMIT_LINE Then
      out$(j%) = lx.line$
      Inc j%
    EndIf
    If result% = fmt.EMPTY_LINE_AFTER Then
      out$(j%) = ""
      Inc j%
    EndIf
  Next
End Sub

Sub test_indent_multi_line_if_then()
  in$(0) = "If a = b Then"
  in$(1) = "Print c"
  in$(2) = "EndIf"

  opt.indent_sz% = 2
  format_lines()

  expected$(0) = "If a = b Then"
  expected$(1) = "  Print c"
  expected$(2) = "EndIf"
  assert_string_array_equals(expected$(), out$())
End Sub

Sub test_indent_single_line_if_then()
  in$(0) = "If a = b Then c = d"
  in$(1) = "Print c"

  opt.indent_sz% = 2
  format_lines()

  expected$(0) = "If a = b Then c = d"
  expected$(1) = "Print c"
  assert_string_array_equals(expected$(), out$())
End Sub

Sub test_indent_continue_for()
  in$(0) = "If 1 Then"
  in$(1) = "If a = b Then"
  in$(2) = "Continue For"
  in$(3) = "EndIf"
  in$(4) = "EndIf"

  opt.indent_sz% = 2
  format_lines()

  expected$(0) = "If 1 Then"
  expected$(1) = "  If a = b Then"
  expected$(2) = "    Continue For"
  expected$(3) = "  EndIf"
  expected$(4) = "EndIf"
  assert_string_array_equals(expected$(), out$())
End Sub

Sub test_indent_sub()
  in$(0) = "Sub foo()"
  in$(1) = "Print a"
  in$(2) = "End Sub"
  in$(3) = "Print b"

  opt.indent_sz% = 2
  format_lines()

  expected$(0) = "Sub foo()"
  expected$(1) = "  Print a"
  expected$(2) = "End Sub"
  expected$(3) = "Print b"
  assert_string_array_equals(expected$(), out$())
End Sub

Sub test_indent_function()
  in$(0) = "Function foo()"
  in$(1) = "Print a"
  in$(2) = "End Function"
  in$(3) = "Print b"

  opt.indent_sz% = 2
  format_lines()

  expected$(0) = "Function foo()"
  expected$(1) = "  Print a"
  expected$(2) = "End Function"
  expected$(3) = "Print b"
  assert_string_array_equals(expected$(), out$())
End Sub

Sub test_indent_exit_for()
  in$(0) = "If 1 Then"
  in$(1) = "If a = b Then"
  in$(2) = "Exit For"
  in$(3) = "EndIf"
  in$(4) = "EndIf"

  opt.indent_sz% = 2
  format_lines()

  expected$(0) = "If 1 Then"
  expected$(1) = "  If a = b Then"
  expected$(2) = "    Exit For"
  expected$(3) = "  EndIf"
  expected$(4) = "EndIf"
  assert_string_array_equals(expected$(), out$())
End Sub

Sub test_indent_exit_function()
  in$(0) = "If 1 Then"
  in$(1) = "If a = b Then"
  in$(2) = "Exit Function"
  in$(3) = "EndIf"
  in$(4) = "EndIf"

  opt.indent_sz% = 2
  format_lines()

  expected$(0) = "If 1 Then"
  expected$(1) = "  If a = b Then"
  expected$(2) = "    Exit Function"
  expected$(3) = "  EndIf"
  expected$(4) = "EndIf"
  assert_string_array_equals(expected$(), out$())
End Sub

Sub test_indent_exit_sub()
  in$(0) = "If 1 Then"
  in$(1) = "If a = b Then"
  in$(2) = "Exit Sub"
  in$(3) = "EndIf"
  in$(4) = "EndIf"

  opt.indent_sz% = 2
  format_lines()

  expected$(0) = "If 1 Then"
  expected$(1) = "  If a = b Then"
  expected$(2) = "    Exit Sub"
  expected$(3) = "  EndIf"
  expected$(4) = "EndIf"
  assert_string_array_equals(expected$(), out$())
End Sub

Sub test_indent_select_case()
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

  opt.indent_sz% = 2
  format_lines()

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

Sub test_indent_csub()
  in$(0) = "CSub foo()"
  in$(1) = "00000000"
  in$(2) = "00AABBCC FFFFFFFF"
  in$(3) = "End CSub"
  in$(4) = "x = x + 1 ' something at global level"

  opt.indent_sz% = 2
  format_lines()

  expected$(0) = "CSub foo()"
  expected$(1) = "  00000000"
  expected$(2) = "  00AABBCC FFFFFFFF"
  expected$(3) = "End CSub"
  expected$(4) = in$(4)
  assert_string_array_equals(expected$(), out$())
End Sub

Sub test_indent_line_numbers()

  ' Line numbers left-padded to 6 characters.
  in$(0) = "1 foo"
  in$(1) = "12 foo"
  in$(2) = "1234 foo"
  in$(3) = "12345 foo"
  in$(4) = "123456 foo"
  in$(5) = "1234567 foo"

  opt.indent_sz% = 2
  format_lines()

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
  in$(1) = "20 If a% = b% Then"
  in$(2) = "30 foo"
  in$(3) = "40 EndIf"
  in$(4) = "50 Next"

  opt.indent_sz% = 2
  format_lines()

  expected$(0) = "    10 For i% = 1 To 5"
  expected$(1) = "    20   If a% = b% Then"
  expected$(2) = "    30     foo"
  expected$(3) = "    40   EndIf"
  expected$(4) = "    50 Next"
  assert_string_array_equals(expected$(), out$())
End Sub

Sub test_preserve_spacing()
  opt.spacing% = -1
  setup_spacing_test()

  format_lines()

  Local i%
  For i% = Bound(in$(), 0) To Bound(in$(), 1)
    ' Expect trailing whitespace removed.
    expected$(i%) = str.rtrim$(in$(i%))
  Next

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
  in$(13) = "Dim a = b - 1"
  in$(14) = "foo(" + str.quote$("bar") + ")"
  in$(15) = "c% = Bound(a$(), 1) - Bound(a$(), 0) + 1"
  in$(16) = "x%(j%) = x%(j%) And Inv(1 << (i% Mod 64))"
  in$(17) = "Print 5 ;"
  in$(18) = "Local shift% = Len(token$) + Len(sep$) + (idx% = 0)"
  in$(19) = "tr.update_num_comments( + 1)"
  in$(20) = "trailing = whitespace  "
  in$(21) = "If Mm.Info$(Device) = " + str.quote$("MMB4L") + " Then"
  in$(22) = "If f$ <> " + str.quote$("MMB4L") + " Then"
  in$(23) = "lx.store(TK_NUMBER, start , lx.pos - start)"
  in$(24) = "Case Else : a = 1"
  in$(25) = "Print " + str.quote$("foo") + " s$ " + str.quote$("bar")
  in$(26) = "If p% > Len(s$) Then"
  in$(27) = "If p% <= Len(s$) Then"
  in$(28) = "If p% <> Len(s$) Then"
  in$(29) = "Print " + str.quote$("[") + " Str$(i%) " + str.quote$("]")
  in$(30) = "Inc x, (5)"
  in$(31) = "con.print(Left$(ia_str$(i), p - 1))"
  in$(32) = "Local h% = Mm.VRes \ Mm.Info(FontHeight)"
  in$(33) = "Local h%=Mm.VRes*Mm.Info(FontHeight)"
  in$(34) = "Local h%=Mm.VRes/Mm.Info(FontHeight)"
  in$(35) = "Local h%=Mm.VRes+Mm.Info(FontHeight)"
  in$(36) = "Local h%=Mm.VRes-Mm.Info(FontHeight)"
  in$(37) = "Case <32, >126 : Exit Function"
  in$(38) = "Print Chr$(&h08) s$"
  in$(39) = "Print Chr$(8) ; " + str.quote$(" ") + " ; Chr$(8) ;"
  in$(40) = "If Not flags% And msgbox.NO_PAGES Then ? ;"
  in$(41) = "Case Is >= 0"
  in$(42) = "? Mm.Info(Exists " + str.quote$("foo") + ")"
  in$(43) = "foo'comment1"
  in$(44) = "bar    ' comment2"
End Sub

Sub test_minimal_spacing()
  opt.spacing% = 0
  setup_spacing_test()

  format_lines()

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
  expected$(10) = "For i%=5 To 1 Step -1"
  expected$(11) = "Loop Until(-a>-b)"
  expected$(12) = "label: foo:bar"
  expected$(13) = "Dim a=b-1"
  expected$(14) = "foo(" + str.quote$("bar") + ")"
  expected$(15) = "c%=Bound(a$(),1)-Bound(a$(),0)+1"
  expected$(16) = "x%(j%)=x%(j%)And Inv(1<<(i% Mod 64))"
  expected$(17) = "Print 5;"
  expected$(18) = "Local shift%=Len(token$)+Len(sep$)+(idx%=0)"
  expected$(19) = "tr.update_num_comments(+1)"
  expected$(20) = "trailing=whitespace"
  expected$(21) = "If Mm.Info$(Device)=" + str.quote$("MMB4L") + "Then"
  expected$(22) = "If f$<>" + str.quote$("MMB4L") + "Then"
  expected$(23) = "lx.store(TK_NUMBER,start,lx.pos-start)"
  expected$(24) = "Case Else:a=1"
  expected$(25) = "Print " + str.quote$("foo") + "s$" + str.quote$("bar")
  expected$(26) = "If p%>Len(s$)Then"
  expected$(27) = "If p%<=Len(s$)Then"
  expected$(28) = "If p%<>Len(s$)Then"
  expected$(29) = "Print " + str.quote$("[") + "Str$(i%)" + str.quote$("]")
  expected$(30) = "Inc x,(5)"
  expected$(31) = "con.print(Left$(ia_str$(i),p-1))"
  expected$(32) = "Local h%=Mm.VRes\Mm.Info(FontHeight)"
  expected$(33) = "Local h%=Mm.VRes*Mm.Info(FontHeight)"
  expected$(34) = "Local h%=Mm.VRes/Mm.Info(FontHeight)"
  expected$(35) = "Local h%=Mm.VRes+Mm.Info(FontHeight)"
  expected$(36) = "Local h%=Mm.VRes-Mm.Info(FontHeight)"
  expected$(37) = "Case<32,>126:Exit Function"
  expected$(38) = "Print Chr$(&h08)s$"
  expected$(39) = "Print Chr$(8);" + str.quote$(" ") + ";Chr$(8);"
  expected$(40) = "If Not flags% And msgbox.NO_PAGES Then ?;"
  expected$(41) = "Case Is >=0"
  expected$(42) = "?Mm.Info(Exists " + str.quote$("foo") + ")"
  expected$(43) = "foo'comment1"
  expected$(44) = "bar    ' comment2"
  assert_string_array_equals(expected$(), out$())
End Sub

Sub test_compact_spacing()
  opt.spacing% = 1
  setup_spacing_test()

  format_lines()

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
  expected$(13) = "Dim a=b-1"
  expected$(14) = "foo(" + str.quote$("bar") + ")"
  expected$(15) = "c%=Bound(a$(),1)-Bound(a$(),0)+1"
  expected$(16) = "x%(j%)=x%(j%) And Inv(1<<(i% Mod 64))"
  expected$(17) = "Print 5;"
  expected$(18) = "Local shift%=Len(token$)+Len(sep$)+(idx%=0)"
  expected$(19) = "tr.update_num_comments(+1)"
  expected$(20) = "trailing=whitespace"
  expected$(21) = "If Mm.Info$(Device)=" + str.quote$("MMB4L") + " Then"
  expected$(22) = "If f$<>" + str.quote$("MMB4L") + " Then"
  expected$(23) = "lx.store(TK_NUMBER,start,lx.pos-start)"
  expected$(24) = "Case Else : a=1"
  expected$(25) = "Print " + str.quote$("foo") + " s$ " + str.quote$("bar")
  expected$(26) = "If p%>Len(s$) Then"
  expected$(27) = "If p%<=Len(s$) Then"
  expected$(28) = "If p%<>Len(s$) Then"
  expected$(29) = "Print " + str.quote$("[") + " Str$(i%) " + str.quote$("]")
  expected$(30) = "Inc x,(5)"
  expected$(31) = "con.print(Left$(ia_str$(i),p-1))"
  expected$(32) = "Local h%=Mm.VRes\Mm.Info(FontHeight)"
  expected$(33) = "Local h%=Mm.VRes*Mm.Info(FontHeight)"
  expected$(34) = "Local h%=Mm.VRes/Mm.Info(FontHeight)"
  expected$(35) = "Local h%=Mm.VRes+Mm.Info(FontHeight)"
  expected$(36) = "Local h%=Mm.VRes-Mm.Info(FontHeight)"
  expected$(37) = "Case <32,>126 : Exit Function"
  expected$(38) = "Print Chr$(&h08) s$"
  expected$(39) = "Print Chr$(8);" + str.quote$(" ") + ";Chr$(8);"
  expected$(40) = "If Not flags% And msgbox.NO_PAGES Then ?;"
  expected$(41) = "Case Is >=0"
  expected$(42) = "?Mm.Info(Exists " + str.quote$("foo") + ")"
  expected$(43) = "foo 'comment1"
  expected$(44) = "bar    ' comment2"
  assert_string_array_equals(expected$(), out$())
End Sub

Sub test_generous_spacing()
  opt.spacing% = 2
  setup_spacing_test()

  format_lines()

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
  expected$(13) = "Dim a = b - 1"
  expected$(14) = "foo(" + str.quote$("bar") + ")"
  expected$(15) = "c% = Bound(a$(), 1) - Bound(a$(), 0) + 1"
  expected$(16) = "x%(j%) = x%(j%) And Inv(1 << (i% Mod 64))"
  expected$(17) = "Print 5;"
  expected$(18) = "Local shift% = Len(token$) + Len(sep$) + (idx% = 0)"
  expected$(19) = "tr.update_num_comments(+1)"
  expected$(20) = "trailing = whitespace"
  expected$(21) = "If Mm.Info$(Device) = " + str.quote$("MMB4L") + " Then"
  expected$(22) = "If f$ <> " + str.quote$("MMB4L") + " Then"
  expected$(23) = "lx.store(TK_NUMBER, start, lx.pos - start)"
  expected$(24) = "Case Else : a = 1"
  expected$(25) = "Print " + str.quote$("foo") + " s$ " + str.quote$("bar")
  expected$(26) = "If p% > Len(s$) Then"
  expected$(27) = "If p% <= Len(s$) Then"
  expected$(28) = "If p% <> Len(s$) Then"
  expected$(29) = "Print " + str.quote$("[") + " Str$(i%) " + str.quote$("]")
  expected$(30) = "Inc x, (5)"
  expected$(31) = "con.print(Left$(ia_str$(i), p - 1))"
  expected$(32) = "Local h% = Mm.VRes \ Mm.Info(FontHeight)"
  expected$(33) = "Local h% = Mm.VRes * Mm.Info(FontHeight)"
  expected$(34) = "Local h% = Mm.VRes / Mm.Info(FontHeight)"
  expected$(35) = "Local h% = Mm.VRes + Mm.Info(FontHeight)"
  expected$(36) = "Local h% = Mm.VRes - Mm.Info(FontHeight)"
  expected$(37) = "Case < 32, > 126 : Exit Function"
  expected$(38) = "Print Chr$(&h08) s$"
  expected$(39) = "Print Chr$(8); " + str.quote$(" ") + "; Chr$(8);"
  expected$(40) = "If Not flags% And msgbox.NO_PAGES Then ?;"
  expected$(41) = "Case Is >= 0"
  expected$(42) = "? Mm.Info(Exists " + str.quote$("foo") + ")"
  expected$(43) = "foo 'comment1"
  expected$(44) = "bar    ' comment2"
  assert_string_array_equals(expected$(), out$())
End Sub

Sub test_keyword_capitalisation()
  in$(0) = "FOr i=20 TO 1 StEP -2"

  opt.keywords = -1 ' preserve capitalisation.
  format_lines()
  expected$(0) = "FOr i=20 TO 1 StEP -2"
  assert_string_array_equals(expected$(), out$())

  opt.keywords = 0 ' lower-case.
  format_lines()
  expected$(0) = "for i=20 to 1 step -2"
  assert_string_array_equals(expected$(), out$())

  opt.keywords = 1 ' pascal-case.
  format_lines()
  expected$(0) = "For i=20 To 1 Step -2"
  assert_string_array_equals(expected$(), out$())

  opt.keywords = 2 ' upper-case.
  format_lines()
  expected$(0) = "FOR i=20 TO 1 STEP -2"
  assert_string_array_equals(expected$(), out$())
End Sub

Sub test_preserve_empty_lines()
  in$(0) = ""
  in$(1) = "foo"
  in$(2) = ""
  in$(3) = ""
  in$(4) = "bar"
  in$(5) = ""

  opt.empty_lines% = -1
  format_lines()

  expected$(0) = ""
  expected$(1) = "foo"
  expected$(2) = ""
  expected$(3) = ""
  expected$(4) = "bar"
  expected$(5) = ""
  assert_string_array_equals(expected$(), out$())
End Sub

Sub test_ignore_empty_lines()
  in$(0) = ""
  in$(1) = "foo"
  in$(2) = ""
  in$(3) = ""
  in$(4) = "bar"
  in$(5) = ""

  opt.empty_lines% = 0
  format_lines()

  expected$(0) = "foo"
  expected$(1) = "bar"
  assert_string_array_equals(expected$(), out$())
End Sub

Sub test_insert_empty_lines()
  in$(0) = "a = 1"
  in$(1) = "Function foo()"
  in$(2) = "End Function"
  in$(3) = "Sub bar()"
  in$(4) = "End Sub"
  in$(5) = "CFunction wom()"
  in$(6) = "End CFunction"
  in$(7) = "CSub bat()"
  in$(8) = "End CSub"

  opt.empty_lines% = 1
  format_lines()

  expected$(0) = "a = 1"
  expected$(1) = ""
  expected$(2) = "Function foo()"
  expected$(3) = "End Function"
  expected$(4) = ""
  expected$(5) = "Sub bar()"
  expected$(6) = "End Sub"
  expected$(7) = ""
  expected$(8) = "CFunction wom()"
  expected$(9) = "End CFunction"
  expected$(10) = ""
  expected$(11) = "CSub bat()"
  expected$(12) = "End CSub"
  assert_string_array_equals(expected$(), out$())
End Sub

Sub test_empty_lines_given_comment()
  in$(0) = "a = 1"
  in$(1) = "' Leading comment 1"
  in$(2) = "Function foo()"
  in$(3) = "End Function"
  in$(4) = "' Leading comment 2"
  in$(5) = "Sub bar()"
  in$(6) = "End Sub"

  opt.empty_lines% = 1
  format_lines()

  expected$(0) = "a = 1"
  expected$(1) = "' Leading comment 1"
  expected$(2) = "Function foo()"
  expected$(3) = "End Function"
  expected$(4) = ""
  expected$(5) = "' Leading comment 2"
  expected$(6) = "Sub bar()"
  expected$(7) = "End Sub"
  assert_string_array_equals(expected$(), out$())
End Sub


Sub test_omit_comments()
  in$(0) = "' leading space"
  in$(1) = "'no leading space"
  in$(2) = "'_leading underscore"
  in$(3) = "' license"
  in$(4) = "' LICENCE"
  in$(5) = "' copyRIGHT"
  in$(6) = "' (c)"
  in$(7) = "REM legacy comment"

  opt.comments% = 0
  format_lines()

  ' expected$() is initially empty.
  assert_string_array_equals(expected$(), out$())
End Sub

Sub test_preserve_comments()
  in$(0) = "' leading space"
  in$(1) = "'no leading space"
  in$(2) = "'_leading underscore"
  in$(3) = "' license"
  in$(4) = "' LICENCE"
  in$(5) = "' copyRIGHT"
  in$(6) = "' (c)"
  in$(7) = "REM legacy comment"

  opt.comments% = -1
  format_lines()

  assert_string_array_equals(in$(), out$())
End Sub

Sub expect_token(i%, type%, txt$, start%)
  Local ok% = (lx.type(i) = type%)
  ok% = ok% And (lx.token$(i) = txt$)
  ok% = ok% And (lx.len(i%) = Len(txt$))
  If start% Then ok% = ok% And (lx.start%(i%) = start%)
  If Not ok% Then
    Local msg$ = "expected " + token_to_string$(type%, txt$, Len(txt$), start%)
    Cat msg$, ", found " + token_to_string$(lx.type(i), lx.token$(i), lx.len(i), lx.start(i))
    assert_fail(msg$)
  EndIf
End Sub

Function token_to_string$(type%, txt$, len%, start%)
  Local s$
  Cat s$, Str$(type%)
  Cat s$, ", " + txt$
  Cat s$, ", " + Str$(len%)
  If start% Then Cat s$, ", " + Str$(start%)
  token_to_string$ = "{ " + s$ + " }"
End Function

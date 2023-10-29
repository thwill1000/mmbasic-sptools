' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

Option Explicit On
Option Default Integer

'Const MAX_NUM_FILES = 5
'Dim in.num_open_files = 1

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

Const CY$ = vt100.colour$("cyan")
Const GR$ = vt100.colour$("green")
Const MA$ = vt100.colour$("magenta")
Const RD$ = vt100.colour$("red")
Const RS$ = vt100.colour$("reset")
Const WH$ = vt100.colour$("white")
Const YE$ = vt100.colour$("yellow")

' Stub "../output.inc"
Dim out.buf$

Sub out.endl()
  out.print(sys.CRLF$)
End Sub

Sub out.print(s$)
  If out.buf$ = Chr$(0) Then out.buf$ = ""
  Cat out.buf$, s$
End Sub

Sub out.println(s$)
  out.print(s$)
  out.endl()
End Sub

sys.provides("output")

#Include "../highlight.inc"

Dim expected$(19)
Dim in$(19)
Dim out$(19)

keywords.init()

add_test("test_highlight")
add_test("test_highlight_csub")
add_test("test_highlight_cfunction")
add_test("test_highlight_comments")

run_tests()

End

Sub setup_test()
  out.buf$ = ""
  Local i%
  For i% = Bound(in$(), 0) To Bound(in$(), 1)
    expected$(i%) = ""
    in$(i%) = ""
    out$(i%) = ""
  Next
End Sub

Sub highlight_lines()
  Local i%, j% = Mm.Info(Option Base)
  For i% = Bound(in$(), 0) To Bound(in$(), 1)
    out.buf$ = Chr$(0)
    assert_int_equals(sys.SUCCESS, lx.parse_basic%(in$(i%)))
    hil.highlight()
    If out.buf$ <> Chr$(0) Then
      out$(j%) = out.buf$
      ' Trim trailing CRLF.
      If Right$(out$(j%), 2) = sys.CRLF$ Then out$(j%) = Left$(out$(j%), Len(out$(j%)) - 2)
      Inc j%
    EndIf
  Next
End Sub

Sub test_highlight()
  in$(0) = "Dim a = 1 + 2"
  in$(1) = "Dim b$ = " + str.quote$("foo")
  in$(2) = "'!if defined(bar)"
  in$(3) = "100 Dim line_number"
  in$(4) = "wombat: Dim label"

  highlight_lines()

  expected$(0) = CY$ + "Dim " + WH$ + "a " + WH$ + "= " + GR$ + "1 " + WH$ + "+ " + GR$ + "2" + RS$
  expected$(1) = CY$ + "Dim " + WH$ + "b$ " + WH$ + "= " + MA$ + str.quote$("foo") + RS$
  expected$(2) = RD$ + "'!if " + WH$ + "defined" + WH$ + "(" + WH$ + "bar" + WH$ + ")" + RS$
  expected$(3) = GR$ + "100 " + CY$ + "Dim " + WH$ + "line_number" + RS$
  expected$(4) = GR$ + "wombat: " + CY$ + "Dim " + WH$ + "label" + RS$
  assert_string_array_equals(expected$(), out$())
End Sub

Sub test_highlight_csub(s$)
  If Not Len(s$) Then s$ = "CSub"

  in$(0) = s$ + " abcdef()"
  in$(1) = "  00000000"
  in$(2) = "  00AABBCC FFFFFFFF"
  in$(3) = "  ' comment"
  in$(5) = "  not_valid = 5"
  in$(6) = "  not_valid_either = " + Chr$(34) + "wombat" + Chr$(34)
  in$(7) = "End " + s$

  highlight_lines()

  expected$(0) = CY$ + s$ + " " + WH$ + "abcdef" + WH$ +"(" + WH$ + ")" + RS$
  expected$(1) = "  " + GR$ + "00000000" + RS$
  expected$(2) = "  " + GR$ + "00AABBCC " + GR$ + "FFFFFFFF" + RS$
  expected$(3) = "  " + YE$ + "' comment" + RS$
  expected$(5) = "  " + WH$ + "not_valid " + WH$ + "= " + GR$ + "5" + RS$
  expected$(6) = "  " + WH$ + "not_valid_either " + WH$ + "= " + ma$ + Chr$(34) + "wombat" + Chr$(34) + RS$
  expected$(7) = CY$ + "End " + CY$ + s$ + RS$
  assert_string_array_equals(expected$(), out$())
End Sub

Sub test_highlight_cfunction()
  test_highlight_csub("CFunction")
End Sub

' Test syntax highlighting of comments.
Sub test_highlight_comments()
  in$(0) = "' Comment 1"
  in$(1) = "foo 'Comment2"
  in$(2) = "bar REM Comment 3"

  highlight_lines()

  expected$(0) = YE$ + "' Comment 1" + RS$
  expected$(1) = WH$ + "foo " + YE$ + "'Comment2" + RS$
  expected$(2) = WH$ + "bar " + YE$ + "REM Comment 3" + RS$
  assert_string_array_equals(expected$(), out$())
End Sub

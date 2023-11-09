' Copyright (c) 2020-2023 Thomas Hugo Williams
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
#Include "../keywords.inc"
#Include "../lexer.inc"
#Include "../options.inc"
#Include "../output.inc"

Const BASE = Mm.Info(Option Base)

Dim CY$, GR$, MA$, RD$, RS$, WH$, YE$
Dim expected$(array.new%(20))
Dim in$(array.new%(20))
Dim out$(array.new%(20))
Dim out_next%

keywords.init()

add_test("test_print")
add_test("test_println")
add_test("test_println_given_line_num")
add_test("test_endl")
add_test("test_line")
add_test("test_line_gvn_colour")
add_test("test_line_gvn_empty")
add_test("test_line_csub")
add_test("test_line_csub_gvn_colour")
add_test("test_line_cfunc")
add_test("test_line_cfunc_gvn_colour")
add_test("test_line_comment")
add_test("test_line_comment_gvn_colour")
add_test("test_omit_line")
add_test("test_empty_line")
add_test("test_empty_line_gvn_omit")
add_test("test_empty_line_gvn_start")

run_tests()

End

Sub setup_test()
  Local i%
  For i% = Bound(in$(), 0) To Bound(in$(), 1)
    expected$(i%) = ""
    in$(i%) = ""
    out$(i%) = ""
  Next
  out_next% = Bound(out$(), 0)
  out.append% = 0
  out.line_num% = 0
  out.line_num_width% = 0
  out.write_cb$ = "write_cb"
  opt.colour% = 0
  expect_colours(opt.colour%)
End Sub

Sub write_cb(fnbr%, s$)
  If fnbr% <> 0 Then Error "Invalid state"
  If Right$(s$, 2) = Chr$(13) + Chr$(10) Then
    Cat out$(out_next%), Left$(s$, Len(s$) - 2)
    Inc out_next%
  ElseIf InStr(Chr$(13) + Chr$(10), Right$(s$, 1)) Then
    Cat out$(out_next%), Left$(s$, Len(s$) - 1)
    Inc out_next%
  Else
    Cat out$(out_next%), s$
  EndIf
End Sub

Sub output_lines()
  Local i%
  For i% = Bound(in$(), 0) To Bound(in$(), 1)
    assert_int_equals(sys.SUCCESS, lx.parse_basic%(in$(i%)))
    out.line()
  Next
End Sub

Sub expect_colours(colour%)
  CY$ = Choice(colour%, vt100.colour$("cyan"), "")
  GR$ = Choice(colour%, vt100.colour$("green"), "")
  MA$ = Choice(colour%, vt100.colour$("magenta"), "")
  RD$ = Choice(colour%, vt100.colour$("red"), "")
  RS$ = Choice(colour%, vt100.colour$("reset"), "")
  WH$ = Choice(colour%, vt100.colour$("white"), "")
  YE$ = Choice(colour%, vt100.colour$("yellow"), "")
End Sub

Sub test_print()
  out.print("foo")
  out.print("bar")

  assert_int_equals(1, out.line_num%)
  assert_int_equals(BASE, out_next%)
  assert_string_equals("foobar", out$(BASE + 0))
End Sub

Sub test_println()
  out.println("foo")
  out.println("bar")

  assert_int_equals(2, out.line_num%)
  assert_int_equals(BASE + 2, out_next%)
  assert_string_equals("foo", out$(BASE + 0))
  assert_string_equals("bar", out$(BASE + 1))
End Sub

Sub test_println_given_line_num()
  out.line_num_width% = 5
  out.println("foo")
  out.println("bar")

  assert_int_equals(2, out.line_num%)
  assert_int_equals(BASE + 2, out_next%)
  assert_string_equals("1     foo", out$(BASE + 0))
  assert_string_equals("2     bar", out$(BASE + 1))
End Sub

Sub test_endl()
  out.println("foo")
  out.endl()

  assert_int_equals(2, out.line_num%)
  assert_int_equals(BASE + 2, out_next%)
  assert_string_equals("foo", out$(BASE + 0))
  assert_string_equals("", out$(BASE + 1))
End Sub

Sub test_line(colour%)
  in$(0) = "Dim a = 1 + 2"
  in$(1) = "Dim b$ = " + str.quote$("foo")
  in$(2) = "'!if defined(bar)"
  in$(3) = "100 Dim line_number"
  in$(4) = "wombat: Dim label"

  expect_colours(colour%)
  opt.colour% = colour%
  output_lines()

  expected$(0) = CY$ + "Dim " + WH$ + "a " + WH$ + "= " + GR$ + "1 " + WH$ + "+ " + GR$ + "2" + RS$
  expected$(1) = CY$ + "Dim " + WH$ + "b$ " + WH$ + "= " + MA$ + str.quote$("foo") + RS$
  expected$(2) = RD$ + "'!if " + WH$ + "defined" + WH$ + "(" + WH$ + "bar" + WH$ + ")" + RS$
  expected$(3) = GR$ + "100 " + CY$ + "Dim " + WH$ + "line_number" + RS$
  expected$(4) = GR$ + "wombat: " + CY$ + "Dim " + WH$ + "label" + RS$
  assert_string_array_equals(expected$(), out$())
End Sub

Sub test_line_gvn_colour()
  test_line(1)
End Sub

Sub test_line_gvn_empty()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("foo"))
  in$(0) = "foo"
  in$(1) = ""
  in$(0) = "bar"

  output_lines()

  assert_string_array_equals(in$(), out$())
End Sub

Sub test_line_csub(fn$, colour%)
  If Not Len(fn$) Then fn$ = "CSub"

  in$(0) = fn$ + " abcdef()"
  in$(1) = "  00000000"
  in$(2) = "  00AABBCC FFFFFFFF"
  in$(3) = "  ' comment"
  in$(5) = "  not_valid = 5"
  in$(6) = "  not_valid_either = " + str.quote$("wombat")
  in$(7) = "End " + fn$

  expect_colours(colour%)
  opt.colour% = colour%
  output_lines()

  expected$(0) = CY$ + fn$ + " " + WH$ + "abcdef" + WH$ +"(" + WH$ + ")" + RS$
  expected$(1) = "  " + GR$ + "00000000" + RS$
  expected$(2) = "  " + GR$ + "00AABBCC " + GR$ + "FFFFFFFF" + RS$
  expected$(3) = "  " + YE$ + "' comment" + RS$
  expected$(5) = "  " + WH$ + "not_valid " + WH$ + "= " + GR$ + "5" + RS$
  expected$(6) = "  " + WH$ + "not_valid_either " + WH$ + "= " + ma$ + str.quote$("wombat") + RS$
  expected$(7) = CY$ + "End " + CY$ + fn$ + RS$
  assert_string_array_equals(expected$(), out$())
End Sub

Sub test_line_csub_gvn_colour()
  test_line_csub("CSub", 1)
End Sub

Sub test_line_cfunc()
  test_line_csub("CFunction", 0)
End Sub

Sub test_line_cfunc_gvn_colour()
  test_line_csub("CFunction", 1)
End Sub

Sub test_line_comment(colour%)
  in$(0) = "' Comment 1"
  in$(1) = "foo 'Comment2"
  in$(2) = "bar REM Comment 3"

  expect_colours(colour%)
  opt.colour% = colour%
  output_lines()

  expected$(0) = YE$ + "' Comment 1" + RS$
  expected$(1) = WH$ + "foo " + YE$ + "'Comment2" + RS$
  expected$(2) = WH$ + "bar " + YE$ + "REM Comment 3" + RS$
  assert_string_array_equals(expected$(), out$())
End Sub

Sub test_line_comment_gvn_colour()
  test_line_comment(1)
End Sub

Sub test_omit_line()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("foo"))
  out.line()
  out.omit_line()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("bar"))
  out.line()

  expected$(0) = "foo"
  expected$(1) = "bar"
  assert_string_array_equals(expected$(), out$())
End Sub

Sub test_empty_line()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("foo"))
  out.line()
  out.empty_line()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("bar"))
  out.line()

  expected$(0) = "foo"
  expected$(1) = ""
  expected$(2) = "bar"
  assert_string_array_equals(expected$(), out$())
End Sub

' IF the current line is empty
' AND the last line was omitted
' AND the last non-omitted line was empty
' THEN omit this line.
Sub test_empty_line_gvn_omit()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("foo"))
  out.line()
  out.empty_line()
  out.omit_line()
  out.empty_line()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("bar"))
  out.line()

  expected$(0) = "foo"
  expected$(1) = ""
  expected$(2) = "bar"
  assert_string_array_equals(expected$(), out$())
End Sub

' Omit empty lines at start of file.
Sub test_empty_line_gvn_start()
  out.empty_line()
  out.empty_line()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("foo"))
  out.line()

  expected$(0) = "foo"
  assert_string_array_equals(expected$(), out$())
End Sub

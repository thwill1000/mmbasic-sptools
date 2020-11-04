' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

#Include "../options.inc"
#Include "../../common/error.inc"
#Include "../../common/file.inc"
#Include "../../common/list.inc"
#Include "../../common/set.inc"
#Include "../../sptest/unittest.inc"

add_test("test_colour")
add_test("test_comments")
add_test("test_empty_lines")
add_test("test_format_only")
add_test("test_indent")
add_test("test_spacing")
add_test("test_infile")
add_test("test_outfile")
add_test("test_unknown")

run_tests()

End

Sub setup_test()
  opt.init()
End Sub

Sub teardown_test()
End Sub

Function test_colour()
  Local elements$(10) Length 10, i

  assert_equals(0, opt.colour)

  elements$(0) = "0"
  elements$(1) = "off"
  elements$(2) = ""
  elements$(3) = "default"
  elements$(4) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.colour = 999
    opt.set("colour", elements$(i))
    assert_equals(0, opt.colour)
    i = i + 1
  Loop

  elements$(0) = "1"
  elements$(1) = "on"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.colour = 999
    opt.set("colour", elements$(i))
    assert_equals(1, opt.colour)
    i = i + 1
  Loop

  opt.set("colour", "foo")
  assert_error("expects 'on|off' argument")
End Function

Function test_comments()
  Local elements$(10) Length 10, i

  assert_equals(-1, opt.comments)

  elements$(0) = "preserve"
  elements$(1) = "default"
  elements$(2) = "on"
  elements$(3) = "-1"
  elements$(4) = ""
  elements$(5) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.comments = 999
    opt.set("comments", elements$(i))
    assert_equals(-1, opt.comments)
    i = i + 1
  Loop

  elements$(0) = "omit"
  elements$(1) = "off"
  elements$(2) = "none"
  elements$(3) = "0"
  elements$(4) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.comments = 999
    opt.set("comments", elements$(i))
    assert_equals(0, opt.comments)
    i = i + 1
  Loop

  opt.set("comments", "foo")
  assert_error("expects 'on|off' argument")
End Function

Function test_empty_lines()
  Local elements$(10) Length 10, i

  assert_equals(-1, opt.empty_lines)

  elements$(0) = "preserve"
  elements$(1) = "default"
  elements$(1) = "on"
  elements$(2) = "-1"
  elements$(3) = ""
  elements$(4) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.empty_lines = 999
    opt.set("empty-lines", elements$(i))
    assert_equals(-1, opt.empty_lines)
    i = i + 1
  Loop

  elements$(0) = "none"
  elements$(1) = "omit"
  elements$(2) = "off"
  elements$(3) = "0"
  elements$(4) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.comments = 999
    opt.set("empty-lines", elements$(i))
    assert_equals(0, opt.empty_lines)
    i = i + 1
  Loop

  elements$(0) = "single"
  elements$(1) = "1"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.comments = 999
    opt.set("empty-lines", elements$(i))
    assert_equals(1, opt.empty_lines)
    i = i + 1
  Loop

  opt.set("empty-lines", "foo")
  assert_error("expects 'on|off|single' argument")
End Function

Function test_format_only()
  Local elements$(10) Length 10, i

  assert_equals(0, opt.format_only)

  elements$(0) = "0"
  elements$(1) = "off"
  elements$(2) = ""
  elements$(3) = "default"
  elements$(4) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.format_only = 999
    opt.set("format-only", elements$(i))
    assert_equals(0, opt.format_only)
    i = i + 1
  Loop

  elements$(0) = "1"
  elements$(1) = "on"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.format_only = 999
    opt.set("format-only", elements$(i))
    assert_equals(1, opt.format_only)
    i = i + 1
  Loop

  opt.set("format-only", "foo")
  assert_error("expects 'on|off' argument")
End Function

Function test_indent()
  Local elements$(10) Length 10, i

  assert_equals(-1, opt.indent_sz)

  elements$(0) = "-1"
  elements$(1) = "preserve"
  elements$(2) = ""
  elements$(3) = "default"
  elements$(4) = "on"
  elements$(5) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.indent_sz = 999
    opt.set("indent", elements$(i))
    assert_equals(-1, opt.indent_sz)
    i = i + 1
  Loop

  elements$(0) = "0"
  elements$(1) = "1"
  elements$(2) = "2"
  elements$(3) = "3"
  elements$(4) = "4"
  elements$(5) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.indent_sz = 999
    opt.set("indent", elements$(i))
    assert_equals(i, opt.indent_sz)
    i = i + 1
  Loop

  err$ = ""
  opt.set("indent", "foo")
  assert_error("expects 'on|<number>' argument")

  err$ = ""
  opt.set("indent", "-2")
  assert_error("expects 'on|<number>' argument")
End Function

Function test_spacing()
  Local elements$(10) Length 10, i

  assert_equals(-1, opt.spacing)

  elements$(0) = "preserve"
  elements$(1) = "default"
  elements$(2) = "on"
  elements$(3) = ""
  elements$(4) = "-1"
  elements$(5) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.spacing = 999
    opt.set("spacing", elements$(i))
    assert_equals(-1, opt.spacing)
    i = i + 1
  Loop

  elements$(0) = "minimal"
  elements$(1) = "0"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.spacing = 999
    opt.set("spacing", elements$(i))
    assert_equals(0, opt.spacing)
    i = i + 1
  Loop

  elements$(0) = "compact"
  elements$(1) = "1"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.spacing = 999
    opt.set("spacing", elements$(i))
    assert_equals(1, opt.spacing)
    i = i + 1
  Loop

  elements$(0) = "generous"
  elements$(1) = "2"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.spacing = 999
    opt.set("spacing", elements$(i))
    assert_equals(2, opt.spacing)
    i = i + 1
  Loop

  err$ = ""
  opt.set("spacing", "foo")
  assert_error("expects 'on|minimal|compact|generous' argument")

  err$ = ""
  opt.set("spacing", "3")
  assert_error("expects 'on|minimal|compact|generous' argument")
End Function

Function test_infile()
  assert_string_equals("", opt.infile$)

  err$ = ""
  opt.set("infile", "foo.bas")
  assert_no_error()
  assert_string_equals("foo.bas", opt.infile$)
End Function

Function test_outfile()
  assert_string_equals("", opt.outfile$)

  err$ = ""
  opt.set("outfile", "foo.bas")
  assert_no_error()
  assert_string_equals("foo.bas", opt.outfile$)
End Function

Function test_unknown()
  err$ = ""
  opt.set("unknown", "foo")
  assert_error("unknown option: unknown")
End Function

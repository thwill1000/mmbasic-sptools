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
#Include "../../splib/set.inc"
#Include "../../splib/vt100.inc"
#Include "../../sptest/unittest.inc"
#Include "../options.inc"

add_test("test_colour")
add_test("test_comments")
add_test("test_crunch")
add_test("test_empty_lines")
add_test("test_format_only")
add_test("test_include_only")
add_test("test_indent")
add_test("test_infile")
add_test("test_keywords")
add_test("test_outfile")
add_test("test_pretty_print")
add_test("test_process_directives")
add_test("test_quiet")
add_test("test_spacing")
add_test("test_unknown")

run_tests()

End

Sub setup_test()
  opt.init()
End Sub

Sub test_colour()
  Local elements$(10) Length 10, i

  assert_int_equals(0, opt.colour)

  elements$(0) = "0"
  elements$(1) = "off"
  elements$(2) = ""
  elements$(3) = "default"
  elements$(4) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.colour = 999
    opt.set("colour", elements$(i))
    assert_int_equals(0, opt.colour)
    Inc i
  Loop

  elements$(0) = "1"
  elements$(1) = "on"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.colour = 999
    opt.set("colour", elements$(i))
    assert_int_equals(1, opt.colour)
    Inc i
  Loop

  opt.set("colour", "foo")
  assert_error("expects 'on|off' argument")
End Sub

Sub test_comments()
  Local elements$(10) Length 10, i

  assert_int_equals(-1, opt.comments)

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
    assert_int_equals(-1, opt.comments)
    Inc i
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
    assert_int_equals(0, opt.comments)
    Inc i
  Loop

  opt.set("comments", "foo")
  assert_error("expects 'on|off' argument")
End Sub

Sub test_crunch()
  Local elements$(10) Length 10, i

  assert_int_equals(0, opt.colour)

  elements$(0) = "0"
  elements$(1) = "off"
  elements$(2) = ""
  elements$(3) = "default"
  elements$(4) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.comments = 999
    opt.empty_lines = 999
    opt.indent_sz = 999
    opt.spacing = 999
    opt.set("crunch", elements$(i))
    assert_int_equals(999, opt.comments)
    assert_int_equals(999, opt.empty_lines)
    assert_int_equals(999, opt.indent_sz)
    assert_int_equals(999, opt.spacing)
    Inc i
  Loop

  elements$(0) = "1"
  elements$(1) = "on"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.comments = 999
    opt.empty_lines = 999
    opt.indent_sz = 999
    opt.spacing = 999
    opt.set("crunch", elements$(i))
    assert_int_equals(0, opt.comments)
    assert_int_equals(0, opt.empty_lines)
    assert_int_equals(0, opt.indent_sz)
    assert_int_equals(0, opt.spacing)
    Inc i
  Loop

  opt.set("crunch", "foo")
  assert_error("expects 'on|off' argument")
End Sub

Sub test_empty_lines()
  Local elements$(10) Length 10, i

  assert_int_equals(-1, opt.empty_lines)

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
    assert_int_equals(-1, opt.empty_lines)
    Inc i
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
    assert_int_equals(0, opt.empty_lines)
    Inc i
  Loop

  elements$(0) = "single"
  elements$(1) = "1"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.comments = 999
    opt.set("empty-lines", elements$(i))
    assert_int_equals(1, opt.empty_lines)
    Inc i
  Loop

  opt.set("empty-lines", "foo")
  assert_error("expects 'on|off|single' argument")
End Sub

Sub test_format_only()
  Local elements$(10) Length 10, i

  assert_int_equals(0, opt.format_only)

  elements$(0) = "0"
  elements$(1) = "off"
  elements$(2) = ""
  elements$(3) = "default"
  elements$(4) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.format_only = 999
    opt.set("format-only", elements$(i))
    assert_int_equals(0, opt.format_only)
    Inc i
  Loop

  elements$(0) = "1"
  elements$(1) = "on"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.format_only = 999
    opt.set("format-only", elements$(i))
    assert_int_equals(1, opt.format_only)
    Inc i
  Loop

  opt.set("format-only", "foo")
  assert_error("expects 'on|off' argument")
End Sub

Sub test_include_only()
  Local elements$(10) Length 10, i

  assert_int_equals(0, opt.format_only)

  elements$(0) = "0"
  elements$(1) = "off"
  elements$(2) = ""
  elements$(3) = "default"
  elements$(4) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.include_only = 999
    opt.set("include-only", elements$(i))
    assert_int_equals(0, opt.include_only)
    Inc i
  Loop

  elements$(0) = "1"
  elements$(1) = "on"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.include_only = 999
    opt.set("include-only", elements$(i))
    assert_int_equals(1, opt.include_only)
    Inc i
  Loop

  opt.set("include-only", "foo")
  assert_error("expects 'on|off' argument")
End Sub

Sub test_indent()
  Local elements$(10) Length 10, i

  assert_int_equals(-1, opt.indent_sz)

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
    assert_int_equals(-1, opt.indent_sz)
    Inc i
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
    assert_int_equals(i, opt.indent_sz)
    Inc i
  Loop

  sys.err$ = ""
  opt.set("indent", "foo")
  assert_error("expects 'on|<number>' argument")

  sys.err$ = ""
  opt.set("indent", "-2")
  assert_error("expects 'on|<number>' argument")
End Sub

Sub test_keywords()
  Local elements$(10) Length 10, i

  assert_int_equals(-1, opt.keywords)

  elements$(0) = "preserve"
  elements$(1) = "default"
  elements$(2) = "-1"
  elements$(3) = ""
  elements$(4) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.keywords = 999
    opt.set("keywords", elements$(i))
    assert_int_equals(-1, opt.keywords)
    Inc i
  Loop

  elements$(0) = "lower"
  elements$(1) = "l"
  elements$(2) = "0"
  elements$(3) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.keywords = 999
    opt.set("keywords", elements$(i))
    assert_int_equals(0, opt.keywords)
    Inc i
  Loop

  elements$(0) = "mixed"
  elements$(1) = "pascal"
  elements$(2) = "m"
  elements$(3) = "p"
  elements$(4) = "1"
  elements$(5) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.keywords = 999
    opt.set("keywords", elements$(i))
    assert_int_equals(1, opt.keywords)
    Inc i
  Loop

  elements$(0) = "upper"
  elements$(1) = "u"
  elements$(2) = "2"
  elements$(3) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.keywords = 999
    opt.set("keywords", elements$(i))
    assert_int_equals(2, opt.keywords)
    Inc i
  Loop

  sys.err$ = ""
  opt.set("keywords", "foo")
  assert_error("expects 'preserve|lower|pascal|upper' argument")

  sys.err$ = ""
  opt.set("keywords", "3")
  assert_error("expects 'preserve|lower|pascal|upper' argument")
End Sub

Sub test_quiet()
  Local elements$(10) Length 10, i

  assert_int_equals(0, opt.quiet)

  elements$(0) = "0"
  elements$(1) = "off"
  elements$(2) = ""
  elements$(3) = "default"
  elements$(4) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.quiet = 999
    opt.set("quiet", elements$(i))
    assert_int_equals(0, opt.quiet)
    Inc i
  Loop

  elements$(0) = "1"
  elements$(1) = "on"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.quiet = 999
    opt.set("quiet", elements$(i))
    assert_int_equals(1, opt.quiet)
    Inc i
  Loop

  opt.set("quiet", "foo")
  assert_error("expects 'on|off' argument")
End Sub

Sub test_spacing()
  Local elements$(10) Length 10, i

  assert_int_equals(-1, opt.spacing)

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
    assert_int_equals(-1, opt.spacing)
    Inc i
  Loop

  elements$(0) = "minimal"
  elements$(1) = "0"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.spacing = 999
    opt.set("spacing", elements$(i))
    assert_int_equals(0, opt.spacing)
    Inc i
  Loop

  elements$(0) = "compact"
  elements$(1) = "1"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.spacing = 999
    opt.set("spacing", elements$(i))
    assert_int_equals(1, opt.spacing)
    Inc i
  Loop

  elements$(0) = "generous"
  elements$(1) = "2"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    opt.spacing = 999
    opt.set("spacing", elements$(i))
    assert_int_equals(2, opt.spacing)
    Inc i
  Loop

  sys.err$ = ""
  opt.set("spacing", "foo")
  assert_error("expects 'on|minimal|compact|generous' argument")

  sys.err$ = ""
  opt.set("spacing", "3")
  assert_error("expects 'on|minimal|compact|generous' argument")
End Sub

Sub test_infile()
  assert_string_equals("", opt.infile$)

  sys.err$ = ""
  opt.set("infile", "foo.bas")
  assert_no_error()
  assert_string_equals("foo.bas", opt.infile$)
End Sub

Sub test_outfile()
  assert_string_equals("", opt.outfile$)

  sys.err$ = ""
  opt.set("outfile", "foo.bas")
  assert_no_error()
  assert_string_equals("foo.bas", opt.outfile$)
End Sub

Sub test_unknown()
  sys.err$ = ""
  opt.set("unknown", "foo")
  assert_error("unknown option: unknown")
End Sub

Sub test_pretty_print()
  given_options("")
  assert_int_equals(0, opt.pretty_print%())

  given_options("colour=1")
  assert_int_equals(1, opt.pretty_print%())

  given_options("comments=0")
  assert_int_equals(1, opt.pretty_print%())

  given_options("comments=1")
  assert_int_equals(0, opt.pretty_print%())

  given_options("empty-lines=0")
  assert_int_equals(1, opt.pretty_print%())

  given_options("format-only=1")
  assert_int_equals(0, opt.pretty_print%())

  given_options("indent=0")
  assert_int_equals(1, opt.pretty_print%())

  given_options("keywords=0")
  assert_int_equals(1, opt.pretty_print%())

  given_options("help=1")
  assert_int_equals(0, opt.pretty_print%())

  given_options("include-only=1")
  assert_int_equals(0, opt.pretty_print%())

  given_options("no-comments=0")
  assert_int_equals(0, opt.pretty_print%())

  given_options("no-comments=1")
  assert_int_equals(1, opt.pretty_print%())

  given_options("spacing=0")
  assert_int_equals(1, opt.pretty_print%())

  given_options("version=1")
  assert_int_equals(0, opt.pretty_print%())
End Sub

Sub given_options(s$)
  setup_test()
  Local i% = 1, k$, v$
  Do
    k$ = Field$(s$, i%, ",=")
    If k$ = "" Then Exit Do
    v$ = Field$(s$, i% + 1, ",=")
    opt.set(k$, v$)
    Inc i%, 2
  Loop
End Sub

Sub test_process_directives()
  given_options("")
  assert_int_equals(1, opt.process_directives%())

  given_options("colour=1")
  assert_int_equals(1, opt.process_directives%())

  given_options("comments=0")
  assert_int_equals(1, opt.process_directives%())

  given_options("comments=1")
  assert_int_equals(1, opt.process_directives%())

  given_options("empty-lines=0")
  assert_int_equals(1, opt.process_directives%())

  given_options("format-only=1")
  assert_int_equals(0, opt.process_directives%())

  given_options("indent=0")
  assert_int_equals(1, opt.process_directives%())

  given_options("keywords=0")
  assert_int_equals(1, opt.process_directives%())

  given_options("help=1")
  assert_int_equals(1, opt.process_directives%())

  given_options("include-only=1")
  assert_int_equals(0, opt.process_directives%())

  given_options("no-comments=0")
  assert_int_equals(1, opt.process_directives%())

  given_options("no-comments=1")
  assert_int_equals(1, opt.process_directives%())

  given_options("spacing=0")
  assert_int_equals(1, opt.process_directives%())

  given_options("version=1")
  assert_int_equals(1, opt.process_directives%())
End Sub

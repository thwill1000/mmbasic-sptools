' Copyright (c) 2020-2021 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For Colour Maximite 2, MMBasic 5.07

Option Explicit On
Option Default Integer

#Include "../../splib/system.inc"
#Include "../../splib/array.inc"
#Include "../../splib/list.inc"
#Include "../../splib/string.inc"
#Include "../../splib/file.inc"
#Include "../../splib/vt100.inc"
#Include "../../sptest/unittest.inc"
#Include "../options.inc"

add_test("test_all")
add_test("test_brief")
add_test("test_no_location")
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

Sub test_all()
  Local elements$(10) Length 10, i

  assert_int_equals(0, opt.all)

  elements$(0) = "on"
  elements$(1) = "1"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    sys.err$ = ""
    opt.all = 999
    opt.set("all", elements$(i))
    assert_no_error()
    assert_int_equals(1, opt.all)
    i = i + 1
  Loop

  elements$(0) = "off"
  elements$(1) = "0"
  elements$(2) = "default"
  elements$(3) = ""
  elements$(4) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    sys.err$ = ""
    opt.all = 999
    opt.set("all", elements$(i))
    assert_no_error()
    assert_int_equals(0, opt.all)
    i = i + 1
  Loop

  opt.set("all", "foo")
  assert_error("expects 'on|off' argument")
End Sub

Sub test_brief()
  Local elements$(10) Length 10, i

  assert_int_equals(0, opt.brief)

  elements$(0) = "on"
  elements$(1) = "1"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    sys.err$ = ""
    opt.brief = 999
    opt.set("brief", elements$(i))
    assert_no_error()
    assert_int_equals(1, opt.brief)
    i = i + 1
  Loop

  elements$(0) = "off"
  elements$(1) = "0"
  elements$(2) = "default"
  elements$(3) = ""
  elements$(4) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    sys.err$ = ""
    opt.brief = 999
    opt.set("brief", elements$(i))
    assert_no_error()
    assert_int_equals(0, opt.brief)
    i = i + 1
  Loop

  opt.set("brief", "foo")
  assert_error("expects 'on|off' argument")
End Sub

Sub test_no_location()
  Local elements$(10) Length 10, i

  assert_int_equals(0, opt.no_location)

  elements$(0) = "on"
  elements$(1) = "1"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    sys.err$ = ""
    opt.no_location = 999
    opt.set("no-location", elements$(i))
    assert_no_error()
    assert_int_equals(1, opt.no_location)
    i = i + 1
  Loop

  elements$(0) = "off"
  elements$(1) = "0"
  elements$(2) = "default"
  elements$(3) = ""
  elements$(4) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    sys.err$ = ""
    opt.no_location = 999
    opt.set("no-location", elements$(i))
    assert_no_error()
    assert_int_equals(0, opt.no_location)
    i = i + 1
  Loop

  opt.set("no-location", "foo")
  assert_error("expects 'on|off' argument")
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

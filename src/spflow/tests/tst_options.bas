' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

#Include "../options.inc"
#Include "../../common/error.inc"
#Include "../../common/file.inc"
#Include "../../common/list.inc"
#Include "../../common/set.inc"
#Include "../../sptest/unittest.inc"

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

  assert_equals(0, opt.all)

  elements$(0) = "on"
  elements$(1) = "1"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    err$ = ""
    opt.all = 999
    opt.set("all", elements$(i))
    assert_no_error()
    assert_equals(1, opt.all)
    i = i + 1
  Loop

  elements$(0) = "off"
  elements$(1) = "0"
  elements$(2) = "default"
  elements$(3) = ""
  elements$(4) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    err$ = ""
    opt.all = 999
    opt.set("all", elements$(i))
    assert_no_error()
    assert_equals(0, opt.all)
    i = i + 1
  Loop

  opt.set("all", "foo")
  assert_error("expects 'on|off' argument")
End Sub

Sub test_brief()
  Local elements$(10) Length 10, i

  assert_equals(0, opt.brief)

  elements$(0) = "on"
  elements$(1) = "1"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    err$ = ""
    opt.brief = 999
    opt.set("brief", elements$(i))
    assert_no_error()
    assert_equals(1, opt.brief)
    i = i + 1
  Loop

  elements$(0) = "off"
  elements$(1) = "0"
  elements$(2) = "default"
  elements$(3) = ""
  elements$(4) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    err$ = ""
    opt.brief = 999
    opt.set("brief", elements$(i))
    assert_no_error()
    assert_equals(0, opt.brief)
    i = i + 1
  Loop

  opt.set("brief", "foo")
  assert_error("expects 'on|off' argument")
End Sub

Sub test_no_location()
  Local elements$(10) Length 10, i

  assert_equals(0, opt.no_location)

  elements$(0) = "on"
  elements$(1) = "1"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    err$ = ""
    opt.no_location = 999
    opt.set("no-location", elements$(i))
    assert_no_error()
    assert_equals(1, opt.no_location)
    i = i + 1
  Loop

  elements$(0) = "off"
  elements$(1) = "0"
  elements$(2) = "default"
  elements$(3) = ""
  elements$(4) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    err$ = ""
    opt.no_location = 999
    opt.set("no-location", elements$(i))
    assert_no_error()
    assert_equals(0, opt.no_location)
    i = i + 1
  Loop

  opt.set("no-location", "foo")
  assert_error("expects 'on|off' argument")
End Sub

Sub test_infile()
  assert_string_equals("", opt.infile$)

  err$ = ""
  opt.set("infile", "foo.bas")
  assert_no_error()
  assert_string_equals("foo.bas", opt.infile$)
End Sub

Sub test_outfile()
  assert_string_equals("", opt.outfile$)

  err$ = ""
  opt.set("outfile", "foo.bas")
  assert_no_error()
  assert_string_equals("foo.bas", opt.outfile$)
End Sub

Sub test_unknown()
  err$ = ""
  opt.set("unknown", "foo")
  assert_error("unknown option: unknown")
End Sub

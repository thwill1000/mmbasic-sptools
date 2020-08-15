' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

#Include "../options.inc"
#Include "../../common/error.inc"
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
  op_init()
End Sub

Sub teardown_test()
End Sub

Function test_all()
  Local elements$(10) Length 10, i

  assert_equals(0, op_all)

  elements$(0) = "on"
  elements$(1) = "1"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    err$ = ""
    op_all = 999
    op_set("all", elements$(i))
    assert_no_error()
    assert_equals(1, op_all)
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
    op_all = 999
    op_set("all", elements$(i))
    assert_no_error()
    assert_equals(0, op_all)
    i = i + 1
  Loop

  op_set("all", "foo")
  assert_error("expects 'on|off' argument")
End Function

Function test_brief()
  Local elements$(10) Length 10, i

  assert_equals(0, op_brief)

  elements$(0) = "on"
  elements$(1) = "1"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    err$ = ""
    op_brief = 999
    op_set("brief", elements$(i))
    assert_no_error()
    assert_equals(1, op_brief)
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
    op_brief = 999
    op_set("brief", elements$(i))
    assert_no_error()
    assert_equals(0, op_brief)
    i = i + 1
  Loop

  op_set("brief", "foo")
  assert_error("expects 'on|off' argument")
End Function

Function test_no_location()
  Local elements$(10) Length 10, i

  assert_equals(0, op_no_location)

  elements$(0) = "on"
  elements$(1) = "1"
  elements$(2) = Chr$(0)
  i = 0
  Do While elements$(i) <> Chr$(0)
    err$ = ""
    op_no_location = 999
    op_set("no-location", elements$(i))
    assert_no_error()
    assert_equals(1, op_no_location)
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
    op_no_location = 999
    op_set("no-location", elements$(i))
    assert_no_error()
    assert_equals(0, op_no_location)
    i = i + 1
  Loop

  op_set("no-location", "foo")
  assert_error("expects 'on|off' argument")
End Function

Function test_infile()
  assert_string_equals("", op_infile$)

  err$ = ""
  op_set("infile", "foo.bas")
  assert_no_error()
  assert_string_equals("foo.bas", op_infile$)
End Function

Function test_outfile()
  assert_string_equals("", op_outfile$)

  err$ = ""
  op_set("outfile", "foo.bas")
  assert_no_error()
  assert_string_equals("foo.bas", op_outfile$)
End Function

Function test_unknown()
  err$ = ""
  op_set("unknown", "foo")
  assert_error("unknown option: unknown")
End Function

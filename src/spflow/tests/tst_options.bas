' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

#Include "../options.inc"
#Include "../../common/error.inc"
#Include "../../common/list.inc"
#Include "../../common/set.inc"
#Include "../../sptest/unittest.inc"

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

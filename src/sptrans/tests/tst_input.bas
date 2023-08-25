' Copyright (c) 2023-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

Option Base 0
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
#Include "../input.inc"

add_test("test_open_given_file")
add_test("test_open_given_dir")
add_test("test_open_given_not_found")
add_test("test_open_given_too_many")
add_test("test_open_given_relative")

run_tests()

End

Sub setup_test()
  MkDir TMPDIR$
End Sub

Sub teardown_test()
  Local fnbr%
  For fnbr% = 1 To list.size%(in.files$())
    If list.get$(in.files$(), fnbr% - 1) <> "" Then Close fnbr%
  Next
End Sub

Sub test_open_given_file()
  in.init()
  Const f$ = TMPDIR$ + "/foo.bas"
  ut.create_file(f$)

  assert_int_equals(sys.SUCCESS, in.open%(f$))
  assert_no_error()
  assert_int_equals(1, list.size%(in.files$()))
  assert_string_equals(f$, list.get$(in.files$(0)))
  assert_int_equals(0, in.line_num%(0))
End Sub

Sub test_open_given_dir()
  in.init()
  Const f$ = TMPDIR$ + "/foo.bas"
  MkDir f$

  assert_int_equals(sys.FAILURE, in.open%(f$))
  assert_error("Cannot #Include directory '" + f$ + "'")
  assert_int_equals(0, list.size%(in.files$()))
End Sub

Sub test_open_given_not_found()
  in.init()
  Const f$ = TMPDIR$ + "/not_found.bas"

  assert_int_equals(sys.FAILURE, in.open%(f$))
  assert_error("#Include file '" + f$ + "' not found")
  assert_int_equals(0, list.size%(in.files$()))
End Sub

Sub test_open_given_too_many()
  in.init()

  ' Open the maximum number of files (5).
  Local files$(array.new%(5)) = ("one", "two", "three", "four", "five")
  Local f$, i%
  For i% = Bound(files$(), 0) TO Bound(files$(), 1)
    f$ = TMPDIR$ + "/" + files$(i%) + ".bas"
    ut.create_file(f$, 10)
    assert_int_equals(sys.SUCCESS, in.open%(f$))
    assert_no_error()
  Next

  ' Verify that all the files are recorded as open.
  assert_int_equals(5, list.size%(in.files$()))
  For i% = Bound(files$(), 0) TO Bound(files$(), 1)
    f$ = TMPDIR$ + "/" + files$(i%) + ".bas"
    assert_string_equals(f$, list.get$(in.files$(), i%))
    assert_int_equals(0, in.line_num%(i%))
  Next

  ' Try to open a 6th file.
  f$ = TMPDIR$ + "/six.bas"
  ut.create_file(f$, 10)
  assert_int_equals(sys.FAILURE, in.open%(f$))
  assert_error("Too many open #Include files")

  ' Verify that the records for the other 5 files have not changed.
  assert_int_equals(5, list.size%(in.files$()))
  For i% = Bound(files$(), 0) TO Bound(files$(), 1)
    f$ = TMPDIR$ + "/" + files$(i%) + ".bas"
    assert_string_equals(f$, list.get$(in.files$(), i%))
    assert_int_equals(0, in.line_num%(i%))
  Next
End Sub

Sub test_open_given_relative()
  in.init()
  ut.create_file(TMPDIR$ + "/foo.bas")
  MkDir TMPDIR$ + "/bar"
  ut.create_file(TMPDIR$ + "/bar/wombat.inc")

  assert_int_equals(sys.SUCCESS, in.open%(TMPDIR$ + "/foo.bas"))
  assert_no_error()
  assert_int_equals(sys.SUCCESS, in.open%("bar/wombat.inc"))
  assert_no_error()
  assert_int_equals(2, list.size%(in.files$()))
  assert_string_equals(TMPDIR$ + "/foo.bas", list.get$(in.files$(), 0))
  assert_string_equals(TMPDIR$ + "/bar/wombat.inc", list.get$(in.files$(), 1))
  assert_int_equals(0, in.line_num%(0))
  assert_int_equals(0, in.line_num%(1))
End Sub

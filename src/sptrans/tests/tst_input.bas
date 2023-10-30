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
add_test("test_readln_gvn_empty_buffer")
add_test("test_readln_gvn_non_empty_buffer")
add_test("test_readln_gvn_eof")
add_test("test_buffer_line_gvn_full")

run_tests()

End

Sub setup_test()
  MkDir TMPDIR$
  in.init()
End Sub

Sub teardown_test()
  Local fnbr%
  For fnbr% = 1 To list.size%(in.files$())
    If list.get$(in.files$(), fnbr% - 1) <> "" Then Close fnbr%
  Next
End Sub

Sub test_open_given_file()
  Const f$ = TMPDIR$ + "/foo.bas"
  ut.create_file(f$)

  assert_int_equals(sys.SUCCESS, in.open%(f$))
  assert_no_error()
  assert_int_equals(1, list.size%(in.files$()))
  assert_string_equals(f$, list.get$(in.files$(0)))
  assert_int_equals(0, in.line_num%(0))
End Sub

Sub test_open_given_dir()
  Const f$ = TMPDIR$ + "/foo.bas"
  MkDir f$

  assert_int_equals(sys.FAILURE, in.open%(f$))
  assert_error("Cannot #Include directory '" + f$ + "'")
  assert_int_equals(0, list.size%(in.files$()))
End Sub

Sub test_open_given_not_found()
  Const f$ = TMPDIR$ + "/not_found.bas"

  assert_int_equals(sys.FAILURE, in.open%(f$))
  assert_error("#Include file '" + f$ + "' not found")
  assert_int_equals(0, list.size%(in.files$()))
End Sub

Sub test_open_given_too_many()
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

Sub test_readln_gvn_empty_buffer()
  Const f$ = TMPDIR$ + "/test_readln_gvn_empty_buffer.bas"
  ut.write_data_file(TMPDIR$ + "/test_readln_gvn_empty_buffer.bas", "input_data")

  assert_int_equals(sys.SUCCESS, in.open%(f$))
  assert_int_equals(0, list.size%(in.buffer$()))
  assert_string_equals("10 Print " + str.quote$("Hello World"), in.readln$())
End Sub

Sub test_readln_gvn_non_empty_buffer()
  Const f$ = TMPDIR$ + "/test_readln_gvn_empty_buffer.bas"
  ut.write_data_file(TMPDIR$ + "/test_readln_gvn_empty_buffer.bas", "input_data")

  assert_int_equals(sys.SUCCESS, in.open%(f$))
  assert_int_equals(0, list.size%(in.buffer$()))
  assert_int_equals(sys.SUCCESS, in.buffer_line%("Dim a = 42"))
  assert_int_equals(sys.SUCCESS, in.buffer_line%("Const PI = 3.142"))
  assert_string_equals("Dim a = 42", in.readln$())
  assert_string_equals("Const PI = 3.142", in.readln$())
  assert_string_equals("10 Print " + str.quote$("Hello World"), in.readln$())
End Sub

Sub test_readln_gvn_eof()
  Const f$ = TMPDIR$ + "/test_readln_gvn_empty_buffer.bas"
  ut.write_data_file(TMPDIR$ + "/test_readln_gvn_empty_buffer.bas", "input_data")

  assert_int_equals(sys.SUCCESS, in.open%(f$))
  assert_string_equals("10 Print " + str.quote$("Hello World"), in.readln$())
  assert_string_equals("20 Goto 10", in.readln$())

  ' Does not currently report EOF but keeps returning empty lines.
  assert_string_equals("", in.readln$())
  assert_string_equals("", in.readln$())
  assert_int_equals(4, in.line_num%(0))
End Sub

Sub test_buffer_line_gvn_full()
  Const f$ = TMPDIR$ + "/test_readln_gvn_empty_buffer.bas"
  ut.write_data_file(TMPDIR$ + "/test_readln_gvn_empty_buffer.bas", "input_data")

  assert_int_equals(sys.SUCCESS, in.open%(f$))
  assert_int_equals(0, list.size%(in.buffer$()))
  assert_int_equals(sys.SUCCESS, in.buffer_line%("one"))
  assert_int_equals(sys.SUCCESS, in.buffer_line%("two"))
  assert_int_equals(sys.SUCCESS, in.buffer_line%("three"))
  assert_int_equals(sys.SUCCESS, in.buffer_line%("four"))
  assert_int_equals(sys.SUCCESS, in.buffer_line%("five"))
  assert_int_equals(sys.FAILURE, in.buffer_line%("six"))
  assert_error("Input buffer full")
End Sub

input_data:
Data "text/json" ' Will convert single => double quote.
Data "10 Print 'Hello World'"
Data "20 Goto 10"
Data "<EOF>"

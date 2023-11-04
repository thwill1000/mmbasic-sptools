' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

Option Base 0
Option Default Integer
Option Explicit On

#Include "../../splib/system.inc"
#Include "../../splib/array.inc"
#Include "../../splib/bits.inc"
#Include "../../splib/list.inc"
#Include "../../splib/string.inc"
#Include "../../splib/file.inc"
#Include "../../splib/map.inc"
#Include "../../splib/map2.inc"
#Include "../../splib/set.inc"
#Include "../../splib/vt100.inc"
#Include "../../sptest/unittest.inc"
#Include "../../common/sptools.inc"
#Include "../input.inc"
#Include "../keywords.inc"
#Include "../lexer.inc"
#Include "../options.inc"
#Include "../output.inc"
#Include "../symbols.inc"
#Include "../symproc.inc"

Dim actual$(10), expected$(10), lines$(10)

keywords.init()

add_test("test_initial_state")
add_test("test_global_vars")
add_test("test_sub_declarations")
add_test("test_call_from_sub")
add_test("test_call_from_global")
add_test("test_split_globals")
add_test("test_split_globals_bug_1")
add_test("test_split_globals_bug_2")
add_test("test_nested_sub")
add_test("test_given_unbalanced_end_sub")
add_test("test_given_duplicate_sub")
add_test("test_given_start_not_col_1")
add_test("test_given_end_not_last_tok")
add_test("test_given_leading_comment")

run_tests()

End

Sub setup_test()
  in.init()
  list.push(in.files$(), "my_file.bas")
  in.num_open_files% = 1
  out.line_num = 0
  symproc.init(32, 300, 1)
  clear_arrays()
End Sub

Sub clear_arrays()
  array.fill(actual$())
  array.fill(expected$())
  array.fill(lines$())
End Sub

Sub parse_and_process(lines$())
  Local i%
  For i% = 1 To Bound(lines$(), 1)
    Inc out.line_num
    in.line_num%(0) = i%
    assert_int_equals(sys.SUCCESS, lx.parse_basic%(lines$(i%)))
    assert_int_equals(sys.SUCCESS, symproc.process%())
  Next
End Sub

Sub test_initial_state()
  ' One file.
  clear_arrays()
  assert_int_equals(1, sym.get_files%(actual$()))
  expected$(0) = "my_file.bas"
  assert_string_array_equals(expected$(), actual$())

  ' One identifier representing the global scope.
  clear_arrays()
  assert_int_equals(1, sym.get_names%(actual$()))
  expected$(0) = symproc.GLOBAL_SCOPE
  assert_string_array_equals(expected$(), actual$())

  ' One function representing the global scope.
  clear_arrays()
  assert_int_equals(1, sym.get_functions%(actual$()))
  expected$(0) = symproc.GLOBAL_SCOPE + ",0,1,0,0,0:0,0:0"
  assert_string_array_equals(expected$(), actual$())

  ' No references.
  clear_arrays()
  assert_int_equals(0, sym.get_references%(symproc.GLOBAL_SCOPE, actual$()))
  assert_string_array_equals(expected$(), actual$())
End Sub

Sub test_global_vars()
  lines$(1) = "Dim s$"
  lines$(2) = "Const MY_CONST"
  parse_and_process(lines$())

  ' Check indentifiers.
  clear_arrays()
  assert_int_equals(3, sym.get_names%(actual$()))
  expected$(0) = symproc.GLOBAL_SCOPE
  expected$(1) = "my_const"
  expected$(2) = "s$"
  assert_string_array_equals(expected$(), actual$())

  ' Check functions.
  clear_arrays()
  assert_int_equals(1, sym.get_functions%(actual$()))
  expected$(0) = symproc.GLOBAL_SCOPE + ",0,1,0,0,0:0,0:0"
  assert_string_array_equals(expected$(), actual$())

  ' Check references.
  clear_arrays()
  assert_int_equals(2, sym.get_references%(symproc.GLOBAL_SCOPE, actual$()))
  expected$(0) = "my_const"
  expected$(1) = "s$"
  assert_string_array_equals(expected$(), actual$())
End sub

Sub test_sub_declarations()
  lines$(1) = "CFunction my_cfunction()"
  lines$(2) = "End CFunction"
  lines$(3) = "CSub my_csub()"
  lines$(4) = "End CSub"
  lines$(5) = "Function my_function()"
  lines$(6) = "End Function"
  lines$(7) = "Sub my_sub()"
  lines$(8) = "End Sub"
  parse_and_process(lines$())

  ' Check identifiers.
  clear_arrays()
  assert_int_equals(5, sym.get_names%(actual$()))
  expected$(0) = symproc.GLOBAL_SCOPE
  expected$(1) = "my_cfunction"
  expected$(2) = "my_csub"
  expected$(3) = "my_function"
  expected$(4) = "my_sub"
  assert_string_array_equals(expected$(), actual$())

  ' Check functions.
  clear_arrays()
  assert_int_equals(5, sym.get_functions%(actual$()))
  expected$(0) = symproc.GLOBAL_SCOPE + ",0,1,0,0,0:0,0:0"
  expected$(1) = "my_cfunction,0,1,4,1,1:1,2:13"
  expected$(2) = "my_csub,0,3,8,2,3:1,4:8"
  expected$(3) = "my_function,0,5,12,3,5:1,6:12"
  expected$(4) = "my_sub,0,7,16,4,7:1,8:7"
  assert_string_array_equals(expected$(), actual$())

  ' Check references, note *global* does not reference sub declarations.
  clear_arrays()
  assert_int_equals(0, sym.get_references%(symproc.GLOBAL_SCOPE, actual$()))
  assert_int_equals(0, sym.get_references%("my_cfunction", actual$()))
  assert_int_equals(0, sym.get_references%("my_csub", actual$()))
  assert_int_equals(0, sym.get_references%("my_function", actual$()))
  assert_int_equals(0, sym.get_references%("my_sub", actual$()))
End Sub

Sub test_call_from_sub()
  lines$(1) = "Sub foo()"
  lines$(2) = "  bar()"
  lines$(3) = "End Sub"
  lines$(4) = "Sub bar()"
  lines$(5) = "End Sub"
  parse_and_process(lines$())

  ' Check identifiers.
  clear_arrays()
  assert_int_equals(3, sym.get_names%(actual$()))
  expected$(0) = symproc.GLOBAL_SCOPE
  expected$(1) = "bar"
  expected$(2) = "foo"
  assert_string_array_equals(expected$(), actual$())

  ' Check functions.
  clear_arrays()
  assert_int_equals(3, sym.get_functions%(actual$()))
  expected$(0) = symproc.GLOBAL_SCOPE + ",0,1,0,0,0:0,0:0"
  expected$(1) = "bar,0,4,12,2,4:1,5:7"
  expected$(2) = "foo,0,1,4,1,1:1,3:7"
  assert_string_array_equals(expected$(), actual$())

  ' Check references.
  clear_arrays()
  assert_int_equals(0, sym.get_references%(symproc.GLOBAL_SCOPE, actual$()))
  assert_int_equals(0, sym.get_references%("bar", actual$()))
  assert_int_equals(1, sym.get_references%("foo", actual$()))
  expected$(0) = "bar"
  assert_string_array_equals(expected$(), actual$())
End Sub

Sub test_call_from_global()
  lines$(1) = "foo()"
  parse_and_process(lines$())

  ' Check identifiers.
  clear_arrays()
  assert_int_equals(2, sym.get_names%(actual$()))
  expected$(0) = symproc.GLOBAL_SCOPE
  expected$(1) = "foo"
  assert_string_array_equals(expected$(), actual$())

  ' Check functions.
  clear_arrays()
  assert_int_equals(1, sym.get_functions%(actual$()))
  expected$(0) = symproc.GLOBAL_SCOPE + ",0,1,0,0,0:0,0:0"
  assert_string_array_equals(expected$(), actual$())

  ' Check references.
  clear_arrays()
  assert_int_equals(1, sym.get_references%(symproc.GLOBAL_SCOPE, actual$()))
  expected$(0) = "foo"
  assert_string_array_equals(expected$(), actual$())
End Sub

Sub test_split_globals()
  lines$(1) = "foo()"
  lines$(2) = "Sub bar()"
  lines$(3) = "End Sub"
  lines$(4) = "wombat()" ' Identifier in the global scope after a SUB.
  parse_and_process(lines$())

  ' Check identifiers.
  clear_arrays()
  assert_int_equals(4, sym.get_names%(actual$()))
  expected$(0) = symproc.GLOBAL_SCOPE
  expected$(1) = "bar"
  expected$(2) = "foo"
  expected$(3) = "wombat"
  assert_string_array_equals(expected$(), actual$())

  ' Check functions.
  clear_arrays()
  assert_int_equals(2, sym.get_functions%(actual$()))
  expected$(0) = symproc.GLOBAL_SCOPE + ",0,1,0,0,0:0,0:0"
  expected$(1) = "bar,0,2,8,2,2:1,3:7"
  assert_string_array_equals(expected$(), actual$())

  ' Check references.
  clear_arrays()
  assert_int_equals(2, sym.get_references%(symproc.GLOBAL_SCOPE, actual$()))
  expected$(0) = "foo"
  expected$(1) = "wombat"
  assert_string_array_equals(expected$(), actual$())
  assert_int_equals(0, sym.get_references%("bar", actual$()))
End Sub

Sub test_split_globals_bug_1()
  lines$(1) = "Sub a()"
  lines$(2) = "End Sub"
  lines$(3) = "Dim b"
  lines$(4) = "Dim c"
  parse_and_process(lines$())

  ' Check identifiers.
  clear_arrays()
  assert_int_equals(4, sym.get_names%(actual$()))
  expected$(0) = symproc.GLOBAL_SCOPE
  expected$(1) = "a"
  expected$(2) = "b"
  expected$(3) = "c"
  assert_string_array_equals(expected$(), actual$())

  ' Check functions.
  clear_arrays()
  assert_int_equals(2, sym.get_functions%(actual$()))
  expected$(0) = symproc.GLOBAL_SCOPE + ",0,1,0,0,0:0,0:0"
  expected$(1) = "a,0,1,4,1,1:1,2:7"
  assert_string_array_equals(expected$(), actual$())

  ' Check references.
  clear_arrays()
  assert_int_equals(2, sym.get_references%(symproc.GLOBAL_SCOPE, actual$()))
  expected$(0) = "b"
  expected$(1) = "c"
  assert_string_array_equals(expected$(), actual$())
  assert_int_equals(0, sym.get_references%("a", actual$()))
End Sub

Sub test_split_globals_bug_2()
  lines$(1) = "Sub a()"
  lines$(2) = "End Sub"
  lines$(3) = "a()"
  lines$(4) = "Sub b()"
  lines$(5) = "End Sub"
  lines$(6) = "a()"
  parse_and_process(lines$())

  ' Check identifiers.
  clear_arrays()
  assert_int_equals(3, sym.get_names%(actual$()))
  expected$(0) = symproc.GLOBAL_SCOPE
  expected$(1) = "a"
  expected$(2) = "b"
  assert_string_array_equals(expected$(), actual$())

  ' Check functions.
  clear_arrays()
  assert_int_equals(3, sym.get_functions%(actual$()))
  expected$(0) = symproc.GLOBAL_SCOPE + ",0,1,0,0,0:0,0:0"
  expected$(1) = "a,0,1,4,1,1:1,2:7"
  expected$(2) = "b,0,4,16,2,4:1,5:7"
  assert_string_array_equals(expected$(), actual$())

  ' Check references.
  clear_arrays()
  assert_int_equals(1, sym.get_references%(symproc.GLOBAL_SCOPE, actual$()))
  expected$(0) = "a"
  assert_string_array_equals(expected$(), actual$())
  assert_int_equals(0, sym.get_references%("a", actual$()))
  assert_int_equals(0, sym.get_references%("b", actual$()))
End Sub

Sub test_nested_sub()
  in.line_num%(0) = 1
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("Sub foo()"))
  assert_int_equals(sys.SUCCESS, symproc.process%())
  in.line_num%(0) = 2
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("Sub bar()"))
  assert_int_equals(sys.FAILURE, symproc.process%())
  assert_error("Nested FUNCTION/SUB")
End Sub

Sub test_given_unbalanced_end_sub()
  in.line_num%(0) = 1
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("End Sub"))
  assert_int_equals(sys.FAILURE, symproc.process%())
  assert_error("Unbalanced END FUNCTION/SUB")
End Sub

Sub test_given_duplicate_sub()
  in.line_num%(0) = 1
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("Sub foo()"))
  assert_int_equals(sys.SUCCESS, symproc.process%())
  in.line_num%(0) = 2
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("End Sub"))
  assert_int_equals(sys.SUCCESS, symproc.process%())
  in.line_num%(0) = 3
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("Sub foo()"))
  assert_int_equals(sys.FAILURE, symproc.process%())
  assert_error("Duplicate FUNCTION/SUB")
End Sub

Sub test_given_start_not_col_1()
  lines$(1) = "  Function my_function()"
  lines$(2) = "End Function"
  lines$(3) = "Print : Sub my_sub()"
  lines$(4) = "End Sub"
  parse_and_process(lines$())

  clear_arrays()
  assert_int_equals(3, sym.get_functions%(actual$()))
  expected$(0) = symproc.GLOBAL_SCOPE + ",0,1,0,0,0:0,0:0"
  expected$(1) = "my_function,0,1,4,1,1:3,2:12"
  expected$(2) = "my_sub,0,3,8,2,3:9,4:7"
  assert_string_array_equals(expected$(), actual$())
End Sub

Sub test_given_end_not_last_tok()
  lines$(1) = "Function my_function()"
  lines$(2) = "End Function  "
  lines$(3) = "Sub my_sub()"
  lines$(4) = "End Sub : Print"
  parse_and_process(lines$())

  clear_arrays()
  assert_int_equals(3, sym.get_functions%(actual$()))
  expected$(0) = symproc.GLOBAL_SCOPE + ",0,1,0,0,0:0,0:0"
  expected$(1) = "my_function,0,1,4,1,1:1,2:12"
  expected$(2) = "my_sub,0,3,8,2,3:1,4:7"
  assert_string_array_equals(expected$(), actual$())
End Sub

Sub test_given_leading_comment()
  lines$(1) = "Function my_function()"
  lines$(2) = "End Function"
  lines$(3) = "' Unrelated comment"
  lines$(4) = ""
  lines$(5) = "' Unrelated comment"
  lines$(6) = "Dim foo"
  lines$(7) = "' Comment about my_sub()"
  lines$(8) = "' More comments"
  lines$(9) = "Sub my_sub()"
  lines$(10) = "End Sub"
  parse_and_process(lines$())

  clear_arrays()
  assert_int_equals(3, sym.get_functions%(actual$()))
  expected$(0) = symproc.GLOBAL_SCOPE + ",0,1,0,0,0:0,0:0"
  expected$(1) = "my_function,0,1,4,1,1:1,2:12"
  expected$(2) = "my_sub,0,9,16,3,7:1,10:7"
  assert_string_array_equals(expected$(), actual$())
End Sub

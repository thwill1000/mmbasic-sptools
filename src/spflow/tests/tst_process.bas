' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

#Include "../options.inc"
#Include "../process.inc"
#Include "../../common/error.inc"
#Include "../../common/list.inc"
#Include "../../common/map.inc"
#Include "../../common/set.inc"
#Include "../../sptest/unittest.inc"
#Include "../../sptrans/lexer.inc"

Dim in_files$(1)
Dim in_files_sz = 1
in_files$(0) = "input.bas"
Dim in_line_num(1)

add_test("test_simple_sub")
add_test("test_simple_fn")
add_test("test_self_recursive_sub")
add_test("test_self_recursive_fn")

run_tests()

End

Sub setup_test()
  op_init()
  pr_init()
End Sub

Sub teardown_test()
End Sub

Function test_simple_sub()
  Local lines$(7)
  lines$(1) = "Sub foo()"
  lines$(2) = "  bar()"
  lines$(3) = "End Sub"
  lines$(4) = "Sub bar()"
  lines$(5) = "  ' do something"
  lines$(6) = "End Sub"
  lines$(7) = "foo()"

  Local pass
  For pass = 1 To 2
    For in_line_num(0) = 1 To 7
      lx_parse_basic(lines$(in_line_num(0)))
      process(pass)
    Next in_line_num(0)
    pass_completed(pass)
  Next pass

  ' Check the contents of the 'subs' map.
  assert_string_equals("*global*", subs_k$(0))
  assert_string_equals("*GLOBAL*,input.bas,1,3", subs_v$(0))
  assert_string_equals("bar", subs_k$(1))
  assert_string_equals("bar,input.bas,4,2", subs_v$(1))
  assert_string_equals("foo", subs_k$(2))
  assert_string_equals("foo,input.bas,1,0", subs_v$(2))

  ' Check the contents of 'all_calls()'.
  assert_equals(5, all_calls_sz)
  assert_equals(1, all_calls(0))
  assert_equals(-1, all_calls(1))
  assert_equals(-1, all_calls(2))
  assert_equals(2, all_calls(3))
  assert_equals(-1, all_calls(4))

End Function

Function test_simple_fn()
  Local lines$(7)
  lines$(1) = "Function foo()"
  lines$(2) = "  foo = 2"
  lines$(3) = "End Function"
  lines$(4) = "a = foo()"

  Local pass
  For pass = 1 To 2
    For in_line_num(0) = 1 To 4
      lx_parse_basic(lines$(in_line_num(0)))
      process(pass)
    Next in_line_num(0)
    pass_completed(pass)
  Next pass

  ' Check the contents of the 'subs' map.
  assert_string_equals("*global*", subs_k$(0))
  assert_string_equals("*GLOBAL*,input.bas,1,1", subs_v$(0))
  assert_string_equals("foo", subs_k$(1))
  assert_string_equals("foo,input.bas,1,0", subs_v$(1))

  ' Check the contents of 'all_calls()'.
  assert_equals(3, all_calls_sz)
  assert_equals(-1, all_calls(0)) ' foo() calls nothing
  assert_equals( 1, all_calls(1)) ' *global* calls foo()
  assert_equals(-1, all_calls(2))

End Function

Function test_self_recursive_sub()
  Local lines$(4)
  lines$(1) = "Sub foo()"
  lines$(2) = "  foo()
  lines$(3) = "End Sub"
  lines$(4) = "foo()"

  Local pass
  For pass = 1 To 2
    For in_line_num(0) = 1 To 4
      lx_parse_basic(lines$(in_line_num(0)))
      process(pass)
    Next in_line_num(0)
    pass_completed(pass)
  Next pass

  ' Check the contents of the 'subs' map.
  assert_string_equals("*global*", subs_k$(0))
  assert_string_equals("*GLOBAL*,input.bas,1,2", subs_v$(0))
  assert_string_equals("foo", subs_k$(1))
  assert_string_equals("foo,input.bas,1,0", subs_v$(1))

  ' Check the contents of 'all_calls()'.
  assert_equals(4, all_calls_sz)
  assert_equals(1, all_calls(0))
  assert_equals(-1, all_calls(1))
  assert_equals(1, all_calls(2))
  assert_equals(-1, all_calls(3))

End Function

Function test_self_recursive_fn()
  Local lines$(4)
  lines$(1) = "Function foo()"
  lines$(2) = "  foo = foo()
  lines$(3) = "End Function"
  lines$(4) = "a = foo()"

  Local pass
  For pass = 1 To 2
    For in_line_num(0) = 1 To 4
      lx_parse_basic(lines$(in_line_num(0)))
      process(pass)
    Next in_line_num(0)
    pass_completed(pass)
  Next pass

  ' Check the contents of the 'subs' map.
  assert_string_equals("*global*", subs_k$(0))
  assert_string_equals("*GLOBAL*,input.bas,1,2", subs_v$(0))
  assert_string_equals("foo", subs_k$(1))
  assert_string_equals("foo,input.bas,1,0", subs_v$(1))

  ' Check the contents of 'all_calls()'.
  assert_equals(4, all_calls_sz)
  assert_equals(1, all_calls(0))
  assert_equals(-1, all_calls(1))
  assert_equals(1, all_calls(2))
  assert_equals(-1, all_calls(3))

End Function


' Copyright (c) 2020-2021 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.06

Option Explicit On
Option Default Integer

#Include "../../common/system.inc"
#Include "../../common/array.inc"
#Include "../../common/list.inc"
#Include "../../common/string.inc"
#Include "../../common/file.inc"
#Include "../../common/map.inc"
#Include "../../common/set.inc"
#Include "../../common/vt100.inc"
#Include "../../sptest/unittest.inc"
#Include "../../sptrans/keywords.inc"
#Include "../../sptrans/lexer.inc"
#Include "../options.inc"
#Include "../process.inc"

Dim in.files$(1)
Dim in.num_open_files = 1
in.files$(0) = "input.bas"
Dim in.line_num(1)

add_test("test_simple_sub")
add_test("test_simple_fn")
add_test("test_self_recursive_sub")
add_test("test_self_recursive_fn")

run_tests()

End

Sub setup_test()
  opt.init()
  pro.init()
End Sub

Sub teardown_test()
End Sub

Sub test_simple_sub()
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
    For in.line_num(0) = 1 To 7
      lx.parse_basic(lines$(in.line_num(0)))
      process(pass)
    Next in.line_num(0)
    pass_completed(pass)
  Next pass

  ' Check the contents of the 'subs' map.
  assert_int_equals(3, map.size%(subs$()))
  assert_string_equals("*GLOBAL*,input.bas,1,3", map.get$(subs$(), "*global*"))
  assert_string_equals("bar,input.bas,4,2", map.get$(subs$(), "bar"))
  assert_string_equals("foo,input.bas,1,0", map.get$(subs$(), "foo"))

  ' Check the contents of 'all_calls()'.
  assert_int_equals(5, all_calls_sz)
  assert_int_equals(1, all_calls(0))
  assert_int_equals(-1, all_calls(1))
  assert_int_equals(-1, all_calls(2))
  assert_int_equals(2, all_calls(3))
  assert_int_equals(-1, all_calls(4))

End Sub

Sub test_simple_fn()
  Local lines$(7)
  lines$(1) = "Sub foo()"
  lines$(2) = "  foo = 2"
  lines$(3) = "End Sub"
  lines$(4) = "a = foo()"

  Local pass
  For pass = 1 To 2
    For in.line_num(0) = 1 To 4
      lx.parse_basic(lines$(in.line_num(0)))
      process(pass)
    Next in.line_num(0)
    pass_completed(pass)
  Next pass

  ' Check the contents of the 'subs' map.
  assert_int_equals(2, map.size%(subs$()))
  assert_string_equals("*GLOBAL*,input.bas,1,1", map.get$(subs$(), "*global*"))
  assert_string_equals("foo,input.bas,1,0", map.get$(subs$(), "foo"))

  ' Check the contents of 'all_calls()'.
  assert_int_equals(3, all_calls_sz)
  assert_int_equals(-1, all_calls(0)) ' foo() calls nothing
  assert_int_equals( 1, all_calls(1)) ' *global* calls foo()
  assert_int_equals(-1, all_calls(2))

End Sub

Sub test_self_recursive_sub()
  Local lines$(4)
  lines$(1) = "Sub foo()"
  lines$(2) = "  foo()"
  lines$(3) = "End Sub"
  lines$(4) = "foo()"

  Local pass
  For pass = 1 To 2
    For in.line_num(0) = 1 To 4
      lx.parse_basic(lines$(in.line_num(0)))
      process(pass)
    Next in.line_num(0)
    pass_completed(pass)
  Next pass

  ' Check the contents of the 'subs' map.
  assert_int_equals(2, map.size%(subs$()))
  assert_string_equals("*GLOBAL*,input.bas,1,2", map.get$(subs$(), "*global*"))
  assert_string_equals("foo,input.bas,1,0", map.get$(subs$(), "foo"))

  ' Check the contents of 'all_calls()'.
  assert_int_equals(4, all_calls_sz)
  assert_int_equals(1, all_calls(0))
  assert_int_equals(-1, all_calls(1))
  assert_int_equals(1, all_calls(2))
  assert_int_equals(-1, all_calls(3))

End Sub

Sub test_self_recursive_fn()
  Local lines$(4)
  lines$(1) = "Sub foo()"
  lines$(2) = "  foo = foo()"
  lines$(3) = "End Sub"
  lines$(4) = "a = foo()"

  Local pass
  For pass = 1 To 2
    For in.line_num(0) = 1 To 4
      lx.parse_basic(lines$(in.line_num(0)))
      process(pass)
    Next in.line_num(0)
    pass_completed(pass)
  Next pass

  ' Check the contents of the 'subs' map.
  assert_int_equals(2, map.size%(subs$()))
  assert_string_equals("*GLOBAL*,input.bas,1,2", map.get$(subs$(), "*global*"))
  assert_string_equals("foo,input.bas,1,0", map.get$(subs$(), "foo"))

  ' Check the contents of 'all_calls()'.
  assert_int_equals(4, all_calls_sz)
  assert_int_equals(1, all_calls(0))
  assert_int_equals(-1, all_calls(1))
  assert_int_equals(1, all_calls(2))
  assert_int_equals(-1, all_calls(3))

End Sub

' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

#Include "../error.inc"
#Include "../file.inc"
#Include "../list.inc"
#Include "../set.inc"
#Include "../../sptest/unittest.inc"

add_test("test_init")
add_test("test_capacity")
add_test("test_clear")
add_test("test_clear_given_empty")
add_test("test_clear_given_full")
add_test("test_get")
add_test("test_put")
add_test("test_put_given_present")
add_test("test_put_given_full")
add_test("test_remove")

run_tests()

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Function test_init()
  Local my_set$(set.new%(20))
  set.init(my_set$())

  Local i%
  For i% = 0 To 19
    assert_string_equals(set.NULL$, my_set$(i%))
  Next
End Function

Function test_capacity()
  Local my_set$(set.new%(20))
  set.init(my_set$())

  assert_equals(20, set.capacity%(my_set$()))
End Function

Function test_clear()
  Local my_set$(set.new%(20))
  set.init(my_set$())

  set.put(my_set$(), "foo")
  set.put(my_set$(), "bar")

  set.clear(my_set$())

  assert_equals(0, set.size%(my_set$()))
  Local i%
  For i% = 0 To 19 : assert_string_equals(set.NULL$, my_set$(i%)) : Next
End Function

Function test_clear_given_empty()
  Local my_set$(set.new%(20))
  set.init(my_set$())

  set.clear(my_set$())

  assert_equals(0, set.size%(my_set$()))
  Local i%
  For i% = 0 To 19 : assert_string_equals(set.NULL$, my_set$(i%)) : Next
End Function

Function test_clear_given_full()
  Local my_set$(set.new%(20))
  set.init(my_set$())

  Local i%
  For i% = 0 To 19 : set.put(my_set$(), "item" + Str$(i%)) : Next
  assert_equals(20, set.size%(my_set$()))

  set.clear(my_set$())

  assert_equals(0, set.size%(my_set$()))
  For i% = 0 To 19 : assert_string_equals(set.NULL$, my_set$(i%)) : Next
End Function

Function test_get()
  Local my_set$(set.new%(20))
  set.init(my_set$())

  set.put(my_set$(), "foo")
  set.put(my_set$(), "bar")

  assert_equals( 0, set.get%(my_set$(), "bar"))
  assert_equals( 1, set.get%(my_set$(), "foo"))
  assert_equals(-1, set.get%(my_set$(), "wombat"))
End Function

Function test_put()
  Local my_set$(set.new%(20))
  set.init(my_set$())

  set.put(my_set$(), "foo")
  set.put(my_set$(), "bar")

  assert_equals(2, set.size%(my_set$()))
  assert_string_equals("bar", my_set$(0))
  assert_string_equals("foo", my_set$(1))
End Function

Function test_put_given_full()
  Local my_set$(set.new%(20))
  set.init(my_set$())

  Local i%
  For i% = 0 To 19 : set.put(my_set$(), "item" + Str$(i%)) : Next
  assert_equals(20, set.size%(my_set$()))

  On Error Ignore
  set.put(my_set$(), "too many")
  assert_true(InStr(Mm.ErrMsg$, "set full") > 0, "Assert failed, expected error not thrown")
  On Error Abort
End Function

Function test_put_given_present()
  Local my_set$(set.new%(20))
  set.init(my_set$())

  set.put(my_set$(), "foo")
  set.put(my_set$(), "bar")

  set.put(my_set$(), "foo")
  set.put(my_set$(), "bar")

  assert_equals(2, set.size%(my_set$()))
  assert_string_equals("bar", my_set$(0))
  assert_string_equals("foo", my_set$(1))
End Function

Function test_remove()
  Local my_set$(set.new%(20))
  set.init(my_set$())

  set.put(my_set$(), "foo")
  set.put(my_set$(), "bar")

  set.remove(my_set$(), "bar")

  assert_equals(1, set.size%(my_set$()))
  assert_equals(0, set.get%(my_set$(), "foo"))
  assert_equals(-1, set.get%(my_set$(), "bar"))

  set.remove(my_set$(), "foo")

  assert_equals(0, set.size%(my_set$()))
  assert_equals(-1, set.get%(my_set$(), "foo"))
  assert_equals(-1, set.get%(my_set$(), "bar"))
End Function

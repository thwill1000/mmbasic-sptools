' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default None

If InStr(Mm.CmdLine$, "--base=1") Then
  Option Base 1
Else
  Option Base 0
EndIf

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

If InStr(Mm.CmdLine$, "--base") Then run_tests() Else run_tests("--base=1")

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Sub test_init()
  Local base% = Mm.Info(Option Base)
  Local my_set$(set.new%(20))
  set.init(my_set$())

  Local i%
  For i% = base% To base% + 19 : assert_string_equals(set.NULL$, my_set$(i%)) : Next
End Sub

Sub test_capacity()
  Local my_set$(set.new%(20))
  set.init(my_set$())

  assert_equals(20, set.capacity%(my_set$()))
End Sub

Sub test_clear()
  Local base% = Mm.Info(Option Base)
  Local my_set$(set.new%(20))
  set.init(my_set$())

  set.put(my_set$(), "foo")
  set.put(my_set$(), "bar")

  set.clear(my_set$())

  assert_equals(0, set.size%(my_set$()))
  Local i%
  For i% = base% To base% + 19 : assert_string_equals(set.NULL$, my_set$(i%)) : Next
End Sub

Sub test_clear_given_empty()
  Local base% = Mm.Info(Option Base)
  Local my_set$(set.new%(20))
  set.init(my_set$())

  set.clear(my_set$())

  assert_equals(0, set.size%(my_set$()))
  Local i%
  For i% = base% To base% + 19 : assert_string_equals(set.NULL$, my_set$(i%)) : Next
End Sub

Sub test_clear_given_full()
  Local base% = Mm.Info(Option Base)
  Local my_set$(set.new%(20))
  set.init(my_set$())

  Local i%
  For i% = base% To base% + 19 : set.put(my_set$(), "item" + Str$(i%)) : Next
  assert_equals(20, set.size%(my_set$()))

  set.clear(my_set$())

  assert_equals(0, set.size%(my_set$()))
  For i% = base% To base% + 19 : assert_string_equals(set.NULL$, my_set$(i%)) : Next
End Sub

Sub test_get()
  Local base% = Mm.Info(Option Base)
  Local my_set$(set.new%(20))
  set.init(my_set$())

  set.put(my_set$(), "foo")
  set.put(my_set$(), "bar")

  assert_equals(base% + 0, set.get%(my_set$(), "bar"))
  assert_equals(base% + 1, set.get%(my_set$(), "foo"))
  assert_equals(-1, set.get%(my_set$(), "wombat"))
End Sub

Sub test_put()
  Local base% = Mm.Info(Option Base)
  Local my_set$(set.new%(20))
  set.init(my_set$())

  set.put(my_set$(), "foo")
  set.put(my_set$(), "bar")

  assert_equals(2, set.size%(my_set$()))
  assert_string_equals("bar", my_set$(base% + 0))
  assert_string_equals("foo", my_set$(base% + 1))
End Sub

Sub test_put_given_full()
  Local base% = Mm.Info(Option Base)
  Local my_set$(set.new%(20))
  set.init(my_set$())

  Local i%
  For i% = base% To base% + 19 : set.put(my_set$(), "item" + Str$(i%)) : Next
  assert_equals(20, set.size%(my_set$()))

  On Error Ignore
  set.put(my_set$(), "too many")
  assert_true(InStr(Mm.ErrMsg$, "set full") > 0, "Assert failed, expected error not thrown")
  On Error Abort
End Sub

Sub test_put_given_present()
  Local base% = Mm.Info(Option Base)
  Local my_set$(set.new%(20))
  set.init(my_set$())

  set.put(my_set$(), "foo")
  set.put(my_set$(), "bar")

  set.put(my_set$(), "foo")
  set.put(my_set$(), "bar")

  assert_equals(2, set.size%(my_set$()))
  assert_string_equals("bar", my_set$(base% + 0))
  assert_string_equals("foo", my_set$(base% + 1))
End Sub

Sub test_remove()
  Local base% = Mm.Info(Option Base)
  Local my_set$(set.new%(20))
  set.init(my_set$())

  set.put(my_set$(), "foo")
  set.put(my_set$(), "bar")

  set.remove(my_set$(), "bar")

  assert_equals(1, set.size%(my_set$()))
  assert_equals(base% + 0, set.get%(my_set$(), "foo"))
  assert_equals(-1, set.get%(my_set$(), "bar"))

  set.remove(my_set$(), "foo")

  assert_equals(0, set.size%(my_set$()))
  assert_equals(-1, set.get%(my_set$(), "foo"))
  assert_equals(-1, set.get%(my_set$(), "bar"))
End Sub

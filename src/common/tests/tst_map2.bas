' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

#Include "../error.inc"
#Include "../file.inc"
#Include "../list.inc"
#Include "../map2.inc"
#Include "../set.inc"
#Include "../../sptest/unittest.inc"

add_test("test_init")
add_test("test_clear")
add_test("test_clear_given_empty")
add_test("test_clear_given_full")
add_test("test_get")
add_test("test_put")
add_test("test_put_given_full")
add_test("test_put_given_present")
add_test("test_remove")
add_test("test_remove_given_absent")
add_test("test_remove_given_empty")
add_test("test_remove_given_full")

run_tests()

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Function test_init()
  Local my_map$(map2.new%(20))
  map2.init(my_map$())

  Local i%
  For i% = 0 To 39 : assert_string_equals(map2.NULL$, my_map$(i%)) : Next
  assert_string_equals("0", my_map$(40));
  assert_equals(0, map2.size%(my_map$()));
  assert_equals(20, map2.capacity%(my_map$()));
End Function

Function test_clear()
  Local my_map$(map2.new%(20))
  map2.init(my_map$())

  map2.put(my_map$(), "foo", "bar")
  map2.put(my_map$(), "wom", "bat")
  map2.put(my_map$(), "aaa", "bbb")

  map2.clear(my_map$())

  Local i%
  For i% = 0 To 39 : assert_string_equals(map2.NULL$, my_map$(i%)) : Next
  assert_string_equals("0", my_map$(40));
  assert_equals(0, map2.size%(my_map$()));
End Function

Function test_clear_given_empty()
  Local my_map$(map2.new%(20))
  map2.init(my_map$())

  map2.clear(my_map$())

  Local i%
  For i% = 0 To 39 : assert_string_equals(map2.NULL$, my_map$(i%)) : Next
  assert_string_equals("0", my_map$(40));
  assert_equals(0, map2.size%(my_map$()));
End Function

Function test_clear_given_full()
  Local my_map$(map2.new%(20))
  map2.init(my_map$())
  Local i%
  For i% = 0 To 19 : map2.put(my_map$(), "key" + Str$(i%), "value" + Str$(i%)) : Next

  map2.clear(my_map$())

  For i% = 0 To 39 : assert_string_equals(map2.NULL$, my_map$(i%)) : Next
  assert_string_equals("0", my_map$(40));
  assert_equals(0, map2.size%(my_map$()));
End Function

Function test_get()
  Local my_map$(map2.new%(20))
  map2.init(my_map$())

  map2.put(my_map$(), "foo", "bar")
  map2.put(my_map$(), "wom", "bat")
  map2.put(my_map$(), "aaa", "bbb")

  assert_string_equals("bar", map2.get$(my_map$(), "foo"))
  assert_string_equals("bat", map2.get$(my_map$(), "wom"))
  assert_string_equals("bbb", map2.get$(my_map$(), "aaa"))
  assert_string_equals(map2.NULL$, map2.get$(my_map$(), "unknown"))
End Function

Function test_put()
  Local my_map$(map2.new%(20))
  map2.init(my_map$())

  map2.put(my_map$(), "foo", "bar")
  map2.put(my_map$(), "wom", "bat")
  map2.put(my_map$(), "aaa", "bbb")

  assert_equals(3, map2.size%(my_map$()))
  assert_string_equals("aaa", my_map$(0))
  assert_string_equals("bbb", my_map$(0 + 20))
  assert_string_equals("foo", my_map$(1))
  assert_string_equals("bar", my_map$(1 + 20))
  assert_string_equals("wom", my_map$(2))
  assert_string_equals("bat", my_map$(2 + 20))
End Function

Function test_put_given_full()
  Local my_map$(map2.new%(20))
  map2.init(my_map$())
  Local i%
  For i% = 0 To 19 : map2.put(my_map$(), "key" + Str$(i%), "value" + Str$(i%)) : Next

  ' Assert reports 'map full' error.
  On Error Ignore
  map2.put(my_map$(), "too many", "value"))
  assert_true(InStr(Mm.ErrMsg$, "map full") > 0, "Assert failed, expected error not thrown")
  On Error Abort
  assert_equals(20, map2.size%(my_map$()))

  ' Unless the key already exists.
  map2.put(my_map$(), "key15", "value")
  assert_string_equals("value", map2.get$(my_map$(), "key15"))
  assert_equals(20, map2.size%(my_map$()))
End Function

Function test_put_given_present()
  Local my_map$(map2.new%(20))
  map2.init(my_map$())

  map2.put(my_map$(), "foo", "bar")
  map2.put(my_map$(), "wom", "bat")
  map2.put(my_map$(), "aaa", "bbb")

  map2.put(my_map$(), "foo", "bar2")
  map2.put(my_map$(), "wom", "bat2")
  map2.put(my_map$(), "aaa", "bbb2")

  assert_equals(3, map2.size%(my_map$()))
  assert_string_equals("aaa",  my_map$(0))
  assert_string_equals("bbb2", my_map$(0 + 20))
  assert_string_equals("foo",  my_map$(1))
  assert_string_equals("bar2", my_map$(1 + 20))
  assert_string_equals("wom",  my_map$(2))
  assert_string_equals("bat2", my_map$(2 + 20))
End Function

Function test_remove()
  Local my_map$(map2.new%(20))
  map2.init(my_map$())

  map2.put(my_map$(), "foo", "bar")
  map2.put(my_map$(), "wom", "bat")
  map2.put(my_map$(), "aaa", "bbb")

  map2.remove(my_map$(), "wom")

  assert_equals(2, map2.size%(my_map$()))
  assert_string_equals("aaa",      my_map$(0))
  assert_string_equals("bbb",      my_map$(0 + 20))
  assert_string_equals("foo",      my_map$(1))
  assert_string_equals("bar",      my_map$(1 + 20))
  assert_string_equals(map2.NULL$, my_map$(2))
  assert_string_equals(map2.NULL$, my_map$(2 + 20))

  map2.remove(my_map$(), "aaa")

  assert_equals(1, map2.size%(my_map$()))
  assert_string_equals("foo", my_map$(0))
  assert_string_equals("bar", my_map$(0 + 20))
  assert_string_equals(map2.NULL$, my_map$(1))
  assert_string_equals(map2.NULL$, my_map$(1 + 20))

  map2.remove(my_map$(), "foo")

  assert_equals(0, map2.size%(my_map$()))
  assert_string_equals(map2.NULL$, my_map$(0))
  assert_string_equals(map2.NULL$, my_map$(0 + 20))
End Function

Function test_remove_given_absent()
  Local my_map$(map2.new%(20))
  map2.init(my_map$())
  map2.put(my_map$(), "foo", "bar")
  map2.put(my_map$(), "wom", "bat")
  map2.put(my_map$(), "aaa", "bbb")

  map2.remove(my_map$(), "absent")

  assert_equals(3, map2.size%(my_map$()))
  assert_string_equals("aaa", my_map$(0))
  assert_string_equals("bbb", my_map$(0 + 20))
  assert_string_equals("foo", my_map$(1))
  assert_string_equals("bar", my_map$(1 + 20))
  assert_string_equals("wom", my_map$(2))
  assert_string_equals("bat", my_map$(2 + 20))
End Function

Function test_remove_given_empty()
  Local my_map$(map2.new%(20))
  map2.init(my_map$())

  map2.remove(my_map$(), "absent")

  Local i%
  For i% = 0 To 39 : assert_string_equals(map2.NULL$, my_map$(i%)) : Next
  assert_string_equals("0", my_map$(40));
  assert_equals(0, map2.size%(my_map$()));
End Function

Function test_remove_given_full()
  Local my_map$(map2.new%(20))
  map2.init(my_map$())
  Local i%
  For i% = 0 To 19 : map2.put(my_map$(), "key" + Str$(i%), "value" + Str$(i%)) : Next

  map2.remove(my_map$(), "key15")

  For i% = 0 To 19
    If i% <> 15 Then
      assert_string_equals("value" + Str$(i%), map2.get$(my_map$(), "key" + Str$(i%)))
    Else
      assert_string_equals(map2.NULL$, map2.get$(my_map$(), "key" + Str$(i%)))
    EndIf
  Next
  assert_string_equals("19", my_map$(40));
  assert_equals(19, map2.size%(my_map$()));
End Function

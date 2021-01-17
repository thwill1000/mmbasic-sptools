' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default None

If InStr(Mm.CmdLine$, "--base=1") Then
  Option Base 1
Else
  Option Base 0
EndIf

#Include "../system.inc"
#Include "../array.inc"
#Include "../list.inc"
#Include "../string.inc"
#Include "../file.inc"
#Include "../map.inc"
#Include "../vt100.inc"
#Include "../../sptest/unittest.inc"

add_test("test_init")
add_test("test_clear")
add_test("test_clear_given_empty")
add_test("test_clear_given_full")
add_test("test_get_key_index")
add_test("test_get")
add_test("test_put")
add_test("test_put_given_full")
add_test("test_put_given_present")
add_test("test_remove")
add_test("test_remove_given_absent")
add_test("test_remove_given_empty")
add_test("test_remove_given_full")

If InStr(Mm.CmdLine$, "--base") Then run_tests() Else run_tests("--base=1")

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Sub test_init()
  Local base% = Mm.Info(Option Base)
  Local my_map$(map.new%(20))
  map.init(my_map$())

  Local i%
  For i% = base% To base% + 39 : assert_string_equals(sys.NO_DATA$, my_map$(i%)) : Next
  assert_string_equals("0", my_map$(base% + 40));
  assert_int_equals(0, map.size%(my_map$()));
  assert_int_equals(20, map.capacity%(my_map$()));
End Sub

Sub test_clear()
  Local base% = Mm.Info(Option Base)
  Local my_map$(map.new%(20))
  map.init(my_map$())

  map.put(my_map$(), "foo", "bar")
  map.put(my_map$(), "wom", "bat")
  map.put(my_map$(), "aaa", "bbb")

  map.clear(my_map$())

  Local i%
  For i% = base% To base% + 39 : assert_string_equals(sys.NO_DATA$, my_map$(i%)) : Next
  assert_string_equals("0", my_map$(base% + 40));
  assert_int_equals(0, map.size%(my_map$()));
End Sub

Sub test_clear_given_empty()
  Local base% = Mm.Info(Option Base)
  Local my_map$(map.new%(20))
  map.init(my_map$())

  map.clear(my_map$())

  Local i%
  For i% = base% To base% + 39 : assert_string_equals(sys.NO_DATA$, my_map$(i%)) : Next
  assert_string_equals("0", my_map$(base% + 40));
  assert_int_equals(0, map.size%(my_map$()));
End Sub

Sub test_clear_given_full()
  Local base% = Mm.Info(Option Base)
  Local my_map$(map.new%(20))
  map.init(my_map$())
  Local i%
  For i% = base% To base% + 19 : map.put(my_map$(), "key" + Str$(i%), "value" + Str$(i%)) : Next

  map.clear(my_map$())

  For i% = base% To base% + 39 : assert_string_equals(sys.NO_DATA$, my_map$(i%)) : Next
  assert_string_equals("0", my_map$(base% + 40));
  assert_int_equals(0, map.size%(my_map$()));
End Sub

Sub test_get_key_index()
  Local base% = Mm.Info(Option Base)
  Local my_map$(map.new%(20))
  map.init(my_map$())

  map.put(my_map$(), "foo", "bar")
  map.put(my_map$(), "wom", "bat")
  map.put(my_map$(), "aaa", "bbb")

  assert_int_equals(base%,     map.get_key_index%(my_map$(), "aaa"))
  assert_int_equals(base% + 1, map.get_key_index%(my_map$(), "foo"))
  assert_int_equals(base% + 2, map.get_key_index%(my_map$(), "wom"))
  assert_int_equals(-1,        map.get_key_index%(my_map$(), "unknown"))
End Sub

Sub test_get()
  Local my_map$(map.new%(20))
  map.init(my_map$())

  map.put(my_map$(), "foo", "bar")
  map.put(my_map$(), "wom", "bat")
  map.put(my_map$(), "aaa", "bbb")

  assert_string_equals("bar",        map.get$(my_map$(), "foo"))
  assert_string_equals("bat",        map.get$(my_map$(), "wom"))
  assert_string_equals("bbb",        map.get$(my_map$(), "aaa"))
  assert_string_equals(sys.NO_DATA$, map.get$(my_map$(), "unknown"))
End Sub

Sub test_put()
  Local base% = Mm.Info(Option Base)
  Local my_map$(map.new%(20))
  map.init(my_map$())

  map.put(my_map$(), "foo", "bar")
  map.put(my_map$(), "wom", "bat")
  map.put(my_map$(), "aaa", "bbb")

  assert_int_equals(3, map.size%(my_map$()))
  assert_string_equals("aaa", my_map$(base% + 0))
  assert_string_equals("bbb", my_map$(base% + 0 + 20))
  assert_string_equals("foo", my_map$(base% + 1))
  assert_string_equals("bar", my_map$(base% + 1 + 20))
  assert_string_equals("wom", my_map$(base% + 2))
  assert_string_equals("bat", my_map$(base% + 2 + 20))
End Sub

Sub test_put_given_full()
  Local base% = Mm.Info(Option Base)
  Local my_map$(map.new%(20))
  map.init(my_map$())
  Local i%
  For i% = base% To base% + 19 : map.put(my_map$(), "key" + Str$(i%), "value" + Str$(i%)) : Next

  ' Assert reports 'map full' error.
  On Error Ignore
  map.put(my_map$(), "too many", "value"))
  assert_true(InStr(Mm.ErrMsg$, "map full") > 0, "Assert failed, expected error not thrown")
  On Error Abort
  assert_int_equals(20, map.size%(my_map$()))

  ' Unless the key already exists.
  map.put(my_map$(), "key15", "value")
  assert_string_equals("value", map.get$(my_map$(), "key15"))
  assert_int_equals(20, map.size%(my_map$()))
End Sub

Sub test_put_given_present()
  Local base% = Mm.Info(Option Base)
  Local my_map$(map.new%(20))
  map.init(my_map$())

  map.put(my_map$(), "foo", "bar")
  map.put(my_map$(), "wom", "bat")
  map.put(my_map$(), "aaa", "bbb")

  map.put(my_map$(), "foo", "bar2")
  map.put(my_map$(), "wom", "bat2")
  map.put(my_map$(), "aaa", "bbb2")

  assert_int_equals(3, map.size%(my_map$()))
  assert_string_equals("aaa",  my_map$(base% + 0))
  assert_string_equals("bbb2", my_map$(base% + 0 + 20))
  assert_string_equals("foo",  my_map$(base% + 1))
  assert_string_equals("bar2", my_map$(base% + 1 + 20))
  assert_string_equals("wom",  my_map$(base% + 2))
  assert_string_equals("bat2", my_map$(base% + 2 + 20))
End Sub

Sub test_remove()
  Local base% = Mm.Info(Option Base)
  Local my_map$(map.new%(20))
  map.init(my_map$())

  map.put(my_map$(), "foo", "bar")
  map.put(my_map$(), "wom", "bat")
  map.put(my_map$(), "aaa", "bbb")

  map.remove(my_map$(), "wom")

  assert_int_equals(2, map.size%(my_map$()))
  assert_string_equals("aaa",        my_map$(base% + 0))
  assert_string_equals("bbb",        my_map$(base% + 0 + 20))
  assert_string_equals("foo",        my_map$(base% + 1))
  assert_string_equals("bar",        my_map$(base% + 1 + 20))
  assert_string_equals(sys.NO_DATA$, my_map$(base% + 2))
  assert_string_equals(sys.NO_DATA$, my_map$(base% + 2 + 20))

  map.remove(my_map$(), "aaa")

  assert_int_equals(1, map.size%(my_map$()))
  assert_string_equals("foo",        my_map$(base% + 0))
  assert_string_equals("bar",        my_map$(base% + 0 + 20))
  assert_string_equals(sys.NO_DATA$, my_map$(base% + 1))
  assert_string_equals(sys.NO_DATA$, my_map$(base% + 1 + 20))

  map.remove(my_map$(), "foo")

  assert_int_equals(0, map.size%(my_map$()))
  assert_string_equals(sys.NO_DATA$, my_map$(base% + 0))
  assert_string_equals(sys.NO_DATA$, my_map$(base% + 0 + 20))
End Sub

Sub test_remove_given_absent()
  Local base% = Mm.Info(Option Base)
  Local my_map$(map.new%(20))
  map.init(my_map$())
  map.put(my_map$(), "foo", "bar")
  map.put(my_map$(), "wom", "bat")
  map.put(my_map$(), "aaa", "bbb")

  map.remove(my_map$(), "absent")

  assert_int_equals(3, map.size%(my_map$()))
  assert_string_equals("aaa", my_map$(base% + 0))
  assert_string_equals("bbb", my_map$(base% + 0 + 20))
  assert_string_equals("foo", my_map$(base% + 1))
  assert_string_equals("bar", my_map$(base% + 1 + 20))
  assert_string_equals("wom", my_map$(base% + 2))
  assert_string_equals("bat", my_map$(base% + 2 + 20))
End Sub

Sub test_remove_given_empty()
  Local base% = Mm.Info(Option Base)
  Local my_map$(map.new%(20))
  map.init(my_map$())

  map.remove(my_map$(), "absent")

  Local i%
  For i% = base% To base% + 39 : assert_string_equals(sys.NO_DATA$, my_map$(i%)) : Next
  assert_string_equals("0", my_map$(base% + 40));
  assert_int_equals(0, map.size%(my_map$()));
End Sub

Sub test_remove_given_full()
  Local base% = Mm.Info(Option Base)
  Local my_map$(map.new%(20))
  map.init(my_map$())
  Local i%
  For i% = base% To base% + 19 : map.put(my_map$(), "key" + Str$(i%), "value" + Str$(i%)) : Next

  map.remove(my_map$(), "key15")

  For i% = base% To base% + 19
    If i% <> 15 Then
      assert_string_equals("value" + Str$(i%), map.get$(my_map$(), "key" + Str$(i%)))
    Else
      assert_string_equals(sys.NO_DATA$, map.get$(my_map$(), "key" + Str$(i%)))
    EndIf
  Next
  assert_string_equals("19", my_map$(base% + 40));
  assert_int_equals(19, map.size%(my_map$()));
End Sub

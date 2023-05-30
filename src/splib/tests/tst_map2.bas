' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For Colour Maximite 2, MMBasic 5.07

Option Explicit On
Option Default None
Option Base InStr(Mm.CmdLine$, "--base=1") > 0

#Include "../system.inc"
#Include "../array.inc"
#Include "../list.inc"
#Include "../string.inc"
#Include "../file.inc"
#Include "../map.inc"
#Include "../map2.inc"
#Include "../vt100.inc"
#Include "../../sptest/unittest.inc"

add_test("test_new")
add_test("test_init")
add_test("test_init_given_invalid_key_len")
add_test("test_put")
add_test("test_put_given_full")
add_test("test_put_given_key_too_long")
add_test("test_put_sorts_entries")
add_test("test_put_if_absent_given_absent")
add_test("test_get_given_present")
add_test("test_get_given_absent")
add_test("test_remove_given_present")
add_test("test_remove_given_absent")
add_test("test_size")
add_test("test_is_full")
add_test("test_clear")
add_test("test_capacity")

If InStr(Mm.CmdLine$, "--base") Then run_tests() Else run_tests("--base=1")

End

Sub test_new()
  assert_int_equals(Choice(Mm.Info(Option Base) = 0, 10, 11), map2.new%(10))
End Sub

Sub test_init()
  Local i%, mp$(map2.new%(10))
  Const lb% = Bound(mp$(), 0), ub% = Bound(mp$(), 1)

  map2.init(mp$(), 8)

  For i% = lb% To ub% - 1
    assert_string_equals(sys.NO_DATA$, mp$(i%))
  Next
  assert_string_equals("8,0", mp$(ub%))
End Sub

Sub test_init_given_invalid_key_len()
  Local mp$(map2.new%(10))

  On Error Ignore
  map2.init(mp$())
  assert_raw_error("Invalid key length, must be > 0")

  On Error Ignore
  map2.init(mp$(), 0)
  assert_raw_error("Invalid key length, must be > 0")

  On Error Ignore
  map2.init(mp$(), -1)
  assert_raw_error("Invalid key length, must be > 0")
End Sub

Sub test_put()
  Local mp$(map2.new%(10))
  Const lb% = Bound(mp$(), 0), ub% = Bound(mp$(), 1)
  map2.init(mp$(), 8)

  map2.put(mp$(), "foo", "bar")
  assert_string_equals("foo     bar", mp$(lb%))
  assert_string_equals("8,1", mp$(ub%))

  map2.put(mp$(), "wom", "bat")
  assert_string_equals("wom     bat", mp$(lb% + 1))
  assert_string_equals("8,2", mp$(ub%))
End Sub

Sub test_put_given_full()
  Local i%, mp$(map2.new%(10))
  Const lb% = Bound(mp$(), 0), ub% = Bound(mp$(), 1)
  map2.init(mp$(), 8)
  For i% = lb% To ub% - 1
    map2.put(mp$(), "key_" + Str$(i%), "value_" + Str$(i%))
  Next

  On Error Ignore
  map2.put(mp$(), "foo", "bar")
  assert_raw_error("Map full")

  assert_int_equals(10, map2.size%(mp$()))
  For i% = lb% To ub% - 1
    assert_string_equals("value_" + Str$(i%), map2.get$(mp$(), "key_" + Str$(i%)))
  Next
  assert_string_equals("8,10", mp$(ub%))
End Sub

Sub test_put_given_key_too_long()
  Local i%, mp$(map2.new%(10))
  Const lb% = Bound(mp$(), 0), ub% = Bound(mp$(), 1)
  map2.init(mp$(), 8)

  map2.put(mp$(), "12345678", "bar")
  assert_string_equals("bar", map2.get$(mp$(), "12345678"))

  On Error Ignore
  map2.put(mp$(), "123456789", "bat")
  assert_raw_error("Key too long")

  assert_int_equals(1, map2.size%(mp$()))
End Sub

Sub test_put_sorts_entries()
  Local i%, mp$(map2.new%(5))
  Const lb% = Bound(mp$(), 0), ub% = Bound(mp$(), 1)
  Local keys$(array.new%(5)) = ("one", "two", "three", "four", "five")
  map2.init(mp$(), 8)

  For i% = lb% To ub% - 1
    map2.put(mp$(), keys$(i%), "value_" + keys$(i%))
  Next

  assert_string_equals("five    value_five", mp$(lb% + 0))
  assert_string_equals("four    value_four", mp$(lb% + 1))
  assert_string_equals("one     value_one", mp$(lb% + 2))
  assert_string_equals("three   value_three", mp$(lb% + 3))
  assert_string_equals("two     value_two", mp$(lb% + 4))
End Sub

Sub test_put_if_absent_given_absent()
  Local mp$(map2.new%(10))
  Const lb% = Bound(mp$(), 0), ub% = Bound(mp$(), 1)
  map2.init(mp$(), 8)

  assert_string_equals("bar", map2.put_if_absent$(mp$(), "foo", "bar"))
  assert_string_equals("foo     bar", mp$(lb%))
  assert_string_equals("8,1", mp$(ub%))

  assert_string_equals("bat", map2.put_if_absent$(mp$(), "wom", "bat"))
  assert_string_equals("wom     bat", mp$(lb% + 1))
  assert_string_equals("8,2", mp$(ub%))
End Sub

Sub test_get_given_present()
  Local mp$(map2.new%(10))
  Const lb% = Bound(mp$(), 0), ub% = Bound(mp$(), 1)
  map2.init(mp$(), 8)
  map2.put(mp$(), "foo", "bar")
  map2.put(mp$(), "wom", "bat")

  assert_string_equals("bar", map2.get$(mp$(), "foo"))
  assert_string_equals("bat", map2.get$(mp$(), "wom"))
End Sub

Sub test_get_given_absent()
  Local mp$(map2.new%(10))
  Const lb% = Bound(mp$(), 0), ub% = Bound(mp$(), 1)
  map2.init(mp$(), 8)
  map2.put(mp$(), "foo", "bar")

  assert_string_equals(sys.NO_DATA$, map2.get$(mp$(), "wom"))
End Sub

Sub test_remove_given_present()
  Local mp$(map2.new%(10))
  map2.init(mp$(), 8)
  map2.put(mp$(), "foo", "bar")
  map2.put(mp$(), "wom", "bat")

  map2.remove(mp$(), "foo")

  assert_string_equals(sys.NO_DATA$, map2.get$(mp$(), "foo"))
  assert_string_equals("bat", map2.get$(mp$(), "wom"))
  assert_int_equals(1, map2.size%(mp$()))

  map2.remove(mp$(), "wom")

  assert_string_equals(sys.NO_DATA$, map2.get$(mp$(), "wom"))
  assert_int_equals(0, map2.size%(mp$()))
End Sub

Sub test_remove_given_absent()
  Local mp$(map2.new%(10))
  map2.init(mp$(), 8)
  map2.put(mp$(), "foo", "bar")
  map2.put(mp$(), "wom", "bat")

  map2.remove(mp$(), "sna")

  assert_string_equals("bar", map2.get$(mp$(), "foo"))
  assert_string_equals("bat", map2.get$(mp$(), "wom"))
  assert_int_equals(2, map2.size%(mp$()))
End Sub

Sub test_size()
  Local mp$(map2.new%(10))
  map2.init(mp$(), 8)

  assert_int_equals(0, map2.size%(mp$()))

  map2.put(mp$(), "foo", "bar")
  map2.put(mp$(), "wom", "bat")

  assert_int_equals(2, map2.size%(mp$()))
End Sub

Sub test_is_full()
  Local i%, mp$(map2.new%(10))
  map2.init(mp$(), 8)

  assert_int_equals(0, map2.is_full%(mp$()))

  map2.put(mp$(), "foo", "bar")

  assert_int_equals(0, map2.is_full%(mp$()))

  For i% = 1 To 9
    map2.put(mp$(), "key_" + Str$(i%), "value_" + Str$(i%))
  Next

  assert_int_equals(1, map2.is_full%(mp$()))

  map2.remove(mp$(), "foo")

  assert_int_equals(0, map2.is_full%(mp$()))
End Sub

Sub test_clear()
  Local i%, mp$(map2.new%(10))
  map2.init(mp$(), 8)
  For i% = 1 To 10
    map2.put(mp$(), "key_" + Str$(i%), "value_" + Str$(i%))
  Next

  assert_int_equals(10, map2.size%(mp$()))

  map2.clear(mp$())

  assert_int_equals(0, map2.size%(mp$()))
  Const lb% = Bound(mp$(), 0), ub% = Bound(mp$(), 1)
  For i% = lb% To ub% - 1
    assert_string_equals(sys.NO_DATA$, mp$(i%))
  Next

  assert_string_equals("8,0", mp$(ub%))
End Sub

Sub test_capacity()
  Local mp$(map2.new%(10))
  map2.init(mp$(), 8)

  assert_int_equals(10, map2.capacity%(mp$()))
End Sub

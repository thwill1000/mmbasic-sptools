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
#Include "../set.inc"
#Include "../vt100.inc"
#Include "../../sptest/unittest.inc"

add_test("test_init")
add_test("test_add")
add_test("test_clear")
add_test("test_get")
add_test("test_insert")
add_test("test_peek")
add_test("test_pop")
add_test("test_push")
add_test("test_remove")
add_test("test_set")
add_test("test_sort")

If InStr(Mm.CmdLine$, "--base") Then run_tests() Else run_tests("--base=1")

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Sub test_init()
  Local base% = Mm.Info(Option Base)
  Local my_list$(list.new%(20))
  list.init(my_list$())

  assert_equals(20, list.capacity%(my_list$()))
  assert_equals(0, list.size%(my_list$()))
  Local i%
  For i% = base% To base% + 19
    assert_string_equals(list.NULL$, my_list$(i%))
  Next
End Sub

Sub test_add()
  Local base% = Mm.Info(Option Base)
  Local my_list$(list.new%(20))
  list.init(my_list$())

  list.add(my_list$(), "foo")
  list.add(my_list$(), "bar")

  assert_equals(2, list.size%(my_list$()))
  assert_string_equals("foo", my_list$(base% + 0))
  assert_string_equals("bar", my_list$(base% + 1))

  assert_equals(20, list.capacity%(my_list$()))
End Sub

Sub test_clear()
  Local base% = Mm.Info(Option Base)
  Local my_list$(list.new%(20))
  list.init(my_list$())
  list.add(my_list$(), "aa")
  list.add(my_list$(), "bb")
  list.add(my_list$(), "cc")

  list.clear(my_list$())

  assert_equals(0, list.size%(my_list$()))
  Local i%
  For i% = base% To base% + 19
    assert_string_equals(list.NULL$, my_list$(i%))
  Next

  assert_equals(20, list.capacity%(my_list$()))
End Sub

Sub test_get()
  Local base% = Mm.Info(Option Base)
  Local my_list$(list.new%(20))
  list.init(my_list$())
  list.add(my_list$(), "aa")
  list.add(my_list$(), "bb")
  list.add(my_list$(), "cc")

  assert_equals(20, list.capacity%(my_list$()))
  assert_equals(3, list.size%(my_list$()))
  assert_string_equals("aa", list.get$(my_list$(), base% + 0))
  assert_string_equals("bb", list.get$(my_list$(), base% + 1))
  assert_string_equals("cc", list.get$(my_list$(), base% + 2))

  On Error Ignore
  Local s$ = list.get$(my_list$(), base% + 3)
  assert_raw_error("index out of bounds: " + Str$(base% + 3))
  On Error Abort
End Sub

Sub test_insert()
  Local base% = Mm.Info(Option Base)
  Local my_list$(list.new%(20))
  list.init(my_list$())
  list.add(my_list$(), "foo")
  list.add(my_list$(), "bar")

  list.insert(my_list$(), 0, "wom")
  assert_equals(3, list.size%(my_list$()))
  assert_string_equals("wom", my_list$(base% + 0))
  assert_string_equals("foo", my_list$(base% + 1))
  assert_string_equals("bar", my_list$(base% + 2))

  list.insert(my_list$(), 1, "bat")
  assert_equals(4, list.size%(my_list$()))
  assert_string_equals("wom", my_list$(base% + 0))
  assert_string_equals("bat", my_list$(base% + 1))
  assert_string_equals("foo", my_list$(base% + 2))
  assert_string_equals("bar", my_list$(base% + 3))

  list.insert(my_list$(), 4, "snafu")
  assert_equals(5, list.size%(my_list$()))
  assert_string_equals("wom", my_list$(base% + 0))
  assert_string_equals("bat", my_list$(base% + 1))
  assert_string_equals("foo", my_list$(base% + 2))
  assert_string_equals("bar", my_list$(base% + 3))
  assert_string_equals("snafu", my_list$(base% + 4))

  assert_equals(20, list.capacity%(my_list$()))
End Sub

Sub test_peek()
  Local my_list$(list.new%(20))
  list.init(my_list$())

  assert_string_equals(list.NULL$, list.peek$(my_list$()))

  list.add(my_list$(), "foo")
  list.add(my_list$(), "bar")

  assert_string_equals("bar", list.peek$(my_list$()))
End Sub

Sub test_pop()
  Local my_list$(list.new%(20))
  list.init(my_list$())
  list.add(my_list$(), "foo")
  list.add(my_list$(), "bar")

  assert_string_equals("bar", list.pop$(my_list$()))
  assert_equals(1, list.size%(my_list$()))
  assert_string_equals("foo", list.pop$(my_list$()))
  assert_equals(0, list.size%(my_list$()))
  assert_string_equals(list.NULL$, list.pop$(my_list$()))
  assert_equals(0, list.size%(my_list$()))
  assert_string_equals(list.NULL$, list.pop$(my_list$()))
  assert_equals(0, list.size%(my_list$()))

  assert_equals(20, list.capacity%(my_list$()))
End Sub

Sub test_push()
  Local base% = Mm.Info(Option Base)
  Local my_list$(list.new%(20))
  list.init(my_list$())

  list.push(my_list$(), "foo")
  list.push(my_list$(), "bar")

  assert_equals(2, list.size%(my_list$()))
  assert_string_equals("foo", my_list$(base% + 0))
  assert_string_equals("bar", my_list$(base% + 1))

  assert_equals(20, list.capacity%(my_list$()))
End Sub

Sub test_remove()
  Local base% = Mm.Info(Option Base)
  Local my_list$(list.new%(20))
  list.init(my_list$())
  list.add(my_list$(), "aa")
  list.add(my_list$(), "bb")
  list.add(my_list$(), "cc")
  list.add(my_list$(), "dd")

  list.remove(my_list$(), base% + 1)
  assert_equals(3, list.size%(my_list$()))
  assert_string_equals("aa", my_list$(base% + 0))
  assert_string_equals("cc", my_list$(base% + 1))
  assert_string_equals("dd", my_list$(base% + 2))
  assert_string_equals(list.NULL$, my_list$(base% + 3))

  list.remove(my_list$(), base% + 0)
  assert_equals(2, list.size%(my_list$()))
  assert_string_equals("cc", my_list$(base% + 0))
  assert_string_equals("dd", my_list$(base% + 1))
  assert_string_equals(list.NULL$, my_list$(base% + 2))

  list.remove(my_list$(), base% + 1)
  assert_equals(1, list.size%(my_list$()))
  assert_string_equals("cc", my_list$(base% + 0))
  assert_string_equals(list.NULL$, my_list$(base% + 1))

  list.remove(my_list$(), base% + 0)
  assert_equals(0, list.size%(my_list$()))
  assert_string_equals(list.NULL$, my_list$(base% + 0))

  assert_equals(20, list.capacity%(my_list$()))
End Sub

Sub test_set()
  Local base% = Mm.Info(Option Base)
  Local my_list$(list.new%(20))
  list.init(my_list$())
  list.add(my_list$(), "aa")
  list.add(my_list$(), "bb")
  list.add(my_list$(), "cc")

  list.set(my_list$(), base% + 0, "00")
  list.set(my_list$(), base% + 1, "11")
  list.set(my_list$(), base% + 2, "22")

  assert_equals(20, list.capacity%(my_list$()))
  assert_equals(3, list.size%(my_list$()))
  assert_string_equals("00", my_list$(base% + 0))
  assert_string_equals("11", my_list$(base% + 1))
  assert_string_equals("22", my_list$(base% + 2))

  On Error Ignore
  list.set(my_list$(), base% + 3, "33")
  assert_raw_error("index out of bounds: " + Str$(base% + 3))
  On Error Abort
End Sub

Sub test_sort()
  Local base% = Mm.Info(Option Base)
  Local my_list$(list.new%(20))
  list.init(my_list$())
  list.add(my_list$(), "bb")
  list.add(my_list$(), "dd")
  list.add(my_list$(), "cc")
  list.add(my_list$(), "aa")

  list.sort(my_list$())

  assert_equals(20, list.capacity%(my_list$()))
  assert_equals(4, list.size%(my_list$()))
  assert_string_equals("aa", my_list$(base% + 0))
  assert_string_equals("bb", my_list$(base% + 1))
  assert_string_equals("cc", my_list$(base% + 2))
  assert_string_equals("dd", my_list$(base% + 3))
End Sub

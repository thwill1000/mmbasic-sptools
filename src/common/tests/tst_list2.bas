' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer
Option Base 0

#Include "../error.inc"
#Include "../file.inc"
#Include "../list.inc"
#Include "../list2.inc"
#Include "../set.inc"
#Include "../../sptest/unittest.inc"

add_test("test_init")
add_test("test_add")
add_test("test_clear")
add_test("test_get")
add_test("test_insert")
add_test("test_remove")
add_test("test_pop")
add_test("test_push")
add_test("test_set")
add_test("test_sort")

run_tests()

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Function test_init()
  Local my_list$(list2.new%(20))
  list2.init(my_list$())

  assert_equals(20, list2.capacity%(my_list$()))
  assert_equals(0, list2.size%(my_list$()))
  Local i
  For i = 0 To 19
    assert_string_equals(LIST2.NULL$, my_list$(i))
  Next
End Function

Function test_add()
  Local my_list$(list2.new%(20))
  list2.init(my_list$())

  list2.add(my_list$(), "foo")
  list2.add(my_list$(), "bar")

  assert_equals(2, list2.size%(my_list$()))
  assert_string_equals("foo", my_list$(0))
  assert_string_equals("bar", my_list$(1))

  assert_equals(20, list2.capacity%(my_list$()))
End Function

Function test_clear()
  Local my_list$(list2.new%(20))
  list2.init(my_list$())
  list2.add(my_list$(), "aa")
  list2.add(my_list$(), "bb")
  list2.add(my_list$(), "cc")

  list2.clear(my_list$())

  assert_equals(0, list2.size%(my_list$()))
  Local i
  For i = 0 To 19
    assert_string_equals(LIST2.NULL$, my_list$(i))
  Next

  assert_equals(20, list2.capacity%(my_list$()))
End Function

Function test_get()
  Local my_list$(list2.new%(20))
  list2.init(my_list$())
  list2.add(my_list$(), "aa")
  list2.add(my_list$(), "bb")
  list2.add(my_list$(), "cc")

  assert_equals(20, list2.capacity%(my_list$()))
  assert_equals(3, list2.size%(my_list$()))
  assert_string_equals("aa", list2.get$(my_list$(), 0))
  assert_string_equals("bb", list2.get$(my_list$(), 1))
  assert_string_equals("cc", list2.get$(my_list$(), 2))

  On Error Ignore
  Local s$ = list2.get$(my_list$(), 3)
  assert_true(InStr(Mm.ErrMsg$, "index out of bounds: 3") > 0)
  On Error Abort
End Function

Function test_insert()
  Local my_list$(list2.new%(20))
  list2.init(my_list$())
  list2.add(my_list$(), "foo")
  list2.add(my_list$(), "bar")

  list2.insert(my_list$(), 0, "wom")
  assert_equals(3, list2.size%(my_list$()))
  assert_string_equals("wom", my_list$(0))
  assert_string_equals("foo", my_list$(1))
  assert_string_equals("bar", my_list$(2))

  list2.insert(my_list$(), 1, "bat")
  assert_equals(4, list2.size%(my_list$()))
  assert_string_equals("wom", my_list$(0))
  assert_string_equals("bat", my_list$(1))
  assert_string_equals("foo", my_list$(2))
  assert_string_equals("bar", my_list$(3))

  list2.insert(my_list$(), 4, "snafu")
  assert_equals(5, list2.size%(my_list$()))
  assert_string_equals("wom", my_list$(0))
  assert_string_equals("bat", my_list$(1))
  assert_string_equals("foo", my_list$(2))
  assert_string_equals("bar", my_list$(3))
  assert_string_equals("snafu", my_list$(4))

  assert_equals(20, list2.capacity%(my_list$()))
End Function

Function test_pop()
  Local my_list$(list2.new%(20))
  list2.init(my_list$())
  list2.add(my_list$(), "foo")
  list2.add(my_list$(), "bar")

  assert_string_equals("bar", list2.pop$(my_list$()))
  assert_equals(1, list2.size%(my_list$()))
  assert_string_equals("foo", list2.pop$(my_list$()))
  assert_equals(0, list2.size%(my_list$()))
  assert_string_equals(LIST2.NULL$, list2.pop$(my_list$()))
  assert_equals(0, list2.size%(my_list$()))
  assert_string_equals(LIST2.NULL$, list2.pop$(my_list$()))
  assert_equals(0, list2.size%(my_list$()))

  assert_equals(20, list2.capacity%(my_list$()))
End Function

Function test_push()
  Local my_list$(list2.new%(20))
  list2.init(my_list$())

  list2.push(my_list$(), "foo")
  list2.push(my_list$(), "bar")

  assert_equals(2, list2.size%(my_list$()))
  assert_string_equals("foo", my_list$(0))
  assert_string_equals("bar", my_list$(1))

  assert_equals(20, list2.capacity%(my_list$()))
End Function

Function test_remove()
  Local my_list$(list2.new%(20))
  list2.init(my_list$())
  list2.add(my_list$(), "aa")
  list2.add(my_list$(), "bb")
  list2.add(my_list$(), "cc")
  list2.add(my_list$(), "dd")

  list2.remove(my_list$(), 1)
  assert_equals(3, list2.size%(my_list$()))
  assert_string_equals("aa", my_list$(0))
  assert_string_equals("cc", my_list$(1))
  assert_string_equals("dd", my_list$(2))

  list2.remove(my_list$(), 0)
  assert_equals(2, list2.size%(my_list$()))
  assert_string_equals("cc", my_list$(0))
  assert_string_equals("dd", my_list$(1))

  list2.remove(my_list$(), 1)
  assert_equals(1, list2.size%(my_list$()))
  assert_string_equals("cc", my_list$(0))

  list2.remove(my_list$(), 0)
  assert_equals(0, list2.size%(my_list$()))

  assert_equals(20, list2.capacity%(my_list$()))
End Function

Function test_set()
  Local my_list$(list2.new%(20))
  list2.init(my_list$())
  list2.add(my_list$(), "aa")
  list2.add(my_list$(), "bb")
  list2.add(my_list$(), "cc")

  list2.set(my_list$(), 0, "00")
  list2.set(my_list$(), 1, "11")
  list2.set(my_list$(), 2, "22")

  assert_equals(20, list2.capacity%(my_list$()))
  assert_equals(3, list2.size%(my_list$()))
  assert_string_equals("00", my_list$(0))
  assert_string_equals("11", my_list$(1))
  assert_string_equals("22", my_list$(2))

  On Error Ignore
  list2.set(my_list$(), 3, "33")
  assert_true(InStr(Mm.ErrMsg$, "index out of bounds: 3") > 0)
  On Error Abort
End Function

Function test_sort()
  Local my_list$(list2.new%(20))
  list2.init(my_list$())
  list2.add(my_list$(), "bb")
  list2.add(my_list$(), "dd")
  list2.add(my_list$(), "cc")
  list2.add(my_list$(), "aa")

  list2.sort(my_list$())

  assert_equals(20, list2.capacity%(my_list$()))
  assert_equals(4, list2.size%(my_list$()))
  assert_string_equals("aa", my_list$(0))
  assert_string_equals("bb", my_list$(1))
  assert_string_equals("cc", my_list$(2))
  assert_string_equals("dd", my_list$(3))
End Function

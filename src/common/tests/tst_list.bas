' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

#Include "../error.inc"
#Include "../list.inc"
#Include "../set.inc"
#Include "../../sptest/unittest.inc"

add_test("test_init")
add_test("test_add")
add_test("test_insert")
add_test("test_remove")
add_test("test_pop")
add_test("test_push")
add_test("test_clear")

run_tests()

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Function test_init()
  Local i
  Local my_list_sz = 20
  Local my_list$(my_list_sz - 1)

  list_init(my_list$(), my_list_sz)

  assert_equals(0, my_list_sz)
  For i = 0 To 19
    assert_string_equals(Chr$(&h7F), my_list$(i))
  Next i
End Function

Function test_add()
  Local my_list_sz = 20
  Local my_list$(my_list_sz - 1)
  list_init(my_list$(), my_list_sz)

  list_add(my_list$(), my_list_sz, "foo")
  list_add(my_list$(), my_list_sz, "bar")

  assert_equals(2, my_list_sz)
  assert_string_equals("foo", my_list$(0))
  assert_string_equals("bar", my_list$(1))
End Function

Function test_insert()
  Local my_list_sz = 20
  Local my_list$(my_list_sz - 1)
  list_init(my_list$(), my_list_sz)
  list_push(my_list$(), my_list_sz, "foo")
  list_push(my_list$(), my_list_sz, "bar")

  list_insert(my_list$(), my_list_sz, 0, "wom")
  assert_equals(3, my_list_sz)
  assert_string_equals("wom", my_list$(0))
  assert_string_equals("foo", my_list$(1))
  assert_string_equals("bar", my_list$(2))

  list_insert(my_list$(), my_list_sz, 1, "bat")
  assert_equals(4, my_list_sz)
  assert_string_equals("wom", my_list$(0))
  assert_string_equals("bat", my_list$(1))
  assert_string_equals("foo", my_list$(2))
  assert_string_equals("bar", my_list$(3))

  list_insert(my_list$(), my_list_sz, 4, "snafu")
  assert_equals(5, my_list_sz)
  assert_string_equals("wom", my_list$(0))
  assert_string_equals("bat", my_list$(1))
  assert_string_equals("foo", my_list$(2))
  assert_string_equals("bar", my_list$(3))
  assert_string_equals("snafu", my_list$(4))
End Function

Function test_remove()
  Local my_list_sz = 20
  Local my_list$(my_list_sz - 1)
  list_init(my_list$(), my_list_sz)
  list_push(my_list$(), my_list_sz, "aa")
  list_push(my_list$(), my_list_sz, "bb")
  list_push(my_list$(), my_list_sz, "cc")
  list_push(my_list$(), my_list_sz, "dd")

  list_remove(my_list$(), my_list_sz, 1)
  assert_equals(3, my_list_sz)
  assert_string_equals("aa", my_list$(0))
  assert_string_equals("cc", my_list$(1))
  assert_string_equals("dd", my_list$(2))

  list_remove(my_list$(), my_list_sz, 0)
  assert_equals(2, my_list_sz)
  assert_string_equals("cc", my_list$(0))
  assert_string_equals("dd", my_list$(1))

  list_remove(my_list$(), my_list_sz, 1)
  assert_equals(1, my_list_sz)
  assert_string_equals("cc", my_list$(0))

  list_remove(my_list$(), my_list_sz, 0)
  assert_equals(0, my_list_sz)
End Function

Function test_push()
  Local my_list_sz = 20
  Local my_list$(my_list_sz - 1)
  list_init(my_list$(), my_list_sz)

  list_push(my_list$(), my_list_sz, "foo")
  list_push(my_list$(), my_list_sz, "bar")

  assert_equals(2, my_list_sz)
  assert_string_equals("foo", my_list$(0))
  assert_string_equals("bar", my_list$(1))
End Function

Function test_pop()
  Local my_list_sz = 20
  Local my_list$(my_list_sz - 1)
  list_init(my_list$(), my_list_sz)
  list_push(my_list$(), my_list_sz, "foo")
  list_push(my_list$(), my_list_sz, "bar")

  assert_string_equals("bar", list_pop$(my_list$(), my_list_sz))
  assert_string_equals("foo", list_pop$(my_list$(), my_list_sz))
  assert_string_equals(Chr$(&h7F), list_pop$(my_list$(), my_list_sz))
End Function

Function test_clear()
  Local i
  Local my_list_sz = 20
  Local my_list$(my_list_sz - 1)
  list_init(my_list$(), my_list_sz)
  list_push(my_list$(), my_list_sz, "aa")
  list_push(my_list$(), my_list_sz, "bb")
  list_push(my_list$(), my_list_sz, "cc")

  list_clear(my_list$(), my_list_sz)

  assert_equals(0, my_list_sz)
  For i = 0 To 19
    assert_string_equals(Chr$(&h7F), my_list$(i))
  Next i
End Function

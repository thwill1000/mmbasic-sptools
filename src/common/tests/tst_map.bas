' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

Dim err$

#Include "../common.inc"
#Include "../list.inc"
#Include "../map.inc"
#Include "../set.inc"
#Include "../../sptest/unittest.inc"

add_test("test_init")
add_test("test_put")
add_test("test_put_given_already_present")
add_test("test_get")
add_test("test_remove")
add_test("test_clear")

' TODO: add tests for case-sensitivity.

run_tests()

End

Sub setup_test()
  err$ = ""
End Sub

Sub teardown_test()
End Sub

Function test_init()
  Local i
  Local my_keys$(19)
  Local my_values$(19)

  map_init(my_keys$(), my_values$(), 20)

  For i = 0 To 19
    assert_string_equals(Chr$(&h7F), my_keys$(i))
    assert_string_equals(Chr$(0), my_values$(i))
  Next i
End Function

Function test_put()
  Local my_keys$(19)
  Local my_values$(19)
  Local my_map_sz = 0

  map_init(my_keys$(), my_values$(), 20)

  map_put(my_keys$(), my_values$(), my_map_sz, "foo", "bar")
  map_put(my_keys$(), my_values$(), my_map_sz, "wom", "bat")
  map_put(my_keys$(), my_values$(), my_map_sz, "aaa", "bbb")

  assert_equals(3, my_map_sz)
  assert_string_equals("aaa", my_keys$(0))
  assert_string_equals("bbb", my_values$(0))
  assert_string_equals("foo", my_keys$(1))
  assert_string_equals("bar", my_values$(1))
  assert_string_equals("wom", my_keys$(2))
  assert_string_equals("bat", my_values$(2))
End Function

Function test_put_given_already_present()
  Local my_keys$(19)
  Local my_values$(19)
  Local my_map_sz = 0

  map_init(my_keys$(), my_values$(), 20)
  map_put(my_keys$(), my_values$(), my_map_sz, "foo", "bar")
  map_put(my_keys$(), my_values$(), my_map_sz, "wom", "bat")
  map_put(my_keys$(), my_values$(), my_map_sz, "aaa", "bbb")

  map_put(my_keys$(), my_values$(), my_map_sz, "foo", "bar2")
  map_put(my_keys$(), my_values$(), my_map_sz, "wom", "bat2")
  map_put(my_keys$(), my_values$(), my_map_sz, "aaa", "bbb2")

  assert_equals(3, my_map_sz)
  assert_string_equals("aaa", my_keys$(0))
  assert_string_equals("bbb2", my_values$(0))
  assert_string_equals("foo", my_keys$(1))
  assert_string_equals("bar2", my_values$(1))
  assert_string_equals("wom", my_keys$(2))
  assert_string_equals("bat2", my_values$(2))
End Function

Function test_get()
  Local my_keys$(19)
  Local my_values$(19)
  Local my_map_sz = 0

  map_init(my_keys$(), my_values$(), 20)
  map_put(my_keys$(), my_values$(), my_map_sz, "foo", "bar")
  map_put(my_keys$(), my_values$(), my_map_sz, "wom", "bat")
  map_put(my_keys$(), my_values$(), my_map_sz, "aaa", "bbb")

  assert_string_equals("bar", map_get$(my_keys$(), my_values$(), my_map_sz, "foo"))
  assert_string_equals("bat", map_get$(my_keys$(), my_values$(), my_map_sz, "wom"))
  assert_string_equals("bbb", map_get$(my_keys$(), my_values$(), my_map_sz, "aaa"))
  assert_string_equals(Chr$(0), map_get$(my_keys$(), my_values$(), my_map_sz, "unknown"))
End Function

Function test_remove()
  Local my_keys$(19)
  Local my_values$(19)
  Local my_map_sz = 0

  map_init(my_keys$(), my_values$(), 20)
  map_put(my_keys$(), my_values$(), my_map_sz, "foo", "bar")
  map_put(my_keys$(), my_values$(), my_map_sz, "wom", "bat")
  map_put(my_keys$(), my_values$(), my_map_sz, "aaa", "bbb")

  map_remove(my_keys$(), my_values$(), my_map_sz, "wom")

  assert_equals(2, my_map_sz)
  assert_string_equals("aaa", my_keys$(0))
  assert_string_equals("bbb", my_values$(0))
  assert_string_equals("foo", my_keys$(1))
  assert_string_equals("bar", my_values$(1))
  assert_string_equals(Chr$(&h7F), my_keys$(2))
  assert_string_equals(Chr$(0), my_values$(2))

  map_remove(my_keys$(), my_values$(), my_map_sz, "aaa")

  assert_equals(1, my_map_sz)
  assert_string_equals("foo", my_keys$(0))
  assert_string_equals("bar", my_values$(0))
  assert_string_equals(Chr$(&h7F), my_keys$(1))
  assert_string_equals(Chr$(0), my_values$(1))

  map_remove(my_keys$(), my_values$(), my_map_sz, "foo")

  assert_equals(0, my_map_sz)
  assert_string_equals(Chr$(&h7F), my_keys$(0))
  assert_string_equals(Chr$(0), my_values$(0))
End Function

Function test_clear()
  Local i
  Local my_keys$(19)
  Local my_values$(19)
  Local my_map_sz = 0

  map_init(my_keys$(), my_values$(), 20)
  map_put(my_keys$(), my_values$(), my_map_sz, "foo", "bar")
  map_put(my_keys$(), my_values$(), my_map_sz, "wom", "bat")
  map_put(my_keys$(), my_values$(), my_map_sz, "aaa", "bbb")

  map_clear(my_keys$(), my_values$(), my_map_sz)

  assert_equals(0, my_map_sz)
  For i = 0 To 19
    assert_string_equals(Chr$(&h7F), my_keys$(i))
    assert_string_equals(Chr$(0), my_values$(i))
  Next i
End Function

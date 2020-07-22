' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

#Include "unittest.inc"
#Include "../map.inc"
#Include "../set.inc"

Cls

ut_add_test("test_init")
ut_add_test("test_put")
ut_add_test("test_put_given_already_present")
ut_add_test("test_get")
ut_add_test("test_remove")
ut_add_test("test_clear")

' TODO: add tests for case-sensitivity.

ut_run_tests()

End

Function test_init()
  Local i
  Local my_keys$(19)
  Local my_values$(19)

  map_init(my_keys$(), my_values$(), 20)

  For i = 0 To 19
    ut_assert_string_equals(Chr$(&h7F), my_keys$(i))
    ut_assert_string_equals(Chr$(0), my_values$(i))
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

  ut_assert_equals(3, my_map_sz)
  ut_assert_string_equals("aaa", my_keys$(0))
  ut_assert_string_equals("bbb", my_values$(0))
  ut_assert_string_equals("foo", my_keys$(1))
  ut_assert_string_equals("bar", my_values$(1))
  ut_assert_string_equals("wom", my_keys$(2))
  ut_assert_string_equals("bat", my_values$(2))
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

  ut_assert_equals(3, my_map_sz)
  ut_assert_string_equals("aaa", my_keys$(0))
  ut_assert_string_equals("bbb2", my_values$(0))
  ut_assert_string_equals("foo", my_keys$(1))
  ut_assert_string_equals("bar2", my_values$(1))
  ut_assert_string_equals("wom", my_keys$(2))
  ut_assert_string_equals("bat2", my_values$(2))
End Function

Function test_get()
  Local my_keys$(19)
  Local my_values$(19)
  Local my_map_sz = 0

  map_init(my_keys$(), my_values$(), 20)
  map_put(my_keys$(), my_values$(), my_map_sz, "foo", "bar")
  map_put(my_keys$(), my_values$(), my_map_sz, "wom", "bat")
  map_put(my_keys$(), my_values$(), my_map_sz, "aaa", "bbb")

  ut_assert_string_equals("bar", map_get$(my_keys$(), my_values$(), my_map_sz, "foo"))
  ut_assert_string_equals("bat", map_get$(my_keys$(), my_values$(), my_map_sz, "wom"))
  ut_assert_string_equals("bbb", map_get$(my_keys$(), my_values$(), my_map_sz, "aaa"))
  ut_assert_string_equals(Chr$(0), map_get$(my_keys$(), my_values$(), my_map_sz, "unknown"))
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

  ut_assert_equals(2, my_map_sz)
  ut_assert_string_equals("aaa", my_keys$(0))
  ut_assert_string_equals("bbb", my_values$(0))
  ut_assert_string_equals("foo", my_keys$(1))
  ut_assert_string_equals("bar", my_values$(1))
  ut_assert_string_equals(Chr$(&h7F), my_keys$(2))
  ut_assert_string_equals(Chr$(0), my_values$(2))

  map_remove(my_keys$(), my_values$(), my_map_sz, "aaa")

  ut_assert_equals(1, my_map_sz)
  ut_assert_string_equals("foo", my_keys$(0))
  ut_assert_string_equals("bar", my_values$(0))
  ut_assert_string_equals(Chr$(&h7F), my_keys$(1))
  ut_assert_string_equals(Chr$(0), my_values$(1))

  map_remove(my_keys$(), my_values$(), my_map_sz, "foo")

  ut_assert_equals(0, my_map_sz)
  ut_assert_string_equals(Chr$(&h7F), my_keys$(0))
  ut_assert_string_equals(Chr$(0), my_values$(0))
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

  ut_assert_equals(0, my_map_sz)
  For i = 0 To 19
    ut_assert_string_equals(Chr$(&h7F), my_keys$(i))
    ut_assert_string_equals(Chr$(0), my_values$(i))
  Next i
End Function

' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

#Include "../unittest.inc"
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
  Local my_set$(19)
  Local my_set_sz = 0

  set_init(my_set$(), 20)

  For i = 0 To 19
    ut_assert_string_equals(Chr$(&h7F), my_set$(i))
  Next i
End Function

Function test_put()
  Local my_set$(19)
  Local my_set_sz = 0

  set_init(my_set$(), 20)

  set_put(my_set$(), my_set_sz, "foo")
  set_put(my_set$(), my_set_sz, "bar")

  ut_assert_equals(2, my_set_sz)
  ut_assert_string_equals("bar", my_set$(0))
  ut_assert_string_equals("foo", my_set$(1))
End Function

Function test_put_given_already_present()
  Local my_set$(19)
  Local my_set_sz = 0

  set_init(my_set$(), 20)
  set_put(my_set$(), my_set_sz, "foo")
  set_put(my_set$(), my_set_sz, "bar")

  set_put(my_set$(), my_set_sz, "foo")
  set_put(my_set$(), my_set_sz, "bar")

  ut_assert_equals(2, my_set_sz)
  ut_assert_string_equals("bar", my_set$(0))
  ut_assert_string_equals("foo", my_set$(1))
End Function

Function test_get()
  Local my_set$(19)
  Local my_set_sz = 0

  set_init(my_set$(), 20)
  set_put(my_set$(), my_set_sz, "foo")
  set_put(my_set$(), my_set_sz, "bar")

  ut_assert_equals(0, set_get(my_set$(), my_set_sz, "bar"))
  ut_assert_equals(1, set_get(my_set$(), my_set_sz, "foo"))
  ut_assert_equals(-1, set_get(my_set$(), my_set_sz, "wombat"))
End Function

Function test_remove()
  Local my_set$(19)
  Local my_set_sz = 0

  set_init(my_set$(), 20)
  set_put(my_set$(), my_set_sz, "foo")
  set_put(my_set$(), my_set_sz, "bar")

  set_remove(my_set$(), my_set_sz, "bar")

  ut_assert_equals(1, my_set_sz)
  ut_assert_equals(0, set_get(my_set$(), my_set_sz, "foo"))
  ut_assert_equals(-1, set_get(my_set$(), my_set_sz, "bar"))

  set_remove(my_set$(), my_set_sz, "foo")

  ut_assert_equals(0, my_set_sz)
  ut_assert_equals(-1, set_get(my_set$(), my_set_sz, "foo"))
  ut_assert_equals(-1, set_get(my_set$(), my_set_sz, "bar"))
End Function

Function test_clear()
  Local i
  Local my_set$(19)
  Local my_set_sz = 0

  set_init(my_set$(), 20)
  set_put(my_set$(), my_set_sz, "foo")
  set_put(my_set$(), my_set_sz, "bar")

  set_clear(my_set$(), my_set_sz)

  ut_assert_equals(0, my_set_sz)
  For i = 0 To 19
    ut_assert_string_equals(Chr$(&h7F), my_set$(i))
  Next i
End Function

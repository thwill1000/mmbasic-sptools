' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

Option Base 0
Option Default None
Option Explicit On

#Include "../../splib/system.inc"
#Include "../../splib/array.inc"
#Include "../../splib/list.inc"
#Include "../../splib/string.inc"
#Include "../../splib/file.inc"
#Include "../../splib/map.inc"
#Include "../../splib/map2.inc"
#Include "../../splib/set.inc"
#Include "../../splib/vt100.inc"
#Include "../../sptest/unittest.inc"
#Include "../symbols.inc"

add_test("test_add_file_given_absent")
add_test("test_add_file_given_present")
add_test("test_add_file_given_too_many")
add_test("test_add_file_given_too_long")
add_test("test_add_fn_given_absent")
add_test("test_add_fn_given_present")
add_test("test_add_fn_given_too_many")
add_test("test_add_fn_given_too_long")
add_test("test_add_name_given_absent")
add_test("test_add_name_given_present")
add_test("test_add_name_given_too_many")
add_test("test_add_name_given_too_long")
add_test("test_add_name_given_hash_prefix")
add_test("test_add_ref_given_absent")
add_test("test_add_ref_given_present")
add_test("test_add_ref_given_too_many")
add_test("test_add_ref_given_too_long")
add_test("test_add_combination")
add_test("test_get_id_given_hash_prefix")

run_tests()

End

Sub setup_test()
  sym.init(32, 300, 1)
End Sub

Sub test_add_file_given_absent()
  assert_int_equals(0, sym.add_file%("A:/foo"))
  assert_string_equals("0", map2.get$(sym.files$(), "A:/foo"))
  assert_int_equals(1, map2.size%(sym.files$()))

  assert_int_equals(1, sym.add_file%("A:/bar"))
  assert_string_equals("1", map2.get$(sym.files$(), "A:/bar"))
  assert_int_equals(2, map2.size%(sym.files$()))
End Sub

Sub test_add_file_given_present()
  Const foo_idx% = sym.add_file%("A:/foo")
  Const bar_idx% = sym.add_file%("A:/bar")

  ' Add duplicates.
  assert_int_equals(foo_idx%, sym.add_file%("A:/foo"))
  assert_int_equals(bar_idx%, sym.add_file%("A:/bar"))
  assert_int_equals(2, map2.size%(sym.files$()))
End Sub

Sub test_add_file_given_too_many()
  Local i%
  For i% = 1 To sym.MAX_FILES%
    assert_int_equals(i% - 1, sym.add_file%("file_" + Str$(i%)))
  Next

  assert_int_equals(sys.FAILURE, sym.add_file%("straw"))
  assert_error("Too many files, max 32")
  assert_int_equals(sym.MAX_FILES%, map2.size%(sym.files$()))
End Sub

Sub test_add_file_given_too_long()
  Const file_128$ = String$(128, "a")
  assert_int_equals(0, sym.add_file%(file_128$))

  Const file_129$ = String$(129, "b")
  assert_int_equals(sys.FAILURE, sym.add_file%(file_129$))
  assert_error("Path too long, max 128 characters")
  assert_int_equals(1, map2.size%(sym.files$()))
End Sub

Sub test_add_fn_given_absent()
  assert_int_equals(0, sym.add_function%("FN_1", "my_file.inc", 42))
  assert_string_equals("FN_1,0,42,0,0", map2.get$(sym.functions$(), "fn_1"))
  assert_string_equals("0", map2.get$(sym.names$(), "fn_1"))
  assert_string_equals("0", map2.get$(sym.files$(), "my_file.inc"))
  assert_int_equals(sys.FAILURE, sym.get_reference%("fn_1", 0))
  assert_error("Reference index out of bounds")

  sys.err$ = ""
  assert_int_equals(1, sym.add_function%("FN_2", "your_file.inc", 99))
  assert_string_equals("FN_2,1,99,4,1", map2.get$(sym.functions$(), "fn_2"))
  assert_string_equals("1", map2.get$(sym.names$(), "fn_2"))
  assert_string_equals("1", map2.get$(sym.files$(), "your_file.inc"))
  assert_int_equals(sys.FAILURE, sym.get_reference%("fn_2", 0))
  assert_error("Reference index out of bounds")

  assert_int_equals(2, map2.size%(sym.functions$()))
End Sub

Sub test_add_fn_given_present()
  assert_int_equals(0, sym.add_function%("foo", "my_file.inc", 42))

  assert_int_equals(sys.FAILURE, sym.add_function%("foo", "your_file.inc", 99))
  assert_error("Duplicate function/subroutine")
  assert_int_equals(1, map2.size%(sym.functions$()))
End Sub

Sub test_add_fn_given_too_many()
  Local i%
  For i% = 1 To sym.MAX_FUNCTIONS%
    assert_int_equals(i% - 1, sym.add_function%("fun_" + Str$(i%)))
  Next

  assert_int_equals(sys.FAILURE, sym.add_function%("straw"))
  assert_error("Too many functions/subroutines, max 32")
  assert_int_equals(sym.MAX_FUNCTIONS%, map2.size%(sym.functions$()))
End Sub

Sub test_add_fn_given_too_long()
  Const name_33$ = String$(33, "a")
  assert_int_equals(0, sym.add_function%(name_33$, "my_file.inc", 42))

  Const name_34$ = String$(34, "a")
  assert_int_equals(sys.FAILURE, sym.add_function%(name_34$, "my_file.inc", 42))
  assert_error("Name too long, max 33 characters")
  assert_int_equals(1, map2.size%(sym.functions$()))
End Sub

Sub test_add_name_given_absent()
  assert_int_equals(0, sym.add_name%("FOO"))
  assert_string_equals("0", map2.get$(sym.names$(), "foo"))
  assert_int_equals(1, map2.size%(sym.names$()))

  assert_int_equals(1, sym.add_name%("BAR"))
  assert_string_equals("1", map2.get$(sym.names$(), "bar"))
  assert_int_equals(2, map2.size%(sym.names$()))
End Sub

Sub test_add_name_given_present()
  assert_int_equals(0, sym.add_name%("foo"))
  assert_int_equals(1, sym.add_name%("bar"))

  ' Add duplicates.
  assert_int_equals(0, sym.add_name%("foo"))
  assert_int_equals(1, sym.add_name%("bar"))
  assert_int_equals(2, map2.size%(sym.names$()))
End Sub

Sub test_add_name_given_too_many()
  Local i%
  For i% = 1 To sym.MAX_NAMES%
    assert_int_equals(i% - 1, sym.add_name%("id_" + Str$(i%)))
  Next

  assert_int_equals(sys.FAILURE, sym.add_name%("straw"))
  assert_error("Too many names, max 300")
  assert_int_equals(sym.MAX_NAMES%, map2.size%(sym.names$()))
End Sub

Sub test_add_name_given_too_long()
  Const id_33$ = String$(33, "a")
  assert_int_equals(0, sym.add_name%(id_33$))

  Const id_34$ = String$(34, "a")
  assert_int_equals(sys.FAILURE, sym.add_name%(id_34$))
  assert_error("Name too long, max 33 characters")
  assert_int_equals(1, map2.size%(sym.names$()))
End Sub

Sub test_add_name_given_hash_prefix()
  assert_int_equals(0, sym.add_name%("#foo"))
  assert_string_equals("0", map2.get$(sym.names$(), "foo"))
  assert_int_equals(1, map2.size%(sym.names$()))
End Sub

Sub test_add_ref_given_absent()
  assert_int_equals(0, sym.add_function%("my_function_1", "my_file.inc", 42))

  assert_int_equals(1, sym.add_reference%("foo"))
  assert_string_equals("1", map2.get$(sym.names$(), "foo"))
  assert_int_equals(1, sym.get_reference%("my_function_1", 0))

  assert_int_equals(2, sym.add_reference%("bar"))
  assert_string_equals("2", map2.get$(sym.names$(), "bar"))
  assert_int_equals(2, sym.get_reference%("my_function_1", 1))

  ' Start adding references from a new function.
  assert_int_equals(3, sym.add_function%("my_function_2", "my_file.inc", 42))

  assert_int_equals(2, sym.add_reference%("bar"))
  assert_string_equals("2", map2.get$(sym.names$(), "bar"))
  assert_int_equals(2, sym.get_reference%("my_function_2", 0))

  assert_int_equals(1, sym.add_reference%("foo"))
  assert_string_equals("1", map2.get$(sym.names$(), "foo"))
  assert_int_equals(1, sym.get_reference%("my_function_2", 1))

  ' Verify contents of the 'References' table.
  Local expected%(6) = ( 1, 2, &hFFFFFFFF, 2, 1, &hFFFFFFFF, &hFFFFFFFF)
  Local actual%(6), i%
  For i% = 0 To 6 : actual%(i%) = Peek(Word sym.P_REF_BASE% + 4 * i%) : Next
  assert_int_array_equals(expected%(), actual%())
End Sub

Sub test_add_ref_given_present()
  Const fn1_idx% = sym.add_function%("my_function_1", "my_file.inc", 42)
  Const foo_idx% = sym.add_reference%("foo")
  Const bar_idx% = sym.add_reference%("bar")

  ' Duplicate existing references.
  assert_int_equals(foo_idx%, sym.add_reference%("foo"))
  assert_int_equals(bar_idx%, sym.add_reference%("bar"))

  assert_int_equals(foo_idx%, sym.get_reference%("my_function_1", 0))
  assert_int_equals(bar_idx%, sym.get_reference%("my_function_1", 1))
  assert_int_equals(sys.FAILURE, sym.get_reference%("my_function_1", 2))
  assert_error("Reference index out of bounds")

  ' Verify contents of the 'References' table.
  Local expected%(3) = ( 1, 2, &hFFFFFFFF, &hFFFFFFFF)
  Local actual%(3), i%
  For i% = 0 To 3 : actual%(i%) = Peek(Word sym.P_REF_BASE% + 4 * i%) : Next
  assert_int_array_equals(expected%(), actual%())
End Sub

Sub test_add_ref_given_too_many()
  Const fn1_idx% = sym.add_function%("my_function_1", "my_file.inc", 42)
  Local i%
  For i% = 1 To 256
    assert_int_equals(i%, sym.add_reference%("id_" + Str$(i%)))
  Next

  assert_int_equals(sys.FAILURE, sym.add_reference%("id_257"))
  assert_error("Too many references")
End Sub

Sub test_add_ref_given_too_long()
  Const fn1_idx% = sym.add_function%("my_function_1", "my_file.inc", 42)

  Const id_33$ = String$(33, "a")
  assert_int_equals(1, sym.add_reference%(id_33$))

  Const id_34$ = String$(34, "a")
  assert_int_equals(sys.FAILURE, sym.add_reference%(id_34$))
  assert_error("Name too long, max 33 characters")
End Sub

Sub test_add_combination()
  assert_int_equals(0, sym.add_name%("global_1"))
  assert_int_equals(1, sym.add_name%("global_2"))
  assert_int_equals(2, sym.add_function%("FN_1", "file_1", 100))
  assert_int_equals(3, sym.add_reference%("local_1"))
  assert_int_equals(4, sym.add_reference%("local_2"))
  assert_int_equals(5, sym.add_name%("global_3"))
  assert_int_equals(6, sym.add_function%("FN_2", "file_1", 200))
  assert_int_equals(3, sym.add_reference%("local_1"))
  assert_int_equals(4, sym.add_reference%("local_2"))
  assert_int_equals(7, sym.add_reference%("local_3"))
  assert_int_equals(8, sym.add_function%("FN_3", "file_2", 300))
  assert_int_equals(7, sym.add_reference%("local_3"))
  assert_int_equals(9, sym.add_function%("FN_4", "file_3", 400))

  ' Validate contents of 'Files' table.
  assert_int_equals(3, map2.size%(sym.files$()))
  assert_string_equals("0", map2.get$(sym.files$(), "file_1"))
  assert_string_equals("1", map2.get$(sym.files$(), "file_2"))
  assert_string_equals("2", map2.get$(sym.files$(), "file_3"))

  ' Validate contents of 'Names' table.
  assert_int_equals(10, map2.size%(sym.names$()))
  assert_string_equals("0", map2.get$(sym.names$(), "global_1"))
  assert_string_equals("1", map2.get$(sym.names$(), "global_2"))
  assert_string_equals("2", map2.get$(sym.names$(), "fn_1"))
  assert_string_equals("3", map2.get$(sym.names$(), "local_1"))
  assert_string_equals("4", map2.get$(sym.names$(), "local_2"))
  assert_string_equals("5", map2.get$(sym.names$(), "global_3"))
  assert_string_equals("6", map2.get$(sym.names$(), "fn_2"))
  assert_string_equals("7", map2.get$(sym.names$(), "local_3"))
  assert_string_equals("8", map2.get$(sym.names$(), "fn_3"))
  assert_string_equals("9", map2.get$(sym.names$(), "fn_4"))

  ' Validate contents of 'Functions' table.
  assert_int_equals(4, map2.size%(sym.functions$()))
  assert_string_equals("FN_1,0,100,0,2", map2.get$(sym.functions$(), "fn_1"))
  assert_string_equals("FN_2,0,200,12,6", map2.get$(sym.functions$(), "fn_2"))
  assert_string_equals("FN_3,1,300,28,8", map2.get$(sym.functions$(), "fn_3"))
  assert_string_equals("FN_4,2,400,36,9", map2.get$(sym.functions$(), "fn_4"))

  ' Validate contents of 'References' table.
  Local expected%(10) = (3,4,&hFFFFFFFF,3,4,7,&hFFFFFFFF,7,&hFFFFFFFF,&hFFFFFFFF,&hFFFFFFFF)
  Local actual%(10), i%
  For i% = 0 To 10 : actual%(i%) = Peek(Word sym.P_REF_BASE% + 4 * i%) : Next
  assert_int_array_equals(expected%(), actual%())
End Sub

Sub test_get_id_given_hash_prefix()
  assert_int_equals(0, sym.add_name%("foo"))
  assert_int_equals(1, sym.add_name%("#bar"))

  assert_int_equals(0, sym.get_id%("foo"))
  assert_int_equals(0, sym.get_id%("#foo"))
  assert_int_equals(1, sym.get_id%("bar"))
  assert_int_equals(1, sym.get_id%("#bar"))
End Sub

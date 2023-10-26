' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

Option Base 0
Option Default Integer
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
#Include "../../common/sptools.inc"
#Include "../symbols.inc"

Dim actual$(9), expected$(9)

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
add_test("test_name_to_id_given_present")
add_test("test_name_to_id_given_absent")
add_test("test_name_to_id_given_hash_pfx")
add_test("test_switch_fn_given_absent")
add_test("test_switch_fn_given_present")
add_test("test_switch_fn_to_last")
add_test("test_add_fn_after_switch")
add_test("test_name_to_fn_given_present")
add_test("test_name_to_fn_given_absent")
add_test("test_id_to_fn")
add_test("test_id_to_name_given_present")
add_test("test_id_to_name_given_absent")
add_test("test_get_files")
add_test("test_get_names")
add_test("test_get_functions")
add_test("test_get_referenced_ids")
add_test("test_get_referenced_ids_given_too_many", "test_get_ref_id_too_many")

run_tests()

End

Sub setup_test()
  sym.init(32, 300, 1)
  clear_arrays()
End Sub

Sub clear_arrays()
  array.fill(actual$())
  array.fill(expected$())
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
  Const foo_id% = sym.add_file%("A:/foo")
  Const bar_id% = sym.add_file%("A:/bar")

  ' Add duplicates.
  assert_int_equals(foo_id%, sym.add_file%("A:/foo"))
  assert_int_equals(bar_id%, sym.add_file%("A:/bar"))
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
  assert_int_equals(0, sym.get_references%("fn_1", actual$()))

  sys.err$ = ""
  assert_int_equals(1, sym.add_function%("FN_2", "your_file.inc", 99))
  assert_string_equals("FN_2,1,99,4,1", map2.get$(sym.functions$(), "fn_2"))
  assert_string_equals("1", map2.get$(sym.names$(), "fn_2"))
  assert_string_equals("1", map2.get$(sym.files$(), "your_file.inc"))
  assert_int_equals(0, sym.get_references%("fn_2", actual$()))

  assert_int_equals(2, map2.size%(sym.functions$()))
End Sub

Sub test_add_fn_given_present()
  assert_int_equals(0, sym.add_function%("foo", "my_file.inc", 42))

  assert_int_equals(sys.FAILURE, sym.add_function%("foo", "your_file.inc", 99))
  assert_error("Duplicate FUNCTION/SUB")
  assert_int_equals(1, map2.size%(sym.functions$()))
End Sub

Sub test_add_fn_given_too_many()
  Local i%
  For i% = 1 To sym.MAX_FUNCTIONS%
    assert_int_equals(i% - 1, sym.add_function%("fun_" + Str$(i%)))
  Next

  assert_int_equals(sys.FAILURE, sym.add_function%("straw"))
  assert_error("Too many FUNCTION/SUBs, max 32")
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
  assert_int_equals(1, sym.get_references%("my_function_1", actual$()))
  expected$(0) = "foo"
  assert_string_array_equals(expected$(), actual$())

  assert_int_equals(2, sym.add_reference%("bar"))
  assert_string_equals("2", map2.get$(sym.names$(), "bar"))
  assert_int_equals(2, sym.get_references%("my_function_1", actual$()))
  expected$(0) = "bar"
  expected$(1) = "foo"
  assert_string_array_equals(expected$(), actual$())

  ' Start adding references from a new function.
  assert_int_equals(3, sym.add_function%("my_function_2", "my_file.inc", 42))

  assert_int_equals(2, sym.add_reference%("bar"))
  assert_string_equals("2", map2.get$(sym.names$(), "bar"))
  clear_arrays()
  assert_int_equals(1, sym.get_references%("my_function_2", actual$()))
  expected$(0) = "bar"
  assert_string_array_equals(expected$(), actual$())

  assert_int_equals(1, sym.add_reference%("foo"))
  assert_string_equals("1", map2.get$(sym.names$(), "foo"))
  assert_int_equals(2, sym.get_references%("my_function_2", actual$()))
  expected$(0) = "bar"
  expected$(1) = "foo"
  assert_string_array_equals(expected$(), actual$())

  ' Verify contents of the 'References' table.
  Local iexpected%(6) = ( 1, 2, &hFFFFFFFF, 2, 1, &hFFFFFFFF, &hFFFFFFFF)
  Local iactual%(6), i%
  For i% = 0 To 6 : iactual%(i%) = Peek(Word sym.P_REF_BASE% + 4 * i%) : Next
  assert_int_array_equals(iexpected%(), iactual%())
End Sub

Sub test_add_ref_given_present()
  Const fn1_id% = sym.add_function%("my_function_1", "my_file.inc", 42)
  Const foo_id% = sym.add_reference%("foo")
  Const bar_id% = sym.add_reference%("bar")

  ' Duplicate existing references.
  assert_int_equals(foo_id%, sym.add_reference%("foo"))
  assert_int_equals(bar_id%, sym.add_reference%("bar"))
  assert_int_equals(2, sym.get_references%("my_function_1", actual$()))
  expected$(0) = "bar"
  expected$(1) = "foo"
  assert_string_array_equals(expected$(), actual$())

  ' Verify contents of the 'References' table.
  Local expected%(3) = ( 1, 2, &hFFFFFFFF, &hFFFFFFFF)
  Local actual%(3), i%
  For i% = 0 To 3 : actual%(i%) = Peek(Word sym.P_REF_BASE% + 4 * i%) : Next
  assert_int_array_equals(expected%(), actual%())
End Sub

Sub test_add_ref_given_too_many()
  Const fn1_id% = sym.add_function%("my_function_1", "my_file.inc", 42)
  Local i%
  For i% = 1 To 256
    assert_int_equals(i%, sym.add_reference%("id_" + Str$(i%)))
  Next

  assert_int_equals(sys.FAILURE, sym.add_reference%("id_257"))
  assert_error("Too many references")
End Sub

Sub test_add_ref_given_too_long()
  Const fn1_id% = sym.add_function%("my_function_1", "my_file.inc", 42)

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

Sub test_name_to_id_given_present()
  assert_int_equals(0, sym.add_name%("foo"))
  assert_int_equals(1, sym.add_name%("BAR"))

  assert_int_equals(0, sym.name_to_id%("foo"))
  assert_int_equals(0, sym.name_to_id%("FOO"))
  assert_int_equals(1, sym.name_to_id%("bar"))
  assert_int_equals(1, sym.name_to_id%("BAR"))
End Sub

Sub test_name_to_id_given_absent()
  assert_no_error()
  assert_int_equals(sys.FAILURE, sym.name_to_id%("foo"))
  assert_error("Name not found")
End Sub

Sub test_name_to_id_given_hash_pfx()
  assert_int_equals(0, sym.add_name%("foo"))
  assert_int_equals(1, sym.add_name%("#bar"))

  assert_int_equals(0, sym.name_to_id%("foo"))
  assert_int_equals(0, sym.name_to_id%("#foo"))
  assert_int_equals(1, sym.name_to_id%("bar"))
  assert_int_equals(1, sym.name_to_id%("#bar"))
End Sub

Sub test_switch_fn_given_absent()
  assert_int_equals(sys.FAILURE, sym.switch_function%("absent"))
  assert_error("FUNCTION/SUB not found")
End Sub

Sub test_switch_fn_given_present()
  assert_int_equals(0, sym.add_function%("fn_a", "my_file.inc", 10))
  assert_int_equals(1, sym.add_reference%("one"))
  assert_int_equals(2, sym.add_function%("fn_b", "my_file.inc", 20))
  assert_int_equals(3, sym.add_reference%("two"))
  assert_int_equals(4, sym.add_function%("fn_c", "my_file.inc", 30))
  assert_int_equals(5, sym.add_reference%("three"))

  ' Check initial fixture state.
  expected$(0) = "one"
  assert_int_equals(1, sym.get_references%("fn_a", actual$()))
  assert_string_array_equals(expected$(), actual$())

  expected$(0) = "two"
  assert_int_equals(1, sym.get_references%("fn_b", actual$()))
  assert_string_array_equals(expected$(), actual$())

  expected$(0) = "three"
  assert_int_equals(1, sym.get_references%("fn_c", actual$()))
  assert_string_array_equals(expected$(), actual$())

  ' Switch current function and add new reference.
  assert_int_equals(2, sym.switch_function%("fn_b"))
  assert_int_equals(6, sym.add_reference%("four"))
  assert_int_equals(7, sym.add_reference%("five"))

  ' Check final state.
  expected$(0) = "one"
  assert_int_equals(1, sym.get_references%("fn_a", actual$()))
  assert_string_array_equals(expected$(), actual$())

  expected$(0) = "five"
  expected$(1) = "four"
  expected$(2) = "two"
  assert_int_equals(3, sym.get_references%("fn_b", actual$()))
  assert_string_array_equals(expected$(), actual$())

  clear_arrays()
  expected$(0) = "three"
  assert_int_equals(1, sym.get_references%("fn_c", actual$()))
  assert_string_array_equals(expected$(), actual$())
End Sub

Sub test_switch_fn_to_last()
  assert_int_equals(0, sym.add_function%("fn_a", "my_file.inc", 10))
  assert_int_equals(1, sym.add_reference%("one"))
  assert_int_equals(2, sym.add_function%("fn_b", "my_file.inc", 20))
  assert_int_equals(3, sym.add_reference%("two"))
  assert_int_equals(4, sym.add_function%("fn_c", "my_file.inc", 30))
  assert_int_equals(5, sym.add_reference%("three"))
  assert_int_equals(2, sym.switch_function%("fn_b"))
  assert_int_equals(6, sym.add_reference%("four"))
  assert_int_equals(7, sym.add_reference%("five"))

  ' Switch function to last.
  assert_int_equals(4, sym.switch_function%("fn_c"))
  assert_int_equals(8, sym.add_reference%("six"))

  ' Check references.
  expected$(0) = "one"
  assert_int_equals(1, sym.get_references%("fn_a", actual$()))
  assert_string_array_equals(expected$(), actual$())

  expected$(0) = "five"
  expected$(1) = "four"
  expected$(2) = "two"
  assert_int_equals(3, sym.get_references%("fn_b", actual$()))
  assert_string_array_equals(expected$(), actual$())

  clear_arrays()
  expected$(0) = "six"
  expected$(1) = "three"
  assert_int_equals(2, sym.get_references%("fn_c", actual$()))
  assert_string_array_equals(expected$(), actual$())
End Sub

Sub test_add_fn_after_switch()
  assert_int_equals(0, sym.add_function%("fn_a", "my_file.inc", 10))
  assert_int_equals(1, sym.add_reference%("one"))
  assert_int_equals(2, sym.add_function%("fn_b", "my_file.inc", 20))
  assert_int_equals(3, sym.add_reference%("two"))
  assert_int_equals(4, sym.add_function%("fn_c", "my_file.inc", 30))
  assert_int_equals(5, sym.add_reference%("three"))

  ' Switch back to "fn_a"
  assert_int_equals(0, sym.switch_function%("fn_a"))

  ' Now start a new function "fn_d"
  assert_int_equals(6, sym.add_function%("fn_d", "my_file.inc", 30))
  assert_int_equals(7, sym.add_reference%("six"))

  ' Check references.
  expected$(0) = "one"
  assert_int_equals(1, sym.get_references%("fn_a", actual$()))
  assert_string_array_equals(expected$(), actual$())

  expected$(0) = "two"
  assert_int_equals(1, sym.get_references%("fn_b", actual$()))
  assert_string_array_equals(expected$(), actual$())

  clear_arrays()
  expected$(0) = "three"
  assert_int_equals(1, sym.get_references%("fn_c", actual$()))
  assert_string_array_equals(expected$(), actual$())

  expected$(0) = "six"
  assert_int_equals(1, sym.get_references%("fn_d", actual$()))
  assert_string_array_equals(expected$(), actual$())
End Sub

Sub test_name_to_fn_given_present()
  assert_int_equals(0, sym.add_name%("foo"))
  assert_int_equals(1, sym.add_function%("FN_1", "my_file.inc", 42))
  assert_int_equals(2, sym.add_function%("FN_2", "my_file.inc", 99))

  Local fn_data$
  assert_int_equals(1, sym.name_to_fn%("fn_1", fn_data$))
  assert_string_equals("FN_1,0,42,0,1", fn_data$)
  assert_int_equals(1, sym.name_to_fn%("FN_1", fn_data$))
  assert_string_equals("FN_1,0,42,0,1", fn_data$)
  assert_int_equals(2, sym.name_to_fn%("fn_2", fn_data$))
  assert_string_equals("FN_2,0,99,4,2", fn_data$)
  assert_int_equals(2, sym.name_to_fn%("FN_2", fn_data$))
  assert_string_equals("FN_2,0,99,4,2", fn_data$)
End Sub

Sub test_name_to_fn_given_absent()
  Local fn_data$
  assert_no_error()
  assert_int_equals(sys.FAILURE, sym.name_to_fn%("fn_1", fn_data$))
  assert_error("FUNCTION/SUB not found")
End Sub

Sub test_id_to_fn()
  assert_int_equals(0, sym.add_name%("foo"))
  assert_int_equals(1, sym.add_function%("FN_1", "my_file.inc", 42))
  assert_int_equals(2, sym.add_function%("FN_2", "my_file.inc", 99))

  Local fn_data$
  fn_data$ = sym.id_to_fn$(0)
  assert_string_equals(sys.NO_DATA$, fn_data$)
  fn_data$ = sym.id_to_fn$(1)
  assert_string_equals("FN_1,0,42,0,1", fn_data$)
  fn_data$ = sym.id_to_fn$(2)
  assert_string_equals("FN_2,0,99,4,2", fn_data$)
  fn_data$ = sym.id_to_fn$(3)
  assert_string_equals(sys.NO_DATA$, fn_data$)
End Sub

Sub test_id_to_name_given_present()
  assert_int_equals(0, sym.add_name%("wombat"))
  assert_int_equals(1, sym.add_name%("foo"))
  assert_int_equals(2, sym.add_name%("BAR"))

  assert_string_equals("wombat", sym.id_to_name$(0))
  assert_string_equals("foo", sym.id_to_name$(1))
  assert_string_equals("bar", sym.id_to_name$(2))
End Sub

Sub test_id_to_name_given_absent()
  assert_no_error()
  assert_string_equals(sys.NO_DATA$, sym.id_to_name$(0))
  assert_error("Invalid id")
End Sub

Sub test_get_files()
  assert_int_equals(0, sym.get_files%(actual$()))
  assert_string_array_equals(expected$(), actual$())

  assert_int_equals(0, sym.add_file%("foo"))
  assert_int_equals(1, sym.add_file%("bar"))
  assert_int_equals(2, sym.add_file%("wombat"))

  assert_int_equals(3, sym.get_files%(actual$()))
  expected$(0) = "bar"
  expected$(1) = "foo"
  expected$(2) = "wombat"
  assert_string_array_equals(expected$(), actual$())

  ' Test behaviour when array capacity < num. of files.
  Local actual_short$(1)
  Local expected_short$(1)
  assert_int_equals(3, sym.get_files%(actual_short$()))
  expected_short$(0) = expected$(0)
  expected_short$(1) = expected$(1)
  assert_string_array_equals(expected_short$(), actual_short$())
End Sub

Sub test_get_names()
  assert_int_equals(0, sym.get_names%(actual$()))
  assert_string_array_equals(expected$(), actual$())

  assert_int_equals(0, sym.add_name%("foo"))
  assert_int_equals(1, sym.add_name%("bar"))
  assert_int_equals(2, sym.add_name%("wombat"))

  assert_int_equals(3, sym.get_names%(actual$()))
  expected$(0) = "bar"
  expected$(1) = "foo"
  expected$(2) = "wombat"
  assert_string_array_equals(expected$(), actual$())

  ' Test behaviour when array capacity < num. of names.
  Local actual_short$(1)
  Local expected_short$(1)
  assert_int_equals(3, sym.get_names%(actual_short$()))
  expected_short$(0) = expected$(0)
  expected_short$(1) = expected$(1)
  assert_string_array_equals(expected_short$(), actual_short$())
End Sub

Sub test_get_functions()
  assert_int_equals(0, sym.get_functions%(actual$()))
  assert_string_array_equals(expected$(), actual$())

  assert_int_equals(0, sym.add_function%("foo", "my_file", 42))
  assert_int_equals(1, sym.add_function%("bar", "my_file", 43))
  assert_int_equals(2, sym.add_function%("wombat", "my_file2", 44))

  assert_int_equals(3, sym.get_functions%(actual$()))
  expected$(0) = "bar,0,43,4,1"
  expected$(1) = "foo,0,42,0,0"
  expected$(2) = "wombat,1,44,8,2"
  assert_string_array_equals(expected$(), actual$())

  ' Test behaviour when array capacity < num. of functions.
  Local actual_short$(1)
  Local expected_short$(1)
  assert_int_equals(3, sym.get_functions%(actual_short$()))
  expected_short$(0) = expected$(0)
  expected_short$(1) = expected$(1)
  assert_string_array_equals(expected_short$(), actual_short$())
End Sub

Sub test_get_referenced_ids()
  Local actual%(3), expected%(3)

  assert_int_equals(0, sym.add_function%("root", "my_file", 1))
  assert_int_equals(1, sym.add_reference%("foo"))
  assert_int_equals(1, sym.add_function%("foo", "my_file", 42))
  assert_int_equals(2, sym.add_reference%("bar"))
  assert_int_equals(3, sym.add_reference%("wombat"))
  assert_int_equals(2, sym.add_function%("bar", "my_file", 43))
  assert_int_equals(3, sym.add_function%("wombat", "my_file2", 44))

  assert_int_equals(1, sym.get_referenced_ids%(0, actual%()))
  expected%(0) = 1
  assert_int_array_equals(expected%(), actual%())

  assert_int_equals(2, sym.get_referenced_ids%(1, actual%()))
  expected%(0) = 2
  expected%(1) = 3
  assert_int_array_equals(expected%(), actual%())

  assert_int_equals(0, sym.get_referenced_ids%(2, actual%()))
  assert_int_equals(0, sym.get_referenced_ids%(3, actual%()))

  assert_int_equals(sys.FAILURE, sym.get_referenced_ids%(4, actual%()))
  assert_error("FUNCTION/SUB not found")
End Sub

Sub test_get_ref_id_too_many()
  Local actual%(2), expected%(2)

  assert_int_equals(0, sym.add_function%("*global*", "my_file", 1))
  assert_int_equals(1, sym.add_reference%("one"))
  assert_int_equals(2, sym.add_reference%("two"))
  assert_int_equals(3, sym.add_reference%("three"))
  assert_int_equals(4, sym.add_reference%("four"))

  assert_int_equals(4, sym.get_referenced_ids%(0, actual%()))
  expected%(0) = 1
  expected%(1) = 2
  expected%(2) = 3
  assert_int_array_equals(expected%(), actual%())
End Sub

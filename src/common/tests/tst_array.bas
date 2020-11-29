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
#Include "../vt100.inc"
#Include "../../sptest/unittest.inc"

add_test("test_capacity")
add_test("test_copy")
add_test("test_fill")
add_test("test_case_sens_ascending_sort")
add_test("test_case_sens_descending_sort")
add_test("test_case_insens_ascending_sort")
add_test("test_case_insens_descending_sort")
add_test("test_case_sens_bsearch")
add_test("test_case_insens_bsearch")

If InStr(Mm.CmdLine$, "--base") Then run_tests() Else run_tests("--base=1")

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Sub test_capacity()
  Local a$(array.new%(5))

  assert_equals(5, array.capacity%(a$()))
End Sub

Sub test_copy()
  Local base% = Mm.Info(Option Base)
  Local src$(array.new%(5)) = ("one", "two", "three", "four", "five")
  Local dst$(array.new%(5))

  ' Test default copy.
  array.copy(src$(), dst$())

  assert_string_equals("one",   dst$(base% + 0))
  assert_string_equals("two",   dst$(base% + 1))
  assert_string_equals("three", dst$(base% + 2))
  assert_string_equals("four",  dst$(base% + 3))
  assert_string_equals("five",  dst$(base% + 4))

  ' Test copy first 3 elements from source.
  array.fill(dst$())
  array.copy(src$(), dst$(), base%, base%, 3)

  assert_string_equals("one",   dst$(base% + 0))
  assert_string_equals("two",   dst$(base% + 1))
  assert_string_equals("three", dst$(base% + 2))
  assert_string_equals("",      dst$(base% + 3))
  assert_string_equals("",      dst$(base% + 4))

  ' Test copy middle 3 elements from source.
  array.fill(dst$())
  array.copy(src$(), dst$(), base% + 1, base%, 3)

  assert_string_equals("two",   dst$(base% + 0))
  assert_string_equals("three", dst$(base% + 1))
  assert_string_equals("four",  dst$(base% + 2))
  assert_string_equals("",      dst$(base% + 3))
  assert_string_equals("",      dst$(base% + 4))

  ' Test copy last 3 elements from source.
  array.fill(dst$())
  array.copy(src$(), dst$(), base% + 2, base%, 3)

  assert_string_equals("three", dst$(base% + 0))
  assert_string_equals("four",  dst$(base% + 1))
  assert_string_equals("five",  dst$(base% + 2))
  assert_string_equals("",      dst$(base% + 3))
  assert_string_equals("",      dst$(base% + 4))

  ' Test copy to middle 3 elements of destination.
  array.fill(dst$())
  array.copy(src$(), dst$(), base% + 1, base% + 1, 3)

  assert_string_equals("",      dst$(base% + 0))
  assert_string_equals("two",   dst$(base% + 1))
  assert_string_equals("three", dst$(base% + 2))
  assert_string_equals("four",  dst$(base% + 3))
  assert_string_equals("",      dst$(base% + 4))

  ' Test copy to last 3 elements of destination.
  array.fill(dst$())
  array.copy(src$(), dst$(), base% + 1, base% + 2, 3)

  assert_string_equals("",      dst$(base% + 0))
  assert_string_equals("",      dst$(base% + 1))
  assert_string_equals("two",   dst$(base% + 2))
  assert_string_equals("three", dst$(base% + 3))
  assert_string_equals("four",  dst$(base% + 4))

  ' Test copy with no dst_idx% specified
  array.fill(dst$())
  array.copy(src$(), dst$(), base% + 1)

  assert_string_equals("two",   dst$(base% + 0))
  assert_string_equals("three", dst$(base% + 1))
  assert_string_equals("four",  dst$(base% + 2))
  assert_string_equals("five",  dst$(base% + 3))
  assert_string_equals("",      dst$(base% + 4))

  ' Test copy with no num% specified
  array.fill(dst$())
  array.copy(src$(), dst$(), base% + 1, base% + 1)

  assert_string_equals("",      dst$(base% + 0))
  assert_string_equals("two",   dst$(base% + 1))
  assert_string_equals("three", dst$(base% + 2))
  assert_string_equals("four",  dst$(base% + 3))
  assert_string_equals("five",  dst$(base% + 4))

End Sub

Sub test_fill()
  Local a$(array.new%(5))

  array.fill(a$(), "foo")

  Local i%
  For i% = Bound(a$(), 0) To Bound(a$(), 1)
    assert_string_equals("foo", a$(i%))
  Next

  array.fill(a$())

  For i% = Bound(a$(), 0) To Bound(a$(), 1)
    assert_string_equals("", a$(i%))
  Next
End Sub

Sub test_case_sens_ascending_sort()
  Local base% = Mm.Info(Option Base)
  Local test_data$(array.new%(5)) = ("one", "two", "three", "four", "five")
  Local a$(array.new%(5))

  ' Sort entire array.
  array.copy(test_data$(), a$())
  array.sort(a$())

  assert_string_equals("five",  a$(base% + 0))
  assert_string_equals("four",  a$(base% + 1))
  assert_string_equals("one",   a$(base% + 2))
  assert_string_equals("three", a$(base% + 3))
  assert_string_equals("two",   a$(base% + 4))

  ' Sort first three elements.
  array.copy(test_data$(), a$())
  array.sort(a$(), "", base%, 3)

  assert_string_equals("one",   a$(base% + 0))
  assert_string_equals("three", a$(base% + 1))
  assert_string_equals("two",   a$(base% + 2))
  assert_string_equals("four",  a$(base% + 3))
  assert_string_equals("five",  a$(base% + 4))

  ' Sort middle three elements.
  array.copy(test_data$(), a$())
  array.sort(a$(), "", base% + 1, 3)

  assert_string_equals("one",   a$(base% + 0))
  assert_string_equals("four",  a$(base% + 1))
  assert_string_equals("three", a$(base% + 2))
  assert_string_equals("two",   a$(base% + 3))
  assert_string_equals("five",  a$(base% + 4))

  ' Sort last three elements.
  array.copy(test_data$(), a$())
  array.sort(a$(), "", base% + 2, 3)

  assert_string_equals("one",   a$(base% + 0))
  assert_string_equals("two",   a$(base% + 1))
  assert_string_equals("five",  a$(base% + 2))
  assert_string_equals("four",  a$(base% + 3))
  assert_string_equals("three", a$(base% + 4))

  ' Sort single elements
  Local i%
  array.copy(test_data$(), a$())
  For i% = base% To base% + 4
    array.sort(a$(), "", i%, 1)

    assert_string_equals("one",   a$(base% + 0))
    assert_string_equals("two",   a$(base% + 1))
    assert_string_equals("three", a$(base% + 2))
    assert_string_equals("four",  a$(base% + 3))
    assert_string_equals("five",  a$(base% + 4))
  Next

End Sub

Sub test_case_sens_descending_sort()
  Local base% = Mm.Info(Option Base)
  Local test_data$(array.new%(5)) = ("one", "two", "three", "four", "five")
  Local a$(array.new%(5))

  ' Sort entire array.
  array.copy(test_data$(), a$())
  array.sort(a$(), "d")

  assert_string_equals("two",   a$(base% + 0))
  assert_string_equals("three", a$(base% + 1))
  assert_string_equals("one",   a$(base% + 2))
  assert_string_equals("four",  a$(base% + 3))
  assert_string_equals("five",  a$(base% + 4))

  ' Sort first three elements.
  array.copy(test_data$(), a$())
  array.sort(a$(), "d", base%, 3)

  assert_string_equals("two",   a$(base% + 0))
  assert_string_equals("three", a$(base% + 1))
  assert_string_equals("one",   a$(base% + 2))
  assert_string_equals("four",  a$(base% + 3))
  assert_string_equals("five",  a$(base% + 4))

  ' Sort middle three elements.
  array.copy(test_data$(), a$())
  array.sort(a$(), "d", base% + 1, 3)

  assert_string_equals("one",   a$(base% + 0))
  assert_string_equals("two",   a$(base% + 1))
  assert_string_equals("three", a$(base% + 2))
  assert_string_equals("four",  a$(base% + 3))
  assert_string_equals("five",  a$(base% + 4))

  ' Sort last three elements.
  array.copy(test_data$(), a$())
  array.sort(a$(), "d", base% + 2, 3)

  assert_string_equals("one",   a$(base% + 0))
  assert_string_equals("two",   a$(base% + 1))
  assert_string_equals("three", a$(base% + 2))
  assert_string_equals("four",  a$(base% + 3))
  assert_string_equals("five",  a$(base% + 4))

  ' Sort single elements
  Local i%
  array.copy(test_data$(), a$())
  For i% = base% To base% + 4
    array.sort(a$(), "d", i%, 1)

    assert_string_equals("one",   a$(base% + 0))
    assert_string_equals("two",   a$(base% + 1))
    assert_string_equals("three", a$(base% + 2))
    assert_string_equals("four",  a$(base% + 3))
    assert_string_equals("five",  a$(base% + 4))
  Next

End Sub

Sub test_case_insens_ascending_sort()
  Local base% = Mm.Info(Option Base)
  Local test_data$(array.new%(5)) = ("fubar1", "fuBar3", "Fubar2", "FuBar5", "FUBAR4")
  Local a$(array.new%(5))

  ' Sort entire array.
  array.copy(test_data$(), a$())
  array.sort(a$(), "i")

  assert_string_equals("fubar1", a$(base% + 0))
  assert_string_equals("Fubar2", a$(base% + 1))
  assert_string_equals("fuBar3", a$(base% + 2))
  assert_string_equals("FUBAR4", a$(base% + 3))
  assert_string_equals("FuBar5", a$(base% + 4))

  ' Sort first three elements.
  array.copy(test_data$(), a$())
  array.sort(a$(), "i", base%, 3)

  assert_string_equals("fubar1", a$(base% + 0))
  assert_string_equals("Fubar2", a$(base% + 1))
  assert_string_equals("fuBar3", a$(base% + 2))
  assert_string_equals("FuBar5", a$(base% + 3))
  assert_string_equals("FUBAR4", a$(base% + 4))

  ' Sort middle three elements.
  array.copy(test_data$(), a$())
  array.sort(a$(), "i", base% + 1, 3)

  assert_string_equals("fubar1", a$(base% + 0))
  assert_string_equals("Fubar2", a$(base% + 1))
  assert_string_equals("fuBar3", a$(base% + 2))
  assert_string_equals("FuBar5", a$(base% + 3))
  assert_string_equals("FUBAR4", a$(base% + 4))

  ' Sort last three elements.
  array.copy(test_data$(), a$())
  array.sort(a$(), "i", base% + 2, 3)

  assert_string_equals("fubar1", a$(base% + 0))
  assert_string_equals("fuBar3", a$(base% + 1))
  assert_string_equals("Fubar2", a$(base% + 2))
  assert_string_equals("FUBAR4", a$(base% + 3))
  assert_string_equals("FuBar5", a$(base% + 4))

  ' Sort single elements
  array.copy(test_data$(), a$())
  Local i%
  For i% = base% To base% + 4
    array.sort(a$(), "i", i%, 1)

    assert_string_equals("fubar1", a$(base% + 0))
    assert_string_equals("fuBar3", a$(base% + 1))
    assert_string_equals("Fubar2", a$(base% + 2))
    assert_string_equals("FuBar5", a$(base% + 3))
    assert_string_equals("FUBAR4", a$(base% + 4))
  Next

End Sub

Sub test_case_insens_descending_sort()
  Local base% = Mm.Info(Option Base)
  Local test_data$(array.new%(5)) = ("fubar1", "fuBar3", "Fubar2", "FuBar5", "FUBAR4")
  Local a$(array.new%(5))

  ' Sort entire array.
  array.copy(test_data$(), a$())
  array.sort(a$(), "id")

  assert_string_equals("FuBar5", a$(base% + 0))
  assert_string_equals("FUBAR4", a$(base% + 1))
  assert_string_equals("fuBar3", a$(base% + 2))
  assert_string_equals("Fubar2", a$(base% + 3))
  assert_string_equals("fubar1", a$(base% + 4))

  ' Sort first three elements.
  array.copy(test_data$(), a$())
  array.sort(a$(), "id", base%, 3)

  assert_string_equals("fuBar3", a$(base% + 0))
  assert_string_equals("Fubar2", a$(base% + 1))
  assert_string_equals("fubar1", a$(base% + 2))
  assert_string_equals("FuBar5", a$(base% + 3))
  assert_string_equals("FUBAR4", a$(base% + 4))

  ' Sort middle three elements.
  array.copy(test_data$(), a$())
  array.sort(a$(), "id", base% + 1, 3)

  assert_string_equals("fubar1", a$(base% + 0))
  assert_string_equals("FuBar5", a$(base% + 1))
  assert_string_equals("fuBar3", a$(base% + 2))
  assert_string_equals("Fubar2", a$(base% + 3))
  assert_string_equals("FUBAR4", a$(base% + 4))

  ' Sort last three elements.
  array.copy(test_data$(), a$())
  array.sort(a$(), "id", base% + 2, 3)

  assert_string_equals("fubar1", a$(base% + 0))
  assert_string_equals("fuBar3", a$(base% + 1))
  assert_string_equals("FuBar5", a$(base% + 2))
  assert_string_equals("FUBAR4", a$(base% + 3))
  assert_string_equals("Fubar2", a$(base% + 4))

  ' Sort single elements
  array.copy(test_data$(), a$())
  Local i%
  For i% = base% To base% + 4
    array.sort(a$(), "id", i%, 1)

    assert_string_equals("fubar1", a$(base% + 0))
    assert_string_equals("fuBar3", a$(base% + 1))
    assert_string_equals("Fubar2", a$(base% + 2))
    assert_string_equals("FuBar5", a$(base% + 3))
    assert_string_equals("FUBAR4", a$(base% + 4))
  Next

End Sub

Sub test_case_sens_bsearch()
  Local base% = Mm.Info(Option Base)
  Local a$(array.new%(5)) = ("abc", "def", "ghi", "jkl", "mno")

  assert_equals(base% + 0, array.bsearch%(a$(), "abc"))
  assert_equals(base% + 1, array.bsearch%(a$(), "def"))
  assert_equals(base% + 2, array.bsearch%(a$(), "ghi"))
  assert_equals(base% + 3, array.bsearch%(a$(), "jkl"))
  assert_equals(base% + 4, array.bsearch%(a$(), "mno"))
  assert_equals(-1,        array.bsearch%(a$(), "wombat"))

  Local lb% = base% + 1
  assert_equals(-1,        array.bsearch%(a$(), "abc", "", lb%))
  assert_equals(base% + 1, array.bsearch%(a$(), "def", "", lb%))
  assert_equals(base% + 2, array.bsearch%(a$(), "ghi", "", lb%))
  assert_equals(base% + 3, array.bsearch%(a$(), "jkl", "", lb%))
  assert_equals(base% + 4, array.bsearch%(a$(), "mno", "", lb%))

  lb% = base% + 2
  assert_equals(-1,        array.bsearch%(a$(), "abc", "", lb%))
  assert_equals(-1,        array.bsearch%(a$(), "def", "", lb%))
  assert_equals(base% + 2, array.bsearch%(a$(), "ghi", "", lb%))
  assert_equals(base% + 3, array.bsearch%(a$(), "jkl", "", lb%))
  assert_equals(base% + 4, array.bsearch%(a$(), "mno", "", lb%))

  Local num% = 4
  lb% = base%
  assert_equals(base% + 0, array.bsearch%(a$(), "abc", "", lb%, num%));
  assert_equals(base% + 1, array.bsearch%(a$(), "def", "", lb%, num%));
  assert_equals(base% + 2, array.bsearch%(a$(), "ghi", "", lb%, num%));
  assert_equals(base% + 3, array.bsearch%(a$(), "jkl", "", lb%, num%));
  assert_equals(-1,        array.bsearch%(a$(), "mno", "", lb%, num%));

  num% = 3
  assert_equals(base% + 0, array.bsearch%(a$(), "abc", "", lb%, num%));
  assert_equals(base% + 1, array.bsearch%(a$(), "def", "", lb%, num%));
  assert_equals(base% + 2, array.bsearch%(a$(), "ghi", "", lb%, num%));
  assert_equals(-1,        array.bsearch%(a$(), "jkl", "", lb%, num%));
  assert_equals(-1,        array.bsearch%(a$(), "mno", "", lb%, num%));

  lb% = base% + 1
  num% = 2
  assert_equals(-1,        array.bsearch%(a$(), "abc", "", lb%, num%));
  assert_equals(base% + 1, array.bsearch%(a$(), "def", "", lb%, num%));
  assert_equals(base% + 2, array.bsearch%(a$(), "ghi", "", lb%, num%));
  assert_equals(-1,        array.bsearch%(a$(), "jkl", "", lb%, num%));
  assert_equals(-1,        array.bsearch%(a$(), "mno", "", lb%, num%));

  num% = 1
  assert_equals(-1,        array.bsearch%(a$(), "abc", "", lb%, num%));
  assert_equals(base% + 1, array.bsearch%(a$(), "def", "", lb%, num%));
  assert_equals(-1,        array.bsearch%(a$(), "ghi", "", lb%, num%));
  assert_equals(-1,        array.bsearch%(a$(), "jkl", "", lb%, num%));
  assert_equals(-1,        array.bsearch%(a$(), "mno", "", lb%, num%));

  ' Test that the search is case-sensitive.
  assert_equals(-1, array.bsearch%(a$(), "abC"))
  assert_equals(-1, array.bsearch%(a$(), "DEF"))
  assert_equals(-1, array.bsearch%(a$(), "gHi"))
  assert_equals(-1, array.bsearch%(a$(), "jKL"))
  assert_equals(-1, array.bsearch%(a$(), "MNo"))
End Sub

Sub test_case_insens_bsearch()
  Local base% = Mm.Info(Option Base)
  Local a$(array.new%(5)) = ("abc", "DEf", "gHi", "jkL", "MNO")

  assert_equals(base% + 0, array.bsearch%(a$(), "abc", "i"))
  assert_equals(base% + 1, array.bsearch%(a$(), "def", "i"))
  assert_equals(base% + 2, array.bsearch%(a$(), "ghi", "i"))
  assert_equals(base% + 3, array.bsearch%(a$(), "jkl", "i"))
  assert_equals(base% + 4, array.bsearch%(a$(), "mno", "i"))
  assert_equals(-1,        array.bsearch%(a$(), "wombat"))

  Local lb% = base% + 1
  assert_equals(-1,        array.bsearch%(a$(), "abc", "i", lb%))
  assert_equals(base% + 1, array.bsearch%(a$(), "def", "i", lb%))
  assert_equals(base% + 2, array.bsearch%(a$(), "ghi", "i", lb%))
  assert_equals(base% + 3, array.bsearch%(a$(), "jkl", "i", lb%))
  assert_equals(base% + 4, array.bsearch%(a$(), "mno", "i", lb%))

  lb% = base% + 2
  assert_equals(-1,        array.bsearch%(a$(), "abc", "i", lb%))
  assert_equals(-1,        array.bsearch%(a$(), "def", "i", lb%))
  assert_equals(base% + 2, array.bsearch%(a$(), "ghi", "i", lb%))
  assert_equals(base% + 3, array.bsearch%(a$(), "jkl", "i", lb%))
  assert_equals(base% + 4, array.bsearch%(a$(), "mno", "i", lb%))

  Local num% = 4
  lb% = base%
  assert_equals(base% + 0, array.bsearch%(a$(), "abc", "i", lb%, num%));
  assert_equals(base% + 1, array.bsearch%(a$(), "def", "i", lb%, num%));
  assert_equals(base% + 2, array.bsearch%(a$(), "ghi", "i", lb%, num%));
  assert_equals(base% + 3, array.bsearch%(a$(), "jkl", "i", lb%, num%));
  assert_equals(-1,        array.bsearch%(a$(), "mno", "i", lb%, num%));

  num% = 3
  assert_equals(base% + 0, array.bsearch%(a$(), "abc", "i", lb%, num%));
  assert_equals(base% + 1, array.bsearch%(a$(), "def", "i", lb%, num%));
  assert_equals(base% + 2, array.bsearch%(a$(), "ghi", "i", lb%, num%));
  assert_equals(-1,        array.bsearch%(a$(), "jkl", "i", lb%, num%));
  assert_equals(-1,        array.bsearch%(a$(), "mno", "i", lb%, num%));

  lb% = base% + 1
  num% = 2
  assert_equals(-1,        array.bsearch%(a$(), "abc", "i", lb%, num%));
  assert_equals(base% + 1, array.bsearch%(a$(), "def", "i", lb%, num%));
  assert_equals(base% + 2, array.bsearch%(a$(), "ghi", "i", lb%, num%));
  assert_equals(-1,        array.bsearch%(a$(), "jkl", "i", lb%, num%));
  assert_equals(-1,        array.bsearch%(a$(), "mno", "i", lb%, num%));

  num% = 1
  assert_equals(-1,        array.bsearch%(a$(), "abc", "i", lb%, num%));
  assert_equals(base% + 1, array.bsearch%(a$(), "def", "i", lb%, num%));
  assert_equals(-1,        array.bsearch%(a$(), "ghi", "i", lb%, num%));
  assert_equals(-1,        array.bsearch%(a$(), "jkl", "i", lb%, num%));
  assert_equals(-1,        array.bsearch%(a$(), "mno", "i", lb%, num%));
End Sub

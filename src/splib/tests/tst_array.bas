' Copyright (c) 2020-2023 Thomas Hugo Williams
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
#Include "../vt100.inc"
#Include "../../sptest/unittest.inc"

Const BASE = Mm.Info(Option Base)

add_test("test_capacity")
add_test("test_copy")
add_test("test_fill")
add_test("test_case_sens_bsearch")
add_test("test_case_insens_bsearch")
add_test("test_find")
add_test("test_find_gvn_case_insensitive")
add_test("test_join_floats")
add_test("test_join_ints")
add_test("test_join_strings")
add_test("test_qsort_ints_gvn_ordered")
add_test("test_qsort_ints_gvn_reversed")
add_test("test_qsort_ints_gvn_identical")
add_test("test_qsort_ints_gvn_1_element")
add_test("test_qsort_ints_gvn_2_elements")
add_test("test_qsort_ints_gvn_comparator")

If InStr(Mm.CmdLine$, "--base") Then run_tests() Else run_tests("--base=1")

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Sub test_capacity()
  Local a$(array.new%(5))

  assert_int_equals(5, array.capacity%(a$()))
End Sub

Sub test_copy()
  Local src$(array.new%(5)) = ("one", "two", "three", "four", "five")
  Local dst$(array.new%(5))

  ' Test default copy.
  array.copy(src$(), dst$())

  assert_string_equals("one",   dst$(BASE + 0))
  assert_string_equals("two",   dst$(BASE + 1))
  assert_string_equals("three", dst$(BASE + 2))
  assert_string_equals("four",  dst$(BASE + 3))
  assert_string_equals("five",  dst$(BASE + 4))

  ' Test copy first 3 elements from source.
  array.fill(dst$())
  array.copy(src$(), dst$(), BASE, BASE, 3)

  assert_string_equals("one",   dst$(BASE + 0))
  assert_string_equals("two",   dst$(BASE + 1))
  assert_string_equals("three", dst$(BASE + 2))
  assert_string_equals("",      dst$(BASE + 3))
  assert_string_equals("",      dst$(BASE + 4))

  ' Test copy middle 3 elements from source.
  array.fill(dst$())
  array.copy(src$(), dst$(), BASE + 1, BASE, 3)

  assert_string_equals("two",   dst$(BASE + 0))
  assert_string_equals("three", dst$(BASE + 1))
  assert_string_equals("four",  dst$(BASE + 2))
  assert_string_equals("",      dst$(BASE + 3))
  assert_string_equals("",      dst$(BASE + 4))

  ' Test copy last 3 elements from source.
  array.fill(dst$())
  array.copy(src$(), dst$(), BASE + 2, BASE, 3)

  assert_string_equals("three", dst$(BASE + 0))
  assert_string_equals("four",  dst$(BASE + 1))
  assert_string_equals("five",  dst$(BASE + 2))
  assert_string_equals("",      dst$(BASE + 3))
  assert_string_equals("",      dst$(BASE + 4))

  ' Test copy to middle 3 elements of destination.
  array.fill(dst$())
  array.copy(src$(), dst$(), BASE + 1, BASE + 1, 3)

  assert_string_equals("",      dst$(BASE + 0))
  assert_string_equals("two",   dst$(BASE + 1))
  assert_string_equals("three", dst$(BASE + 2))
  assert_string_equals("four",  dst$(BASE + 3))
  assert_string_equals("",      dst$(BASE + 4))

  ' Test copy to last 3 elements of destination.
  array.fill(dst$())
  array.copy(src$(), dst$(), BASE + 1, BASE + 2, 3)

  assert_string_equals("",      dst$(BASE + 0))
  assert_string_equals("",      dst$(BASE + 1))
  assert_string_equals("two",   dst$(BASE + 2))
  assert_string_equals("three", dst$(BASE + 3))
  assert_string_equals("four",  dst$(BASE + 4))

  ' Test copy with no dst_idx% specified
  array.fill(dst$())
  array.copy(src$(), dst$(), BASE + 1)

  assert_string_equals("two",   dst$(BASE + 0))
  assert_string_equals("three", dst$(BASE + 1))
  assert_string_equals("four",  dst$(BASE + 2))
  assert_string_equals("five",  dst$(BASE + 3))
  assert_string_equals("",      dst$(BASE + 4))

  ' Test copy with no num% specified
  array.fill(dst$())
  array.copy(src$(), dst$(), BASE + 1, BASE + 1)

  assert_string_equals("",      dst$(BASE + 0))
  assert_string_equals("two",   dst$(BASE + 1))
  assert_string_equals("three", dst$(BASE + 2))
  assert_string_equals("four",  dst$(BASE + 3))
  assert_string_equals("five",  dst$(BASE + 4))

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

Sub test_find()
  Local a$(array.new%(6)) = ("foo", "BAR", "bar", "wom", "wom", "bat")

  assert_int_equals(BASE + 0, array.find_string%(a$(), "foo"))
  assert_int_equals(-1,       array.find_string%(a$(), "FOO"))
  assert_int_equals(BASE + 2, array.find_string%(a$(), "bar"))
  assert_int_equals(BASE + 1, array.find_string%(a$(), "BAR"))
  assert_int_equals(BASE + 3, array.find_string%(a$(), "wom"))
  assert_int_equals(-1,       array.find_string%(a$(), "WOM"))
  assert_int_equals(BASE + 5, array.find_string%(a$(), "bat"))
  assert_int_equals(-1,       array.find_string%(a$(), "BAT"))
  assert_int_equals(-1,       array.find_string%(a$(), "snafu"))
  assert_int_equals(-1,       array.find_string%(a$(), ""))
End Sub

Sub test_find_gvn_case_insensitive()
  Local a$(array.new%(6)) = ("foo", "BAR", "bar", "wom", "wom", "bat")

  assert_int_equals(BASE + 0, array.find_string%(a$(), "foo", "i"))
  assert_int_equals(BASE + 0, array.find_string%(a$(), "FOO", "i"))
  assert_int_equals(BASE + 1, array.find_string%(a$(), "bar", "i"))
  assert_int_equals(BASE + 1, array.find_string%(a$(), "BAR", "i"))
  assert_int_equals(BASE + 3, array.find_string%(a$(), "wom", "i"))
  assert_int_equals(BASE + 3, array.find_string%(a$(), "WOM", "i"))
  assert_int_equals(BASE + 5, array.find_string%(a$(), "bat", "i"))
  assert_int_equals(BASE + 5, array.find_string%(a$(), "BAT", "i"))
  assert_int_equals(-1,       array.find_string%(a$(), "snafu", "i"))
  assert_int_equals(-1,       array.find_string%(a$(), "", "i"))
End Sub

Sub test_case_sens_bsearch()
  Local a$(array.new%(5)) = ("abc", "def", "ghi", "jkl", "mno")

  assert_int_equals(BASE + 0, array.bsearch%(a$(), "abc"))
  assert_int_equals(BASE + 1, array.bsearch%(a$(), "def"))
  assert_int_equals(BASE + 2, array.bsearch%(a$(), "ghi"))
  assert_int_equals(BASE + 3, array.bsearch%(a$(), "jkl"))
  assert_int_equals(BASE + 4, array.bsearch%(a$(), "mno"))
  assert_int_equals(-1,       array.bsearch%(a$(), "wombat"))

  Local lb% = BASE + 1
  assert_int_equals(-1,       array.bsearch%(a$(), "abc", "", lb%))
  assert_int_equals(BASE + 1, array.bsearch%(a$(), "def", "", lb%))
  assert_int_equals(BASE + 2, array.bsearch%(a$(), "ghi", "", lb%))
  assert_int_equals(BASE + 3, array.bsearch%(a$(), "jkl", "", lb%))
  assert_int_equals(BASE + 4, array.bsearch%(a$(), "mno", "", lb%))

  lb% = BASE + 2
  assert_int_equals(-1,       array.bsearch%(a$(), "abc", "", lb%))
  assert_int_equals(-1,       array.bsearch%(a$(), "def", "", lb%))
  assert_int_equals(BASE + 2, array.bsearch%(a$(), "ghi", "", lb%))
  assert_int_equals(BASE + 3, array.bsearch%(a$(), "jkl", "", lb%))
  assert_int_equals(BASE + 4, array.bsearch%(a$(), "mno", "", lb%))

  Local num% = 4
  lb% = BASE
  assert_int_equals(BASE + 0, array.bsearch%(a$(), "abc", "", lb%, num%));
  assert_int_equals(BASE + 1, array.bsearch%(a$(), "def", "", lb%, num%));
  assert_int_equals(BASE + 2, array.bsearch%(a$(), "ghi", "", lb%, num%));
  assert_int_equals(BASE + 3, array.bsearch%(a$(), "jkl", "", lb%, num%));
  assert_int_equals(-1,       array.bsearch%(a$(), "mno", "", lb%, num%));

  num% = 3
  assert_int_equals(BASE + 0, array.bsearch%(a$(), "abc", "", lb%, num%));
  assert_int_equals(BASE + 1, array.bsearch%(a$(), "def", "", lb%, num%));
  assert_int_equals(BASE + 2, array.bsearch%(a$(), "ghi", "", lb%, num%));
  assert_int_equals(-1,       array.bsearch%(a$(), "jkl", "", lb%, num%));
  assert_int_equals(-1,       array.bsearch%(a$(), "mno", "", lb%, num%));

  lb% = BASE + 1
  num% = 2
  assert_int_equals(-1,       array.bsearch%(a$(), "abc", "", lb%, num%));
  assert_int_equals(BASE + 1, array.bsearch%(a$(), "def", "", lb%, num%));
  assert_int_equals(BASE + 2, array.bsearch%(a$(), "ghi", "", lb%, num%));
  assert_int_equals(-1,       array.bsearch%(a$(), "jkl", "", lb%, num%));
  assert_int_equals(-1,       array.bsearch%(a$(), "mno", "", lb%, num%));

  num% = 1
  assert_int_equals(-1,       array.bsearch%(a$(), "abc", "", lb%, num%));
  assert_int_equals(BASE + 1, array.bsearch%(a$(), "def", "", lb%, num%));
  assert_int_equals(-1,       array.bsearch%(a$(), "ghi", "", lb%, num%));
  assert_int_equals(-1,       array.bsearch%(a$(), "jkl", "", lb%, num%));
  assert_int_equals(-1,       array.bsearch%(a$(), "mno", "", lb%, num%));

  ' Test that the search is case-sensitive.
  assert_int_equals(-1, array.bsearch%(a$(), "abC"))
  assert_int_equals(-1, array.bsearch%(a$(), "DEF"))
  assert_int_equals(-1, array.bsearch%(a$(), "gHi"))
  assert_int_equals(-1, array.bsearch%(a$(), "jKL"))
  assert_int_equals(-1, array.bsearch%(a$(), "MNo"))
End Sub

Sub test_case_insens_bsearch()
  Local a$(array.new%(5)) = ("abc", "DEf", "gHi", "jkL", "MNO")

  assert_int_equals(BASE + 0, array.bsearch%(a$(), "abc", "i"))
  assert_int_equals(BASE + 1, array.bsearch%(a$(), "def", "i"))
  assert_int_equals(BASE + 2, array.bsearch%(a$(), "ghi", "i"))
  assert_int_equals(BASE + 3, array.bsearch%(a$(), "jkl", "i"))
  assert_int_equals(BASE + 4, array.bsearch%(a$(), "mno", "i"))
  assert_int_equals(-1,       array.bsearch%(a$(), "wombat"))

  Local lb% = BASE + 1
  assert_int_equals(-1,       array.bsearch%(a$(), "abc", "i", lb%))
  assert_int_equals(BASE + 1, array.bsearch%(a$(), "def", "i", lb%))
  assert_int_equals(BASE + 2, array.bsearch%(a$(), "ghi", "i", lb%))
  assert_int_equals(BASE + 3, array.bsearch%(a$(), "jkl", "i", lb%))
  assert_int_equals(BASE + 4, array.bsearch%(a$(), "mno", "i", lb%))

  lb% = BASE + 2
  assert_int_equals(-1,       array.bsearch%(a$(), "abc", "i", lb%))
  assert_int_equals(-1,       array.bsearch%(a$(), "def", "i", lb%))
  assert_int_equals(BASE + 2, array.bsearch%(a$(), "ghi", "i", lb%))
  assert_int_equals(BASE + 3, array.bsearch%(a$(), "jkl", "i", lb%))
  assert_int_equals(BASE + 4, array.bsearch%(a$(), "mno", "i", lb%))

  Local num% = 4
  lb% = BASE
  assert_int_equals(BASE + 0, array.bsearch%(a$(), "abc", "i", lb%, num%));
  assert_int_equals(BASE + 1, array.bsearch%(a$(), "def", "i", lb%, num%));
  assert_int_equals(BASE + 2, array.bsearch%(a$(), "ghi", "i", lb%, num%));
  assert_int_equals(BASE + 3, array.bsearch%(a$(), "jkl", "i", lb%, num%));
  assert_int_equals(-1,       array.bsearch%(a$(), "mno", "i", lb%, num%));

  num% = 3
  assert_int_equals(BASE + 0, array.bsearch%(a$(), "abc", "i", lb%, num%));
  assert_int_equals(BASE + 1, array.bsearch%(a$(), "def", "i", lb%, num%));
  assert_int_equals(BASE + 2, array.bsearch%(a$(), "ghi", "i", lb%, num%));
  assert_int_equals(-1,       array.bsearch%(a$(), "jkl", "i", lb%, num%));
  assert_int_equals(-1,       array.bsearch%(a$(), "mno", "i", lb%, num%));

  lb% = BASE + 1
  num% = 2
  assert_int_equals(-1,       array.bsearch%(a$(), "abc", "i", lb%, num%));
  assert_int_equals(BASE + 1, array.bsearch%(a$(), "def", "i", lb%, num%));
  assert_int_equals(BASE + 2, array.bsearch%(a$(), "ghi", "i", lb%, num%));
  assert_int_equals(-1,       array.bsearch%(a$(), "jkl", "i", lb%, num%));
  assert_int_equals(-1,       array.bsearch%(a$(), "mno", "i", lb%, num%));

  num% = 1
  assert_int_equals(-1,       array.bsearch%(a$(), "abc", "i", lb%, num%));
  assert_int_equals(BASE + 1, array.bsearch%(a$(), "def", "i", lb%, num%));
  assert_int_equals(-1,       array.bsearch%(a$(), "ghi", "i", lb%, num%));
  assert_int_equals(-1,       array.bsearch%(a$(), "jkl", "i", lb%, num%));
  assert_int_equals(-1,       array.bsearch%(a$(), "mno", "i", lb%, num%));
End Sub

Sub test_join_floats()
  Local a!(array.new%(5)) = (-7.35, 2.3456789, 0.0, -1.2345678, 9999.9999)

  ' Test default behaviour.
  assert_string_equals("-7.35,2.3456789,0,-1.2345678,9999.9999", array.join_floats$(a!()))

  ' Test 'delim%' parameter.
  assert_string_equals("-7.35,2.3456789,0,-1.2345678,9999.9999",     array.join_floats$(a!(), ""))
  assert_string_equals("-7.35, 2.3456789, 0, -1.2345678, 9999.9999", array.join_floats$(a!(), ", "))
  assert_string_equals("-7.35*2.3456789*0*-1.2345678*9999.9999",     array.join_floats$(a!(), "*"))

  ' Test 'lb%' parameter.
  assert_string_equals("-7.35,2.3456789,0,-1.2345678,9999.9999", array.join_floats$(a!(), , BASE + 0))
  assert_string_equals("2.3456789,0,-1.2345678,9999.9999",       array.join_floats$(a!(), , BASE + 1))
  assert_string_equals("0,-1.2345678,9999.9999",                 array.join_floats$(a!(), , BASE + 2))
  assert_string_equals("-1.2345678,9999.9999",                   array.join_floats$(a!(), , BASE + 3))
  assert_string_equals("9999.9999",                              array.join_floats$(a!(), , BASE + 4))

  ' Test 'num%' parameter.
  assert_string_equals("-7.35,2.3456789,0,-1.2345678,9999.9999", array.join_floats$(a!(), , , 0))
  assert_string_equals("-7.35",                                  array.join_floats$(a!(), , , 1))
  assert_string_equals("-7.35,2.3456789",                        array.join_floats$(a!(), , , 2))
  assert_string_equals("-7.35,2.3456789,0",                      array.join_floats$(a!(), , , 3))
  assert_string_equals("-7.35,2.3456789,0,-1.2345678",           array.join_floats$(a!(), , , 4))
  assert_string_equals("-7.35,2.3456789,0,-1.2345678,9999.9999", array.join_floats$(a!(), , , 5))

  ' Test 'slen%' parameter.
  assert_string_equals("...",                                    array.join_floats$(a!(), , , , 3))
  assert_string_equals("-7....",                                 array.join_floats$(a!(), , , , 6))
  assert_string_equals("-7.35,...",                              array.join_floats$(a!(), , , , 9))
  assert_string_equals("-7.35,2.3...",                           array.join_floats$(a!(), , , , 12))
  assert_string_equals("-7.35,2.3456...",                        array.join_floats$(a!(), , , , 15))
  assert_string_equals("-7.35,2.3456789,0...",                   array.join_floats$(a!(), , , , 20))
  assert_string_equals("-7.35,2.3456789,0,-1.2...",              array.join_floats$(a!(), , , , 25))
  assert_string_equals("-7.35,2.3456789,0,-1.2345678,999...",    array.join_floats$(a!(), , , , 35))

  ' Test it all together.
  assert_string_equals("2.3456789*0",      array.join_floats$(a!(), "*", BASE + 1, 2, 20))
  assert_string_equals("0*-1.2345678...",  array.join_floats$(a!(), "*", BASE + 2, 3, 15))
End Sub

Sub test_join_ints()
  Local a%(array.new%(5)) = (-735, 23456789, 0, -12345678, 99999999)

  ' Test default behaviour.
  assert_string_equals("-735,23456789,0,-12345678,99999999", array.join_ints$(a%()))

  ' Test 'delim%' parameter.
  assert_string_equals("-735,23456789,0,-12345678,99999999",     array.join_ints$(a%(), ""))
  assert_string_equals("-735, 23456789, 0, -12345678, 99999999", array.join_ints$(a%(), ", "))
  assert_string_equals("-735*23456789*0*-12345678*99999999",     array.join_ints$(a%(), "*"))

  ' Test 'lb%' parameter.
  assert_string_equals("-735,23456789,0,-12345678,99999999", array.join_ints$(a%(), , BASE + 0))
  assert_string_equals("23456789,0,-12345678,99999999",      array.join_ints$(a%(), , BASE + 1))
  assert_string_equals("0,-12345678,99999999",               array.join_ints$(a%(), , BASE + 2))
  assert_string_equals("-12345678,99999999",                 array.join_ints$(a%(), , BASE + 3))
  assert_string_equals("99999999",                           array.join_ints$(a%(), , BASE + 4))

  ' Test 'num%' parameter.
  assert_string_equals("-735,23456789,0,-12345678,99999999", array.join_ints$(a%(), , , 0))
  assert_string_equals("-735",                               array.join_ints$(a%(), , , 1))
  assert_string_equals("-735,23456789",                      array.join_ints$(a%(), , , 2))
  assert_string_equals("-735,23456789,0",                    array.join_ints$(a%(), , , 3))
  assert_string_equals("-735,23456789,0,-12345678",          array.join_ints$(a%(), , , 4))
  assert_string_equals("-735,23456789,0,-12345678,99999999", array.join_ints$(a%(), , , 5))

  ' Test 'slen%' parameter.
  assert_string_equals("...",                                array.join_ints$(a%(), , , , 3))
  assert_string_equals("-73...",                             array.join_ints$(a%(), , , , 6))
  assert_string_equals("-735,2...",                          array.join_ints$(a%(), , , , 9))
  assert_string_equals("-735,2345...",                       array.join_ints$(a%(), , , , 12))
  assert_string_equals("-735,2345678...",                    array.join_ints$(a%(), , , , 15))
  assert_string_equals("-735,23456789,0,-...",               array.join_ints$(a%(), , , , 20))
  assert_string_equals("-735,23456789,0,-12345...",          array.join_ints$(a%(), , , , 25))
  assert_string_equals("-735,23456789,0,-12345678,99999999", array.join_ints$(a%(), , , , 35))

  ' Test it all together.
  assert_string_equals("23456789*0",      array.join_ints$(a%(), "*", BASE + 1, 2, 20))
  assert_string_equals("0*-12345678*...", array.join_ints$(a%(), "*", BASE + 2, 3, 15))
End Sub

Sub test_join_strings()
  Local a$(array.new%(5)) = ("one", "two", "three", "four", "five")

  ' Test default behaviour.
  assert_string_equals("one,two,three,four,five", array.join_strings$(a$()))

  ' Test 'delim%' parameter.
  assert_string_equals("one,two,three,four,five",     array.join_strings$(a$(), ""))
  assert_string_equals("one, two, three, four, five", array.join_strings$(a$(), ", "))
  assert_string_equals("one*two*three*four*five",     array.join_strings$(a$(), "*"))

  ' Test 'lb%' parameter.
  assert_string_equals("one,two,three,four,five", array.join_strings$(a$(), , BASE + 0))
  assert_string_equals("two,three,four,five",     array.join_strings$(a$(), , BASE + 1))
  assert_string_equals("three,four,five",         array.join_strings$(a$(), , BASE + 2))
  assert_string_equals("four,five",               array.join_strings$(a$(), , BASE + 3))
  assert_string_equals("five",                    array.join_strings$(a$(), , BASE + 4))

  ' Test 'num%' parameter.
  assert_string_equals("one,two,three,four,five", array.join_strings$(a$(), , , 0))
  assert_string_equals("one",                     array.join_strings$(a$(), , , 1))
  assert_string_equals("one,two",                 array.join_strings$(a$(), , , 2))
  assert_string_equals("one,two,three",           array.join_strings$(a$(), , , 3))
  assert_string_equals("one,two,three,four",      array.join_strings$(a$(), , , 4))
  assert_string_equals("one,two,three,four,five", array.join_strings$(a$(), , , 5))

  ' Test 'slen%' parameter.
  assert_string_equals("...",                     array.join_strings$(a$(), , , , 3))
  assert_string_equals("o...",                    array.join_strings$(a$(), , , , 4))
  assert_string_equals("on...",                   array.join_strings$(a$(), , , , 5))
  assert_string_equals("one...",                  array.join_strings$(a$(), , , , 6))
  assert_string_equals("one,...",                 array.join_strings$(a$(), , , , 7))
  assert_string_equals("one,t...",                array.join_strings$(a$(), , , , 8))
  assert_string_equals("one,tw...",               array.join_strings$(a$(), , , , 9))
  assert_string_equals("one,two...",              array.join_strings$(a$(), , , , 10))
  assert_string_equals("one,two,...",             array.join_strings$(a$(), , , , 11))
  assert_string_equals("one,two,t...",            array.join_strings$(a$(), , , , 12))
  assert_string_equals("one,two,th...",           array.join_strings$(a$(), , , , 13))
  assert_string_equals("one,two,thr...",          array.join_strings$(a$(), , , , 14))
  assert_string_equals("one,two,thre...",         array.join_strings$(a$(), , , , 15))
  assert_string_equals("one,two,three...",        array.join_strings$(a$(), , , , 16))
  assert_string_equals("one,two,three,...",       array.join_strings$(a$(), , , , 17))
  assert_string_equals("one,two,three,f...",      array.join_strings$(a$(), , , , 18))
  assert_string_equals("one,two,three,fo...",     array.join_strings$(a$(), , , , 19))
  assert_string_equals("one,two,three,fou...",    array.join_strings$(a$(), , , , 20))
  assert_string_equals("one,two,three,four...",   array.join_strings$(a$(), , , , 21))
  assert_string_equals("one,two,three,four,...",  array.join_strings$(a$(), , , , 22))
  assert_string_equals("one,two,three,four,five", array.join_strings$(a$(), , , , 23))
  assert_string_equals("one,two,three,four,five", array.join_strings$(a$(), , , , 24))

  ' Test it all together.
  assert_string_equals("two*t...",  array.join_strings$(a$(), "*", BASE + 1, 2, 8))
  assert_string_equals("two*three", array.join_strings$(a$(), "*", BASE + 1, 2, 9))
End Sub

Sub test_qsort_ints_gvn_ordered()
  Local in%(array.new%(10)) = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
  Local expected%(array.new%(10)) = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

  assert_int_equals(sys.SUCCESS%, array.qsort_ints%(in%()))
  assert_int_array_equals(expected%(), in%())
End Sub

Sub test_qsort_ints_gvn_reversed()
  Local in%(array.new%(10)) = (10, 9, 8, 7, 6, 5, 4, 3, 2, 1)
  Local expected%(array.new%(10)) = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

  assert_int_equals(sys.SUCCESS%, array.qsort_ints%(in%()))
  assert_int_array_equals(expected%(), in%())
End Sub

Sub test_qsort_ints_gvn_identical()
  Local in%(array.new%(10)) = (5, 5, 5, 5, 5, 5, 5, 5, 5, 5)
  Local expected%(array.new%(10)) = (5, 5, 5, 5, 5, 5, 5, 5, 5, 5)

  assert_int_equals(sys.SUCCESS%, array.qsort_ints%(in%()))
  assert_int_array_equals(expected%(), in%())
End Sub

Sub test_qsort_ints_gvn_1_element()
  Local in%(array.new%(2)) = (2, 1)
  Local expected%(array.new%(2)) = (2, 1)

  ' Sort 1 element of a two element array.
  assert_int_equals(sys.SUCCESS%, array.qsort_ints%(in%(), BASE, 1))
  assert_int_array_equals(expected%(), in%())
End Sub

Sub test_qsort_ints_gvn_2_elements()
  Local in%(array.new%(2)) = (2, 1)
  Local expected%(array.new%(2)) = (1, 2)

  assert_int_equals(sys.SUCCESS%, array.qsort_ints%(in%()))
  assert_int_array_equals(expected%(), in%())
End Sub

Sub test_qsort_ints_gvn_comparator()
  Local in%(array.new%(10)) = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
  Local expected%(array.new%(10)) = (10, 9, 8, 7, 6, 5, 4, 3, 2, 1)

  assert_int_equals(sys.SUCCESS%, array.qsort_ints%(in%(), BASE, 10, "reverse_comparator%"))
  assert_int_array_equals(expected%(), in%())
End Sub

Function reverse_comparator%(a%, b%)
  reverse_comparator% = b% - a%
End Function

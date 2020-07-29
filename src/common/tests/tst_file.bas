:' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

Dim err$

#Include "../check.inc"
#Include "../file.inc"
#Include "../list.inc"
#Include "../set.inc"
#Include "../string.inc"
#Include "../../sptest/unittest.inc"

add_test("test_get_parent")
add_test("test_get_name")
add_test("test_get_canonical")
add_test("test_exists")
add_test("test_is_absolute")

run_tests()

End

Sub setup_test()
  err$ = ""
End Sub

Sub teardown_test()
End Sub

Function test_get_parent()
  assert_string_equals("", fi_get_parent$("foo.bas"))
  assert_string_equals("test", fi_get_parent$("test/foo.bas"))
  assert_string_equals("test", fi_get_parent$("test\foo.bas"))
  assert_string_equals("A:/test", fi_get_parent$("A:/test/foo.bas"))
  assert_string_equals("A:\test", fi_get_parent$("A:\test\foo.bas"))
  assert_string_equals("..", fi_get_parent$("../foo.bas"))
  assert_string_equals("..", fi_get_parent$("..\foo.bas"))
End Function

Function test_get_name()
  assert_string_equals("foo.bas", fi_get_name$("foo.bas"))
  assert_string_equals("foo.bas", fi_get_name$("test/foo.bas"))
  assert_string_equals("foo.bas", fi_get_name$("test\foo.bas"))
  assert_string_equals("foo.bas", fi_get_name$("A:/test/foo.bas"))
  assert_string_equals("foo.bas", fi_get_name$("A:\test\foo.bas"))
  assert_string_equals("foo.bas", fi_get_name$("../foo.bas"))
  assert_string_equals("foo.bas", fi_get_name$("..\foo.bas"))
End Function

Function test_get_canonical()
  Local base$ = Cwd$
  assert_string_equals(base$ + "/foo.bas", fi_get_canonical$("foo.bas"))
  assert_string_equals(base$ + "/dir/foo.bas", fi_get_canonical$("dir/foo.bas"))
  assert_string_equals(base$ + "/dir/foo.bas", fi_get_canonical$("dir\foo.bas"))
  assert_string_equals("A:/dir/foo.bas", fi_get_canonical$("A:/dir/foo.bas"))
  assert_string_equals("A:/dir/foo.bas", fi_get_canonical$("A:\dir\foo.bas"))
  assert_string_equals("A:/dir/foo.bas", fi_get_canonical$("a:/dir/foo.bas"))
  assert_string_equals("A:/dir/foo.bas", fi_get_canonical$("a:\dir\foo.bas"))
  assert_string_equals("A:/dir/foo.bas", fi_get_canonical$("/dir/foo.bas"))
  assert_string_equals("A:/dir/foo.bas", fi_get_canonical$("\dir\foo.bas"))
  assert_string_equals(base$ + "/foo.bas", fi_get_canonical$("dir/../foo.bas"))
  assert_string_equals(base$ + "/foo.bas", fi_get_canonical$("dir\..\foo.bas"))
  assert_string_equals(base$ + "/dir/foo.bas", fi_get_canonical$("dir/./foo.bas"))
  assert_string_equals(base$ + "/dir/foo.bas", fi_get_canonical$("dir\.\foo.bas"))
End Function

Function test_exists()
  Local f$ = Mm.Info$(Current)
  assert_equals(1, fi_exists(f$))
  assert_equals(1, fi_exists(fi_get_parent$(f$) + "/foo/../" + fi_get_name$(f$)))
  assert_equals(0, fi_exists(fi_get_parent$(f$) + "/foo/" + fi_get_name$(f$)))
End Function

Function test_is_absolute()
  assert_equals(0, fi_is_absolute("foo.bas"))
  assert_equals(0, fi_is_absolute("dir/foo.bas"))
  assert_equals(0, fi_is_absolute("dir\foo.bas"))
  assert_equals(1, fi_is_absolute("A:/dir/foo.bas"))
  assert_equals(1, fi_is_absolute("A:\dir\foo.bas"))
  assert_equals(1, fi_is_absolute("a:/dir/foo.bas"))
  assert_equals(1, fi_is_absolute("a:\dir\foo.bas"))
  assert_equals(1, fi_is_absolute("/dir/foo.bas"))
  assert_equals(1, fi_is_absolute("\dir\foo.bas"))
  assert_equals(0, fi_is_absolute("dir/../foo.bas"))
  assert_equals(0, fi_is_absolute("dir\..\foo.bas"))
  assert_equals(0, fi_is_absolute("dir/./foo.bas"))
  assert_equals(0, fi_is_absolute("dir\.\foo.bas"))
End Function

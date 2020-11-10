' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

If InStr(Mm.CmdLine$, "--base=1") Then
  Option Base 1
Else
  Option Base 0
EndIf

#Include "../error.inc"
#Include "../file.inc"
#Include "../list.inc"
#Include "../set.inc"
#Include "../strings.inc"
#Include "../../sptest/unittest.inc"

add_test("test_get_parent")
add_test("test_get_name")
add_test("test_get_canonical")
add_test("test_exists")
add_test("test_is_absolute")

run_tests()

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Function test_get_parent()
  assert_string_equals("", fil.get_parent$("foo.bas"))
  assert_string_equals("test", fil.get_parent$("test/foo.bas"))
  assert_string_equals("test", fil.get_parent$("test\foo.bas"))
  assert_string_equals("A:/test", fil.get_parent$("A:/test/foo.bas"))
  assert_string_equals("A:\test", fil.get_parent$("A:\test\foo.bas"))
  assert_string_equals("..", fil.get_parent$("../foo.bas"))
  assert_string_equals("..", fil.get_parent$("..\foo.bas"))
End Function

Function test_get_name()
  assert_string_equals("foo.bas", fil.get_name$("foo.bas"))
  assert_string_equals("foo.bas", fil.get_name$("test/foo.bas"))
  assert_string_equals("foo.bas", fil.get_name$("test\foo.bas"))
  assert_string_equals("foo.bas", fil.get_name$("A:/test/foo.bas"))
  assert_string_equals("foo.bas", fil.get_name$("A:\test\foo.bas"))
  assert_string_equals("foo.bas", fil.get_name$("../foo.bas"))
  assert_string_equals("foo.bas", fil.get_name$("..\foo.bas"))
End Function

Function test_get_canonical()
  Local base$ = Cwd$
  assert_string_equals(base$ + "/foo.bas", fil.get_canonical$("foo.bas"))
  assert_string_equals(base$ + "/dir/foo.bas", fil.get_canonical$("dir/foo.bas"))
  assert_string_equals(base$ + "/dir/foo.bas", fil.get_canonical$("dir\foo.bas"))
  assert_string_equals("A:/dir/foo.bas", fil.get_canonical$("A:/dir/foo.bas"))
  assert_string_equals("A:/dir/foo.bas", fil.get_canonical$("A:\dir\foo.bas"))
  assert_string_equals("A:/dir/foo.bas", fil.get_canonical$("a:/dir/foo.bas"))
  assert_string_equals("A:/dir/foo.bas", fil.get_canonical$("a:\dir\foo.bas"))
  assert_string_equals("A:/dir/foo.bas", fil.get_canonical$("/dir/foo.bas"))
  assert_string_equals("A:/dir/foo.bas", fil.get_canonical$("\dir\foo.bas"))
  assert_string_equals(base$ + "/foo.bas", fil.get_canonical$("dir/../foo.bas"))
  assert_string_equals(base$ + "/foo.bas", fil.get_canonical$("dir\..\foo.bas"))
  assert_string_equals(base$ + "/dir/foo.bas", fil.get_canonical$("dir/./foo.bas"))
  assert_string_equals(base$ + "/dir/foo.bas", fil.get_canonical$("dir\.\foo.bas"))
End Function

Function test_exists()
  Local f$ = Mm.Info$(Current)
  assert_equals(1, fil.exists%(f$))
  assert_equals(1, fil.exists%(fil.get_parent$(f$) + "/foo/../" + fil.get_name$(f$)))
  assert_equals(0, fil.exists%(fil.get_parent$(f$) + "/foo/" + fil.get_name$(f$)))
End Function

Function test_is_absolute()
  assert_equals(0, fil.is_absolute%("foo.bas"))
  assert_equals(0, fil.is_absolute%("dir/foo.bas"))
  assert_equals(0, fil.is_absolute%("dir\foo.bas"))
  assert_equals(1, fil.is_absolute%("A:/dir/foo.bas"))
  assert_equals(1, fil.is_absolute%("A:\dir\foo.bas"))
  assert_equals(1, fil.is_absolute%("a:/dir/foo.bas"))
  assert_equals(1, fil.is_absolute%("a:\dir\foo.bas"))
  assert_equals(1, fil.is_absolute%("/dir/foo.bas"))
  assert_equals(1, fil.is_absolute%("\dir\foo.bas"))
  assert_equals(0, fil.is_absolute%("dir/../foo.bas"))
  assert_equals(0, fil.is_absolute%("dir\..\foo.bas"))
  assert_equals(0, fil.is_absolute%("dir/./foo.bas"))
  assert_equals(0, fil.is_absolute%("dir\.\foo.bas"))
End Function

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

add_test("test_get_parent")
add_test("test_get_name")
add_test("test_get_canonical")
add_test("test_exists")
add_test("test_is_absolute")
add_test("test_is_directory")
add_test("test_fnmatch")
add_test("test_find_all")
add_test("test_find_files")
add_test("test_find_dirs")
add_test("test_find_all_matching")
add_test("test_find_files_matching")
add_test("test_find_dirs_matching")

If InStr(Mm.CmdLine$, "--base") Then run_tests() Else run_tests("--base=1")

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Sub test_get_parent()
  assert_string_equals("", fil.get_parent$("foo.bas"))
  assert_string_equals("test", fil.get_parent$("test/foo.bas"))
  assert_string_equals("test", fil.get_parent$("test\foo.bas"))
  assert_string_equals("A:/test", fil.get_parent$("A:/test/foo.bas"))
  assert_string_equals("A:\test", fil.get_parent$("A:\test\foo.bas"))
  assert_string_equals("..", fil.get_parent$("../foo.bas"))
  assert_string_equals("..", fil.get_parent$("..\foo.bas"))
End Sub

Sub test_get_name()
  assert_string_equals("foo.bas", fil.get_name$("foo.bas"))
  assert_string_equals("foo.bas", fil.get_name$("test/foo.bas"))
  assert_string_equals("foo.bas", fil.get_name$("test\foo.bas"))
  assert_string_equals("foo.bas", fil.get_name$("A:/test/foo.bas"))
  assert_string_equals("foo.bas", fil.get_name$("A:\test\foo.bas"))
  assert_string_equals("foo.bas", fil.get_name$("../foo.bas"))
  assert_string_equals("foo.bas", fil.get_name$("..\foo.bas"))
End Sub

Sub test_get_canonical()
  Local root$ = Mm.Info(Directory)
  assert_string_equals(root$ + "foo.bas", fil.get_canonical$("foo.bas"))
  assert_string_equals(root$ + "dir/foo.bas", fil.get_canonical$("dir/foo.bas"))
  assert_string_equals(root$ + "dir/foo.bas", fil.get_canonical$("dir\foo.bas"))
  assert_string_equals("A:/dir/foo.bas", fil.get_canonical$("A:/dir/foo.bas"))
  assert_string_equals("A:/dir/foo.bas", fil.get_canonical$("A:\dir\foo.bas"))
  assert_string_equals("A:/dir/foo.bas", fil.get_canonical$("a:/dir/foo.bas"))
  assert_string_equals("A:/dir/foo.bas", fil.get_canonical$("a:\dir\foo.bas"))
  assert_string_equals("A:/dir/foo.bas", fil.get_canonical$("/dir/foo.bas"))
  assert_string_equals("A:/dir/foo.bas", fil.get_canonical$("\dir\foo.bas"))
  assert_string_equals(root$ + "foo.bas", fil.get_canonical$("dir/../foo.bas"))
  assert_string_equals(root$ + "foo.bas", fil.get_canonical$("dir\..\foo.bas"))
  assert_string_equals(root$ + "dir/foo.bas", fil.get_canonical$("dir/./foo.bas"))
  assert_string_equals(root$ + "dir/foo.bas", fil.get_canonical$("dir\.\foo.bas"))
  assert_string_equals("A:", fil.get_canonical$("A:"))
  assert_string_equals("A:", fil.get_canonical$("A:/"))
  assert_string_equals("A:", fil.get_canonical$("A:\"))
  assert_string_equals("A:", fil.get_canonical$("/"))
  assert_string_equals("A:", fil.get_canonical$("\"))
End Sub

Sub test_exists()
  Local f$ = Mm.Info$(Current)

  assert_true(fil.exists%(f$))
  assert_true(fil.exists%(fil.get_parent$(f$) + "/foo/../" + fil.get_name$(f$)))
  assert_true(fil.exists%(FIL.PROG_DIR$))
  assert_true(fil.exists%("A:"))
  assert_true(fil.exists%("A:/"))
  assert_true(fil.exists%("A:\"))
  assert_true(fil.exists%("/"))
  assert_true(fil.exists%("\"))

  assert_false(fil.exists%(fil.get_parent$(f$) + "/foo/" + fil.get_name$(f$)))
End Sub

Sub test_is_absolute()
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

  assert_true(fil.is_absolute%("A:"))
  assert_true(fil.is_absolute%("A:/"))
  assert_true(fil.is_absolute%("A:\"))
  assert_true(fil.is_absolute%("/"))
  assert_true(fil.is_absolute%("\"))
End Sub

Sub test_is_directory()
  assert_true(fil.is_directory%(FIL.PROG_DIR$))
  assert_true(fil.is_directory%("A:"))
  assert_true(fil.is_directory%("A:/"))
  assert_true(fil.is_directory%("A:\"))
  assert_true(fil.is_directory%("/"))
  assert_true(fil.is_directory%("\"))

  assert_false(fil.is_directory%(Mm.Info$(Current)))
End Sub

Sub test_fnmatch()
  ' Matches.
  assert_true(fil.fnmatch%("foo",   "foo"))
  assert_true(fil.fnmatch%("foo",   "FOO"))
  assert_true(fil.fnmatch%("FOO",   "foo"))
  assert_true(fil.fnmatch%("fo?",   "foo"))
  assert_true(fil.fnmatch%("f??",   "foo"))
  assert_true(fil.fnmatch%("???",   "foo"))
  assert_true(fil.fnmatch%("?oo",   "foo"))
  assert_true(fil.fnmatch%("?o?",   "foo"))
  assert_true(fil.fnmatch%("*",     "foo.txt"))
  assert_true(fil.fnmatch%("*.txt", "foo.txt"))
  assert_true(fil.fnmatch%("f*.*",  "foo.txt"))
  assert_true(fil.fnmatch%("f?o.*", "foo.txt"))

  ' Non-matches.
  assert_false(fil.fnmatch%("foo",   "bar"))
  assert_false(fil.fnmatch%("foo?",  "foo"))
  assert_false(fil.fnmatch%("?foo",  "foo"))
  assert_false(fil.fnmatch%("?",     "foo"))
  assert_false(fil.fnmatch%("??",    "foo"))
  assert_false(fil.fnmatch%("????",  "foo"))
  assert_false(fil.fnmatch%("*.txt", "foo.bin"))
End Sub

Sub test_find_all()
  Local root$ = fil.get_canonical$(FIL.PROG_DIR$ + "/..")

  ' Search for all files and directories, filtering out ".bak" files.
  Local files$(array.new%(50)) Length 128
  list.init(files$())
  Local f$ = fil.find$(root$, "*", "all")
  Do While f$ <> ""
    If Right$(f$, 4) <> ".bak" Then list.push(files$(), f$)
    f$ = fil.find$()
  Loop
  Local i% = Mm.Info(Option Base)
  assert_string_equals(root$,                           files$(i%)) : Inc i%
  assert_string_equals(root$ + "/array.inc",            files$(i%)) : Inc i%
  assert_string_equals(root$ + "/file.inc",             files$(i%)) : Inc i%
  assert_string_equals(root$ + "/list.inc",             files$(i%)) : Inc i%
  assert_string_equals(root$ + "/map.inc",              files$(i%)) : Inc i%
  assert_string_equals(root$ + "/set.inc",              files$(i%)) : Inc i%
  assert_string_equals(root$ + "/sptools.inc",          files$(i%)) : Inc i%
  assert_string_equals(root$ + "/string.inc",           files$(i%)) : Inc i%
  assert_string_equals(root$ + "/system.inc",           files$(i%)) : Inc i%
  assert_string_equals(root$ + "/tests",                files$(i%)) : Inc i%
  assert_string_equals(root$ + "/tests/tst_array.bas",  files$(i%)) : Inc i%
  assert_string_equals(root$ + "/tests/tst_file.bas",   files$(i%)) : Inc i%
  assert_string_equals(root$ + "/tests/tst_list.bas",   files$(i%)) : Inc i%
  assert_string_equals(root$ + "/tests/tst_map.bas",    files$(i%)) : Inc i%
  assert_string_equals(root$ + "/tests/tst_set.bas",    files$(i%)) : Inc i%
  assert_string_equals(root$ + "/tests/tst_string.bas", files$(i%)) : Inc i%
  assert_string_equals(root$ + "/tests/tst_system.bas", files$(i%)) : Inc i%
  assert_string_equals(root$ + "/vt100.inc",            files$(i%)) : Inc i%
  assert_string_equals(list.NULL$,                      files$(i%))
End Sub

Sub test_find_files()
  Local root$ = fil.get_canonical$(FIL.PROG_DIR$ + "/..")

  ' Search for all files, filtering out ".bak" files.
  Local files$(array.new%(50)) Length 128
  list.init(files$())
  Local f$ = fil.find$(root$, "*", "file")
  Do While f$ <> ""
    If Right$(f$, 4) <> ".bak" Then list.push(files$(), f$)
    f$ = fil.find$()
  Loop
  Local i% = Mm.Info(Option Base)
  assert_string_equals(root$ + "/array.inc",            files$(i%)) : Inc i%
  assert_string_equals(root$ + "/file.inc",             files$(i%)) : Inc i%
  assert_string_equals(root$ + "/list.inc",             files$(i%)) : Inc i%
  assert_string_equals(root$ + "/map.inc",              files$(i%)) : Inc i%
  assert_string_equals(root$ + "/set.inc",              files$(i%)) : Inc i%
  assert_string_equals(root$ + "/sptools.inc",          files$(i%)) : Inc i%
  assert_string_equals(root$ + "/string.inc",           files$(i%)) : Inc i%
  assert_string_equals(root$ + "/system.inc",           files$(i%)) : Inc i%
  assert_string_equals(root$ + "/tests/tst_array.bas",  files$(i%)) : Inc i%
  assert_string_equals(root$ + "/tests/tst_file.bas",   files$(i%)) : Inc i%
  assert_string_equals(root$ + "/tests/tst_list.bas",   files$(i%)) : Inc i%
  assert_string_equals(root$ + "/tests/tst_map.bas",    files$(i%)) : Inc i%
  assert_string_equals(root$ + "/tests/tst_set.bas",    files$(i%)) : Inc i%
  assert_string_equals(root$ + "/tests/tst_string.bas", files$(i%)) : Inc i%
  assert_string_equals(root$ + "/tests/tst_system.bas", files$(i%)) : Inc i%
  assert_string_equals(root$ + "/vt100.inc",            files$(i%)) : Inc i%
  assert_string_equals(list.NULL$,                      files$(i%))
End Sub

Sub test_find_dirs()
  Local root$ = fil.get_canonical$(FIL.PROG_DIR$ + "/../..")
  assert_string_equals(root$,                    fil.find$(root$, "*", "dir"))
  assert_string_equals(root$ + "/common",        fil.find$())
  assert_string_equals(root$ + "/common/tests",  fil.find$())
  assert_string_equals(root$ + "/spfind",        fil.find$())
  assert_string_equals(root$ + "/spflow",        fil.find$())
  assert_string_equals(root$ + "/spflow/tests",  fil.find$())
  assert_string_equals(root$ + "/sptest",        fil.find$())
  assert_string_equals(root$ + "/sptrans",       fil.find$())
  assert_string_equals(root$ + "/sptrans/tests", fil.find$())
  assert_string_equals("",                       fil.find$())
End Sub

Sub test_find_all_matching()
  Local root$ = fil.get_canonical$(FIL.PROG_DIR$ + "/..")

  ' Search for all files and directories, filtering out ".bak" files.
  Local files$(array.new%(50)) Length 128
  list.init(files$())
  Local f$ = fil.find$(root$, "*e*", "all")
  Do While f$ <> ""
    If Right$(f$, 4) <> ".bak" Then list.push(files$(), f$)
    f$ = fil.find$()
  Loop
  Local i% = Mm.Info(Option Base)
  assert_string_equals(root$ + "/file.inc",              files$(i%)) : Inc i%
  assert_string_equals(root$ + "/set.inc",               files$(i%)) : Inc i%
  assert_string_equals(root$ + "/system.inc",            files$(i%)) : Inc i%
  assert_string_equals(root$ + "/tests",                 files$(i%)) : Inc i%
  assert_string_equals(root$ + "/tests/tst_file.bas",    files$(i%)) : Inc i%
  assert_string_equals(root$ + "/tests/tst_set.bas",     files$(i%)) : Inc i%
  assert_string_equals(root$ + "/tests/tst_system.bas",  files$(i%)) : Inc i%
  assert_string_equals(list.NULL$,                       files$(i%))
End Sub

Sub test_find_files_matching()
  Local root$ = fil.get_canonical$(FIL.PROG_DIR$ + "/..")

  assert_string_equals(root$ + "/tests/tst_array.bas",  fil.find$(root$, "*.bas", "file"))
  assert_string_equals(root$ + "/tests/tst_file.bas",   fil.find$())
  assert_string_equals(root$ + "/tests/tst_list.bas",   fil.find$())
  assert_string_equals(root$ + "/tests/tst_map.bas",    fil.find$())
  assert_string_equals(root$ + "/tests/tst_set.bas",    fil.find$())
  assert_string_equals(root$ + "/tests/tst_string.bas", fil.find$())
  assert_string_equals(root$ + "/tests/tst_system.bas", fil.find$())
  assert_string_equals("",                              fil.find$())
End Sub

Sub test_find_dirs_matching()
  Local root$ = fil.get_canonical$(FIL.PROG_DIR$ + "/../..")
  assert_string_equals(root$,                    fil.find$(root$, "s*", "dir"))
  assert_string_equals(root$ + "/spfind",        fil.find$())
  assert_string_equals(root$ + "/spflow",        fil.find$())
  assert_string_equals(root$ + "/sptest",        fil.find$())
  assert_string_equals(root$ + "/sptrans",       fil.find$())
  assert_string_equals("",                       fil.find$())
End Sub

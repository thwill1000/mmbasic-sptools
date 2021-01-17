' Copyright (c) 2020-2021 Thomas Hugo Williams
' For Colour Maximite 2, MMBasic 5.06

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

Const base% = Mm.Info(Option Base)

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
add_test("test_count_files")
add_test("test_get_extension")
add_test("test_get_files")
add_test("test_trim_extension")

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
  assert_true(fil.exists%(fil.PROG_DIR$))
  assert_true(fil.exists%("A:"))
  assert_true(fil.exists%("A:/"))
  assert_true(fil.exists%("A:\"))
  assert_true(fil.exists%("/"))
  assert_true(fil.exists%("\"))

  assert_false(fil.exists%(fil.get_parent$(f$) + "/foo/" + fil.get_name$(f$)))
End Sub

Sub test_is_absolute()
  assert_int_equals(0, fil.is_absolute%("foo.bas"))
  assert_int_equals(0, fil.is_absolute%("dir/foo.bas"))
  assert_int_equals(0, fil.is_absolute%("dir\foo.bas"))
  assert_int_equals(1, fil.is_absolute%("A:/dir/foo.bas"))
  assert_int_equals(1, fil.is_absolute%("A:\dir\foo.bas"))
  assert_int_equals(1, fil.is_absolute%("a:/dir/foo.bas"))
  assert_int_equals(1, fil.is_absolute%("a:\dir\foo.bas"))
  assert_int_equals(1, fil.is_absolute%("/dir/foo.bas"))
  assert_int_equals(1, fil.is_absolute%("\dir\foo.bas"))
  assert_int_equals(0, fil.is_absolute%("dir/../foo.bas"))
  assert_int_equals(0, fil.is_absolute%("dir\..\foo.bas"))
  assert_int_equals(0, fil.is_absolute%("dir/./foo.bas"))
  assert_int_equals(0, fil.is_absolute%("dir\.\foo.bas"))

  assert_true(fil.is_absolute%("A:"))
  assert_true(fil.is_absolute%("A:/"))
  assert_true(fil.is_absolute%("A:\"))
  assert_true(fil.is_absolute%("/"))
  assert_true(fil.is_absolute%("\"))
End Sub

Sub test_is_directory()
  assert_true(fil.is_directory%(fil.PROG_DIR$))
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
  Local root$ = fil.get_canonical$(fil.PROG_DIR$ + "/..")

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
  assert_string_equals(sys.NO_DATA$,                    files$(i%))
End Sub

Sub test_find_files()
  Local root$ = fil.get_canonical$(fil.PROG_DIR$ + "/..")

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
  assert_string_equals(sys.NO_DATA$,                    files$(i%))
End Sub

Sub test_find_dirs()
  Local root$ = fil.get_canonical$(fil.PROG_DIR$ + "/../..")
  assert_string_equals(root$,                    fil.find$(root$, "*", "dir"))
  assert_string_equals(root$ + "/spfind",        fil.find$())
  assert_string_equals(root$ + "/spflow",        fil.find$())
  assert_string_equals(root$ + "/spflow/tests",  fil.find$())
  assert_string_equals(root$ + "/splib",         fil.find$())
  assert_string_equals(root$ + "/splib/tests",   fil.find$())
  assert_string_equals(root$ + "/sptest",        fil.find$())
  assert_string_equals(root$ + "/sptrans",       fil.find$())
  assert_string_equals(root$ + "/sptrans/tests", fil.find$())
  assert_string_equals("",                       fil.find$())
End Sub

Sub test_find_all_matching()
  Local root$ = fil.get_canonical$(fil.PROG_DIR$ + "/..")

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
  assert_string_equals(sys.NO_DATA$,                     files$(i%))
End Sub

Sub test_find_files_matching()
  Local root$ = fil.get_canonical$(fil.PROG_DIR$ + "/..")

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
  Local root$ = fil.get_canonical$(fil.PROG_DIR$ + "/../..")
  assert_string_equals(root$,              fil.find$(root$, "s*", "dir"))
  assert_string_equals(root$ + "/spfind",  fil.find$())
  assert_string_equals(root$ + "/spflow",  fil.find$())
  assert_string_equals(root$ + "/splib",   fil.find$())
  assert_string_equals(root$ + "/sptest",  fil.find$())
  assert_string_equals(root$ + "/sptrans", fil.find$())
  assert_string_equals("",                 fil.find$())
End Sub

Sub test_count_files()
  Local root$ = fil.get_canonical$(fil.PROG_DIR$ + "/..")

  assert_int_equals(9, fil.count_files%(root$, "*.inc", "all"))
  assert_int_equals(7, fil.count_files%(fil.PROG_DIR$, "*.bas", "all"))
  assert_int_equals(0, fil.count_files%(root$, "*.foo", "all"))

  assert_int_equals(1, fil.count_files%(root$, "*", "dir"))
  assert_int_equals(0, fil.count_files%(root$, "*.inc", "dir"))
  assert_int_equals(0, fil.count_files%(fil.PROG_DIR$, "*.bas", "dir"))
  assert_int_equals(0, fil.count_files%(root$, "*.foo", "dir"))

  assert_int_equals(9, fil.count_files%(root$, "*.inc", "file"))
  assert_int_equals(7, fil.count_files%(fil.PROG_DIR$, "*.bas", "file"))
  assert_int_equals(0, fil.count_files%(root$, "*.foo", "file"))
End Sub

Sub test_get_extension()
  assert_string_equals(".dat", fil.get_extension$("foo.dat"))
  assert_string_equals("", fil.get_extension$(""))
  assert_string_equals("", fil.get_extension$("foo"))
  assert_string_equals(".dat", fil.get_extension$(".dat"))
  assert_string_equals(".dat", fil.get_extension$("f.dat"))
  assert_string_equals(".dat", fil.get_extension$("foo.bar.dat"))
  assert_string_equals(".dat", fil.get_extension$("bugaloo/foo.dat"))
  assert_string_equals("", fil.get_extension$("wom.bat/foo"))
  assert_string_equals("", fil.get_extension$("wom.bat\foo"))
  assert_string_equals(".dat", fil.get_extension$("wom.bat/foo.dat"))
  assert_string_equals(".dat", fil.get_extension$("wom.bat\foo.dat"))
  assert_string_equals("", fil.get_extension$("A:/foo"))
  assert_string_equals("", fil.get_extension$("A:\foo"))
  assert_string_equals(".dat", fil.get_extension$("A:/foo.dat"))
  assert_string_equals(".dat", fil.get_extension$("A:\foo.dat"))
  assert_string_equals("", fil.get_extension$("/foo"))
  assert_string_equals("", fil.get_extension$("\foo"))
  assert_string_equals(".dat", fil.get_extension$("/foo.dat"))
  assert_string_equals(".dat", fil.get_extension$("\foo.dat"))
  assert_string_equals(".longer", fil.get_extension$("foo.longer"))
  assert_string_equals(".", fil.get_extension$("foo."))
End Sub

Sub test_get_files()
  Local root$ = fil.get_canonical$(fil.PROG_DIR$ + "/..")
  Local actual$(array.new%(10)) Length 128
  Local expected$(array.new%(10)) Length 128

  ' Type = ALL

  array.fill(actual$(), "")
  fil.get_files(root$, "*.inc", "all", actual$())
  array.fill(expected$(), "")
  expected$(base% + 0) = "array.inc"
  expected$(base% + 1) = "file.inc"
  expected$(base% + 2) = "list.inc"
  expected$(base% + 3) = "map.inc"
  expected$(base% + 4) = "set.inc"
  expected$(base% + 5) = "sptools.inc"
  expected$(base% + 6) = "string.inc"
  expected$(base% + 7) = "system.inc"
  expected$(base% + 8) = "vt100.inc"
  assert_string_array_equals(expected$(), actual$())

  array.fill(actual$(), "")
  fil.get_files(fil.PROG_DIR$, "*.BAS", "ALL", actual$())
  array.fill(expected$(), "")
  expected$(base% + 0) = "tst_array.bas"
  expected$(base% + 1) = "tst_file.bas"
  expected$(base% + 2) = "tst_list.bas"
  expected$(base% + 3) = "tst_map.bas"
  expected$(base% + 4) = "tst_set.bas"
  expected$(base% + 5) = "tst_string.bas"
  expected$(base% + 6) = "tst_system.bas"
  assert_string_array_equals(expected$(), actual$())

  array.fill(actual$(), "")
  fil.get_files(root$, "*.foo", "ALL", actual$())
  array.fill(expected$(), "")
  assert_string_array_equals(expected$(), actual$())

  ' Type = DIR

  array.fill(actual$(), "")
  fil.get_files(root$, "*", "dir", actual$())
  array.fill(expected$(), "")
  expected$(base% + 0) = "tests"
  assert_string_array_equals(expected$(), actual$())

  array.fill(actual$(), "")
  fil.get_files(root$, "*.inc", "dir", actual$())
  array.fill(expected$(), "")
  assert_string_array_equals(expected$(), actual$())

  array.fill(actual$(), "")
  fil.get_files(fil.PROG_DIR$, "*.bas", "dir", actual$())
  array.fill(expected$(), "")
  assert_string_array_equals(expected$(), actual$())

  array.fill(actual$(), "")
  fil.get_files(root$, "*.foo", "dir", actual$())
  array.fill(expected$(), "")
  assert_string_array_equals(expected$(), actual$())

  ' Type = FILE

  array.fill(actual$(), "")
  fil.get_files(root$, "*.inc", "file", actual$())
  array.fill(expected$(), "")
  expected$(base% + 0) = "array.inc"
  expected$(base% + 1) = "file.inc"
  expected$(base% + 2) = "list.inc"
  expected$(base% + 3) = "map.inc"
  expected$(base% + 4) = "set.inc"
  expected$(base% + 5) = "sptools.inc"
  expected$(base% + 6) = "string.inc"
  expected$(base% + 7) = "system.inc"
  expected$(base% + 8) = "vt100.inc"
  assert_string_array_equals(expected$(), actual$())

  array.fill(actual$(), "")
  fil.get_files(fil.PROG_DIR$, "*.BAS", "FILE", actual$())
  array.fill(expected$(), "")
  expected$(base% + 0) = "tst_array.bas"
  expected$(base% + 1) = "tst_file.bas"
  expected$(base% + 2) = "tst_list.bas"
  expected$(base% + 3) = "tst_map.bas"
  expected$(base% + 4) = "tst_set.bas"
  expected$(base% + 5) = "tst_string.bas"
  expected$(base% + 6) = "tst_system.bas"
  assert_string_array_equals(expected$(), actual$())

  array.fill(actual$(), "")
  fil.get_files(root$, "*.foo", "FILE", actual$())
  array.fill(expected$(), "")
  assert_string_array_equals(expected$(), actual$())
End Sub

Sub test_trim_extension()
  assert_string_equals("foo",         fil.trim_extension$("foo.dat"))
  assert_string_equals("",            fil.trim_extension$(""))
  assert_string_equals("foo",         fil.trim_extension$("foo"))
  assert_string_equals("",            fil.trim_extension$(".dat"))
  assert_string_equals("f",           fil.trim_extension$("f.dat"))
  assert_string_equals("foo.bar",     fil.trim_extension$("foo.bar.dat"))
  assert_string_equals("bugaloo/foo", fil.trim_extension$("bugaloo/foo.dat"))
  assert_string_equals("wom.bat/foo", fil.trim_extension$("wom.bat/foo"))
  assert_string_equals("wom.bat\foo", fil.trim_extension$("wom.bat\foo"))
  assert_string_equals("wom.bat/foo", fil.trim_extension$("wom.bat/foo.dat"))
  assert_string_equals("wom.bat\foo", fil.trim_extension$("wom.bat\foo.dat"))
  assert_string_equals("A:/foo",      fil.trim_extension$("A:/foo"))
  assert_string_equals("A:\foo",      fil.trim_extension$("A:\foo"))
  assert_string_equals("A:/foo",      fil.trim_extension$("A:/foo.dat"))
  assert_string_equals("A:\foo",      fil.trim_extension$("A:\foo.dat"))
  assert_string_equals("/foo",        fil.trim_extension$("/foo"))
  assert_string_equals("\foo",        fil.trim_extension$("\foo"))
  assert_string_equals("/foo",        fil.trim_extension$("/foo.dat"))
  assert_string_equals("\foo",        fil.trim_extension$("\foo.dat"))
  assert_string_equals("foo",         fil.trim_extension$("foo.longer"))
  assert_string_equals("foo",         fil.trim_extension$("foo."))
End Sub

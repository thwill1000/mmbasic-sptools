' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07.03

Option Explicit On
Option Default None
' TODO: this is just a placeholder.
If InStr(Mm.Device$, "PicoMite") > 0 Then Dim Mm.CmdLine$ = ""
Option Base InStr(Mm.CmdLine$, "--base=1") > 0

#Include "../system.inc"
#Include "../array.inc"
#Include "../list.inc"
#Include "../string.inc"
#Include "../file.inc"
#Include "../vt100.inc"
#Include "../../sptest/unittest.inc"

Const BASE% = Mm.Info(Option Base)
Const RSRC$ = file.get_canonical$(file.PROG_DIR$ + "/resources/tst_file")
Const TMPDIR$ = sys.string_prop$("tmpdir") + "/tst_file"

add_test("test_get_parent")
add_test("test_get_name")
add_test("test_is_absolute")
add_test("test_is_symlink")
add_test("test_get_canonical")
add_test("test_exists")
add_test("test_is_directory")
add_test("test_fnmatch")
add_test("test_find_all")
add_test("test_find_files")
add_test("test_find_dirs")
add_test("test_find_all_matching")
add_test("test_find_files_matching")
add_test("test_find_dirs_matching")
add_test("test_find_does_not_follow_symlinks", "test_find_with_symlinks")
add_test("test_count_files")
add_test("test_count_files_not_found")
add_test("test_count_files_given_not_dir")
add_test("test_count_files_given_invalid")
add_test("test_get_extension")
add_test("test_get_files")
add_test("test_get_files_given_not_found")
add_test("test_get_files_given_not_dir")
add_test("test_get_files_given_invalid")
add_test("test_trim_extension")
add_test("test_mkdir_abs_path")
add_test("test_mkdir_rel_path")
add_test("test_depth_first_given_file")
add_test("test_depth_first_given_dir")
add_test("test_depth_first_given_symlink")
add_test("test_depth_first_given_not_found", "test_depth_first_not_found")
add_test("test_delete_root")
add_test("test_delete_given_not_found")
add_test("test_delete_given_file")
add_test("test_delete_given_dir")
add_test("test_delete_given_symlink")

If InStr(Mm.CmdLine$, "--base") Then run_tests() Else run_tests("--base=1")

End

Sub setup_test()
  If file.exists%(TMPDIR$) Then
    If file.delete%(TMPDIR$, 1) <> sys.SUCCESS Then Error "Failed to delete directory '" + TMPDIR$ + "'"
  EndIf
  MkDir TMPDIR$
End Sub

Sub teardown_test()
  If file.delete%(TMPDIR$, 1) <> sys.SUCCESS Then Error "Failed to delete directory '" + TMPDIR$ + "'"
End Sub

Sub test_get_parent()
  assert_string_equals("", file.get_parent$("foo.bas"))
  assert_string_equals("test", file.get_parent$("test/foo.bas"))
  assert_string_equals("test", file.get_parent$("test\foo.bas"))
  assert_string_equals("A:/test", file.get_parent$("A:/test/foo.bas"))
  assert_string_equals("A:\test", file.get_parent$("A:\test\foo.bas"))
  assert_string_equals("..", file.get_parent$("../foo.bas"))
  assert_string_equals("..", file.get_parent$("..\foo.bas"))
End Sub

Sub test_get_name()
  assert_string_equals("foo.bas", file.get_name$("foo.bas"))
  assert_string_equals("foo.bas", file.get_name$("test/foo.bas"))
  assert_string_equals("foo.bas", file.get_name$("test\foo.bas"))
  assert_string_equals("foo.bas", file.get_name$("A:/test/foo.bas"))
  assert_string_equals("foo.bas", file.get_name$("A:\test\foo.bas"))
  assert_string_equals("foo.bas", file.get_name$("../foo.bas"))
  assert_string_equals("foo.bas", file.get_name$("..\foo.bas"))
End Sub

Sub test_get_canonical()
  Local root$ = Left$(Mm.Info(Directory), Len(Mm.Info(Directory)) - 1)

  assert_string_equals("A:", file.get_canonical$("A:"))
  assert_string_equals("A:", file.get_canonical$("A:/"))
  assert_string_equals("A:", file.get_canonical$("A:\"))
  assert_string_equals("A:", file.get_canonical$("/"))
  assert_string_equals("A:", file.get_canonical$("\"))
  assert_string_equals("C:", file.get_canonical$("C:"))
  assert_string_equals("C:", file.get_canonical$("C:/"))
  assert_string_equals("C:", file.get_canonical$("C:\"))

  assert_string_equals(expected_path$(root$ + "/foo.bas"), file.get_canonical$("foo.bas"))
  assert_string_equals(expected_path$(root$ + "/dir/foo.bas"), file.get_canonical$("dir/foo.bas"))
  assert_string_equals(expected_path$(root$ + "/dir/foo.bas"), file.get_canonical$("dir\foo.bas"))
  assert_string_equals(expected_path$("A:/dir/foo.bas"), file.get_canonical$("A:/dir/foo.bas"))
  assert_string_equals(expected_path$("A:/dir/foo.bas"), file.get_canonical$("A:\dir\foo.bas"))
  assert_string_equals(expected_path$("A:/dir/foo.bas"), file.get_canonical$("a:/dir/foo.bas"))
  assert_string_equals(expected_path$("A:/dir/foo.bas"), file.get_canonical$("a:\dir\foo.bas"))
  assert_string_equals(expected_path$("A:/dir/foo.bas"), file.get_canonical$("/dir/foo.bas"))
  assert_string_equals(expected_path$("A:/dir/foo.bas"), file.get_canonical$("\dir\foo.bas"))
  assert_string_equals(expected_path$(root$ + "/foo.bas"), file.get_canonical$("dir/../foo.bas"))
  assert_string_equals(expected_path$(root$ + "/foo.bas"), file.get_canonical$("dir\..\foo.bas"))
  assert_string_equals(expected_path$(root$ + "/dir/foo.bas"), file.get_canonical$("dir/./foo.bas"))
  assert_string_equals(expected_path$(root$ + "/dir/foo.bas"), file.get_canonical$("dir\.\foo.bas"))

  ' Trailing .
  assert_string_equals("A:", file.get_canonical$("A:/."))
  assert_string_equals(expected_path$("A:/dir"), file.get_canonical$("A:/dir/."))
  assert_string_equals(expected_path$(root$), file.get_canonical$("."))

  ' Trailing ..
  assert_string_equals("A:", file.get_canonical$("A:/.."))
  assert_string_equals("A:", file.get_canonical$("A:/dir/.."))

  ' TODO: should the parent of "A:" be "" or should it be "A:" ?
  Local parent$ = file.get_parent$(root$)
  If parent$ = "" Then parent$ = "A:"
  assert_string_equals(expected_path$(parent$), file.get_canonical$(".."))

  ' Tilde expansion
  assert_string_equals(expected_path$(sys.string_prop$("home")), file.get_canonical$("~"))
  assert_string_equals(expected_path$(sys.string_prop$("home") + "/dir"), file.get_canonical$("~/dir"))
  assert_string_equals(expected_path$(sys.string_prop$("home") + "/dir"), file.get_canonical$("~\dir"))
End Sub

Function expected_path$(f$)
  expected_path$ = f$
  If Mm.Device$ = "MMBasic for Windows" Then
    ' Convert slash to backslash.
    Local i%
    For i% = 1 To Len(expected_path$)
      If Peek(Var expected_path$, i%) = 47 Then Poke Var expected_path$, i%, 92
    Next
  EndIf
End Function

Sub test_exists()
  Local f$ = Mm.Info$(Current)

  assert_true(file.exists%(f$))
  assert_true(file.exists%(file.get_parent$(f$) + "/foo/../" + file.get_name$(f$)))
  assert_true(file.exists%(file.PROG_DIR$))
  assert_false(file.exists%(file.get_parent$(f$) + "/foo/" + file.get_name$(f$)))

  ' Given A: drive.
  Local expected% = Mm.Device$ <> "MMBasic for Windows"
  assert_int_equals(expected%, file.exists%("A:"))
  assert_int_equals(expected%, file.exists%("A:/"))
  assert_int_equals(expected%, file.exists%("A:\"))

  ' Given C: drive.
  assert_int_equals(1, file.exists%("C:"))
  assert_int_equals(1, file.exists%("C:/"))
  assert_int_equals(1, file.exists%("C:\"))

  ' Given UNIX absolute paths.
  assert_true(file.exists%("/"))
  assert_true(file.exists%("/."))
  assert_true(file.exists%("\"))
  assert_true(file.exists%("\."))

  ' Given relative paths.
  assert_true(file.exists%("."))
  assert_true(file.exists%(".."))
End Sub

Sub test_is_absolute()
  assert_false(file.is_absolute%("foo.bas"))
  assert_false(file.is_absolute%("dir/foo.bas"))
  assert_false(file.is_absolute%("dir\foo.bas"))
  assert_true(file.is_absolute%("A:/dir/foo.bas"))
  assert_true(file.is_absolute%("A:\dir\foo.bas"))
  assert_true(file.is_absolute%("a:/dir/foo.bas"))
  assert_true(file.is_absolute%("a:\dir\foo.bas"))
  assert_true(file.is_absolute%("/dir/foo.bas"))
  assert_true(file.is_absolute%("\dir\foo.bas"))
  assert_false(file.is_absolute%("dir/../foo.bas"))
  assert_false(file.is_absolute%("dir\..\foo.bas"))
  assert_false(file.is_absolute%("dir/./foo.bas"))
  assert_false(file.is_absolute%("dir\.\foo.bas"))

  assert_true(file.is_absolute%("A:"))
  assert_true(file.is_absolute%("A:/"))
  assert_true(file.is_absolute%("A:\"))
  assert_true(file.is_absolute%("/"))
  assert_true(file.is_absolute%("/."))
  assert_true(file.is_absolute%("\"))
  assert_true(file.is_absolute%("\."))

  assert_false(file.is_absolute%("."))
  assert_false(file.is_absolute%(".."))
End Sub

Sub test_is_symlink()
  ' Test on directory.
  assert_false(file.is_symlink%(TMPDIR$))

  ' Test on actual file.
  Local filename$ = TMPDIR$ + "/test_is_symlink.txt"
  given_non_empty_file(filename$)
  assert_false(file.is_symlink%(filename$))

  ' Test on symbolic link to file.
  If Mm.Device$ <> "MMB4L" Then Exit Sub
  Local symlink$ = TMPDIR$ + "/test_is_symlink.lnk"
  If file.exists%(symlink$) Then Kill symlink$
  System("ln -s " + filename$ + " " + symlink$)
  assert_true(file.is_symlink%(symlink$))
  Kill symlink$
  Kill filename$

  assert_false(file.is_symlink%("/"))
  assert_false(file.is_symlink%("/."))
  assert_false(file.is_symlink%("\"))
  assert_false(file.is_symlink%("\."))
  assert_false(file.is_symlink%("."))
  assert_false(file.is_symlink%(".."))
End Sub

Sub given_non_empty_file(f$)
  If file.exists%(f$) Then Kill f$
  Open f$ For Output As #1
  Print #1, "Hello World"
  Close #1
End Sub

Sub test_is_directory()
  assert_true(file.is_directory%(file.PROG_DIR$))

  Select Case Mm.Device$
    Case "MMBasic for Windows" : Const has_a% = 0
    Case Else                  : Const has_a% = 1 ' MMB4L pretends to have an A: drive
  End Select
  assert_int_equals(has_a%, file.is_directory%("A:"))
  assert_int_equals(has_a%, file.is_directory%("A:/"))
  assert_int_equals(has_a%, file.is_directory%("A:\"))

  Const has_c% = 1 ' MMB4L pretends to have a C: drive
  assert_int_equals(has_c%, file.is_directory%("C:"))
  assert_int_equals(has_c%, file.is_directory%("C:/"))
  assert_int_equals(has_c%, file.is_directory%("C:\"))

  assert_true(file.is_directory%("/"))
  assert_true(file.is_directory%("/."))
  assert_true(file.is_directory%("\"))
  assert_true(file.is_directory%("\."))
  assert_true(file.is_directory%("."))
  assert_true(file.is_directory%(".."))

  assert_false(file.is_directory%(Mm.Info$(Current)))
End Sub

Sub test_fnmatch()
  ' Matches.
  assert_true(file.fnmatch%("foo",   "foo"))
  assert_true(file.fnmatch%("foo",   "FOO"))
  assert_true(file.fnmatch%("FOO",   "foo"))
  assert_true(file.fnmatch%("fo?",   "foo"))
  assert_true(file.fnmatch%("f??",   "foo"))
  assert_true(file.fnmatch%("???",   "foo"))
  assert_true(file.fnmatch%("?oo",   "foo"))
  assert_true(file.fnmatch%("?o?",   "foo"))
  assert_true(file.fnmatch%("*",     "foo.txt"))
  assert_true(file.fnmatch%("*.txt", "foo.txt"))
  assert_true(file.fnmatch%("f*.*",  "foo.txt"))
  assert_true(file.fnmatch%("f?o.*", "foo.txt"))

  ' Non-matches.
  assert_false(file.fnmatch%("foo",   "bar"))
  assert_false(file.fnmatch%("foo?",  "foo"))
  assert_false(file.fnmatch%("?foo",  "foo"))
  assert_false(file.fnmatch%("?",     "foo"))
  assert_false(file.fnmatch%("??",    "foo"))
  assert_false(file.fnmatch%("????",  "foo"))
  assert_false(file.fnmatch%("*.txt", "foo.bin"))
End Sub

Sub test_find_all()
  assert_string_equals(RSRC$,                                 file.find$(RSRC$, "*", "all"))
  assert_string_equals(RSRC$ + "/snafu-dir",                  file.find$())
  assert_string_equals(RSRC$ + "/snafu-dir/one.foo",          file.find$())
  assert_string_equals(RSRC$ + "/snafu-dir/subdir",           file.find$())
  assert_string_equals(RSRC$ + "/snafu-dir/subdir/five.foo",  file.find$())
  assert_string_equals(RSRC$ + "/snafu-dir/subdir/four.bar",  file.find$())
  assert_string_equals(RSRC$ + "/snafu-dir/three.bar",        file.find$())
  assert_string_equals(RSRC$ + "/snafu-dir/two.foo",          file.find$())
  assert_string_equals(RSRC$ + "/wombat-dir",                 file.find$())
  assert_string_equals(RSRC$ + "/wombat-dir/one.foo",         file.find$())
  assert_string_equals(RSRC$ + "/wombat-dir/subdir",          file.find$())
  assert_string_equals(RSRC$ + "/wombat-dir/subdir/five.foo", file.find$())
  assert_string_equals(RSRC$ + "/wombat-dir/subdir/four.bar", file.find$())
  assert_string_equals(RSRC$ + "/wombat-dir/three.bar",       file.find$())
  assert_string_equals(RSRC$ + "/wombat-dir/two.foo",         file.find$())
  assert_string_equals(RSRC$ + "/zzz.txt",                    file.find$())
  assert_string_equals("",                                    file.find$())
End Sub

Sub test_find_files()
  assert_string_equals(RSRC$ + "/snafu-dir/one.foo",          file.find$(RSRC$, "*", "file"))
  assert_string_equals(RSRC$ + "/snafu-dir/subdir/five.foo",  file.find$())
  assert_string_equals(RSRC$ + "/snafu-dir/subdir/four.bar",  file.find$())
  assert_string_equals(RSRC$ + "/snafu-dir/three.bar",        file.find$())
  assert_string_equals(RSRC$ + "/snafu-dir/two.foo",          file.find$())
  assert_string_equals(RSRC$ + "/wombat-dir/one.foo",         file.find$())
  assert_string_equals(RSRC$ + "/wombat-dir/subdir/five.foo", file.find$())
  assert_string_equals(RSRC$ + "/wombat-dir/subdir/four.bar", file.find$())
  assert_string_equals(RSRC$ + "/wombat-dir/three.bar",       file.find$())
  assert_string_equals(RSRC$ + "/wombat-dir/two.foo",         file.find$())
  assert_string_equals(RSRC$ + "/zzz.txt",                    file.find$())
  assert_string_equals("",                                    file.find$())
End Sub

Sub test_find_dirs()
  assert_string_equals(RSRC$,                        file.find$(RSRC$, "*", "dir"))
  assert_string_equals(RSRC$ + "/snafu-dir",         file.find$())
  assert_string_equals(RSRC$ + "/snafu-dir/subdir",  file.find$())
  assert_string_equals(RSRC$ + "/wombat-dir",        file.find$())
  assert_string_equals(RSRC$ + "/wombat-dir/subdir", file.find$())
  assert_string_equals("",                           file.find$())
End Sub

Sub test_find_all_matching()
  assert_string_equals(RSRC$,                                 file.find$(RSRC$, "*f*", "all"))
  assert_string_equals(RSRC$ + "/snafu-dir",                  file.find$())
  assert_string_equals(RSRC$ + "/snafu-dir/one.foo",          file.find$())
  assert_string_equals(RSRC$ + "/snafu-dir/subdir/five.foo",  file.find$())
  assert_string_equals(RSRC$ + "/snafu-dir/subdir/four.bar",  file.find$())
  assert_string_equals(RSRC$ + "/snafu-dir/two.foo",          file.find$())
  assert_string_equals(RSRC$ + "/wombat-dir/one.foo",         file.find$())
  assert_string_equals(RSRC$ + "/wombat-dir/subdir/five.foo", file.find$())
  assert_string_equals(RSRC$ + "/wombat-dir/subdir/four.bar", file.find$())
  assert_string_equals(RSRC$ + "/wombat-dir/two.foo",         file.find$())
  assert_string_equals("",                                    file.find$())
End Sub

Sub test_find_files_matching()
  assert_string_equals(RSRC$ + "/snafu-dir/one.foo",          file.find$(RSRC$, "*.foo", "file"))
  assert_string_equals(RSRC$ + "/snafu-dir/subdir/five.foo",  file.find$())
  assert_string_equals(RSRC$ + "/snafu-dir/two.foo",          file.find$())
  assert_string_equals(RSRC$ + "/wombat-dir/one.foo",         file.find$())
  assert_string_equals(RSRC$ + "/wombat-dir/subdir/five.foo", file.find$())
  assert_string_equals(RSRC$ + "/wombat-dir/two.foo",         file.find$())
  assert_string_equals("",                                    file.find$())
End Sub

Sub test_find_dirs_matching()
  assert_string_equals(RSRC$ + "/snafu-dir/subdir",  file.find$(RSRC$, "*ub*", "dir"))
  assert_string_equals(RSRC$ + "/wombat-dir/subdir", file.find$())
  assert_string_equals("",                           file.find$())
End Sub

Sub test_find_with_symlinks()
  If Mm.Device$ <> "MMB4L" Then Exit Sub

  ' Setup.
  Local foo_dir$ = TMPDIR$ + "/foo"
  MkDir foo_dir$
  given_non_empty_file(TMPDIR$ + "/foo/one.txt")
  given_non_empty_file(TMPDIR$ + "/foo/two.txt")
  MkDir TMPDIR$ + "/bar"
  given_non_empty_file(TMPDIR$ + "/bar/one.txt")
  given_non_empty_file(TMPDIR$ + "/bar/two.txt")
  Local symlink$ = TMPDIR$ + "/foo.lnk"
  If file.exists%(symlink$) Then Kill symlink$
  System("ln -s " + foo_dir$ + " " + symlink$)

  ' Test.
  assert_string_equals("A:" + TMPDIR$ + "/bar/one.txt", file.find$(TMPDIR$, "*.txt", "all"))
  assert_string_equals("A:" + TMPDIR$ + "/bar/two.txt", file.find$())
  assert_string_equals("A:" + TMPDIR$ + "/foo/one.txt", file.find$())
  assert_string_equals("A:" + TMPDIR$ + "/foo/two.txt", file.find$())
  assert_string_equals("",                              file.find$())
End Sub

Sub test_count_files()
  assert_int_equals(3, file.count_files%(RSRC$, "*", "all"))
  assert_int_equals(1, file.count_files%(RSRC$, "*fu*", "all"))
  assert_int_equals(4, file.count_files%(RSRC$ + "/snafu-dir", "*", "all"))
  assert_int_equals(2, file.count_files%(RSRC$ + "/snafu-dir", "*.foo", "all"))
  assert_int_equals(1, file.count_files%(RSRC$ + "/snafu-dir", "*.bar", "all"))
  assert_int_equals(2, file.count_files%(RSRC$ + "/snafu-dir", "*r", "all"))

  assert_int_equals(1, file.count_files%(RSRC$, "*", "file"))
  assert_int_equals(0, file.count_files%(RSRC$, "*fu*", "file"))
  assert_int_equals(3, file.count_files%(RSRC$ + "/snafu-dir", "*", "file"))
  assert_int_equals(2, file.count_files%(RSRC$ + "/snafu-dir", "*.foo", "file"))
  assert_int_equals(1, file.count_files%(RSRC$ + "/snafu-dir", "*.bar", "file"))
  assert_int_equals(1, file.count_files%(RSRC$ + "/snafu-dir", "*r", "file"))

  assert_int_equals(2, file.count_files%(RSRC$, "*", "dir"))
  assert_int_equals(1, file.count_files%(RSRC$, "*fu*", "dir"))
  assert_int_equals(1, file.count_files%(RSRC$ + "/snafu-dir", "*", "dir"))
  assert_int_equals(0, file.count_files%(RSRC$ + "/snafu-dir", "*.foo", "dir"))
  assert_int_equals(0, file.count_files%(RSRC$ + "/snafu-dir", "*.bar", "dir"))
  assert_int_equals(1, file.count_files%(RSRC$ + "/snafu-dir", "*r", "dir"))
End Sub

Sub test_count_files_not_found()
  Local f$ = TMPDIR$ + "/not_found"

  assert_int_equals(sys.FAILURE, file.count_files%(f$))
  assert_error("Not a directory '" + f$ + "'")
End Sub

Sub test_count_files_given_not_dir()
  Local f$ = TMPDIR$ + "/not_dir"
  ut.create_file(f$)

  assert_int_equals(sys.FAILURE, file.count_files%(f$))
  assert_error("Not a directory '" + f$ + "'")
End Sub

Sub test_count_files_given_invalid()
  assert_int_equals(sys.FAILURE, file.count_files%(TMPDIR$, "*", "wombat"))
  assert_error("Invalid file type 'wombat'")
End Sub

Sub test_get_extension()
  assert_string_equals(".dat", file.get_extension$("foo.dat"))
  assert_string_equals("", file.get_extension$(""))
  assert_string_equals("", file.get_extension$("foo"))
  assert_string_equals(".dat", file.get_extension$(".dat"))
  assert_string_equals(".dat", file.get_extension$("f.dat"))
  assert_string_equals(".dat", file.get_extension$("foo.bar.dat"))
  assert_string_equals(".dat", file.get_extension$("bugaloo/foo.dat"))
  assert_string_equals("", file.get_extension$("wom.bat/foo"))
  assert_string_equals("", file.get_extension$("wom.bat\foo"))
  assert_string_equals(".dat", file.get_extension$("wom.bat/foo.dat"))
  assert_string_equals(".dat", file.get_extension$("wom.bat\foo.dat"))
  assert_string_equals("", file.get_extension$("A:/foo"))
  assert_string_equals("", file.get_extension$("A:\foo"))
  assert_string_equals(".dat", file.get_extension$("A:/foo.dat"))
  assert_string_equals(".dat", file.get_extension$("A:\foo.dat"))
  assert_string_equals("", file.get_extension$("/foo"))
  assert_string_equals("", file.get_extension$("\foo"))
  assert_string_equals(".dat", file.get_extension$("/foo.dat"))
  assert_string_equals(".dat", file.get_extension$("\foo.dat"))
  assert_string_equals(".longer", file.get_extension$("foo.longer"))
  assert_string_equals(".", file.get_extension$("foo."))
End Sub

Sub test_get_files()
  Local actual$(array.new%(10)) Length 128
  Local expected$(array.new%(10)) Length 128

  ' Type = ALL

  array.fill(actual$(), "")
  assert_int_equals(2, file.get_files%(RSRC$ + "/snafu-dir", "*r*", "all", actual$())))
  array.fill(expected$(), "")
  expected$(BASE% + 0) = "subdir"
  expected$(BASE% + 1) = "three.bar"
  assert_string_array_equals(expected$(), actual$())

  array.fill(actual$(), "")
  assert_int_equals(2, file.get_files%(RSRC$ + "/snafu-dir", "*R*", "ALL", actual$()))
  array.fill(expected$(), "")
  expected$(BASE% + 0) = "subdir"
  expected$(BASE% + 1) = "three.bar"
  assert_string_array_equals(expected$(), actual$())

  array.fill(actual$(), "")
  assert_int_equals(0, file.get_files%(RSRC$ + "/snafu-dir", "*xyz*", "ALL", actual$()))
  array.fill(expected$(), "")
  assert_string_array_equals(expected$(), actual$())

  ' Type = DIR

  array.fill(actual$(), "")
  assert_int_equals(2, file.get_files%(RSRC$, "*", "dir", actual$()))
  array.fill(expected$(), "")
  expected$(BASE% + 0) = "snafu-dir"
  expected$(BASE% + 1) = "wombat-dir"
  assert_string_array_equals(expected$(), actual$())

  array.fill(actual$(), "")
  assert_int_equals(1, file.get_files%(RSRC$, "*fu*", "dir", actual$()))
  array.fill(expected$(), "")
  expected$(BASE% + 0) = "snafu-dir"
  assert_string_array_equals(expected$(), actual$())

  array.fill(actual$(), "")
  assert_int_equals(0, file.get_files%(RSRC$, "*.foo", "dir", actual$()))
  array.fill(expected$(), "")
  assert_string_array_equals(expected$(), actual$())

  array.fill(actual$(), "")
  assert_int_equals(1, file.get_files%(RSRC$ + "/snafu-dir", "*r*", "dir", actual$()))
  array.fill(expected$(), "")
  expected$(BASE% + 0) = "subdir"
  assert_string_array_equals(expected$(), actual$())

  array.fill(actual$(), "")
  assert_int_equals(1, file.get_files%(RSRC$ + "/snafu-dir", "*R*", "DIR", actual$()))
  array.fill(expected$(), "")
  expected$(BASE% + 0) = "subdir"
  assert_string_array_equals(expected$(), actual$())

  array.fill(actual$(), "")
  assert_int_equals(1, file.get_files%(RSRC$ + "/snafu-dir", "subdir", "DIR", actual$()))
  array.fill(expected$(), "")
  expected$(BASE% + 0) = "subdir"
  assert_string_array_equals(expected$(), actual$())

  ' Type = FILE

  array.fill(actual$(), "")
  assert_int_equals(1, file.get_files%(RSRC$ + "/snafu-dir", "*r*", "file", actual$()))
  array.fill(expected$(), "")
  expected$(BASE% + 0) = "three.bar"
  assert_string_array_equals(expected$(), actual$())

  array.fill(actual$(), "")
  assert_int_equals(1, file.get_files%(RSRC$ + "/snafu-dir", "*R*", "FILE", actual$()))
  array.fill(expected$(), "")
  expected$(BASE% + 0) = "three.bar"
  assert_string_array_equals(expected$(), actual$())

  array.fill(actual$(), "")
  assert_int_equals(0, file.get_files%(RSRC$ + "/snafu-dir", "subdir", "FILE", actual$()))
  array.fill(expected$(), "")
  assert_string_array_equals(expected$(), actual$())
End Sub

Sub test_get_files_given_not_found()
  Local actual$(array.new%(10)) Length 128
  Local f$ = TMPDIR$ + "/not_found"

  assert_int_equals(sys.FAILURE, file.get_files%(f$, "*", "all", actual$()))
  assert_error("Not a directory '" + f$ + "'")
End Sub

Sub test_get_files_given_not_dir()
  Local actual$(array.new%(10)) Length 128
  Local f$ = TMPDIR$ + "/not_dir"
  ut.create_file(f$)

  assert_int_equals(sys.FAILURE, file.get_files%(f$, "*", "all", actual$()))
  assert_error("Not a directory '" + f$ + "'")
End Sub

Sub test_get_files_given_invalid()
  Local actual$(array.new%(10)) Length 128

  assert_int_equals(sys.FAILURE, file.get_files%(TMPDIR$, "*", "wombat", actual$()))
  assert_error("Invalid file type 'wombat'")
End Sub

Sub test_trim_extension()
  assert_string_equals("foo",         file.trim_extension$("foo.dat"))
  assert_string_equals("",            file.trim_extension$(""))
  assert_string_equals("foo",         file.trim_extension$("foo"))
  assert_string_equals("",            file.trim_extension$(".dat"))
  assert_string_equals("f",           file.trim_extension$("f.dat"))
  assert_string_equals("foo.bar",     file.trim_extension$("foo.bar.dat"))
  assert_string_equals("bugaloo/foo", file.trim_extension$("bugaloo/foo.dat"))
  assert_string_equals("wom.bat/foo", file.trim_extension$("wom.bat/foo"))
  assert_string_equals("wom.bat\foo", file.trim_extension$("wom.bat\foo"))
  assert_string_equals("wom.bat/foo", file.trim_extension$("wom.bat/foo.dat"))
  assert_string_equals("wom.bat\foo", file.trim_extension$("wom.bat\foo.dat"))
  assert_string_equals("A:/foo",      file.trim_extension$("A:/foo"))
  assert_string_equals("A:\foo",      file.trim_extension$("A:\foo"))
  assert_string_equals("A:/foo",      file.trim_extension$("A:/foo.dat"))
  assert_string_equals("A:\foo",      file.trim_extension$("A:\foo.dat"))
  assert_string_equals("/foo",        file.trim_extension$("/foo"))
  assert_string_equals("\foo",        file.trim_extension$("\foo"))
  assert_string_equals("/foo",        file.trim_extension$("/foo.dat"))
  assert_string_equals("\foo",        file.trim_extension$("\foo.dat"))
  assert_string_equals("foo",         file.trim_extension$("foo.longer"))
  assert_string_equals("foo",         file.trim_extension$("foo."))
End Sub

Sub test_mkdir_abs_path()
  ' Given parent exists.
  assert_int_equals(sys.SUCCESS, file.mkdir%(TMPDIR$ + "/foo"))
  assert_no_error()
  assert_true(file.is_directory%(TMPDIR$ + "/foo"))

  ' Given parent does not exist.
  assert_int_equals(sys.SUCCESS, file.mkdir%(TMPDIR$ + "/foo/a/b"))
  assert_no_error()
  assert_true(file.is_directory%(TMPDIR$ + "/foo/a/b"))

  ' Given exists and is a directory.
  assert_int_equals(sys.SUCCESS, file.mkdir%(TMPDIR$ + "/foo"))
  assert_no_error()
  assert_true(file.is_directory%(TMPDIR$ + "/foo"))

  ' Given exists and is a file.
  ut.create_file(TMPDIR$ + "/foo/file")
  assert_int_equals(sys.FAILURE, file.mkdir%(TMPDIR$ + "/foo/file"))
  assert_error("File exists")
  assert_false(file.is_directory%(TMPDIR$ + "/foo/file"))

  ' Given parent exists and is a file.
  assert_int_equals(sys.FAILURE, file.mkdir%(TMPDIR$ + "/foo/file/a"))
  assert_error("File exists")
  assert_false(file.is_directory%(TMPDIR$ + "/foo/file/a"))

  ' Given root directory.
  assert_int_equals(sys.SUCCESS, file.mkdir%("C:/"))
  assert_no_error()
  assert_int_equals(sys.SUCCESS, file.mkdir%("C:\"))
  assert_no_error()
  assert_int_equals(sys.SUCCESS, file.mkdir%("C:"))
  assert_no_error()
  If Mm.Device$ <> "MMBasic for Windows" Then
    assert_int_equals(sys.SUCCESS, file.mkdir%("/"))
    assert_no_error()
    assert_int_equals(sys.SUCCESS, file.mkdir%("\"))
    assert_no_error()
  EndIf
End Sub

Sub test_mkdir_rel_path()
  assert_int_equals(sys.SUCCESS, file.mkdir%(TMPDIR$ + "/foo"))
  Local old_cwd$ = Cwd$
  ChDir TMPDIR$ + "/foo"

  ' Given parent exists.
  assert_int_equals(sys.SUCCESS, file.mkdir%("./subdir"))
  assert_no_error()
  assert_true(file.is_directory%(TMPDIR$ + "/foo/subdir"))

  ' Given parent does not exist.
  assert_int_equals(sys.SUCCESS, file.mkdir%("a/b"))
  assert_no_error()
  assert_true(file.is_directory%(TMPDIR$ + "/foo/a/b"))

  ' Given exists and is a directory.
  assert_int_equals(sys.SUCCESS, file.mkdir%("a"))
  assert_no_error()
  assert_true(file.is_directory%(TMPDIR$ + "/foo/a"))

  ' Given exists and is a file.
  ut.create_file("file")
  assert_int_equals(sys.FAILURE, file.mkdir%(TMPDIR$ + "/foo/file"))
  assert_error("File exists")
  assert_false(file.is_directory%("file"))

  ' Given parent exists and is a file.
  assert_int_equals(sys.FAILURE, file.mkdir%("file/a"))
  assert_error("File exists")
  assert_false(file.is_directory%(TMPDIR$ + "/foo/file/a"))

  ' Cleanup.
  ChDir old_cwd$
End Sub

Sub test_depth_first_given_file()
  Local f$ = TMPDIR$ + "/foo"
  ut.create_file(f$)

  Local expected$(list.new%(10))
  list.init(expected$())
  list.add(expected$(), file.get_canonical$(f$) + "_5")

  Dim actual$(list.new%(10))
  list.init(actual$())
  assert_int_equals(sys.SUCCESS, file.depth_first%(f$, "depth_first_callback%", 5))
  assert_string_array_equals(expected$(), actual$())

  Erase actual$()
End Sub

Function depth_first_callback%(f$, xtra%)
  list.add(actual$(), f$ + "_" + Str$(xtra%))
End Function

Sub test_depth_first_given_dir()
  ut.create_file(TMPDIR$ + "/foo")
  MkDir TMPDIR$ + "/bar-dir"
  ut.create_file(TMPDIR$ + "/bar-dir/wombat")
  ut.create_file(TMPDIR$ + "/zzz")

  ' The order of files at the same level may be a bit variable.
  ' The important thing is that the contents of a directory is visited before
  ' the directory itself is.
  Local expected$(list.new%(10))
  list.init(expected$())
  If sys.is_device%("mmb4l-armv6l") Then
    list.add(expected$(), file.get_canonical$(TMPDIR$ + "/zzz_5"))
    list.add(expected$(), file.get_canonical$(TMPDIR$ + "/foo_5"))
  Else
    list.add(expected$(), file.get_canonical$(TMPDIR$ + "/foo_5"))
    list.add(expected$(), file.get_canonical$(TMPDIR$ + "/zzz_5"))
  EndIf
  list.add(expected$(), file.get_canonical$(TMPDIR$ + "/bar-dir/wombat_5"))
  list.add(expected$(), file.get_canonical$(TMPDIR$ + "/bar-dir_5"))
  list.add(expected$(), file.get_canonical$(TMPDIR$ + "_5"))

  Dim actual$(list.new%(10))
  list.init(actual$())
  assert_int_equals(sys.SUCCESS, file.depth_first%(TMPDIR$, "depth_first_callback%", 5))
  assert_string_array_equals(expected$(), actual$())

  Erase actual$()
End Sub

Sub test_depth_first_given_symlink()
  If Mm.Device$ <> "MMB4L" Then Exit Sub

  MkDir TMPDIR$ + "/foo-dir"
  ut.create_file(TMPDIR$ + "/foo-dir/bar")
  System "ln -s " + TMPDIR$ + "/foo-dir " + TMPDIR$ + "/foo-link"

  ' Should not recurse into target of symbolic link.
  Local expected$(list.new%(10))
  list.init(expected$())
  list.add(expected$(), file.get_canonical$(TMPDIR$ + "/foo-link_5"))

  Dim actual$(list.new%(10))
  list.init(actual$())
  assert_int_equals(sys.SUCCESS, file.depth_first%(TMPDIR$ + "/foo-link", "depth_first_callback%", 5))
  assert_string_array_equals(expected$(), actual$())

  Erase actual$()
End Sub

Sub test_depth_first_not_found()
  Local f$ = TMPDIR$ + "/foo"
  assert_int_equals(sys.FAILURE, file.depth_first%(f$, "depth_first_callback%", 5))
  assert_error("No such file or directory '" + file.get_canonical$(f$) + "'")
End Sub

Sub test_delete_root()
  Local roots$(array.new%(8)) = ("/", "\", "A:", "B:", "A:\", "A:/", "B:\", "B:/")
  Local i%

  For i% = Bound(roots$(), 0) To Bound(roots$(), 1)
    sys.err$ = ""
    assert_int_equals(sys.FAILURE, file.delete%(roots$(i%)))
    assert_error("Cannot delete '" + file.get_canonical$(roots$(i%)) + "'")
  Next
End Sub

Sub test_delete_given_not_found()
  Local f$ = TMPDIR$ + "/foo"

  assert_int_equals(sys.FAILURE, file.delete%(f$, 1))
  assert_error("No such file or directory '" + file.get_canonical$(f$) + "'")
End Sub

Sub test_delete_given_file()
  Local f$ = TMPDIR$ + "/foo"
  ut.create_file(f$)

  assert_true(file.exists%(f$))
  assert_int_equals(sys.SUCCESS, file.delete%(f$, 1))
  assert_false(file.exists%(f$))
End Sub

Sub test_delete_given_dir()
  Local f$ = TMPDIR$ + "/foo-dir"
  MkDir f$
  ut.create_file(f$ + "/one")
  ut.create_file(f$ + "/two")
  ut.create_file(TMPDIR$ + "/bar")

  assert_true(file.exists%(f$))
  assert_true(file.exists%(f$ + "/one"))
  assert_true(file.exists%(f$ + "/two"))
  assert_true(file.exists%(TMPDIR$ + "/bar"))
  assert_int_equals(sys.SUCCESS, file.delete%(f$, 1))
  assert_false(file.exists%(f$))
  assert_false(file.exists%(f$ + "/one"))
  assert_false(file.exists%(f$ + "/two"))
  assert_true(file.exists%(TMPDIR$ + "/bar"))
End Sub

Sub test_delete_given_symlink()
  If Mm.Device$ <> "MMB4L" Then Exit Sub

  MkDir TMPDIR$ + "/foo-dir"
  ut.create_file(TMPDIR$ + "/foo-dir/bar")
  System "ln -s " + TMPDIR$ + "/foo-dir " + TMPDIR$ + "/foo-link"

  assert_true(file.exists%(TMPDIR$ + "/foo-link"))
  assert_int_equals(sys.SUCCESS, file.delete%(TMPDIR$ + "/foo-link", 1))
  assert_false(file.exists%(TMPDIR$ + "/foo-link"))

  ' Should not recurse and delete into target of symbolic link.
  assert_true(file.exists%(TMPDIR$ + "/foo-dir"))
  assert_true(file.exists%(TMPDIR$ + "/foo-dir/bar"))
End Sub

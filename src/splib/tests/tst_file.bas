' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

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

Const BASE% = Mm.Info(Option Base)

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
add_test("test_get_files_given_too_many")
add_test("test_trim_extension")
add_test("test_mkdir_abs_path")
add_test("test_mkdir_rel_path")
add_test("test_mkdir_skips_path_len")
add_test("test_depth_first_given_file")
add_test("test_depth_first_given_dir")
add_test("test_depth_first_given_symlink")
add_test("test_depth_first_given_not_found", "test_depth_first_not_found")
add_test("test_delete_root")
add_test("test_delete_given_not_found")
add_test("test_delete_given_file")
add_test("test_delete_given_dir")
add_test("test_delete_given_symlink")
add_test("test_delete_given_too_many")
add_test("test_delete_given_unlimited")

' On the PicoMite the tests should run 4 times:
'   Base 0, Drive A
'   Base 1, Drive A
'   Base 0, Drive B
'   Base 1, Drive B
If sys.is_platform%("pm*") Then
  If InStr(Mm.CmdLine$, "--base=1 --drive=b") Then
    run_tests()
  ElseIf InStr(Mm.CmdLine$, "--base=1") Then
    run_tests("--base=1", "--drive=b")
  ElseIf InStr(Mm.CmdLine$, "--drive=b") Then
    run_tests("--drive=b", "--base=1 --drive=b")
  Else
    run_tests("--base=1")
  EndIf
ElseIf InStr(Mm.CmdLine$, "--base=1") Then
  run_tests("")
Else
  run_tests("--base=1")
EndIf

End

Sub test_get_parent()
  assert_string_equals("", file.get_parent$("foo.bas"))
  assert_string_equals("test", file.get_parent$("test/foo.bas"))
  assert_string_equals("test", file.get_parent$("test\foo.bas"))
  assert_string_equals("A:/test", file.get_parent$("A:/test/foo.bas"))
  assert_string_equals("A:\test", file.get_parent$("A:\test\foo.bas"))
  assert_string_equals("A:", file.get_parent$("A:/test"))
  assert_string_equals("A:", file.get_parent$("A:\test"))
  assert_string_equals("\", file.get_parent$("\test"))
  assert_string_equals("/", file.get_parent$("/test"))
  assert_string_equals("..", file.get_parent$("../foo.bas"))
  assert_string_equals("..", file.get_parent$("..\foo.bas"))
  assert_string_equals("", file.get_parent$("/"))
  assert_string_equals("", file.get_parent$("\"))
  assert_string_equals("", file.get_parent$("A:/"))
  assert_string_equals("", file.get_parent$("A:"))
  assert_string_equals("", file.get_parent$("A:\"))
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
  Local current$ = Cwd$
  If InStr("/\", Right$(current$, 1)) Then current$ = Left$(current$, Len(current$) - 1)

  assert_string_equals("A:", file.get_canonical$("/"))
  assert_string_equals("A:", file.get_canonical$("\"))
  assert_string_equals("A:", file.get_canonical$("A:"))
  assert_string_equals("A:", file.get_canonical$("A:/"))
  assert_string_equals("A:", file.get_canonical$("A:\"))
  assert_string_equals("B:", file.get_canonical$("B:"))
  assert_string_equals("B:", file.get_canonical$("B:/"))
  assert_string_equals("B:", file.get_canonical$("B:\"))
  assert_string_equals("C:", file.get_canonical$("C:"))
  assert_string_equals("C:", file.get_canonical$("C:/"))
  assert_string_equals("C:", file.get_canonical$("C:\"))

  assert_string_equals(expected_path$(current$ + "/foo.bas"), file.get_canonical$("foo.bas"))
  assert_string_equals(expected_path$(current$ + "/dir/foo.bas"), file.get_canonical$("dir/foo.bas"))
  assert_string_equals(expected_path$(current$ + "/dir/foo.bas"), file.get_canonical$("dir\foo.bas"))
  assert_string_equals(expected_path$("A:/dir/foo.bas"), file.get_canonical$("A:/dir/foo.bas"))
  assert_string_equals(expected_path$("A:/dir/foo.bas"), file.get_canonical$("A:\dir\foo.bas"))
  assert_string_equals(expected_path$("A:/dir/foo.bas"), file.get_canonical$("a:/dir/foo.bas"))
  assert_string_equals(expected_path$("A:/dir/foo.bas"), file.get_canonical$("a:\dir\foo.bas"))
  assert_string_equals(expected_path$("A:/dir/foo.bas"), file.get_canonical$("/dir/foo.bas"))
  assert_string_equals(expected_path$("A:/dir/foo.bas"), file.get_canonical$("\dir\foo.bas"))
  assert_string_equals(expected_path$(current$ + "/foo.bas"), file.get_canonical$("dir/../foo.bas"))
  assert_string_equals(expected_path$(current$ + "/foo.bas"), file.get_canonical$("dir\..\foo.bas"))
  assert_string_equals(expected_path$(current$ + "/dir/foo.bas"), file.get_canonical$("dir/./foo.bas"))
  assert_string_equals(expected_path$(current$ + "/dir/foo.bas"), file.get_canonical$("dir\.\foo.bas"))

  ' Trailing .
  assert_string_equals("A:", file.get_canonical$("A:/."))
  assert_string_equals(expected_path$("A:/dir"), file.get_canonical$("A:/dir/."))
  assert_string_equals(expected_path$(current$), file.get_canonical$("."))

  ' Trailing ..
  assert_string_equals("A:", file.get_canonical$("A:/.."))
  assert_string_equals("A:", file.get_canonical$("A:/dir/.."))

  ' TODO: should the parent of "A:" be "" or should it be "A:" ?
  Local parent$ = file.get_parent$(current$)
  If parent$ = "" Then parent$ = Choice(Not sys.is_platform%("pm*"), "A:", Mm.Info$(Drive))
  assert_string_equals(expected_path$(parent$), file.get_canonical$(".."))

  ' Tilde expansion
  assert_string_equals(expected_path$(sys.HOME$()), file.get_canonical$("~"))
  assert_string_equals(expected_path$(sys.HOME$() + "/dir"), file.get_canonical$("~/dir"))
  assert_string_equals(expected_path$(sys.HOME$() + "/dir"), file.get_canonical$("~\dir"))
End Sub

Function expected_path$(f$)
  expected_path$ = str.replace$(f$, "/", file.SEPARATOR)
End Function

Sub test_exists()
  Local f$ = Mm.Info$(Current)
  assert_true(file.exists%(f$))
  assert_true(file.exists%(Mm.Info$(Path)))
  assert_true(file.exists%(file.get_parent$(f$)))
  assert_true(file.exists%(file.get_parent$(f$) + "/foo/../" + file.get_name$(f$)))
  assert_false(file.exists%(file.get_parent$(f$) + "/foo/" + file.get_name$(f$)))

  ' Given A: drive.
  Local expected% = Not sys.is_platform%("mmb4w")
  assert_int_equals(expected%, file.exists%("A:"))
  assert_int_equals(expected%, file.exists%("A:/"))
  assert_int_equals(expected%, file.exists%("A:\"))

  ' Given C: drive.
  If Not sys.is_platform%("pm*") Then
    assert_int_equals(1, file.exists%("C:"))
    assert_int_equals(1, file.exists%("C:/"))
    assert_int_equals(1, file.exists%("C:\"))
  EndIf

  ' Given UNIX absolute paths.
  assert_true(file.exists%("/"))
  assert_true(file.exists%("/."))
  assert_true(file.exists%("\"))
  assert_true(file.exists%("\."))

  ' Given relative paths.
  assert_true(file.exists%(""))
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

  assert_true(file.is_absolute%("/"))
  assert_true(file.is_absolute%("/."))
  assert_true(file.is_absolute%("\"))
  assert_true(file.is_absolute%("\."))
  assert_true(file.is_absolute%("A:"))
  assert_true(file.is_absolute%("A:/"))
  assert_true(file.is_absolute%("A:\"))
  assert_true(file.is_absolute%("B:"))
  assert_true(file.is_absolute%("B:/"))
  assert_true(file.is_absolute%("B:\"))
  assert_true(file.is_absolute%("C:"))
  assert_true(file.is_absolute%("C:/"))
  assert_true(file.is_absolute%("C:\"))

  assert_false(file.is_absolute%("."))
  assert_false(file.is_absolute%(".."))
End Sub

Sub test_is_symlink()
  MkDir TMPDIR$

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
  assert_true(file.is_directory%(Mm.Info$(Path)))

  Const has_a% = Choice(sys.is_platform%("mmb4w"), 0, 1)
  assert_int_equals(has_a%, file.is_directory%("A:"))
  assert_int_equals(has_a%, file.is_directory%("A:/"))
  assert_int_equals(has_a%, file.is_directory%("A:\"))

  Const has_b% = Choice(sys.is_platform%("mmb4w"), 0, 1)
  assert_int_equals(has_b%, file.is_directory%("A:"))
  assert_int_equals(has_b%, file.is_directory%("A:/"))
  assert_int_equals(has_b%, file.is_directory%("A:\"))

  If Not sys.is_platform%("pm*") Then
    Const has_c% = 1
    assert_int_equals(has_c%, file.is_directory%("C:"))
    assert_int_equals(has_c%, file.is_directory%("C:/"))
    assert_int_equals(has_c%, file.is_directory%("C:\"))
  EndIf

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
  If sys.is_platform%("pm*") Then Exit Sub
  given_file_tree()

  Const CANON$ = file.get_canonical$(TMPDIR$)
  assert_string_equals(CANON$,                                 file.find$(TMPDIR$, "*", "all"))
  assert_string_equals(CANON$ + "/snafu-dir",                  file.find$())
  assert_string_equals(CANON$ + "/snafu-dir/one.foo",          file.find$())
  assert_string_equals(CANON$ + "/snafu-dir/subdir",           file.find$())
  assert_string_equals(CANON$ + "/snafu-dir/subdir/five.foo",  file.find$())
  assert_string_equals(CANON$ + "/snafu-dir/subdir/four.bar",  file.find$())
  assert_string_equals(CANON$ + "/snafu-dir/three.bar",        file.find$())
  assert_string_equals(CANON$ + "/snafu-dir/two.foo",          file.find$())
  assert_string_equals(CANON$ + "/wombat-dir",                 file.find$())
  assert_string_equals(CANON$ + "/wombat-dir/one.foo",         file.find$())
  assert_string_equals(CANON$ + "/wombat-dir/subdir",          file.find$())
  assert_string_equals(CANON$ + "/wombat-dir/subdir/five.foo", file.find$())
  assert_string_equals(CANON$ + "/wombat-dir/subdir/four.bar", file.find$())
  assert_string_equals(CANON$ + "/wombat-dir/three.bar",       file.find$())
  assert_string_equals(CANON$ + "/wombat-dir/two.foo",         file.find$())
  assert_string_equals(CANON$ + "/zzz.txt",                    file.find$())
  assert_string_equals("",                                     file.find$())
End Sub

Sub given_file_tree()
  MkDir TMPDIR$
  MkDir TMPDIR$ + "/snafu-dir"
  MkDir TMPDIR$ + "/snafu-dir/subdir"
  MkDir TMPDIR$ + "/wombat-dir"
  MkDir TMPDIR$ + "/wombat-dir/subdir"
  ut.create_file(TMPDIR$ + "/snafu-dir/one.foo")
  ut.create_file(TMPDIR$ + "/snafu-dir/two.foo")
  ut.create_file(TMPDIR$ + "/snafu-dir/three.bar")
  ut.create_file(TMPDIR$ + "/snafu-dir/subdir/four.bar")
  ut.create_file(TMPDIR$ + "/snafu-dir/subdir/five.foo")
  ut.create_file(TMPDIR$ + "/wombat-dir/one.foo")
  ut.create_file(TMPDIR$ + "/wombat-dir/two.foo")
  ut.create_file(TMPDIR$ + "/wombat-dir/three.bar")
  ut.create_file(TMPDIR$ + "/wombat-dir/subdir/four.bar")
  ut.create_file(TMPDIR$ + "/wombat-dir/subdir/five.foo")
  ut.create_file(TMPDIR$ + "/zzz.txt")
End Sub

Sub test_find_files()
  If sys.is_platform%("pm*") Then Exit Sub
  given_file_tree()

  Const CANON$ = file.get_canonical$(TMPDIR$)
  assert_string_equals(CANON$ + "/snafu-dir/one.foo",          file.find$(TMPDIR$, "*", "file"))
  assert_string_equals(CANON$ + "/snafu-dir/subdir/five.foo",  file.find$())
  assert_string_equals(CANON$ + "/snafu-dir/subdir/four.bar",  file.find$())
  assert_string_equals(CANON$ + "/snafu-dir/three.bar",        file.find$())
  assert_string_equals(CANON$ + "/snafu-dir/two.foo",          file.find$())
  assert_string_equals(CANON$ + "/wombat-dir/one.foo",         file.find$())
  assert_string_equals(CANON$ + "/wombat-dir/subdir/five.foo", file.find$())
  assert_string_equals(CANON$ + "/wombat-dir/subdir/four.bar", file.find$())
  assert_string_equals(CANON$ + "/wombat-dir/three.bar",       file.find$())
  assert_string_equals(CANON$ + "/wombat-dir/two.foo",         file.find$())
  assert_string_equals(CANON$ + "/zzz.txt",                    file.find$())
  assert_string_equals("",                                     file.find$())
End Sub

Sub test_find_dirs()
  If sys.is_platform%("pm*") Then Exit Sub
  given_file_tree()

  Const CANON$ = file.get_canonical$(TMPDIR$)
  assert_string_equals(CANON$,                        file.find$(TMPDIR$, "*", "dir"))
  assert_string_equals(CANON$ + "/snafu-dir",         file.find$())
  assert_string_equals(CANON$ + "/snafu-dir/subdir",  file.find$())
  assert_string_equals(CANON$ + "/wombat-dir",        file.find$())
  assert_string_equals(CANON$ + "/wombat-dir/subdir", file.find$())
  assert_string_equals("",                            file.find$())
End Sub

Sub test_find_all_matching()
  If sys.is_platform%("pm*") Then Exit Sub
  given_file_tree()

  Const CANON$ = file.get_canonical$(TMPDIR$)
  assert_string_equals(CANON$,                                 file.find$(TMPDIR$, "*f*", "all"))
  assert_string_equals(CANON$ + "/snafu-dir",                  file.find$())
  assert_string_equals(CANON$ + "/snafu-dir/one.foo",          file.find$())
  assert_string_equals(CANON$ + "/snafu-dir/subdir/five.foo",  file.find$())
  assert_string_equals(CANON$ + "/snafu-dir/subdir/four.bar",  file.find$())
  assert_string_equals(CANON$ + "/snafu-dir/two.foo",          file.find$())
  assert_string_equals(CANON$ + "/wombat-dir/one.foo",         file.find$())
  assert_string_equals(CANON$ + "/wombat-dir/subdir/five.foo", file.find$())
  assert_string_equals(CANON$ + "/wombat-dir/subdir/four.bar", file.find$())
  assert_string_equals(CANON$ + "/wombat-dir/two.foo",         file.find$())
  assert_string_equals("",                                     file.find$())
End Sub

Sub test_find_files_matching()
  If sys.is_platform%("pm*") Then Exit Sub
  given_file_tree()

  Const CANON$ = file.get_canonical$(TMPDIR$)
  assert_string_equals(CANON$ + "/snafu-dir/one.foo",          file.find$(TMPDIR$, "*.foo", "file"))
  assert_string_equals(CANON$ + "/snafu-dir/subdir/five.foo",  file.find$())
  assert_string_equals(CANON$ + "/snafu-dir/two.foo",          file.find$())
  assert_string_equals(CANON$ + "/wombat-dir/one.foo",         file.find$())
  assert_string_equals(CANON$ + "/wombat-dir/subdir/five.foo", file.find$())
  assert_string_equals(CANON$ + "/wombat-dir/two.foo",         file.find$())
  assert_string_equals("",                                     file.find$())
End Sub

Sub test_find_dirs_matching()
  If sys.is_platform%("pm*") Then Exit Sub
  given_file_tree()

  Const CANON$ = file.get_canonical$(TMPDIR$)
  assert_string_equals(CANON$ + "/snafu-dir/subdir",  file.find$(TMPDIR$, "*ub*", "dir"))
  assert_string_equals(CANON$ + "/wombat-dir/subdir", file.find$())
  assert_string_equals("",                            file.find$())
End Sub

Sub test_find_with_symlinks()
  If Not sys.is_platform%("mmb4l") Then Exit Sub

  ' Setup.
  MkDir TMPDIR$
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
  given_file_tree()

  assert_int_equals(3, file.count_files%(TMPDIR$, "*", "all"))
  assert_int_equals(1, file.count_files%(TMPDIR$, "*fu*", "all"))
  assert_int_equals(4, file.count_files%(TMPDIR$ + "/snafu-dir", "*", "all"))
  assert_int_equals(2, file.count_files%(TMPDIR$ + "/snafu-dir", "*.foo", "all"))
  assert_int_equals(1, file.count_files%(TMPDIR$ + "/snafu-dir", "*.bar", "all"))
  assert_int_equals(2, file.count_files%(TMPDIR$ + "/snafu-dir", "*r", "all"))

  assert_int_equals(1, file.count_files%(TMPDIR$, "*", "file"))
  assert_int_equals(0, file.count_files%(TMPDIR$, "*fu*", "file"))
  assert_int_equals(3, file.count_files%(TMPDIR$ + "/snafu-dir", "*", "file"))
  assert_int_equals(2, file.count_files%(TMPDIR$ + "/snafu-dir", "*.foo", "file"))
  assert_int_equals(1, file.count_files%(TMPDIR$ + "/snafu-dir", "*.bar", "file"))
  assert_int_equals(1, file.count_files%(TMPDIR$ + "/snafu-dir", "*r", "file"))

  assert_int_equals(2, file.count_files%(TMPDIR$, "*", "dir"))
  assert_int_equals(1, file.count_files%(TMPDIR$, "*fu*", "dir"))
  assert_int_equals(1, file.count_files%(TMPDIR$ + "/snafu-dir", "*", "dir"))
  assert_int_equals(0, file.count_files%(TMPDIR$ + "/snafu-dir", "*.foo", "dir"))
  assert_int_equals(0, file.count_files%(TMPDIR$ + "/snafu-dir", "*.bar", "dir"))
  assert_int_equals(1, file.count_files%(TMPDIR$ + "/snafu-dir", "*r", "dir"))
End Sub

Sub test_count_files_not_found()
  given_file_tree()
  Local f$ = TMPDIR$ + "/not_found"

  assert_int_equals(sys.FAILURE, file.count_files%(f$))
  assert_error("Not a directory '" + f$ + "'")
End Sub

Sub test_count_files_given_not_dir()
  given_file_tree()
  Local f$ = TMPDIR$ + "/not_dir"
  ut.create_file(f$)

  assert_int_equals(sys.FAILURE, file.count_files%(f$))
  assert_error("Not a directory '" + f$ + "'")
End Sub

Sub test_count_files_given_invalid()
  given_file_tree()
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
  given_file_tree()
  Local actual$(array.new%(10)) Length 128
  Local expected$(array.new%(10)) Length 128

  ' Type = ALL

  array.fill(actual$(), "")
  assert_int_equals(2, file.get_files%(TMPDIR$ + "/snafu-dir", "*r*", "all", actual$())))
  array.fill(expected$(), "")
  expected$(BASE% + 0) = "subdir"
  expected$(BASE% + 1) = "three.bar"
  assert_string_array_equals(expected$(), actual$())

  array.fill(actual$(), "")
  assert_int_equals(2, file.get_files%(TMPDIR$ + "/snafu-dir", "*R*", "ALL", actual$()))
  array.fill(expected$(), "")
  expected$(BASE% + 0) = "subdir"
  expected$(BASE% + 1) = "three.bar"
  assert_string_array_equals(expected$(), actual$())

  array.fill(actual$(), "")
  assert_int_equals(0, file.get_files%(TMPDIR$ + "/snafu-dir", "*xyz*", "ALL", actual$()))
  array.fill(expected$(), "")
  assert_string_array_equals(expected$(), actual$())

  ' Type = DIR

  array.fill(actual$(), "")
  assert_int_equals(2, file.get_files%(TMPDIR$, "*", "dir", actual$()))
  array.fill(expected$(), "")
  expected$(BASE% + 0) = "snafu-dir"
  expected$(BASE% + 1) = "wombat-dir"
  assert_string_array_equals(expected$(), actual$())

  array.fill(actual$(), "")
  assert_int_equals(1, file.get_files%(TMPDIR$, "*fu*", "dir", actual$()))
  array.fill(expected$(), "")
  expected$(BASE% + 0) = "snafu-dir"
  assert_string_array_equals(expected$(), actual$())

  array.fill(actual$(), "")
  assert_int_equals(0, file.get_files%(TMPDIR$, "*.foo", "dir", actual$()))
  array.fill(expected$(), "")
  assert_string_array_equals(expected$(), actual$())

  array.fill(actual$(), "")
  assert_int_equals(1, file.get_files%(TMPDIR$ + "/snafu-dir", "*r*", "dir", actual$()))
  array.fill(expected$(), "")
  expected$(BASE% + 0) = "subdir"
  assert_string_array_equals(expected$(), actual$())

  array.fill(actual$(), "")
  assert_int_equals(1, file.get_files%(TMPDIR$ + "/snafu-dir", "*R*", "DIR", actual$()))
  array.fill(expected$(), "")
  expected$(BASE% + 0) = "subdir"
  assert_string_array_equals(expected$(), actual$())

  array.fill(actual$(), "")
  assert_int_equals(1, file.get_files%(TMPDIR$ + "/snafu-dir", "subdir", "DIR", actual$()))
  array.fill(expected$(), "")
  expected$(BASE% + 0) = "subdir"
  assert_string_array_equals(expected$(), actual$())

  ' Type = FILE

  array.fill(actual$(), "")
  assert_int_equals(1, file.get_files%(TMPDIR$ + "/snafu-dir", "*r*", "file", actual$()))
  array.fill(expected$(), "")
  expected$(BASE% + 0) = "three.bar"
  assert_string_array_equals(expected$(), actual$())

  array.fill(actual$(), "")
  assert_int_equals(1, file.get_files%(TMPDIR$ + "/snafu-dir", "*R*", "FILE", actual$()))
  array.fill(expected$(), "")
  expected$(BASE% + 0) = "three.bar"
  assert_string_array_equals(expected$(), actual$())

  array.fill(actual$(), "")
  assert_int_equals(0, file.get_files%(TMPDIR$ + "/snafu-dir", "subdir", "FILE", actual$()))
  array.fill(expected$(), "")
  assert_string_array_equals(expected$(), actual$())
End Sub

Sub test_get_files_given_not_found()
  given_file_tree()
  Local actual$(array.new%(10)) Length 128
  Local f$ = TMPDIR$ + "/not_found"

  assert_int_equals(sys.FAILURE, file.get_files%(f$, "*", "all", actual$()))
  assert_error("Not a directory '" + f$ + "'")
End Sub

Sub test_get_files_given_not_dir()
  given_file_tree()
  Local actual$(array.new%(10)) Length 128
  Local f$ = TMPDIR$ + "/not_dir"
  ut.create_file(f$)

  assert_int_equals(sys.FAILURE, file.get_files%(f$, "*", "all", actual$()))
  assert_error("Not a directory '" + f$ + "'")
End Sub

Sub test_get_files_given_invalid()
  given_file_tree()
  Local actual$(array.new%(10)) Length 128

  assert_int_equals(sys.FAILURE, file.get_files%(TMPDIR$, "*", "wombat", actual$()))
  assert_error("Invalid file type 'wombat'")
End Sub

Sub test_get_files_given_too_many()
  given_file_tree()
  Local actual$(array.new%(2)) Length 128

  assert_int_equals(4, file.get_files%(TMPDIR$ + "/wombat-dir", "*", "all", actual$()))

  ' Which 2 of the 4 files is present is system dependent.
  Local all_files$(array.new%(4)) Length 128 = ("one.foo", "two.foo", "three.bar", "subdir")
  assert_int_neq(-1, array.find_string%(all_files$(), actual$(BASE% + 0)))
  assert_int_neq(-1, array.find_string%(all_files$(), actual$(BASE% + 1)))
  assert_string_neq(actual$(BASE% + 0), actual$(BASE% + 1))
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
  MkDir TMPDIR$

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
  Local root_drive$ = Choice(sys.is_platform%("pm*"), "A:", "C:")
  assert_int_equals(sys.SUCCESS, file.mkdir%(root_drive$ + "/"))
  assert_no_error()
  assert_int_equals(sys.SUCCESS, file.mkdir%(root_drive$ + "\"))
  assert_no_error()
  assert_int_equals(sys.SUCCESS, file.mkdir%(root_drive$))
  assert_no_error()
  If Not sys.is_platform%("mmb4w") Then
    assert_int_equals(sys.SUCCESS, file.mkdir%("/"))
    assert_no_error()
    assert_int_equals(sys.SUCCESS, file.mkdir%("\"))
    assert_no_error()
  EndIf
End Sub

Sub test_mkdir_rel_path()
  MkDir TMPDIR$

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

' Test that fails if file.mkdir%() does not skip the length byte at the start of the path string.
Sub test_mkdir_skips_path_len()
  MkDir TMPDIR$
  Local path_len% = Asc("/")
  Local f$ = TMPDIR$ + "/" + String$(path_len% - 1 - Len(TMPDIR$), "a")

  assert_int_equals(sys.SUCCESS, file.mkdir%(f$))
  assert_no_error()
  assert_true(file.is_directory%(f$))

  path_len% = Asc("\")
  f$ = TMPDIR$ + "/" + String$(path_len% - 1 - Len(TMPDIR$), "a")

  assert_int_equals(sys.SUCCESS, file.mkdir%(f$))
  assert_no_error()
  assert_true(file.is_directory%(f$))
End Sub

Sub test_depth_first_given_file()
  MkDir TMPDIR$
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
  MkDir TMPDIR$
  MkDir TMPDIR$ + "/bar-dir"
  ut.create_file(TMPDIR$ + "/foo")
  ut.create_file(TMPDIR$ + "/zzz")
  ut.create_file(TMPDIR$ + "/bar-dir/wombat")

  Dim actual$(list.new%(10))
  list.init(actual$())
  assert_int_equals(sys.SUCCESS, file.depth_first%(TMPDIR$, "depth_first_callback%", 5))

  ' The order of files at the same level is system dependent.
  ' The important thing is that the contents of a directory is visited before
  ' the directory itself is.
  assert_int_neq(-1, find_path%(actual$(), "/bar-dir/wombat_5"))
  assert_int_neq(-1, find_path%(actual$(), "/bar-dir_5"))
  assert_int_neq(-1, find_path%(actual$(), "/foo_5"))
  assert_int_neq(-1, find_path%(actual$(), "/zzz_5"))
  assert_int_neq(-1, find_path%(actual$(), "_5"))
  assert_true(find_path%(actual$(), "/bar-dir/wombat_5") < find_path%(actual$(), "/bar-dir_5"))
  assert_true(find_path%(actual$(), "/bar-dir_5") < find_path%(actual$(), "_5"))
  assert_true(find_path%(actual$(), "/foo_5") < find_path%(actual$(), "_5"))
  assert_true(find_path%(actual$(), "/zzz_5") < find_path%(actual$(), "_5"))

  Erase actual$()
End Sub

Function find_path%(a$(), f$)
  find_path% = array.find_string%(a$(), file.get_canonical$(TMPDIR$ + f$))
End Function

Sub test_depth_first_given_symlink()
  If Mm.Device$ <> "MMB4L" Then Exit Sub

  MkDir TMPDIR$
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
  MkDir TMPDIR$
  Local f$ = TMPDIR$ + "/foo"
  assert_int_equals(sys.FAILURE, file.depth_first%(f$, "depth_first_callback%", 5))
  assert_error("No such file or directory '" + file.get_canonical$(f$) + "'")
End Sub

Sub test_delete_root()
  Local roots$(array.new%(8)) = ("/", "\", "A:", "B:", "A:\", "A:/", "B:\", "B:/")
  Local i%

  For i% = Bound(roots$(), 0) To Bound(roots$(), 1)
    sys.err$ = ""
    assert_int_equals(sys.FAILURE, file.delete%(roots$(i%), 1))
    assert_error("Cannot delete drive '" + file.get_canonical$(roots$(i%)) + "'")
  Next
End Sub

Sub test_delete_given_not_found()
  MkDir TMPDIR$
  Local f$ = TMPDIR$ + "/foo"

  assert_int_equals(sys.FAILURE, file.delete%(f$, 1))
  assert_error("No such file or directory '" + file.get_canonical$(f$) + "'")
End Sub

Sub test_delete_given_file()
  MkDir TMPDIR$
  Local f$ = TMPDIR$ + "/foo"
  ut.create_file(f$)

  assert_true(file.exists%(f$))
  assert_int_equals(sys.SUCCESS, file.delete%(f$, 1))
  assert_false(file.exists%(f$))
End Sub

Sub test_delete_given_dir()
  given_file_tree()
  assert_int_equals(3, file.count_files%(TMPDIR$, "*", "all"))

  assert_int_equals(sys.SUCCESS, file.delete%(TMPDIR$, 20))
  assert_no_error()

  assert_false(file.exists%(TMPDIR$))
End Sub

Sub test_delete_given_symlink()
  If Mm.Device$ <> "MMB4L" Then Exit Sub

  MkDir TMPDIR$
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

Sub test_delete_given_too_many()
  given_file_tree()
  assert_int_equals(3, file.count_files%(TMPDIR$, "*", "all"))

  assert_int_equals(sys.FAILURE, file.delete%(TMPDIR$, 5))
  Local expected$ = "Cannot delete '" + file.get_canonical$(TMPDIR$)
  Cat expected$, "'; found 16 files but maximum is 5"
  assert_error(expected$)
  assert_int_equals(3, file.count_files%(TMPDIR$, "*", "all"))
End Sub

Sub test_delete_given_unlimited()
  given_file_tree()
  assert_int_equals(3, file.count_files%(TMPDIR$, "*", "all"))

  assert_int_equals(sys.SUCCESS, file.delete%(TMPDIR$, -1))
  assert_no_error()
  assert_false(file.exists%(TMPDIR$))
End Sub

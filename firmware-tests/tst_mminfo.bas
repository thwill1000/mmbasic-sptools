' Copyright (c) 2021 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For Colour Maximite 2, MMBasic 5.07

Option Explicit On
Option Default None
Option Base InStr(Mm.CmdLine$, "--base=1") > 0

#Include "../src/splib/system.inc"
#Include "../src/splib/array.inc"
#Include "../src/splib/list.inc"
#Include "../src/splib/string.inc"
#Include "../src/splib/file.inc"
#Include "../src/splib/vt100.inc"
#Include "../src/sptest/unittest.inc"

Const BASE% = Mm.Info(Option Base)
Const EXPECTED_FONT_HEIGHT% = 12
Const EXPECTED_FONT_WIDTH% = 8
Const EXPECTED_DIR$ = "/home/thwill/github/mmbasic-firmware/linux/build"
Const EXPECTED_PATH$ = "/home/thwill/github/sptools/firmware-tests"

add_test("test_architecture")
add_test("test_current")
add_test("test_device")
add_test("test_directory")
add_test("test_envvar")
add_test("test_errmsg")
add_test("test_errno")
add_test("test_exists")
add_test("test_filesize")
add_test("test_fontheight")
add_test("test_fontwidth")
add_test("test_hpos")
add_test("test_hres")
add_test("test_option_base")
add_test("test_option_break")
add_test("test_option_case")
add_test("test_option_default")
add_test("test_option_explicit")
add_test("test_option_resolution")
add_test("test_option_serial")
add_test("test_option_tab")
add_test("test_path")
add_test("test_version")
add_test("test_vpos")
add_test("test_vres")

run_tests()
'If InStr(Mm.CmdLine$, "--base") Then run_tests() Else run_tests("--base=1")

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Sub test_architecture()
  assert_string_equals("x86_64", Mm.Info$(Arch))
  assert_string_equals("x86_64", Mm.Info$(Architecture))
End Sub

Sub test_current()
  assert_string_equals(EXPECTED_PATH$ + "/tst_mminfo.bas", Mm.Info(Current))
End Sub

Sub test_device()
  assert_string_equals("Linux", Mm.Device$)
  assert_string_equals("Linux", Mm.Info$(Device))
End Sub

Sub test_directory()
  assert_string_equals(EXPECTED_DIR$ + "/", MM.Info$(Directory))
  assert_string_equals(EXPECTED_DIR$, Cwd$)
End Sub

Sub test_envvar()
  assert_string_equals("/home/thwill", Mm.Info$(ENVVAR "HOME"))
End Sub

Sub test_errmsg()
  On Error Skip 1
  Error "foo"
  assert_string_equals("Error in line", Left$(Mm.ErrMsg$, 13));
  assert_string_equals("foo", Right$(Mm.ErrMsg$, 3));
  assert_string_equals("Error in line", Left$(Mm.Info(ErrMsg), 13));
  assert_string_equals("foo", Right$(Mm.Info$(ErrMsg), 3));
End Sub

Sub test_errno()
  On Error Skip 1
  Error "foo"
  assert_int_equals(16, Mm.ErrNo);
  assert_int_equals(16, Mm.Info$(ErrNo));
End Sub

Sub test_exists()
  Local existing_dir$ = EXPECTED_PATH$
  Local existing_file$ = EXPECTED_PATH$ + "/tst_mminfo.bas"
  Local non_existing$ = EXPECTED_PATH$ + "/does_not_exist"
  Local root$ = "/"
  Local sym_link_dir$ = EXPECTED_DIR$ + "/firmware-tests"

  ' TODO: what about directory paths with trailing '/' ?

  assert_int_equals(1, Mm.Info(Exists existing_dir$))
  assert_int_equals(1, Mm.Info(Exists existing_file$))
  assert_int_equals(0, Mm.Info(Exists non_existing$))
  assert_int_equals(1, Mm.Info(Exists root$))
  assert_int_equals(1, Mm.Info(Exists sym_link_dir$))

  assert_int_equals(0, Mm.Info(Exists File existing_dir$))
  assert_int_equals(1, Mm.Info(Exists File existing_file$))
  assert_int_equals(0, Mm.Info(Exists File non_existing$))
  assert_int_equals(0, Mm.Info(Exists File root$))
  assert_int_equals(0, Mm.Info(Exists File sym_link_dir$))

  assert_int_equals(1, Mm.Info(Exists Dir existing_dir$))
  assert_int_equals(0, Mm.Info(Exists Dir existing_file$))
  assert_int_equals(0, Mm.Info(Exists Dir non_existing$))
  assert_int_equals(1, Mm.Info(Exists Dir root$))
  assert_int_equals(1, Mm.Info(Exists Dir sym_link_dir$))

  assert_int_equals(0, Mm.Info(Exists SymLink existing_dir$))
  assert_int_equals(0, Mm.Info(Exists SymLink existing_file$))
  assert_int_equals(0, Mm.Info(Exists SymLink non_existing$))
  assert_int_equals(0, Mm.Info(Exists SymLink root$))
  assert_int_equals(1, Mm.Info(Exists SymLink sym_link_dir$))
End Sub

Sub test_filesize()
  ' Test when file does not exist.
  assert_int_equals(-1, Mm.Info(FileSize "test_filesize.txt"))

  ' Test when file is empty.
  Open "test_filesize.txt" For Output As #1
  Close #1
  assert_int_equals(0, Mm.Info(FileSize "test_filesize.txt"))
  Kill "test_filesize.txt"

  ' Test when file is not empty.
  Open "test_filesize.txt" For Output As #1
  Print #1, "7 bytes";
  Close #1
  assert_int_equals(7, Mm.Info(FileSize "test_filesize.txt"))
  Kill "test_filesize.txt"

  ' Test when file is directory.
  assert_int_equals(-2, Mm.Info(FileSize Mm.Info(Directory)))
End Sub

Sub test_fontheight()
  assert_int_equals(EXPECTED_FONT_HEIGHT%, Mm.Info(FontHeight))
End Sub

Sub test_fontwidth()
  assert_int_equals(EXPECTED_FONT_WIDTH%, Mm.Info(FontWidth))
End Sub

Sub test_hpos()
  Option Resolution Character
  Local actual% = Mm.Info(HPos)
  assert_int_equals(0, actual%)

  Option Resolution Pixel
  assert_int_equals(actual% * EXPECTED_FONT_WIDTH%, Mm.Info(HPos))
End Sub

Sub test_hres()
  Option Resolution Character
  Local actual% = Mm.Info(HRes)
  assert_int_equals(0, actual%)
  assert_int_equals(actual%, Mm.HRes)

  Option Resolution Pixel
  assert_int_equals(actual% * EXPECTED_FONT_WIDTH%, Mm.Info(HRes))
  assert_int_equals(actual% * EXPECTED_FONT_WIDTH%, Mm.HRes)
End Sub

Sub test_option_base()
  assert_int_equals(InStr(Mm.CmdLine$, "--base=1") > 0, Mm.Info(Option Base))
End Sub

Sub test_option_break()
  assert_int_equals(3, Mm.Info(Option Break))

  Option Break 4
  assert_int_equals(4, Mm.Info(Option Break));

  Option Break 3
  assert_int_equals(3, Mm.Info(Option Break))
End Sub

Sub test_option_case()
  assert_string_equals("Title", Mm.Info(Option Case))

  Option Case Lower
  assert_string_equals("Lower", Mm.Info(Option Case))

  Option Case Upper
  assert_string_equals("Upper", Mm.Info(Option Case))

  Option Case Title
  assert_string_equals("Title", Mm.Info(Option Case))
End Sub

Sub test_option_default()
  assert_string_equals("None", Mm.Info(Option Default))

  Option Default Integer
  assert_string_equals("Integer", Mm.Info(Option Default))

  Option Default Float
  assert_string_equals("Float", Mm.Info(Option Default))

  Option Default String
  assert_string_equals("String", Mm.Info(Option Default))

  Option Default None
  assert_string_equals("None", Mm.Info(Option Default))
End Sub

Sub test_option_explicit()
  assert_string_equals("On", Mm.Info(Option Explicit))

  Option Explicit Off
  assert_string_equals("Off", Mm.Info(Option Explicit))

  Option Explicit True
  assert_string_equals("On", Mm.Info(Option Explicit))

  Option Explicit False
  assert_string_equals("Off", Mm.Info(Option Explicit))

  Option Explicit On
  assert_string_equals("On", Mm.Info(Option Explicit))

  Option Explicit False
  Option Explicit
  assert_string_equals("On", Mm.Info(Option Explicit))
End Sub

Sub test_option_resolution()
  Option Resolution Pixel
  assert_string_equals("Pixel", Mm.Info(Option Resolution))

  Option Resolution Character
  assert_string_equals("Character", Mm.Info(Option Resolution))
End Sub

Sub test_option_serial()
  assert_string_equals("Serial", Mm.Info(Option Console))

  ' For MMB4L 'OPTION CONSOLE {BOTH|SCREEN}' is ignored.

  Option Console Both
  assert_string_equals("Serial", Mm.Info(Option Console))

  Option Console Screen
  assert_string_equals("Serial", Mm.Info(Option Console))

  Option Console Serial
  assert_string_equals("Serial", Mm.Info(Option Console))

End Sub

Sub test_option_tab()
  assert_int_equals(4, Mm.Info(Option Tab))

  Option Tab 2
  assert_int_equals(2, Mm.Info(Option Tab))

  Option Tab 8
  assert_int_equals(8, Mm.Info(Option Tab))

  Option Tab 4
  assert_int_equals(4, Mm.Info(Option Tab))
End Sub

Sub test_path()
  assert_string_equals(EXPECTED_PATH$ + "/", MM.Info$(Path))
End Sub

Sub test_vpos()
  Option Resolution Character
  Local actual% = Mm.Info(VPos)
  assert_int_equals(0, actual%)

  Option Resolution Pixel
  assert_int_equals(actual% * EXPECTED_FONT_HEIGHT%, Mm.Info(VPos))
End Sub

Sub test_vres()
  Option Resolution Character
  Local actual% = Mm.Info(VRes)
  assert_int_equals(0, actual%)
  assert_int_equals(actual%, Mm.VRes)

  Option Resolution Pixel
  assert_int_equals(actual% * EXPECTED_FONT_HEIGHT%, Mm.Info(VRes))
  assert_int_equals(actual% * EXPECTED_FONT_HEIGHT%, Mm.VRes)
End Sub

Sub test_version()
  assert_float_equals(2021.0, Mm.Info(Version))
  assert_float_equals(2021.0, Mm.Info(Ver))
End Sub

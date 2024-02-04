' Copyright (c) 2020-2021 Thomas Hugo Williams
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

add_test("test_provides")
add_test("test_provides_given_duplicates")
add_test("test_provides_given_too_many")
add_test("test_requires")
add_test("test_get_config")
add_test("test_format_version")
add_test("test_format_firmware_version")
add_test("test_is_platform")

If InStr(Mm.CmdLine$, "--base") Then run_tests() Else run_tests("--base=1")

End

Sub setup_test()
End Sub

Sub teardown_test()
End Sub

Sub test_provides()
  Local i%
  For i% = 1 To sys.MAX_INCLUDES% : sys.includes$(i%) = "" : Next

  sys.provides("foo")
  sys.provides("bar")

  assert_no_error()
  If Mm.Info(Option Base) = 0 Then assert_string_equals("", sys.includes$(0))
  assert_string_equals("foo", sys.includes$(1))
  assert_string_equals("bar", sys.includes$(2))
  For i% = 3 To sys.MAX_INCLUDES% : assert_string_equals("", sys.includes$(i%)) : Next
End Sub

Sub test_provides_given_duplicates()
  Local i%
  For i% = 1 To sys.MAX_INCLUDES% : sys.includes$(i%) = "" : Next
  sys.provides("list")
  sys.provides("set")
  assert_no_error()

  sys.provides("list")
  assert_error("file already included: list.inc")
End Sub

Sub test_provides_given_too_many()
  Local i%
  For i% = 1 To sys.MAX_INCLUDES% : sys.includes$(i%) = "foo" + Str$(i%) : Next
  assert_no_error()

  sys.provides("wombat")
  assert_error("too many includes")
End Sub

Sub test_requires()
  Local i%
  sys.includes$(1) = "foo"
  sys.includes$(2) = "bar"
  For i% = 3 To sys.MAX_INCLUDES% : sys.includes$(i%) = "" : Next

  sys.requires("bar")
  assert_no_error()

  sys.requires("wombat")
  assert_error("required file(s) not included: wombat.inc")

  sys.requires("snafu")
  assert_error("required file(s) not included: snafu.inc")

  sys.requires("wombat", "snafu")
  assert_error("required file(s) not included: wombat.inc, snafu.inc")

  sys.requires("a", "bar", "c", "d", "e", "foo", "g", "h", "i", "j")
  assert_error("required file(s) not included: a.inc, c.inc, d.inc, e.inc, g.inc, h.inc, i.inc, j.inc")
End Sub

Sub test_get_config()
  MkDir TMPDIR$
  Const f$ = TMPDIR$ + "/test_get_config.ini"
  Open f$ For Output As #1
  Print #1, "key_a = value_a"
  Print #1, "key_b = " + Chr$(34) + "value_b" + Chr$(34)
  Print #1, "key_c = value_c # comment"
  Print #1, "key_d = value_d ; comment"
  Print #1, "key_e ="
  Print #1, "key_f"
  Close #1

  assert_string_equals("value_a", sys.get_config$("key_a", "my_default", f$))
  assert_string_equals("value_b", sys.get_config$("KEY_B", "my_default", f$))
  assert_string_equals("value_c", sys.get_config$("key_c", "my_default", f$))
  assert_string_equals("value_d", sys.get_config$("key_d", "my_default", f$))
  assert_string_equals("", sys.get_config$("key_e", "my_default", f$))
  assert_string_equals("", sys.get_config$("key_f", "my_default", f$))
  assert_string_equals("my_default", sys.get_config$("key_g", "my_default", f$))
  assert_string_equals("my_default", sys.get_config$("key_a", "my_default", TMPDIR$ + "missing.ini"))
End Sub

Sub test_format_version()
  ' Override sys.VERSION to make test stable.
  Erase sys.VERSION
  Dim sys.VERSION As Integer = 123456
  assert_string_equals("1.23.156", sys.format_version$())

  assert_string_equals("5.6 alpha 0", sys.format_version$(506000))
  assert_string_equals("5.6 beta 0", sys.format_version$(506100))
  assert_string_equals("5.6 RC 0", sys.format_version$(506200))
  assert_string_equals("5.6.0", sys.format_version$(506300))
  assert_string_equals("5.6.153", sys.format_version$(506453))
  assert_string_equals("0.9.9", sys.format_version$(9309))
End Sub

Sub test_format_firmware_version()
  ' Override sys.FIRMWARE to make test stable.
  Erase sys.FIRMWARE
  Dim sys.FIRMWARE As Integer = 12345600

  If Mm.Device$ = "MMB4L" Then
    assert_string_equals("0.1 RC 34 build 5600", sys.format_firmware_version$())
    assert_string_equals("0.6.0", sys.format_firmware_version$(63000000))
    assert_string_equals("6.5 alpha 4", sys.format_firmware_version$(6050040000))
    assert_string_equals("6.5 beta 3", sys.format_firmware_version$(6051030000))
    assert_string_equals("6.5 RC 2", sys.format_firmware_version$(6052020000))
    assert_string_equals("6.5.1 build 1", sys.format_firmware_version$(6053010001))
  Else
    assert_string_equals("12.34.56", sys.format_firmware_version$())
    assert_string_equals("0.06.00", sys.format_firmware_version$(60000))
    assert_string_equals("10.07.08b7", sys.format_firmware_version$(10070807))
    assert_string_equals("5.07.08b7", sys.format_firmware_version$(5070807))
    assert_string_equals("5.06.00", sys.format_firmware_version$(5060000))
  EndIf
End Sub

Sub test_is_platform()
  Local original$ = Choice(InStr(Mm.Device$, "PicoMite"), Mm.Info$(Platform), "")
  If original$ = "" Then original$ = Mm.Device$

  override_platform("Colour Maximite 2")
  assert_int_equals(0, sys.is_platform%("mmb4l"))
  assert_int_equals(1, sys.is_platform%("cmm2"))
  assert_int_equals(1, sys.is_platform%("cmm2*"))
  assert_int_equals(0, sys.is_platform%("cmm2g2"))

  override_platform("Game*Mite")
  assert_int_equals(0, sys.is_platform%("mmb4l"))
  assert_int_equals(0, sys.is_platform%("cmm2"))
  assert_int_equals(1, sys.is_platform%("gamemite"))
  assert_int_equals(0, sys.is_platform%("pgvga"))
  assert_int_equals(0, sys.is_platform%("pm"))
  assert_int_equals(0, sys.is_platform%("pmvga"))
  assert_int_equals(1, sys.is_platform%("pm*"))

  override_platform("PicoMite")
  assert_int_equals(0, sys.is_platform%("mmb4l"))
  assert_int_equals(0, sys.is_platform%("cmm2"))
  assert_int_equals(0, sys.is_platform%("gamemite"))
  assert_int_equals(0, sys.is_platform%("pgvga"))
  assert_int_equals(1, sys.is_platform%("pm"))
  assert_int_equals(0, sys.is_platform%("pmvga"))
  assert_int_equals(0, sys.is_platform%("pmvga*"))
  assert_int_equals(1, sys.is_platform%("pm*"))

  override_platform("PicoMiteVGA")
  assert_int_equals(0, sys.is_platform%("mmb4l"))
  assert_int_equals(0, sys.is_platform%("cmm2"))
  assert_int_equals(0, sys.is_platform%("gamemite"))
  assert_int_equals(0, sys.is_platform%("pgvga"))
  assert_int_equals(0, sys.is_platform%("pm"))
  assert_int_equals(1, sys.is_platform%("pmvga"))
  assert_int_equals(1, sys.is_platform%("pmvga*"))
  assert_int_equals(1, sys.is_platform%("pm*"))

  override_platform("PicoGAME VGA")
  assert_int_equals(0, sys.is_platform%("mmb4l"))
  assert_int_equals(0, sys.is_platform%("cmm2"))
  assert_int_equals(0, sys.is_platform%("gamemite"))
  assert_int_equals(1, sys.is_platform%("pgvga"))
  assert_int_equals(0, sys.is_platform%("pm"))
  assert_int_equals(0, sys.is_platform%("pmvga"))
  assert_int_equals(1, sys.is_platform%("pmvga*"))
  assert_int_equals(1, sys.is_platform%("pm*"))

  override_platform(original$)
End Sub

Sub override_platform(platform$)
  On Error Skip
  Erase sys.OVERRIDE_PLATFORM$
  On Error Clear
  Dim sys.OVERRIDE_PLATFORM$ = platform$
End Sub

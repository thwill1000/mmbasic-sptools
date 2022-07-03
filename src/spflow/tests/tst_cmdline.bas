' Copyright (c) 2020-2022 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For Colour Maximite 2, MMBasic 5.07

Option Explicit On
Option Default Integer

#Include "../../splib/system.inc"
#Include "../../splib/array.inc"
#Include "../../splib/list.inc"
#Include "../../splib/string.inc"
#Include "../../splib/file.inc"
#Include "../../splib/map.inc"
#Include "../../splib/set.inc"
#Include "../../splib/vt100.inc"
#Include "../../common/sptools.inc"
#Include "../../sptest/unittest.inc"
#Include "../../sptrans/keywords.inc"
#Include "../../sptrans/lexer.inc"
#Include "../options.inc"
#Include "../cmdline.inc"

Const INPUT_FILE$ = "input.bas"
Const OUTPUT_FILE$ = "output.txt"

add_test("test_no_input_file")
add_test("test_input_file")
add_test("test_output_file")
add_test("test_all")
add_test("test_brief")
add_test("test_no_location")
add_test("test_unknown_option")
add_test("test_too_many_arguments")

run_tests()

End

Sub setup_test()
  opt.init()
End Sub

Sub teardown_test()
End Sub

Sub test_no_input_file()
  cli.parse("")

  assert_error("no input file specified")
End Sub

Sub test_input_file()
  ' Test with unquoted filename.
  cli.parse(INPUT_FILE$)

  assert_no_error()
  assert_string_equals("input.bas", opt.infile$)

  ' Test with quoted multi-word filename.
  cli.parse(str.quote$("my input.bas"))

  assert_no_error()
  assert_string_equals("my input.bas", opt.infile$)
End Sub

Sub test_output_file()
  ' Test with unquoted filename.
  cli.parse(INPUT_FILE$ + " " + OUTPUT_FILE$)

  assert_no_error()
  assert_string_equals("input.bas", opt.infile$)
  assert_string_equals("output.txt", opt.outfile$)

  ' Test with quoted multi-word filename.
  cli.parse(INPUT_FILE$ + " " + str.quote$("my output.txt"))

  assert_no_error()
  assert_string_equals("input.bas", opt.infile$)
  assert_string_equals("my output.txt", opt.outfile$)
End Sub

Sub test_all()
  cli.parse("--all " + INPUT_FILE$)
  assert_no_error()
  assert_int_equals(1, opt.all)

  cli.parse("-A=1 " + INPUT_FILE$)
  assert_error("option '-A' does not expect argument")
End Sub

Sub test_brief()
  cli.parse("--brief " + INPUT_FILE$)
  assert_no_error()
  assert_int_equals(1, opt.brief)

  cli.parse("-b=1 " + INPUT_FILE$)
  assert_error("option '-b' does not expect argument")
End Sub

Sub test_no_location()
  cli.parse("--no-location " + INPUT_FILE$)
  assert_no_error()
  assert_int_equals(1, opt.no_location)

  cli.parse("--no-location=1 " + INPUT_FILE$)
  assert_error("option '--no-location' does not expect argument")
End Sub

Sub test_unknown_option()
  cli.parse("--wombat " + INPUT_FILE$)

  assert_error("option '--wombat' is unknown")
End Sub

Sub test_too_many_arguments()
  cli.parse(INPUT_FILE$ + " " + OUTPUT_FILE$ + " wombat")

  assert_error("unexpected argument 'wombat'")
End Sub

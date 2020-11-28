' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

#Include "../../common/system.inc"
#Include "../../common/array.inc"
#Include "../../common/list.inc"
#Include "../../common/string.inc"
#Include "../../common/file.inc"
#Include "../../common/set.inc"
#Include "../../common/vt100.inc"
#Include "../../sptest/unittest.inc"
#Include "../../sptrans/lexer.inc"
#Include "../cmdline.inc"
#Include "../options.inc"

Const input_file$ = Chr$(34) + "input.bas" + Chr$(34)
Const output_file$ = Chr$(34) + "output.bas" + Chr$(34)

add_test("test_no_input_file")
add_test("test_input_file")
add_test("test_unquoted_input_file")
add_test("test_output_file")
add_test("test_unquoted_output_file")
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
  cli.parse(input_file$)

  assert_no_error()
  assert_string_equals("input.bas", opt.infile$)
End Sub

Sub test_unquoted_input_file()
  cli.parse("input.bas")

  assert_error("input file name must be quoted")
End Sub

Sub test_output_file()
  cli.parse(input_file$ + " " + output_file$)

  assert_no_error()
  assert_string_equals("input.bas", opt.infile$)
  assert_string_equals("output.bas", opt.outfile$)
End Sub

Sub test_unquoted_output_file()
  cli.parse(input_file$ + " output.bas")

  assert_error("output file name must be quoted")
End Sub

Sub test_all()
  cli.parse("--all " + input_file$)
  assert_no_error()
  assert_equals(1, opt.all)

  cli.parse("-A=1 " + input_file$)
  assert_error("option '-A' does not expect argument")
End Sub

Sub test_brief()
  cli.parse("--brief " + input_file$)
  assert_no_error()
  assert_equals(1, opt.brief)

  cli.parse("-b=1 " + input_file$)
  assert_error("option '-b' does not expect argument")
End Sub

Sub test_no_location()
  cli.parse("--no-location " + input_file$)
  assert_no_error()
  assert_equals(1, opt.no_location)

  cli.parse("--no-location=1 " + input_file$)
  assert_error("option '--no-location' does not expect argument")
End Sub

Sub test_unknown_option()
  cli.parse("--wombat " + input_file$)

  assert_error("option '--wombat' is unknown")
End Sub

Sub test_too_many_arguments()
  cli.parse(input_file$ + " " + output_file$ + " wombat")

  assert_error("unexpected argument 'wombat'")
End Sub

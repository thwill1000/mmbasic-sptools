' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

#Include "../cmdline.inc"
#Include "../options.inc"
#Include "../../common/error.inc"
#Include "../../common/file.inc"
#Include "../../common/list.inc"
#Include "../../common/set.inc"
#Include "../../sptest/unittest.inc"
#Include "../../sptrans/lexer.inc"

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
  op_init()
End Sub

Sub teardown_test()
End Sub

Function test_no_input_file()
  cl_parse("")

  assert_error("no input file specified")
End Function

Function test_input_file()
  cl_parse(input_file$)

  assert_no_error()
  assert_string_equals("input.bas", op_infile$)
End Function

Function test_unquoted_input_file()
  cl_parse("input.bas")

  assert_error("input file name must be quoted")
End Function

Function test_output_file()
  cl_parse(input_file$ + " " + output_file$)

  assert_no_error()
  assert_string_equals("input.bas", op_infile$)
  assert_string_equals("output.bas", op_outfile$)
End Function

Function test_unquoted_output_file()
  cl_parse(input_file$ + " output.bas")

  assert_error("output file name must be quoted")
End Function

Function test_all()
  cl_parse("--all " + input_file$)
  assert_no_error()
  assert_equals(1, op_all)

  cl_parse("-A=1 " + input_file$)
  assert_error("option '-A' does not expect argument")
End Function

Function test_brief()
  cl_parse("--brief " + input_file$)
  assert_no_error()
  assert_equals(1, op_brief)

  cl_parse("-b=1 " + input_file$)
  assert_error("option '-b' does not expect argument")
End Function

Function test_no_location()
  cl_parse("--no-location " + input_file$)
  assert_no_error()
  assert_equals(1, op_no_location)

  cl_parse("--no-location=1 " + input_file$)
  assert_error("option '--no-location' does not expect argument")
End Function

Function test_unknown_option()
  cl_parse("--wombat " + input_file$)

  assert_error("option '--wombat' is unknown")
End Function

Function test_too_many_arguments()
  cl_parse(input_file$ + " " + output_file$ + " wombat")

  assert_error("unexpected argument 'wombat'")
End Function

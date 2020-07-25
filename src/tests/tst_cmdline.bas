' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

Dim err$
Dim mbt_in$
Dim mbt_out$

#Include "unittest.inc"
#Include "../cmdline.inc"
#Include "../lexer.inc"
#Include "../options.inc"
#Include "../set.inc"

Const input_file$ = Chr$(34) + "input.bas" + Chr$(34)
Const output_file$ = Chr$(34) + "output.bas" + Chr$(34)

Cls

add_test("test_no_input_file")
add_test("test_input_file")
add_test("test_unquoted_input_file")
add_test("test_colour")
add_test("test_no_comments")
add_test("test_empty_lines")
add_test("test_format_only")
add_test("test_indent")
add_test("test_spacing")
add_test("test_output_file")
add_test("test_unquoted_output_file")
add_test("test_unknown_option")
add_test("test_too_many_arguments")
add_test("test_everything")

run_tests()

End

Sub test_setup()
  err$ = ""
  op_init()
  mbt_in$ = ""
  mbt_out$ = ""
End Sub

Function test_no_input_file()
  test_setup() ' TODO: automate calling of this before each test function

  cl_parse("-f")

  assert_error("no input file specified")
End Function

Function test_input_file()
  test_setup()

  cl_parse(input_file$)

  assert_no_error()
  assert_string_equals("input.bas", mbt_in$)
End Function

Function test_unquoted_input_file()
  test_setup()

  cl_parse("input.bas")

  assert_error("input file name must be quoted")
End Function

Function test_colour()
  test_setup() ' TODO: automate calling of this before each test function

  cl_parse("--colour " + input_file$)
  assert_no_error()
  assert_equals(1, op_colour)

  cl_parse("-C=1 " + input_file$)
  assert_error("option '-C' does not expect argument")
End Function

Function test_no_comments()
  test_setup()

  op_comments = 999
  cl_parse("--no-comments " + input_file$)
  assert_no_error()
  assert_equals(0, op_comments)

  op_comments = 999
  cl_parse("-n " + input_file$)
  assert_no_error()
  assert_equals(0, op_comments)

  cl_parse("--no-comments=1" + input_file$)
  assert_error("option '--no-comments' does not expect argument")
End Function

Function test_empty_lines()
  test_setup()

  cl_parse("--empty-lines=0 " + input_file$)

  assert_no_error()
  assert_equals(0, op_empty_lines)

  cl_parse("--empty-lines=1 " + input_file$)

  assert_no_error()
  assert_equals(1, op_empty_lines)

  cl_parse("--empty-lines " + input_file$)
  assert_error("option '--empty-lines' expects {0|1} argument")

  cl_parse("--empty-lines=3" + input_file$)
  assert_error("option '--empty-lines' expects {0|1} argument")
End Function

Function test_format_only()
  test_setup()

  cl_parse("--format-only " + input_file$)
  assert_no_error()
  assert_equals(1, op_format_only)

  cl_parse("-f=1 " + input_file$)
  assert_error("option '-f' does not expect argument")
End Function

Function test_indent()
  test_setup()

  cl_parse("--indent=0 " + input_file$)
  assert_no_error()
  assert_equals(0, op_indent_sz)

  cl_parse("--indent=1 " + input_file$)
  assert_no_error()
  assert_equals(1, op_indent_sz)

  cl_parse("--indent " + input_file$)
  assert_error("option '--indent' expects <number> argument")

  cl_parse("--indent=3 " + input_file$)
  assert_no_error()
  assert_equals(3, op_indent_sz)
End Function

Function test_spacing()
  test_setup()

  cl_parse("--spacing=0 " + input_file$)

  assert_no_error()
  assert_equals(0, op_spacing)

  cl_parse("--spacing=1 " + input_file$)

  assert_no_error()
  assert_equals(1, op_spacing)

  cl_parse("--spacing=2 " + input_file$)

  assert_no_error()
  assert_equals(2, op_spacing)

  cl_parse("--spacing " + input_file$)
  assert_error("option '--spacing' expects {0|1|2} argument")

  cl_parse("--spacing=3 " + input_file$)
  assert_error("option '--spacing' expects {0|1|2} argument")
End Function

Function test_output_file()
  test_setup()

  cl_parse(input_file$ + " " + output_file$)

  assert_no_error()
  assert_string_equals("input.bas", mbt_in$)
  assert_string_equals("output.bas", mbt_out$)
End Function

Function test_unquoted_output_file()
  test_setup()

  cl_parse(input_file$ + " output.bas")

  assert_error("output file name must be quoted")
End Function

Function test_unknown_option()
  test_setup()

  cl_parse("--wombat " + input_file$)

  assert_error("option '--wombat' is unknown")
End Function

Function test_too_many_arguments()
  test_setup()

  cl_parse(input_file$ + " " + output_file$ + " wombat")

  assert_error("unexpected argument 'wombat'")
End Function

Function test_everything()
  test_setup()

  cl_parse("-f -C -e=1 -i=2 -s=0 -n " + input_file$ + " " + output_file$)

  assert_no_error()
  assert_equals(1, op_format_only)
  assert_string_equals("input.bas", mbt_in$)
  assert_string_equals("output.bas", mbt_out$)
  assert_equals(1, op_colour)
  assert_equals(0, op_comments)
  assert_equals(1, op_empty_lines)
  assert_equals(2, op_indent_sz)
  assert_equals(0, op_spacing)
End Function

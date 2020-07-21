' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

Dim err$
Dim mbt_in$
Dim mbt_out$

#Include "../cmdline.inc"
#Include "../lexer.inc"
#Include "../options.inc"
#Include "../set.inc"
#Include "../unittest.inc"

Const input_file$ = Chr$(34) + "input.bas" + Chr$(34)
Const output_file$ = Chr$(34) + "output.bas" + Chr$(34)

Cls

ut_add_test("test_no_input_file")
ut_add_test("test_input_file")
ut_add_test("test_unquoted_input_file")
ut_add_test("test_colour")
ut_add_test("test_comments")
ut_add_test("test_empty_lines")
ut_add_test("test_format_only")
ut_add_test("test_indent")
ut_add_test("test_spacing")
ut_add_test("test_output_file")
ut_add_test("test_unquoted_output_file")
ut_add_test("test_unknown_option")
ut_add_test("test_too_many_arguments")
ut_add_test("test_everything")

ut_run_tests()

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

  ut_assert_string_equals("no input file specified", err$)
End Function

Function test_input_file()
  test_setup()

  cl_parse(input_file$)

  ut_assert_string_equals("", err$)
  ut_assert_string_equals("input.bas", mbt_in$)
End Function

Function test_unquoted_input_file()
  test_setup()

  cl_parse("input.bas")

  ut_assert_string_equals("input file name must be quoted", err$)
End Function

Function test_colour()
  test_setup() ' TODO: automate calling of this before each test function

  cl_parse("--colour " + input_file$)
  ut_assert_string_equals("", err$)
  ut_assert_equals(1, op_colour)

  cl_parse("-C=1 " + input_file$)
  ut_assert_string_equals("option '-C' does not expect argument", err$)
End Function

Function test_comments()
  test_setup()

  cl_parse("--comments=0 " + input_file$)

  ut_assert_string_equals("", err$)
  ut_assert_equals(0, op_comments)

  cl_parse("--comments=1 " + input_file$)

  ut_assert_string_equals("", err$)
  ut_assert_equals(1, op_comments)

  cl_parse("--comments " + input_file$)
  ut_assert_string_equals("option '--comments' expects {0|1} argument", err$)

  cl_parse("--comments=3" + input_file$)
  ut_assert_string_equals("option '--comments' expects {0|1} argument", err$)
End Function

Function test_empty_lines()
  test_setup()

  cl_parse("--empty-lines=0 " + input_file$)

  ut_assert_string_equals("", err$)
  ut_assert_equals(0, op_empty_lines)

  cl_parse("--empty-lines=1 " + input_file$)

  ut_assert_string_equals("", err$)
  ut_assert_equals(1, op_empty_lines)

  cl_parse("--empty-lines " + input_file$)
  ut_assert_string_equals("option '--empty-lines' expects {0|1} argument", err$)

  cl_parse("--empty-lines=3" + input_file$)
  ut_assert_string_equals("option '--empty-lines' expects {0|1} argument", err$)
End Function

Function test_format_only()
  test_setup()

  cl_parse("--format-only " + input_file$)
  ut_assert_string_equals("", err$)
  ut_assert_equals(1, op_format_only)

  cl_parse("-f=1 " + input_file$)
  ut_assert_string_equals("option '-f' does not expect argument", err$)
End Function

Function test_indent()
  test_setup()

  cl_parse("--indent=0 " + input_file$)
  ut_assert_string_equals("", err$)
  ut_assert_equals(0, op_indent_sz)

  cl_parse("--indent=1 " + input_file$)
  ut_assert_string_equals("", err$)
  ut_assert_equals(1, op_indent_sz)

  cl_parse("--indent " + input_file$)
  ut_assert_string_equals("option '--indent' expects <number> argument", err$)

  cl_parse("--indent=3 " + input_file$)
  ut_assert_string_equals("", err$)
  ut_assert_equals(3, op_indent_sz)
End Function

Function test_spacing()
  test_setup()

  cl_parse("--spacing=0 " + input_file$)

  ut_assert_string_equals("", err$)
  ut_assert_equals(0, op_spacing)

  cl_parse("--spacing=1 " + input_file$)

  ut_assert_string_equals("", err$)
  ut_assert_equals(1, op_spacing)

  cl_parse("--spacing=2 " + input_file$)

  ut_assert_string_equals("", err$)
  ut_assert_equals(2, op_spacing)

  cl_parse("--spacing " + input_file$)
  ut_assert_string_equals("option '--spacing' expects {0|1|2} argument", err$)

  cl_parse("--spacing=3 " + input_file$)
  ut_assert_string_equals("option '--spacing' expects {0|1|2} argument", err$)
End Function

Function test_output_file()
  test_setup()

  cl_parse(input_file$ + " " + output_file$)

  ut_assert_string_equals("", err$)
  ut_assert_string_equals("input.bas", mbt_in$)
  ut_assert_string_equals("output.bas", mbt_out$)
End Function

Function test_unquoted_output_file()
  test_setup()

  cl_parse(input_file$ + " output.bas")

  ut_assert_string_equals("output file name must be quoted", err$)
End Function

Function test_unknown_option()
  test_setup()

  cl_parse("--wombat " + input_file$)

  ut_assert_string_equals("option '--wombat' is unknown", err$)
End Function

Function test_too_many_arguments()
  test_setup()

  cl_parse(input_file$ + " " + output_file$ + " wombat")

  ut_assert_string_equals("unexpected argument 'wombat'", err$)
End Function

Function test_everything()
  test_setup()

  cl_parse("-f -C -e=1 -i=2 -s=0 -c=1 " + input_file$ + " " + output_file$)

  ut_assert_string_equals("", err$)
  ut_assert_equals(1, op_format_only)
  ut_assert_string_equals("input.bas", mbt_in$)
  ut_assert_string_equals("output.bas", mbt_out$)
  ut_assert_equals(1, op_colour)
  ut_assert_equals(1, op_comments)
  ut_assert_equals(1, op_empty_lines)
  ut_assert_equals(2, op_indent_sz)
  ut_assert_equals(0, op_spacing)
End Function

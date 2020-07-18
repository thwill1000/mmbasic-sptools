' Copyright (c) 2020 Thomas Hugo Williams

Option Explicit On
Option Default Integer

Dim err$
Dim mbt_format_only
Dim mbt_in$
Dim mbt_out$
Dim pp_colour
Dim pp_comments
Dim pp_empty_lines
Dim pp_indent_sz
Dim pp_spacing

#Include "../cmdline.inc"
#Include "../lexer.inc"
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
  mbt_format_only = 0
  mbt_in$ = ""
  mbt_out$ = ""
  pp_colour = 0
  pp_comments = -1
  pp_empty_lines = -1
  pp_indent_sz = -1
  pp_spacing = -1
End Sub

Function test_no_input_file()
  test_setup() ' TODO: automate calling of this before each test function

  parse_cmdline("-f")

  ut_assert_string_equals("no input file specified", err$)
End Function

Function test_input_file()
  test_setup()

  parse_cmdline(input_file$)

  ut_assert_string_equals("", err$)
  ut_assert_string_equals("input.bas", mbt_in$)
End Function

Function test_unquoted_input_file()
  test_setup()

  parse_cmdline("input.bas")

  ut_assert_string_equals("input file name must be quoted", err$)
End Function

Function test_colour()
  test_setup() ' TODO: automate calling of this before each test function

  parse_cmdline("--colour " + input_file$)

  ut_assert_string_equals("", err$)
  ut_assert_equals(1, pp_colour)
End Function

Function test_comments()
  test_setup()

  parse_cmdline("--comments=0 " + input_file$)

  ut_assert_string_equals("", err$)
  ut_assert_equals(0, pp_comments)

  parse_cmdline("--comments=1 " + input_file$)

  ut_assert_string_equals("", err$)
  ut_assert_equals(1, pp_comments)

  parse_cmdline("--comments " + input_file$)
  ut_assert_string_equals("option '--comments' expects argument of 0 or 1", err$)

  parse_cmdline("--comments=3" + input_file$)
  ut_assert_string_equals("option '--comments' expects argument of 0 or 1", err$)
End Function

Function test_empty_lines()
  test_setup()

  parse_cmdline("--empty-lines=0 " + input_file$)

  ut_assert_string_equals("", err$)
  ut_assert_equals(0, pp_empty_lines)

  parse_cmdline("--empty-lines=1 " + input_file$)

  ut_assert_string_equals("", err$)
  ut_assert_equals(1, pp_empty_lines)

  parse_cmdline("--empty-lines " + input_file$)
  ut_assert_string_equals("option '--empty-lines' expects argument of 0 or 1", err$)

  parse_cmdline("--empty-lines=3" + input_file$)
  ut_assert_string_equals("option '--empty-lines' expects argument of 0 or 1", err$)
End Function

Function test_format_only()
  test_setup()

  parse_cmdline("--format-only " + input_file$)

  ut_assert_string_equals("", err$)
  ut_assert_equals(1, mbt_format_only)
End Function

Function test_indent()
  test_setup()

  parse_cmdline("--indent=0 " + input_file$)

  ut_assert_string_equals("", err$)
  ut_assert_equals(0, pp_indent_sz)

  parse_cmdline("--indent=1 " + input_file$)

  ut_assert_string_equals("", err$)
  ut_assert_equals(1, pp_indent_sz)

  parse_cmdline("--indent " + input_file$)
  ut_assert_string_equals("option '--indent' expects number argument >= 0", err$)

  parse_cmdline("--indent=3" + input_file$)
  ut_assert_equals(3, pp_indent_sz)
End Function

Function test_spacing()
  test_setup()

  parse_cmdline("--spacing=0 " + input_file$)

  ut_assert_string_equals("", err$)
  ut_assert_equals(0, pp_spacing)

  parse_cmdline("--spacing=1 " + input_file$)

  ut_assert_string_equals("", err$)
  ut_assert_equals(1, pp_spacing)

  parse_cmdline("--spacing=2 " + input_file$)

  ut_assert_string_equals("", err$)
  ut_assert_equals(2, pp_spacing)

  parse_cmdline("--spacing " + input_file$)
  ut_assert_string_equals("option '--spacing' expects argument of 0, 1 or 2", err$)

  parse_cmdline("--spacing=3" + input_file$)
  ut_assert_string_equals("option '--spacing' expects argument of 0, 1 or 2", err$)
End Function

Function test_output_file()
  test_setup()

  parse_cmdline(input_file$ + " " + output_file$)

  ut_assert_string_equals("", err$)
  ut_assert_string_equals("input.bas", mbt_in$)
  ut_assert_string_equals("output.bas", mbt_out$)
End Function

Function test_unquoted_output_file()
  test_setup()

  parse_cmdline(input_file$ + " output.bas")

  ut_assert_string_equals("output file name must be quoted", err$)
End Function

Function test_unknown_option()
  test_setup()

  parse_cmdline("--wombat " + input_file$)

  ut_assert_string_equals("option '--wombat' is unknown", err$)
End Function

Function test_too_many_arguments()
  test_setup()

  parse_cmdline(input_file$ + " " + output_file$ + " wombat")

  ut_assert_string_equals("unexpected argument 'wombat'", err$)
End Function

Function test_everything()
  test_setup()

  parse_cmdline("-f -C -e=1 -i=2 -s=0 -c=1 " + input_file$ + " " + output_file$)

  ut_assert_string_equals("", err$)
  ut_assert_equals(1, mbt_format_only)
  ut_assert_string_equals("input.bas", mbt_in$)
  ut_assert_string_equals("output.bas", mbt_out$)
  ut_assert_equals(1, pp_colour)
  ut_assert_equals(1, pp_comments)
  ut_assert_equals(1, pp_empty_lines)
  ut_assert_equals(2, pp_indent_sz)
  ut_assert_equals(0, pp_spacing)
End Function

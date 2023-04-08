' Copyright (c) 2020-2022 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

Option Explicit On
Option Default Integer

#Include "../../splib/system.inc"
#Include "../../splib/array.inc"
#Include "../../splib/list.inc"
#Include "../../splib/string.inc"
#Include "../../splib/file.inc"
#Include "../../splib/set.inc"
#Include "../../splib/map.inc"
#Include "../../splib/vt100.inc"
#Include "../../sptest/unittest.inc"
#Include "../../common/sptools.inc"
#Include "../keywords.inc"
#Include "../lexer.inc"
#Include "../options.inc"
#Include "../defines.inc"
#Include "../cmdline.inc"

Const INPUT_FILE$ = "input.bas"
Const OUTPUT_FILE$ = "output.bas"

add_test("test_no_input_file")
add_test("test_input_file")
add_test("test_colour")
add_test("test_crunch")
add_test("test_define")
add_test("test_no_comments")
add_test("test_empty_lines")
add_test("test_format_only")
add_test("test_include_only")
add_test("test_indent")
add_test("test_keywords")
add_test("test_spacing")
add_test("test_output_file")
add_test("test_unknown_option")
add_test("test_too_many_arguments")
add_test("test_incompatible_arguments")
add_test("test_everything")

run_tests()

End

Sub setup_test()
  opt.init()
  def.init()
End Sub

Sub test_no_input_file()
  cli.parse("-f")

  assert_error("no input file specified")
End Sub

Sub test_input_file()
  ' Given unquoted filename.
  cli.parse(INPUT_FILE$)
  assert_no_error()
  assert_string_equals("input.bas", opt.infile$)

  ' Given quoted multi-word filename.
  cli.parse(str.quote$("my input.bas"))
  assert_no_error()
  assert_string_equals("my input.bas", opt.infile$)

  ' Given unquoted hyphenated filename.
  cli.parse("my-input.bas")
  assert_no_error()
  assert_string_equals("my-input.bas", opt.infile$)

  ' Given unquoted file path.
  cli.parse("my/input.bas")
  assert_no_error()
  assert_string_equals("my/input.bas", opt.infile$)
End Sub

Sub test_colour()
  cli.parse("--colour " + INPUT_FILE$)
  assert_no_error()
  assert_int_equals(1, opt.colour)

  cli.parse("-C=1 " + INPUT_FILE$)
  assert_error("option -C does not expect argument")
End Sub

Sub test_crunch()
  opt.comments = 999
  opt.empty_lines = 999
  opt.indent_sz = 999
  opt.spacing = 999

  cli.parse("--crunch " + INPUT_FILE$)

  assert_no_error()
  assert_int_equals(0, opt.comments)
  assert_int_equals(0, opt.empty_lines)
  assert_int_equals(0, opt.indent_sz)
  assert_int_equals(0, opt.spacing)

  cli.parse("--crunch=1 " + INPUT_FILE$)
  assert_error("option --crunch does not expect argument")
End Sub

Sub test_define()
  cli.parse("-Dfoo " + INPUT_FILE$)

  assert_no_error()
  assert_int_neq(-1, set.get%(def.defines$(), "foo"))

  setup_test()
  cli.parse("-D " + INPUT_FILE$)

  assert_error("option -D<id> expects id")
  assert_int_equals(0, set.size%(def.defines$()))

  setup_test()
  cli.parse("-Dfoo=bar " + INPUT_FILE$)

  assert_error("option -D<id> does not expect argument")
  assert_int_equals(0, set.size%(def.defines$()))
End Sub

Sub test_no_comments()
  opt.comments = 999
  cli.parse("--no-comments " + INPUT_FILE$)
  assert_no_error()
  assert_int_equals(0, opt.comments)

  opt.comments = 999
  cli.parse("-n " + INPUT_FILE$)
  assert_no_error()
  assert_int_equals(0, opt.comments)

  cli.parse("--no-comments=1" + INPUT_FILE$)
  assert_error("option --no-comments does not expect argument")
End Sub

Sub test_empty_lines()
  cli.parse("--empty-lines=0 " + INPUT_FILE$)
  assert_no_error()
  assert_int_equals(0, opt.empty_lines)

  cli.parse("--empty-lines=1 " + INPUT_FILE$)
  assert_no_error()
  assert_int_equals(1, opt.empty_lines)

  cli.parse("--empty-lines " + INPUT_FILE$)
  assert_error("option --empty-lines expects {0|1} argument")

  cli.parse("--empty-lines=3" + INPUT_FILE$)
  assert_error("option --empty-lines expects {0|1} argument")
End Sub

Sub test_format_only()
  cli.parse("--format-only " + INPUT_FILE$)
  assert_no_error()
  assert_int_equals(1, opt.format_only)

  cli.parse("-f=1 " + INPUT_FILE$)
  assert_error("option -f does not expect argument")
End Sub

Sub test_include_only()
  cli.parse("--include-only " + INPUT_FILE$)
  assert_no_error()
  assert_int_equals(1, opt.include_only)

  cli.parse("-I=1 " + INPUT_FILE$)
  assert_error("option -I does not expect argument")
End Sub

Sub test_indent()
  cli.parse("--indent=0 " + INPUT_FILE$)
  assert_no_error()
  assert_int_equals(0, opt.indent_sz)

  cli.parse("--indent=1 " + INPUT_FILE$)
  assert_no_error()
  assert_int_equals(1, opt.indent_sz)

  cli.parse("--indent " + INPUT_FILE$)
  assert_error("option --indent expects <number> argument")

  cli.parse("--indent=3 " + INPUT_FILE$)
  assert_no_error()
  assert_int_equals(3, opt.indent_sz)
End Sub

Sub test_keywords()
  cli.parse("--keywords=l " + INPUT_FILE$)
  assert_no_error()
  assert_int_equals(0, opt.keywords)

  cli.parse("--keywords=p " + INPUT_FILE$)
  assert_no_error()
  assert_int_equals(1, opt.keywords)

  cli.parse("--keywords=u " + INPUT_FILE$)
  assert_no_error()
  assert_int_equals(2, opt.keywords)

  cli.parse("--keywords " + INPUT_FILE$)
  assert_error("option --keywords expects {l|p|u} argument")

  cli.parse("--keywords=3 " + INPUT_FILE$)
  assert_error("option --keywords expects {l|p|u} argument")
End Sub

Sub test_spacing()
  cli.parse("--spacing=0 " + INPUT_FILE$)
  assert_no_error()
  assert_int_equals(0, opt.spacing)

  cli.parse("--spacing=1 " + INPUT_FILE$)
  assert_no_error()
  assert_int_equals(1, opt.spacing)

  cli.parse("--spacing=2 " + INPUT_FILE$)
  assert_no_error()
  assert_int_equals(2, opt.spacing)

  cli.parse("--spacing " + INPUT_FILE$)
  assert_error("option --spacing expects {0|1|2} argument")

  cli.parse("--spacing=3 " + INPUT_FILE$)
  assert_error("option --spacing expects {0|1|2} argument")
End Sub

Sub test_output_file()
  ' Test with unquoted filename.
  cli.parse(INPUT_FILE$ + " " + OUTPUT_FILE$)

  assert_no_error()
  assert_string_equals("input.bas", opt.infile$)
  assert_string_equals("output.bas", opt.outfile$)

  ' Test with quoted multi-word filename.
  cli.parse(INPUT_FILE$ + " " + str.quote$("my output.bas"))

  assert_no_error()
  assert_string_equals("input.bas", opt.infile$)
  assert_string_equals("my output.bas", opt.outfile$)
End Sub

Sub test_unknown_option()
  cli.parse("--wombat " + INPUT_FILE$)

  assert_error("option --wombat is unknown")
End Sub

Sub test_too_many_arguments()
  cli.parse(INPUT_FILE$ + " " + OUTPUT_FILE$ + " wombat")

  assert_error("unexpected argument 'wombat'")
End Sub

Sub test_incompatible_arguments()
  cli.parse("-f -I " + INPUT_FILE$ + " " + OUTPUT_FILE$)

  assert_error("--format-only and --include-only options are mutually exclusive")
End Sub

Sub test_everything()
  cli.parse("-f -C -e=1 -i=2 -s=0 -n " + INPUT_FILE$ + " " + OUTPUT_FILE$)

  assert_no_error()
  assert_int_equals(1, opt.format_only)
  assert_string_equals("input.bas", opt.infile$)
  assert_string_equals("output.bas", opt.outfile$)
  assert_int_equals(1, opt.colour)
  assert_int_equals(0, opt.comments)
  assert_int_equals(1, opt.empty_lines)
  assert_int_equals(2, opt.indent_sz)
  assert_int_equals(0, opt.spacing)
End Sub

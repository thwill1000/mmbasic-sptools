' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07.06

Option Explicit On
Option Default Integer

Const MAX_NUM_FILES = 5
Dim in.num_open_files = 1

#Include "../../splib/system.inc"
#Include "../../splib/array.inc"
#Include "../../splib/list.inc"
#Include "../../splib/string.inc"
#Include "../../splib/file.inc"
#Include "../../splib/map.inc"
#Include "../../splib/set.inc"
#Include "../../splib/vt100.inc"
#Include "../../sptest/unittest.inc"
#Include "../../common/sptools.inc"
#Include "../keywords.inc"
#Include "../lexer.inc"
#Include "../options.inc"
#Include "../trans.inc"

keywords.init()

add_test("test_transpile_includes")
add_test("test_parse_replace")
add_test("test_parse_replace_given_errors")
add_test("test_parse_unreplace")
add_test("test_parse_unreplace_given_errs")
add_test("test_parse_given_too_many_rpl")
add_test("test_apply_replace")
add_test("test_apply_replace_groups")
add_test("test_apply_replace_patterns")
add_test("test_replace_fails_if_too_long")
add_test("test_replace_with_fewer_tokens")
add_test("test_replace_with_more_tokens")
add_test("test_replace_given_new_rpl")
add_test("test_apply_unreplace")
add_test("test_clear_given_flag_set")
add_test("test_clear_given_flag_unset")
add_test("test_clear_given_flag_too_long")
add_test("test_clear_is_case_insensitive")
add_test("test_comment_if")
add_test("test_comment_if_not")
add_test("test_uncomment_if")
add_test("test_uncomment_if_not")
add_test("test_unknown_directive")
add_test("test_remove_if")
add_test("test_remove_if_not")
add_test("test_ifdef_given_set")
add_test("test_ifdef_given_unset")
add_test("test_ifdef_given_0_args")
add_test("test_ifdef_given_2_args")
add_test("test_ifdef_is_case_insensitive")
add_test("test_ifdef_nested_1")
add_test("test_ifdef_nested_2")
add_test("test_ifdef_nested_3")
add_test("test_ifdef_nested_4")
add_test("test_ifndef_given_set")
add_test("test_ifndef_given_unset")
add_test("test_ifndef_given_0_args")
add_test("test_ifndef_given_2_args")
add_test("test_ifndef_is_case_insensitive")
add_test("test_ifndef_nested_1")
add_test("test_ifndef_nested_2")
add_test("test_ifndef_nested_3")
add_test("test_ifndef_nested_4")
add_test("test_set_given_flag_set")
add_test("test_set_given_flag_unset")
add_test("test_set_given_flag_too_long")
add_test("test_set_is_case_insensitive")
add_test("test_omit_directives_from_output")
add_test("test_unbalanced_endif")
add_test("test_sptrans_flag_is_set")
add_test("test_error_directive")
add_test("test_omit_and_line_spacing")
add_test("test_comments_directive")

run_tests()

End

Sub setup_test()
  opt.init()

  ' TODO: extract into trans.init() or trans.reset().
  tr.clear_replacements()
  tr.include$ = ""
  tr.omit_flag% = 0
  tr.empty_line_flag% = 0
  tr.omitted_line_flag% = 0

  Local i%, j%
  For i% = Bound(tr.num_comments(), 0) To Bound(tr.num_comments(), 1)
    tr.num_comments(i%) = 0
  Next
  For i% = Bound(tr.if_stack(), 0) To Bound(tr.if_stack(), 1)
    For j% = Bound(tr.if_stack(), 0) To Bound(tr.if_stack(), 2)
      tr.if_stack(i%, j%) = 0
    Next
    tr.if_stack_sz(i%) = 0
  Next
End Sub

Sub test_transpile_includes()
  ' Given #INCLUDE statement.
  setup_test()
  lx.parse_basic("#include " + str.quote$("foo/bar.inc"))
  assert_int_equals(2, tr.transpile_includes%())
  assert_no_error()
  assert_string_equals("foo/bar.inc", tr.include$)

  ' Given #INCLUDE statement preceded by whitespace.
  setup_test()
  lx.parse_basic("  #include " + str.quote$("foo/bar.inc"))
  assert_int_equals(2, tr.transpile_includes%())
  assert_no_error()
  assert_string_equals("foo/bar.inc", tr.include$)

  ' Given #INCLUDE statement followed by whitespace.
  setup_test()
  lx.parse_basic("#include " + str.quote$("foo/bar.inc") + "  ")
  assert_int_equals(2, tr.transpile_includes%())
  assert_no_error()
  assert_string_equals("foo/bar.inc", tr.include$)

  ' Given other statement.
  setup_test()
  lx.parse_basic("Print " + str.quote$("Hello World"))
  assert_int_equals(1, tr.transpile_includes%())
  assert_no_error()
  assert_string_equals("", tr.include$)

  ' Given missing argument.
  setup_test()
  lx.parse_basic("#include")
  assert_int_equals(0, tr.transpile_includes%())
  assert_error("#INCLUDE expects a <file> argument")
  assert_string_equals("", tr.include$)

  ' Given non-string argument.
  setup_test()
  lx.parse_basic("#include foo")
  assert_int_equals(0, tr.transpile_includes%())
  assert_error("#INCLUDE expects a <file> argument")
  assert_string_equals("", tr.include$)

  ' Given too many arguments.
  setup_test()
  lx.parse_basic("#include " + str.quote$("foo/bar.inc") + " " + str.quote$("wombat.inc"))
  assert_int_equals(0, tr.transpile_includes%())
  assert_error("#INCLUDE expects a <file> argument")
  assert_string_equals("", tr.include$)

  ' Given #INCLUDE is not the first token on the line.
  setup_test()
  lx.parse_basic("Dim i% : #include " + str.quote$("foo/bar.inc"))
  assert_int_equals(1, tr.transpile_includes%())
  assert_no_error()
  assert_string_equals("", tr.include$)
End Sub

Sub test_parse_replace()
  Local ok%

  ok% = parse_and_transpile%("'!replace DEF Sub")
  assert_no_error()
  expect_replacement(0, "def", "Sub")

  ok% = parse_and_transpile%("'!replace ENDPROC { End Sub }")
  assert_no_error()
  expect_replacement(1, "endproc", "End|Sub")

  ok% = parse_and_transpile%("'!replace { THEN ENDPROC } { Then Exit Sub }")
  assert_no_error()
  expect_replacement(2, "then|endproc", "Then|Exit|Sub")

  ok% = parse_and_transpile%("'!replace GOTO%% { Goto %1 }")
  assert_no_error()
  expect_replacement(3, "goto%%", "Goto|%1")

  ok% = parse_and_transpile%("'!replace { THEN %% } { Then Goto %1 }")
  assert_no_error()
  expect_replacement(4, "then|%%", "Then|Goto|%1")

  ok% = parse_and_transpile%("'!replace '%% { CRLF$ %1 }")
  assert_no_error()
  expect_replacement(5, "'%%", "CRLF$|%1")

  ok% = parse_and_transpile%("'!replace &%h &h%1")
  assert_no_error()
  expect_replacement(6, "&%h", "&h%1")

  ok% = parse_and_transpile%("'!replace foo")
  ok% = tr.transpile%()
  assert_no_error()
  expect_replacement(7, "foo", "")

  ok% = parse_and_transpile%("'!replace {foo}")
  ok% = tr.transpile%()
  assert_no_error()
  expect_replacement(7, Chr$(0), Chr$(0))
  expect_replacement(8, "foo", "")

  ok% = parse_and_transpile%("'!replace foo {}")
  ok% = tr.transpile%()
  assert_no_error()
  expect_replacement(8, Chr$(0), Chr$(0))
  expect_replacement(9, "foo", "")
End Sub

Sub test_parse_replace_given_errors()
  Local ok%

  ok% = parse_and_transpile%("'!replace")
  ok% = tr.transpile%()
  assert_int_equals(0, tr.num_replacements%)
  assert_error("!replace directive expects <from> argument")

  ok% = parse_and_transpile%("'!replace {}")
  ok% = tr.transpile%()
  assert_int_equals(0, tr.num_replacements%)
  assert_error("!replace directive has empty <from> group")

  ok% = parse_and_transpile%("'!replace {} y")
  ok% = tr.transpile%()
  assert_int_equals(0, tr.num_replacements%)
  assert_error("!replace directive has empty <from> group")

  ok% = parse_and_transpile%("'!replace { x y")
  ok% = tr.transpile%()
  assert_int_equals(0, tr.num_replacements%)
  assert_error("!replace directive has missing '}'")

  ok% = parse_and_transpile%("'!replace { x } { y z")
  ok% = tr.transpile%()
  assert_int_equals(0, tr.num_replacements%)
  assert_error("!replace directive has missing '}'")

  ok% = parse_and_transpile%("'!replace { x } { y } z")
  ok% = tr.transpile%()
  assert_int_equals(0, tr.num_replacements%)
  assert_error("!replace directive has too many arguments")

  ok% = parse_and_transpile%("'!replace { x } { y } { z }")
  ok% = tr.transpile%()
  assert_int_equals(0, tr.num_replacements%)
  assert_error("!replace directive has too many arguments")

  ok% = parse_and_transpile%("'!replace { {")
  ok% = tr.transpile%()
  assert_int_equals(0, tr.num_replacements%)
  assert_error("!replace directive has unexpected '{'")

  ok% = parse_and_transpile%("'!replace foo }")
  ok% = tr.transpile%()
  assert_int_equals(0, tr.num_replacements%)
  assert_error("!replace directive has unexpected '}'")
End Sub

Sub test_parse_given_too_many_rpl()
  Local i%, ok%

  For i% = 0 To tr.MAX_REPLACEMENTS% - 1
    ok% = parse_and_transpile%("'!replace a" + Str$(i%) + " b")
  Next
  assert_no_error()

  ok% = parse_and_transpile%("'!replace foo bar")
  assert_error("!replace directive too many replacements (max 200)")
End Sub

Sub test_parse_unreplace()
  Local ok%

  ok% = parse_and_transpile%("'!replace foo bar")
  ok% = parse_and_transpile%("'!replace wom bat")
  ok% = parse_and_transpile%("'!unreplace foo")

  assert_no_error()
  assert_int_equals(2, tr.num_replacements%)
  expect_replacement(0, Chr$(0), Chr$(0))
  expect_replacement(1, "wom", "bat")
End Sub

Sub test_parse_unreplace_given_errs()
  Local ok%

  ' Test given missing argument to directive.
  ok% = parse_and_transpile%("'!unreplace")
  assert_error("!unreplace directive expects <from> argument")

  ' Test given directive has too many arguments.
  ok% = parse_and_transpile%("'!unreplace { a b } c")
  assert_error("!unreplace directive has too many arguments")

  ' Test given replacement not present.
  ok% = parse_and_transpile%("'!replace wom bat")
  ok% = parse_and_transpile%("'!unreplace foo")
  assert_error("!unreplace directive could not find 'foo'")
  assert_int_equals(1, tr.num_replacements%)
  expect_replacement(0, "wom", "bat")
End Sub

Sub test_apply_replace()
  Local ok%

  ok% = parse_and_transpile%("'!replace x      y")
  ok% = parse_and_transpile%("'!replace &hFFFF z")
  ok% = parse_and_transpile%("Dim x = &hFFFF ' comment")

  expect_tokens(5)
  expect_tk(0, TK_KEYWORD, "Dim")
  expect_tk(1, TK_IDENTIFIER, "y")
  expect_tk(2, TK_SYMBOL, "=")
  expect_tk(3, TK_IDENTIFIER, "z")
  expect_tk(4, TK_COMMENT, "' comment")
  assert_string_equals("Dim y = z ' comment", lx.line$)
End Sub

Sub test_apply_replace_groups()
  Local ok%

  ok% = parse_and_transpile%("'!replace ab { cd ef }")
  ok% = parse_and_transpile%("ab gh ij")
  expect_tokens(4)
  expect_tk(0, TK_IDENTIFIER, "cd")
  expect_tk(1, TK_IDENTIFIER, "ef")
  expect_tk(2, TK_IDENTIFIER, "gh")
  expect_tk(3, TK_IDENTIFIER, "ij")

  setup_test()
  ok% = parse_and_transpile%("'!replace {ab cd} ef")
  ok% = parse_and_transpile%("ab cd gh ij")
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "ef")
  expect_tk(1, TK_IDENTIFIER, "gh")
  expect_tk(2, TK_IDENTIFIER, "ij")
End Sub

Sub test_apply_replace_patterns()
  Local ok%

  setup_test()
  ok% = parse_and_transpile%("'!replace { DEF PROC%% } { SUB proc%1 }")
  ok% = parse_and_transpile%("foo DEF PROCWOMBAT bar")
  expect_tokens(4)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_KEYWORD,    "SUB")
  expect_tk(2, TK_IDENTIFIER, "procWOMBAT") ' Note don't want to change case of WOMBAT.
  expect_tk(3, TK_IDENTIFIER, "bar")

  setup_test()
  ok% = parse_and_transpile%("'!replace GOTO%d { Goto %1 }")
  ok% = parse_and_transpile%("foo GOTO1234 bar")
  expect_tokens(4)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_KEYWORD   , "Goto")
  expect_tk(2, TK_NUMBER,     "1234")
  expect_tk(3, TK_IDENTIFIER, "bar") 

  setup_test()
  ok% = parse_and_transpile%("'!replace { THEN %d } { Then Goto %1 }")

  ' Test %d pattern matches decimal digits ...
  ok% = parse_and_transpile%("foo THEN 1234 bar")
  expect_tokens(5)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_KEYWORD   , "Then")
  expect_tk(2, TK_KEYWORD   , "Goto")
  expect_tk(3, TK_NUMBER,     "1234")
  expect_tk(4, TK_IDENTIFIER, "bar") 

  ' ... but it should not match other characters.
  ok% = parse_and_transpile%("foo THEN wombat bar")
  expect_tokens(4)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_KEYWORD   , "THEN")
  expect_tk(2, TK_IDENTIFIER, "wombat")
  expect_tk(3, TK_IDENTIFIER, "bar") 

  setup_test()
  ok% = parse_and_transpile%("'!replace { PRINT '%% } { ? : ? %1 }")
  ok% = parse_and_transpile%("foo PRINT '" + str.quote$("wombat") + " bar")
  expect_tokens(6)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_SYMBOL,     "?")
  expect_tk(2, TK_SYMBOL,     ":")
  expect_tk(3, TK_SYMBOL,     "?")
  expect_tk(4, TK_STRING,     str.quote$("wombat"))
  expect_tk(5, TK_IDENTIFIER, "bar")

  setup_test()
  ok% = parse_and_transpile%("'!replace '%% { : ? %1 }")
  ok% = parse_and_transpile%("foo PRINT '" + str.quote$("wombat") + " bar")
  expect_tokens(6)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_KEYWORD,    "PRINT")
  expect_tk(2, TK_SYMBOL,     ":")
  expect_tk(3, TK_SYMBOL,     "?")
  expect_tk(4, TK_STRING,     str.quote$("wombat"))
  expect_tk(5, TK_IDENTIFIER, "bar")

  setup_test()
  ok% = parse_and_transpile%("'!replace REM%% { ' %1 }")
  ok% = parse_and_transpile%("foo REM This is a comment")
  expect_tokens(2)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_COMMENT, "' This is a comment")

  setup_test()
  ok% = parse_and_transpile%("'!replace { Spc ( } { Space$ ( }")
  ok% = parse_and_transpile%("foo Spc(5) bar")
  expect_tokens(6)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_KEYWORD,    "Space$")
  expect_tk(2, TK_SYMBOL,     "(")
  expect_tk(3, TK_NUMBER,     "5")
  expect_tk(4, TK_SYMBOL,     ")")
  expect_tk(5, TK_IDENTIFIER, "bar")

  ' Test %h pattern matches hex digits ...
  setup_test()
  ok% = parse_and_transpile%("'!replace GOTO%h { Goto %1 }")
  ok% = parse_and_transpile%("foo GOTOabcdef0123456789 bar")
  expect_tokens(4)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_KEYWORD,    "Goto")
  expect_tk(2, TK_IDENTIFIER, "abcdef0123456789")
  expect_tk(3, TK_IDENTIFIER, "bar")

  ' ... but it should not match other characters.
  ok% = parse_and_transpile%("foo GOTOxyz bar")
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_IDENTIFIER, "GOTOxyz")
  expect_tk(2, TK_IDENTIFIER, "bar")
End Sub

Sub test_replace_fails_if_too_long()
  Local ok%, s$

  ok% = parse_and_transpile%("'!replace foo foobar")

  ' Test where replaced string should be 255 characters.
  s$ = String$(248, "a")
  Cat s$, " foo"
  assert_int_equals(252, Len(s$))
  ok% = parse_and_transpile%(s$)
  ok% = tr.transpile%()
  assert_no_error()
  expect_tokens(2)
  expect_tk(0, TK_IDENTIFIER, String$(248, "a"))
  expect_tk(1, TK_IDENTIFIER, "foobar")


  ' Test where replaced string should be 256 characters.
  s$ = String$(251, "a")
  Cat s$, " foo"
  assert_int_equals(255, Len(s$))
  ok% = parse_and_transpile%(s$)
  ok% = tr.transpile%()
  assert_error("applying replacement makes line > 255 characters")
End Sub

Sub test_replace_with_fewer_tokens()
  Local ok%

  ' Replace 1 token with 0.
  ok% = parse_and_transpile%("'!replace bar")
  ok% = parse_and_transpile%("foo bar wom")
  expect_tokens(2)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_IDENTIFIER, "wom")

  ' Removal of all tokens.
  setup_test()
  ok% = parse_and_transpile%("'!replace bar")
  ok% = parse_and_transpile%("bar bar bar")
  expect_tokens(0)

  ' Replace 2 tokens with 1.
  setup_test()
  ok% = parse_and_transpile%("'!replace { foo bar } wom")
  ok% = parse_and_transpile%("foo bar foo bar snafu")
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "wom")
  expect_tk(1, TK_IDENTIFIER, "wom")
  expect_tk(2, TK_IDENTIFIER, "snafu")

  ' Note that we don't end up with the single token "foo" because once we have
  ' applied a replacement we do not recursively apply that replacement to the
  ' already replaced text.
  setup_test()
  ok% = parse_and_transpile%("'!replace { foo bar } foo")
  ok% = parse_and_transpile%("foo bar bar")
  expect_tokens(2)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_IDENTIFIER, "bar")

  ' Replace 3 tokens with 1 - again note we don't just end up with "foo".
  setup_test()
  ok% = parse_and_transpile%("'!replace { foo bar wom } foo")
  ok% = parse_and_transpile%("foo bar wom bar wom")
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_IDENTIFIER, "bar")
  expect_tk(2, TK_IDENTIFIER, "wom")

  ' Replace 3 tokens with 2 - and again we don't just end up with "foo bar".
  setup_test()
  ok% = parse_and_transpile%("'!replace { foo bar wom } { foo bar }")
  ok% = parse_and_transpile%("foo bar wom wom")
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_IDENTIFIER, "bar")
  expect_tk(2, TK_IDENTIFIER, "wom")
End Sub

Sub test_replace_with_more_tokens()
  Local ok%

  ' Replace 1 token with 2 - note that we don't get infinite recursion because
  ' once we have applied the replacement text we not not recusively apply the
  ' replacement to the already replaced text.
  ok% = parse_and_transpile%("'!replace foo { foo bar }")
  ok% = parse_and_transpile%("foo wom")
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_IDENTIFIER, "bar")
  expect_tk(2, TK_IDENTIFIER, "wom")

  setup_test()
  ok% = parse_and_transpile%("'!replace foo { bar foo }")
  ok% = parse_and_transpile%("foo wom foo")
  expect_tokens(5)
  expect_tk(0, TK_IDENTIFIER, "bar")
  expect_tk(1, TK_IDENTIFIER, "foo")
  expect_tk(2, TK_IDENTIFIER, "wom")
  expect_tk(3, TK_IDENTIFIER, "bar")
  expect_tk(4, TK_IDENTIFIER, "foo")

  ' Ensure replacement applied for multiple matches.
  setup_test()
  ok% = parse_and_transpile%("'!replace foo { bar foo }")
  ok% = parse_and_transpile%("foo foo")
  expect_tokens(4)
  expect_tk(0, TK_IDENTIFIER, "bar")
  expect_tk(1, TK_IDENTIFIER, "foo")
  expect_tk(2, TK_IDENTIFIER, "bar")
  expect_tk(3, TK_IDENTIFIER, "foo")

  ' Replace 3 tokens with 4.
  setup_test()
  ok% = parse_and_transpile%("'!replace { foo bar wom } { foo bar wom foo }")
  ok% = parse_and_transpile%("foo bar wom bar wom")
  expect_tokens(6)
  expect_tk(0, TK_IDENTIFIER, "foo")
  expect_tk(1, TK_IDENTIFIER, "bar")
  expect_tk(2, TK_IDENTIFIER, "wom")
  expect_tk(3, TK_IDENTIFIER, "foo")
  expect_tk(4, TK_IDENTIFIER, "bar")
  expect_tk(5, TK_IDENTIFIER, "wom")
End Sub

Sub test_replace_given_new_rpl()
  Local ok%

  ok% = parse_and_transpile%("'!replace foo bar")
  ok% = parse_and_transpile%("foo wom bill")
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "bar")
  expect_tk(1, TK_IDENTIFIER, "wom")
  expect_tk(2, TK_IDENTIFIER, "bill")

  ok% = parse_and_transpile%("'!replace foo snafu")
  ok% = parse_and_transpile%("foo wom bill")
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "snafu")
  expect_tk(1, TK_IDENTIFIER, "wom")
  expect_tk(2, TK_IDENTIFIER, "bill")
End Sub

Sub test_apply_unreplace()
  Local ok%

  ok% = parse_and_transpile%("'!replace foo bar")
  ok% = parse_and_transpile%("'!replace wom bat")
  ok% = parse_and_transpile%("'!replace bill ben")
  expect_replacement(0, "foo", "bar")
  expect_replacement(1, "wom", "bat")
  expect_replacement(2, "bill", "ben")
  expect_replacement(3, "", "")

  ok% = parse_and_transpile%("foo wom bill")
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "bar")
  expect_tk(1, TK_IDENTIFIER, "bat")
  expect_tk(2, TK_IDENTIFIER, "ben")

  ok% = parse_and_transpile%("'!unreplace wom")
  assert_no_error()
  expect_replacement(0, "foo", "bar")
  expect_replacement(1, Chr$(0), Chr$(0))
  expect_replacement(2, "bill", "ben")
  expect_replacement(3, "", "")

  ok% = parse_and_transpile%("foo wom bill")
  expect_tokens(3)
  expect_tk(0, TK_IDENTIFIER, "bar")
  expect_tk(1, TK_IDENTIFIER, "wom")
  expect_tk(2, TK_IDENTIFIER, "ben")
End Sub

Sub test_clear_given_flag_set()
  Local ok%

  opt.set_flag("foo")
  opt.set_flag("bar")

  ok% = parse_and_transpile%("'!clear foo")
  assert_int_equals(0, opt.is_flag_set%("foo"))
  assert_int_equals(1, opt.is_flag_set%("bar"))

  ok% = parse_and_transpile%("'!clear bar")
  assert_int_equals(0, opt.is_flag_set%("foo"))
  assert_int_equals(0, opt.is_flag_set%("bar"))
End Sub

Sub test_clear_given_flag_unset()
  Local ok%

  ok% = parse_and_transpile%("'!clear foo")
  assert_int_equals(0, ok%)
  assert_error("!clear directive flag 'foo' is not set")

  ok% = parse_and_transpile%("'!clear BAR")
  assert_int_equals(0, ok%)
  assert_error("!clear directive flag 'BAR' is not set")
End Sub

Sub test_clear_given_flag_too_long()
  Local ok%

  ok% = parse_and_transpile%("'!clear flag5678901234567890123456789012345678901234567890123456789012345")
  assert_int_equals(0, ok%)
  assert_error("!clear directive flag too long, max 64 chars")
End Sub

Sub test_clear_is_case_insensitive()
  Local ok%

  opt.set_flag("foo")
  opt.set_flag("BAR")

  ok% = parse_and_transpile%("'!clear FOO")
  assert_int_equals(0, opt.is_flag_set%("foo"))
  assert_int_equals(1, opt.is_flag_set%("BAR"))

  ok% = parse_and_transpile%("'!clear bar")
  assert_int_equals(0, opt.is_flag_set%("foo"))
  assert_int_equals(0, opt.is_flag_set%("BAR"))
End Sub

Sub test_comment_if()
  Local ok%

  ' 'foo' is set, code inside !comment_if block should be commented.
  ok% = parse_and_transpile%("'!set foo")
  ok% = parse_and_transpile%("'!comment_if foo")
  ok% = parse_and_transpile%("one")
  expect_tokens(1)
  expect_tk(0, TK_COMMENT, "' one")
  ok% = parse_and_transpile%("two")
  expect_tokens(1)
  expect_tk(0, TK_COMMENT, "' two")
  ok% = parse_and_transpile%("'!endif")

  ' Code outside the block should not be commented.
  ok% = parse_and_transpile%("three")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "three")
End Sub

Sub test_comment_if_not()
  Local ok%

  ' 'foo' is NOT set, code inside !comment_if NOT block should be commented.
  ok% = parse_and_transpile%("'!comment_if not foo")
  ok% = parse_and_transpile%("one")
  expect_tokens(1)
  expect_tk(0, TK_COMMENT, "' one")
  ok% = parse_and_transpile%("two")
  expect_tokens(1)
  expect_tk(0, TK_COMMENT, "' two")
  ok% = parse_and_transpile%("'!endif")

  ' 'foo' is set, code inside !comment_if NOT block should NOT be commented.
  ok% = parse_and_transpile%("'!set foo")
  ok% = parse_and_transpile%("'!comment_if not foo")
  ok% = parse_and_transpile%("three")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "three")
  ok% = parse_and_transpile%("'!endif")
End Sub

Sub test_uncomment_if()
  Local ok%

  ' 'foo' is set, code inside !uncomment_if block should be uncommented.
  ok% = parse_and_transpile%("'!set foo")
  ok% = parse_and_transpile%("'!uncomment_if foo")

  ok% = parse_and_transpile%("' one")
  assert_string_equals(" one", lx.line$)
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "one")

  ok% = parse_and_transpile%("REM two")
  assert_string_equals(" two", lx.line$)
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "two")

  ok% = parse_and_transpile%("'' three")
  assert_string_equals("' three", lx.line$)
  expect_tokens(1)
  expect_tk(0, TK_COMMENT, "' three")

  ok% = parse_and_transpile%("'!endif")

  ' Code outside the block should not be uncommented.
  ok% = parse_and_transpile%("' four")
  assert_string_equals("' four", lx.line$)
  expect_tokens(1)
  expect_tk(0, TK_COMMENT, "' four")
End Sub

Sub test_uncomment_if_not()
  Local ok%

  ' 'foo' is NOT set, code inside !uncomment_if NOT block should be uncommented.
  ok% = parse_and_transpile%("'!uncomment_if not foo")

  ok% = parse_and_transpile%("' one")
  assert_string_equals(" one", lx.line$)
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "one")

  ok% = parse_and_transpile%("REM two")
  assert_string_equals(" two", lx.line$)
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "two")

  ok% = parse_and_transpile%("'' three")
  assert_string_equals("' three", lx.line$)
  expect_tokens(1)
  expect_tk(0, TK_COMMENT, "' three")
  ok% = parse_and_transpile%("'!endif")

  ' 'foo' is set, code inside !uncomment_if NOT block should NOT be uncommented.
  ok% = parse_and_transpile%("'!set foo")
  ok% = parse_and_transpile%("'!uncomment_if not foo")
  ok% = parse_and_transpile%("' four")
  assert_string_equals("' four", lx.line$)
  expect_tokens(1)
  expect_tk(0, TK_COMMENT, "' four")
  ok% = parse_and_transpile%("'!endif")
End Sub

Sub test_remove_if()
  Local ok%

  ' 'foo' is set, code inside !remove_if block should be omitted.
  ok% = parse_and_transpile%("'!set foo")
  ok% = parse_and_transpile%("'!remove_if foo")
  ok% = parse_and_transpile%("one")
  expect_tokens(0)
  ok% = parse_and_transpile%("two")
  expect_tokens(0)
  ok% = parse_and_transpile%("'!endif")

  ' Code outside the block should not be omitted.
  ok% = parse_and_transpile%("three")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "three")
End Sub

Sub test_remove_if_not()
  Local ok%

  ' 'foo' is not set, code inside !remove_if block should be omitted.
  ok% = parse_and_transpile%("'!remove_if not foo")
  ok% = parse_and_transpile%("one")
  expect_tokens(0)
  ok% = parse_and_transpile%("two")
  expect_tokens(0)
  ok% = parse_and_transpile%("'!endif")

  ' Code outside the block should not be omitted.
  ok% = parse_and_transpile%("three")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "three")
End Sub

Sub test_ifdef_given_set()
  Local ok%

  ' FOO is set so all code within !ifdef FOO is included.
  ok% = parse_and_transpile%("'!set FOO")
  ok% = parse_and_transpile%("'!ifdef FOO")
  ok% = parse_and_transpile%("one")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "one")
  ok% = parse_and_transpile%("two")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "two")
  ok% = parse_and_transpile%("'!endif")
  expect_tokens(0)

  ' Code outside the block is included.
  ok% = parse_and_transpile%("three")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "three")
End Sub

Sub test_ifdef_given_unset()
  Local ok%

  ' FOO is unset so all code within !ifdef FOO is excluded.
  ok% = parse_and_transpile%("'!ifdef FOO")
  ok% = parse_and_transpile%("one")
  expect_tokens(0)
  ok% = parse_and_transpile%("two")
  expect_tokens(0)
  ok% = parse_and_transpile%("'!endif")
  expect_tokens(0)

  ' Code outside the block is included.
  ok% = parse_and_transpile%("three")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "three")
End Sub

Sub test_ifdef_given_0_args()
  Local ok%
  ok% = parse_and_transpile%("'!ifdef")
  assert_int_equals(0, ok%)
  assert_string_equals("!ifdef directive expects 1 argument", sys.err$)
End Sub

Sub test_ifdef_given_2_args()
  Local ok%
  ok% = parse_and_transpile%("'!ifdef not bar")
  assert_int_equals(0, ok%)
  assert_string_equals("!ifdef directive expects 1 argument", sys.err$)
End Sub

Sub test_ifdef_is_case_insensitive()
  Local ok%
  opt.set_flag("foo")
  ok% = parse_and_transpile%("'!ifdef FOO")
  ok% = parse_and_transpile%("one")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "one")
  ok% = parse_and_transpile%("'!endif")
End Sub

Sub test_ifdef_nested_1()
  Local ok%

  ' FOO and BAR are both unset so all code within !ifdef FOO is excluded.
  ok% = parse_and_transpile%("'!ifdef FOO")
  ok% = parse_and_transpile%("one")
  expect_tokens(0)
  ok% = parse_and_transpile%("'!ifdef BAR")
  ok% = parse_and_transpile%("two")
  expect_tokens(0)
  ok% = parse_and_transpile%("'!endif")
  expect_tokens(0)
  ok% = parse_and_transpile%("'!endif")
  expect_tokens(0)

  ' Code outside the block is included.
  ok% = parse_and_transpile%("three")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "three")
End Sub

Sub test_ifdef_nested_2()
  Local ok%

  ' FOO is set and BAR is unset so code within !ifdef BAR is excluded.
  ok% = parse_and_transpile%("'!set FOO")
  ok% = parse_and_transpile%("'!ifdef FOO")
  ok% = parse_and_transpile%("one")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "one")
  ok% = parse_and_transpile%("'!ifdef BAR")
  ok% = parse_and_transpile%("two")
  expect_tokens(0)
  ok% = parse_and_transpile%("'!endif")
  expect_tokens(0)
  ok% = parse_and_transpile%("'!endif")
  expect_tokens(0)

  ' Code outside the block is included.
  ok% = parse_and_transpile%("three")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "three")
End Sub

Sub test_ifdef_nested_3()
  Local ok%

  ' BAR is set and FOO is unset so all code within !ifdef FOO is excluded.
  ok% = parse_and_transpile%("'!set BAR")
  ok% = parse_and_transpile%("'!ifdef FOO")
  ok% = parse_and_transpile%("one")
  expect_tokens(0)
  ok% = parse_and_transpile%("'!ifdef BAR")
  ok% = parse_and_transpile%("two")
  expect_tokens(0)
  ok% = parse_and_transpile%("'!endif")
  expect_tokens(0)
  ok% = parse_and_transpile%("'!endif")
  expect_tokens(0)

  ' Code outside the block is included.
  ok% = parse_and_transpile%("three")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "three")
End Sub

Sub test_ifdef_nested_4()
  Local ok%

  ' FOO and BAR are both set so all code within !ifdef FOO and !ifdef BAR is included.
  ok% = parse_and_transpile%("'!set FOO")
  ok% = parse_and_transpile%("'!set BAR")
  ok% = parse_and_transpile%("'!ifdef FOO")
  ok% = parse_and_transpile%("one")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "one")
  ok% = parse_and_transpile%("'!ifdef BAR")
  ok% = parse_and_transpile%("two")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "two")
  ok% = parse_and_transpile%("'!endif")
  expect_tokens(0)
  ok% = parse_and_transpile%("'!endif")
  expect_tokens(0)

  ' Code outside the block is included.
  ok% = parse_and_transpile%("three")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "three")
End Sub

Sub test_ifndef_given_set()
  Local ok%

  ' FOO is set so all code within !ifndef FOO is excluded.
  ok% = parse_and_transpile%("'!set FOO")
  ok% = parse_and_transpile%("'!ifndef FOO")
  ok% = parse_and_transpile%("one")
  expect_tokens(0)
  ok% = parse_and_transpile%("two")
  expect_tokens(0)
  ok% = parse_and_transpile%("'!endif")
  expect_tokens(0)

  ' Code outside the block is included.
  ok% = parse_and_transpile%("three")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "three")
End Sub

Sub test_ifndef_given_unset()
  Local ok%

  ' FOO is unset so all code within !ifndef FOO is included.
  ok% = parse_and_transpile%("'!ifndef FOO")
  ok% = parse_and_transpile%("one")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "one")
  ok% = parse_and_transpile%("two")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "two")
  ok% = parse_and_transpile%("'!endif")
  expect_tokens(0)

  ' Code outside the block is included.
  ok% = parse_and_transpile%("three")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "three")
End Sub

Sub test_ifndef_given_0_args()
  Local ok%
  ok% = parse_and_transpile%("'!ifndef")
  assert_int_equals(0, ok%)
  assert_string_equals("!ifndef directive expects 1 argument", sys.err$)
End Sub

Sub test_ifndef_given_2_args()
  Local ok%
  ok% = parse_and_transpile%("'!ifndef not bar")
  assert_int_equals(0, ok%)
  assert_string_equals("!ifndef directive expects 1 argument", sys.err$)
End Sub

Sub test_ifndef_is_case_insensitive()
  Local ok%
  opt.set_flag("foo")
  ok% = parse_and_transpile%("'!ifndef FOO")
  ok% = parse_and_transpile%("one")
  expect_tokens(0)
  ok% = parse_and_transpile%("'!endif")
End Sub

Sub test_ifndef_nested_1()
  Local ok%

  ' FOO and BAR are both unset so all code within !ifndef FOO is included.
  ok% = parse_and_transpile%("'!ifndef FOO")
  ok% = parse_and_transpile%("one")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "one")
  ok% = parse_and_transpile%("'!ifndef BAR")
  ok% = parse_and_transpile%("two")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "two")
  ok% = parse_and_transpile%("'!endif")
  expect_tokens(0)
  ok% = parse_and_transpile%("'!endif")
  expect_tokens(0)

  ' Code outside the block is included.
  ok% = parse_and_transpile%("three")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "three")
End Sub

Sub test_ifndef_nested_2()
  Local ok%

  ' FOO is set and BAR is unset so all code within !ifndef FOO is excluded.
  ok% = parse_and_transpile%("'!set FOO")
  ok% = parse_and_transpile%("'!ifndef FOO")
  ok% = parse_and_transpile%("one")
  expect_tokens(0)
  ok% = parse_and_transpile%("'!ifndef BAR")
  ok% = parse_and_transpile%("two")
  expect_tokens(0)
  ok% = parse_and_transpile%("'!endif")
  expect_tokens(0)
  ok% = parse_and_transpile%("'!endif")
  expect_tokens(0)

  ' Code outside the block is included.
  ok% = parse_and_transpile%("three")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "three")
End Sub

Sub test_ifndef_nested_3()
  Local ok%

  ' BAR is set and FOO is unset so all code within !ifndef BAR is excluded.
  ok% = parse_and_transpile%("'!set BAR")
  ok% = parse_and_transpile%("'!ifndef FOO")
  ok% = parse_and_transpile%("one")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "one")
  ok% = parse_and_transpile%("'!ifndef BAR")
  ok% = parse_and_transpile%("two")
  expect_tokens(0)
  ok% = parse_and_transpile%("'!endif")
  expect_tokens(0)
  ok% = parse_and_transpile%("'!endif")
  expect_tokens(0)

  ' Code outside the block is included.
  ok% = parse_and_transpile%("three")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "three")
End Sub

Sub test_ifndef_nested_4()
  Local ok%

  ' FOO and BAR are both set so all code within !ifndef FOO and !ifndef BAR is excluded.
  ok% = parse_and_transpile%("'!set FOO")
  ok% = parse_and_transpile%("'!set BAR")
  ok% = parse_and_transpile%("'!ifndef FOO")
  ok% = parse_and_transpile%("one")
  expect_tokens(0)
  ok% = parse_and_transpile%("'!ifndef BAR")
  ok% = parse_and_transpile%("two")
  expect_tokens(0)
  ok% = parse_and_transpile%("'!endif")
  expect_tokens(0)
  ok% = parse_and_transpile%("'!endif")
  expect_tokens(0)

  ' Code outside the block is included.
  ok% = parse_and_transpile%("three")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "three")
End Sub

Sub test_set_given_flag_set()
  Local ok%

  ok% = parse_and_transpile%("'!set foo")
  assert_no_error()
  assert_int_equals(1, opt.is_flag_set%("foo"))

  ok% = parse_and_transpile%("'!set foo")
  assert_error("!set directive flag 'foo' is already set")
End Sub

Sub test_set_given_flag_unset()
  Local ok%

  ok% = parse_and_transpile%("'!set foo")
  assert_no_error()
  assert_int_equals(1, opt.is_flag_set%("foo"))

  ok% = parse_and_transpile%("'!set BAR")
  assert_no_error()
  assert_int_equals(1, opt.is_flag_set%("BAR"))
End Sub

Sub test_set_given_flag_too_long()
  Local ok%
  Local flag$ = "flag567890123456789012345678901234567890123456789012345678901234"

  ok% = parse_and_transpile%("'!set " + flag$)
  assert_no_error()
  assert_int_equals(1, opt.is_flag_set%(flag$))

  ok% = parse_and_transpile%("'!set " + flag$ + "5")
  assert_error("!set directive flag too long, max 64 chars")
End Sub

Sub test_set_is_case_insensitive()
  Local ok%

  ok% = parse_and_transpile%("'!set foo")
  assert_no_error()
  assert_int_equals(1, opt.is_flag_set%("FOO"))

  ok% = parse_and_transpile%("'!set FOO")
  assert_error("!set directive flag 'FOO' is already set")
End Sub

Sub test_omit_directives_from_output()
  Local ok%

  setup_test()
  ok% = parse_and_transpile%("'!set FOO")
  ok% = parse_and_transpile%("'!clear FOO")
  assert_int_equals(tr.STATUS_OMIT_LINE%, ok%)
  expect_tokens(0)

  setup_test()
  ok% = parse_and_transpile%("'!comments on")
  assert_int_equals(tr.STATUS_OMIT_LINE%, ok%)
  expect_tokens(0)

  setup_test()
  ok% = parse_and_transpile%("'!comment_if FOO")
  assert_int_equals(ok%, tr.STATUS_OMIT_LINE%)
  expect_tokens(0)
  ok% = parse_and_transpile%("'!set FOO")
  ok% = parse_and_transpile%("'!comment_if FOO")
  assert_int_equals(tr.STATUS_OMIT_LINE%, ok%)
  expect_tokens(0)

  setup_test()
  ok% = parse_and_transpile%("'!empty-lines 1")
  assert_int_equals(tr.STATUS_OMIT_LINE%, ok%)
  expect_tokens(0)

  setup_test()
  ok% = parse_and_transpile%("'!ifdef FOO")
  assert_int_equals(tr.STATUS_OMIT_LINE%, ok%)
  expect_tokens(0)
  ok% = parse_and_transpile%("'!set FOO")
  ok% = parse_and_transpile%("'!ifdef FOO")
  assert_int_equals(tr.STATUS_OMIT_LINE%, ok%)
  expect_tokens(0)

  setup_test()
  ok% = parse_and_transpile%("'!ifndef FOO")
  assert_int_equals(tr.STATUS_OMIT_LINE%, ok%)
  expect_tokens(0)
  ok% = parse_and_transpile%("'!set FOO")
  ok% = parse_and_transpile%("'!ifndef FOO")
  assert_int_equals(tr.STATUS_OMIT_LINE%, ok%)
  expect_tokens(0)

  setup_test()
  ok% = parse_and_transpile%("'!indent 1")
  assert_int_equals(tr.STATUS_OMIT_LINE%, ok%)
  expect_tokens(0)

  setup_test()
  ok% = parse_and_transpile%("'!replace FOO BAR")
  assert_int_equals(tr.STATUS_OMIT_LINE%, ok%)
  expect_tokens(0)

  setup_test()
  ok% = parse_and_transpile%("'!remove_if FOO")
  assert_int_equals(tr.STATUS_OMIT_LINE%, ok%)
  expect_tokens(0)
  ok% = parse_and_transpile%("'!set FOO")
  ok% = parse_and_transpile%("'!remove_if FOO")
  assert_int_equals(tr.STATUS_OMIT_LINE%, ok%)
  expect_tokens(0)

  setup_test()
  ok% = parse_and_transpile%("'!set FOO")
  assert_int_equals(tr.STATUS_OMIT_LINE%, ok%)
  expect_tokens(0)

  setup_test()
  ok% = parse_and_transpile%("'!spacing 1")
  assert_int_equals(tr.STATUS_OMIT_LINE%, ok%)
  expect_tokens(0)

  setup_test()
  ok% = parse_and_transpile%("'!uncomment_if FOO")
  assert_int_equals(tr.STATUS_OMIT_LINE%, ok%)
  expect_tokens(0)
  ok% = parse_and_transpile%("'!set FOO")
  ok% = parse_and_transpile%("'!uncomment_if FOO")
  assert_int_equals(tr.STATUS_OMIT_LINE%, ok%)
  expect_tokens(0)

  setup_test()
  ok% = parse_and_transpile%("'!replace FOO BAR")
  ok% = parse_and_transpile%("'!unreplace FOO")
  assert_int_equals(tr.STATUS_OMIT_LINE%, ok%)
  expect_tokens(0)

  setup_test()
  ok% = parse_and_transpile%("'!ifdef FOO")
  ok% = parse_and_transpile%("'!endif")
  assert_int_equals(tr.STATUS_OMIT_LINE%, ok%)
  expect_tokens(0)
  ok% = parse_and_transpile%("'!set FOO")
  ok% = parse_and_transpile%("'!ifdef FOO")
  ok% = parse_and_transpile%("'!endif")
  assert_int_equals(tr.STATUS_OMIT_LINE%, ok%)
  expect_tokens(0)
End Sub

Sub test_unknown_directive()
  Local ok% = parse_and_transpile%("'!wombat foo")
  assert_int_equals(0, ok%)
  assert_error("unknown !wombat directive")
End Sub

Sub test_unbalanced_endif()
  Local ok%

  ok% = parse_and_transpile%("'!ifndef FOO")
  ok% = parse_and_transpile%("'!endif")
  assert_int_equals(tr.STATUS_OMIT_LINE%, ok%)
  expect_tokens(0)
  ok% = parse_and_transpile%("'!endif")
  assert_int_equals(0, ok%)
  assert_error("unmatched !endif")
End Sub

Sub test_sptrans_flag_is_set()
  Local ok%

  ' The SPTRANS flag is always considered set by the transpiler.
  ok% = parse_and_transpile%("'!ifdef SPTRANS")
  assert_int_equals(tr.STATUS_OMIT_LINE%, ok%)
  ok% = parse_and_transpile%("one")
  expect_tokens(1)
  expect_tk(0, TK_IDENTIFIER, "one")
  ok% = parse_and_transpile%("'!endif")
  assert_int_equals(tr.STATUS_OMIT_LINE%, ok%)
End Sub

Sub test_error_directive()
  Local ok%

  ok% = parse_and_transpile%("'!error " + str.quote$("This is an error"))
  assert_int_equals(0, ok%)
  assert_error("This is an error")

  ok% = parse_and_transpile%("'!error")
  assert_int_equals(0, ok%)
  assert_error("!error directive has missing " + str.quote$("message") + " argument")

  ok% = parse_and_transpile%("'!error 42")
  assert_int_equals(0, ok%)
  assert_error("!error directive has missing " + str.quote$("message") + " argument")
End Sub

' If the result of transpiling a line is such that the line is omitted
' and that omission then causes two empty lines to run sequentially then
' we automatically omit the second empty line.
Sub test_omit_and_line_spacing()
  Local ok%

  ok% = parse_and_transpile%("")
  assert_no_error()
  assert_int_equals(1, ok%)

  ok% = parse_and_transpile%("")
  assert_no_error()
  assert_int_equals(1, ok%)

  ok% = parse_and_transpile%("'!set foo")
  assert_no_error()
  assert_int_equals(3, ok%)
  assert_int_equals(0, tr.omit_flag%)

  ' Should be omitted, because the last line was omitted AND
  ' the last non-omitted line was empty.
  ok% = parse_and_transpile%("")
  assert_no_error()
  assert_int_equals(3, ok%)
  assert_int_equals(0, tr.omit_flag%)

  ok% = parse_and_transpile%("'!ifndef foo")
  assert_no_error()
  assert_int_equals(3, ok%)
  assert_int_equals(1, tr.omit_flag%)

  ok% = parse_and_transpile%("bar")
  assert_no_error()
  assert_int_equals(3, ok%)
  assert_int_equals(1, tr.omit_flag%)

  ok% = parse_and_transpile%("'!endif")
  assert_no_error()
  assert_int_equals(3, ok%)
  assert_int_equals(0, tr.omit_flag%)

  ' Should be omitted, because the last line was omitted AND
  ' the last non-omitted line was empty.
  ok% = parse_and_transpile%("")
  assert_no_error()
  assert_int_equals(3, ok%)
  assert_int_equals(0, tr.omit_flag%)
End Sub

Sub test_comments_directive()
  Local ok%

  ok% = parse_and_transpile%("'!comments off")
  assert_no_error()
  assert_int_equals(tr.STATUS_OMIT_LINE%, ok%)
  expect_tokens(0)
  assert_int_equals(0, opt.comments)

  ok% = parse_and_transpile%("' This is a comment")
  assert_no_error()
  expect_tokens(0)
  assert_int_equals(tr.STATUS_OMIT_LINE%, ok%)
  assert_string_equals("", lx.line$)

  ok% = parse_and_transpile%("Dim a = 1 ' This is also a comment")
  assert_no_error()
  assert_int_equals(1, ok%)
  expect_tokens(4)
  expect_tk(0, TK_KEYWORD, "Dim")
  expect_tk(1, TK_IDENTIFIER, "a")
  expect_tk(2, TK_SYMBOL, "=")
  expect_tk(3, TK_NUMBER, "1")
  assert_string_equals("Dim a = 1", lx.line$)

  ok% = parse_and_transpile%("'!comments on")
  assert_no_error()
  assert_int_equals(tr.STATUS_OMIT_LINE%, ok%)
  expect_tokens(0)
  assert_int_equals(-1, opt.comments)

  ok% = parse_and_transpile%("' This is a third comment")
  assert_no_error()
  assert_int_equals(1, ok%)
  expect_tokens(1)
  expect_tk(0, TK_COMMENT, "' This is a third comment")
End Sub

Function parse_and_transpile%(s$)
  lx.parse_basic(s$)
  assert_no_error()
  parse_and_transpile% = tr.transpile%()
End Function

Sub expect_replacement(i%, from$, to_$)
  assert_true(from$ = tr.replacements$(i%, 0), "Assert failed, expected from$ = '" + from$ + "', but was '" + tr.replacements$(i%, 0) + "'")
  assert_true(to_$  = tr.replacements$(i%, 1), "Assert failed, expected to_$ = '"   + to_$  + "', but was '" + tr.replacements$(i%, 1) + "'")
End Sub

Sub expect_tokens(num)
  assert_no_error()
  assert_true(lx.num = num, "expected " + Str$(num) + " tokens, found " + Str$(lx.num))
End Sub

Sub expect_tk(i, type, s$)
  assert_true(lx.type(i) = type, "expected type " + Str$(type) + ", found " + Str$(lx.type(i)))
  assert_string_equals(s$, lx.token$(i))
End Sub


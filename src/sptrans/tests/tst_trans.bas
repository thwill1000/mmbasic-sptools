' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

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
#Include "../defines.inc"
#Include "../expression.inc"
#Include "../trans.inc"

const SUCCESS = 0

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
add_test("test_endif_given_no_if")
add_test("test_endif_given_args")
add_test("test_endif_given_trail_comment")
add_test("test_error_directive")
add_test("test_omit_and_line_spacing")
add_test("test_comments_directive")
add_test("test_always_true_flags")
add_test("test_always_false_flags")
add_test("test_if_given_true")
add_test("test_if_given_false")
add_test("test_if_given_nested")
add_test("test_else_given_if_active")
add_test("test_else_given_else_active")
add_test("test_else_given_no_if")
add_test("test_too_many_elses")
add_test("test_elif_given_if_active")
add_test("test_elif_given_elif_1_active")
add_test("test_elif_given_elif_2_active")
add_test("test_elif_given_else_active")
add_test("test_elif_given_no_expression")
add_test("test_elif_given_invalid_expr")
add_test("test_elif_given_no_if")
add_test("test_elif_given_comment_if")
add_test("test_elif_given_uncomment_if")
add_test("test_elif_given_ifdef")
add_test("test_elif_given_shortcut_expr")
add_test("test_info_defined")

run_tests()

End

Sub setup_test()
  opt.init()
  def.init()

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

  sys.err$ = ""
End Sub

Sub test_transpile_includes()
  ' Given #INCLUDE statement.
  setup_test()
  assert_int_equals(SUCCESS, lx.parse_basic%("#include " + str.quote$("foo/bar.inc")))
  assert_int_equals(2, tr.transpile_includes%())
  assert_no_error()
  assert_string_equals("foo/bar.inc", tr.include$)

  ' Given #INCLUDE statement preceded by whitespace.
  setup_test()
  assert_int_equals(SUCCESS, lx.parse_basic%("  #include " + str.quote$("foo/bar.inc")))
  assert_int_equals(2, tr.transpile_includes%())
  assert_no_error()
  assert_string_equals("foo/bar.inc", tr.include$)

  ' Given #INCLUDE statement followed by whitespace.
  setup_test()
  assert_int_equals(SUCCESS, lx.parse_basic%("#include " + str.quote$("foo/bar.inc") + "  "))
  assert_int_equals(2, tr.transpile_includes%())
  assert_no_error()
  assert_string_equals("foo/bar.inc", tr.include$)

  ' Given other statement.
  setup_test()
  assert_int_equals(SUCCESS, lx.parse_basic%("Print " + str.quote$("Hello World")))
  assert_int_equals(1, tr.transpile_includes%())
  assert_no_error()
  assert_string_equals("", tr.include$)

  ' Given missing argument.
  setup_test()
  assert_int_equals(SUCCESS, lx.parse_basic%("#include"))
  assert_int_equals(0, tr.transpile_includes%())
  assert_error("#INCLUDE expects a <file> argument")
  assert_string_equals("", tr.include$)

  ' Given non-string argument.
  setup_test()
  assert_int_equals(SUCCESS, lx.parse_basic%("#include foo"))
  assert_int_equals(0, tr.transpile_includes%())
  assert_error("#INCLUDE expects a <file> argument")
  assert_string_equals("", tr.include$)

  ' Given too many arguments.
  setup_test()
  assert_int_equals(SUCCESS, lx.parse_basic%("#include " + str.quote$("foo/bar.inc") + " " + str.quote$("wombat.inc")))
  assert_int_equals(0, tr.transpile_includes%())
  assert_error("#INCLUDE expects a <file> argument")
  assert_string_equals("", tr.include$)

  ' Given #INCLUDE is not the first token on the line.
  setup_test()
  assert_int_equals(SUCCESS, lx.parse_basic%("Dim i% : #include " + str.quote$("foo/bar.inc")))
  assert_int_equals(1, tr.transpile_includes%())
  assert_no_error()
  assert_string_equals("", tr.include$)
End Sub

Sub test_parse_replace()
  expect_transpile_omits("'!replace DEF Sub")
  expect_replacement(0, "def", "Sub")

  expect_transpile_omits("'!replace ENDPROC { End Sub }")
  expect_replacement(1, "endproc", "End|Sub")

  expect_transpile_omits("'!replace { THEN ENDPROC } { Then Exit Sub }")
  expect_replacement(2, "then|endproc", "Then|Exit|Sub")

  expect_transpile_omits("'!replace GOTO%% { Goto %1 }")
  expect_replacement(3, "goto%%", "Goto|%1")

  expect_transpile_omits("'!replace { THEN %% } { Then Goto %1 }")
  expect_replacement(4, "then|%%", "Then|Goto|%1")

  expect_transpile_omits("'!replace '%% { CRLF$ %1 }")
  expect_replacement(5, "'%%", "CRLF$|%1")

  expect_transpile_omits("'!replace &%h &h%1")
  expect_replacement(6, "&%h", "&h%1")

  expect_transpile_omits("'!replace foo")
  expect_replacement(7, "foo", "")

  expect_transpile_omits("'!replace {foo}")
  expect_replacement(7, Chr$(0), Chr$(0))
  expect_replacement(8, "foo", "")

  expect_transpile_omits("'!replace foo {}")
  expect_replacement(8, Chr$(0), Chr$(0))
  expect_replacement(9, "foo", "")
End Sub

Sub test_parse_replace_given_errors()
  expect_transpile_error("'!replace", "!replace directive expects <from> argument")
  assert_int_equals(0, tr.num_replacements%)

  expect_transpile_error("'!replace {}", "!replace directive has empty <from> group")
  assert_int_equals(0, tr.num_replacements%)

  expect_transpile_error("'!replace {} y", "!replace directive has empty <from> group")
  assert_int_equals(0, tr.num_replacements%)

  expect_transpile_error("'!replace { x y", "!replace directive has missing '}'")
  assert_int_equals(0, tr.num_replacements%)

  expect_transpile_error("'!replace { x } { y z", "!replace directive has missing '}'")
  assert_int_equals(0, tr.num_replacements%)

  expect_transpile_error("'!replace { x } { y } z", "!replace directive has too many arguments")
  assert_int_equals(0, tr.num_replacements%)

  expect_transpile_error("'!replace { x } { y } { z }", "!replace directive has too many arguments")
  assert_int_equals(0, tr.num_replacements%)

  expect_transpile_error("'!replace { {", "!replace directive has unexpected '{'")
  assert_int_equals(0, tr.num_replacements%)

  expect_transpile_error("'!replace foo }", "!replace directive has unexpected '}'")
  assert_int_equals(0, tr.num_replacements%)
End Sub

Sub test_parse_given_too_many_rpl()
  Local i%

  For i% = 0 To tr.MAX_REPLACEMENTS% - 1
    expect_transpile_omits("'!replace a" + Str$(i%) + " b")
  Next

  expect_transpile_error("'!replace foo bar", "!replace directive too many replacements (max 200)")
End Sub

Sub test_parse_unreplace()
  expect_transpile_omits("'!replace foo bar")
  expect_transpile_omits("'!replace wom bat")
  expect_transpile_omits("'!unreplace foo")

  assert_int_equals(2, tr.num_replacements%)
  expect_replacement(0, Chr$(0), Chr$(0))
  expect_replacement(1, "wom", "bat")
End Sub

Sub test_parse_unreplace_given_errs()
  ' Test given missing argument to directive.
  expect_transpile_error("'!unreplace", "!unreplace directive expects <from> argument")

  ' Test given directive has too many arguments.
  expect_transpile_error("'!unreplace { a b } c", "!unreplace directive has too many arguments")

  ' Test given replacement not present.
  expect_transpile_omits("'!replace wom bat")
  expect_transpile_error("'!unreplace foo", "!unreplace directive could not find 'foo'")
  assert_int_equals(1, tr.num_replacements%)
  expect_replacement(0, "wom", "bat")
End Sub

Sub test_apply_replace()
  expect_transpile_omits("'!replace x      y")
  expect_transpile_omits("'!replace &hFFFF z")
  expect_transpile_succeeds("Dim x = &hFFFF ' comment")

  expect_token_count(5)
  expect_token(0, TK_KEYWORD, "Dim")
  expect_token(1, TK_IDENTIFIER, "y")
  expect_token(2, TK_SYMBOL, "=")
  expect_token(3, TK_IDENTIFIER, "z")
  expect_token(4, TK_COMMENT, "' comment")
  assert_string_equals("Dim y = z ' comment", lx.line$)
End Sub

Sub test_apply_replace_groups()
  expect_transpile_omits("'!replace ab { cd ef }")
  expect_transpile_succeeds("ab gh ij")
  expect_token_count(4)
  expect_token(0, TK_IDENTIFIER, "cd")
  expect_token(1, TK_IDENTIFIER, "ef")
  expect_token(2, TK_IDENTIFIER, "gh")
  expect_token(3, TK_IDENTIFIER, "ij")

  setup_test()
  expect_transpile_omits("'!replace {ab cd} ef")
  expect_transpile_succeeds("ab cd gh ij")
  expect_token_count(3)
  expect_token(0, TK_IDENTIFIER, "ef")
  expect_token(1, TK_IDENTIFIER, "gh")
  expect_token(2, TK_IDENTIFIER, "ij")
End Sub

Sub test_apply_replace_patterns()
  setup_test()
  expect_transpile_omits("'!replace { DEF PROC%% } { SUB proc%1 }")
  expect_transpile_succeeds("foo DEF PROCWOMBAT bar")
  expect_token_count(4)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_KEYWORD,    "SUB")
  expect_token(2, TK_IDENTIFIER, "procWOMBAT") ' Note don't want to change case of WOMBAT.
  expect_token(3, TK_IDENTIFIER, "bar")

  setup_test()
  expect_transpile_omits("'!replace GOTO%d { Goto %1 }")
  expect_transpile_succeeds("foo GOTO1234 bar")
  expect_token_count(4)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_KEYWORD   , "Goto")
  expect_token(2, TK_NUMBER,     "1234")
  expect_token(3, TK_IDENTIFIER, "bar") 

  setup_test()
  expect_transpile_omits("'!replace { THEN %d } { Then Goto %1 }")

  ' Test %d pattern matches decimal digits ...
  expect_transpile_succeeds("foo THEN 1234 bar")
  expect_token_count(5)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_KEYWORD   , "Then")
  expect_token(2, TK_KEYWORD   , "Goto")
  expect_token(3, TK_NUMBER,     "1234")
  expect_token(4, TK_IDENTIFIER, "bar") 

  ' ... but it should not match other characters.
  expect_transpile_succeeds("foo THEN wombat bar")
  expect_token_count(4)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_KEYWORD   , "THEN")
  expect_token(2, TK_IDENTIFIER, "wombat")
  expect_token(3, TK_IDENTIFIER, "bar") 

  setup_test()
  expect_transpile_omits("'!replace { PRINT '%% } { ? : ? %1 }")
  expect_transpile_succeeds("foo PRINT '" + str.quote$("wombat") + " bar")
  expect_token_count(6)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_SYMBOL,     "?")
  expect_token(2, TK_SYMBOL,     ":")
  expect_token(3, TK_SYMBOL,     "?")
  expect_token(4, TK_STRING,     str.quote$("wombat"))
  expect_token(5, TK_IDENTIFIER, "bar")

  setup_test()
  expect_transpile_omits("'!replace '%% { : ? %1 }")
  expect_transpile_succeeds("foo PRINT '" + str.quote$("wombat") + " bar")
  expect_token_count(6)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_KEYWORD,    "PRINT")
  expect_token(2, TK_SYMBOL,     ":")
  expect_token(3, TK_SYMBOL,     "?")
  expect_token(4, TK_STRING,     str.quote$("wombat"))
  expect_token(5, TK_IDENTIFIER, "bar")

  setup_test()
  expect_transpile_omits("'!replace REM%% { ' %1 }")
  expect_transpile_succeeds("foo REM This is a comment")
  expect_token_count(2)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_COMMENT, "' This is a comment")

  setup_test()
  expect_transpile_omits("'!replace { Spc ( } { Space$ ( }")
  expect_transpile_succeeds("foo Spc(5) bar")
  expect_token_count(6)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_KEYWORD,    "Space$")
  expect_token(2, TK_SYMBOL,     "(")
  expect_token(3, TK_NUMBER,     "5")
  expect_token(4, TK_SYMBOL,     ")")
  expect_token(5, TK_IDENTIFIER, "bar")

  ' Test %h pattern matches hex digits ...
  setup_test()
  expect_transpile_omits("'!replace GOTO%h { Goto %1 }")
  expect_transpile_succeeds("foo GOTOabcdef0123456789 bar")
  expect_token_count(4)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_KEYWORD,    "Goto")
  expect_token(2, TK_IDENTIFIER, "abcdef0123456789")
  expect_token(3, TK_IDENTIFIER, "bar")

  ' ... but it should not match other characters.
  expect_transpile_succeeds("foo GOTOxyz bar")
  expect_token_count(3)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_IDENTIFIER, "GOTOxyz")
  expect_token(2, TK_IDENTIFIER, "bar")
End Sub

Sub test_replace_fails_if_too_long()
  expect_transpile_omits("'!replace foo foobar")

  ' Test where replaced string should be 255 characters.
  Local s$ = String$(248, "a")
  Cat s$, " foo"
  assert_int_equals(252, Len(s$))
  expect_transpile_succeeds(s$)
  expect_token_count(2)
  expect_token(0, TK_IDENTIFIER, String$(248, "a"))
  expect_token(1, TK_IDENTIFIER, "foobar")


  ' Test where replaced string should be 256 characters.
  s$ = String$(251, "a")
  Cat s$, " foo"
  assert_int_equals(255, Len(s$))
  expect_transpile_error(s$, "applying replacement makes line > 255 characters")
End Sub

Sub test_replace_with_fewer_tokens()
  ' Replace 1 token with 0.
  expect_transpile_omits("'!replace bar")
  expect_transpile_succeeds("foo bar wom")
  expect_token_count(2)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_IDENTIFIER, "wom")

  ' Removal of all tokens.
  setup_test()
  expect_transpile_omits("'!replace bar")
  expect_transpile_succeeds("bar bar bar", 1)
  expect_token_count(0)

  ' Replace 2 tokens with 1.
  setup_test()
  expect_transpile_omits("'!replace { foo bar } wom")
  expect_transpile_succeeds("foo bar foo bar snafu")
  expect_token_count(3)
  expect_token(0, TK_IDENTIFIER, "wom")
  expect_token(1, TK_IDENTIFIER, "wom")
  expect_token(2, TK_IDENTIFIER, "snafu")

  ' Note that we don't end up with the single token "foo" because once we have
  ' applied a replacement we do not recursively apply that replacement to the
  ' already replaced text.
  setup_test()
  expect_transpile_omits("'!replace { foo bar } foo")
  expect_transpile_succeeds("foo bar bar")
  expect_token_count(2)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_IDENTIFIER, "bar")

  ' Replace 3 tokens with 1 - again note we don't just end up with "foo".
  setup_test()
  expect_transpile_omits("'!replace { foo bar wom } foo")
  expect_transpile_succeeds("foo bar wom bar wom")
  expect_token_count(3)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_IDENTIFIER, "bar")
  expect_token(2, TK_IDENTIFIER, "wom")

  ' Replace 3 tokens with 2 - and again we don't just end up with "foo bar".
  setup_test()
  expect_transpile_omits("'!replace { foo bar wom } { foo bar }")
  expect_transpile_succeeds("foo bar wom wom")
  expect_token_count(3)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_IDENTIFIER, "bar")
  expect_token(2, TK_IDENTIFIER, "wom")
End Sub

Sub test_replace_with_more_tokens()
  ' Replace 1 token with 2 - note that we don't get infinite recursion because
  ' once we have applied the replacement text we not not recusively apply the
  ' replacement to the already replaced text.
  expect_transpile_omits("'!replace foo { foo bar }")
  expect_transpile_succeeds("foo wom")
  expect_token_count(3)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_IDENTIFIER, "bar")
  expect_token(2, TK_IDENTIFIER, "wom")

  setup_test()
  expect_transpile_omits("'!replace foo { bar foo }")
  expect_transpile_succeeds("foo wom foo")
  expect_token_count(5)
  expect_token(0, TK_IDENTIFIER, "bar")
  expect_token(1, TK_IDENTIFIER, "foo")
  expect_token(2, TK_IDENTIFIER, "wom")
  expect_token(3, TK_IDENTIFIER, "bar")
  expect_token(4, TK_IDENTIFIER, "foo")

  ' Ensure replacement applied for multiple matches.
  setup_test()
  expect_transpile_omits("'!replace foo { bar foo }")
  expect_transpile_succeeds("foo foo")
  expect_token_count(4)
  expect_token(0, TK_IDENTIFIER, "bar")
  expect_token(1, TK_IDENTIFIER, "foo")
  expect_token(2, TK_IDENTIFIER, "bar")
  expect_token(3, TK_IDENTIFIER, "foo")

  ' Replace 3 tokens with 4.
  setup_test()
  expect_transpile_omits("'!replace { foo bar wom } { foo bar wom foo }")
  expect_transpile_succeeds("foo bar wom bar wom")
  expect_token_count(6)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_IDENTIFIER, "bar")
  expect_token(2, TK_IDENTIFIER, "wom")
  expect_token(3, TK_IDENTIFIER, "foo")
  expect_token(4, TK_IDENTIFIER, "bar")
  expect_token(5, TK_IDENTIFIER, "wom")
End Sub

Sub test_replace_given_new_rpl()
  expect_transpile_omits("'!replace foo bar")
  expect_transpile_succeeds("foo wom bill")
  expect_token_count(3)
  expect_token(0, TK_IDENTIFIER, "bar")
  expect_token(1, TK_IDENTIFIER, "wom")
  expect_token(2, TK_IDENTIFIER, "bill")

  expect_transpile_omits("'!replace foo snafu")
  expect_transpile_succeeds("foo wom bill")
  expect_token_count(3)
  expect_token(0, TK_IDENTIFIER, "snafu")
  expect_token(1, TK_IDENTIFIER, "wom")
  expect_token(2, TK_IDENTIFIER, "bill")
End Sub

Sub test_apply_unreplace()
  expect_transpile_omits("'!replace foo bar")
  expect_transpile_omits("'!replace wom bat")
  expect_transpile_omits("'!replace bill ben")
  expect_replacement(0, "foo", "bar")
  expect_replacement(1, "wom", "bat")
  expect_replacement(2, "bill", "ben")
  expect_replacement(3, "", "")

  expect_transpile_succeeds("foo wom bill")
  expect_token_count(3)
  expect_token(0, TK_IDENTIFIER, "bar")
  expect_token(1, TK_IDENTIFIER, "bat")
  expect_token(2, TK_IDENTIFIER, "ben")

  expect_transpile_omits("'!unreplace wom")
  expect_replacement(0, "foo", "bar")
  expect_replacement(1, Chr$(0), Chr$(0))
  expect_replacement(2, "bill", "ben")
  expect_replacement(3, "", "")

  expect_transpile_succeeds("foo wom bill")
  expect_token_count(3)
  expect_token(0, TK_IDENTIFIER, "bar")
  expect_token(1, TK_IDENTIFIER, "wom")
  expect_token(2, TK_IDENTIFIER, "ben")
End Sub

Sub test_clear_given_flag_set()
  def.set_flag("foo")
  def.set_flag("bar")

  expect_transpile_omits("'!clear foo")
  assert_int_equals(0, def.is_flag_set%("foo"))
  assert_int_equals(1, def.is_flag_set%("bar"))

  expect_transpile_omits("'!clear bar")
  assert_int_equals(0, def.is_flag_set%("foo"))
  assert_int_equals(0, def.is_flag_set%("bar"))
End Sub

Sub test_clear_given_flag_unset()
  expect_transpile_error("'!clear foo", "!clear directive flag 'foo' is not set")
  expect_transpile_error("'!clear BAR", "!clear directive flag 'BAR' is not set")
End Sub

Sub test_clear_given_flag_too_long()
  Local line$ = "'!clear flag5678901234567890123456789012345678901234567890123456789012345"
  Local emsg$ = "!clear directive flag too long, max 64 chars"
  expect_transpile_error(line$, emsg$)
End Sub

Sub test_clear_is_case_insensitive()
  def.set_flag("foo")
  def.set_flag("BAR")

  expect_transpile_omits("'!clear FOO")
  assert_int_equals(0, def.is_flag_set%("foo"))
  assert_int_equals(1, def.is_flag_set%("BAR"))

  expect_transpile_omits("'!clear bar")
  assert_int_equals(0, def.is_flag_set%("foo"))
  assert_int_equals(0, def.is_flag_set%("BAR"))
End Sub

Sub test_comment_if()
  ' 'foo' is set, code inside !comment_if block should be commented.
  expect_transpile_omits("'!set foo")
  expect_transpile_omits("'!comment_if foo")
  expect_transpile_succeeds("one")
  expect_token_count(1)
  expect_token(0, TK_COMMENT, "' one")
  expect_transpile_succeeds("two")
  expect_token_count(1)
  expect_token(0, TK_COMMENT, "' two")
  expect_transpile_omits("'!endif")

  ' Code outside the block should not be commented.
  expect_transpile_succeeds("three")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "three")
End Sub

Sub test_comment_if_not()
  ' 'foo' is NOT set, code inside !comment_if NOT block should be commented.
  expect_transpile_omits("'!comment_if not foo")
  expect_transpile_succeeds("one")
  expect_token_count(1)
  expect_token(0, TK_COMMENT, "' one")
  expect_transpile_succeeds("two")
  expect_token_count(1)
  expect_token(0, TK_COMMENT, "' two")
  expect_transpile_omits("'!endif")

  ' 'foo' is set, code inside !comment_if NOT block should NOT be commented.
  expect_transpile_omits("'!set foo")
  expect_transpile_omits("'!comment_if not foo")
  expect_transpile_succeeds("three")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "three")
  expect_transpile_omits("'!endif")
End Sub

Sub test_uncomment_if()
  ' 'foo' is set, code inside !uncomment_if block should be uncommented.
  expect_transpile_omits("'!set foo")
  expect_transpile_omits("'!uncomment_if foo")

  expect_transpile_succeeds("' one")
  assert_string_equals(" one", lx.line$)
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "one")

  expect_transpile_succeeds("REM two")
  assert_string_equals(" two", lx.line$)
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "two")

  expect_transpile_succeeds("'' three")
  assert_string_equals("' three", lx.line$)
  expect_token_count(1)
  expect_token(0, TK_COMMENT, "' three")

  expect_transpile_omits("'!endif")

  ' Code outside the block should not be uncommented.
  expect_transpile_succeeds("' four")
  assert_string_equals("' four", lx.line$)
  expect_token_count(1)
  expect_token(0, TK_COMMENT, "' four")
End Sub

Sub test_uncomment_if_not()
  ' 'foo' is NOT set, code inside !uncomment_if NOT block should be uncommented.
  expect_transpile_omits("'!uncomment_if not foo")

  expect_transpile_succeeds("' one")
  assert_string_equals(" one", lx.line$)
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "one")

  expect_transpile_succeeds("REM two")
  assert_string_equals(" two", lx.line$)
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "two")

  expect_transpile_succeeds("'' three")
  assert_string_equals("' three", lx.line$)
  expect_token_count(1)
  expect_token(0, TK_COMMENT, "' three")
  expect_transpile_omits("'!endif")

  ' 'foo' is set, code inside !uncomment_if NOT block should NOT be uncommented.
  expect_transpile_omits("'!set foo")
  expect_transpile_omits("'!uncomment_if not foo")
  expect_transpile_succeeds("' four")
  assert_string_equals("' four", lx.line$)
  expect_token_count(1)
  expect_token(0, TK_COMMENT, "' four")
  expect_transpile_omits("'!endif")
End Sub

Sub test_ifdef_given_set()
  ' FOO is set so all code within !ifdef FOO is included.
  expect_transpile_omits("'!set FOO")
  expect_transpile_omits("'!ifdef FOO")
  expect_transpile_succeeds("one")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "one")
  expect_transpile_succeeds("two")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "two")
  expect_transpile_omits("'!endif")

  ' Code outside the block is included.
  expect_transpile_succeeds("three")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "three")
End Sub

Sub test_ifdef_given_unset()
  ' FOO is unset so all code within !ifdef FOO is excluded.
  expect_transpile_omits("'!ifdef FOO")
  expect_transpile_omits("one")
  expect_transpile_omits("two")
  expect_transpile_omits("'!endif")

  ' Code outside the block is included.
  expect_transpile_succeeds("three")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "three")
End Sub

Sub test_ifdef_given_0_args()
  expect_transpile_error("'!ifdef", "!ifdef directive expects 1 argument")
End Sub

Sub test_ifdef_given_2_args()
  expect_transpile_error("'!ifdef not bar", "!ifdef directive expects 1 argument")
End Sub

Sub test_ifdef_is_case_insensitive()
  def.set_flag("foo")
  expect_transpile_omits("'!ifdef FOO")
  expect_transpile_succeeds("one")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "one")
  expect_transpile_omits("'!endif")
End Sub

Sub test_ifdef_nested_1()
  ' FOO and BAR are both unset so all code within !ifdef FOO is excluded.
  expect_transpile_omits("'!ifdef FOO")
  expect_transpile_omits("one")
  expect_transpile_omits("'!ifdef BAR")
  expect_transpile_omits("two")
  expect_transpile_omits("'!endif")
  expect_transpile_omits("'!endif")

  ' Code outside the block is included.
  expect_transpile_succeeds("three")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "three")
End Sub

Sub test_ifdef_nested_2()
  ' FOO is set and BAR is unset so code within !ifdef BAR is excluded.
  expect_transpile_omits("'!set FOO")
  expect_transpile_omits("'!ifdef FOO")
  expect_transpile_succeeds("one")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "one")
  expect_transpile_omits("'!ifdef BAR")
  expect_transpile_omits("two")
  expect_transpile_omits("'!endif")
  expect_transpile_omits("'!endif")

  ' Code outside the block is included.
  expect_transpile_succeeds("three")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "three")
End Sub

Sub test_ifdef_nested_3()
  ' BAR is set and FOO is unset so all code within !ifdef FOO is excluded.
  expect_transpile_omits("'!set BAR")
  expect_transpile_omits("'!ifdef FOO")
  expect_transpile_omits("one")
  expect_transpile_omits("'!ifdef BAR")
  expect_transpile_omits("two")
  expect_transpile_omits("'!endif")
  expect_transpile_omits("'!endif")

  ' Code outside the block is included.
  expect_transpile_succeeds("three")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "three")
End Sub

Sub test_ifdef_nested_4()
  ' FOO and BAR are both set so all code within !ifdef FOO and !ifdef BAR is included.
  expect_transpile_omits("'!set FOO")
  expect_transpile_omits("'!set BAR")
  expect_transpile_omits("'!ifdef FOO")
  expect_transpile_succeeds("one")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "one")
  expect_transpile_omits("'!ifdef BAR")
  expect_transpile_succeeds("two")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "two")
  expect_transpile_omits("'!endif")
  expect_transpile_omits("'!endif")

  ' Code outside the block is included.
  expect_transpile_succeeds("three")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "three")
End Sub

Sub test_ifndef_given_set()
  ' FOO is set so all code within !ifndef FOO is excluded.
  expect_transpile_omits("'!set FOO")
  expect_transpile_omits("'!ifndef FOO")
  expect_transpile_omits("one")
  expect_transpile_omits("two")
  expect_transpile_omits("'!endif")

  ' Code outside the block is included.
  expect_transpile_succeeds("three")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "three")
End Sub

Sub test_ifndef_given_unset()
  ' FOO is unset so all code within !ifndef FOO is included.
  expect_transpile_omits("'!ifndef FOO")
  expect_transpile_succeeds("one")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "one")
  expect_transpile_succeeds("two")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "two")
  expect_transpile_omits("'!endif")

  ' Code outside the block is included.
  expect_transpile_succeeds("three")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "three")
End Sub

Sub test_ifndef_given_0_args()
  expect_transpile_error("'!ifndef", "!ifndef directive expects 1 argument")
End Sub

Sub test_ifndef_given_2_args()
  expect_transpile_error("'!ifndef not bar", "!ifndef directive expects 1 argument")
End Sub

Sub test_ifndef_is_case_insensitive()
  def.set_flag("foo")
  expect_transpile_omits("'!ifndef FOO")
  expect_transpile_omits("one")
  expect_token_count(0)
  expect_transpile_omits("'!endif")
End Sub

Sub test_ifndef_nested_1()
  ' FOO and BAR are both unset so all code within !ifndef FOO is included.
  expect_transpile_omits("'!ifndef FOO")
  expect_transpile_succeeds("one")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "one")
  expect_transpile_omits("'!ifndef BAR")
  expect_transpile_succeeds("two")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "two")
  expect_transpile_omits("'!endif")
  expect_transpile_omits("'!endif")

  ' Code outside the block is included.
  expect_transpile_succeeds("three")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "three")
End Sub

Sub test_ifndef_nested_2()
  ' FOO is set and BAR is unset so all code within !ifndef FOO is excluded.
  expect_transpile_omits("'!set FOO")
  expect_transpile_omits("'!ifndef FOO")
  expect_transpile_omits("one")
  expect_transpile_omits("'!ifndef BAR")
  expect_transpile_omits("two")
  expect_transpile_omits("'!endif")
  expect_transpile_omits("'!endif")

  ' Code outside the block is included.
  expect_transpile_succeeds("three")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "three")
End Sub

Sub test_ifndef_nested_3()
  ' BAR is set and FOO is unset so all code within !ifndef BAR is excluded.
  expect_transpile_omits("'!set BAR")
  expect_transpile_omits("'!ifndef FOO")
  expect_transpile_succeeds("one")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "one")
  expect_transpile_omits("'!ifndef BAR")
  expect_transpile_omits("two")
  expect_transpile_omits("'!endif")
  expect_transpile_omits("'!endif")

  ' Code outside the block is included.
  expect_transpile_succeeds("three")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "three")
End Sub

Sub test_ifndef_nested_4()
  ' FOO and BAR are both set so all code within !ifndef FOO and !ifndef BAR is excluded.
  expect_transpile_omits("'!set FOO")
  expect_transpile_omits("'!set BAR")
  expect_transpile_omits("'!ifndef FOO")
  expect_transpile_omits("one")
  expect_transpile_omits("'!ifndef BAR")
  expect_transpile_omits("two")
  expect_transpile_omits("'!endif")
  expect_transpile_omits("'!endif")

  ' Code outside the block is included.
  expect_transpile_succeeds("three")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "three")
End Sub

Sub test_set_given_flag_set()
  expect_transpile_omits("'!set foo")
  assert_int_equals(1, def.is_flag_set%("foo"))

  expect_transpile_error("'!set foo", "!set directive flag 'foo' is already set")
End Sub

Sub test_set_given_flag_unset()
  expect_transpile_omits("'!set foo")
  assert_int_equals(1, def.is_flag_set%("foo"))

  expect_transpile_omits("'!set BAR")
  assert_int_equals(1, def.is_flag_set%("BAR"))
End Sub

Sub test_set_given_flag_too_long()
  Local flag$ = "flag567890123456789012345678901234567890123456789012345678901234"

  expect_transpile_omits("'!set " + flag$)
  assert_int_equals(1, def.is_flag_set%(flag$))

  expect_transpile_error("'!set " + flag$ + "5", "!set directive flag too long, max 64 chars")
End Sub

Sub test_set_is_case_insensitive()
  expect_transpile_omits("'!set foo")
  assert_int_equals(1, def.is_flag_set%("FOO"))

  expect_transpile_error("'!set FOO", "!set directive flag 'FOO' is already set")
End Sub

Sub test_omit_directives_from_output()
  setup_test()
  expect_transpile_omits("'!set FOO")
  expect_transpile_omits("'!clear FOO")

  setup_test()
  expect_transpile_omits("'!comments on")

  setup_test()
  expect_transpile_omits("'!comment_if FOO")
  expect_transpile_omits("'!set FOO")
  expect_transpile_omits("'!comment_if FOO")

  setup_test()
  expect_transpile_omits("'!empty-lines 1")

  setup_test()
  expect_transpile_omits("'!ifdef FOO")
  expect_transpile_omits("'!set FOO")
  expect_transpile_omits("'!ifdef FOO")

  setup_test()
  expect_transpile_omits("'!ifndef FOO")
  expect_transpile_omits("'!set FOO")
  expect_transpile_omits("'!ifndef FOO")

  setup_test()
  expect_transpile_omits("'!indent 1")

  setup_test()
  expect_transpile_omits("'!replace FOO BAR")

  setup_test()
  expect_transpile_omits("'!set FOO")

  setup_test()
  expect_transpile_omits("'!spacing 1")

  setup_test()
  expect_transpile_omits("'!uncomment_if FOO")
  expect_transpile_omits("'!set FOO")
  expect_transpile_omits("'!uncomment_if FOO")

  setup_test()
  expect_transpile_omits("'!replace FOO BAR")
  expect_transpile_omits("'!unreplace FOO")

  setup_test()
  expect_transpile_omits("'!ifdef FOO")
  expect_transpile_omits("'!endif")
  expect_transpile_omits("'!set FOO")
  expect_transpile_omits("'!ifdef FOO")
  expect_transpile_omits("'!endif")
End Sub

Sub test_unknown_directive()
  expect_transpile_error("'!wombat foo", "Unknown !wombat directive")
End Sub

Sub test_endif_given_no_if()
  expect_transpile_omits("'!ifndef FOO")
  expect_transpile_omits("'!endif")
  expect_transpile_error("'!endif", "!endif directive without !if")
End Sub

Sub test_endif_given_args()
  expect_transpile_omits("'!ifndef FOO")
  expect_transpile_error("'!endif wombat", "!endif directive has too many arguments")
End Sub

Sub test_endif_given_trail_comment()
  expect_transpile_omits("'!if defined(FOO)")
  expect_transpile_omits("'!endif ' my comment")

  ' Note that only the first token on a line will be recognised as a directive.
  expect_transpile_omits("'!if defined(FOO)")
  expect_transpile_omits("'!endif '!if defined(FOO)")
End Sub

Sub test_error_directive()
  expect_transpile_error("'!error " + str.quote$("This is an error"), "This is an error")
  expect_transpile_error("'!error", "!error directive has missing " + str.quote$("message") + " argument")
  expect_transpile_error("'!error 42", "!error directive has missing " + str.quote$("message") + " argument")
End Sub

' If the result of transpiling a line is such that the line is omitted
' and that omission then causes two empty lines to run sequentially then
' we automatically omit the second empty line.
Sub test_omit_and_line_spacing()
  expect_transpile_succeeds("", 1)
  expect_transpile_succeeds("", 1)

  expect_transpile_omits("'!set foo")
  assert_int_equals(0, tr.omit_flag%)

  ' Should be omitted, because the last line was omitted AND
  ' the last non-omitted line was empty.
  expect_transpile_omits("")
  assert_int_equals(0, tr.omit_flag%)

  expect_transpile_omits("'!ifndef foo")
  assert_int_equals(1, tr.omit_flag%)

  expect_transpile_omits("bar")
  assert_int_equals(1, tr.omit_flag%)

  expect_transpile_omits("'!endif")
  assert_int_equals(0, tr.omit_flag%)

  ' Should be omitted, because the last line was omitted AND
  ' the last non-omitted line was empty.
  expect_transpile_omits("")
  assert_int_equals(0, tr.omit_flag%)
End Sub

Sub test_comments_directive()
  expect_transpile_omits("'!comments off")
  assert_int_equals(0, opt.comments)

  expect_transpile_omits("' This is a comment")
  assert_string_equals("", lx.line$)

  expect_transpile_succeeds("Dim a = 1 ' This is also a comment")
  expect_token_count(4)
  expect_token(0, TK_KEYWORD, "Dim")
  expect_token(1, TK_IDENTIFIER, "a")
  expect_token(2, TK_SYMBOL, "=")
  expect_token(3, TK_NUMBER, "1")
  assert_string_equals("Dim a = 1", lx.line$)

  expect_transpile_omits("'!comments on")
  assert_int_equals(-1, opt.comments)

  expect_transpile_succeeds("' This is a third comment")
  expect_token_count(1)
  expect_token(0, TK_COMMENT, "' This is a third comment")
End Sub

Sub test_always_true_flags()
  Local flags$(4) = ("1", "true", "TRUE", "on", "ON")
  Local i%

  For i% = Bound(flags$(), 0) To Bound(flags$(), 1)
    expect_transpile_omits("'!ifdef " + flags$(i%))
    expect_transpile_succeeds("should_not_be_omitted")
    expect_token_count(1)
    expect_token(0, TK_IDENTIFIER, "should_not_be_omitted")
  Next

  For i% = Bound(flags$(), 0) To Bound(flags$(), 1)
    expect_transpile_omits("'!ifndef " + flags$(i%))
    expect_transpile_omits("should_be_omitted")
    expect_transpile_omits("'!endif")
  Next
End Sub

Sub test_always_false_flags()
  Local flags$(4) = ("0", "false", "FALSE", "off", "OFF")
  Local i%

  For i% = Bound(flags$(), 0) To Bound(flags$(), 1)
    expect_transpile_omits("'!ifndef " + flags$(i%))
    expect_transpile_succeeds("should_not_be_omitted")
    expect_token_count(1)
    expect_token(0, TK_IDENTIFIER, "should_not_be_omitted")
    expect_transpile_omits("'!endif")
  Next

  For i% = Bound(flags$(), 0) To Bound(flags$(), 1)
    expect_transpile_omits("'!ifdef " + flags$(i%))
    expect_transpile_omits("should_be_omitted")
    expect_transpile_omits("'!endif")
  Next
End Sub

Sub test_if_given_true()
  expect_transpile_omits("'!if defined(true)")
  expect_transpile_succeeds(" if_clause")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "if_clause")
  expect_transpile_omits("'!endif")
  assert_true(tr.if_stack_sz(0) = 0, "IF stack is not empty")
End Sub

Sub test_if_given_false()
  expect_transpile_omits("'!if defined(false)")
  expect_transpile_omits(" if_clause")
  expect_transpile_omits("'!endif")
  assert_true(tr.if_stack_sz(0) = 0, "IF stack is not empty")
End Sub

Sub test_if_given_nested()
  expect_transpile_omits("'!if false")
  expect_transpile_omits("  '!if true")
  expect_transpile_omits("  '!endif")
  expect_transpile_omits("'!endif")
End Sub

Sub test_else_given_if_active()
  expect_transpile_omits("'!if defined(true)")
  expect_transpile_succeeds(" if_clause")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "if_clause")
  expect_transpile_omits("'!else")
  expect_transpile_omits("    else_clause")
  expect_transpile_omits("'!endif")
  assert_true(tr.if_stack_sz(0) = 0, "IF stack is not empty")
End Sub

Sub test_else_given_else_active()
  expect_transpile_omits("'!if defined(false)")
  expect_transpile_omits("    if_clause")
  expect_transpile_omits("'!else")
  expect_transpile_succeeds(" else_clause")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "else_clause")
  expect_transpile_omits("'!endif")
  assert_true(tr.if_stack_sz(0) = 0, "IF stack is not empty")
End Sub

Sub test_else_given_no_if()
  expect_transpile_error("'!else", "!else directive without !if")
End Sub

Sub test_too_many_elses()
  expect_transpile_omits("'!if defined(true)")
  expect_transpile_omits("'!else")
  expect_transpile_error("'!else", "Too many !else directives")

  setup_test()
  expect_transpile_omits("'!if defined(false)")
  expect_transpile_omits("'!else")
  expect_transpile_error("'!else", "Too many !else directives")
End Sub

Sub test_elif_given_if_active()
  expect_transpile_omits("'!if defined(true)")
  expect_transpile_succeeds(" if_clause")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "if_clause")
  expect_transpile_omits("'!elif defined(true)")
  expect_transpile_omits("    elif_clause_1")
  expect_transpile_omits("'!elif defined(true)")
  expect_transpile_omits("    elif_clause_2")
  expect_transpile_omits("'!else")
  expect_transpile_omits("    else_clause")
  expect_transpile_omits("'!endif")
  assert_true(tr.if_stack_sz(0) = 0, "IF stack is not empty")
End Sub

Sub test_elif_given_elif_1_active()
  expect_transpile_omits("'!if defined(false)")
  expect_transpile_omits("    if_clause")
  expect_transpile_omits("'!elif defined(true)")
  expect_transpile_succeeds(" elif_clause_1")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "elif_clause_1")
  expect_transpile_omits("'!elif defined(true)")
  expect_transpile_omits("    elif_clause_2")
  expect_transpile_omits("'!else")
  expect_transpile_omits("    else_clause")
  expect_transpile_omits("'!endif")
  assert_true(tr.if_stack_sz(0) = 0, "IF stack is not empty")
End Sub

Sub test_elif_given_elif_2_active()
  expect_transpile_omits("'!if defined(false)")
  expect_transpile_omits("    if_clause")
  expect_transpile_omits("'!elif defined(false)")
  expect_transpile_omits("    elif_clause_1")
  expect_transpile_omits("'!elif defined(true)")
  expect_transpile_succeeds(" elif_clause_2")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "elif_clause_2")
  expect_transpile_omits("'!else")
  expect_transpile_omits("    else_clause")
  expect_transpile_omits("'!endif")
  assert_true(tr.if_stack_sz(0) = 0, "IF stack is not empty")
End Sub

Sub test_elif_given_else_active()
  expect_transpile_omits("'!if defined(false)")
  expect_transpile_omits("    if_clause")
  expect_transpile_omits("'!elif defined(false)")
  expect_transpile_omits("    elif_clause_1")
  expect_transpile_omits("'!elif defined(false)")
  expect_transpile_omits("    elif_clause_2")
  expect_transpile_omits("'!else")
  expect_transpile_succeeds(" else_clause")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "else_clause")
  expect_transpile_omits("'!endif")
  assert_true(tr.if_stack_sz(0) = 0, "IF stack is not empty")
End Sub

Sub test_elif_given_no_expression()
  expect_transpile_omits("'!if defined(false)")
  expect_transpile_omits("    if_clause")
  expect_transpile_error("'!elif", "!elif directive expects at least 1 argument")
End Sub

Sub test_elif_given_invalid_expr()
  expect_transpile_omits("'!if defined(false)")
  expect_transpile_omits("    if_clause")
  expect_transpile_error("'!elif a +", "Invalid expression syntax")
End Sub

Sub test_elif_given_no_if()
  expect_transpile_error("'!elif defined(true)", "!elif directive without !if")
End Sub

Sub test_elif_given_comment_if()
  expect_transpile_omits("'!comment_if true")
  expect_transpile_error("'!elif defined(true)", "!elif directive without !if")

  setup_test()
  expect_transpile_omits("'!comment_if false")
  expect_transpile_error("'!elif defined(true)", "!elif directive without !if")
End Sub

Sub test_elif_given_uncomment_if()
  expect_transpile_omits("'!uncomment_if true")
  expect_transpile_error("'!elif defined(true)", "!elif directive without !if")

  setup_test()
  expect_transpile_omits("'!uncomment_if false")
  expect_transpile_error("'!elif defined(true)", "!elif directive without !if")
End Sub

Sub test_elif_given_ifdef()
  expect_transpile_omits("'!ifdef true")
  expect_transpile_succeeds(" if_clause")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "if_clause")
  expect_transpile_omits("'!elif defined(true)")
  expect_transpile_omits("    elif_clause_1")
  expect_transpile_omits("'!endif")
  assert_true(tr.if_stack_sz(0) = 0, "IF stack is not empty")

  setup_test()
  expect_transpile_omits("'!ifdef false")
  expect_transpile_omits("    if_clause")
  expect_transpile_omits("'!elif defined(true)")
  expect_transpile_succeeds(" elif_clause_1")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "elif_clause_1")
  expect_transpile_omits("'!endif")
  assert_true(tr.if_stack_sz(0) = 0, "IF stack is not empty")
End Sub

' Test given shortcut expression:
'   !ELIF foo
' rather than full:4
'   !ELIF DEFINED(foo)
Sub test_elif_given_shortcut_expr()
  expect_transpile_omits("'!if false")
  expect_transpile_omits(" if_clause")
  expect_transpile_omits("'!elif true")
  expect_transpile_succeeds(" elif_clause")
  expect_token_count(1)
  expect_token(0, TK_IDENTIFIER, "elif_clause")
  expect_transpile_omits("'!endif")
  assert_true(tr.if_stack_sz(0) = 0, "IF stack is not empty")
End Sub

Sub test_info_defined()
  expect_transpile_omits("'!info defined foo")
  expect_transpile_omits("'!set foo")
  expect_transpile_succeeds("'!info defined foo")
  expect_token_count(1)
  expect_token(0, TK_COMMENT, "' Preprocessor flag FOO defined")
  expect_transpile_omits("'!clear foo")
  expect_transpile_omits("'!info defined foo")
  expect_transpile_error("'!info", "!info directive expects two arguments")
  expect_transpile_error("'!info defined", "!info directive expects two arguments")
  expect_transpile_error("'!info foo bar", "!info directive has invalid first argument: foo")
End Sub

Sub expect_replacement(i%, from$, to_$)
  assert_true(from$ = tr.replacements$(i%, 0), "Assert failed, expected from$ = '" + from$ + "', but was '" + tr.replacements$(i%, 0) + "'")
  assert_true(to_$  = tr.replacements$(i%, 1), "Assert failed, expected to_$ = '"   + to_$  + "', but was '" + tr.replacements$(i%, 1) + "'")
End Sub

Sub expect_token_count(num)
  assert_no_error()
  assert_true(lx.num = num, "expected " + Str$(num) + " tokens, found " + Str$(lx.num))
End Sub

Sub expect_token(i, type, s$)
  assert_true(lx.type(i) = type, "expected type " + Str$(type) + ", found " + Str$(lx.type(i)))
  assert_string_equals(s$, lx.token$(i))
End Sub

Sub expect_transpile_omits(line$)
  Local result%
  If lx.parse_basic%(line$) Then
    assert_fail("Parse failed: " + line$)
  Else
    result% = tr.transpile%()
    If result% = tr.STATUS_OMIT_LINE% Then
      If lx.num <> 0 Then
        assert_fail("Omitted line contains " + Str$(lx.num) + " tokens: " + line$)
      EndIf
    Else
      assert_fail("Transpiler failed to omit line, result = " + Str$(result%) + " : " + line$)
    EndIf
  EndIf
  assert_no_error()
End Sub

Sub expect_transpile_succeeds(line$, allow_zero_tokens%)
  Local result%
  If lx.parse_basic%(line$) Then
    assert_fail("Parse failed: " + line$)
  Else
    result% = tr.transpile%()
    If result% = tr.STATUS_SUCCESS% Then
      If Not allow_zero_tokens% And lx.num < 1 Then
        assert_fail("Transpiled line contains zero tokens: " + line$)
      EndIf
    Else
      assert_fail("Transpiler did not return SUCCESS, result = " + Str$(result%) + " : " + line$)
    EndIf
  EndIf
  assert_no_error()
End Sub

Sub expect_transpile_error(line$, msg$)
  Local result%
  If lx.parse_basic%(line$) Then
    assert_fail("Parse failed: " + line$)
  Else
    result% = tr.transpile%()
    If result% = tr.STATUS_ERROR% Then
      assert_error(msg$)
    Else
      assert_fail("Transpiler did not return ERROR, result = " + Str$(result%) + " : " + line$)
    EndIf
  EndIf
End Sub

' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

Option Base 0
Option Default Integer
Option Explicit On

#Include "../../splib/system.inc"
#Include "../../splib/array.inc"
#Include "../../splib/bits.inc"
#Include "../../splib/list.inc"
#Include "../../splib/string.inc"
#Include "../../splib/file.inc"
#Include "../../splib/map.inc"
#Include "../../splib/map2.inc"
#Include "../../splib/set.inc"
#Include "../../splib/vt100.inc"
#Include "../../sptest/unittest.inc"
#Include "../../common/sptools.inc"
#Include "../keywords.inc"
#Include "../lexer.inc"
#Include "../options.inc"
#Include "../defines.inc"
#Include "../expression.inc"

sys.provides("console")
Sub con.spin()
End Sub

sys.provides("output")
Dim out.line_num%

#Include "../symbols.inc"
#Include "../input.inc"
#Include "../symproc.inc"
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
add_test("test_undef_given_defined")
add_test("test_undef_given_undefined")
add_test("test_undef_given_id_too_long")
add_test("test_undef_is_case_insensitive")
add_test("test_undef_given_constant")
add_test("test_comment_if")
add_test("test_comment_if_not")
add_test("test_uncomment_if")
add_test("test_uncomment_if_not")
add_test("test_unknown_directive")
add_test("test_unknown_directive_given_inactive_if", "test_unknown_given_inactive_if")
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
add_test("test_define_given_defined")
add_test("test_define_given_undefined")
add_test("test_define_given_id_too_long")
add_test("test_define_is_case_insensitive")
add_test("test_define_given_constant")
add_test("test_omit_directives_from_output")
add_test("test_endif_given_no_if")
add_test("test_endif_given_args")
add_test("test_endif_given_trail_comment")
add_test("test_error_directive")
add_test("test_comments_directive")
add_test("test_always_defined_values")
add_test("test_always_undefined_values")
add_test("test_if_given_true")
add_test("test_if_given_false")
add_test("test_if_given_nested_1")
add_test("test_if_given_nested_2")
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
add_test("test_dynamic_call")
add_test("test_dynamic_call_given_no_arg")
add_test("test_dynamic_call_given_too_many_args", "test_dynamic_too_many_args")
add_test("test_dynamic_call_given_too_many_names", "test_dynamic_too_many_names")
add_test("test_disable_format")
add_test("test_disable_format_gvn_2_args")
add_test("test_disable_format_gvn_invalid")

run_tests()

End

Sub setup_test()
  opt.init()
  def.init()
  symproc.init(32, 300, 1)

  in.num_open_files% = 1

  ' TODO: extract into trans.init() or trans.reset().
  tr.clear_replacements()
  tr.include$ = ""
  tr.omit_flag% = 0

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
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("#include " + str.quote$("foo/bar.inc")))
  assert_int_equals(tr.INCLUDE_FILE, tr.transpile_includes%())
  assert_no_error()
  assert_string_equals("foo/bar.inc", tr.include$)

  ' Given #INCLUDE statement preceded by whitespace.
  setup_test()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("  #include " + str.quote$("foo/bar.inc")))
  assert_int_equals(tr.INCLUDE_FILE, tr.transpile_includes%())
  assert_no_error()
  assert_string_equals("foo/bar.inc", tr.include$)

  ' Given #INCLUDE statement followed by whitespace.
  setup_test()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("#include " + str.quote$("foo/bar.inc") + "  "))
  assert_int_equals(tr.INCLUDE_FILE, tr.transpile_includes%())
  assert_no_error()
  assert_string_equals("foo/bar.inc", tr.include$)

  ' Given other statement.
  setup_test()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("Print " + str.quote$("Hello World")))
  assert_int_equals(sys.SUCCESS, tr.transpile_includes%())
  assert_no_error()
  assert_string_equals("", tr.include$)

  ' Given missing argument.
  setup_test()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("#include"))
  assert_int_equals(sys.FAILURE, tr.transpile_includes%())
  assert_error("#INCLUDE expects a <file> argument")
  assert_string_equals("", tr.include$)

  ' Given non-string argument.
  setup_test()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("#include foo"))
  assert_int_equals(sys.FAILURE, tr.transpile_includes%())
  assert_error("#INCLUDE expects a <file> argument")
  assert_string_equals("", tr.include$)

  ' Given too many arguments.
  setup_test()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("#include " + str.quote$("foo/bar.inc") + " " + str.quote$("wombat.inc")))
  assert_int_equals(sys.FAILURE, tr.transpile_includes%())
  assert_error("#INCLUDE expects a <file> argument")
  assert_string_equals("", tr.include$)

  ' Given #INCLUDE is not the first token on the line.
  setup_test()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("Dim i% : #include " + str.quote$("foo/bar.inc")))
  assert_int_equals(sys.SUCCESS, tr.transpile_includes%())
  assert_no_error()
  assert_string_equals("", tr.include$)

  ' Given #INCLUDE statement followed by comment.
  setup_test()
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("#include " + str.quote$("foo/bar.inc") + " ' This is a harmless comment"))
  assert_int_equals(tr.INCLUDE_FILE, tr.transpile_includes%())
  assert_no_error()
  assert_string_equals("foo/bar.inc", tr.include$)
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
  expect_transpile_succeeds("Dim x = &hFFFF ' comment", 5)
  expect_token(0, TK_KEYWORD, "Dim")
  expect_token(1, TK_IDENTIFIER, "y")
  expect_token(2, TK_SYMBOL, "=")
  expect_token(3, TK_IDENTIFIER, "z")
  expect_token(4, TK_COMMENT, "' comment")
  assert_string_equals("Dim y = z ' comment", lx.line$)
End Sub

Sub test_apply_replace_groups()
  expect_transpile_omits("'!replace ab { cd ef }")
  expect_transpile_succeeds("ab gh ij", 4)
  expect_token(0, TK_IDENTIFIER, "cd")
  expect_token(1, TK_IDENTIFIER, "ef")
  expect_token(2, TK_IDENTIFIER, "gh")
  expect_token(3, TK_IDENTIFIER, "ij")

  setup_test()
  expect_transpile_omits("'!replace {ab cd} ef")
  expect_transpile_succeeds("ab cd gh ij", 3)
  expect_token(0, TK_IDENTIFIER, "ef")
  expect_token(1, TK_IDENTIFIER, "gh")
  expect_token(2, TK_IDENTIFIER, "ij")
End Sub

Sub test_apply_replace_patterns()
  setup_test()
  expect_transpile_omits("'!replace { DEF PROC%% } { SUB proc%1 }")
  expect_transpile_succeeds("foo DEF PROCWOMBAT bar", 4)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_KEYWORD,    "SUB")
  expect_token(2, TK_IDENTIFIER, "procWOMBAT") ' Note don't want to change case of WOMBAT.
  expect_token(3, TK_IDENTIFIER, "bar")

  setup_test()
  expect_transpile_omits("'!replace GOTO%d { Goto %1 }")
  expect_transpile_succeeds("foo GOTO1234 bar", 4)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_KEYWORD   , "Goto")
  expect_token(2, TK_NUMBER,     "1234")
  expect_token(3, TK_IDENTIFIER, "bar") 

  setup_test()
  expect_transpile_omits("'!replace { THEN %d } { Then Goto %1 }")

  ' Test %d pattern matches decimal digits ...
  expect_transpile_succeeds("foo THEN 1234 bar", 5)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_KEYWORD   , "Then")
  expect_token(2, TK_KEYWORD   , "Goto")
  expect_token(3, TK_NUMBER,     "1234")
  expect_token(4, TK_IDENTIFIER, "bar") 

  ' ... but it should not match other characters.
  expect_transpile_succeeds("foo THEN wombat bar", 4)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_KEYWORD   , "THEN")
  expect_token(2, TK_IDENTIFIER, "wombat")
  expect_token(3, TK_IDENTIFIER, "bar") 

  setup_test()
  expect_transpile_omits("'!replace { PRINT '%% } { ? : ? %1 }")
  expect_transpile_succeeds("foo PRINT '" + str.quote$("wombat") + " bar", 6)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_SYMBOL,     "?")
  expect_token(2, TK_SYMBOL,     ":")
  expect_token(3, TK_SYMBOL,     "?")
  expect_token(4, TK_STRING,     str.quote$("wombat"))
  expect_token(5, TK_IDENTIFIER, "bar")

  setup_test()
  expect_transpile_omits("'!replace '%% { : ? %1 }")
  expect_transpile_succeeds("foo PRINT '" + str.quote$("wombat") + " bar", 6)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_KEYWORD,    "PRINT")
  expect_token(2, TK_SYMBOL,     ":")
  expect_token(3, TK_SYMBOL,     "?")
  expect_token(4, TK_STRING,     str.quote$("wombat"))
  expect_token(5, TK_IDENTIFIER, "bar")

  setup_test()
  expect_transpile_omits("'!replace REM%% { ' %1 }")
  expect_transpile_succeeds("foo REM This is a comment", 2)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_COMMENT, "' This is a comment")

  setup_test()
  expect_transpile_omits("'!replace { Spc ( } { Space$ ( }")
  expect_transpile_succeeds("foo Spc(5) bar", 6)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_KEYWORD,    "Space$")
  expect_token(2, TK_SYMBOL,     "(")
  expect_token(3, TK_NUMBER,     "5")
  expect_token(4, TK_SYMBOL,     ")")
  expect_token(5, TK_IDENTIFIER, "bar")

  ' Test %h pattern matches hex digits ...
  setup_test()
  expect_transpile_omits("'!replace GOTO%h { Goto %1 }")
  expect_transpile_succeeds("foo GOTOabcdef0123456789 bar", 4)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_KEYWORD,    "Goto")
  expect_token(2, TK_IDENTIFIER, "abcdef0123456789")
  expect_token(3, TK_IDENTIFIER, "bar")

  ' ... but it should not match other characters.
  expect_transpile_succeeds("foo GOTOxyz bar", 3)
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
  expect_transpile_succeeds(s$, 2)
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
  expect_transpile_succeeds("foo bar wom", 2)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_IDENTIFIER, "wom")

  ' Removal of all tokens.
  setup_test()
  expect_transpile_omits("'!replace bar")
  expect_transpile_succeeds("bar bar bar", 0)

  ' Replace 2 tokens with 1.
  setup_test()
  expect_transpile_omits("'!replace { foo bar } wom")
  expect_transpile_succeeds("foo bar foo bar snafu", 3)
  expect_token(0, TK_IDENTIFIER, "wom")
  expect_token(1, TK_IDENTIFIER, "wom")
  expect_token(2, TK_IDENTIFIER, "snafu")

  ' Note that we don't end up with the single token "foo" because once we have
  ' applied a replacement we do not recursively apply that replacement to the
  ' already replaced text.
  setup_test()
  expect_transpile_omits("'!replace { foo bar } foo")
  expect_transpile_succeeds("foo bar bar", 2)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_IDENTIFIER, "bar")

  ' Replace 3 tokens with 1 - again note we don't just end up with "foo".
  setup_test()
  expect_transpile_omits("'!replace { foo bar wom } foo")
  expect_transpile_succeeds("foo bar wom bar wom", 3)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_IDENTIFIER, "bar")
  expect_token(2, TK_IDENTIFIER, "wom")

  ' Replace 3 tokens with 2 - and again we don't just end up with "foo bar".
  setup_test()
  expect_transpile_omits("'!replace { foo bar wom } { foo bar }")
  expect_transpile_succeeds("foo bar wom wom", 3)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_IDENTIFIER, "bar")
  expect_token(2, TK_IDENTIFIER, "wom")
End Sub

Sub test_replace_with_more_tokens()
  ' Replace 1 token with 2 - note that we don't get infinite recursion because
  ' once we have applied the replacement text we not not recusively apply the
  ' replacement to the already replaced text.
  expect_transpile_omits("'!replace foo { foo bar }")
  expect_transpile_succeeds("foo wom", 3)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_IDENTIFIER, "bar")
  expect_token(2, TK_IDENTIFIER, "wom")

  setup_test()
  expect_transpile_omits("'!replace foo { bar foo }")
  expect_transpile_succeeds("foo wom foo", 5)
  expect_token(0, TK_IDENTIFIER, "bar")
  expect_token(1, TK_IDENTIFIER, "foo")
  expect_token(2, TK_IDENTIFIER, "wom")
  expect_token(3, TK_IDENTIFIER, "bar")
  expect_token(4, TK_IDENTIFIER, "foo")

  ' Ensure replacement applied for multiple matches.
  setup_test()
  expect_transpile_omits("'!replace foo { bar foo }")
  expect_transpile_succeeds("foo foo", 4)
  expect_token(0, TK_IDENTIFIER, "bar")
  expect_token(1, TK_IDENTIFIER, "foo")
  expect_token(2, TK_IDENTIFIER, "bar")
  expect_token(3, TK_IDENTIFIER, "foo")

  ' Replace 3 tokens with 4.
  setup_test()
  expect_transpile_omits("'!replace { foo bar wom } { foo bar wom foo }")
  expect_transpile_succeeds("foo bar wom bar wom", 6)
  expect_token(0, TK_IDENTIFIER, "foo")
  expect_token(1, TK_IDENTIFIER, "bar")
  expect_token(2, TK_IDENTIFIER, "wom")
  expect_token(3, TK_IDENTIFIER, "foo")
  expect_token(4, TK_IDENTIFIER, "bar")
  expect_token(5, TK_IDENTIFIER, "wom")
End Sub

Sub test_replace_given_new_rpl()
  expect_transpile_omits("'!replace foo bar")
  expect_transpile_succeeds("foo wom bill", 3)
  expect_token(0, TK_IDENTIFIER, "bar")
  expect_token(1, TK_IDENTIFIER, "wom")
  expect_token(2, TK_IDENTIFIER, "bill")

  expect_transpile_omits("'!replace foo snafu")
  expect_transpile_succeeds("foo wom bill", 3)
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

  expect_transpile_succeeds("foo wom bill", 3)
  expect_token(0, TK_IDENTIFIER, "bar")
  expect_token(1, TK_IDENTIFIER, "bat")
  expect_token(2, TK_IDENTIFIER, "ben")

  expect_transpile_omits("'!unreplace wom")
  expect_replacement(0, "foo", "bar")
  expect_replacement(1, Chr$(0), Chr$(0))
  expect_replacement(2, "bill", "ben")
  expect_replacement(3, "", "")

  expect_transpile_succeeds("foo wom bill", 3)
  expect_token(0, TK_IDENTIFIER, "bar")
  expect_token(1, TK_IDENTIFIER, "wom")
  expect_token(2, TK_IDENTIFIER, "ben")
End Sub

Sub test_undef_given_defined()
  def.define("foo")
  def.define("bar")

  expect_transpile_omits("'!undef foo")
  assert_int_equals(0, def.is_defined%("foo"))
  assert_int_equals(1, def.is_defined%("bar"))

  expect_transpile_omits("'!undef bar")
  assert_int_equals(0, def.is_defined%("foo"))
  assert_int_equals(0, def.is_defined%("bar"))
End Sub

Sub test_undef_given_undefined()
  ' Undefining non-existent defines is allowed.
  expect_transpile_omits("'!undef foo")
  expect_transpile_omits("'!undef BAR")
End Sub

Sub test_undef_given_id_too_long()
  Local line$ = "'!undef flag5678901234567890123456789012345678901234567890123456789012345"
  Local emsg$ = "!undef directive identifier too long, max 64 chars"
  expect_transpile_error(line$, emsg$)
End Sub

Sub test_undef_is_case_insensitive()
  def.define("foo")
  def.define("BAR")

  expect_transpile_omits("'!undef FOO")
  assert_int_equals(0, def.is_defined%("foo"))
  assert_int_equals(1, def.is_defined%("BAR"))

  expect_transpile_omits("'!undef bar")
  assert_int_equals(0, def.is_defined%("foo"))
  assert_int_equals(0, def.is_defined%("BAR"))
End Sub

Sub test_undef_given_constant()
  Local id$ = str.next_token$(def.CONSTANTS$, "|", 1)
  Do While id$ <> sys.NO_DATA$
    expect_transpile_error("'!undef " + id$, "!undef directive '" + id$ + "' cannot be undefined")
    id$ = str.next_token$()
  Loop
End Sub

Sub test_comment_if()
  ' 'foo' is set, code inside !comment_if block should be commented.
  expect_transpile_omits("'!define foo")
  expect_transpile_omits("'!comment_if foo")
  expect_transpile_succeeds("one", 1, TK_COMMENT, "' one")
  expect_transpile_succeeds("two", 1, TK_COMMENT, "' two")
  expect_transpile_omits("'!endif")

  ' Code outside the block should not be commented.
  expect_transpile_succeeds("three", 1, TK_IDENTIFIER, "three")
End Sub

Sub test_comment_if_not()
  ' 'foo' is NOT set, code inside !comment_if NOT block should be commented.
  expect_transpile_omits("'!comment_if not foo")
  expect_transpile_succeeds("one", 1, TK_COMMENT, "' one")
  expect_transpile_succeeds("two", 1, TK_COMMENT, "' two")
  expect_transpile_omits("'!endif")

  ' 'foo' is set, code inside !comment_if NOT block should NOT be commented.
  expect_transpile_omits("'!define foo")
  expect_transpile_omits("'!comment_if not foo")
  expect_transpile_succeeds("three", 1, TK_IDENTIFIER, "three")
  expect_transpile_omits("'!endif")
End Sub

Sub test_uncomment_if()
  ' 'foo' is set, code inside !uncomment_if block should be uncommented.
  expect_transpile_omits("'!define foo")
  expect_transpile_omits("'!uncomment_if foo")

  expect_transpile_succeeds("' one", 1, TK_IDENTIFIER, "one")
  assert_string_equals(" one", lx.line$)

  expect_transpile_succeeds("REM two", 1, TK_IDENTIFIER, "two")
  assert_string_equals(" two", lx.line$)

  expect_transpile_succeeds("'' three", 1, TK_COMMENT, "' three")
  assert_string_equals("' three", lx.line$)

  expect_transpile_omits("'!endif")

  ' Code outside the block should not be uncommented.
  expect_transpile_succeeds("' four", 1, TK_COMMENT, "' four")
  assert_string_equals("' four", lx.line$)
End Sub

Sub test_uncomment_if_not()
  ' 'foo' is NOT set, code inside !uncomment_if NOT block should be uncommented.
  expect_transpile_omits("'!uncomment_if not foo")

  expect_transpile_succeeds("' one", 1, TK_IDENTIFIER, "one")
  assert_string_equals(" one", lx.line$)

  expect_transpile_succeeds("REM two", 1, TK_IDENTIFIER, "two")
  assert_string_equals(" two", lx.line$)

  expect_transpile_succeeds("'' three", 1, TK_COMMENT, "' three")
  assert_string_equals("' three", lx.line$)
  expect_transpile_omits("'!endif")

  ' 'foo' is set, code inside !uncomment_if NOT block should NOT be uncommented.
  expect_transpile_omits("'!define foo")
  expect_transpile_omits("'!uncomment_if not foo")
  expect_transpile_succeeds("' four", 1, TK_COMMENT, "' four")
  assert_string_equals("' four", lx.line$)
  expect_transpile_omits("'!endif")
End Sub

Sub test_ifdef_given_set()
  ' FOO is set so all code within !ifdef FOO is included.
  expect_transpile_omits("'!define FOO")
  expect_transpile_omits("'!ifdef FOO")
  expect_transpile_succeeds("one", 1, TK_IDENTIFIER, "one")
  expect_transpile_succeeds("two", 1, TK_IDENTIFIER, "two")
  expect_transpile_omits("'!endif")

  ' Code outside the block is included.
  expect_transpile_succeeds("after_if_block", 1, TK_IDENTIFIER, "after_if_block")
End Sub

Sub test_ifdef_given_unset()
  ' FOO is unset so all code within !ifdef FOO is excluded.
  expect_transpile_omits("'!ifdef FOO")
  expect_transpile_omits("one")
  expect_transpile_omits("two")
  expect_transpile_omits("'!endif")

  ' Code outside the block is included.
  expect_transpile_succeeds("after_if_block", 1, TK_IDENTIFIER, "after_if_block")
End Sub

Sub test_ifdef_given_0_args()
  expect_transpile_error("'!ifdef", "!ifdef directive expects 1 argument")
End Sub

Sub test_ifdef_given_2_args()
  expect_transpile_error("'!ifdef not bar", "!ifdef directive expects 1 argument")
End Sub

Sub test_ifdef_is_case_insensitive()
  def.define("foo")
  expect_transpile_omits("'!ifdef FOO")
  expect_transpile_succeeds("one", 1)
  expect_token(0, TK_IDENTIFIER, "one")
  expect_transpile_omits("'!endif")

  ' Code outside the block is included.
  expect_transpile_succeeds("after_if_block", 1, TK_IDENTIFIER, "after_if_block")
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
  expect_transpile_succeeds("after_if_block", 1, TK_IDENTIFIER, "after_if_block")
End Sub

Sub test_ifdef_nested_2()
  ' FOO is set and BAR is unset so code within !ifdef BAR is excluded.
  expect_transpile_omits("'!define FOO")
  expect_transpile_omits("'!ifdef FOO")
  expect_transpile_succeeds("one", 1, TK_IDENTIFIER, "one")
  expect_transpile_omits("'!ifdef BAR")
  expect_transpile_omits("two")
  expect_transpile_omits("'!endif")
  expect_transpile_omits("'!endif")

  ' Code outside the block is included.
  expect_transpile_succeeds("after_if_block", 1, TK_IDENTIFIER, "after_if_block")
End Sub

Sub test_ifdef_nested_3()
  ' BAR is set and FOO is unset so all code within !ifdef FOO is excluded.
  expect_transpile_omits("'!define BAR")
  expect_transpile_omits("'!ifdef FOO")
  expect_transpile_omits("one")
  expect_transpile_omits("'!ifdef BAR")
  expect_transpile_omits("two")
  expect_transpile_omits("'!endif")
  expect_transpile_omits("'!endif")

  ' Code outside the block is included.
  expect_transpile_succeeds("after_if_block", 1, TK_IDENTIFIER, "after_if_block")
End Sub

Sub test_ifdef_nested_4()
  ' FOO and BAR are both set so all code within !ifdef FOO and !ifdef BAR is included.
  expect_transpile_omits("'!define FOO")
  expect_transpile_omits("'!define BAR")
  expect_transpile_omits("'!ifdef FOO")
  expect_transpile_succeeds("one", 1, TK_IDENTIFIER, "one")
  expect_transpile_omits("'!ifdef BAR")
  expect_transpile_succeeds("two", 1, TK_IDENTIFIER, "two")
  expect_transpile_omits("'!endif")
  expect_transpile_omits("'!endif")

  ' Code outside the block is included.
  expect_transpile_succeeds("after_if_block", 1, TK_IDENTIFIER, "after_if_block")
End Sub

Sub test_ifndef_given_set()
  ' FOO is set so all code within !ifndef FOO is excluded.
  expect_transpile_omits("'!define FOO")
  expect_transpile_omits("'!ifndef FOO")
  expect_transpile_omits("one")
  expect_transpile_omits("two")
  expect_transpile_omits("'!endif")

  ' Code outside the block is included.
  expect_transpile_succeeds("after_if_block", 1, TK_IDENTIFIER, "after_if_block")
End Sub

Sub test_ifndef_given_unset()
  ' FOO is unset so all code within !ifndef FOO is included.
  expect_transpile_omits("'!ifndef FOO")
  expect_transpile_succeeds("one", 1, TK_IDENTIFIER, "one")
  expect_transpile_succeeds("two", 1, TK_IDENTIFIER, "two")
  expect_transpile_omits("'!endif")

  ' Code outside the block is included.
  expect_transpile_succeeds("after_if_block", 1, TK_IDENTIFIER, "after_if_block")
End Sub

Sub test_ifndef_given_0_args()
  expect_transpile_error("'!ifndef", "!ifndef directive expects 1 argument")
End Sub

Sub test_ifndef_given_2_args()
  expect_transpile_error("'!ifndef not bar", "!ifndef directive expects 1 argument")
End Sub

Sub test_ifndef_is_case_insensitive()
  def.define("foo")
  expect_transpile_omits("'!ifndef FOO")
  expect_transpile_omits("one")
  expect_transpile_omits("'!endif")

  ' Code outside the block is included.
  expect_transpile_succeeds("after_if_block", 1, TK_IDENTIFIER, "after_if_block")
End Sub

Sub test_ifndef_nested_1()
  ' FOO and BAR are both unset so all code within !ifndef FOO is included.
  expect_transpile_omits("'!ifndef FOO")
  expect_transpile_succeeds("one", 1, TK_IDENTIFIER, "one")
  expect_transpile_omits("'!ifndef BAR")
  expect_transpile_succeeds("two", 1, TK_IDENTIFIER, "two")
  expect_transpile_omits("'!endif")
  expect_transpile_omits("'!endif")

  ' Code outside the block is included.
  expect_transpile_succeeds("after_if_block", 1, TK_IDENTIFIER, "after_if_block")
End Sub

Sub test_ifndef_nested_2()
  ' FOO is set and BAR is unset so all code within !ifndef FOO is excluded.
  expect_transpile_omits("'!define FOO")
  expect_transpile_omits("'!ifndef FOO")
  expect_transpile_omits("one")
  expect_transpile_omits("'!ifndef BAR")
  expect_transpile_omits("two")
  expect_transpile_omits("'!endif")
  expect_transpile_omits("'!endif")

  ' Code outside the block is included.
  expect_transpile_succeeds("after_if_block", 1, TK_IDENTIFIER, "after_if_block")
End Sub

Sub test_ifndef_nested_3()
  ' BAR is set and FOO is unset so all code within !ifndef BAR is excluded.
  expect_transpile_omits("'!define BAR")
  expect_transpile_omits("'!ifndef FOO")
  expect_transpile_succeeds("one", 1, TK_IDENTIFIER, "one")
  expect_transpile_omits("'!ifndef BAR")
  expect_transpile_omits("two")
  expect_transpile_omits("'!endif")
  expect_transpile_omits("'!endif")

  ' Code outside the block is included.
  expect_transpile_succeeds("after_if_block", 1, TK_IDENTIFIER, "after_if_block")
End Sub

Sub test_ifndef_nested_4()
  ' FOO and BAR are both set so all code within !ifndef FOO and !ifndef BAR is excluded.
  expect_transpile_omits("'!define FOO")
  expect_transpile_omits("'!define BAR")
  expect_transpile_omits("'!ifndef FOO")
  expect_transpile_omits("one")
  expect_transpile_omits("'!ifndef BAR")
  expect_transpile_omits("two")
  expect_transpile_omits("'!endif")
  expect_transpile_omits("'!endif")

  ' Code outside the block is included.
  expect_transpile_succeeds("after_if_block", 1, TK_IDENTIFIER, "after_if_block")
End Sub

Sub test_define_given_defined()
  expect_transpile_omits("'!define foo")
  assert_int_equals(1, def.is_defined%("foo"))

  expect_transpile_error("'!define foo", "!define directive 'foo' is already defined")
End Sub

Sub test_define_given_undefined()
  expect_transpile_omits("'!define foo")
  assert_int_equals(1, def.is_defined%("foo"))

  expect_transpile_omits("'!define BAR")
  assert_int_equals(1, def.is_defined%("BAR"))
End Sub

Sub test_define_given_id_too_long()
  Local id$ = "flag567890123456789012345678901234567890123456789012345678901234"

  expect_transpile_omits("'!define " + id$)
  assert_int_equals(1, def.is_defined%(id$))

  expect_transpile_error("'!define " + id$ + "5", "!define directive identifier too long, max 64 chars")
End Sub

Sub test_define_is_case_insensitive()
  expect_transpile_omits("'!define foo")
  assert_int_equals(1, def.is_defined%("FOO"))

  expect_transpile_error("'!define FOO", "!define directive 'FOO' is already defined")
End Sub

Sub test_define_given_constant()
  Local id$ = str.next_token$(def.CONSTANTS$, "|", 1)
  Do While id$ <> sys.NO_DATA$
    expect_transpile_error("'!define " + id$, "!define directive '" + id$ + "' cannot be defined")
    id$ = str.next_token$()
  Loop
End Sub

Sub test_omit_directives_from_output()
  setup_test()
  expect_transpile_omits("'!define FOO")
  expect_transpile_omits("'!undef FOO")

  setup_test()
  expect_transpile_omits("'!comments on")

  setup_test()
  expect_transpile_omits("'!comment_if FOO")
  expect_transpile_omits("'!define FOO")
  expect_transpile_omits("'!comment_if FOO")

  setup_test()
  expect_transpile_omits("'!empty-lines 1")

  setup_test()
  expect_transpile_omits("'!ifdef FOO")
  expect_transpile_omits("'!define FOO")
  expect_transpile_omits("'!ifdef FOO")

  setup_test()
  expect_transpile_omits("'!ifndef FOO")
  expect_transpile_omits("'!define FOO")
  expect_transpile_omits("'!ifndef FOO")

  setup_test()
  expect_transpile_omits("'!indent 1")

  setup_test()
  expect_transpile_omits("'!replace FOO BAR")

  setup_test()
  expect_transpile_omits("'!define FOO")

  setup_test()
  expect_transpile_omits("'!spacing 1")

  setup_test()
  expect_transpile_omits("'!uncomment_if FOO")
  expect_transpile_omits("'!define FOO")
  expect_transpile_omits("'!uncomment_if FOO")

  setup_test()
  expect_transpile_omits("'!replace FOO BAR")
  expect_transpile_omits("'!unreplace FOO")

  setup_test()
  expect_transpile_omits("'!ifdef FOO")
  expect_transpile_omits("'!endif")
  expect_transpile_omits("'!define FOO")
  expect_transpile_omits("'!ifdef FOO")
  expect_transpile_omits("'!endif")
End Sub

Sub test_unknown_directive()
  expect_transpile_error("'!wombat foo", "Unknown !wombat directive")
End Sub

Sub test_unknown_given_inactive_if()
  expect_transpile_omits("'!if defined(false)")
  expect_transpile_error("  '!wombat foo", "Unknown !wombat directive")
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

Sub test_comments_directive()
  ' Omit all comments.
  expect_transpile_omits("'!comments off")
  assert_int_equals(0, opt.comments)

  ' Preserve comments.
  expect_transpile_omits("'!comments on")
  assert_int_equals(-1, opt.comments)
End Sub

Sub test_always_defined_values()
  Local values$(4) = ("1", "true", "TRUE", "on", "ON")
  Local i%

  For i% = Bound(values$(), 0) To Bound(values$(), 1)
    expect_transpile_omits("'!ifdef " + values$(i%))
    expect_transpile_succeeds("should_not_be_omitted", 1)
    expect_token(0, TK_IDENTIFIER, "should_not_be_omitted")
  Next

  For i% = Bound(values$(), 0) To Bound(values$(), 1)
    expect_transpile_omits("'!ifndef " + values$(i%))
    expect_transpile_omits("should_be_omitted")
    expect_transpile_omits("'!endif")
  Next
End Sub

Sub test_always_undefined_values()
  Local values$(4) = ("0", "false", "FALSE", "off", "OFF")
  Local i%

  For i% = Bound(values$(), 0) To Bound(values$(), 1)
    expect_transpile_omits("'!ifndef " + values$(i%))
    expect_transpile_succeeds("should_not_be_omitted", 1)
    expect_token(0, TK_IDENTIFIER, "should_not_be_omitted")
    expect_transpile_omits("'!endif")
  Next

  For i% = Bound(values$(), 0) To Bound(values$(), 1)
    expect_transpile_omits("'!ifdef " + values$(i%))
    expect_transpile_omits("should_be_omitted")
    expect_transpile_omits("'!endif")
  Next
End Sub

Sub test_if_given_true()
  expect_transpile_omits("'!if defined(true)")
  expect_transpile_succeeds(" if_clause", 1, TK_IDENTIFIER, "if_clause")
  expect_transpile_omits("'!endif")
  assert_true(tr.if_stack_sz(0) = 0, "IF stack is not empty")

  ' Code outside the block is included.
  expect_transpile_succeeds("after_if_block", 1, TK_IDENTIFIER, "after_if_block")
End Sub

Sub test_if_given_false()
  expect_transpile_omits("'!if defined(false)")
  expect_transpile_omits(" if_clause")
  expect_transpile_omits("'!endif")
  assert_true(tr.if_stack_sz(0) = 0, "IF stack is not empty")

  ' Code outside the block is included.
  expect_transpile_succeeds("after_if_block", 1, TK_IDENTIFIER, "after_if_block")
End Sub

Sub test_if_given_nested_1()
  expect_transpile_omits   ("'!if false")
  expect_transpile_omits   ("  _1_expect_omitted")
  expect_transpile_omits   ("  '!if true")
  expect_transpile_omits   ("  _2_expect_omitted")
  expect_transpile_omits   ("  '!endif")
  expect_transpile_omits   ("  _3_expect_omitted")
  expect_transpile_omits   ("'!endif")

  ' Code outside the block is included.
  expect_transpile_succeeds("after_if_block", 1, TK_IDENTIFIER, "after_if_block")
End Sub

Sub test_if_given_nested_2()
  expect_transpile_omits   ("'!if true")
  expect_transpile_succeeds("  _1_expect_not_omitted", 1, TK_IDENTIFIER, "_1_expect_not_omitted")
  expect_transpile_omits   ("  '!if true")
  expect_transpile_succeeds("    _2_expect_not_omitted", 1, TK_IDENTIFIER, "_2_expect_not_omitted")
  expect_transpile_omits   ("  '!elif false")
  expect_transpile_omits   ("    _3_expect_omitted")
  expect_transpile_omits   ("  '!endif")
  expect_transpile_succeeds("  _4_expect_not_omitted", 1, TK_IDENTIFIER, "_4_expect_not_omitted")
  expect_transpile_omits   ("'!endif")

  ' Code outside the block is included.
  expect_transpile_succeeds("after_if_block", 1, TK_IDENTIFIER, "after_if_block")
End Sub

Sub test_else_given_if_active()
  expect_transpile_omits("'!if defined(true)")
  expect_transpile_succeeds(" if_clause", 1, TK_IDENTIFIER, "if_clause")
  expect_transpile_omits("'!else")
  expect_transpile_omits("    else_clause")
  expect_transpile_omits("'!endif")
  assert_true(tr.if_stack_sz(0) = 0, "IF stack is not empty")

  ' Code outside the block is included.
  expect_transpile_succeeds("after_if_block", 1, TK_IDENTIFIER, "after_if_block")
End Sub

Sub test_else_given_else_active()
  expect_transpile_omits("'!if defined(false)")
  expect_transpile_omits("    if_clause")
  expect_transpile_omits("'!else")
  expect_transpile_succeeds(" else_clause", 1, TK_IDENTIFIER, "else_clause")
  expect_transpile_omits("'!endif")
  assert_true(tr.if_stack_sz(0) = 0, "IF stack is not empty")

  ' Code outside the block is included.
  expect_transpile_succeeds("after_if_block", 1, TK_IDENTIFIER, "after_if_block")
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
  expect_transpile_succeeds(" if_clause", 1, TK_IDENTIFIER, "if_clause")
  expect_transpile_omits("'!elif defined(true)")
  expect_transpile_omits("    elif_clause_1")
  expect_transpile_omits("'!elif defined(true)")
  expect_transpile_omits("    elif_clause_2")
  expect_transpile_omits("'!else")
  expect_transpile_omits("    else_clause")
  expect_transpile_omits("'!endif")
  assert_true(tr.if_stack_sz(0) = 0, "IF stack is not empty")

  ' Code outside the block is included.
  expect_transpile_succeeds("after_if_block", 1, TK_IDENTIFIER, "after_if_block")
End Sub

Sub test_elif_given_elif_1_active()
  expect_transpile_omits("'!if defined(false)")
  expect_transpile_omits("    if_clause")
  expect_transpile_omits("'!elif defined(true)")
  expect_transpile_succeeds(" elif_clause_1", 1, TK_IDENTIFIER, "elif_clause_1")
  expect_transpile_omits("'!elif defined(true)")
  expect_transpile_omits("    elif_clause_2")
  expect_transpile_omits("'!else")
  expect_transpile_omits("    else_clause")
  expect_transpile_omits("'!endif")
  assert_true(tr.if_stack_sz(0) = 0, "IF stack is not empty")

  ' Code outside the block is included.
  expect_transpile_succeeds("after_if_block", 1, TK_IDENTIFIER, "after_if_block")
End Sub

Sub test_elif_given_elif_2_active()
  expect_transpile_omits("'!if defined(false)")
  expect_transpile_omits("    if_clause")
  expect_transpile_omits("'!elif defined(false)")
  expect_transpile_omits("    elif_clause_1")
  expect_transpile_omits("'!elif defined(true)")
  expect_transpile_succeeds(" elif_clause_2", 1, TK_IDENTIFIER, "elif_clause_2")
  expect_transpile_omits("'!else")
  expect_transpile_omits("    else_clause")
  expect_transpile_omits("'!endif")
  assert_true(tr.if_stack_sz(0) = 0, "IF stack is not empty")

  ' Code outside the block is included.
  expect_transpile_succeeds("after_if_block", 1, TK_IDENTIFIER, "after_if_block")
End Sub

Sub test_elif_given_else_active()
  expect_transpile_omits("'!if defined(false)")
  expect_transpile_omits("    if_clause")
  expect_transpile_omits("'!elif defined(false)")
  expect_transpile_omits("    elif_clause_1")
  expect_transpile_omits("'!elif defined(false)")
  expect_transpile_omits("    elif_clause_2")
  expect_transpile_omits("'!else")
  expect_transpile_succeeds(" else_clause", 1, TK_IDENTIFIER, "else_clause")
  expect_transpile_omits("'!endif")
  assert_true(tr.if_stack_sz(0) = 0, "IF stack is not empty")

  ' Code outside the block is included.
  expect_transpile_succeeds("after_if_block", 1, TK_IDENTIFIER, "after_if_block")
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
  expect_transpile_succeeds(" if_clause", 1, TK_IDENTIFIER, "if_clause")
  expect_transpile_omits("'!elif defined(true)")
  expect_transpile_omits("    elif_clause_1")
  expect_transpile_omits("'!endif")
  assert_true(tr.if_stack_sz(0) = 0, "IF stack is not empty")

  ' Code outside the block is included.
  expect_transpile_succeeds("after_if_block", 1, TK_IDENTIFIER, "after_if_block")

  setup_test()
  expect_transpile_omits("'!ifdef false")
  expect_transpile_omits("    if_clause")
  expect_transpile_omits("'!elif defined(true)")
  expect_transpile_succeeds(" elif_clause_1", 1, TK_IDENTIFIER, "elif_clause_1")
  expect_transpile_omits("'!endif")
  assert_true(tr.if_stack_sz(0) = 0, "IF stack is not empty")

  ' Code outside the block is included.
  expect_transpile_succeeds("after_if_block", 1, TK_IDENTIFIER, "after_if_block")
End Sub

' Test given shortcut expression:
'   !ELIF foo
' rather than full:4
'   !ELIF DEFINED(foo)
Sub test_elif_given_shortcut_expr()
  expect_transpile_omits("'!if false")
  expect_transpile_omits(" if_clause")
  expect_transpile_omits("'!elif true")
  expect_transpile_succeeds(" elif_clause", 1, TK_IDENTIFIER, "elif_clause")
  expect_transpile_omits("'!endif")
  assert_true(tr.if_stack_sz(0) = 0, "IF stack is not empty")

  ' Code outside the block is included.
  expect_transpile_succeeds("after_if_block", 1, TK_IDENTIFIER, "after_if_block")
End Sub

Sub test_info_defined()
  expect_transpile_omits("'!info defined foo")
  expect_transpile_omits("'!define foo")
  expect_transpile_succeeds("'!info defined foo", 1)
  expect_token(0, TK_COMMENT, "'_Preprocessor value FOO defined")
  expect_transpile_omits("'!undef foo")
  expect_transpile_omits("'!info defined foo")
  expect_transpile_error("'!info", "!info directive expects two arguments")
  expect_transpile_error("'!info defined", "!info directive expects two arguments")
  expect_transpile_error("'!info foo bar", "!info directive has invalid first argument: foo")
End Sub

Sub test_dynamic_call()
  expect_transpile_omits("'!dynamic_call fn_a")
  expect_transpile_omits("'!dynamic_call fn_b")
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("Function wombat%()"))
  assert_int_equals(3, symproc.fn_decl%(0))
  expect_transpile_omits("'!dynamic_call fn_c")
  assert_int_equals(sys.SUCCESS, lx.parse_basic%("End Function"))
  assert_int_equals(3, symproc.fn_end%(0))
  expect_transpile_omits("'!dynamic_call fn_d")

  Local ids%(4)
  assert_int_equals(3, sym.get_referenced_ids%(0, ids%()))
  assert_string_equals("fn_a", sym.id_to_name$(ids%(0)))
  assert_string_equals("fn_b", sym.id_to_name$(ids%(1)))
  assert_string_equals("fn_d", sym.id_to_name$(ids%(2)))
  assert_int_equals(1, sym.get_referenced_ids%(3, ids%()))
  assert_string_equals("fn_c", sym.id_to_name$(ids%(0)))
End Sub

Sub test_dynamic_call_given_no_arg()
  expect_transpile_error("'!dynamic_call", "!dynamic_call directive expects <id> argument")
End Sub

Sub test_dynamic_too_many_args()
  expect_transpile_error("'!dynamic_call foo bar", "!dynamic_call directive has too many arguments")
End Sub

Sub test_dynamic_too_many_names()
  Local i%, id%
  For i% = 0 To sym.MAX_NAMES% - 1
    id% = sym.add_name%("name_" + Str$(i%))
  Next
  expect_transpile_error("'!dynamic_call foo", "!dynamic_call directive invalid; too many names, max 300")
End Sub

Sub test_disable_format()
  Local directives$(1) = ("disable-format", "disable_format"), i%
  For i% = Bound(directives$(), 0) To Bound(directives$(), 1)
    opt.disable_format% = 0
    expect_transpile_omits("'!" + directives$(i%))
    assert_int_equals(1, opt.disable_format%)

    opt.disable_format% = 0
    expect_transpile_omits("'!" + directives$(i%) + " on")
    assert_int_equals(1, opt.disable_format%)

    opt.disable_format% = 1
    expect_transpile_omits("'!" + directives$(i%) + " off")
    assert_int_equals(0, opt.disable_format%)
  Next
End Sub

Sub test_disable_format_gvn_2_args()
  expect_transpile_error("'!disable-format on foo", "!disable-format directive has too many arguments")
End Sub

Sub test_disable_format_gvn_invalid()
  expect_transpile_error("'!disable-format foo", "!disable-format directive expects 'on|off' argument")
End Sub


Sub expect_replacement(i%, from$, to_$)
  assert_true(from$ = tr.replacements$(i%, 0), "Assert failed, expected from$ = '" + from$ + "', but was '" + tr.replacements$(i%, 0) + "'")
  assert_true(to_$  = tr.replacements$(i%, 1), "Assert failed, expected to_$ = '"   + to_$  + "', but was '" + tr.replacements$(i%, 1) + "'")
End Sub

Sub expect_token(i%, type%, txt$, start%)
  Local ok% = (lx.type(i) = type%)
  ok% = ok% And (lx.token$(i) = txt$)
  ok% = ok% And (lx.len(i%) = Len(txt$))
  If start% Then ok% = ok% And (lx.start%(i%) = start%)
  If Not ok% Then
    Local msg$ = "expected " + token_to_string$(type%, txt$, Len(txt$), start%)
    Cat msg$, ", found " + token_to_string$(lx.type(i), lx.token$(i), lx.len(i), lx.start(i))
    assert_fail(msg$)
  EndIf
End Sub

Function token_to_string$(type%, txt$, len%, start%)
  Local s$
  Cat s$, Str$(type%)
  Cat s$, ", " + txt$
  Cat s$, ", " + Str$(len%)
  If start% Then Cat s$, ", " + Str$(start%)
  token_to_string$ = "{ " + s$ + " }"
End Function

Sub expect_transpile_omits(line$)
  If lx.parse_basic%(line$) <> sys.SUCCESS Then
    assert_fail("Parse failed: " + line$)
  Else
    Local result% = tr.transpile%()
    If result% = tr.OMIT_LINE Then
      If lx.num <> 0 Then
        assert_fail("Omitted line contains " + Str$(lx.num) + " tokens: " + line$)
      EndIf
    Else
      assert_fail("Transpiler failed to omit line, result = " + Str$(result%) + " : " + line$)
    EndIf
  EndIf
  assert_no_error()
End Sub

Sub expect_transpile_succeeds(line$, expected_count%, type0%, txt0$)
  If lx.parse_basic%(line$) = sys.SUCCESS Then
    Local result% = tr.transpile%()
    If result% = sys.SUCCESS Then
      If lx.num = expected_count% Then
        If type0% Then expect_token(0, type0%, txt0$)
      Else
        assert_fail("Transpiled line expected " + Str$(expected_count%) + " tokens, found " + Str$(lx.num))
      EndIf
    Else
      assert_fail("Transpiler did not return SUCCESS, result = " + Str$(result%) + " : " + line$)
    EndIf
    assert_no_error()
  Else
    assert_fail("Parse failed: " + line$)
  EndIf
End Sub

Sub expect_transpile_error(line$, msg$)
  If lx.parse_basic%(line$) <> sys.SUCCESS Then
    assert_fail("Parse failed: " + line$)
  Else
    Local result% = tr.transpile%()
    If result% = sys.FAILURE Then
      assert_error(msg$)
    Else
      assert_fail("Transpiler did not return FAILURE, result = " + Str$(result%) + " : " + line$)
    EndIf
  EndIf
End Sub

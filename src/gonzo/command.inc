' Copyright (c) 2021-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMB4L 0.6.0

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("array", "console", "file", "history", "inifile", "map", "string", "spsh", "gonzo")
sys.provides("command")
If sys.err$ <> "" Then Error sys.err$

' @return  1 if the exit flag is set, otherwise 0.
Function cmd.do_command%(cmd$, argc%, argv$())
  Local call_cmd$, i%

  ' Ignore comments.
  If Left$(cmd$, 1) = "#" Then Exit Function

  ' If cmd$ is "R" or "REMOTE" then suffix the first argument with R and
  ' use that as the cmd$ instead, e.g. "REMOTE TYPE foo" => "RTYPE foo".
  If LCase$(cmd$) = "r" Or LCase$(cmd$) = "remote" And argc% > 0 Then
    cmd$ = "r" + argv$(0)
    For i% = 1 To argc% - 1
      argv$(i% - 1) = argv$(i%)
    Next
    argv$(argc% - 1) = ""
    Inc argc%, -1
  EndIf

  ' Lookup command.
  Restore gonzo_commands
  Local synonyms$, usage$, description$
  Do
    Read synonyms$, usage$, description$
    If synonyms$ = "<END>" Then Exit Do
    If InStr(synonyms$, "|" + LCase$(cmd$) + "|") Then
      call_cmd$ = Mid$(synonyms$, 2, InStr(2, synonyms$, "|") - 2)
    EndIf
  Loop Until call_cmd$ <> ""

  sys.err$ = ""
  If call_cmd$ = "" Then sys.err$ = "Unknown command '" + cmd$ + "'"
  If call_cmd$ = "!" Then call_cmd$ = "bang"

  If sys.err$ = "" Then
    On Error Skip 1
    Call "cmd." + call_cmd$, cmd$, argc%, argv$()
    If Mm.ErrMsg$ <> "" Then sys.err$ = Mm.ErrMsg$
  EndIf

  If sys.err$ <> "" Then con.errorln(sys.err$)

  cmd.do_command% = gonzo.exit_flag%
End Function

Sub cmd.bang(cmd$, argc%, argv$())
  If Not gonzo.check_arg_count%(cmd$, argc%, 1) Then Exit Sub
  Local idx% = Val(argv$(0))
  If idx% <= 0 Then sys.err$ = gonzo.usage$(cmd$) : Exit Sub
  idx% = history.newest%(gonzo.history%()) - idx%
  Local cmd.line$ = Choice(idx% < 0, "", history.get$(gonzo.history%(), idx%))
  If cmd.line$ = "" Then sys.err$ = "Event not found" : Exit Sub
  If Left$(cmd.line$, 1) = "!" Then sys.err$ = "Unexpected ! event" : Exit Sub
  history.push(gonzo.history%(), cmd.line$)
  gonzo.parse_cmd.line(cmd.line$, cmd$, argc%, argv$())
  If cmd$ <> "" Then gonzo.exit_flag% = cmd.do_command%(cmd$, argc%, argv$())
  sys.err$ = "" ' So that we don't repeat error message twice.
End Sub

Sub cmd.break(cmd$, argc%, argv$())
  If Not gonzo.check_arg_count%(cmd$, argc%, 0) Then Exit Sub
  gonzo.send_break()
  gonzo.read_until_prompt()
End Sub

Sub cmd.chdir(cmd$, argc%, argv$())
  If Not gonzo.check_arg_count%(cmd$, argc%, 1) Then Exit Sub
  spsh.cmd_chdir(cmd$, argc%, argv$())
End Sub

Sub cmd.cls(cmd$, argc%, argv$())
  If Not gonzo.check_arg_count%(cmd$, argc%, 0) Then Exit Sub
  Cls
End Sub

Sub cmd.connect(cmd$, argc%, argv$())
  Local comspec$, i%

  If argc% = 0 Then
    comspec$ = gonzo.prompt_for_comspec$()
  Else
    If Left$(argv$(0), 8) = "/dev/tty" Then
      comspec$ = argv$(0)
    ElseIf Left$(argv$(0), 3) = "tty" Then
      comspec$ = "/dev/" + argv$(0)
    Else
      comspec$ = "/dev/tty" + argv$(0)
    EndIf
    For i% = 1 To argc% - 1
      Cat comspec$, "," + argv$(i%)
    Next
  EndIf

  If sys.break_flag% Then
    Print
  Else
    gonzo.comspec$ = comspec$
    gonzo.connect(1)
  EndIf
End Sub

Sub cmd.device(cmd$, argc%, argv$())
  con.println(gonzo.device_name$)
End Sub

Sub cmd.exit(cmd$, argc%, argv$())
  If Not gonzo.check_arg_count%(cmd$, argc%, 0) Then Exit Sub
  gonzo.exit_flag% = 1
End Sub

Sub cmd.files(cmd$, argc%, argv$())
  If Not gonzo.check_arg_max%(cmd$, argc%, 1) Then Exit Sub
  spsh.cmd_files(cmd$, argc%, argv$())
End Sub

Sub cmd.help(cmd$, argc%, argv$())
  If Not gonzo.check_arg_max%(cmd$, argc%, 1) Then Exit Sub

  If argc% = 1 Then
    con.println(gonzo.usage$(argv$(0)))
    Exit Sub
  EndIf

  con.println("Commands are:")
  Restore gonzo_commands
  Local synonyms$, usage$, description$
  Do
    Read synonyms$, usage$, description$
    If synonyms$ = "<END>" Then Exit Do
    synonyms$ = Mid$(synonyms$, 2, InStr(2, synonyms$, "|") - 2)
    con.println("  " + str.rpad$(synonyms$, 10) + "  " + description$)
  Loop
End Sub

Sub cmd.history(cmd$, argc%, argv$())
  If Not gonzo.check_arg_count%(cmd$, argc%, 0) Then Exit Sub
  Local i%, s$, newest% = history.newest%(gonzo.history%())
  For i% = history.count%(gonzo.history%()) - 1 To 0 Step -1
    s$ = history.get$(gonzo.history%(), i%)
    If s$ = "" Then Exit Do
    con.println(" " + str.lpad$(Str$(newest% - i%), 3) + " " + s$)
  Next
End Sub

Sub cmd.log(cmd$, argc%, argv$())
  If argc% = 1 And UCase$(argv$(0)) = "CLEAR" Then
    Close #gonzo.LOG_FNBR
    Open gonzo.LOG_FILE For Output As gonzo.LOG_FNBR
    Exit Sub
  ElseIf Not gonzo.check_arg_count%(cmd$, argc%, 0)
    Exit Sub
  EndIf

  Open gonzo.LOG_FILE For Input As #gonzo.IN_FNBR
  con.foreground("white")
  Local c%, ch$
  Do While Not Eof(#gonzo.IN_FNBR)
    ch$ = Input$(1, #gonzo.IN_FNBR)
    c% = Asc(ch$)
    Select Case c%
      Case 0 To 31, 127 To 255
        con.foreground("green")
        Print "<" Hex$(c%, 2) ">";
        con.foreground("white")
        If c% = &h0A Then Print
      Case Else
        Print ch$;
    End Select
  Loop
  Close #gonzo.IN_FNBR
  con.println()
  con.foreground("default")
End Sub

Sub cmd.pwd(cmd$, argc%, argv$())
  If Not gonzo.check_arg_count%(cmd$, argc%, 0) Then Exit Sub
  spsh.cmd_pwd(cmd$, argc%, argv$())
End Sub

Sub cmd.rchdir(cmd$, argc%, argv$())
  If Not gonzo.check_arg_count%(cmd$, argc%, 1) Then Exit Sub
  Local file$ = str.unquote$(argv$(0))
  gonzo.remote_file_cmd("ChDir " + str.quote$(file$))
End Sub

Sub cmd.rcls(cmd$, argc%, argv$())
  If Not gonzo.check_arg_count%(cmd$, argc%, 0) Then Exit Sub
  gonzo.send_break()
  gonzo.read_until_prompt()
  gonzo.writeln("cls")
  gonzo.read_until_match("> cls")
End Sub

Sub cmd.rename(cmd$, argc%, argv$())
  If Not gonzo.check_arg_count%(cmd$, argc%, 2) Then Exit Sub
  spsh.cmd_rename(cmd$, argc%, argv$())
End Sub

Sub cmd.rexec(cmd$, argc%, argv$())
  If Not gonzo.check_connection%() Then Exit Sub

  gonzo.send_break()
  gonzo.read_until_prompt()
  Local command$
  If argc% = 1 Then
    command$ = str.replace$(str.unquote$(argv$(0)), "\" + Chr$(34), Chr$(34))
  Else
    command$ = array.join_strings$(argv$(), " ", 0, argc%)
  EndIf
  gonzo.writeln(command$)
  gonzo.read_until_match("> " + command$)
  con.foreground("white")
  gonzo.clear_buf()
  gonzo.read_until_prompt(ECHO Or SKIP_EMPTY)
  con.foreground("yellow")
End Sub

Sub cmd.rcopy(cmd$, argc%, argv$())
  Local src$, dst$
  Select Case argc%
    Case 2
      src$ = str.unquote$(argv$(0))
      dst$ = str.unquote$(argv$(1))
    Case 3
      If UCase$(argv$(1)) <> "TO" Then
        sys.err$ = "syntax"
      Else
        src$ = str.unquote$(argv$(0))
        dst$ = str.unquote$(argv$(2))
      EndIf
    Case Else
      sys.err$ = gonzo.usage$(cmd$)
      Exit Sub
  End Select

  gonzo.remote_file_cmd("Copy " + str.quote$(src$) + " To " + str.quote$(dst$))
End Sub

Sub cmd.rdelete(cmd$, argc%, argv$())
  If Not gonzo.check_arg_count%(cmd$, argc%, 1) Then Exit Sub
  Local file$ = str.unquote$(argv$(0))
  gonzo.remote_file_cmd("Kill " + str.quote$(file$))
End Sub

Sub cmd.receive(cmd$, argc%, argv$())
  If Not gonzo.check_connection%() Then Exit Sub
  If Not gonzo.check_arg_range%(cmd$, argc%, 1, 2) Then Exit Sub
  Local remote_file$ = str.unquote$(argv$(0))

  Local file_size% = gonzo.get_file_size%(remote_file$)
  If sys.err$ <> "" Then Exit Sub
  Local local_file$ = Choice(argc% = 1, file.get_name$(remote_file$), argv$(1))

  ' Send LIST command.
  Local command$ = "List " + str.quote$(remote_file$)
  gonzo.writeln(command$)
  gonzo.read_until_match("> " + command$)

  ' Open the file to receive.
  Open file.get_name$(local_file$) For Output As #gonzo.OUT_FNBR

  con.println("Autosave receiving " + Str$(file_size%) +  + " bytes to '" + local_file$ + "'...")
  Local t% = Timer

  ' Read lines and echo them to the file.
  Local count% = 0, s$, x%
  Local term$ = Chr$(27) + "[?25h" + Chr$(27) + "[37m" + Chr$(27) + "[m"
  Do While Not sys.break_flag%
    x% = gonzo.getln%(s$)
    If Not x% Then
      If gonzo.rx_buf$ = "> " Then Exit Do
      gonzo.handle_press_any_key()
      Continue Do
    EndIf

    If s$ = term$ Then Exit Do
    If Left$(s$, 8) = "Error : " Then Exit Do
    Print #gonzo.OUT_FNBR, s$ Chr$(&h0A);
    Inc count%
    con.println(Choice(count% > 1, Chr$(27) + "[1F", "") + "Received " + Str$(count%) + " lines")
  Loop

  Close #gonzo.OUT_FNBR

  If sys.break_flag% Then sys.err$ = "Interrupted by user"
  If sys.err$ = "" Then con.println("OK, " + Str$((file_size% * 8000) / (Timer - t%), 0, 1) + " bit/s")
End Sub

Sub cmd.rfiles(cmd$, argc%, argv$())
  If Not gonzo.check_connection%() Then Exit Sub
  If Not gonzo.check_arg_max%(cmd$, argc%, 2) Then Exit Sub

  Local d$ = Choice(argv$(0) = "", "*", str.unquote$(argv$(0)))
  If file.is_directory%(d$) Then Cat d$, "/*"

  gonzo.send_break()
  gonzo.read_until_prompt()
  Local command$ = Choice(gonzo.device% = gonzo.DEVICE_CMM2, "Ls ", "Files ") + str.quote$(d$)
  gonzo.writeln(command$)
  gonzo.read_until_match("> " + command$)

  Local x%, s$
  Do
    x% = gonzo.getln%(s$)
    If Not x% Then
      gonzo.handle_press_any_key()
    ElseIf s$ <> "" Then
      If Left$(s$, 1) <> ">" Then con.println(str.trim$(s$))
      If Left$(s$, 8) = "Error : " Then Exit Do
    EndIf
  Loop Until file.fnmatch%("* director*file*", s$)
End Sub

Sub cmd.rmkdir(cmd$, argc%, argv$())
  If Not gonzo.check_arg_count%(cmd$, argc%, 1) Then Exit Sub
  Local file$ = str.unquote$(argv$(0))
  gonzo.remote_file_cmd("MkDir " + str.quote$(file$))
End Sub

Sub cmd.rpwd(cmd$, argc%, argv$())
  If Not gonzo.check_arg_count%(cmd$, argc%, 0) Then Exit Sub

  gonzo.send_break()
  gonzo.read_until_prompt()
  Local command$ = "? Cwd$"
  gonzo.writeln(command$)
  gonzo.read_until_match("> " + command$)
  gonzo.read_until_prompt(ECHO Or SKIP_EMPTY)
End Sub

Sub cmd.rrename(cmd$, argc%, argv$())
  Local src$, dst$
  Select Case argc%
    Case 2
      src$ = str.unquote$(argv$(0))
      dst$ = str.unquote$(argv$(1))
    Case 3
      If UCase$(argv$(1)) <> "AS" Then
        sys.err$ = "syntax"
      Else
        src$ = str.unquote$(argv$(0))
        dst$ = str.unquote$(argv$(2))
      EndIf
    Case Else
      sys.err$ = gonzo.usage$(cmd$)
      Exit Sub
  End Select

  gonzo.remote_file_cmd("Rename " + str.quote$(src$) + " As " + str.quote$(dst$))
End Sub

Sub cmd.rsize(cmd$, argc%, argv$())
  If Not gonzo.check_arg_count%(cmd$, argc%, 1) Then Exit Sub
  Local file$ = str.unquote$(argv$(0))
  Local size% = gonzo.get_file_size%(file$)
  If sys.err$ = "" Then con.println(Str$(size%))
End Sub

Sub cmd.rtype(cmd$, argc%, argv$())
  If Not gonzo.check_arg_count%(cmd$, argc%, 1) Then Exit Sub
  Local file$ = str.unquote$(argv$(0))

  gonzo.send_break()
  gonzo.read_until_prompt()
  Local command$ = "List " + str.quote$(file$)
  gonzo.writeln(command$)
  gonzo.read_until_match("> " + command$)

  ' Read lines and echo them to the file until we reach a prompt.
  Local s$, x%
  Do While Not sys.break_flag%
    x% = gonzo.getln%(s$)
    If x% Then
      con.println(s$)
    Else
      If Left$(gonzo.rx_buf$, 2) = "> " Then Exit Do
      gonzo.handle_press_any_key()
    EndIf
  Loop
End Sub

Sub cmd.send(cmd$, argc%, argv$())
  If Not gonzo.check_connection%() Then Exit Sub

  Local xcmd%
  Select Case cmd$
    Case "put", "send"
      xcmd% = 0
    Case "xput", "xsend"
      xcmd% = 1
    Case Else
      sys.err$ "Error: invalid '" + cmd$ + "' command"
      Exit Sub
  End Select

  Local i%, p%, run_flag%, trans_args$, trans_flag%
  For i% = 0 To argc% - 1
    If Left$(argv$(i%), 1) <> "-" Then Exit For

    If InStr(argv$(i%), "-t=") = 1 Or InStr(argv$(i%), "--trans=") = 1) Then
      p% = InStr(argv$(i%), "=")
      trans_args$ = str.unquote$(Mid$(argv$(i%), p% + 1))
      argv$(i%) = "-t"
    EndIf

    Select Case LCase$(argv$(i%))
      Case "-r", "--run"
        run_flag% = 1
      Case "-t", "--trans"
        trans_flag% = 1
      Case Else
        sys.err$ = "Error: unknown option '" + argv$(i%) + "'"
        Exit Sub
    End Select
  Next

  If argc% - i% <= 0 Or argc% - i% > 2 Then
    sys.err$ = gonzo.usage$(cmd$)
    Exit Sub
  EndIf

  Local local_file$ = str.unquote$(argv$(i%))
  If Not file.exists%(local_file$) Then
    sys.err$ = "Error: file not found"
    Exit Sub
  EndIf

  Local remote_file$ = Choice(argc% - i% = 1, file.get_name$(local_file$), str.unquote$(argv$(i% + 1)))

  ' Transpile file if requested.
  Local command$, tmp_file$
  If trans_flag% Then
    tmp_file$ = sys.string_prop$("tmpdir") + "/gonzo.trans." + Str$(Int(Rnd() * 1e6))
    On Error Skip 1
    Kill tmp_file$
    On Error Clear
    If gonzo.transpile%(local_file$, tmp_file$, trans_args$) <> 0 Then Exit Sub
    local_file$ = tmp_file$
    ' Replace .bpp file-extension with .bas.
    If LCase$(file.get_extension$(remote_file$)) = ".bpp" Then
      remote_file$ = Left$(remote_file$, Len(remote_file$) - 4) + ".bas"
    EndIf
  EndIf

  If xcmd% Then
    gonzo.xsend_file(local_file$, remote_file$)
  Else
    gonzo.send_file(local_file$, remote_file$, 1)
  EndIf
  If sys.err$ <> "" Then Exit Sub

  If run_flag% Then
    command$ = "Run " + str.quote$(remote_file$)
    gonzo.writeln(command$)
    gonzo.read_until_match("> " + command$)
    con.foreground("white")
    gonzo.read_until_prompt(ECHO) ' TODO
  ElseIf xcmd% And LCase$(file.get_extension$(remote_file$)) = ".bas" Then
    If gonzo.device% <> gonzo.DEVICE_CMM2 Then
      ' For desinations other than the CMM2 (which has no LOAD command) we
      ' we automatically LOAD a sent .bas file so that RUN with no argument
      ' will execute it.
      gonzo.writeln("Load " + str.quote$(remote_file$))
    EndIf
    gonzo.read_until_prompt()
  EndIf
End Sub

Sub cmd.take(cmd$, argc%, argv$())
  If Not gonzo.check_connection%() Then Exit Sub
  If Not gonzo.check_arg_count%(cmd$, argc%, 1) Then Exit Sub
  Local local_file$ = str.unquote$(argv$(0))
  If Not gonzo.check_file_exists%(local_file$) Then Exit Sub
  con.open_in(gonzo.CONSOLE_FNBR, local_file$)
End Sub

Sub cmd.term(cmd$, argc%, argv$())
  If Not gonzo.check_connection%() Then Exit Sub
  If Not gonzo.check_arg_count%(cmd$, argc%, 0) Then Exit Sub

  gonzo.update_title("TERMINAL")
  con.println("(Connected to remote host, type ^]C to get back.)")
  con.foreground("white")

  Do While Inkey$ <> "" : Loop

  On Error Ignore

  Local ch%, escape_flag%, s$
  Do
    ' Pass Ctrl-C onto the remote.
    If sys.break_flag% Then
      sys.break_flag% = 0
      gonzo.send_break()
    EndIf

    ' Read from remote, write to local.
    ch% = gonzo.getc%(0)
    If ch% > 0 Then con.print(Chr$(ch%));

    ' Read from local.
    s$ = Inkey$
    If Mm.ErrNo Then Exit Do
    If s$ = "" Then Continue Do
    If escape_flag% Then
      escape_flag% = 0
      Select Case LCase$(s$)
        Case "c"        : Exit Do ' Exit from terminal.
        Case Chr$(&h1D)           ' Write escape character to the remote.
        Case Else       : s$ = "" ' Ignore unrecognised escape.
      End Select
    Else
      Select Case s$
        Case Chr$(&h0A) : s$ = Chr$(&h0D)  ' Use CR '\r' to end lines.
        Case Chr$(&h1D) : escape_flag% = 1 ' Ctrl-]
      End Select
    EndIf

    ' Write to remote.
    If Not escape_flag% And s$ <> "" Then gonzo.write(s$)

  Loop While Mm.ErrNo = 0

  con.foreground("yellow")
  ' If Pos > 1 Then con.println()
  con.println("(Back at local Gonzo.)")

  Select Case Mm.ErrNo
    Case 0
      ' Do nothing
    Case 5
      sys.err$ = "Error: connection lost"
      gonzo.device_name$ = "DISCONNECTED"
      gonzo.device% = gonzo.DEVICE_DISCONNECTED
    Case Else
      sys.err$ = Mm.ErrMsg$
  End Select

  On Error Clear

  If Pos > 1 Then con.println()
  Console ShowCursor

  gonzo.update_title()
End Sub

Sub cmd.trans(cmd$, argc%, argv$())
  If Not gonzo.check_arg_min%(cmd$, argc%, 1) Then Exit Sub
  Local command$ = "mmbasic " + Mm.Info$(Path) + "../sptrans/sptrans.bas"
  Local cmdline$ = array.join_strings$(argv$(), " ", 0, argc%)
  System command$ + " " + cmdline$
End Sub

Sub cmd.type(cmd$, argc%, argv$())
  If Not gonzo.check_arg_count%(cmd$, argc%, 1) Then Exit Sub
  spsh.cmd_type(cmd$, argc%, argv$())
End Sub

Sub cmd.version(cmd$, argc%, argv$())
  If Not gonzo.check_arg_min%(cmd$, argc%, 0) Then Exit Sub

  ' TODO: duplicated from common/sptools.inc
  con.println("gonzo (SP Tools) Release " + sys.VERSION$ + " for MMB4L 2022.01.00")
  con.println("Copyright (c) 2021-2022 Thomas Hugo Williams")
  con.println("A Toy Plastic Trumpet Production for Sockpuppet Studios.")
  con.println("License MIT <https://opensource.org/licenses/MIT>")
  con.println("This is free software: you are free to change and redistribute it.")
  con.println("There is NO WARRANTY, to the extent permitted by law.")
End Sub

Sub cmd.xreceive(cmd$, argc%, argv$())
  If Not gonzo.check_connection%() Then Exit Sub
  If Not gonzo.check_arg_range%(cmd$, argc%, 1, 2) Then Exit Sub
  Local remote_file$ = str.unquote$(argv$(0))

  Local file_size% = gonzo.get_file_size%(remote_file$)
  If sys.err$ <> "" Then Exit Sub
  Local local_file$ = Choice(argc% = 1, file.get_name$(remote_file$), argv$(1))

  ' Send XMODEM SEND command.
  Local command$ = "XModem Send " + str.quote$(remote_file$)
  gonzo.writeln(command$)
  gonzo.read_until_match("> " + command$)
  Local s$
  If gonzo.getln%(s$) Then
    sys.err$ = gonzo.extract_error$(s$)
    If sys.err$ <> "" Then Exit Sub
  EndIf

  con.println("XModem receiving " + Str$(file_size%) + " bytes to '" + local_file$ + "'...")
  Local t% = Timer
  XModem Receive local_file$, #gonzo.SERIAL_FNBR, 1

  If sys.err$ = "" Then
    ' Trim padding off received file.
    Open local_file$ For Input As #gonzo.IN_FNBR
    Local tmp_file$ = sys.string_prop$("tmpdir") + "/" + local_file$
    Open tmp_file$ For Output As #gonzo.OUT_FNBR
    Local remaining% = file_size%
    Do While remaining% > 0
      s$ = Input$(Min(255, remaining%), #gonzo.IN_FNBR)
      Print #gonzo.OUT_FNBR, s$;
      Inc remaining%, -Min(255, remaining%)
    Loop
    Close #gonzo.OUT_FNBR
    Close #gonzo.IN_FNBR
    Copy tmp_file$ To local_file$
  EndIf

  If sys.err$ = "" Then con.println("OK, " + Str$((file_size% * 8000) / (Timer - t%), 0, 1) + " bit/s")
End Sub

Sub cmd.xsend(cmd$, argc%, argv$())
  cmd.send(cmd$, argc%, argv$())
End Sub

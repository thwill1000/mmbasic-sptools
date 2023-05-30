' Copyright (c) 2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

'!ifndef NO_INCLUDE_GUARDS
On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("ctrl", "sound", "string", "txtwm")
sys.provides("menu")
If sys.err$ <> "" Then Error sys.err$
'!endif

Sub menu.init(ctrl$, callback$)
  Dim YES_NO_BTNS$(1) Length 3 = ("Yes", "No")

  Dim menu.callback$ = callback$, menu.ctrl$ = ctrl$
  Dim menu.item_count%, menu.max_item_width%, menu.offset_x%, menu.offset_y%
  Dim menu.selection%, menu.title$', menu.version$

  Font 1
  Dim menu.height% = Mm.VRes \ Mm.Info(FontHeight)
  Dim menu.width% = Mm.HRes \ Mm.Info(FontWidth)
  Local sz%
  Inc sz%, 7 + 2 * menu.height% * menu.width%
  Inc sz%, 7 + 2 * (menu.height% - 10) * (menu.width% - 10)
  twm.init(2, sz%)
  Dim menu.win1% = twm.new_win%(0, 0, menu.width%, menu.height%)
  Dim menu.win2% = twm.new_win%(5, 5, menu.width% - 10, menu.height% - 10)
End Sub

Sub menu.term(msg$)
  sys.restore_break()
  twm.enable_cursor(1)
  Page Write 0
  Cls
  If Len(msg$) Then Text 160, 110, msg$, CM
End Sub

Sub menu.on_break()
  menu.term("Exited due to Ctrl-C")
  End
End Sub

Sub menu.load_data(data_label$)
  Read Save
  Restore data_label$
  Read menu.title$
  menu.item_count% = 0
  menu.max_item_width% = 0
  menu.selection% = 0
  Local item$
  Do
    Read item$
    If Not Len(item$) Then Exit Do
    Inc menu.item_count%
    ' Don't use FIELD$() here because we want to respect whitespace.
    item$ = str.decode$(Left$(item$, InStr(item$, "|") - 1))
    menu.max_item_width% = Max(menu.max_item_width%, Len(item$))
  Loop

  On Error Skip
  Erase menu.items$()
  Dim menu.items$(menu.item_count% - 1)
  Local i%
  Restore data_label$
  Read menu.title$
  For i% = 0 To menu.item_count% - 1
    Read menu.items$(i%)
    menu.items$(i%) = str.decode$(menu.items$(i%))
  Next
  Read Restore

  If Len(menu.callback$) Then Call menu.callback$, "open|" + data_label$
End Sub

Sub menu.render()
  twm.switch(menu.win1%)
  twm.cls()
  twm.foreground(twm.WHITE%)
  twm.box(0, 0, menu.width%, menu.height%)

  ' Title.
  twm.foreground(twm.YELLOW%)
  twm.print_at(1, 2, str.centre$(str.decode$(menu.title$), menu.width% - 2))
  twm.foreground(twm.WHITE%)

  ' Items.
  menu.offset_x% = (menu.width% - menu.max_item_width% - 2) \ 2
  menu.offset_y% = 4
  Local i%
  For i% = 0 To menu.item_count% - 1
    menu.render_item(i%)
  Next

  If Len(menu.callback$) Then Call menu.callback$, "render"

  Page Copy 1 To 0, B
End Sub

Sub menu.render_item(idx%)
  twm.inverse(idx% = menu.selection%)
  ' Don't use FIELD$() here because we want to respect whitespace.
  Local item$ = Left$(menu.items$(idx%), InStr(menu.items$(idx%), "|") - 1)
  item$ = " " + item$ + " " 'str.centre$(item$, menu.max_item_width% + 2)
  Local x% = menu.offset_x% + (menu.max_item_width% + 2 - Len(item$)) \ 2
  twm.print_at(x%, idx% + menu.offset_y%, item$)
  twm.inverse(0)
End Sub

Sub menu.main_loop()
  Local cmd$, key%, new_sel%
  Do
    If sys.break_flag% Then menu.on_break()
    Call menu.ctrl$, key%
    If Not key% Then keys_cursor(key%)
    If Not key% Then Continue Do

    Select Case key%
      Case ctrl.A, ctrl.LEFT, ctrl.RIGHT
        ' TODO: there is a bug in CALL which means it can't handle the case
        '       where an expression that provides the command name contains a
        '       comma or single-quote.
        cmd$ = Field$(menu.items$(menu.selection%), 2, "|")
        Call cmd$, key%

      Case ctrl.B
        If Len(menu.callback$) Then Call menu.callback$, "ctrl|b"

      Case ctrl.DOWN, ctrl.UP
        new_sel% = menu.selection%
        Do
          Inc new_sel%, Choice(key% = ctrl.DOWN, 1, -1)
          If new_sel% < 0 Or new_sel% >= menu.item_count% Then
            If new_sel% < 0 Then new_sel% = 0
            If new_sel% >= menu.item_count% Then new_sel% = menu.item_count% - 1
            menu.play_invalid_fx(1)
            Exit Do
          EndIf
        Loop Until Len(Field$(menu.items$(new_sel%), 1, "|"))
        menu.select(new_sel%)

      Case ctrl.START
        If Len(menu.callback$) Then Call menu.callback$, "ctrl|start"

      Case ctrl.SELECT
        If Len(menu.callback$) Then Call menu.callback$, "ctrl|select"

      Case Else
        menu.play_invalid_fx(1)
    End Select

    Pause 50
  Loop
End Sub

Sub menu.select(new_sel%)
  If new_sel% = menu.selection% Then Exit Sub
  menu.play_valid_fx(1)
  Local old_sel% = menu.selection%
  menu.selection% = new_sel%
  Page Write 1
  menu.render_item(menu.selection%)
  menu.render_item(old_sel%)
  If Len(menu.callback$) Then Call menu.callback$, "select"
  Page Copy 1 To 0 , B
End Sub

Sub menu.cmd_open(key%)
  If key% <> ctrl.A Then menu.play_invalid_fx(1) : Exit Sub
  menu.play_valid_fx(1)
  menu.load_data(Field$(menu.items$(menu.selection%), 3, "|"))
  menu.render()
End Sub

Sub menu.play_valid_fx(block%)
  sound.play_fx(sound.FX_SELECT%())
  If block% Then Do While sound.is_playing%() : Loop
End Sub

Sub menu.play_invalid_fx(block%)
  sound.play_fx(sound.FX_BLART%())
  If block% Then Do While sound.is_playing%() : Loop
End Sub

Function menu.msgbox%(msg$, buttons$(), default%)
  menu.msgbox% = default%

  Local base% = Mm.Info(Option Base), num% = Bound(buttons$(), 1) - base% + 1
  Local ch%, i%, key%, released%, valid% = 1, word$, x%(num%)
  x%(base%) = 2
  For i% = base% + 1 To base% + num% - 1
    x%(i%) = x%(i% - 1) + Len(buttons$(i% - 1)) + 5
  Next

  twm.switch(menu.win2%)
  twm.cls()
  twm.foreground(twm.CYAN%)
  twm.box(0, 0, twm.w%, twm.h%)
  twm.foreground(twm.WHITE%)

  ' Basic word wrapping.
  twm.x% = 2 : twm.y% = 1
  For i% = 1 To Len(msg$) + 1
    ch% = Choice(i% > Len(msg$), &h20, Peek(Var msg$, i%))
    Select Case ch%
      Case &h0A ' \n
        twm.print(word$ + " ")
        twm.x% = 2
        Inc twm.y%
        word$ = ""
      Case &h0D
        If i% = Len(msg$) Or Peek(Var msg$, i% + 1) <> &h0A Then
          twm.print(word$ + " ")
          twm.x% = 2
          Inc twm.y%
          word$ = ""
        EndIf
      Case &h20
        If twm.x% + Len(word$) > twm.w% - 2 Then twm.x% = 2 : Inc twm.y%
        twm.print(word$ + " ")
        word$ = ""
      Case Else
        Cat word$, Chr$(ch%)
    End Select
  Next

  Do
    If sys.break_flag% Then menu.on_break()
    If valid% Then
      For i% = base% To base% + num% - 1
        menu.button(x%(i%), twm.h% - 4, buttons$(i%), menu.msgbox% = i%)
      Next
      Page Copy 1 To 0 , B
      valid% = 0
    EndIf
    Call menu.ctrl$, key%
    If Not key% Then keys_cursor(key%)
    If Not key% Then released% = 1 : Continue Do
    If Not released% Then key% = 0 : Continue Do
    valid% = 0
    Select Case key%
      Case ctrl.A
        valid% = 1
      Case ctrl.LEFT
        If menu.msgbox% = 1 Then menu.msgbox% = 0 : valid% = 1
      Case ctrl.RIGHT
        If menu.msgbox% = 0 Then menu.msgbox% = 1 : valid% = 1
    End Select
    If valid% Then menu.play_valid_fx(1) Else menu.play_invalid_fx(1)
  Loop Until key% = ctrl.A
End Function

Sub menu.button(x%, y%, txt$, selected%)
  twm.lock_vga_cursor(1)
  twm.box1(x%, y%, Len(txt$) + 4, 3)
  If selected% Then twm.inverse(1)
  twm.print_at(x% + 2, y% + 1, txt$)
  If selected% Then twm.inverse(0)
  twm.lock_vga_cursor(0)
End Sub

' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.requires("options")
sys.provides("console")
If sys.err$ <> "" Then Error sys.err$
'!endif

Sub con.endl(always%)
  If Not Len(opt.outfile$) Then Exit Sub
  If Not always% And opt.quiet Then Exit Sub
  Print
End Sub

Sub con.out(s$, always%)
  If Not Len(opt.outfile$) Then Exit Sub
  If Not always% And opt.quiet Then Exit Sub
  Print s$;
End Sub

Sub con.error(msg$)
  Const i% = in.num_open_files% - 1
  Print
  If i% >= 0 Then Print "[" + in.files$(i%) + ":" + Str$(in.line_num%(i%)) + "] ";
  Print "Error: " + msg$
  If Mm.Device$ = "MMB4L" Then End 1 Else End
End Sub

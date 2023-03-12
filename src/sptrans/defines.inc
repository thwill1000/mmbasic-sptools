' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("set")
sys.provides("defines")
If sys.err$ <> "" Then Error sys.err$

' Set of active flags
'   - set at command line using -D<flag>,
'   - or in program using !set directive.
Const def.FLAG_MAX_LENGTH% = 64
Dim def.flags$(set.new%(10)) Length def.FLAG_MAX_LENGTH%

Sub def.init()
  set.init(def.flags$())
End Sub

Sub def.clear_flag(flag$)
  Local s$ = str.trim$(flag$), lower$ = LCase$(s$)

  If s$ = "" Then
    sys.err$ = "invalid flag"
  Else If Len(s$) > def.FLAG_MAX_LENGTH% Then
    sys.err$ = "flag too long, max 64 chars"
  Else If InStr("|1|true|on|0|false|off|", "|" + lower$ + "|") Then
    sys.err$ = "flag '" + s$ + "' cannot be cleared"
  Else If def.is_flag_set%(lower$) Then
    set.remove(def.flags$(), lower$)
  Else
    sys.err$ = "flag '" + s$ + "' is not set"
  EndIf
End Sub

' @return  1 if the flag$ is set, 0 if it is not.
Function def.is_flag_set%(flag$)
  Local s$ = str.trim$(flag$)
  If Len(s$) > def.FLAG_MAX_LENGTH% Then
    sys.err$ = "flag too long, max 64 chars"
  Else If InStr("|1|true|on|", "|" + LCase$(s$) + "|") Then
    def.is_flag_set% = 1
  Else If InStr("|0|false|off|", "|" + LCase$(s$) + "|") Then
    def.is_flag_set% = 0
  Else
    def.is_flag_set% = set.get%(def.flags$(), LCase$(s$)) <> -1
  Endif
End Function

Sub def.set_flag(flag$)
  Local i%, s$ = str.trim$(flag$), lower$ = LCase$(s$)
  sys.err$ = "invalid flag"

  If s$ = "" Then Exit Sub

  If Len(s$) > def.FLAG_MAX_LENGTH% Then
    sys.err$ = "flag too long, max 64 chars"
    Exit Sub
  EndIf

  If InStr("|1|true|on|0|false|off|", "|" + lower$ + "|") Then
    sys.err$ = "flag '" + s$ + "' cannot be set"
    Exit Sub
  EndIf

  If Not InStr("_abcdefghijklmnopqrstuvwxyz", Mid$(lower$, 1, 1)) Then Exit Sub
  For i% = 2 To Len(lower$)
    If Not InStr("_abcdefghijklmnopqrstuvwxyz0123456789", Mid$(lower$, i%, 1)) Then Exit Sub
  Next

  If set.get%(def.flags$(), lower$) <> -1 Then
    sys.err$ = "flag '" + s$ + "' is already set"
    Exit Sub
  EndIf

  If set.is_full%(def.flags$()) Then
     sys.err$ = "too many flags"
     Exit Sub
  EndIf

  sys.err$ = ""
  set.put(def.flags$(), lower$)
End Sub

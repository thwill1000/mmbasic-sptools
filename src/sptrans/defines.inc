' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.requires("set")
sys.provides("defines")
If sys.err$ <> "" Then Error sys.err$
'!endif

Const def.CONSTANTS$ = "|1|true|on|0|false|off|"

' Set of active defines
'   - set at command line using -D<flag>,
'   - or in program using !DEFINE directive.
Const def.ID_MAX_LENGTH% = 64
Dim def.defines$(set.new%(10)) Length def.ID_MAX_LENGTH%

Sub def.init()
  set.init(def.defines$())
End Sub

' Undefines the given define.
'
' Undefining an already undefined symbol is an allowed no-op.
Sub def.undefine(id$)
  Local s$ = str.trim$(id$), lower$ = LCase$(s$)

  If s$ = "" Then
    sys.err$ = "invalid identifier"
  Else If Len(s$) > def.ID_MAX_LENGTH% Then
    sys.err$ = "identifier too long, max 64 chars"
  Else If InStr(def.CONSTANTS$, "|" + lower$ + "|") Then
    sys.err$ = "'" + s$ + "' cannot be undefined"
  Else If def.is_defined%(lower$) Then
    set.remove(def.defines$(), lower$)
  EndIf
End Sub

' @return  1 if the id$ is defined, 0 if it is not.
Function def.is_defined%(id$)
  Local s$ = str.trim$(id$)
  If Len(s$) > def.ID_MAX_LENGTH% Then
    sys.err$ = "identifier too long, max 64 chars"
  Else If InStr("|1|true|on|", "|" + LCase$(s$) + "|") Then
    def.is_defined% = 1
  Else If InStr("|0|false|off|", "|" + LCase$(s$) + "|") Then
    def.is_defined% = 0
  Else
    def.is_defined% = set.get%(def.defines$(), LCase$(s$)) <> -1
  Endif
End Function

Sub def.define(id$)
  Local i%, s$ = str.trim$(id$), lower$ = LCase$(s$)
  sys.err$ = "invalid identifier"

  If s$ = "" Then Exit Sub

  If Len(s$) > def.ID_MAX_LENGTH% Then
    sys.err$ = "identifier too long, max 64 chars"
    Exit Sub
  EndIf

  If InStr(def.CONSTANTS$, "|" + lower$ + "|") Then
    sys.err$ = "'" + s$ + "' cannot be defined"
    Exit Sub
  EndIf

  If Not InStr("_abcdefghijklmnopqrstuvwxyz", Mid$(lower$, 1, 1)) Then Exit Sub
  For i% = 2 To Len(lower$)
    If Not InStr("_abcdefghijklmnopqrstuvwxyz0123456789", Mid$(lower$, i%, 1)) Then Exit Sub
  Next

  If set.get%(def.defines$(), lower$) <> -1 Then
    sys.err$ = "'" + s$ + "' is already defined"
    Exit Sub
  EndIf

  If set.is_full%(def.defines$()) Then
     sys.err$ = "too many defines"
     Exit Sub
  EndIf

  sys.err$ = ""
  set.put(def.defines$(), lower$)
End Sub

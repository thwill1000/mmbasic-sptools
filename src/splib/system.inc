' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07

'!info defined CMM2
'!info defined GAMEMITE
'!info defined MMB4L
'!info defined MMB4W
'!info defined PICOMITE
'!info defined PICOMITEVGA

'!if defined(CMM2)
  '!define PLATFORM_DEFINED
'!endif

'!if defined(GAMEMITE)
  '!if defined(PLATFORM_DEFINED)
    '!error "Multiple platforms defined"
  '!else
    '!define PLATFORM_DEFINED
  '!endif
'!endif

'!if defined(MMB4L)
  '!if defined(PLATFORM_DEFINED)
    '!error "Multiple platforms defined"
  '!else
    '!define PLATFORM_DEFINED
  '!endif
'!endif

'!if defined(MMB4W)
  '!if defined(PLATFORM_DEFINED)
    '!error "Multiple platforms defined"
  '!else
    '!define PLATFORM_DEFINED
  '!endif
'!endif

'!if defined(PICOMITE)
  '!if defined(PLATFORM_DEFINED)
    '!error "Multiple platforms defined"
  '!else
    '!define PLATFORM_DEFINED
  '!endif
'!endif

'!if defined(PICOMITEVGA)
  '!if defined(PLATFORM_DEFINED)
    '!error "Multiple platforms defined"
  '!else
    '!define PLATFORM_DEFINED
  '!endif
'!endif

Const sys.VERSION = 102201 ' 1.2.0 RC 1
Const sys.DEVICE = sys.get_config$("device", Mm.Device$)
Const sys.NO_DATA$ = Chr$(&h7F)
Const sys.CRLF$ = Chr$(13) + Chr$(10)
If Mm.Info$(Device) = "MMB4L" Then
  Const sys.FIRMWARE = Mm.Info(Version) \ 100
Else
  Const sys.FIRMWARE = Int(1000000 * Mm.Info(Version))
EndIf

Const sys.SUCCESS = 0
Const sys.FAILURE = -1

Dim sys.break_flag%
Dim sys.err$

'!if !defined(NO_INCLUDE_GUARDS)
Const sys.MAX_INCLUDES% = 30
Dim sys.includes$(sys.MAX_INCLUDES%) Length 20

Sub sys.provides(f$)
  Local f_$ = LCase$(f$)
  Local i% = 1
  Do
    Select Case sys.includes$(i%)
      Case f_$ : sys.err$ = "file already included: " + f_$ + ".inc" : Exit Sub
      Case ""  : sys.includes$(i%) = f_$ : Exit Sub
    End Select
    Inc i%
    If i% > sys.MAX_INCLUDES% Then sys.err$ = "too many includes" : Exit Sub
  Loop
End Sub

Sub sys.requires(f1$, f2$, f3$, f4$, f5$, f6$, f7$, f8$, f9$, f10$)

  ' Use indexes from 1..10 even when Option Base 0.
  Local f$(10) Length 20
  f$(1) = f1$ : f$(2) = f2$ : f$(3) = f3$ : f$(4) = f4$ : f$(5) = f5$
  f$(6) = f6$ : f$(7) = f7$ : f$(8) = f8$ : f$(9) = f9$ : f$(10) = f10$
  Local i%
  For i% = 1 To 10 : f$(i%) = LCase$(f$(i%)) : Next

  Local j%, ok%, fail%
  For i% = 1 To 10
    If f$(i%) <> "" Then
      ok% = 0
      For j% = 1 To sys.MAX_INCLUDES%
        Select Case sys.includes$(j%)
          Case f$(i%) : ok% = 1 : Exit For
          Case ""     : Exit For
        End Select
      Next
      If Not ok% Then
        If Not fail% Then
          sys.err$ = "required file(s) not included: " + f$(i%) + ".inc"
          fail% = 1
        Else
          Cat sys.err$, ", " + f$(i%) + ".inc"
        EndIf
      EndIf
    EndIf
  Next
End Sub
'!endif

' Reads property from config (.ini) file.
'
' @param  key$      case-insensitive key for property to lookup.
' @param  default$  value to return if property or file is not present.
' @param  file$     file to read. If empty then read "A:/.spconfig", or
'                   if that is not present "A:/.config".
Function sys.get_config$(key$, default$, file$)
  sys.get_config$ = default$
  If file$ = "" Then
    Const file_$ = Choice(Mm.Info(Exists File "A:/.spconfig"), "A:/.spconfig", "A:/.config")
  Else
    Const file_$ = file$
  EndIf
  If Not Mm.Info(Exists File file_$) Then Exit Function

  Local key_$ = LCase$(key$), s$, v$
  Open file_$ For Input As #1
  Do While Not Eof(#1)
    Line Input #1, s$
    If LCase$(Field$(Field$(s$, 1, "=", Chr$(34)),1, "#;", Chr$(34))) = key_$ Then
      v$ = Field$(Field$(s$, 2, "=", Chr$(34)), 1, "#;", Chr$(34))
      If Left$(v$, 1) = Chr$(34) Then v$ = Mid$(v$, 2)
      If Right$(v$, 1) = Chr$(34) Then v$ = Mid$(v$, 1, Len(v$) - 1)
      sys.get_config$ = v$
      Exit Do
    EndIf
  Loop
  Close #1
End Function

' Formats an SP Tools integer version as a string.
Function sys.format_version$(v%)
  Const v_% = Choice(v%, v%, sys.VERSION), a% = v_%\10^5, b% = (v_%-a%*10^5)\10^3
  Local c% = v_%-a%*10^5-b%*10^3, s$ = Str$(a%) + "." + Str$(b%)
  Select Case c%
    Case < 100 : Cat s$, " alpha "
    Case < 200 : Cat s$, " beta " : Inc c%, -100
    Case < 300 : Cat s$, " RC " : Inc c%, -200
    Case Else  : Cat s$, "." : Inc c%, -300
  End Select
  sys.format_version$ = s$ + Str$(c%)
End Function

' Formats a firmware integer version as a string.
Function sys.format_firmware_version$(v%)
  Const v_% = Choice(v%, v%, sys.FIRMWARE), a% = v_%\10^6, b% = (v_%-a%*10^6)\10^4
  Const c% = (v_%-a%*10^6-b%*10^4)\100, d% = v_%-a%*10^6-b%*10^4-c%*100
  Const digits% = Choice(Mm.Info(Device) = "MMB4L", 1, 2)
  Const s$ = Str$(a%) + "." + Str$(b%,digits%,0,"0") + "." + Str$(c%,digits%,0,"0")
  sys.format_firmware_version$ = s$ + Choice(d%, "b" + Str$(d%), "")
End Function

' Overrides Ctrl-C behaviour such that:
'   - Ctrl-C will call sys.break_handler()
'   - Ctrl-D will perform an actual MMBasic break
Sub sys.override_break(callback$)
  sys.break_flag% = 0
  Option Break 4
  If Len(callback$) Then
    Execute "On Key 3, " + callback$ + "()"
  Else
    On Key 3, sys.break_handler()
  EndIf
End Sub

' Called as an ON KEY interrupt when Ctrl-C is overridden by sys.override_break().
' Increments the sys.break_flag%, if the flag is then > 1 then END the program.
Sub sys.break_handler()
  Inc sys.break_flag%
  If sys.break_flag% > 1 Then
    sys.restore_break()
    End
  EndIf
End Sub

' Restores default Ctrl-C behaviour.
Sub sys.restore_break()
  sys.break_flag% = 0
  On Key 3, 0
  Option Break 3
End Sub

Function sys.HOME$()
  Select Case sys.DEVICE
    Case "MMB4L"
      sys.HOME$ = Mm.Info$(EnvVar "HOME")
    Case "MMBasic for Windows"
      sys.HOME$ = Mm.Info$(EnvVar "HOMEDIR") + Mm.Info$(EnvVar "HOMEPATH")
    Case Else
      sys.HOME$ = "A:"
  End Select
End Function

Function sys.SEPARATOR$()
  sys.SEPARATOR$ = Choice(sys.DEVICE = "MMBasic for Windows", "\", "/")
End Function

Function sys.TMPDIR$()
  Select Case sys.DEVICE
    Case "MMB4L"
      sys.TMPDIR$ = Choice(Mm.Info$(EnvVar "TMPDIR") = "", "/tmp", Mm.Info$(EnvVar "TMPDIR"))
    Case "MMBasic for Windows"
      sys.TMPDIR$ = Mm.Info$(EnvVar "TMP")
    Case Else
      sys.TMPDIR$ = "A:/tmp"
  End Select
End Function

' Are we running on one of the given devices ?
'
' @param  d1$, d2$, ... d5$  one of:
'                mmb4l    - MMB4L (aka MMBasic for Linux)
'                mmb4w    - MMBasic for Windows
'                cmm2     - Colour Maximite 2 (G1)
'                cmm2g2   - Colour Maximite 2 (G2)
'                cmm2*    - any Colour Maximite 2
'                gamemite - Game*Mite
'                pgvga    - PicoGAME VGA
'                pm       - PicoMite
'                pmvga    - PicoMiteVGA
'                pmvga*   - PicoMiteVGA or PicoGAME VGA
'                pm*      - PicoMite, PicoMiteVGA, PicoGAME VGA and Game*Mite
Function sys.is_device%(d1$, d2$, d3$, d4$, d5$)
  Local devices$(5 + Mm.Info(Option Base)) Length 16 = (d1$, d2$, d3$, d4$, d5$, "")
  Local ii% = Mm.Info(Option Base), match$

  sys.is_device% = 1
  Do While Len(devices$(ii%)) > 0
    Select Case sys.DEVICE
      Case "Colour Maximite 2" : match$ = "|cmm2|cmm2*|"
      Case "Colour Maximite 2 G2" : match$ = "|cmm2g2|cmm2*"
      Case "Game*Mite" : match$ = "|pm*|gamemite|"
      Case "MMB4L"
        If LCase$(devices$(ii%)) = "mmb4l-armv6l" Then
          If Mm.Info$(Arch) = "Linux armv6l" Then Exit Function
        EndIf
        match$ = "|mmb4l|"
      Case "MMBasic for Windows" : match$ = "|mmb4w|"
      Case "PicoGAME VGA" : match$ = "|pgvga|pmvga*|pm*|"
      Case "PicoMite" : match$ = "|pm|pm*|"
      Case "PicoMiteVGA": match$ = "|pmvga|pmvga*|pm*|"
      Case Else : Error "Unknown device: " + sys.DEVICE
    End Select
    If InStr(match$, "|" + LCase$(devices$(ii%)) + "|") Then Exit Function
    Inc ii%
  Loop
  sys.is_device% = 0
End Function

Function sys.error%(code%, msg$)
  If Not code% Then Error "Invalid error code"
  sys.error% = code%
  sys.err$ = msg$
End Function

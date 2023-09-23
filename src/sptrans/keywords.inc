' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07.07

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.requires("map", "sptools")
sys.provides("keywords")
If sys.err$ <> "" Then Error sys.err$
'!endif

Sub keywords.init()
  Local num_keywords%, max_keyword_len%, i%, s$
  Read Save
  Restore keywords.data
  Read num_keywords%, max_keyword_len%
  Dim keywords$(map.new%(num_keywords%)) Length max_keyword_len%
  map.init(keywords$())
  For i% = 1 To num_keywords%
    Read s$
    map.put(keywords$(), LCase$(s$), s$)
  Next
  Read Restore
End Sub

Function keywords.contains%(s$)
  keywords.contains% = map.get$(keywords$(), LCase$(s$)) <> sys.NO_DATA$
End Function

Function keywords.get$(s$)
  keywords.get$ = map.get$(keywords$(), LCase$(s$))
End Function

keywords.data:
Data 453, 14
Data "#Gps","#Include","@","Abort","Abs","Acos","Adc","Ain","All","Altitude"
Data "And","Append","Arc","Area","As","Asc","Asin","Atan2","Atn","Auto"
Data "AutoRefresh","Autorun","Autosave","Backlight","Bargauge","Base","Baudrate"
Data "Bcolour","Be","Beep","Bezier","Bin$","Bin2Str$","Bitmap","Black","Blit"
Data "Blue","Bmp","Bound","Box","Break","Brown","Button","Byte","C16","C20"
Data "C40","C8","Calibrate","Camera","Cancel","Caption","Capture","Case","Cat"
Data "CFunAddr","CFunction","ChDir","Checkbox","Choice","Chr$","Cin","CInt"
Data "Circle","Clear","Close","Cls","CodePage","Color","ColorCode","Colour"
Data "ColourCode","Concat","Console","Const","Continue","Controller","Controls"
Data "Copy","Cos","Cpu","Create","Csub","Ctrlval","Current","Cursor","Cwd$"
Data "Cyan","Dac","Data","Date$","DateTime$","Day$","Default","DefineFont","Deg"
Data "Delete","Dht22","Dim","Din","Dir","Dir$","Disable","Display","DisplayBox"
Data "Distance","Do","Dop","Dout","Down","Draw3d","Ds18b20","Edit","Editor"
Data "Else","ElseIf","Enable","End","EndIf","Eof","Epoch","Erase","Error","Es"
Data "EnvVar","Eval","Exists","Exit","Exp","Explicit","Fcolour","Fft","Field$"
Data "File","Files","Fin","Fix","Flac","FlashPages","Float","Font","For"
Data "Format$","Fr","Frame","Frequency","Function","F11","F12","Gauge","Geoid"
Data "GetReg","GetScanLine","GetTime","Gosub","Goto","Gps","Gr","Gray","Green"
Data "Gui","Hex$","Hide","Humid","I2C","I2C2","I2C3","If","Ignore","Ili9163"
Data "Ili9341","Ii9341_16","Ii9841","Image","Inc","Init","Inkey$","Input"
Data "Input$","InStr","Int","Intb","Integer","Interrupt","Inth","Intl","Inverse"
Data "Invert","IR","IReturn","Is","It","Jpg","Json$","Key","Keyboard","Keydown"
Data "Keypad","Kill","Landscape","LastRef","LastX","LastY","Latitude","LCase$"
Data "Lcd","LcdPanel","LCompare","Led","Left$","Len","Length","Let","LGetStr$"
Data "Library","Line","LInStr","List","LLen","Load","Loc","Local","Lof","Log"
Data "Longitude","LongString","Loop","Lower","Magenta","Magnitude","Map","Math"
Data "Max","Memory","Mid$","Min","MkDir","Mm.Backup","Mm.CmdLine$","Mm.Device$"
Data "Mm.ErrMsg$","Mm.ErrNo","Mm.FontHeight","Mm.FontWidth","Mm.HPos","Mm.HRes"
Data "Mm.I2C","Mm.Info","Mm.Info$","Mm.OneWire","Mm.Persist","Mm.Ver","Mm.VPos"
Data "Mm.VRes","Mm.Watchdog","Mod","Mode","ModFile","Mouse","Move","Movement"
Data "Mp3","MsgBox","Name","New","NewEdit","Next","NoConsole","NoEcho"
Data "NoInterrupt","NoInvert","None","Not","NumberBox","Nunchuk","Oc","Oct$"
Data "Off","On","OneWire","Oout","Open","Option","Or","Output","OwSearch","Page"
Data "Path","Pause","Peek","Phase","Pi","Pin","Pixel","Play","Png","Poke"
Data "Polygon","Port","Portrait","Pos","Print","ProgMem","Pu","PullDown"
Data "PullUp","Pulse","Pulsin","Pwm","Q_Create","Q_Euler","Q_Invert","Q_Mult"
Data "Q_Rotate","Q_Vector","Rad","Radio","Random","Randomize","RBox","Read"
Data "Red","Redraw","Ref","Refresh","Register","Rem","Rename","Replace","Reset"
Data "Restart","Restore","Resume","Return","Rgb","Right$","Rlandscape","RmDir"
Data "Rnd","Rotate","RPortrait","Rtc","Run","Satellites","Save","Scale"
Data "ScrollH","ScrollR","ScrollV","SdCard","Search","Seek","Select","Send"
Data "SensorFusion","Serial","Servo","SetPin","SetReg","SetTick","SetTime"
Data "Setup","Sgn","Show","Sin","Skip","Slave","Sleep","Sort","Space$","Spc"
Data "Speed","Spi","Spi2","Spi3","SpinBox","Sprite","Sqr","Ssd1963_4"
Data "Ssd1963_5","Ssd1963_5_16","Ssd1963_5_640","Ssd1963_5_buff","Ssd1963_5a"
Data "Ssd1963_7","Ssd1963_7_16","Ssd1963_7_640","Ssd1963_7_buff","Ssd1963_7a"
Data "Ssd1963_8","Ssd1963_8_16","Ssd1963_8_640","Ssd1963_8_buff","St7735"
Data "Start","StartLine","Static","Step","Stop","Str$","Str2Bin","String"
Data "String$","Sub","Switch","SymLink","Tab","Tan","Tempr","Test","Text"
Data "TextBox","Then","Time$","Timer","Title","To","Tone","Touch","Trace"
Data "Track","Triangle","Trigger","Trim","Troff","Tron","Tts","Turtle","UCase$"
Data "UK","Until","Up","Upper","US","UsbKeyboard","Val","Valid","Var","VarAddr"
Data "VarTbl","Vcc","Volume","Watchdog","Wav","WEnd","While","White","Word"
Data "Write","Ws2812","XModem","Xor","Yellow"

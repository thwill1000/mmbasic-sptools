' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07.07

On Error Skip 1 : Dim sys.VERSION$ = ""
If sys.VERSION$ = "" Then Error "'system.inc' not included"
sys.requires("map", "sptools")
sys.provides("keywords")
If sys.err$ <> "" Then Error sys.err$

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
Data 451, 14
Data "#Gps","#Include","@","Abort","Abs","Acos","Adc","Ain","All","Altitude"
Data "And","Append","Arc","Area","As","Asc","Asin","Atan2","Atn","Auto"
Data "AutoRefresh","Autorun","Autosave","Backlight","Bargauge","Base","Baudrate"
Data "Bcolour","Be","Beep","Bezier","Bin$","Bin2Str$","Bitmap","Black","Blit"
Data "Blue","Bmp","Box","Break","Brown","Button","Byte","C16","C20","C40","C8"
Data "Calibrate","Camera","Cancel","Caption","Capture","Case","Cat","CFunAddr"
Data "CFunction","ChDir","Checkbox","Chr$","Cin","CInt","Circle","Clear","Close"
Data "Cls","CodePage","Color","ColorCode","Colour","ColourCode","Concat"
Data "Console","Const","Continue","Controller","Controls","Copy","Cos","Cpu"
Data "Create","Csub","Ctrlval","Current","Cursor","Cwd$","Cyan","Dac","Data"
Data "Date$","DateTime$","Day$","Default","DefineFont","Deg","Delete","Dht22"
Data "Dim","Din","Dir","Dir$","Disable","Display","DisplayBox","Distance","Do"
Data "Dop","Dout","Down","Draw3d","Ds18b20","Edit","Editor","Else","ElseIf"
Data "Enable","End","EndIf","Eof","Epoch","Erase","Error","Es","EnvVar","Eval"
Data "Exists","Exit","Exp","Explicit","Fcolour","Fft","Field$","File","Files"
Data "Fin","Fix","Flac","FlashPages","Float","Font","For","Format$","Fr","Frame"
Data "Frequency","Function","F11","F12","Gauge","Geoid","GetReg","GetScanLine"
Data "GetTime","Gosub","Goto","Gps","Gr","Gray","Green","Gui","Hex$","Hide"
Data "Humid","I2C","I2C2","I2C3","If","Ignore","Ili9163","Ili9341","Ii9341_16"
Data "Ii9841","Image","Inc","Init","Inkey$","Input","Input$","InStr","Int"
Data "Intb","Integer","Interrupt","Inth","Intl","Inverse","Invert","IR"
Data "IReturn","Is","It","Jpg","Json$","Key","Keyboard","Keydown","Keypad"
Data "Kill","Landscape","LastRef","LastX","LastY","Latitude","LCase$","Lcd"
Data "LcdPanel","LCompare","Led","Left$","Len","Length","Let","LGetStr$"
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

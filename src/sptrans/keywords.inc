' Copyright (c) 2020-2023 Thomas Hugo Williams
' License MIT <https://opensource.org/licenses/MIT>
' For MMBasic 5.07.07

'!if !defined(NO_INCLUDE_GUARDS)
On Error Skip 1 : Dim sys.VERSION = -1
If sys.VERSION = -1 Then Error "'system.inc' not included"
sys.requires("map")
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
Data 454, 14
Data "#Gps","#Include","@","Abort","Abs","Acos","Adc","Ain","All","Altitude"
Data "And","Append","Arc","Area","As","Asc","Asin","Atan2","Atn","Auto"
Data "AutoRefresh","Autorun","Autosave","Backlight","Bargauge","Base","Baudrate"
Data "Bcolour","Be","Beep","Bezier","Bin$","Bin2Str$","Bitmap","Black","Blit"
Data "Blue","Bmp","Bound","Box","Break","Brown","Button","Byte","C16","C20"
Data "C40","C8","Calibrate","Call","Camera","Cancel","Caption","Capture","Case"
Data "Cat","CFunAddr","CFunction","ChDir","Checkbox","Choice","Chr$","Cin"
Data "CInt","Circle","Clear","Close","Cls","CodePage","Color","ColorCode"
Data "Colour","ColourCode","Concat","Console","Const","Continue","Controller"
Data "Controls","Copy","Cos","Cpu","Create","Csub","Ctrlval","Current","Cursor"
Data "Cwd$","Cyan","Dac","Data","Date$","DateTime$","Day$","Default"
Data "DefineFont","Deg","Delete","Dht22","Dim","Din","Dir","Dir$","Disable"
Data "Display","DisplayBox","Distance","Do","Dop","Dout","Down","Draw3d"
Data "Ds18b20","Edit","Editor","Else","ElseIf","Enable","End","EndIf","Eof"
Data "Epoch","Erase","Error","Es","EnvVar","Eval","Exists","Exit","Exp"
Data "Explicit","Fcolour","Fft","Field$","File","Files","Fin","Fix","Flac"
Data "FlashPages","Float","Font","For","Format$","Fr","Frame","Frequency"
Data "Function","F11","F12","Gauge","Geoid","GetReg","GetScanLine","GetTime"
Data "Gosub","Goto","Gps","Gr","Gray","Green","Gui","Hex$","Hide","Humid","I2C"
Data "I2C2","I2C3","If","Ignore","Ili9163","Ili9341","Ii9341_16","Ii9841"
Data "Image","Inc","Init","Inkey$","Input","Input$","InStr","Int","Intb"
Data "Integer","Interrupt","Inth","Intl","Inverse","Invert","IR","IReturn","Is"
Data "It","Jpg","Json$","Key","Keyboard","Keydown","Keypad","Kill","Landscape"
Data "LastRef","LastX","LastY","Latitude","LCase$","Lcd","LcdPanel","LCompare"
Data "Led","Left$","Len","Length","Let","LGetStr$","Library","Line","LInStr"
Data "List","LLen","Load","Loc","Local","Lof","Log","Longitude","LongString"
Data "Loop","Lower","Magenta","Magnitude","Map","Math","Max","Memory","Mid$"
Data "Min","MkDir","Mm.Backup","Mm.CmdLine$","Mm.Device$","Mm.ErrMsg$"
Data "Mm.ErrNo","Mm.FontHeight","Mm.FontWidth","Mm.HPos","Mm.HRes","Mm.I2C"
Data "Mm.Info","Mm.Info$","Mm.OneWire","Mm.Persist","Mm.Ver","Mm.VPos","Mm.VRes"
Data "Mm.Watchdog","Mod","Mode","ModFile","Mouse","Move","Movement","Mp3"
Data "MsgBox","Name","New","NewEdit","Next","NoConsole","NoEcho","NoInterrupt"
Data "NoInvert","None","Not","NumberBox","Nunchuk","Oc","Oct$","Off","On"
Data "OneWire","Oout","Open","Option","Or","Output","OwSearch","Page","Path"
Data "Pause","Peek","Phase","Pi","Pin","Pixel","Play","Png","Poke","Polygon"
Data "Port","Portrait","Pos","Print","ProgMem","Pu","PullDown","PullUp","Pulse"
Data "Pulsin","Pwm","Q_Create","Q_Euler","Q_Invert","Q_Mult","Q_Rotate"
Data "Q_Vector","Rad","Radio","Random","Randomize","RBox","Read","Red","Redraw"
Data "Ref","Refresh","Register","Rem","Rename","Replace","Reset","Restart"
Data "Restore","Resume","Return","Rgb","Right$","Rlandscape","RmDir","Rnd"
Data "Rotate","RPortrait","Rtc","Run","Satellites","Save","Scale","ScrollH"
Data "ScrollR","ScrollV","SdCard","Search","Seek","Select","Send","SensorFusion"
Data "Serial","Servo","SetPin","SetReg","SetTick","SetTime","Setup","Sgn","Show"
Data "Sin","Skip","Slave","Sleep","Sort","Space$","Spc","Speed","Spi","Spi2"
Data "Spi3","SpinBox","Sprite","Sqr","Ssd1963_4","Ssd1963_5","Ssd1963_5_16"
Data "Ssd1963_5_640","Ssd1963_5_buff","Ssd1963_5a","Ssd1963_7","Ssd1963_7_16"
Data "Ssd1963_7_640","Ssd1963_7_buff","Ssd1963_7a","Ssd1963_8","Ssd1963_8_16"
Data "Ssd1963_8_640","Ssd1963_8_buff","St7735","Start","StartLine","Static"
Data "Step","Stop","Str$","Str2Bin","String","String$","Sub","Switch","SymLink"
Data "Tab","Tan","Tempr","Test","Text","TextBox","Then","Time$","Timer","Title"
Data "To","Tone","Touch","Trace","Track","Triangle","Trigger","Trim","Troff"
Data "Tron","Tts","Turtle","UCase$","UK","Until","Up","Upper","US","UsbKeyboard"
Data "Val","Valid","Var","VarAddr","VarTbl","Vcc","Volume","Watchdog","Wav"
Data "WEnd","While","White","Word","Write","Ws2812","XModem","Xor","Yellow"

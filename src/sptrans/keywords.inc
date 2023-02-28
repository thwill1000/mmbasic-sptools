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
Data 443, 14
Data "#Gps","#Include","@","Abort","Abs","Acos","Adc","Ain","All","Altitude"
Data "And","Append","Arc","Area","As","Asc","Asin","Atan2","Atn","Auto"
Data "AutoRefresh","Autorun","Autosave","Backlight","Bargauge","Base","Baudrate"
Data "Bcolour","Be","Beep","Bezier","Bin$","Bin2Str$","Bitmap","Black","Blit"
Data "Blue","Bmp","Box","Break","Brown","Button","Byte","C16","C20","C40","C8"
Data "Calibrate","Camera","Cancel","Caption","Capture","Case","Cat","CFunAddr"
Data "CFunction","ChDir","Checkbox","Chr$","Cin","CInt","Circle","Clear","Close"
Data "Cls","Color","ColorCode","Colour","ColourCode","Concat","Console","Const"
Data "Continue","Controller","Controls","Copy","Cos","Cpu","Create","Csub"
Data "Ctrlval","Current","Cursor","Cwd$","Cyan","Dac","Data","Date$","DateTime$"
Data "Day$","Default","DefineFont","Deg","Delete","Dht22","Dim","Din","Dir"
Data "Dir$","Disable","Display","DisplayBox","Distance","Do","Dop","Dout","Down"
Data "Draw3d","Ds18b20","Edit","Else","ElseIf","Enable","End","EndIf","Eof"
Data "Epoch","Erase","Error","Es","Eval","Exit","Exp","Explicit","Fcolour","Fft"
Data "Field$","File","Files","Fin","Fix","Flac","FlashPages","Float","Font"
Data "For","Format$","Fr","Frame","Frequency","Function","Fauge","Geoid"
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
Data "Step","Stop","Str$","Str2Bin","String","String$","Sub","Switch","Tab"
Data "Tan","Tempr","Test","Text","TextBox","Then","Time$","Timer","Title","To"
Data "Tone","Touch","Trace","Track","Triangle","Trigger","Trim","Troff","Tron"
Data "Tts","Turtle","UCase$","UK","Until","Up","Upper","US","UsbKeyboard","Val"
Data "Valid","Var","VarAddr","VarTbl","Vcc","Volume","Watchdog","Wav","WEnd"
Data "While","White","Word","Write","Ws2812","XModem","Xor","Yellow"

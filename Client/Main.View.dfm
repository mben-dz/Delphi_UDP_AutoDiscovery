object MainView: TMainView
  Left = 0
  Top = 0
  Margins.Left = 5
  Margins.Top = 5
  Margins.Right = 5
  Margins.Bottom = 5
  Caption = 'Client Side'
  ClientHeight = 342
  ClientWidth = 701
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -18
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  PixelsPerInch = 144
  TextHeight = 25
  object MemoLog: TMemo
    Left = 10
    Top = 84
    Width = 681
    Height = 193
    Margins.Left = 5
    Margins.Top = 5
    Margins.Right = 5
    Margins.Bottom = 5
    TabOrder = 0
  end
  object TimerSendBroadcastHelp: TTimer
    Enabled = False
    Interval = 2000
    OnTimer = TimerSendBroadcastHelpTimer
    Left = 387
    Top = 24
  end
end

object OptionsForm: TOptionsForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Options'
  ClientHeight = 316
  ClientWidth = 655
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poDesktopCenter
  OnCreate = FormCreate
  TextHeight = 15
  object SleepsCheckBox: TCheckBox
    Left = 20
    Top = 18
    Width = 619
    Height = 22
    Caption = '&Do short pauses after solving squares'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -17
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
  end
  object ReportDurationCheckBox: TCheckBox
    Left = 20
    Top = 46
    Width = 619
    Height = 22
    Caption = '&Report the time taken to solve the puzzle, ignoring pauses'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -17
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
  end
  object ShowSmallDigitsCheckBox: TCheckBox
    Left = 20
    Top = 74
    Width = 619
    Height = 22
    Caption = 
      'S&how small helper digits in each square during Manual Play or S' +
      'imple Solving'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -17
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
  end
  object ShowAttemptsCheckBox: TCheckBox
    Left = 20
    Top = 234
    Width = 619
    Height = 22
    Caption = 'In fast backtracking &approach, show digits being tried'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -17
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
  end
  object MethodRadioGroup: TRadioGroup
    Left = 12
    Top = 114
    Width = 619
    Height = 105
    Caption = 'Solving Method to Use'
    DefaultHeaderFont = False
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -17
    Font.Name = 'Tahoma'
    Font.Style = []
    HeaderFont.Charset = ANSI_CHARSET
    HeaderFont.Color = clWindowText
    HeaderFont.Height = -17
    HeaderFont.Name = 'Tahoma'
    HeaderFont.Style = [fsBold]
    Items.Strings = (
      
        'S&imple solving rules, plus prompt to use fast backtracking appr' +
        'oach if needed'
      
        'Si&mple solving rules, automatically use fast backtracking appro' +
        'ach if needed'
      '&Only use fast backtracking approach')
    ParentFont = False
    TabOrder = 3
  end
  object SaveButton: TButton
    Left = 20
    Top = 275
    Width = 75
    Height = 25
    Caption = '&Save'
    Default = True
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -17
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 5
    OnClick = SaveButtonClick
  end
  object CancelButton: TButton
    Left = 128
    Top = 275
    Width = 75
    Height = 25
    Cancel = True
    Caption = '&Cancel'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -17
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 6
    OnClick = CancelButtonClick
  end
end

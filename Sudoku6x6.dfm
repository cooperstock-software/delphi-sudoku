inherited Sudoku6x6Form: TSudoku6x6Form
  Caption = 'Sudoku6x6Form'
  ClientHeight = 511
  ClientWidth = 363
  StyleElements = [seFont, seClient, seBorder]
  OnClose = FormClose
  OnCreate = FormCreate6x6
  ExplicitLeft = 2
  ExplicitTop = 2
  ExplicitWidth = 379
  ExplicitHeight = 550
  TextHeight = 15
  inherited Shape1: TShape
    Width = 342
    Height = 342
    ExplicitWidth = 342
    ExplicitHeight = 342
  end
  inherited ManualPlayButton: TButton
    Top = 374
    Height = 32
    ExplicitTop = 374
    ExplicitHeight = 32
  end
  inherited SolveButton: TButton
    Top = 374
    Height = 32
    ExplicitTop = 374
    ExplicitHeight = 32
  end
  inherited LoadButton: TButton
    Left = 9
    Top = 414
    Height = 32
    TabOrder = 3
    ExplicitLeft = 9
    ExplicitTop = 414
    ExplicitHeight = 32
  end
  inherited SaveButton: TButton
    Left = 122
    Top = 414
    TabOrder = 4
    ExplicitLeft = 122
    ExplicitTop = 414
  end
  inherited ClearButton: TButton
    Left = 260
    Top = 374
    Width = 94
    TabOrder = 2
    ExplicitLeft = 260
    ExplicitTop = 374
    ExplicitWidth = 94
  end
  inherited SwitchButton: TButton
    Left = 9
    Top = 462
    Caption = 'S&witch to 9x9 Sudoku'
    ExplicitLeft = 9
    ExplicitTop = 462
  end
  inherited OptionsButton: TButton
    Left = 260
    Top = 413
    ExplicitLeft = 260
    ExplicitTop = 413
  end
end

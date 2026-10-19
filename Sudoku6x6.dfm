inherited Sudoku6x6Form: TSudoku6x6Form
  Caption = 'Sudoku6x6Form'
  ClientHeight = 571
  ClientWidth = 423
  StyleElements = [seFont, seClient, seBorder]
  OnClose = FormClose
  OnCreate = FormCreate6x6
  ExplicitTop = 3
  ExplicitWidth = 439
  ExplicitHeight = 610
  TextHeight = 15
  inherited Shape1: TShape
    Width = 402
    Height = 402
    ExplicitWidth = 402
    ExplicitHeight = 402
  end
  inherited ManualPlayButton: TButton
    Top = 439
    Height = 32
    ExplicitTop = 439
    ExplicitHeight = 32
  end
  inherited SolveButton: TButton
    Top = 439
    Height = 32
    ExplicitTop = 439
    ExplicitHeight = 32
  end
  inherited LoadButton: TButton
    Left = 9
    Top = 479
    Height = 32
    TabOrder = 3
    ExplicitLeft = 9
    ExplicitTop = 479
    ExplicitHeight = 32
  end
  inherited SaveButton: TButton
    Left = 122
    Top = 479
    TabOrder = 4
    ExplicitLeft = 122
    ExplicitTop = 479
  end
  inherited ClearButton: TButton
    Left = 316
    Top = 439
    Width = 94
    TabOrder = 2
    ExplicitLeft = 316
    ExplicitTop = 439
    ExplicitWidth = 94
  end
  inherited SwitchButton: TButton
    Left = 9
    Top = 527
    Caption = 'S&witch to 9x9 Sudoku'
    ExplicitLeft = 9
    ExplicitTop = 527
  end
  inherited OptionsButton: TButton
    Left = 316
    Top = 478
    ExplicitLeft = 316
    ExplicitTop = 478
  end
  inherited HelpButton: TButton
    Left = 319
    Top = 530
    ExplicitLeft = 319
    ExplicitTop = 530
  end
end

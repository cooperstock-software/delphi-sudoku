program SudokuProject;

uses
  Vcl.Forms,
  SudokuBase in 'SudokuBase.pas' {SudokuBaseForm},
  cell in 'cell.pas' {Cell1: TFrame},
  Globals in 'Globals.pas',
  Backtrack in 'Backtrack.pas',
  Sudoku6x6 in 'Sudoku6x6.pas' {SudokuBaseOptionsForm},
  Options in 'Options.pas' {OptionsForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TSudokuBaseForm, SudokuBaseForm);
  Application.CreateForm(TSudoku6x6Form, Sudoku6x6Form);
  Application.CreateForm(TOptionsForm, OptionsForm);
  Application.Run;
  // RunApplication;
end.

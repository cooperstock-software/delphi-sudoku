unit Sudoku6x6;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  SudokuBase, Globals;

type
  TSudoku6x6Form = class(TSudokuBaseForm)
    procedure FormCreate6x6(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  protected
		procedure RowColToBox(row, col: integer; var boxNum, boxPos: integer); override;
  public
    { Public declarations }
  end;

var
  Sudoku6x6Form: TSudoku6x6Form;

implementation

{$R *.dfm}

procedure TSudoku6x6Form.FormCreate6x6(Sender: TObject);
begin
   numRowsCols := 6;
   FinishCreate;
end;

procedure TSudoku6x6Form.FormClose(Sender: TObject; var Action: TCloseAction);
begin
	inherited;
   SudokuBaseForm.Close; // otherwise the hidden 9x9 form stays running invisibly
end;

{* Convert a row and column number to a box number and box position - both values 1 to numRowsCols.
 * Rules for this a 6x6 Sudoku:
 * When it's a 6x6 Sudoku:
 *     Box number 1 is top left 3 colums x top 2 rows, box 2 is the 3 columns to
 *     the right of that, box 3 is the left 3 columns and rows 4-5, etc.
 * Box position is the sequential position 1-numRowsCols within the box.
 *}
procedure TSudoku6x6Form.RowColToBox(row, col: integer; var boxNum, boxPos: integer);
var
	rowPart, colPart: integer;
begin
	// first calc the box number from two parts
	rowPart := (row + 1) div 2; // gives 1, 2 or 3 for top 2 rows, centre 2 rows, and bottom 2 rows respectively
	colPart := (col  + 2) div 3; // gives 1 or 2 for left 3 columns and right 3 columns respectively

	boxNum := (rowPart - 1) * 2 + colPart;

	// now calc the position within the box from two parts
	rowPart := (((row - 1) Mod 2) + 1) * 3 - 2; // gives 1 for rows 1, 3 and 5, and 4 for rows 2, 4 and 6
	colPart := ((col - 1) Mod 3) + 1; // gives 1 for columns 1 and 4, 2 for cols 2 and 5, and 3 for cols 3 and 6

	boxPos := rowPart + (colPart - 1);
end;

Initialization

ReportMemoryLeaksOnShutdown := True;

end.

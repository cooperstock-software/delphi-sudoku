unit Backtrack;

interface

uses
	Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
   System.Diagnostics, System.UITypes, System.Math, Vcl.Graphics,
   Vcl.Controls, Vcl.StdCtrls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls;

Type
   TBoard = array[1..9,1..9] of integer;
   TBacktrack = Class

	private
   	numRowsCols: integer;
		procedure InitMasks;
   	function SolveSudoku: boolean;
   	procedure TransferBack;
      function IsAllowed(maskValue, digit: integer): boolean;
      function FindEmpty(var foundRow, foundCol: integer): boolean;
      procedure SetDigit(var maskValue: integer; digit: integer);
      procedure ClearDigit(var maskValue: integer; digit: integer);
   	procedure SetupBoard;
   public
      procedure Initialize(aform: TForm);
      function DoAll: boolean;
   End;

implementation

uses SudokuBase, Globals, Cell;

var
   form: TSudokuBaseForm;
   pCells: PCellArray;

   {* Used in backtracking method:
    * rowMasks[i] is a 9-digit number, with information about row number i, with the j-th right-most
    *   digit being either a 0 (if the digit j doesn't already appear in that row) or a 1
    *   (if the digit j does already appear in that row).
    *   So the 1's place is for digit 1, the 10's place for digit 2, etc.
    * Similarly, colMasks[i] refers to column number i, and boxMasks[i] refers to box number i.
    * These values can be:
    *    tested with IsAllowed(long maskValue, int digit), which returns true if the appropriate digit is a 0,
    *    set to mark them as being already present with uf_set_digit(long maskValue, int digit), or
    *    cleared to mark them as not already present with uf_clear_digit(long maskValue, int digit).
    * "bt" stands for BackTrack!
    *}
   rowMasks: array [1..9] of integer;
   colMasks: array [1..9] of integer;
   boxMasks: array [1..9] of integer;

	board: TBoard;

   // This array represents the powers of 10 used to mark each digit in the
   // masks array. So powers[1] is 10 to the power 0 (1), powers[2] is 10,
   // powers[3] is 100 etc.
	powers: array [1..9] of integer;

{ TBacktrack }

procedure TBacktrack.Initialize(aform: TForm);
var
	i: integer;
begin
     form := (aform as TSudokuBaseForm);
     pCells := @form.cells;
     numRowsCols := form.numRowsCols;

     powers[1] := 1;
     for i := 2 to numRowsCols do
        powers[i] := powers[i - 1] * 10;
end;

function TBacktrack.DoAll: boolean;
begin
   SetupBoard();

   InitMasks();

   if NOT SolveSudoku() then
   begin
      ShowMessage('The possibly slower method was not successful.');
      result := FALSE;
   end
   else
   begin
      // transfer the results back to the puzzle
      TransferBack();
      result := TRUE
   end;
end;

// Set up the initial Board array of current values, 0 for no value.
procedure TBacktrack.SetupBoard;
var
   row, col: integer;
   cell: TCell;
   s: string;
begin
   for row := 1 to numRowsCols do
      for col := 1 to numRowsCols do
      begin
         board[row, col] := 0;
         cell := pCells^[row, col];
         if cell.isResultVisible then
         begin
            s := cell.Result.Caption;
            if s > '' then
               board[row, col] := StrToInt(s);
         end;
      end;
end;

// Initialize masks from the starting board
procedure TBacktrack.InitMasks;
var
	row, col, digit, box: integer;
begin
	for row := 1 to numRowsCols do
   begin
		rowMasks[row] := 0;
		colMasks[row] := 0;
		boxMasks[row] := 0;
	end;

	for row := 1 to numRowsCols do
		for col := 1 to numRowsCols do
		begin
			digit := board[row,col];
			if digit > 0 then
			begin
				box := pCells^[row,col].boxNum;
				SetDigit(rowMasks[row], digit);
				SetDigit(colMasks[col], digit);
				SetDigit(boxMasks[box], digit);
			end;
		end;
end;

// Main new backtracking solving function - recursive!
// Return TRUE for success, FALSE for failure.
function TBacktrack.SolveSudoku: boolean;
var
	row, col, digit, box: integer;
	cell: TCell;
begin
	if not FindEmpty(row, col) then
	begin
		result := TRUE;   // solved
		EXIT;
	end;

	cell := pCells^[row,col];
	box := cell.boxNum;

	for digit := 1 to numRowsCols do

		if IsAllowed(rowMasks[row], digit) and
			IsAllowed(colMasks[col], digit) and
			IsAllowed(boxMasks[box], digit) then
		begin

			// Place digit
			board[row,col] := digit;
			// Can take up to 10 times longer if we include the SetResult calls here!
			if showAttempts then
         begin
				cell.SetResult(IntToStr(digit), SOLVED);
            Application.ProcessMessages;
         end;

			SetDigit(rowMasks[row], digit);
			SetDigit(colMasks[col], digit);
			SetDigit(boxMasks[box], digit);

			if SolveSudoku then
			begin
				result := TRUE;
				EXIT;
			end;

			// Undo
			board[row,col] := 0;
			if showAttempts then
         begin
				cell.SetResult('', SOLVED);
            Application.ProcessMessages;
         end;
			ClearDigit(rowMasks[row], digit);
			ClearDigit(colMasks[col], digit);
			ClearDigit(boxMasks[box], digit);

		end;

	result := FALSE;
end;

// Find next empty cell and fill it into foundRow and foundCol.
// Return TRUE if there is one, FALSE if not.
function TBacktrack.FindEmpty(var foundRow, foundCol: integer): boolean;
var
   row, col: integer;
begin
	for row := 1 to numRowsCols do
		for col := 1 to numRowsCols do
			if board[row,col] = 0 then
			begin
				foundRow := row;
				foundCol := col;
				result := TRUE;
				EXIT;
			end;

	result := FALSE;
end;

// Transfer results back to our UI from the solved board.
procedure TBacktrack.TransferBack;
var
	row, col: integer;
	cell: TCell;
begin
for row := 1 to numRowsCols do
	for col := 1 to numRowsCols do
	begin
		cell := pCells^[row, col];
		if NOT cell.isResultVisible then
			cell.SetResult(IntToStr(board[row, col]), SOLVED);
	end;
end;

// Return whether the digit is allowed in the row, col or box mask value
// (it's not currently present in that row, col or box).
function TBacktrack.IsAllowed(maskValue, digit: integer): boolean;
begin
    result := ((maskValue div powers[digit]) Mod 10) = 0;
end;

// Change the mask value to have the digit set in it.
// This assumes the digit is not already set in it!
// Setting the digit indicates that the digit is already present in the row,
// column or box the mask represents.
procedure TBacktrack.SetDigit(var maskValue: integer; digit: integer);
begin
   maskValue := maskValue + powers[digit];
end;

// Return new version of mask, with the digit cleared from it.
// This assumes the digit is currently set in it!
// Clearing the digit indicates that the digit is not already present in the row,
// column or box the mask represents.
procedure TBacktrack.ClearDigit(var maskValue: integer; digit: integer);
begin
    maskValue := maskValue - powers[digit];
end;

end.

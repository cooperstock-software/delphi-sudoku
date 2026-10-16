unit cell;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.StrUtils, System.Variants, System.Classes, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TCell = class(TFrame)
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Result: TLabel;
    procedure DblClickSmallNumber(Sender: TObject);
    procedure ClickSmallNumber(Sender: TObject);
    procedure FrameClick(Sender: TObject);
    procedure ClickResult(Sender: TObject);
    procedure DblClickResult(Sender: TObject);

	private
      { Private declarations }
      digits: array[1..9] of TLabel;
   	numRowsCols: integer; // 9 or 6, for the different puzzle sizes
      procedure ShowResult;
      //procedure HideDigits;
      //procedure HideResult;
      procedure ChangeResultVisibility(isVisible, changeOther: boolean);
      procedure ChangeDigitsVisibility(isVisible, changeOther: boolean);
      procedure SetResultOriginal(isOriginal: boolean);
      function IsResultOriginal: boolean;
   public
      { Public declarations }
      isResultVisible: boolean;
      areDigitsVisible: boolean;
      isOriginal: boolean; // is the result part of the original puzzle
      row, col, boxNum: Integer;
      constructor Create(AOwner: TComponent; arow, acol, aBoxNum: Integer); reintroduce;
      procedure ShowDigits;
      procedure ResetColor;
      procedure SetResult(key: string; isOriginal: boolean);
      procedure SetPossible(digit: integer; possible: boolean);
      procedure ClearAll;
      function SaveValue: string;
      function ResultText: string;
      function IsPossible(digit: integer): boolean;
   const
		positions: array[1..9] of integer = (10, 76, 142, 209, 275, 341, 408, 474, 540);
      yPositions6x6: array[1..6] of integer = (10, 76, 143, 209, 276, 342);
      // values for the changeOther 2nd arg to the change* functions
      CHANGE_OTHER: boolean = true;
      NO_CHANGE_OTHER: boolean = false;

  end;

implementation

{$R *.dfm}
uses SudokuBase, Globals;

// Do various initialization on construction, passing in some values
constructor TCell.Create(AOwner: TComponent; arow, acol, aBoxNum: Integer);
var
   i: integer;
begin
	inherited Create(AOwner);
   Parent := (AOwner as TWinControl);
   row := aRow;
   col := aCol;
   boxNum := aBoxNum;
	Name := 'Cell' + IntToStr(row) + IntToStr(col);

   numRowsCols := (Parent as TSudokuBaseForm).numRowsCols;

   Left := positions[col];
   if numRowsCols = 9 then
	   Top := positions[row]
   else
   begin
	   Top := yPositions6x6[row];
      label4.Top := 35;
      label5.Top := 35;
      label6.Top := 35;
      label7.Visible := FALSE;
      label8.Visible := FALSE;
      label9.Visible := FALSE;
   end;

   ResetColor;

   {  // confirm that the tabOrders are set in order (they are!)
	if ((row = 1) and (col = 1)) or ((row = 9) and (col = 9)) then
   	ShowMessage(format('at [%d,%d] taborder %d', [row, col, tabOrder])); }

	// make the array of the numRowsCols small digit controls, for easy indexed access
   digits[1] := Label1;
   digits[2] := Label2;
   digits[3] := Label3;
   digits[4] := Label4;
   digits[5] := Label5;
   digits[6] := Label6;

   if numRowsCols = 9 then
   begin
	   digits[7] := Label7;
	   digits[8] := Label8;
	   digits[9] := Label9;
   end;

   for i := 1 to numRowsCols do
   begin
      digits[i].Tag := 1; // 1 means possible, 0 means not possible - start assume possible
      digits[i].Visible := false;
   end;
   Result.Visible := false;

end;

// Flip the visibility and enabled status of the result digit to isVisible.
// If changeOther is TRUE, also flip the status of the 1-iiRowsCols digits to be NOT abVisible.
procedure TCell.ChangeDigitsVisibility(isVisible, changeOther: boolean);
var
   i: integer;
begin
   if showSmallDigits then
      for i := 1 to numRowsCols do
         digits[i].Visible := isVisible;

   areDigitsVisible := isVisible;

   if changeOther then
      ChangeResultVisibility(NOT isVisible, NO_CHANGE_OTHER);
end;

procedure TCell.ChangeResultVisibility(isVisible, changeOther: boolean);
begin
   Result.Visible := isVisible;
   isResultVisible := isVisible;
   if (areDigitsVisible = isVisible) and changeOther then
   begin
      ChangeDigitsVisibility(NOT isVisible, NO_CHANGE_OTHER);
   end;

end;

// Handle a single click on this square; tell the window which square was clicked
procedure TCell.FrameClick(Sender: TObject);
begin
   (Parent as TSudokuBaseForm).ClearSelection;

   (Parent as TSudokuBaseForm).clickedRow := Row;
   (Parent as TSudokuBaseForm).clickedCol := Col;

   Color := clMoneyGreen; // Mint

   // this.SetFocus - don't see equivalent for this for a frame in Delphi

end;

{ these functions were in my previous version but don't seem to be used
// make the numRowsCols small digits invisible
procedure TCell.HideDigits;
begin
   ChangeDigitsVisibility(FALSE, CHANGE_OTHER);
end;

// make the result digit invisible
procedure TCell.HideResult;
begin
    ChangeResultVisibility(FALSE, CHANGE_OTHER);
end;
}

// Clear everything in this square, leaving both parts not visible, the
// 1-numRowsCols small digits possible, and the result original
procedure TCell.ClearAll;
var
	i: integer;
begin
   if areDigitsVisible then ChangeDigitsVisibility(FALSE, NO_CHANGE_OTHER);
   if isResultVisible then ChangeResultVisibility(FALSE, NO_CHANGE_OTHER);

   for i := 1 to numRowsCols do
      SetPossible(i, POSSIBLE);

   // same for the result
   SetResultOriginal(ORIGINAL);
end;

// Same as clicking the empty frame
procedure TCell.ClickResult(Sender: TObject);
begin
   FrameClick(Sender);
end;

// On a double-click on the result digit, if it's not part of the original puzzle
// (not bold), go back to the 1-numRowsCols digits.
// Don't show any disallowed digits as bold (but leave non-bold ones from before
// as non-bold).
procedure TCell.DblClickResult(Sender: TObject);
var
	i: integer;
begin
   if IsResultOriginal then EXIT;

   Self.Result.Caption := '';
   ShowDigits;

   for i := 1 to numRowsCols do
      if IsPossible(i) then
         if NOT (Parent as TSudokuBaseForm).CheckAllowedResult(row, col, IntToStr(i), SILENT) then
            SetPossible(i, IMPOSSIBLE);
end;

// Handle a single-click on one of the 1-numRowsCols small digits.
// If it's currently a possibility (bold) make it show as not possible.
// If it's not a possibility, make it possible (if it's allowed!).
// Also select the square.
procedure TCell.ClickSmallNumber(Sender: TObject);
var
	digit: integer;
   sDigit: string;
   possible: boolean;
begin
	sDigit := (Sender as TLabel).Caption;
   digit := StrToInt(sDigit);
   possible := IsPossible(digit);

   if possible or (Parent as TSudokuBaseForm).CheckAllowedResult(row, col, sDigit, VERBOSE) then
	   SetPossible(digit, NOT possible);

   FrameClick(Sender);
end;

// Handle a double-click on one of the 1-numRowsCols small digits.
// If it's allowed in that square, switch to it as a (non-bold) result.
// Also select this square.
procedure TCell.DblClickSmallNumber(Sender: TObject);
var
   sDigit: string;
begin
	sDigit := (Sender as TLabel).Caption;

   if (Parent as TSudokuBaseForm).CheckAllowedResult(row, col, sDigit, VERBOSE) then
   begin
      SetResult(sDigit, SOLVED);
      if (Parent as TSudokuBaseForm).IsPuzzleSolved then
         ShowMessage('You have solved the puzzle!');
   end;

   FrameClick(Sender);
end;

procedure TCell.ResetColor;
var
   isWhite: boolean;
   newColor: TColor;
begin
	if numRowsCols = 9 then
	   isWhite := (boxNum Mod 2) = 1
   else
   	isWhite := boxNum in [1, 4, 5]; // bit weird in 6x6 puzzle!

   if isWhite then
   	newColor := clWhite
   else
   	newColor := clSilver;

   if newColor <> color then color := newColor;
end;

// Just return the character (if any) in st_result
function TCell.ResultText: string;
begin
   result := Self.Result.Caption;
end;

// Return a value for saving from this square, which is three spaces if it
// doesn't have a result digit in it, or the result digit 3 times, if it's bold
// (an original puzzle digit), or the result digit surrounded by two spaces if not.
function TCell.SaveValue: string;
var
	s: string;
begin
   if NOT isResultVisible then
   begin
   	result := '   ';
      EXIT;
   end;

   s := Self.Result.Caption;

   if IsResultOriginal then
   	result := DupeString(s, 3)
   else
	   result := ' ' + s + ' ';

end;

// Set the digit in the small 1-numRowsCols digits as possible (if abPossible is
// TRUE or POSSIBLE) or impossible (if FALSE or IMPOSSIBLE),
// by changing its bold and italic settings
procedure TCell.SetPossible(digit: integer; possible: boolean);
var
   tag: integer;
	style: TFontStyles;
begin
   if NOT showSmallDigits then
   begin
      tag := 0;
      if possible then tag := 1;
      digits[digit].Tag := tag;
      EXIT;
   end;

   if possible then
      style := [fsBold]
   else
   	style := [fsItalic];

   digits[digit].Font.Style := style;
end;

// Set the result to be displayed, with the value key.
// If isOriginal is TRUE (value ORIGINAL), it's part of the original entered puzzle.
// If FALSE (value SOLVED) it's not.
procedure TCell.SetResult(key: string; isOriginal: boolean);
begin
   if not isResultVisible then ShowResult;

   SetResultOriginal(isOriginal and (key > ''));
   Result.Caption := key;

   if (key = '') and (Parent as TSudokuBaseForm).isStarted then ShowDigits;

   if key > '' then (Parent as TSudokuBaseForm).BubbleResult(row, col, key);

end;

// Set whether the result is an original puzzle value (if isOriginal is TRUE or
// ORIGINAL) or a solved one (FALSE or SOLVED), by changing its bold and italic settings.
procedure TCell.SetResultOriginal(isOriginal: boolean);
var
	style: TFontStyles;
begin
   if isOriginal then
   	style := [fsBold]
   else
   	style := [];
   Result.Font.Style := style;
   Self.isOriginal := isOriginal;
end;

// Return whether or not the digit aiDigit is still possible in this square
function TCell.IsPossible(digit: integer): boolean;
begin
   if showSmallDigits then
      result := fsBold in digits[digit].font.style
   else
      result := digits[digit].Tag = 1;
end;

// Return whether or not the displayed result value is an original puzzle value
// (as opposed to a solved one), based on whether it's bold
function TCell.IsResultOriginal: boolean;
begin
   result := fsBold in Self.Result.Font.Style;
end;

// make the numRowsCols small digits visible and the result invisible
procedure TCell.ShowDigits;
begin
	ChangeDigitsVisibility(TRUE, CHANGE_OTHER);
end;

// make the result digit visible and the numRowsCols small digits invisible
procedure TCell.ShowResult;
begin
   ChangeResultVisibility(TRUE, CHANGE_OTHER);
end;

end.

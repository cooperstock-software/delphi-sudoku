unit SudokuBase;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellApi,
  System.SysUtils, System.Variants, System.Classes,
  System.Diagnostics, System.UITypes, System.IOUtils, System.StrUtils, Vcl.Graphics,
  Vcl.Controls, Vcl.StdCtrls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls,
  Cell, Globals, Backtrack, Options;

type
   TCellArray = array[1..9, 1..9] of TCell;
	PCellArray = ^TCellArray;
	ArrayType = (ROW_TYPE = 1, COL_TYPE = 2, BOX_TYPE = 3);

  TSudokuBaseForm = class(TForm)
      Shape1: TShape;
      ManualPlayButton: TButton;
      SolveButton: TButton;
      LoadButton: TButton;
    SaveButton: TButton;
    ClearButton: TButton;
    SwitchButton: TButton;
    OptionsButton: TButton;
    HelpButton: TButton;
      procedure FormCreate(Sender: TObject);
      procedure FormKeyPress(Sender: TObject; var Key: Char);
      procedure ManualPlayButtonClick(Sender: TObject);
      procedure SolveButtonClick(Sender: TObject);
      procedure LoadButtonClick(Sender: TObject);
      procedure FormShortCut(var Msg: TWMKey; var Handled: Boolean);
    	procedure SaveButtonClick(Sender: TObject);
    	procedure ClearButtonClick(Sender: TObject);
    procedure SwitchButtonClick(Sender: TObject);
    procedure OptionsButtonClick(Sender: TObject);
    procedure HelpButtonClick(Sender: TObject);
  private
      { Private declarations }
      function IsPuzzleClear: boolean;
      function SolveRowColBox(var anArray: TCellArray; firstIndex, digit: integer): boolean;
      function GetArrayOfType(atype: ArrayType): PCellArray;
      procedure PrepareForSolve;
      procedure ResetBackColors;
      procedure FullSolve;
      procedure ClearAll;
      procedure LoadFile(pathName: string);
      function SolveRowsColsBoxes(var stop, nonePossible: boolean): boolean;
      function SolveSingletonSquares(var nonePossible: boolean): boolean;
      function MainSolveSteps(var done, stop, nonePossible: boolean): boolean;
  protected
      saveFile: string;
		procedure RowColToBox(row, col: integer; var boxNum, boxPos: integer); virtual;
      procedure FinishCreate;
  public
      { Public declarations }
      clickedRow, clickedCol: integer;
      pausesDuration: Int64;
      cells, columns, boxes: TCellArray;
      isStarted, stepping: boolean;
	   numRowsCols: integer; // 9 or 6, for the different puzzle sizes
      procedure ClearSelection;
      procedure BubbleResult(row, col: integer; key: string);
      function CheckAllowedResult(row, col: integer; key: string; verbose: boolean): boolean;
		function IsPuzzleSolved: boolean;
  end;

var
  SudokuBaseForm: TSudokuBaseForm;
  currentDir: string;

implementation

uses Sudoku6x6;
{$R *.dfm}


procedure TSudokuBaseForm.FormCreate(Sender: TObject);
begin
   numRowsCols := 9;
   FinishCreate;
end;

procedure TSudokuBaseForm.FinishCreate;
var
	row, col, boxNum, boxPos: Integer;
   cell: TCell;
begin
	// init some global variables
   ReadIni;
   useC := FALSE; // use our C DLL for the backtracking (not sure I will code for this)

   isStarted := FALSE;

	KeyPreview := True; // ensures the form can receive KeyPress events before any controls

   currentDir := GetCurrentDir;
//   ShowMessage(currentDir);

   for row := 1 to numRowsCols do
      for col := 1 to numRowsCols do
      begin
         RowColToBox(row, col, boxNum, boxPos);
         cell := TCell.Create(self, row, col, boxNum);

         cells[row,col] := cell;
         columns[col, row] := cell;
         try
	         boxes[boxNum, boxPos] := cell;
         except
         	ShowMessage('error');
         end;
      end;
end;

// After enter a valid result digit asDigit in square aiRow, aiCol, bubble it out: remove it from the
// 1 to iiRowsCols digits that are considered possible in all other squares in its row, column and block
procedure TSudokuBaseForm.BubbleResult(row, col: integer; key: string);
var
   i, iDigit, boxNum: integer;
   cell: TCell;
begin
	if key = '' then EXIT;

   iDigit := StrToInt(key);

   // check in this row
   for i := 1 to numRowsCols do
   begin
      cell := cells[row, i];
      if i <> col then
         cell.SetPossible(iDigit, IMPOSSIBLE);
	end;

   // check in this column
   for i := 1 to numRowsCols do
   begin
      cell := cells[i, col];
      if i <> row then
         cell.SetPossible(iDigit, IMPOSSIBLE);
   end;

   // check in this 3x3 or 2x3 box
   boxNum := cells[row, col].boxNum;
   for i := 1 to numRowsCols do
   begin
      cell := boxes[boxNum, i];
      if (cell.row <> row) and (cell.col <> col) then
         cell.SetPossible(iDigit, IMPOSSIBLE);
   end;
end;

// Check whether key is a valid result in the square row, col - i.e. it
// isn't already present in that square's row, column or 3x3 box.
// If verbose, give a message if it's not allowed.
// Return TRUE if it's allowed, FALSE if not.
function TSudokuBaseForm.CheckAllowedResult(row, col: integer; key: string;
														  verbose: boolean): boolean;
var
   i, boxNum: integer;
   cell: TCell;
begin
   if key = '' then  // clearing is always allowed
   begin
   	result := true;
      EXIT;
   end;

   // check in this row
   for i := 1 to numRowsCols do
   begin
      cell := cells[row, i];
      if (i <> col) and cell.isResultVisible and (cell.ResultText = key) then
      begin
         if verbose then
            ShowMessage('You cannot put a ' + key +
            	' in this square, because it already occurs in another ' +
            	'square in the same row.');
         result := FALSE;
         EXIT;
      end;
   end;

   // check in this column
   for i := 1 to numRowsCols do
   begin
      cell := cells[i, col];
      if (i <> row) and cell.isResultVisible and (cell.ResultText = key) then
      begin
         if verbose then
            ShowMessage('You cannot put a ' + key +
            	' in this square, because it already occurs in another ' +
            	'square in the same column.');
         result:= FALSE;
         EXIT;
      end;
   end;

   // check in this 3x3 or 3x2 box
   boxNum := cells[row, col].boxNum;
   for i := 1 to numRowsCols do
   begin
      cell := boxes[boxNum, i];
      if (cell.row <> row) and (cell.col <> col) and cell.isResultVisible and
            (cell.ResultText = key) then
      begin
         if verbose then
            ShowMessage('You cannot put a ' + key +
            	' in this square, because it already occurs in another ' +
            	'square in the same ' +
               (if numRowsCols = 9 then '3 x 3' else '3 x 2') + ' box.');
         result := FALSE;
         EXIT;
      end;
   end;

   result := TRUE // it's OK!
end;

// Clear the selected colour in whichever square (if any) is currently highlighted
procedure TSudokuBaseForm.ClearSelection;
begin
   if (clickedRow > 0) and (clickedCol > 0) then
      cells[clickedRow, clickedCol].ResetColor;
end;

// Handle navigation keys. We have to use this instead of an OnKeyDown event
// because normal controls on the form like buttons were swallowing and acting
// on keys like Tab. This happens earlier.
procedure TSudokuBaseForm.FormShortCut(var Msg: TWMKey; var Handled: Boolean);
var
   shifted: boolean;
   newRow, newCol: integer;
   c: Word;
begin
   c := msg.CharCode;
   shifted := GetKeyState(VK_SHIFT) < 0;
   newRow := clickedRow;
   newCol := ClickedCol;

   // Tab: walk forward through the rows and columns, going from the end of one row
   //      to the start of the next, and from the end of the last row to the top.
   // Shift-Tab: Same in reverse.
   if c = vkTab then
   begin
      if not shifted then
      begin
			Inc(newCol);
			if newCol > numRowsCols then
         begin
				newCol := 1;
				Inc(newRow);
				if newRow > numRowsCols then
					newRow := 1;
			end;
      end
		else
      begin
			Dec(newCol);
			if newCol < 1 then
         begin
				newCol := numRowsCols;
				Dec(newRow);
				if newRow < 1 then
					newRow := numRowsCols;
			end;
		end;
		cells[newRow, newCol].FrameClick(self);
      handled := TRUE; // tell VCL that we handled the key
		EXIT;
   end;

   // Arrow keys move in expected directions but don't wrap
   if c = vkDown then
   begin
		if newRow < numRowsCols then
      begin
			Inc(newRow);
			cells[newRow, newCol].FrameClick(self);
      end
		else
			beep;
      handled := TRUE; // tell VCL that we handled the key
		EXIT;
   end;

   if c = vkUp then
   begin
		if newRow > 1 then
      begin
			Dec(newRow);
			cells[newRow, newCol].FrameClick(self);
      end
		else
			beep;
      handled := TRUE; // tell VCL that we handled the key
		EXIT;
   end;

   if c = vkRight then
   begin
		if newCol < numRowsCols then
      begin
			Inc(newCol);
			cells[newRow, newCol].FrameClick(self);
      end
		else
			beep;
      handled := TRUE; // tell VCL that we handled the key
		EXIT;
   end;

   if c = vkLeft then
   begin
		if newCol > 1 then
      begin
			Dec(newCol);
			cells[newRow, newCol].FrameClick(self);
      end
		else
			beep;
      handled := TRUE; // tell VCL that we handled the key
		EXIT;
   end;

   // PgUp/PgDn go to top or bottom
   if c = vkNext { Page Down } then
   begin
		newRow := numRowsCols;
		cells[newRow, newCol].FrameClick(self);
      handled := TRUE; // tell VCL that we handled the key
		EXIT;
   end;

   if c = vkPrior { Page Up } then
   begin
		newRow := 1;
		cells[newRow, newCol].FrameClick(self);
      handled := TRUE; // tell VCL that we handled the key
		EXIT;
   end;

   // Home/End go to start of end of line
   if c = vkEnd then
   begin
		newCol := numRowsCols;
		cells[newRow, newCol].FrameClick(self);
      handled := TRUE; // tell VCL that we handled the key
		EXIT;
   end;

   if c = vkHome then
   begin
		newCol := 1;
		cells[newRow, newCol].FrameClick(self);
      handled := TRUE; // tell VCL that we handled the key
		EXIT;
   end;

//   inherited; // do default processing
end;

// Catch digits being typed to put them into a cell. Do it here, and pass it through to the cell, because
// the frame for the cell doesn't have key events
procedure TSudokuBaseForm.FormKeyPress(Sender: TObject; var Key: Char);
var
   cell: TCell;
begin
   if (clickedRow = 0) or (clickedCol = 0) then EXIT;

	cell := cells[clickedRow, clickedCol];

	// Can't change original values once started
   if isStarted and cell.isResultVisible and cell.isOriginal then
   begin
      Beep;
      EXIT;
   end;

	if (key >= '1') and ((key <= '6') or ((numRowsCols = 9) and (key <= '9'))) then
   begin
      if CheckAllowedResult(clickedRow, clickedCol, key, VERBOSE) then
      begin
         cell.SetResult(key, not (isStarted or cell.areDigitsVisible));
         Application.ProcessMessages;
         if IsPuzzleSolved then
            ShowMessage('You have solved the puzzle!');
      end;
   end;
end;

// Follow a bunch of steps to solve the puzzle.
// Optionally stop between each step with messages, if stepping.
procedure TSudokuBaseForm.FullSolve;
var
   stopwatch, stopwatch2: TStopwatch;
   elapsedMilliseconds: Int64;
   done, stop, nonePossible, backtrack: boolean;
   duration: Int64;
   smessage: string;
   backtracker: TBacktrack;
begin
   stopwatch := TStopwatch.StartNew;

   Screen.Cursor := crHourGlass;
   try
   	backtrack := FALSE;
      done := FALSE;
      stop := FALSE;
      nonePossible := FALSE;

      PrepareForSolve;

      if stepping then
         if MessageDlg('Did preparation step - reset possible and impossible ' +
         		'digits based on currently solved squares.' +
         		#13 + #13 + 'Continue stepping?', mtConfirmation,
               [mbYes, mbNo], 0) <> mrYes then EXIT;

      if method <> ONLY_BACKTRACK then
         MainSolveSteps(done, stop, nonePossible);

      if NOT (done or stop) then
      begin
         if method <> SIMPLE_PROMPT_BACKTRACK then backtrack := TRUE;
         if NOT backtrack then
         begin
            stopwatch2 := TStopwatch.StartNew;
            backtrack := (MessageDlg(
            	'Sorry, the simple solving rules in this program were not able to completely solve the puzzle.' +
               #13 + #13 +
               'Would you like to have the program use its backtracking approach of trying all remaining possibilities?',
               mtConfirmation, [mbYes, mbNo], 0) = mrYes);
            stopwatch2.Stop;
            Inc(pausesDuration, stopwatch2.ElapsedMilliseconds);
         end;
         if backtrack then
         begin
            stepping := FALSE;

            if NOT useC and showAttempts then
            begin
	            stopwatch2 := TStopwatch.StartNew;
               if MessageDlg(
                  'Showing the attempted digits when using the code for the backtracking ' +
                  'approach can make solving it extremely slow!' + #13 + #13 +
                  'Are you sure you want to show the attempted digits?',
               	mtConfirmation, [mbYes, mbNo], 0) <> mrYes then showAttempts := FALSE;
               stopwatch2.Stop;
               Inc(pausesDuration, stopwatch2.ElapsedMilliseconds);
            end;

            backtracker := TBacktrack.Create;
            backtracker.Initialize(Self);
            backtracker.DoAll;
            backtracker.Free;
{  // this code allows switching between backtrackers
            nvo_backtrack_base lnv_backtrack
            if gbUseC then
               lnv_backtrack = CREATE nvo_backtrack_c
            else
               lnv_backtrack = CREATE nvo_backtrack_pb
            end if

            lnv_backtrack.uf_init(this)
            lnv_backtrack.uf_do_all()
}        end
         else
         begin
            SHowMessage('You can try solving the rest of it manually.');
            reportDuration := FALSE;
         end;
      end;

      if IsPuzzleSolved then
      begin
         stopwatch.Stop;
         elapsedMilliseconds := stopwatch.ElapsedMilliseconds;
         duration := elapsedMilliseconds - pausesDuration;
         smessage := 'The puzzle has been successfully solved.';
         if reportDuration and NOT stepping then
         begin
            smessage := smessage + #13 + #13 + 'That took ' + FormatFloat('##0.00', duration / 1000.0) +
            			' seconds';
            if pausesDuration > 0 then smessage := smessage + ', ignoring any pauses';
            smessage := smessage + '.';
         end;
         ShowMessage(sMessage);
      end;
   finally
      Screen.Cursor := crDefault;
   end;
end;

// Do the two regular solving steps in a loop, until nothing further can be done.
// Return whether anything was solved during these steps, and set all of done,
// stop and nonePossible.
// Return immediately if stop or nonePossible are set.
function TSudokuBaseForm.MainSolveSteps(
            var done, stop, nonePossible: boolean): boolean;
var
   solvedSomething: boolean;
begin
   repeat
      solvedSomething := SolveSingletonSquares(nonePossible);
      done := IsPuzzleSolved;
      if NOT done and stepping then
      	if MessageDlg('Did step to solve any squares with only one possible digit in them.' +
         		#13 + #13 + 'Continue stepping?', mtConfirmation,
               [mbYes, mbNo], 0) <> mrYes then
         begin
         	result := solvedSomething;
            EXIT;
         end;

      if done or nonePossible then
      begin
      	result := solvedSomething;
         EXIT;
      end;

      if SolveRowsColsBoxes(stop, nonePossible) then
         solvedSomething := TRUE;
      done := IsPuzzleSolved;
      if done or stop or nonePossible then
      begin
      	result := solvedSomething;
         EXIT;
      end;
   until NOT solvedSomething;

   result := solvedSomething;
end;

// show the 1-numRowsCols digits in all squares that don't have a result digit in
// them or already have the 1-numRowsCols digits in them
procedure TSudokuBaseForm.ManualPlayButtonClick(Sender: TObject);
var
	row, col: integer;
	cell: TCell;
begin
	for row := 1 to numRowsCols do
		for col := 1 to numRowsCols do
		begin
			cell := cells[row, col];
			if NOT (cell.isResultVisible OR cell.areDigitsVisible) then
				cell.ShowDigits;
		end;

	PrepareForSolve; // re-bubble all of the results

	// TODO
	SolveButton.Enabled := TRUE;
	//cb_step.Enabled := TRUE;

	isStarted := TRUE;
end;

procedure TSudokuBaseForm.OptionsButtonClick(Sender: TObject);
begin
   OptionsForm.ShowModal;
end;

// Return a pointer to one of the three arrays, based on a passed-in type value
function TSudokuBaseForm.GetArrayOfType(atype: ArrayType): PCellArray;
begin
   CASE aType of
      ROW_TYPE:
         result := @cells;
      COL_TYPE:
      	result := @columns;
      BOX_TYPE:
      	result := @boxes;
      else
      	result := nil; // can't really happen
   END;
end;

// Reset the colours on all squares to the standard buttonface or white
procedure TSudokuBaseForm.ResetBackColors;
var
	row, col: integer;
begin
   for row := 1 to numRowsCols do
      for col := 1 to numRowsCols do
         cells[row, col].ResetColor;
end;

{ Convert a row and column number to a box number and box position - both values 1 to numRowsCols.
 Rules for this a 9x9 Sudoku:
    Box number 1 is the top-left numRowsCols squares, box 2 is the top-centre numRowsCols,
    box 3 is the top-right numRowsCols, box 4 is the middle-left numRowsCols, etc.
 Box position is the sequential position 1-numRowsCols within the box.
}
procedure TSudokuBaseForm.RowColToBox(row, col: integer; var boxNum,
  boxPos: integer);
var
	RowPart, ColPart: integer;
begin
	// first calc the box number from two parts
	RowPart := (Row + 2) div 3; // gives 1, 2 or 3 for top 3 rows, centre 3 rows, and bottom 3 rows respectively
	ColPart := (Col   + 2) div 3; // gives 1, 2 or 3 for left 3 columns, middle 3 columns, or right 3 columns respectively

	BoxNum := (RowPart - 1) * 3 + ColPart;

	// now calc the position within the box from two parts
	RowPart := (((Row - 1) Mod 3) + 1) * 3 - 2; // gives 1 for rows 1, 4 and 7, 4 for rows 2, 5 and 8, and 7 for rows 3, 6 and 9
	ColPart := ((Col - 1) Mod 3) + 1; // gives 1 for columns 1, 4 and 7, 2 for cols 2, 5 and 8, and 3 for cols 3, 6 and 9

	BoxPos := RowPart + (ColPart - 1);
end;

// When passed in an array where the first index is rows, columns, or boxes, work
// through row/col/box number aiFirstIndex, looking for an unsolved square where
//  the digit aiDigit only occurs in one of the numRowsCols squares, and if found, solve it.
// Return whether or not anything was solved.
// Follow a bunch of steps to solve the puzzle
procedure TSudokuBaseForm.SolveButtonClick(Sender: TObject);
begin
	stepping := FALSE;

   if not isStarted then ManualPlayButtonClick(Sender);    

   FullSolve;
end;

function TSudokuBaseForm.SolveRowColBox(var anArray: TCellArray;
				firstIndex, digit: integer): boolean;
var
	solvedOne: boolean;
   secondIndex, numOccurrences, occurrenceIndex: integer;
   cell: TCell;
begin
   numOccurrences := 0;
   occurrenceIndex := 0;
   solvedOne := FALSE;

   for secondIndex := 1 to numRowsCols do
   begin
      cell := anArray[firstIndex, secondIndex];
      if NOT cell.areDigitsVisible then CONTINUE;
      if cell.IsPossible(digit) then
      begin
         Inc(numOccurrences);
         if numOccurrences > 1 then BREAK;
         occurrenceIndex := secondIndex;
      end;
   end;
   if numOccurrences = 1 then
   begin
      cell := anArray[firstIndex, occurrenceIndex];
      cell.FrameClick(Self);
      cell.SetResult(IntToStr(digit), SOLVED);
      Application.ProcessMessages;
      if stepping then
      begin
         if doSleeps then
         begin
            sleep(500);
            Inc(pausesDuration, 500);
         end;
      end
      else if doSleeps then
      begin
         sleep(200);
         Inc(pausesDuration, 200);
      end;

      solvedOne := TRUE;
   end;

   result := solvedOne;
end;

// For all rows, all columns, and all boxes, look for an unsolved digit in that
// row/col/box that only occurs once, and solve it.
// If you hit a square with no digits possible, set abNonePossible to TRUE and return FALSE
// Return whether any were solved.
// Set stop to true if you are stepping, you give progress message, and they ask to stop.
function TSudokuBaseForm.SolveRowsColsBoxes(var stop, nonePossible: boolean): boolean;
var
   solvedAny: boolean;
   firstIndex, i: integer;
   aType: ArrayType;
   myCells: PCellArray;
const
	typeNames: array[1..3] of string = ('row', 'column', 'box');
   extraText: array[1..3] of string = ('', '', ' (counting across the boxes then down)');
begin
   stop := FALSE;
   solvedAny := FALSE;

   for aType := ROW_TYPE to BOX_TYPE do
   begin
   	myCells := GetArrayOfType(aType);
      for firstIndex := 1 to numRowsCols do
      begin
         for i := 1 to numRowsCols do
            if SolveRowColBox(myCells^, firstIndex, i) then
            	solvedAny := TRUE;
         if NOT IsPuzzleSolved and stepping then
            if MessageDlg('Did step to solve any squares where one digit was only ' +
            		'possible in one square of ' + typeNames[Ord(aType)] + ' ' +
                  IntToStr(firstIndex) + extraText[Ord(aType)] +
                  '.~n~nContinue stepping?', mtConfirmation,
                  [mbYes, mbNo], 0) <> mrYes then
            begin
               stop := TRUE;
               result := solvedAny;
               EXIT;
            end;
      end;
   end;

   result := solvedAny;
end;

// Solve any squares showing the 1-numRowsCols digits, where only one of those
// digits is bold (i.e. possible).
// Also set abNonePossible and return FALSE if you hit a square with no possible
// values (can occur when doing backtracking).
// Return whether or not any squares were solved.
function TSudokuBaseForm.SolveSingletonSquares(var nonePossible: boolean): boolean;
var
	solvedOne: boolean;
   row, col, i, numVisible, visibleOne: integer;
   cell: TCell;
begin
   nonePossible := FALSE;
   solvedOne := FALSE;

   for row := 1 to numRowsCols do
      for col := 1 to numRowsCols do
      begin
         cell := cells[row, col];
         if NOT cell.areDigitsVisible then CONTINUE;
         numVisible := 0;
         visibleOne := 0;
         for i := 1 to numRowsCols do
            if cell.IsPossible(i) then
            begin
               Inc(numVisible);
               if numVisible > 1 then BREAK;
               visibleOne := i;
            end;
         if numVisible = 1 then
         begin
            cell.FrameClick(Self);
            cell.SetResult(IntToStr(visibleOne), SOLVED);
            Application.ProcessMessages;
            if stepping then
            begin
               if doSleeps then
               begin
                  sleep(500);
                  Inc(pausesDuration, 500);
               end;
            end
            else if doSleeps then
            begin
               sleep(200);
               Inc(pausesDuration, 200);
            end;
            solvedOne := TRUE;
         end
         else if numVisible = 0 then
         begin
            nonePossible := TRUE;
            result := FALSE;
            EXIT;
         end;
      end;

   result := solvedOne;
end;

// Switch to the other size of sudoku (after confirmation, if the puzzle isn't empty)
procedure TSudokuBaseForm.SwitchButtonClick(Sender: TObject);
begin
   if NOT IsPuzzleClear then
		if MessageDlg(
			'There are already results in the puzzle. Are you sure you want to switch to the other size?',
			mtConfirmation, [mbYes, mbNo], 0) <> mrYes then EXIT;

   if numRowsCols = 9 then
   begin
      SudokuBaseForm.Hide;
		Sudoku6x6Form.Show;
   end
   else
   begin
      Sudoku6x6Form.Hide;
   	SudokuBaseForm.Show;
   end;
end;

// Return TRUE if no squares of the puzzle have anything in them (it's "clear"), FALSE otherwise.
function TSudokuBaseForm.IsPuzzleClear: boolean;
var
   row, col: integer;
begin
   for row := 1 to numRowsCols do
   begin
      for col := 1 to numRowsCols do
      begin
         if cells[row, col].isResultVisible then
         begin
            result := FALSE;
            EXIT;
         end;
      end;
   end;

   result := TRUE;
end;

// Return whether or not the puzzle is solved
function TSudokuBaseForm.IsPuzzleSolved: boolean;
var
   row, col: integer;
   cell: TCell;
begin
   for row := 1 to numRowsCols do
   begin
      for col := 1 to numRowsCols do
      begin
         cell := cells[row, col];
         if NOT (cell.isResultVisible and (cell.ResultText > '')) then
         begin
            result := FALSE;
            EXIT;
         end;
      end;
   end;

   result := TRUE;
end;

// Save the currently selected results, in numRowsCols rows of a user-selected text file,
//   surrounded by border and separator rows.
// Each row is numRowsCols consecutive results from the cells in that row of the puzzle,
//   returned from the cell's SaveValue method,
//    with vertical bar separators before the first one, and after each one.
// The cell value is three spaces if it doesn't have a result digit in it,
//   or the result digit 3 times, if it's bold (an original puzzle digit), or the result
//   digit surrounded by two spaces if not.
procedure TSudokuBaseForm.SaveButtonClick(Sender: TObject);
var
   SaveDialog: TSaveDialog;
   pathName, initDir, borderLine, vertical, s: string;
   row, col: integer;
begin
   SaveDialog := TSaveDialog.Create(nil);

   // default to saving a previous-saved (or loaded) one
	if saveFile > '' then
	begin
		SaveDialog.FileName := TPath.GetFileName(saveFile);
		initDir := TPath.GetDirectoryName(saveFile);
	end
	else
   begin
      SaveDialog.FileName := 'save.sud';
		initDir := currentDir;
   end;

   try
   	SaveDialog.Filter := 'Sudoku Files (*.sud)|*.sud';
		SaveDialog.InitialDir := initDir;
		SaveDialog.Options := [ofNoChangeDir, ofOverwritePrompt];
		if SaveDialog.Execute then
			pathname := SaveDialog.FileName
		else
			EXIT;
	finally
		SaveDialog.Free;
	end;

   // build the output
   vertical := '|';
   borderLine := '+' + DupeString('---+', numRowsCols);
   s := '';

   for row := 1 to numRowsCols do
   begin
		s := s + borderLine + #10;
		for col := 1 to numRowsCols do
			s := s + vertical + cells[row, col].SaveValue;
		s := s + vertical + #10;
	end;
	s := s + borderLine + #10;

   // write it out
   try
    TFile.WriteAllText(pathName, s, TEncoding.ANSI);
  except
    on E: Exception do
      ShowMessage(format('Unable to write to file %s.' + sLineBreak + 'Error: %s',
        						 [pathName, E.Message]));
  end;
end;

// Load a previously-saved set of results, saved by SaveButtonClick.
// The results in numRowsCols rows of a user-selected text file, surrounded by border and separator rows.
// Each row is numRowsCols consecutive results from the cells in that row of the
//    puzzle, returned from SaveValue(),
//    with vertical bar separators before the first one, and after each one.
// The cell value is three spaces if it doesn't have a result digit in it,
//   or the result digit 3 times, if it's bold (an original puzzle digit), or the
//   result digit surrounded by two spaces if not.
procedure TSudokuBaseForm.LoadButtonClick(Sender: TObject);
var
   OpenDialog: TOpenDialog;
	pathName, initDir: string;
begin
	OpenDialog := TOpenDialog.Create(nil);

	// first make sure we select a file, defaulting to a previously-saved one
	if saveFile > '' then
	begin
		OpenDialog.FileName := TPath.GetFileName(saveFile);
		initDir := TPath.GetDirectoryName(saveFile);
	end
	else
		initDir := currentDir;

	try
		OpenDialog.Filter := 'Sudoku Files (*.sud)|*.sud';
		OpenDialog.InitialDir := initDir;
		OpenDialog.Options := [ofNoChangeDir, ofFileMustExist];
		if OpenDialog.Execute then
			pathname := OpenDialog.FileName
		else
			EXIT;
	finally
		OpenDialog.Free;
	end;

	// Check we can clear the puzzle
	if NOT IsPuzzleClear() then
		if MessageDlg(
			'Is it OK to clear whatever is currently displayed, before Loading a puzzle?',
			mtConfirmation, [mbYes, mbNo], 0) <> mrYes then EXIT;

   LoadFile(pathName);
end;

// Clear the puzzle and open and display the passed-in file
procedure TSudokuBaseForm.LoadFile(pathName: string);
var
	reader: TStreamReader;
   row, col, lineNo, lineLen, numCells: integer;
   first, isOriginal: boolean;
   line, s, digit: String;
begin
	if not FileExists(pathName) then
   begin
   	ShowMessage('Cannot open file ' + pathName + ' since it doesn''t seem to exist.');
      EXIT;
   end;

	ClearAll;
   first := TRUE;

	try
      reader := TStreamReader.Create(pathName);
      lineNo := 0;
      try
         while not reader.EndOfStream do
         begin
            line := reader.ReadLine;
            Inc(lineNo);
            if lineNo Mod 2 = 1 then CONTINUE; // skip alternate lines


            // todo
            row := lineNo div 2;

            // Check it is for the right size puzzle - line lengths seem to be either
            // 4 x iiRowsCols, or one higher
            if first then
            begin
               first := FALSE;
               lineLen := Length(line);
               if lineLen Mod 2 = 1 then Dec(lineLen);
               numCells := lineLen div 4;
               if numCells <> numRowsCols then
               begin
                  ShowMessage(format('This appears to be a file saved from a %d x %d Sudoku, ' +
                                     'rather than a %d x %d one.',
                                     [numCells, numCells, numRowsCols, numRowsCols]) +
                                     #13 + #13 + 'It cannot be loaded into this puzzle');
                  BREAK;
               end;
            end;

            // parse the line and fill in the results
            for col := 1 to numRowsCols do
            begin
               s := line.Substring(col * 4 - 3, 3);
               digit := s[2];
               if digit = ' ' then CONTINUE; // nothing in this square
               isOriginal := s[1] <> ' ';
               cells[row, col].SetResult(digit, isOriginal);
            end;
         end;

         // save for re-loads or re-saves, after successful save
         saveFile := pathName;
      finally
         reader.Free;
      end;
   except
      on E: EInOutError do
         ShowMessage('Error reading file ' + pathName + ' ' + E.Message);
      on E: Exception do
         ShowMessage('Error processing file ' + pathName + ' ' + E.Message);
   end;
end;

procedure TSudokuBaseForm.ClearAll;
var
	row, col: integer;
begin
	for row := 1 to numRowsCols do
		for col := 1 to numRowsCols do
			cells[row, col].ClearAll;

	ResetBackcolors;
	clickedRow := 0;
	clickedCol := 0;

	//ManualPlayButton.Enabled := FALSE;
	//SolveButton.Enabled := FALSE;

	isStarted := FALSE;
	stepping := FALSE;

	pausesDuration := 0;

end;

// Clear the whole puzzle back to nothing in it and no selected square
procedure TSudokuBaseForm.ClearButtonClick(Sender: TObject);
begin
   if NOT IsPuzzleClear then
		if MessageDlg(
			'There are already results in the puzzle. Are you sure you want to clear it?',
			mtConfirmation, [mbYes, mbNo], 0) <> mrYes then EXIT;

   ClearAll;
end;

// Show the PDF Help file
procedure TSudokuBaseForm.HelpButtonClick(Sender: TObject);
var
   ret: integer;
const
   pdfFile = 'sudoku.pdf';
begin
   if NOT FileExists(pdfFile) then
   begin
   	ShowMessage('Cannot find Help file ' + pdfFile + '.');
      EXIT;
   end;
	ret := ShellExecute(0,'open', PChar(pdfFile), nil, nil, SW_SHOWNORMAL);
   if ret <= 32 then
      ShowMessage(Format('Error # %d opening Help file %s.', [ret, pdfFile]));
end;

// Prepare for solving the puzzle by re-bubbling all results in squares across
// their rows, down their columns, and in their boxes.
procedure TSudokuBaseForm.PrepareForSolve;
var
   row, col: integer;
   cell: TCell;
begin
   // First reset all squares with digits in them (or that are empty)
   for row := 1 to numRowsCols do
      for col := 1 to numRowsCols do
      begin
         cell := cells[row, col];
         if NOT (cell.isResultVisible and (cell.ResultText > '')) then
         begin
            cell.ClearAll;
            cell.ShowDigits;
         end;
      end;

   // Now bubble out all values in squares with results
   for row := 1 to numRowsCols do
      for col := 1 to numRowsCols do
      begin
         cell := cells[row, col];
         if cell.isResultVisible and (cell.ResultText() > '') then
            BubbleResult(row, col, cell.ResultText);
      end;
end;

Initialization

ReportMemoryLeaksOnShutdown := True;

end.


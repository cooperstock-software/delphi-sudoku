unit Globals;

interface

uses System.IniFiles;

type
   Methods = (SIMPLE_PROMPT_BACKTRACK = 1,
              SIMPLE_AUTO_BACKTRACK = 2,
              ONLY_BACKTRACK = 3);

procedure ReadIni;
procedure WriteIni;

var
   currentDirectory: string;
   method: Methods; // selection from the Methods above
   showSmallDigits: boolean; // do we show the small digits, or not?
   doSleeps: boolean; // do we sleep after each solved (or proposed) digit?
   reportDuration: boolean; // do we report the # of seconds taken for a solve?
   debug: boolean; // are we in debug mode
   useC: boolean; // use our C DLL for the backtracking (not sure I will code for this)
	showAttempts: boolean; // in backtracking code, show digits being considered

const
   VERBOSE: boolean = TRUE;
   SILENT: boolean = FALSE;

   // values for sOriginal arg to a couple of cell functions
   ORIGINAL: boolean  = TRUE;
   SOLVED: boolean  = FALSE;

   // values for isPossible arg to a cell function
   POSSIBLE: boolean  = TRUE;
   IMPOSSIBLE: boolean  = FALSE;

   FileName: string = 'sudoku.ini';


   implementation

// Read the values in from the ini file
procedure ReadIni;
var
	iniFile: TMemIniFile;
begin
	iniFile := TMemIniFile.Create(FileName);

   method := Methods(iniFile.ReadInteger('All', 'Method', Ord(SIMPLE_PROMPT_BACKTRACK)));
   showSmallDigits := iniFile.ReadBool('All', 'ShowSmallDigits', TRUE);
   doSleeps := iniFile.ReadBool('All', 'DoSleeps', TRUE);
   reportDuration := iniFile.ReadBool('All', 'ReportDuration', FALSE);
   showAttempts := iniFile.ReadBool('All', 'ShowAttempts', FALSE);
   debug := iniFile.ReadBool('All', 'Debug', FALSE);

   iniFile.Free;
end;

// Write the current values back to the INI file
procedure WriteIni;
var
	iniFile: TMemIniFile;
begin
	iniFile := TMemIniFile.Create(FileName);
   iniFile.AutoSave := TRUE; // don't have to write back; happens on destroy

   iniFile.WriteInteger('All', 'Method', Ord(method));
   iniFile.WriteBool('All', 'ShowSmallDigits', showSmallDigits);
   iniFile.WriteBool('All', 'DoSleeps', doSleeps);
   iniFile.WriteBool('All', 'ReportDuration', reportDuration);
   iniFile.WriteBool('All', 'ShowAttempts', showAttempts);
// iniFile.WriteBool('All', 'Debug', debug); // only set this manually

   iniFile.Free;
end;

end.

unit Options;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Globals, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TOptionsForm = class(TForm)
    SleepsCheckBox: TCheckBox;
    ReportDurationCheckBox: TCheckBox;
    ShowSmallDigitsCheckBox: TCheckBox;
    ShowAttemptsCheckBox: TCheckBox;
    MethodRadioGroup: TRadioGroup;
    SaveButton: TButton;
    CancelButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
    procedure SaveButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  OptionsForm: TOptionsForm;

implementation

{$R *.dfm}

// Initialize the controls from our globals
procedure TOptionsForm.FormCreate(Sender: TObject);
begin
   SleepsCheckBox.Checked := doSleeps;
   ReportDurationCheckBox.Checked := reportDuration;
   ShowSmallDigitsCheckBox.Checked := showSmallDigits;
   ShowAttemptsCheckBox.Checked := showAttempts;

   MethodRadioGroup.ItemIndex := Ord(method) - 1;
end;

// Set our globals from the controls, then Save to the INI file
procedure TOptionsForm.SaveButtonClick(Sender: TObject);
begin
   doSleeps := SleepsCheckBox.Checked;
   reportDuration := ReportDurationCheckBox.Checked;
   showSmallDigits := ShowSmallDigitsCheckBox.Checked;
   showAttempts := ShowAttemptsCheckBox.Checked;

   method := Methods(MethodRadioGroup.ItemIndex + 1);

   WriteIni;

   ModalResult := mrOk;
end;

// Just cancel without saving
procedure TOptionsForm.CancelButtonClick(Sender: TObject);
begin
   ModalResult := mrCancel;
end;

end.

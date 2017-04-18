unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, DB, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls, DBGrids, lconvencoding;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    btnOpen: TButton;
    btnExit: TButton;
    btnSave: TButton;
    ds1: TDataSource;
    dbf1: TDbf;
    dbgrid1: TDBGrid;
    memoLog: TMemo;
    OpenDialog1: TOpenDialog;
    procedure btnExitClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    function dbf1Translate(Dbf: TDbf; Src, Dest: PChar; ToOem: boolean): integer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmMain: TfrmMain;
  curDir: string;
  filename: string;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.btnExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.btnOpenClick(Sender: TObject);
var
  i: integer;
begin
  if OpenDialog1.Execute then
  begin
    ds1.DataSet.Active := False;
    ds1.DataSet.Close;
    dbf1.Close;
    filename := OpenDialog1.Filename;
    memoLog.Append(filename);
    dbf1.FilePathFull := ExtractFilePath(filename);
    dbf1.TableName := ExtractFileName(filename);
    dbf1.Active := True;
    dbf1.Open;
    for i := 0 to dbf1.FieldCount - 1 do
    begin
      // dbf1.Fields[i].DataType = ftString ftFloat ftInteger
      memoLog.Append('Имя поля:' + dbf1.Fields[i].FieldName +
        ' размер поля:' + IntToStr(dbf1.Fields[i].DataSize));
      //      DBGrid1.Columns[i].Title.Caption := 'Name';
      if dbf1.Fields[i].DataType = ftString then
         TStringField(dbf1.Fields[i]).Transliterate := True;
      DBGrid1.Columns[i].FieldName := dbf1.Fields[i].FieldName;
    end;
    ds1.DataSet.Active := True;
    ds1.DataSet.Open;
    dbgrid1.Show;
  end
  else
  begin
    filename := '';
  end;
end;

function TfrmMain.dbf1Translate(Dbf: TDbf; Src, Dest: PChar; ToOem: boolean): integer;
var
  S: string;
begin
  if ToOem then
    S := ConvertEncoding(Src, 'utf8', 'cp866')
  else
    S := ConvertEncoding(Src, 'cp866', 'utf8');
  StrCopy(Dest, PChar(S));
  Result := StrLen(Dest);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  curDir := ExtractFilePath(Application.ExeName);
  OpenDialog1.Filter := 'DBase Table|*.dbf*;.DBF';
  memoLog.Clear;
  //  dbf1.Create(nil);

end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  dbf1.Free;
end;

end.

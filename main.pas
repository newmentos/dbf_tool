unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, db, FileUtil, Forms, Controls, Graphics, Dialogs,
  StdCtrls, DBGrids;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    btnOpen: TButton;
    btnExit: TButton;
    btnSave: TButton;
    DataSource1: TDataSource;
    dbf1: TDbf;
    dbgrid1: TDBGrid;
    memoLog: TMemo;
    OpenDialog1: TOpenDialog;
    procedure btnExitClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
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
    filename := OpenDialog1.Filename;
    memoLog.Append(filename);
    dbf1.FilePathFull := ExtractFilePath(filename);
    dbf1.TableName := ExtractFileName(filename);
    dbf1.Active := True;
    dbf1.Open;
    for i := 0 to dbf1.FieldCount - 1 do
    begin
      // dbf1.Fields[i].DataType = ftString ftFloat ftInteger
      memoLog.Append(dbf1.Fields[i].FieldName + ' ' + IntToStr(dbf1.Fields[i].DataSize));
    end;
    dbf1.Close;
  end
  else
  begin
    filename := '';
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  curDir := ExtractFilePath(Application.ExeName);
  OpenDialog1.Filter := 'DBase Table|*.dbf*;.DBF';
  memoLog.Clear;
end;

end.

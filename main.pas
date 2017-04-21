unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, DB, Sqlite3DS, FileUtil, Forms, Controls, Graphics,
  Dialogs, StdCtrls, DBGrids, lconvencoding, LazFileUtils;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    btnOpen: TButton;
    btnExit: TButton;
    btnSave: TButton;
    ds1: TDataSource;
    dsDbf: TDbf;
    dbgrid1: TDBGrid;
    memoLog: TMemo;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    dsSqlite3: TSqlite3Dataset;
    procedure btnExitClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    function dsDbfTranslate(Dbf: TDbf; Src, Dest: PChar; ToOem: boolean): integer;
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
    dsDbf.Close;
    filename := OpenDialog1.Filename;
    memoLog.Append(filename);
    dsDbf.FilePathFull := ExtractFilePath(filename);
    dsDbf.TableName := ExtractFileName(filename);
    dsDbf.Active := True;
    dsDbf.Open;
    for i := 0 to dsDbf.FieldCount - 1 do
    begin
      memoLog.Append('Имя поля:' + dsDbf.Fields[i].FieldName +
        ' размер поля:' + IntToStr(dsDbf.Fields[i].DataSize));
      if dsDbf.Fields[i].DataType = ftString then
        TStringField(dsDbf.Fields[i]).Transliterate := True;
      DBGrid1.Columns[i].FieldName := dsDbf.Fields[i].FieldName;
      DBGrid1.Columns[i].Title.Caption := dsDbf.Fields[i].FieldName;
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

procedure TfrmMain.btnSaveClick(Sender: TObject);
var
  sFile, sTableName, sqlCreateTable: string;
  i: integer;
begin
  SaveDialog1.InitialDir := ExtractFileDir(OpenDialog1.FileName);
  if SaveDialog1.Execute then
  begin
    sFile := SaveDialog1.FileName;
    sTableName := LazFileUtils.ExtractFileNameOnly(filename);
    memoLog.Append(sFile);
    memoLog.Append(sTableName);
    dsSqlite3.Close;
    dsSqlite3.FileName := sFile;
    dsSqlite3.TableName := sTableName;
    if dsSqlite3.TableExists(sTableName) then
    begin
      if MessageDlg('Внимание!', 'Таблица уже существует! Заменить?',
        mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        dsSqlite3.ExecuteDirect('DROP TABLE "' + sTableName + '";');
      end
      else
        Exit;
    end;
    sqlCreateTable := 'CREATE TABLE "' + sTableName + '" (';
    for i := 0 to dsDbf.FieldCount - 1 do
    begin
      sqlCreateTable += '"' + dsDbf.Fields[i].FieldName + '" ';
      case dsDbf.Fields[i].DataType of
        ftString: sqlCreateTable += ' text(' + IntToStr(dsDbf.Fields[i].DataSize) + '),';
        ftInteger: sqlCreateTable += ' integer(' + IntToStr(dsDbf.Fields[i].DataSize) + '),';
        //        ftBoolean: sqlCreateTable += ' Boolean,';
        //        ftMemo: sqlCreateTable += ' blob,';
        ftFloat: sqlCreateTable += ' real,';
      end;
    end;
    Delete(sqlCreateTable, length(sqlCreateTable), 1);
    sqlCreateTable += ');';
    memoLog.Append(sqlCreateTable);
    dsSqlite3.ExecuteDirect(sqlCreateTable);

  end;
end;

function TfrmMain.dsDbfTranslate(Dbf: TDbf; Src, Dest: PChar; ToOem: boolean): integer;
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
  OpenDialog1.Title := 'Выберите файл dbf для чтения';
  OpenDialog1.DefaultExt := '*.dbf;*.DBF';
  OpenDialog1.Filter := 'DBase Table|*.dbf;*.DBF';
  SaveDialog1.Title := 'Выберите файл SQLite для сохранения данных';
  SaveDialog1.DefaultExt := '*.db;*.sqlite;*.sqlite3';
  SaveDialog1.Filter := 'SQLite database|*.db;*.sqlite;*.sqlite3';

  memoLog.Clear;
  //  dsDbf.Create(nil);

end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  dsDbf.Free;
end;

end.

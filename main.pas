unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, DB, sqlite3conn, sqldblib, sqldb, FileUtil,
  Forms, Controls, Graphics, Dialogs, StdCtrls, DBGrids, Menus, lconvencoding,
  LazFileUtils;

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
    SQLDBLibraryLoader1: TSQLDBLibraryLoader;
    SQLite3Connection1: TSQLite3Connection;
    SQLTransaction1: TSQLTransaction;
    procedure btnExitClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    function dsDbfTranslate(Dbf: TDbf; Src, Dest: PChar; ToOem: boolean): integer;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmMain: TfrmMain;
  curDir, filename, passdatabase: string;

implementation

{$R *.lfm}

function IsTableEnabled(tableName: string): boolean;
var
  qryTemp: TSQLQuery;
begin
  qryTemp := TSQLQuery.Create(nil);
  with qryTemp do
  begin
    DataBase := frmMain.SQLite3Connection1;
    SQL.Text := 'select name from sqlite_master where type=' + QuotedStr(
      'table') + ' and name=' + QuotedStr(tableName);
    Open;
    if Fields.FieldByNumber(1).AsString <> '' then
      IsTableEnabled := True
    else
      IsTableEnabled := False;
  end;
  qryTemp.Free;
end;

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
  sFile, sTableName, sqlCreateTable, sqlInsert, sqlTmpInsert: string;
  i, j: integer;
begin
  SaveDialog1.InitialDir := ExtractFileDir(OpenDialog1.FileName);
  if SaveDialog1.Execute then
  begin
    sFile := SaveDialog1.FileName;
    sTableName := LazFileUtils.ExtractFileNameOnly(filename);
    memoLog.Append(sFile);
    memoLog.Append(sTableName);
    SQLite3Connection1.Connected := False;
    SQLite3Connection1.DatabaseName := sFile;
    try  // пробуем подключится к базе
      SQLIte3Connection1.Open;
      SQLTransaction1.Active := True;
      SQLIte3Connection1.Connected := True;
    except   // если не удалось то выводим сообщение о ошибке
      ShowMessage('Ошибка подключения к базе!');
    end;
    passdatabase := PasswordBox('Пароль базы данных',
      'Для входа введите Ваш текущий пароль:');
    SQLIte3Connection1.ExecuteDirect('PRAGMA key=' + QuotedStr(passdatabase) + ';');

    if IsTableEnabled(sTableName) then
    begin
      if MessageDlg('Внимание!', 'Таблица уже существует! Заменить?',
        mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        SQLite3Connection1.ExecuteDirect('DROP TABLE "' + sTableName + '";');
      end
      else
        Exit;
    end;
    sqlCreateTable := 'CREATE TABLE "' + sTableName + '" (';
    sqlInsert := 'INSERT INTO "' + sTableName + '" (';
    for i := 0 to dsDbf.FieldCount - 1 do
    begin
      sqlCreateTable += '"' + dsDbf.Fields[i].FieldName + '" ';
      sqlInsert += dsDbf.Fields[i].FieldName + ',';
      case dsDbf.Fields[i].DataType of
        ftInteger: sqlCreateTable +=
            ' integer(' + IntToStr(dsDbf.Fields[i].DataSize) + '),';
        ftString: sqlCreateTable +=
            ' varchar(' + IntToStr(dsDbf.Fields[i].DataSize * 2) + '),';
        //        ftBoolean: sqlCreateTable += ' Bool,';
        //        ftMemo: sqlCreateTable += ' blob,';
        {AutoInc
        String
        Memo
        Word
        DateTime
        Date
        Time
        LargeInt
        Currency
        }
        // ftFloat: sqlCreateTable += ' real,';
      end;
    end;
    Delete(sqlCreateTable, length(sqlCreateTable), 1);
    sqlCreateTable += ');';
    Delete(sqlInsert, length(sqlInsert), 1);
    sqlInsert += ') VALUES (';
    memoLog.Append(sqlCreateTable);
    SQLite3Connection1.ExecuteDirect(sqlCreateTable);
    dsDbf.First;
    SQLite3Connection1.ExecuteDirect('Begin Transaction');
    for j := 0 to dsDbf.RecordCount - 1 do
    begin
      sqlTmpInsert := '';
      for i := 0 to dsDbf.FieldCount - 1 do
        // Определяем тип поля
      begin
        if dsDbf.Fields[i].IsNull then
          sqlTmpInsert += 'null,'
        else
        begin
          case dsDbf.Fields[i].DataType of
            // число
            ftInteger: sqlTmpInsert += IntToStr(dsDbf.Fields[i].Value) + ',';
            // строка
            ftString: sqlTmpInsert += QuotedStr(dsDbf.Fields[i].Value) + ',';
            else
              ShowMessage('тип не определен');
          end;
        end;
      end;
      Delete(sqlTmpInsert, Length(sqlTmpInsert), 1);
      memoLog.Append(sqlInsert + sqlTmpInsert + ');');
      SQLite3Connection1.ExecuteDirect(sqlInsert + sqlTmpInsert + ');');
      dsDbf.Next;
    end;
    SQLite3Connection1.ExecuteDirect('End Transaction');
    SQLite3Connection1.ExecuteDirect('Commit');
    SQLite3Connection1.ExecuteDirect('Vacuum');
    SQLite3Connection1.Connected := False;
    SQLite3Connection1.CloseTransactions;
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

procedure TfrmMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  dsDbf.Free;
  SQLite3Connection1.CloseTransactions;
  SQLite3Connection1.Connected := False;
  SQLite3Connection1.Close(True);
  FreeAndNil(SQLTransaction1);
  FreeAndNil(SQLite3Connection1);
  SQLDBLibraryLoader1.UnloadLibrary;
  SQLDBLibraryLoader1.Enabled := False;
  FreeAndNil(SQLDBLibraryLoader1);
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
  // Определяем текущую папку исполняемого файла
  CurDir := ExtractFilePath(Application.ExeName);
  // Загружаем библиотеку для работы с БД
  {$IFDEF WINDOWS}
    {$IFDEF WIN32}
  SQLDBLibraryLoader1.LibraryName :=
    CurDir + 'sqlite3.dll';
    {$endif}
    {$IFDEF WIN64}
  SQLDBLibraryLoader1.LibraryName :=
    CurDir + 'sqlite3_x64.dll';
    {$endif}
  {$else}
  SQLDBLibraryLoader1.LibraryName :=
    CurDir + 'libsqlite3.so';
  {$endif}
  SQLDBLibraryLoader1.ConnectionType := 'SQLite3';
  SQLDBLibraryLoader1.LoadLibrary;
  SQLDBLibraryLoader1.Enabled := True;
  // указываем рабочую кодировку
  SQLite3Connection1.CharSet := 'UTF-8';
  SQLite3Connection1.Transaction := SQLTransaction1;
  SQLTransaction1.DataBase := SQLite3Connection1;
  memoLog.Clear;
  //  dsDbf.Create(nil);
end;

end.

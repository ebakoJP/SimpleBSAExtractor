{

SimpleBSAExtractor.dpr (SimpleBSAExtractor.exe)
----
---

The MIT License (MIT)

Copyright (c) 2017 Tadaaki OKABE

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

---
}
program SimpleBSAExtractor;

{$APPTYPE CONSOLE}

{$R *}

{ ============================================================================ }
uses
{
	System.SysUtils:
		CharInSet, StrToInt, FindCmdLineSwitch, ExpandFileName, ExtractFileName,
		FileExists, DirectoryExists, ExcludeTrailingPathDelimiter,
		ExtractFilePath, ExtractFileExt
	System.IOUtils:
		TPath
	System.Classes:
		TStringList
	Utils.pas, Utils_Streams: from QuickBSAExtractor Source
		getStringfromArchive,
		freeStreamArchive, createArchiveStream, getListfromArchive
}
	System.SysUtils, System.IOUtils, System.Classes, Windows,
	Utils_bsa, Utils_Streams;

{ ============================================================================ }
type
	rParamData = record
		fSrc: string; { 入力BSAファイル }
		fDest: string; { 出力フォルダ }
		fList: string; { リストファイル }
end;

type
	rFileData = record
		fPath: string;
		fName: string;
		fExt: string; { 拡張子 }
end;

{ ============================================================================ }
const 
	scSwichChar = ['/']; { コマンドラインオプションの区切文字 }
	scCmdOptChar = ['s', 'd', 'l' ,'h' ,'?' ]; { コマンドラインオプション }

var
	CmdLineParam: rParamData; { コマンドラインオプションの各引数 }
	flagCreateDestinationFolder: Boolean; { 出力フォルダ作成フラグ }

	slExtractFileList: TStringList; { 抽出ファイルリスト }
	slInvalidFilenameList: TStringList; { 不正形式ファイル名リスト }
	slSkipFileList: TStringList; { 存在しないファイルリスト }

	tdtStartTime: TDateTime; { 実行開始日時 }
	strCurrentFolder: string; { 実行時ディレクトリ }

	i: Integer; { ループカウンタ }
	slTempList: TStringList; { 作業用のTStringList }

{ ============================================================================ }

{ ============================================================================ }
{ Below functions from QuickBSAExtractor source code.
	Original code:
		function parseFileNameData(filename: string): rFileData;
	Modify by EBAKO at 2017/03/20
}
function sbeParseFileNameData(const aValue: string): rFileData;
begin
	Result.fPath := ExcludeTrailingPathDelimiter(ExtractFilePath(aValue));
	Result.fName := ChangeFileExt(ExtractFileName(aValue), '');
	Result.fExt := ExtractFileExt(aValue);
end;

{ Below procedure from QuickBSAExtractor source code.
	Original code:
		procedure ExtractFile(filetoload, extractDir: string);
	Modify by EBAKO at 2017/03/20
}
procedure sbeExtractFile(const aBSAFile, aTargetName, aExtractDir: string);
var
	twbStream: TwbBaseCachedFileStream;
	bsaStream: TObject;
	buffer: TBytes;
	fData: rFileData;
	extDir: string;
begin
	twbStream := nil;
	bsaStream := nil;
	fData := sbeParseFileNameData(aTargetName);
	buffer := nil;

	try
		freeStreamArchive(bsaStream);
		createArchiveStream(bsaStream, aBSAFile);

		if not getStringfromArchive(bsaStream, buffer, aBSAFile, fData.fPath, fData.fName, fData.fExt, true) or (Length(buffer) = 0) then
			exit;
		extDir := IncludeTrailingPathDelimiter(aExtractDir) + fData.fPath;
		ForceDirectories(extDir);
		try
			twbStream := TwbWriteCachedFileStream.Create(IncludeTrailingPathDelimiter(extDir) + fData.fName + fData.fExt);
			twbStream.WriteBuffer(buffer[0], Length(buffer));
		finally
			twbStream.free;
			buffer := nil;
		end;
	finally
		freeStreamArchive(bsaStream);
	end;
end;

{ end of From QuickBSAExtractor source code }
{ ============================================================================ }

{------------------------------------------------------------------------------}
function sbeSearchFileArchive(const aBSAFile, aTargetName: string): Boolean;
{
	BSAファイルに指定ファイルが含まれているかチェックする

	aBSAFile: string : 対象BSAファイル名
	aTargetName: string : 対象ファイル名（パス込）
}
var
	bsaStream: TObject;
	buffer: TBytes;
	fData: rFileData;
begin
	bsaStream := nil;
	fData := sbeParseFileNameData(aTargetName);
	buffer := nil;

	try
		freeStreamArchive(bsaStream);
		createArchiveStream(bsaStream, aBSAFile);
		Result := getStringfromArchive(bsaStream, buffer, aBSAFile, fData.fPath, fData.fName, fData.fExt, false);
	finally
		freeStreamArchive(bsaStream);
		buffer := nil;
	end;
end;

procedure sbeGetListFromArchive(const aBSAFile: string; out aFileList: TStringList);
{
	BSAファイルに含まれるファイルのリストを取得する

	aBSAFile: string : 対象BSAファイル名
	aFileList: TStringList : 含まれるファイルのリスト（を代入する）
}
var
	bsaStream: TObject;
begin
	bsaStream := nil;
	try
		freeStreamArchive(bsaStream);
		createArchiveStream(bsaStream, aBSAFile);
		getListfromArchive(bsaStream, aBSAFile, aFileList, true, [''], ['']);
	finally
		freeStreamArchive(bsaStream);
	end;
end;

function sbeCheckFileTypeIsTextfile(const aFilename: string): Boolean;
{
	指定ファイルがテキストファイルであるか簡易判定する

	aFilename: string : チェック対象のファイル名
}
var
	fsFile: TFileStream; { ファイルストリーム } 
	brTestStream: TBinaryReader; { バイナリストリーム }
	buffer: TBytes; { チェック用に読み出して保存するためのバッファ(バイト配列) }
	nonASCIICount, i: Integer; { nonASCIICount: 非ASCII文字の数、i: ループカウンタ }
begin
	Result := False;
	buffer := nil;
	nonASCIICount := 0;
	i := 0;

	try
		{ 読み取り専用でファイルをバイナリとして開く。エンコード指定はしない }
		fsFile := TFileStream.Create(aFilename, fmOpenRead);
		brTestStream := TBinaryReader.Create(fsFile, nil);

		{ 先頭から 1024 byte 取り出す }
		buffer := brTestStream.ReadBytes(1024);
		brTestStream.Close;
	finally
		brTestStream.Free;
		fsFile.Free;
	end;

	{ BOM チェック }
	if (buffer[0] = $EF) and (buffer[1] = $BB) and (buffer[2] = $BF) then
		i := 2;

	{ 先頭1024 byte 中の英数字、記号、タブ、改行以外の数を調べる（BOMは除く） }
	while i < Length(buffer) do
		case buffer[i] of
			$09, $0A, $0d, $20..$7E: Inc(i);
		else
			begin
				Inc(nonASCIICount);
				Inc(i);
			end;
		end;

	buffer := nil;

	{ 先頭 1024 byte 中に英数字、記号、タブ、改行以外が含まれていたかチェック }
	if nonASCIICount = 0 then
		Result := True;
end;
{------------------------------------------------------------------------------}

{ ============================================================================ }
{ Below function code from
		http://mrxray.on.coocan.jp/Delphi/plSamples/318_AppVersionInfo.htm
		('05_GetFileVersionInfo' sample code)
	(use Unit Windows and $R (Complier option))
}
function sbeGetFileVersionString(const aFilename: string): String;
var
	dwHandle  : Cardinal;
	pInfo     : Pointer;
	InfoSize  : DWORD;
	pFileInfo : PVSFixedFileInfo;
	iVer      : array[0..3] of Cardinal;
begin
	Result := '';

	InfoSize := GetFileVersionInfoSize(PChar(aFilename), dwHandle);
	if InfoSize = 0 then Exit;

	GetMem(pInfo, InfoSize);
	try
		GetFileVersionInfo(PChar(aFilename), 0, InfoSize, pInfo);
		VerQueryValue(pInfo, PathDelim, Pointer(pFileInfo), InfoSize);

		iVer[0] := pFileInfo.dwFileVersionMS shr 16; { Major }
		iVer[1] := pFileInfo.dwFileVersionMS and $FFFF; { Minor }
		iVer[2] := pFileInfo.dwFileVersionLS shr 16; { Release }
		Result := Format('%d.%d.%d', [iVer[0], iVer[1], iVer[2]]);
		{ iVer[3] := pFileInfo.dwFileVersionLS and $FFFF; } { Build }
		{ Result := Format('%d.%d.%d.%d', [iVer[0], iVer[1], iVer[2], iVer[3]]); }
	finally
		FreeMem(pInfo, InfoSize);
	end;
end;

{ end of function code from http://mrxray.on.coocan.jp/Delphi/plSamples/... }
{ ============================================================================ }

{ ============================================================================ }
procedure sbeReportProgress(const aStatus: string);
{
	aStatus: string (const) : 表示文字列
}
begin
	{ “<指定時刻からの経過時間>: 表示文字列” を標準エラー出力へ出力 }
	WriteLn(ErrOutput, FormatDateTime('<hh:nn:ss.zzz>', Now - tdtStartTime), ': ', aStatus);
end;
{ ============================================================================ }

{------------------------------------------------------------------------------}
procedure sbeReportError(const aStatus: string);
{
	[Error] 付きで標準エラーに文字列を出力する
	
	aStatus: string (const) : 表示文字列
}
begin
	WriteLn(ErrOutput, '[Error]: ', aStatus);
end;
{------------------------------------------------------------------------------}

{ ============================================================================ }
function sbeFindCmdLineParam(const aSwitch: string; out aValue: string): Boolean;
{
	値付き引数オプションの値を取り出す

	aSwitch: string (const) : 引数オプション
	aValue: string (out) <= 引数オプションに渡された内容（を代入）
}
var
	i : Integer; { ループカウンタ }
	s : string; { 作業用文字列変数 }
begin
	Result := False;
	aValue := '';
	for i := 1 to ParamCount do begin
		s := ParamStr(i);
		if CharInSet(s[1], scSwichChar) then { 引数の1文字目が scSwichChar であるとき }
			if (AnsiCompareText(Copy(s, 2, Length(aSwitch)), aSwitch) = 0)
			 and (Length(s) = (Length(aSwitch) + 1)) then
				{ 引数の2文字目から aSwitch の長さ分の文字と aSwitch が同じ かつ
					引数全体の長さが、aSwitch の長さ+1 と等しい（オプション区切文字を含んだ長さと等しい） }
				if ParamCount < (i + 1) then begin
					Result := False;
					Exit;
				end else begin
					s := ParamStr(i + 1); { s: 次の引数を取り出す }
					if not CharInSet(s[1], scSwichChar) then begin { 引数の1文字目が scSwichChar でないとき }
						aValue := s; { 引数を aValue に代入する }
						Result := True;
						Exit;
					end;
				end;
	end;
end;
{ ============================================================================ }

{------------------------------------------------------------------------------}
function sbeFindCmdLineSwitch(const aSwitch: string): Boolean;
{
	FindCmdLineSwitchのラッパー関数（引数区切文字と大文字小文字区別を固定指定）

	aSwitch: string (const) : 引数オプション
}
begin
	Result := FindCmdLineSwitch(aSwitch, scSwichChar, False);
end;


function sbeGetArgsParam(out rArgs: rParamData): Boolean;
{
	rArgs: rParamData : 引数パラメータで指定されている各値（を代入）
}
var
	flagNeedsSyntaxInfo: Boolean; { USAGEを表示するか否かのフラグ }
	i : Integer; { ループカウンタ }
	s : string; { 作業用文字列変数 }
begin
	flagNeedsSyntaxInfo := False;

	{ オプション文字のチェック }
	for i := 1 to ParamCount do begin
		s := ParamStr(i);
		if CharInSet(s[1], scSwichChar) and (not CharInSet(s[2], scCmdOptChar)) then begin
			{ 想定以外のオプション文字が指定されていたら USAGE 表示へ }
			flagNeedsSyntaxInfo := True;
			sbeReportError('"' + s + '" is illegal option character. Please check the command line parameters.');
			break;
		end;
	end;

	{ ヘルプオプションの場合 (#09 = tab space) }
	if (not flagNeedsSyntaxInfo) and (sbeFindCmdLineSwitch('?') or sbeFindCmdLineSwitch('h')) then begin
		WriteLn(ErrOutput);
		WriteLn(ErrOutput, 'USAGE: (Ver:', sbeGetFileVersionString(ParamStr(0)), ')');
		WriteLn(ErrOutput, '  SimpleBSAExtractor /s filename');
		WriteLn(ErrOutput, '  SimpleBSAExtractor /s filename /d folder');
		WriteLn(ErrOutput, '  SimpleBSAExtractor /s filename /d folder /l filename');
		WriteLn(ErrOutput, '  SimpleBSAExtractor /h or SimpleBSAExtractor /?');
		WriteLn(ErrOutput, 'OPTIONS:');
		WriteLn(ErrOutput, '  /s', #09, ': Set source BSA(.bsa/.ba2) File. The extention must be ".bsa/.ba2".');
		WriteLn(ErrOutput, '  /d', #09, ': Set destination folder(directory).');
		WriteLn(ErrOutput, #09, ': Not exist _destination_ folder(directory), then create _destination_ folder(directory).');
		WriteLn(ErrOutput, '  /l', #09, ': Set list file. This option must set "/d".');
		WriteLn(ErrOutput, #09, ': List file format is one line by one extract file.');
		WriteLn(ErrOutput, #09, ': And file type is "TEXT" (with all ascii character).');
		WriteLn(ErrOutput, '  /h', #09, ': Show help (this text) and ignore other options.');
		WriteLn(ErrOutput, '  /?', #09, ': Show help (this text) and ignore other options.');
		WriteLn(ErrOutput, 'INFORMATION:');
		WriteLn(ErrOutput, ' It omit "/d" and "/i" options.');
		WriteLn(ErrOutput, ' If both option is omitted, print out all files in source BSA file.');
		Result := False;
		Exit;
	end;

	{ 引数オプションの組合せと値の存在チェック }
	if sbeFindCmdLineSwitch('s') then begin
		if sbeFindCmdLineParam('s', rArgs.fSrc) then begin
			if rArgs.fSrc = '' then begin
				sbeReportError('No source file was specified. Please check the command line parameters.');
				flagNeedsSyntaxInfo := True;
			end
		end else begin
				sbeReportError('No source file was specified. Please check the command line parameters.');
				flagNeedsSyntaxInfo := True;
		end;

		if (not flagNeedsSyntaxInfo) and sbeFindCmdLineSwitch('d') then begin
			if sbeFindCmdLineParam('d', rArgs.fDest) then begin
				if rArgs.fDest = '' then begin
					sbeReportError('No destination folder was specified. Please check the command line parameters.');
					flagNeedsSyntaxInfo := True;
				end
			end else begin
				sbeReportError('No destination folder was specified. Please check the command line parameters.');
				flagNeedsSyntaxInfo := True;
			end;
		end;

		if (not flagNeedsSyntaxInfo) and sbeFindCmdLineSwitch('l') then begin
			if sbeFindCmdLineSwitch('d') then begin
				if sbeFindCmdLineParam('l', rArgs.fList) then begin
					if rArgs.fList = '' then begin
						sbeReportError('No list file was specified. Please check the command line parameters.');
						flagNeedsSyntaxInfo := True;
					end
				end else begin
					sbeReportError('No list file was specified. Please check the command line parameters.');
					flagNeedsSyntaxInfo := True;
				end
			end else begin
				sbeReportError('No "/d" option was found. Please check the command line parameters.');
				flagNeedsSyntaxInfo := True;
			end
		end;
	end else
		if ParamCount >0 then begin
			sbeReportError('No "/s" option was found. Please check the command line parameters.');
			flagNeedsSyntaxInfo := True;
		end;

	{ 引数エラーの場合 }
	if flagNeedsSyntaxInfo or (ParamCount < 1) then begin
		{ USAGEの出力 }
		WriteLn(ErrOutput);
		WriteLn(ErrOutput, 'USAGE: (Ver:', sbeGetFileVersionString(ParamStr(0)), ')');
		WriteLn(ErrOutput, '  SimpleBSAExtractor /s <filename> [/d <folder> [/l <filename>]] [/h] [/?]');
		Result := False;
		Exit;
	end else begin
		Result := True;
		Exit;
	end;
end;

function sbeCheckFilePath(const rPath: rParamData): Boolean;
{
	引数パラメータで指定されたパス（ファイル）の形式と存在チェック

	rPath: rParamData : 引数パラメータで指定されたパス文字列
}
var
	s : string; { 作業用文字列変数 }
begin
	Result := True;

	try
		{ 入力ファイル名のチェックと存在確認 }
		s := ExpandFileName(rPath.fSrc);
		{ ファイル名書式チェック }
		if not TPath.HasValidFileNameChars(ExtractFileName(s), False) then begin
			{ ファイル名書式エラー }
			sbeReportError('The file name foramt of "' + rPath.fSrc + '" is invalid. Please check file name.');
			Result := False;
			Exit;
		end;

		{ 拡張子をチェック（.ba2、.bsa以外は受け付けない） }
		if not ((AnsiLowerCase(ExtractFileExt(s)) = '.bsa')
			 or (AnsiLowerCase(ExtractFileExt(s)) = '.ba2')) then begin
			{ 拡張子が.ba2、.bsa以外である }
			sbeReportError('The Extension of "' + rPath.fSrc + '" is not ".ba2/.bsa". Please check file name.');
			Result := False;
			Exit;
		end;
		if not FileExists(s) then begin
			{ 指定された入力ファイルが存在しない }
			sbeReportError('"' + rPath.fSrc + '" does not exist. Please check file nmae.');
			Result := False;
			Exit;
		end;

		{ 出力フォルダ名が指定されている場合 }
		if rPath.fDest <> '' then begin
			s := ExpandFileName(rPath.fDest);
			{ フォルダ名書式チェック }
			if not TPath.HasValidPathChars(s, False) then begin
				{ フォルダ名書式エラー }
				sbeReportError('The path name foramt of "' + rPath.fDest + '" is invalid. Please check path name.');
				Result := False;
				Exit;
			end;
			{ 出力フォルダ作成フラグセット （存在しない場合: True） }
			flagCreateDestinationFolder := not DirectoryExists(s);

			{ リストファイルが指定されている場合 }
			if rPath.fList <> '' then begin
				s := ExpandFileName(rPath.fList);
				{ ファイル名書式チェック }
				if not TPath.HasValidFileNameChars(ExtractFileName(s), False) then begin
					{ ファイル名書式エラー }
					sbeReportError('The file name foramt of "' + rPath.fList + '" is invalid. Please check file name.');
					Result := False;
					Exit;
				end;
				if not FileExists(s) then begin
					{ 指定されたリストファイルが存在しない }
					sbeReportError('"' + rPath.fList + '" does not exist. Please check file name.');
					Result := False;
					Exit;
				end;
			end;
		end;
	{ 例外処理 }
	except
		on E: Exception do
			sbeReportError('Unexpected Error: <' + E.ClassName + ': ' + E.Message + '>');
	end;
end;
{------------------------------------------------------------------------------}

{ ============================================================================ }
begin

	try
		{ 実行ファイルのフォルダ取得 }
		strCurrentFolder := ExpandFileName(ParamStr(0));

		{ 引数チェックと引数のファイル名、パス名の取得 }
		if not sbeGetArgsParam(CmdLineParam) then
			{ 引数エラーかヘルプ表示ならプログラム終了 }
			Exit;

		{ 引数で渡されたファイル名、パス名の書式チェックと存在確認 }
		if not sbeCheckFilePath(CmdLineParam) then
			{ パスエラーがあればプログラム終了 }
			Exit;

		{ ファイル操作の開始 }
		tdtStartTime := Now;
		sbeReportProgress('<---------------------- Process Start --------------------->');

		{ 抽出ファイルリストを初期化 }
		slExtractFileList := TStringList.Create;

		if CmdLineParam.fList <> '' then begin
			{ リストファイル名が指定されている場合、リストファイル名を絶対パス付きに入れ替える }
			CmdLineParam.fList := ExpandFileName(CmdLineParam.fList);
			sbeReportProgress('Read and check list file: ' + ExtractFileName(CmdLineParam.fList));
			sbeReportProgress('');

			{ リストファイルがテキストファイルかチェックする }
			if not sbeCheckFileTypeIsTextfile(CmdLineParam.fList) then begin
				{ テキストファイルでなければプログラム終了 }
				sbeReportProgress('<---------------------- Process Abort ----------------------->');
				WriteLn(ErrOutput);
				sbeReportError('The file type of "' + ExtractFileName(CmdLineParam.fList) + '" is not "TEXT". Please check file.');
				Exit;
			end;

			{ 不正形式リストと作業用リストを初期化 }
			slInvalidFilenameList := TStringList.Create;
			slTempList := TStringList.Create;

			try
				slTempList.LoadFromFile(CmdLineParam.fList);
				for i := 0 to slTempList.Count - 1 do
					{ パス名書式とファイル名書式の同時チェック }
					if TPath.HasValidPathChars(slTempList[i], False) and
						TPath.HasValidFileNameChars(ExtractFileName(slTempList[i]), False) then
						{ 問題なし: 抽出ファイルリストに追加 }
						slExtractFileList.Add(slTempList[i])
					else
						{ 問題あり: 不正形式リストに追加 }
						slInvalidFilenameList.Add(slTempList[i]);

				{ リストファイルの検査結果と不正形式ファイル名を表示 }
				sbeReportProgress('Valid file name/Invalid file name : ' + IntToStr(slExtractFileList.Count)
					 + '/' + IntToStr(slInvalidFilenameList.Count));
				if slInvalidFilenameList.Count > 0 then begin
						sbeReportProgress('Invalid file name:');
					for i := 0 to slInvalidFilenameList.Count - 1 do
						sbeReportProgress(#09 + slInvalidFilenameList[i]);
				end;
				sbeReportProgress('<---------------------------------------------------------->');

			finally
				{ リストオブジェクトの解放 }
				FreeAndNil(slTempList);
				FreeAndNil(slInvalidFilenameList);
			end;
		end;

		{ 入力ファイルの読み込み }
		{ 入力ファイル名を絶対パスに入れ替える }
		CmdLineParam.fSrc := ExpandFileName(CmdLineParam.fSrc);
		sbeReportProgress('Read and check source file: ' + ExtractFileName(CmdLineParam.fSrc));

		{ 除外ファイルリストを初期化 }
		slSkipFileList := TStringList.Create;

		if slExtractFileList.Count > 0 then begin
			{ 抽出ファイルリストにリストファイルの内容が入っている場合 }
			{ 抽出ファイルリストに記載されたファイルがBSAファイル内に存在するかチェック }
			try
				slTempList := TStringList.Create;
				for i := 0 to slExtractFileList.Count -1 do
					if sbeSearchFileArchive(CmdLineParam.fSrc, slExtractFileList[i]) then
						{ 入力ファイルに要素が存在するものは作業用リストへ追加 }
						slTempList.Add(slExtractFileList[i])
					else
						{ 入力ファイルに要素が存在しないものは除外ファイルリストへ追加 }
						slSkipFileList.Add(slExtractFileList[i]);

				{ 抽出ファイルリストを作業用リストの中身に置き換える }
				{ すべて除外ファイルリストに追加されていた場合、抽出ファイルリストは空になる }
				FreeAndNil(slExtractFileList);
				slExtractFileList := TStringList.Create;
				if slTempList.Count > 0 then
					for i := 0 to slTempList.Count -1 do
						slExtractFileList.Add(slTempList[i]);
			finally
				{ 作業用リストオブジェクトの解放 }
				FreeAndNil(slTempList);
			end;
		end else begin
			{ 入力ファイルに含まれる全ファイルを抽出ファイルリストに追加 }
			sbeGetListFromArchive(CmdLineParam.fSrc, slExtractFileList);
		end;

		sbeReportProgress('<---------------------------------------------------------->');

		{ 抽出ファイルリストが空の場合、抽出に関する処理は実行しない }
		if slExtractFileList.Count > 0 then begin
			if CmdLineParam.fDest = '' then begin
				{ 出力フォルダ指定がない場合、BSAファイルの中身の一覧を標準出力へ出力する }
				sbeReportProgress('Print all contain files in source file: ' + ExtractFileName(CmdLineParam.fSrc));
				sbeReportProgress('<----------------- Below lines to STDOUT ------------------>');
				{ 抽出ファイルリスト(=BSAファイルに含まれるファイルの一覧) }
				for i := 0 to slExtractFileList.Count - 1 do
					WriteLn(Output, slExtractFileList[i]);
				sbeReportProgress('<----------------- Above lines to STDOUT ------------------>');
			end else begin
				{ 出力フォルダ名を絶対パスに入れ替える }
				CmdLineParam.fDest := ExpandFileName(CmdLineParam.fDest);
				{ フォルダ作成フラグをチェック }
				if flagCreateDestinationFolder then begin
					sbeReportProgress('Create destination folder: ' + CmdLineParam.fDest);
					ForceDirectories(CmdLineParam.fDest);
					sbeReportProgress('<---------------------------------------------------------->');
				end;

				{ BSAファイルから抽出ファイルリスト記載のファイルを出力フォルダへ抽出する }
				sbeReportProgress('Extract to destination folder: ' + CmdLineParam.fDest);
				sbeReportProgress('Extract file:');
				for i := 0 to slExtractFileList.Count - 1 do begin
					sbeExtractFile(CmdLineParam.fSrc, slExtractFileList[i], CmdLineParam.fDest);
					sbeReportProgress(#09 + slExtractFileList[i]);
				end;
			end;
		end;
		{ ファイル操作終了 }

		{ 抽出結果とBSAファイルに存在しなかったファイルの表示 }
		sbeReportProgress('<------------------------ Summary ------------------------->');
		sbeReportProgress('Source file        : ' + CmdLineParam.fSrc);

		if CmdLineParam.fDest <> '' then
			sbeReportProgress('Destination folder : ' + CmdLineParam.fDest);
		if CmdLineParam.fList <> '' then
			sbeReportProgress('List file          : ' + CmdLineParam.fList);

		sbeReportProgress('');
		sbeReportProgress('Extract files/Skip files : ' + IntToStr(slExtractFileList.Count) + '/' + IntToStr(slSkipFileList.Count));
		if slSkipFileList.Count > 0 then begin
			sbeReportProgress('Skip file:');
			for i := 0 to slSkipFileList.Count - 1 do
				sbeReportProgress(#09 + slSkipFileList[i]);
		end;
		sbeReportProgress('<---------------------- Process End ----------------------->');

		{ リストオブジェクトの解放 }
		FreeAndNil(slExtractFileList);
		FreeAndNil(slSkipFileList);

	{ 例外処理 }
	except
		on E: Exception do begin
			WriteLn(ErrOutput);
			sbeReportError('Unexpected Error: <' + E.ClassName + ': ' + E.Message + '>');
		end;
	end;
{ ============================================================================ }

end.

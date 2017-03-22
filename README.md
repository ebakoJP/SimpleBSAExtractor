SimpleBSAExtractor
==================

コマンドラインで Bethesda Softworks Archive (BSA/BA2)ファイルを展開するツール  

## Description

BSA/BA2ファイルに対する以下の操作をコマンドラインから実施可能です。  

* BSAファイルに含まれるファイル一覧を出力  
* BSAファイルの展開  
* BSAファイルから指定したファイル（複数化）を展開  

コマンドラインツールのため、バッチファイル（.bat, .ps1(Powershell)）に組み込むことができる。  
あるいは、他のツールから外部コマンドとして指定することもできる。
（バッチファイルの例はDemo参照）

## Support Archive Format

TES5Edit がサポートしている以下のBSAファイル  

* BSA (Oblivion, Skyrim, Skyrim Special Edition)  
* BA2 (Fallout4)  

なお、作者は Skyrim, Skyrim Special Edition しか所有していないため、
BA2(Fallout4)、BSA(Oblivion)で期待どおり動作するか不明です。  

## Requirement

* BSAファイル  
   
* リストファイル作成・編集用にテキストエディタ（Notepad++ など文字コードを判別できるもの）  
* コマンドプロンプトで操作するための知識  

## Usage

* BSAファイルに含まれるファイルの一覧を表示する:  
    （一覧を保存したい場合は、"> hoge.txt" で標準出力をリダイレクトするだけでよい）
    ``` SimpleBSAExtractor /s <filename> ```  
   
* BSAファイルに含まれるすべてのファイルを指定フォルダに展開する:  
    ``` SimpleBSAExtractor /s <filename> /d <folder> ```  
   
* BSAファイルに含まれるファイルのうち、リストファイルに記載したファイルを指定フォルダに展開する:  
    （リストファイルは『一行一ファイル』のテキストファイル(ASCII or UTF8)を用意する。）
    ``` SimpleBSAExtractor /s <filename> /d <folder> /l <filename> ```  
   
* HELP メッセージの表示:
   
    ``` SimpleBSAExtractor /h ``` or ``` SimpleBSAExtractor /? ```  
   
## Install

[Releases](https://github.com/ebakoJP/SimpleBSAExtractor/master/Releases/) から最新リリースをダウンロードして任意の場所で展開してください。  
あるいは [Nexus mod]() からダウンロードしてください。  

## Special Thanks  

- **QuickBSAExtractor**: ソースコードが公開されていなかったら、このツールを作り出せていない。
- **Embarcadero RAD Studio Delphi Delphi Starter Edition**: これがなかったら、このツールを世に送り出せていない。
- **Bethesda Softworks**: Skyrim Special Edition に出会っていなければ、このツールを作ろうとはしてない。

## Licence

Main Code:  
- SimpleBSAExtractor.dpr(SimpleBSAExtractor.exe: [The MIT License](https://github.com/ebakoJP/SimpleBSAExtractor/master/LICENCE.md))  

Library:  
- Lib/Imazing: Mozilla Public License 1.1 ([Vamprye Imageong Library](http://imaginglib.sourceforge.net/))  
- Lib/lz4: BSD 2-Clause License ([LZ4Delphi](https://github.com/atelierw/LZ4Delphi/))  
- Lib/Zlib: Copyright [base2 technologies](http://www.base2ti.com/).  
- Units.pas,Units_stream.pas: Mozilla Public License 1.1 (from [QuickBSAExtractor](http://www.nexusmods.com/skyrimspecialedition/mods/913/))  

## VS. 
### GUI tool:  

* [QuickBSAExtractor](http://www.nexusmods.com/skyrimspecialedition/mods/913/?)  
* [BSA-Manager](http://www.nexusmods.com/skyrimspecialedition/mods/1756/?)  
* [BSA Browser](http://www.nexusmods.com/fallout4/mods/17061/?)  
* B.A.E. - Bethesda Archive Extractor([Fallout4 tools](http://www.nexusmods.com/fallout4/mods/78/?)
 or [SkyrimSE tools](http://www.nexusmods.com/skyrimspecialedition/mods/974/?))  

### CUI tool:  
 **_Nothing!_**  


## Demo

### Demo1:

BSAファイルに含まれるファイルの一覧をリダイレクトを使用してテキストファイルに保存する。  

実行例:  
```
Z:\Demo>SimpleBSAExtractor.exe /s "D:\SteamLibrary\steamapps\common\Skyrim Special Edition\Data\Skyrim - Patch.bsa" > Skyrim-Patch_bsa-FileList.txt
<00:00:00.000>: <---------------------- Process Start --------------------->
<00:00:00.001>: Read and check source file: Skyrim - Patch.bsa
<00:00:00.016>: <---------------------------------------------------------->
<00:00:00.016>: Print all contain files in source file: Skyrim - Patch.bsa
<00:00:00.016>: <----------------- Below lines to STDOUT ------------------>
<00:00:00.017>: <----------------- Above lines to STDOUT ------------------>
<00:00:00.017>: <------------------------ Summary ------------------------->
<00:00:00.017>: Source file        : D:\SteamLibrary\steamapps\common\Skyrim Special Edition\Data\Skyrim - Patch.bsa
<00:00:00.017>:
<00:00:00.017>: Extract files/Skip files : 333/0
<00:00:00.017>: <---------------------- Process End ----------------------->

Z:\Demo>more Skyrim-Patch_bsa-FileList.txt
interface\bartermenu.swf
interface\bethesdanetlogin.swf
interface\book.swf
interface\bookmenu.swf
interface\console.swf
interface\containermenu.swf

....

strings\update_spanish.dlstrings
strings\update_spanish.ilstrings
strings\update_spanish.strings
textures\effects\projecteddiffuse.dds
textures\effects\projectednormal.dds
textures\effects\projectednormaldetail.dds

Z:\Demo>
```

### Demo2:

複数ファイルに対して、各々に含まれるファイルを抜き出す。  
- 女性用エルフキュイラス装備のテクスチャファイルと nif ファイルを抜き出す。

バッチファイル: DEMO2.bat  
```
echo off

REM SimpleBSAExtractor DEMO
REM
REM Set Variable
set SrcDir=D:\SteamLibrary\steamapps\common\Skyrim\Data\
set SrcMeshes=%SrcDir%Skyrim - Meshes.bsa
set SrcTextures=%SrcDir%Skyrim - Textures.bsa

REM Create Listfile
del demo2.txt
echo meshes\armor\elven\f\cuirass_0.nif>> demo2.txt
echo textures\armor\elven\f\cuirass.dds>> demo2.txt

echo on

SimpleBSAExtractor /s "%SrcMeshes%" /d demo2 /l demo2.txt
SimpleBSAExtractor /s "%SrcTextures%" /d demo2 /l demo2.txt

for /F %%i in ('more .\demo2.txt') do dir /B /S .\demo2\%%i
```

実行結果:  
```
Z:\Demo>DEMO2.bat

Z:\Demo>echo off

Z:\Demo>SimpleBSAExtractor /s "D:\SteamLibrary\steamapps\common\Skyrim\Data\Skyrim - Meshes.bsa" /d demo2 /l demo2.txt
<00:00:00.000>: <---------------------- Process Start --------------------->
<00:00:00.000>: Read and check list file: demo2.txt
<00:00:00.001>:
<00:00:00.001>: Valid file name/Invalid file name : 2/0
<00:00:00.001>: <---------------------------------------------------------->
<00:00:00.001>: Read and check source file: Skyrim - Meshes.bsa
<00:00:00.085>: <---------------------------------------------------------->
<00:00:00.085>: Extract to destination folder: Z:\Demo\demo2
<00:00:00.085>: Extract file:
<00:00:00.133>:         meshes\armor\elven\f\cuirass_0.nif
<00:00:00.133>: <------------------------ Summary ------------------------->
<00:00:00.133>: Source file        : D:\SteamLibrary\steamapps\common\Skyrim\Data\Skyrim - Meshes.bsa
<00:00:00.133>: Destination folder : Z:\Demo\demo2
<00:00:00.133>: List file          : Z:\Demo\demo2.txt
<00:00:00.133>:
<00:00:00.133>: Extract files/Skip files : 1/1
<00:00:00.133>: Skip file:
<00:00:00.133>:         textures\armor\elven\f\cuirass.dds
<00:00:00.133>: <---------------------- Process End ----------------------->

Z:\Demo>SimpleBSAExtractor /s "D:\SteamLibrary\steamapps\common\Skyrim\Data\Skyrim - Textures.bsa" /d demo2 /l demo2.txt
<00:00:00.000>: <---------------------- Process Start --------------------->
<00:00:00.000>: Read and check list file: demo2.txt
<00:00:00.000>:
<00:00:00.000>: Valid file name/Invalid file name : 2/0
<00:00:00.001>: <---------------------------------------------------------->
<00:00:00.001>: Read and check source file: Skyrim - Textures.bsa
<00:00:00.091>: <---------------------------------------------------------->
<00:00:00.091>: Extract to destination folder: Z:\Demo\demo2
<00:00:00.092>: Extract file:
<00:00:00.177>:         textures\armor\elven\f\cuirass.dds
<00:00:00.177>: <------------------------ Summary ------------------------->
<00:00:00.177>: Source file        : D:\SteamLibrary\steamapps\common\Skyrim\Data\Skyrim - Textures.bsa
<00:00:00.177>: Destination folder : Z:\Demo\demo2
<00:00:00.177>: List file          : Z:\Demo\demo2.txt
<00:00:00.177>:
<00:00:00.177>: Extract files/Skip files : 1/1
<00:00:00.177>: Skip file:
<00:00:00.177>:         meshes\armor\elven\f\cuirass_0.nif
<00:00:00.177>: <---------------------- Process End ----------------------->

Z:\Demo>for /F %i in ('more .\demo2.txt') do dir /B /S .\demo2\%i

Z:\Demo>dir /B /S .\demo\meshes\armor\elven\f\cuirass_0.nif
Z:\Demo\demo2\meshes\armor\elven\f\cuirass_0.nif

Z:\Demo>dir /B /S .\demo\textures\armor\elven\f\cuirass.dds
Z:\Demo\demo2\textures\armor\elven\f\cuirass.dds

Z:\Demo>
```

### Demo3:

Skyrim Special Edtion英語版を日本語化するために日本語版のファイルから必要なファイルを抜き出す。

リストファイル: ENtoJPFiles.txt  
```
interface\book.swf
interface\fontconfig.txt
interface\fonts_en.swf
interface\translate_english.txt
strings\dawnguard_english.dlstrings
strings\dawnguard_english.ilstrings
strings\dawnguard_english.strings
strings\dragonborn_english.dlstrings
strings\dragonborn_english.ilstrings
strings\dragonborn_english.strings
strings\hearthfires_english.dlstrings
strings\hearthfires_english.ilstrings
strings\hearthfires_english.strings
strings\skyrim_english.dlstrings
strings\skyrim_english.ilstrings
strings\skyrim_english.strings
strings\update_english.dlstrings
strings\update_english.ilstrings
strings\update_english.strings
```

実行結果:  
```
Z:\Demo>SimpleBSAExtractor.exe /s "D:\SteamLibrary\steamapps\common\Skyrim Special Edition\Data\Skyrim - Patch.bsa" /d demo3 /l ENtoJPFiles.txt
<00:00:00.000>: <---------------------- Process Start --------------------->
<00:00:00.000>: Read and check list file: ENtoJPFiles.txt
<00:00:00.000>:
<00:00:00.001>: Valid file name/Invalid file name : 19/0
<00:00:00.002>: <---------------------------------------------------------->
<00:00:00.002>: Read and check source file: Skyrim - Patch.bsa
<00:00:00.048>: <---------------------------------------------------------->
<00:00:00.048>: Create destination folder: Z:\Demo\demo3
<00:00:00.070>: <---------------------------------------------------------->
<00:00:00.070>: Extract to destination folder: Z:\Demo\demo3
<00:00:00.070>: Extract file:
<00:00:00.084>:         interface\book.swf
<00:00:00.094>:         interface\fontconfig.txt
<00:00:00.177>:         interface\fonts_en.swf
<00:00:00.181>:         interface\translate_english.txt
<00:00:00.199>:         strings\dawnguard_english.dlstrings
<00:00:00.205>:         strings\dawnguard_english.ilstrings
<00:00:00.208>:         strings\dawnguard_english.strings
<00:00:00.213>:         strings\dragonborn_english.dlstrings
<00:00:00.219>:         strings\dragonborn_english.ilstrings
<00:00:00.223>:         strings\dragonborn_english.strings
<00:00:00.225>:         strings\hearthfires_english.dlstrings
<00:00:00.227>:         strings\hearthfires_english.ilstrings
<00:00:00.230>:         strings\hearthfires_english.strings
<00:00:00.293>:         strings\skyrim_english.dlstrings
<00:00:00.394>:         strings\skyrim_english.ilstrings
<00:00:00.411>:         strings\skyrim_english.strings
<00:00:00.417>:         strings\update_english.dlstrings
<00:00:00.422>:         strings\update_english.ilstrings
<00:00:00.426>:         strings\update_english.strings
<00:00:00.426>: <------------------------ Summary ------------------------->
<00:00:00.427>: Source file        : Z:\Demo\Skyrim - Patch.bsa
<00:00:00.428>: Destination folder : Z:\Demo\demo3
<00:00:00.428>: List file          : Z:\Demo\ENtoJPFiles.txt
<00:00:00.428>:
<00:00:00.429>: Extract files/Skip files : 19/0
<00:00:00.429>: <---------------------- Process End ----------------------->

Z:\Demo>
```

## Contribution

1. Fork it ( https://github.com/ebakoJP/SimpleBSAExtractor/master/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create new Pull Request

## Author

[ebakoJP](https://github.com/ebakoJP)  

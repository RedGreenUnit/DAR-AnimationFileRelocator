# DAR-AnimationFileRelocator

## [概要]<br>
  SkyrimSE向けのアニメーションファイル管理ツールです。<br>
  ManagedModフォルダ配下に置いたSkyrimのアニメーションModを自動的に読み取り、<br>
  ユーザがカスタマイズした設定ファイルに従ってDynamicAnimationReplacerの管理フォルダに再配置するツールです。<br>
  再配置後にHkanno.exeのAnnotation Updateを自動実行する機能もあります。Annotate情報はアニメーションファイルごとに指定可能です。<br>

## [特徴]<br>
- DARのModを取り込み、論理条件をカスタマイズできる。<br>
- hkanno Animation Annotation ToolsによるAnnotation更新を自動化できる。<br>
- 再配置されたファイルはツールの再実行で自動的に削除され、設定ファイルに基づいて再配置される。<br>
つまり再現性があるので、アニメーション開発のTry&Errorに有用。<br>
- 設定ファイルは共有可能。<br>

## [前提条件]<br>
  Ruby2.4以上 (https://rubyinstaller.org/downloads/) <br>
  Toml-rb (https://github.com/emancu/toml-rb) ※インストール方法はリンク先を参照<br>
  hkanno Animation Annotation Tools (https://www.nexusmods.com/skyrim/mods/89435) <br>

## [使い方]<br>
### 前準備<br>
1. Hkanno.exeを "Hkanno"フォルダに置く。<br>
2. "Managed_Mods"フォルダに読み込みたいModのフォルダを置く。(任意の名前->data->meshes->... の構造)<br>
3. Config.ini を必要に応じて編集する。(◆Config.ini 参照)<br>

### 実行手順<br>
1. コマンドプロンプトで以下を実行<br>
$ ruby AnimFileRelocator.rb<br>
⇒ "ModList.toml"と"ModList.csv" の2ファイルが生成される。<br>
2. 上記2ファイルをコピーするなどして、同じ形式の別名のファイルを用意する。(以降この2ファイルを設定ファイルと呼びます。編集方法は後述)<br>
3. 2で用意したCsvを引数にして、1のコマンドを実行する。<br>
$ ruby AnimFileRelocator.rb hogehoge.csv<br>

### 実行結果<br>
- Config.iniの"DARCondition_Generate_From"に記載した数字のDARの管理フォルダから順に、<br>
  設定ファイルに記載したアニメーションファイルがコピーされる。<br>
- Csvの設定ファイルに記載したDARの論理式を元に、_customCondition.txtを作成してコピー先に配置する。<br>
- Tomlの設定ファイルにHkannoの設定がある場合は、hkanno.exe update が各ファイルに対して更新される。<br>
  更新に成功したかどうかはファイルのタイムスタンプで判断しており、失敗した場合はログに出力する。<br>

### Config.ini<br>
   - DARCondition_Generate_From = 100000<br>
       この番号のDARの管理フォルダ(_CustomConditions)から順にアニメーションファイルが配置される。<br>
   - DARCondition_Generate_To = 110000<br>
       この番号のDARの管理フォルダまで配置が実行される。<br>
   - ExportFolder = ExportFolder<br>
       指定したフォルダにアニメーションファイルを配置する。<br>
       MO2利用者の場合、overwriteフォルダを指定するとよい。パスは " " でくくること<br>
   - DoesNeedDumpAnnotation = false<br>
       読み込んだModのアニメーションファイルにAnnotateされた内容をファイルに出力する。<br>
        (Hkanno.exe dump を実行している)<br>
       出力先：Hkanno/IMPORTED_ANNO_TEXT 以下にMod名のフォルダが作成され、出力される。<br>
   - DEBUG = false<br>
       デバッグ用のログ出力が有効になる<br>


↓　以降はModder向け<br>
## Toml設定ファイルの編集<br>
　★DARの論理式の編集のみに興味のある方は読み飛ばしてください。<br>
![tomlImage](https://user-images.githubusercontent.com/47932625/126166789-77b003e6-a1c1-4d99-8ba6-a22cb26cdd47.PNG)

(上記画像を例にする)
- [SkySA_Animation_For_One-Handed_by_Ni-iru_200]<br>
Managed_Modsフォルダに置いたフォルダ名を元に生成した一意なセクション名。<br>
- comment = "_TypeA&idle"<br>
アニメーションに関するコメント。CustomConditionのフォルダにあるファイルの説明をテキストのファイル名で記載する習慣があるみたいなので<br>
アニメーションフォルダに置かれたテキスト名をコメントとして扱っている。<br>
- hkannoPreset = "SkySA_Ni-ru_Conversion"<br>
"Hkanno"フォルダに置いたフォルダ名を指定する。(◆HkannoのAnnotation方法　を参照)<br>
- location = "200"<br>
アニメーションファイルがどこにあるかを示す値。ここはModList.tomlが生成する値から変更しないこと！<br>
- modFolder = "SkySA Animation For One-Handed by Ni-iru"<br>
Managed_Modsフォルダに置いたフォルダ名。""でくくること!<br>
- skysa_sword1.sourceFileName = "1hm_attackright.hkx"<br>
左辺はコピー先のファイル名(拡張子は除外)、右辺はコピー元のファイル名<br>
- skysa_sword1.hkannoConfig = "_skysa_sword1_Anno.txt"<br>
左辺はコピー先のファイル名(拡張子は除外)、右辺はHkanno.exe update -i で指定されるAnnotation定義ファイル<br>

## Csv設定ファイルの編集<br>
### ![CsvEditSample](https://user-images.githubusercontent.com/47932625/126159043-2f1539dc-2b76-405c-a4fb-160127fb0398.PNG)

- 1列目はTomlの[セクション名] に該当する。ここに記載されたセクションのModのみがコピーされる。<br>
- 2カラム目以降はDARの論理式を表し、横列は"AND"、縦列は "OR"を表す。<br>
    例えば上記画像の3行目 "DAR_-_Diverse_Equipment_Normal_Attack_101008"の論理式は以下のようになる。<br>
    NOT IsFemale() AND IsEquippedRightType(1) OR IsEquippedRightType(2) OR IsEquippedRightType(3) OR IsEquippedRightType(4)<br>
    AND IsEquippedLeftType(1) OR IsEquippedLeftType(2) OR IsEquippedLeftType(3) OR IsEquippedLeftType(4)<br>
- OR条件の行の1列目の"OR"の記載は必須。<br>

## Hkannoの更新方法<br>
  Tomlの {アニメーションファイル名}.hkannoConfig = "{Annotate定義ファイル名}"で指定したファイルで、Hkanno.exeの更新が実行される。<br>
  　コマンドライン： Hkanno.exe update -i {Annotate定義ファイル名} {アニメーションファイル名}<br>
  Annotate定義ファイルは、セクションの "hkannoPreset = "で定義したフォルダに直に置くこと。<br>


## Credits<br>
- hkanno.exe<br>
 (https://www.nexusmods.com/skyrim/mods/89435)<br>
- Dynamic Animation Replacer<br>
 (https://www.nexusmods.com/skyrimspecialedition/mods/33746)<br>

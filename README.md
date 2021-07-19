# DAR-AnimationFileRelocator

◆概要
  SkyrimSE向けのアニメーションファイル管理ツールです。
  ManagedModフォルダ配下に置いたSkyrimのアニメーションModを自動的に読み取り、
  ユーザがカスタマイズした設定ファイルに従ってDynamicAnimationReplacerの管理フォルダに再配置するツールです。
  再配置後にHkanno.exeのAnnotation Updateを自動実行する機能もあります。Annotate情報はアニメーションファイルごとに指定可能です。

◆特徴
・DARのModを取り込み、論理条件をカスタマイズできる。
・hkanno Animation Annotation ToolsによるAnnotation更新を自動化できる。
・再配置されたファイルはツールの再実行で自動的に削除され、設定ファイルに基づいて再配置される。
　つまり再現性があるので、アニメーション開発のTry&Errorに有用。
・設定ファイルは共有可能。

◆前提条件
　Ruby2.4以上 (https://rubyinstaller.org/downloads/)
  Toml-rb (https://github.com/emancu/toml-rb) ※インストール方法はリンク先を参照
  hkanno Animation Annotation Tools (https://www.nexusmods.com/skyrim/mods/89435) 

◆使い方
(前準備)
・Hkanno.exeを "Hkanno"フォルダに置く。
・"Managed_Mods"フォルダに読み込みたいModのフォルダを置く。(任意の名前->data->meshes->... の構造)
・Config.ini を必要に応じて編集する。(後述)

(実行手順)
1. コマンドプロンプトで以下を実行
  $ ruby AnimFileRelocator.rb
  ⇒ "ModList.toml"と"ModList.csv" の2ファイルが生成される。
2. 上記2ファイルをコピーするなどして、同じ形式の別名のファイルを用意する。(以降この2ファイルを設定ファイルと呼びます。編集方法は後述)
3. 2で用意したCsvを引数にして、1のコマンドを実行する。
  $ ruby AnimFileRelocator.rb hogehoge.csv

(実行結果)
・Config.iniの"DARCondition_Generate_From"に記載した数字のDARの管理フォルダから順に、
　設定ファイルに記載したアニメーションファイルがコピーされる。
・Csvの設定ファイルに記載したDARの論理式を元に、_customCondition.txtを作成してコピー先に配置する。
・Tomlの設定ファイルにHkannoの設定がある場合は、hkanno.exe update が各ファイルに対して更新される。
　更新に成功したかどうかはファイルのタイムスタンプで判断しており、失敗した場合はログに出力する。

◆Config.ini
    DARCondition_Generate_From = 100000 // この番号のDARの管理フォルダ(_CustomConditions)から順にアニメーションファイルが配置される。
    DARCondition_Generate_To = 110000   // この番号のDARの管理フォルダまで配置が実行される。
    ExportFolder = ExportFolder         // 指定したフォルダにアニメーションファイルを配置する。
                                        // MO2利用者の場合、overwriteフォルダを指定するとよい。パスは " " でくくること
    DoesNeedDumpAnnotation = false      // 読み込んだModのアニメーションファイルにAnnotateされた内容をファイルに出力する。
                                        // (Hkanno.exe dump を実行している)
                                        // 出力先：Hkanno/IMPORTED_ANNO_TEXT 以下にMod名のフォルダが作成され、出力される。
    DEBUG = false                       // デバッグ用のログ出力が有効になる


↓　以降はModder向け
◆Toml設定ファイルの編集
　★DARの論理式の編集のみに興味のある方は読み飛ばしてください。
・Tomlファイルのフォーマット
[DAR_-_Diverse_Equipment_Normal_Attack_202003] # Managed_Modsフォルダに置いたフォルダ名を元に生成した一意なセクション名。
comment = "" # アニメーションに関するコメント。CustomConditionのフォルダにあるファイルの説明をテキストのファイル名で記載する習慣があるみたいなので
             # アニメーションフォルダに置かれたテキスト名をコメントとして扱っている。
hkannoPreset = ""   # "Hkanno"フォルダに置いたフォルダ名を指定する。(◆HkannoのAnnotation方法　を参照)
location = "202003" # アニメーションファイルがどこにあるかを示す値。ここはModList.tomlが生成する値から変更しないこと！
modFolder = "DAR - Diverse Equipment Normal Attack" # Managed_Modsフォルダに置いたフォルダ名。""でくくること!
    skysa_sword1.sourceFileName = "2hm_attackleft.hkx" # 左辺はコピー先のファイル名(拡張子は除外)、右辺はコピー元のファイル名
    skysa_sword1.hkannoConfig = "_skysa_sword1_Anno.txt" #左辺はコピー先のファイル名(拡張子は除外)、右辺はHkanno.exe update -i で指定されるAnnotation定義ファイル

◆Csv設定ファイルの編集
(https://github.com/RedGreenUnit/DAR-AnimationFileRelocator/issues/1#issue-947597913)

・1列目はTomlの[セクション名] に該当する。ここに記載されたセクションのModのみがコピーされる。
・2カラム目以降はDARの論理式を表し、横列は"AND"、縦列は "OR"を表す。
    例えば上記画像の3行目 "DAR_-_Diverse_Equipment_Normal_Attack_101008"の論理式は以下のようになる。
    NOT IsFemale() AND IsEquippedRightType(1) OR IsEquippedRightType(2) OR IsEquippedRightType(3) OR IsEquippedRightType(4)
    AND IsEquippedLeftType(1) OR IsEquippedLeftType(2) OR IsEquippedLeftType(3) OR IsEquippedLeftType(4)
・OR条件の行の1列目の"OR"の記載は必須。

◆Hkannoの更新方法
  Tomlの {アニメーションファイル名}.hkannoConfig = "{Annotate定義ファイル名}"で指定したファイルで Hkanno.exeの更新が実行される。
  　コマンドライン： Hkanno.exe update -i {Annotate定義ファイル名} {アニメーションファイル名}
  Annotate定義ファイルは、セクションの "hkannoPreset = "で定義したフォルダに直に置くこと。


◆Credits
・hkanno.exe
 (https://www.nexusmods.com/skyrim/mods/89435)
・Dynamic Animation Replacer
 (https://www.nexusmods.com/skyrimspecialedition/mods/33746)

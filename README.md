# DAR-AnimationFileRelocator

## [OverView]<br>
  This is a ruby tool to manage Animation Files and DAR Custom Conditions for Skyrim SE.<br>
  Creating a DAR folder, _condition.txt, placing animation files, and annotating events <br>
  with HKanno.exe are all automated by this tool.<br>
  <br>

## [Features]<br>
- Animation files will be relocated to DAR Custom Condition Folder by using the configuration file.<br>
  You can create the configuration file from scratch, but highly recommended to edit from autogenerated file by this tool.<br>
- The configuration file can describe all DAR Custom Conditions, and placing animation files.<br>
  You no longer have to walk around thousands of DAR Condition folders in Exlorer.<br>
- Hkanno annotation information can also describe in the configuration file, and Hkanno update process is also automated.<br>

## [Requirements]<br>
- Ruby 2.4 (https://rubyinstaller.org/downloads/) <br>
- Toml-rb (https://github.com/emancu/toml-rb) ※Refer to the link for the installation method. <br>
- hkanno Animation Annotation Tools (https://www.nexusmods.com/skyrim/mods/89435) <br>

## [How to Use]<br>
### Preparation<br>
1. Put Hkanno.exe to "Hkanno" folder.<br>
2. Put animation mods to "Managed_Mods" folder.<br>
    Structure must be {Mod Folder}->data->meshes->... <br>
3. Edit Config.ini if you need.<br>
    Refer to "Editing Config.ini"<br>

### Run<br>
1. Double click "AnimFileRelocator.bat"<br>
    "ModList.toml" and "ModList.csv" will be generated.<br>
2. Copy&Paste these files to another name. Two files must be the same name exclude extention.<br>
3. Edit these files for your purpose.<br>
    Refer to [Editing CustomConditions(Csv)] and [Editing Animation List(Toml)]<br>
4. Drag&Drop the csv file to "AnimFileRelocator.bat"<br>

### Editing Config.ini<br>
   - DARCondition_Generate_From = 100000<br>
       Animation files are placed in the DAR management folder (_CustomConditions) from this number. <br>
   - DARCondition_Generate_To = 110000<br>
       Animation files are placed in the DAR management folder (_CustomConditions) until this number. <br>
   - ExportFolder = ExportFolder<br>
       Animation files are placed to the specified folder.<br>
       Path must be the Windows format. (Copy from Explorer Path). If you use MO2, "overwrite" folder is good for use.<br>
   - DoesNeedDumpAnnotation = false<br>
       If true, dump the annotated events below "Hkanno/IMPORTED_ANNO_TEXT" folder.<br>
   - DEBUG = false<br>
       If true, debug mode is on.<br>

## [Editing CustomConditions (Csv)]<br>
### ![CsvEditSample](https://user-images.githubusercontent.com/47932625/126159043-2f1539dc-2b76-405c-a4fb-160127fb0398.PNG)

- The 1st column represent the [Section Name] of Toml. Only listed section will be relocated.<br>
- The second and subsequent columns represent the DAR Custom Conditions. <br>
   The horizontal cells represent "AND", the vertical cells represent "OR".<br>
    e.g) The third line in the above image represent : <br>
    NOT IsFemale() AND IsEquippedRightType(1) OR IsEquippedRightType(2) OR IsEquippedRightType(3) OR IsEquippedRightType(4)<br>
    AND IsEquippedLeftType(1) OR IsEquippedLeftType(2) OR IsEquippedLeftType(3) OR IsEquippedLeftType(4)<br>
- OR condition always requires "OR" in the 1st column.<br>

## [Editing Animation List (Toml)]<br>
![tomlImage](https://user-images.githubusercontent.com/47932625/126166789-77b003e6-a1c1-4d99-8ba6-a22cb26cdd47.PNG)

- [SkySA_Animation_For_One-Handed_by_Ni-iru_200]<br>
A unique section name generated based on the folder name placed in the "Managed_Mods" folder. <br>
- comment = "_TypeA&idle"<br>
Comments on animations. It seems that it is customary to describe the description with the text file name <br>
in the Custom Condition folder, so the text name is treated as a comment. <br>
- hkannoPreset = "SkySA_Ni-ru_Conversion"<br>
Specify the folder name placed in the "Hkanno" folder.<br>
Refer to [Hkanno's Annotation Method] <br>
- location = "200"<br>
A value that indicates where the animation file is located. Do not change this from the value generated by ModList.toml. <br>
- modFolder = "SkySA Animation For One-Handed by Ni-iru"<br>
The name of the folder you placed in the "Managed_Mods" folder. Enclose with " ". <br>
- skysa_sword1.sourceFileName = "1hm_attackright.hkx"<br>
The left side is the file name of the copy destination (excluding the extension), and the right side is the file name of the copy source. <br>
- skysa_sword1.hkannoConfig = "_skysa_sword1_Anno.txt"<br>
The left side is the file name of the copy destination (excluding the extension), <br>
and the right side is the Annotation definition file specified by "Hkanno.exe update -i". <br>

## [Hkanno's Annotation Method]<br>
  "Hkanno.exe update -i {anno.txt}" will be executed by the definition of Toml's {animation file name} .hkannoConfig = "{Annotate definition file name}". <br>
  If you want to check the commandline, set "Debug = true" in Config.ini, and read log.txt.

## Credits<br>
- hkanno.exe<br>
 (https://www.nexusmods.com/skyrim/mods/89435)<br>
- Dynamic Animation Replacer<br>
 (https://www.nexusmods.com/skyrimspecialedition/mods/33746)<br>
<br>
- Ruby 2.4<br>
 (https://rubyinstaller.org)<br>
- Toml-rb<br>
 (https://github.com/emancu/toml-rb)<br>
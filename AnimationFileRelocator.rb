require 'toml-rb'
require_relative "AnimationFileConverterModule.rb"
require_relative "UpdateModList.rb"

def prepareEnv(targetFileName)
    $workspace=Pathname.new(FileUtils.pwd)
    $managedModsFolder=$workspace.join("Managed_Mods")
    $exportFolder=Pathname.new(EXPORT_FOLDER.gsub("\\", "/"))
    $hkannoFolder=$workspace.join("Hkanno")
    $csvPath=$workspace.join(targetFileName + ".csv")
    $logExporter = LogExporter.new($workspace.join("log.txt").to_s)

    defaultTomlPath=$workspace.join("ModList.toml")
    customTomlPath=$workspace.join(targetFileName + ".toml")
    updateCsvAndToml()
    $logExporter.write("Information : Mod List Updated.")

    if !Dir.exist?($exportFolder)
        $logExporter.write("Error : Export Folder not found! Check config.ini")
        return false
    end

    if !File.exist?($csvPath)
        $logExporter.write("Error : Csv not Found! FileName = " + $csvPath.to_s)
        return false
    end

    if !File.exist?(customTomlPath)
        # ToDo : テンプレートの自動生成
        $logExporter.write("Information : Custom Mod List not Found! Template File Created.", 1)
    end

    #Tomlファイル読み込み
    $tomlDataHash=TomlRB.load_file(defaultTomlPath)
    TomlRB.load_file(customTomlPath).each do |key, value|
        $tomlDataHash[key] = value
    end

    # 指定した番号の範囲の出力先フォルダを削除しておく
    for num in CONDITIONS_GENERATE_FROM..CONDITIONS_GENERATE_TO
        targetFolder=getCustomConditionsFolderPath($exportFolder).join(num.to_s)
    	if Dir.exist?(targetFolder)
    	   begin
    		   deleteFolderRecursively(targetFolder)
    		 rescue => e
    		   p e.message
    		   return false
    	   end
    	end
    end
end

# 再帰的なフォルダとファイルの削除
def deleteFolderRecursively(deleteTarget)
    if !Dir.exist?(deleteTarget)
        return
    end

    targets = Dir::glob(deleteTarget + "**/").sort {
      |x,y| y.split('/').size <=> x.split('/').size
    }
    targets.each {|d|
      Dir::foreach(d) {|f|
        File::delete(d+f) if ! (/\.+$/ =~ f)
      }
      Dir::rmdir(d)
    }
end

def relocateAnimationFiles()
    $logExporter.write("Information : Start Relocate Animations.")

    # Csvを読み込み、CsvManagedData生成
    createFolderNumber =  CONDITIONS_GENERATE_FROM
    createCsvManagedDataList = []
    
	CsvTableConverterModule.getCsvManagedDataList(CSV.table($csvPath, headers: false)).each do |data|
        flagIncrement=false
        index = data.doesContainSameCondition(createCsvManagedDataList)
        if index[0]
            $logExporter.write("Information: Same Conditions Found! => Merge to "  + (index[1] + CONDITIONS_GENERATE_FROM).to_s + " ...", 2)
            AnimationFileConverterModule::execute(data, index[1] + CONDITIONS_GENERATE_FROM)
        else
            flagIncrement=true
            $logExporter.write("Information : Creating DAR Condition Folder " + createFolderNumber.to_s + "...")
            AnimationFileConverterModule::execute(data, createFolderNumber)
        end

        createCsvManagedDataList << data
        createFolderNumber += 1 if flagIncrement
    end
    
    $logExporter.write("Information : Relocate Animations Finished!")    
end

def main
    # debug
    system('touch Sample.toml')
    system('touch Sample.csv')
    
    if !prepareEnv("Sample") #debug
        return
    end

    relocateAnimationFiles
end

main
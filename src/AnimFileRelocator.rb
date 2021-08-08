require 'toml-rb'
require_relative "AnimationFileConverterModule.rb"
require_relative "UpdateModList.rb"
require_relative "ConfigReader.rb"

# Global変数は、基本的にここで初期化する
def prepareEnv(workspace)
    $workspace=Pathname.new(workspace)
    if !Dir.exists?($workspace)
        puts "Workspace does not exist. Finish.\n\n"
        return false
    end
    $logExporter = LogExporter.new($workspace.join("log.txt").to_s)
        
    configHash = ConfigReader::read("Config.ini")
    if false == configHash[0]
        return false
    end

    $managedModsFolder=$workspace.join("Managed_Mods")
    $exportFolder=configHash[1]["ExportFolder"]
    $conditionFrom=configHash[1]["DARCondition_Generate_From"]
    $conditionTo=configHash[1]["DARCondition_Generate_To"]
    $doesNeedDumpAnnotation=configHash[1]["DoesNeedDumpAnnotation"]
    $debug=configHash[1]["DEBUG"]
    $hkannoFolder=$workspace.join("Hkanno")
    # hkanno dump の出力フォルダを消しておく
    deleteFolderRecursively($hkannoFolder.join("IMPORTED_ANNO_TEXT"))

    updateCsvAndToml()
    $tomlDataHash=TomlRB.load_file($workspace.join("ModList.toml"))

    # アニメーション出力先を削除しておく
    for num in $conditionFrom..$conditionTo
        targetFolder=getCustomConditionsFolderPath($exportFolder).join(num.to_s)
    	if Dir.exist?(targetFolder)
    	   begin
    		   deleteFolderRecursively(targetFolder)
    		 rescue => e
               $logExporter.write(e.message, 2)
    		   return false
    	   end
    	end
    end

end

def relocateAnimationFiles()
    $logExporter.write("Start Relocating Animations Files.")

    # Csvを読み込み、CsvManagedData生成
    createFolderNumber =  $conditionFrom
    createCsvManagedDataList = []
    
	CsvTableConverterModule.getCsvManagedDataList(CSV.table($csvPath, headers: false)).each do |data|
        next if data.tomlSectionData.nil? # Csvのセクション名がTomlに見つからなかったとき
        $logExporter.write("Relocating " + data.tomlSectionData.sectionName + " ...", 0, 1)
        index = data.doesContainSameCondition(createCsvManagedDataList)
        if index[0]
            $logExporter.write("[" + data.tomlSectionData.sectionName + "] & [" + index[1].tomlSectionData.sectionName + "] Are Same Conditions!", 0, 1)
            $logExporter.write("Check the priority is what you intended. DAR treats as higher value is higher priority.", -1, 1)
        end
        
        AnimationFileConverterModule::execute(data, createFolderNumber)
        createCsvManagedDataList << data
        createFolderNumber += 1
    end
    
    $logExporter.write("Relocate Animation Files Finished!\n")    
end

def main
    workspace = ARGV[0]
    if workspace.nil?
        puts("Workspace not specified. Finish.\n")
        return
    else
        return if !prepareEnv(workspace)
    end

    target = ARGV[1]
    if target.nil?
        $logExporter.write("Csv not specified. Finish.\n")
        return
    else
        $csvPath=$workspace.join(target)
        if !File.exist?($csvPath) || ".csv" != File.extname($csvPath).downcase
            $logExporter.write("Csv not Found! File = " + $csvPath.to_s + "\n", 2)
            return
        end

        # Csvと同名のTomlがあれば、ModList.tomlに上書きする
        customTomlPath = $workspace.join($csvPath.basename(".*").to_s + ".toml")
        if File.exists?(customTomlPath)
            TomlRB.load_file(customTomlPath).each do |key, value|
                $tomlDataHash[key] = value
            end
        end

        relocateAnimationFiles
    end
end

begin
    main
rescue => e
    puts 
    puts ("An unexpected Error has Occurred!")
    puts ("Please report the message and log.txt to author. Be sure to set DEBUG = true in Config.ini .")
    puts 
    puts e.message
    puts e.backtrace
end

puts
system('pause')
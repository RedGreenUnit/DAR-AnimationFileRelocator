require 'toml-rb'
require_relative "CsvManagedData.rb"
require_relative "Util.rb"
require_relative "TomlFormatter.rb"

def createTomlHash(baseHash, tomlSectionName, modFolder, location, fileNameList)
    tomlHash = {}
    if "" != location
        tomlSectionName = tomlSectionName + "_" + location.to_s
    end
    if fileNameList.empty?
        return baseHash
    end

    tomlHash["modFolder"] = modFolder
    tomlHash["location"] = location
    tomlHash["HkannoPreset"] = "vanilla_movesets"
    fileNameList.each {|fileName|
        hashSub = {}
        hashSub["hkannoConfig"] = ""
        hashSub["sourceFileName"] = fileName
        tomlHash[fileName.gsub(/\.hkx/i, "")] = hashSub
    }

    baseHash[tomlSectionName] = tomlHash

    return baseHash
end

def createCsvLine(tomlSectionName, conditionTxt="")
    data = CsvManagedData.new
    data.setDataForImport(tomlSectionName, conditionTxt)
    return data.getCsvLines
end

def updateCsvAndToml
    tomlHash = {}
    csvLines = []
    regExp=Regexp.compile(".hkx", Regexp::IGNORECASE)

    Dir.foreach($managedModsFolder) {|modFolder|
        if "." == modFolder || ".." == modFolder
            next
        end
        # tomlセクション名をModフォルダ名から作成 (スペースとドットは"_"に変換)
        tomlSectionName = modFolder.gsub(" ", "_").gsub(".", "_")
        
        # デフォルトのアニメーションフォルダを探す
        # ToDo : dlcのフォルダ
        searchPath = getDefaultAnimationFolderPath($managedModsFolder.join(modFolder))
        fileNameList = []
        if Dir.exists?(searchPath)
            Dir.foreach(searchPath) {|child|
                next if "file" != File.ftype(searchPath.join(child))
                fileNameList << child if !regExp.match(child).nil?
            }
        end
        tomlHash = createTomlHash(tomlHash, tomlSectionName, modFolder, "", fileNameList)
        createCsvLine(tomlSectionName).each {|line| csvLines << line} if !fileNameList.empty?

        # "male"のアニメーションフォルダを探す
        fileNameList = []
        if Dir.exists?(searchPath.join("male"))
            Dir.foreach(searchPath.join("male")) {|child|
                next if "file" != File.ftype(searchPath.join("male").join(child))
                fileNameList << child if !regExp.match(child).nil?
            }
            tomlHash = createTomlHash(tomlHash, tomlSectionName, modFolder, "male", fileNameList)
            createCsvLine(tomlSectionName + "_" + "male").each {|line| csvLines << line} if !fileNameList.empty?
        end

        # "female"のアニメーションフォルダを探す
        fileNameList = []
        if Dir.exists?(searchPath.join("female"))
            Dir.foreach(searchPath.join("female")) {|child|
                next if "file" != File.ftype(searchPath.join("female").join(child))
                fileNameList << child if !regExp.match(child).nil?
            }
            tomlHash = createTomlHash(tomlHash, tomlSectionName, modFolder, "female", fileNameList)
            createCsvLine(tomlSectionName + "_" + "female").each {|line| csvLines << line} if !fileNameList.empty?
        end
        
        # DARの_CustomConditionsフォルダを探す
        searchPath = getCustomConditionsFolderPath($managedModsFolder.join(modFolder))
        if Dir.exists?(searchPath)
            Dir.foreach(searchPath) {|conditionNumber|
                fileNameList = []
                next if 0 == conditionNumber.to_i && conditionNumber != "0"
                conditionTxt = nil
                Dir.foreach(searchPath.join(conditionNumber.to_s)) {|child|
                    if "file" != File.ftype(searchPath.join(conditionNumber.to_s).join(child))
                        next
                    elsif child == "_conditions.txt"
                        conditionTxt = File.read(searchPath.join(conditionNumber.to_s).join(child))
                    elsif !regExp.match(child).nil?
                        fileNameList << child
                    end
                }
                tomlHash = createTomlHash(tomlHash, tomlSectionName, modFolder, conditionNumber, fileNameList)
                createCsvLine(tomlSectionName + "_" + conditionNumber.to_s, conditionTxt).each {|line| csvLines << line} if !fileNameList.empty?
            }
        end
    }

    File::delete($workspace.join('ModList.toml')) if File::exist?($workspace.join('ModList.toml'))
    File.open($workspace.join('ModList.toml'), "w") do |line|
        line << TomlRB.dump(tomlHash)
    end
    
    # format toml
    TomlFormatterModule::format($workspace.join('ModList.toml'))

    File::delete($workspace.join('ModList.csv')) if File::exist?($workspace.join('ModList.csv'))
    CSV.open($workspace.join('ModList.csv'), "w") do |csv|
		csvLines.each { |csvLine| csv << csvLine }
	end	
end

# 直接たたくとき用
def main
    $workspace=Pathname.new(FileUtils.pwd)
    $managedModsFolder=$workspace.join("Managed_Mods")
    $hkannoFolder=$workspace.join("Hkanno")
    $csvPath=$workspace.join("sample.csv") #debug

    updateCsvAndToml
end

main
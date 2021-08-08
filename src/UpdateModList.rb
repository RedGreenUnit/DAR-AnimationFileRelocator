require 'toml-rb'
require_relative "CsvManagedData.rb"
require_relative "Util.rb"
require_relative "TomlFormatter.rb"

def createTomlHash(baseHash, modFolder, location, fileNameList, comment)
    return baseHash if fileNameList.empty?

    # tomlセクション名をModフォルダ名とlocationから作成 (スペースとドットは"_"に変換)
    tomlSectionName = modFolder.gsub(" ", "_").gsub(".", "_") + "_" + location.to_s.gsub("|", "_").gsub(".", "_")
    
    tomlHash = {}
    tomlHash["modFolder"] = modFolder
    tomlHash["location"] = location
    tomlHash["hkannoPreset"] = ""
    tomlHash["comment"] = comment
    fileNameList.each {|fileName|
        hashSub = {}
        #hashSub["hkannoConfig"] = ""
        hashSub["sourceFileName"] = fileName
        tomlHash[fileName.gsub(/\.hkx/i, "")] = hashSub
    }
    baseHash[tomlSectionName] = tomlHash
    
    
    return baseHash, tomlSectionName
end

def createCsvLine(tomlSectionName, conditionTxt="")
    data = CsvManagedData.new
    data.setDataForImport(tomlSectionName, conditionTxt)
    return data.getCsvLines
end

def findAnimationFiles(searchPath)
    fileNameList = []
    conditionTxt = ""
    comment = ""
    return fileNameList, conditionTxt, comment if !Dir.exists?(searchPath)

    regExp=Regexp.compile(".hkx", Regexp::IGNORECASE)
    Dir.foreach(searchPath) {|child|
        next if "." == child || ".." == child
        foundItem = searchPath.join(child)
        if ".hkx" == File.extname(foundItem).downcase
            fileNameList << child if !regExp.match(child).nil?
        elsif "_conditions.txt" == child
            conditionTxt = File.read(foundItem)
        elsif "_conditions.txt" != child && ".txt" == File.extname(foundItem).downcase
            # CustomConditionのフォルダにあるファイルの説明をテキストのファイル名で記載する習慣がある
            comment = child.gsub(".txt", "")
        elsif "directory" == File::ftype(foundItem) && "DynamicAnimationReplacer" != child
            findAnimationFiles(foundItem)[0].each {|fileName| fileNameList << child + "/" + fileName}
        end
    }

    return fileNameList, conditionTxt, comment
end

def dumpHKannoAnnotation(baseFolderPath, fileNameList, outputDirPath, outputFilePrefix = "")
    return if !$doesNeedDumpAnnotation # Config.iniでDumpが有効になっているときのみ

    FileUtils.cd($hkannoFolder)
    FileUtils.mkdir_p(outputDirPath) if !Dir.exists?(outputDirPath)
    regExp=Regexp.compile("# numAnnotations: .")

    fileNameList.each{|fileNameRelative|
        filePath = baseFolderPath
        fileNameRelative.split("/").each {|item| filePath = filePath.join(item)}
        outputPath = outputDirPath.join(outputFilePrefix+ "_" + filePath.basename(".*").to_s + "_Anno.txt")
        commandLine="hkanno.exe dump -o " \
                      + "\"" + outputPath.to_s  + "\"" \
                      + " \"" + filePath.to_s + "\"" \
                      + " > nul 2>&1"
        system(commandLine)

        # 追加のAnnotationが1件以上あるときは、dump結果をファイルに残す
        foundAnnotation = false
        File.open(outputPath, "r") do |file|
            file.each {|line| 
                if !regExp.match(line).nil?
                    foundAnnotation = true if "0" != regExp.match(line)[0].gsub("# numAnnotations: ", "")
                end
            }
        end
        File::delete(outputPath) if !foundAnnotation
    }

    Dir.rmdir(outputDirPath) if Dir.empty?(outputDirPath)
end

def doesExcludeDir(baseDir, foreachDir)
    # マルチバイト文字を含むかどうか
    foreachDir.bytes do |b|
        return true if  (b & 0b10000000) != 0
    end

    return true if "." == foreachDir || ".." == foreachDir || ".modHidden" == foreachDir

    return !baseDir.join(foreachDir).directory?
end

def updateCsvAndToml
    $logExporter.write("Updating Mod List...")
    $logExporter.write("Start searching mod folders.", 0, 1)
    tomlHash = {}
    csvLines = []
    Dir.foreach($managedModsFolder) {|modFolder|
        next if doesExcludeDir($managedModsFolder, modFolder)
        $logExporter.write("Searching \"" + modFolder + "\" ...", 0, 2)

        # デフォルトのアニメーションフォルダを探す
        searchPath = getDefaultAnimationFolderPath($managedModsFolder.join(modFolder))
        fileNameList, conditionTxt, comment = findAnimationFiles(searchPath)
        tomlHash, tomlSectionName = createTomlHash(tomlHash, modFolder, "default", fileNameList, comment)
        createCsvLine(tomlSectionName).each {|line| csvLines << line} if !fileNameList.empty?
        dumpHKannoAnnotation(searchPath, fileNameList, $hkannoFolder.join("IMPORTED_ANNO_TEXT").join(modFolder))
        
        # DARの_CustomConditionsフォルダを探す
        searchPath = getCustomConditionsFolderPath($managedModsFolder.join(modFolder))
        if Dir.exists?(searchPath)
            Dir.foreach(searchPath) {|conditionNumber|
                next if doesExcludeDir(searchPath, conditionNumber) || 0 == conditionNumber.to_i && conditionNumber != "0"
                fileNameList, conditionTxt, comment = findAnimationFiles(searchPath.join(conditionNumber))
                tomlHash, tomlSectionName = createTomlHash(tomlHash, modFolder, conditionNumber, fileNameList, comment)
                createCsvLine(tomlSectionName, conditionTxt).each {|line| csvLines << line} if !fileNameList.empty?
                dumpHKannoAnnotation(searchPath.join(conditionNumber), fileNameList, $hkannoFolder.join("IMPORTED_ANNO_TEXT").join(modFolder), conditionNumber)
            }
        end

        # DARのActorBaseIdごとのフォルダを探す
        searchPath = getDarRootFolderPath($managedModsFolder.join(modFolder))
        if Dir.exists?(searchPath)
            Dir.foreach(searchPath) {|espFolder|
                next if doesExcludeDir(searchPath, espFolder) || "_CustomConditions" == espFolder
                Dir.foreach(searchPath.join(espFolder)) {|actorBaseId|
                    next if doesExcludeDir(searchPath.join(espFolder), actorBaseId)
                    fileNameList, conditionTxt, comment = findAnimationFiles(searchPath.join(espFolder).join(actorBaseId))
                    tomlHash, tomlSectionName = createTomlHash(tomlHash, modFolder, espFolder + "\|" + actorBaseId, fileNameList, comment)
                    conditionText = "IsActorBase(\"" + espFolder + "\" | " + actorBaseId + ")"
                    createCsvLine(tomlSectionName, conditionText).each {|line| csvLines << line} if !fileNameList.empty?
                    dumpHKannoAnnotation(searchPath.join(espFolder).join(actorBaseId), \
                                         fileNameList, \
                                         $hkannoFolder.join("IMPORTED_ANNO_TEXT").join(modFolder), \
                                         espFolder + "_" + actorBaseId)
                }
            }
        end
    }
    $logExporter.write("Finished searching mod folders.", 0, 1)

    File::delete($workspace.join('ModList.toml')) if File::exist?($workspace.join('ModList.toml'))
    File.open($workspace.join('ModList.toml'), "w") do |line|
        line << TomlRB.dump(tomlHash)
    end
    TomlFormatterModule::format($workspace.join('ModList.toml'))
    $logExporter.write("ModList.toml has successfully created.", 0, 1)

    File::delete($workspace.join('ModList.csv')) if File::exist?($workspace.join('ModList.csv'))
    CSV.open($workspace.join('ModList.csv'), "w") do |csv|
		csvLines.each { |csvLine| csv << csvLine }
	end
    $logExporter.write("ModList.csv has successfully created.", 0, 1)

    $logExporter.write("Mod List Updated.\n")

end

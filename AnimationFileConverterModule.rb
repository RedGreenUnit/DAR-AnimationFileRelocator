require_relative 'CsvManagedData.rb'

module AnimationFileConverterModule
    def execute(csvManagedData, exportConditionNumber)
        if !csvManagedData.is_a?(CsvManagedData)
            $logExporter.write("Error : CsvManagedData is not valid!")
            return
        end

        $logExporter.write("Information : Converting " + csvManagedData.tomlSectionData.sectionName, 1)
        
        currentDir=$workspace.join(HKANNO_FOLDER)
        FileUtils.cd(currentDir)
        FileUtils.rm(currentDir.join("anno.txt")) if File.exists?(currentDir.join("anno.txt"))

        # コピー先準備 & _customCondition.txt作成
        destFolder = getFileLocationFullPath($exportFolder, exportConditionNumber)
        FileUtils.mkdir_p(destFolder)
        File.open(destFolder.join('_conditions.txt'), "w") do |line|
            line << csvManagedData.getConditionText
        end

        csvManagedData.tomlSectionData.getDestSourceFullPathHash(exportConditionNumber).each {|dest, sourceData|
            # Animationファイルコピー
            sourcePath = csvManagedData.tomlSectionData.getSourceAndHKannoConfig(sourceData)[0]
            destPath = Pathname.new(dest)
            FileUtils.copy(sourcePath.to_s, destPath.to_s)
            
            # anno.txt準備
            updateConfigPath = csvManagedData.tomlSectionData.getSourceAndHKannoConfig(sourceData)[1]
            if !File::exist?(updateConfigPath)
                # anno.txt未指定ならコピーするだけ
                $logExporter.write("Information : Hkanno Annotation file not specified. Skip Conversion...")
                next
            end

            File.open(currentDir.join("anno.txt"), "wb") do |annoTxt|
                File.open(updateConfigPath).each_line do |line|
                    # todo : 追加の差し込み
                    annoTxt << line
                end
            end

            # hkanno.exe update -i anno.txt {Target}
            FileUtils.cd(currentDir)
            #commandLine="hkanno.exe update -i anno.txt \"" + dest.to_s + "\""
            commandLine="hkanno.exe update -i " + "\"" + updateConfigPath.to_s + "\""  + " \"" + dest.to_s + "\""
            system(commandLine)
            $logExporter.write(commandLine, 2)
        }
    end

    private
    def toDo
        # "telegraphed attacks window" の秒数を差し込んだHKannoのUpdateテキストを作成する
        valueFlamePrev=0.0
        File.open(currentDir.join("anno.txt"), "wb") do |annoTxt|
            File.open(updateConfigPath).each_line do |line|
                if convertInformation.telegraphedFlame.nil?
                    annoTxt << line
                    next  # 差し込み不要
                end     

                # コメント行
                if line.split(" ")[0] == "#"
                    if line.split(" ")[1] == "numAnnotations:"
                        annoTxt << "# numAnnotations: " + (line.split(" ")[2].to_i + 1).to_s + "\n"
                    else
                        annoTxt << line
                    end
                    next
                end     

                # telegraphed attacks windowのFlame秒数を差し込む
                valueFlame = line.split(" ")[0].to_f
                if (valueFlamePrev <= convertInformation.telegraphedFlame && convertInformation.telegraphedFlame < valueFlame)
                    annoTxt << convertInformation.telegraphedFlame.to_s + " SkySA_eventdrivenmodifier_trigger\n"
                    annoTxt << line
                else
                    annoTxt << line
                end
                valueFlamePrev = valueFlame
            end
        end
    end

    module_function :execute
end
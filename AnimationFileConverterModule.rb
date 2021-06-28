require_relative 'CsvManagedData.rb'

module AnimationFileConverterModule
    def execute(csvManagedData, exportConditionNumber)
        if !csvManagedData.is_a?(CsvManagedData)
            $logExporter.write("CsvManagedData is not valid!", 2) if $debug
            return
        end
        
        FileUtils.cd($hkannoFolder)
        FileUtils.rm($hkannoFolder.join("anno.txt")) if File.exists?($hkannoFolder.join("anno.txt"))

        # コピー先準備 & _customCondition.txt作成
        destFolder = getFileLocationFullPath($exportFolder, exportConditionNumber)
        FileUtils.mkdir_p(destFolder)
        File.open(destFolder.join('_conditions.txt'), "w") do |line|
            line << csvManagedData.getConditionText
        end

        csvManagedData.tomlSectionData.getDestSourceFullPathHash(exportConditionNumber).each {|dest, sourceData|
            # Animationファイルコピー
            sourcePath = csvManagedData.tomlSectionData.getSourceAndHKannoConfig(sourceData)[0]
            if !File.exists?(sourcePath)
                $logExporter.write("No such animation file : " + sourcePath.to_s, 2, 2)
                next
            end
            destPath = Pathname.new(dest)
            FileUtils.mkdir_p(destPath.parent) if !Dir.exist?(destPath.parent) # male, female, dlc01などのフォルダを作る
            FileUtils.copy(sourcePath.to_s, destPath.to_s, {:preserve => true})
            $logExporter.write("Relocated " + destPath.basename.to_s  + " to " + destPath.parent.basename.to_s + " ...", 0, 2)
            
            # anno.txt準備
            updateConfigPath = csvManagedData.tomlSectionData.getSourceAndHKannoConfig(sourceData)[1]
            if !File::exist?(updateConfigPath) || "file" != File.ftype(updateConfigPath)
                # anno.txt未指定ならコピーするだけ
                $logExporter.write("Hkanno Annotation file not specified. Skip Conversion...", 0, 2)
                next
            end

            #File.open(currentDir.join("anno.txt"), "wb") do |annoTxt|
            #    File.open(updateConfigPath).each_line do |line|
            #        # todo : 追加の差し込み
            #        annoTxt << line
            #    end
            #end
            #commandLine="hkanno.exe update -i anno.txt \"" + dest.to_s + "\""

            # hkanno.exe update -i anno.txt {Target}
            time = File.mtime(destPath)
            commandLine="hkanno.exe update -i " + "\"" + updateConfigPath.to_s + "\""  + " \"" + destPath.to_s + "\""
            system(commandLine)

            # HKanno.exe update に成功すると、ファイルの更新日時が変わる
            if time == File.mtime(destPath)
                $logExporter.write("Relocate animation was succeeded, but conversion by hkanno.exe would be failed. This file might be for SSE.", 1, 2)
            else
                $logExporter.write("Relocate and Convert animation was Succeeded!", 0, 2)
            end
            $logExporter.write(commandLine, -1, 2) if $debug
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
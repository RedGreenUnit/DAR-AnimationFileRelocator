
module TomlFormatterModule
    def format(tomlFilePath)
        return if !File::exist?(tomlFilePath)
        outputLines = []
        regExp=Regexp.compile("\\[.*?\\]")
        sectionNameSub=""

        File.open(tomlFilePath, "r") do |file|
            file.each {|line| 
                matchResult = regExp.match(line)
                if !matchResult.nil?
                    if line.split(".")[1].nil?
                        outputLines << "\n"
                        outputLines << "\n"
                        outputLines << line
                        sectionNameSub = ""
                    else
                        sectionNameSub = line.split(".")[1].gsub("\n", "").gsub("]", "")
                        outputLines << "\n"
                    end
                else
                    if sectionNameSub == ""
                        outputLines << line
                    else
                        outputLines << sectionNameSub + "." + line
                    end
                end
            }
        end

        File::delete(tomlFilePath)
        File.open(tomlFilePath, "w") do |file|
            outputLines.each {|line| file << line }
        end
    end
    module_function :format
end

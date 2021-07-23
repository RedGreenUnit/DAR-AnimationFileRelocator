require 'fileutils'
require "pathname"
require_relative "LogExporter.rb"

module ConfigReader
    def read(configPath)
        $logExporter.write("Reading Config.ini.")

        configHash = {}
        if !File.exists?(configPath)
            createDefaultConfig(configPath)
            $logExporter.write("Config.ini not found. Default Config.ini is created.", 0, 1)
        end

        File.open(configPath, "r") do |file|
            num = 0
            file.each {|line| 
                num = num + 1
                line = line.gsub(" = ", "=")
                next if line == "\n" || line[0] == "#"
                if line.split("=")[1].nil?
                    $logExporter.write("Invalid line is found. Check Config.ini at line " + num.to_s, 2, 1)
                    return false, configHash
                end

                configHash[line.split("=")[0]] = line.split("=")[1].gsub("\n", "")
            }
        end

        if !configHash.has_key?("DARCondition_Generate_From") || 0 == configHash["DARCondition_Generate_From"].to_i
            configHash["DARCondition_Generate_From"] = 100000
            $logExporter.write("Config Key : \"DARCondition_Generate_From\" is not set. Default value(100000) is used.", 0, 1)
        else
            configHash["DARCondition_Generate_From"] = configHash["DARCondition_Generate_From"].to_i
        end

        if !configHash.has_key?("DARCondition_Generate_To") || 0 == configHash["DARCondition_Generate_To"].to_i
            configHash["DARCondition_Generate_To"] = 110000
            $logExporter.write("Config Key \"DARCondition_Generate_To\" is not set. Default value(110000) is used.", 0, 1)
        else
            configHash["DARCondition_Generate_To"] = configHash["DARCondition_Generate_To"].to_i
        end
        
        if !configHash.has_key?("ExportFolder")
            configHash["ExportFolder"] = "ExportFolder"
            $logExporter.write("Config Key \"ExportFolder\" is not set. Default value(ExportFolder) is used.", 0, 1)
        end
        configHash["ExportFolder"] = $workspace.join(configHash["ExportFolder"].gsub("\\", "/"))
        if !Dir.exist?(configHash["ExportFolder"])
            $logExporter.write("Export Folder not found! Path = " + configHash["ExportFolder"].to_s, 2, 1)
            return false, configHash
        end

        if !configHash.has_key?("DoesNeedDumpAnnotation")
            configHash["DoesNeedDumpAnnotation"] = "false"
            $logExporter.write("Config Key \"DoesNeedDumpAnnotation\" is not set. Default value(false) is used.", 0, 1)
        end
        configHash["DoesNeedDumpAnnotation"] = configHash["DoesNeedDumpAnnotation"]
        if "true" == configHash["DoesNeedDumpAnnotation"].downcase
            configHash["DoesNeedDumpAnnotation"] = true
        elsif "false" == configHash["DoesNeedDumpAnnotation"].downcase
            configHash["DoesNeedDumpAnnotation"] = false
        else
            $logExporter.write("Invalid value is set on Config Key \"DoesNeedDumpAnnotation\".", 2)
            return false, configHash
        end

        if !configHash.has_key?("DEBUG")
            configHash["DEBUG"] = "false"
        end
        configHash["DEBUG"] = configHash["DEBUG"]
        if "true" == configHash["DEBUG"].downcase
            configHash["DEBUG"] = true
            $logExporter.write("Debug Mode : ON")
        else
            configHash["DEBUG"] = false
        end

        $logExporter.write("DARCondition_Generate_From = " + configHash["DARCondition_Generate_From"].to_s , -1, 2)
        $logExporter.write("DARCondition_Generate_To = " + configHash["DARCondition_Generate_To"].to_s , -1, 2)
        $logExporter.write("ExportFolder = " + configHash["ExportFolder"].to_s , -1, 2)
        $logExporter.write("DoesNeedDumpAnnotation = " + configHash["DoesNeedDumpAnnotation"].to_s , -1, 2)
        $logExporter.write("Config.ini has successfully read.\n")

        return true, configHash
    end


    private
    def createDefaultConfig(configPath)
        File.open(configPath, "w") do |file|
            file.puts("DARCondition_Generate_From = 100000")
            file.puts("DARCondition_Generate_To = 110000")
            file.puts("ExportFolder = ExportFolder")
        end
    end

    module_function :read, :createDefaultConfig
end

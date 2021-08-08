require 'pp'
require 'fileutils'
require "pathname"

# ログ出力クラス
class LogExporter
	def initialize(logFile)
		FileUtils.rm(logFile) if File.exist?(logFile)
		@fileObj = File.open(logFile, "w")
	end

	def LogExporter.callback
		proc {
			@fileObj.close
		}
	  end

	def write(message, logLevel = 0, indent=0, isNewLine=true, showConsole=true)
		char=""
		if (isNewLine)
			char = char + "\n"
		end

		case logLevel
		when 0 then
			char = char + "[Info] "
		when 1 then
			char = char + "[Warning] "
		when 2 then
			char = char + "[ERROR] "
		when 3 then
			char = char + "[DEBUG] "
		else
			char = char + "          "
		end

		for num in 1..indent
			char = char + "    "
		end
		char = char + message

		print char if showConsole
		@fileObj.write(char)
	end
end
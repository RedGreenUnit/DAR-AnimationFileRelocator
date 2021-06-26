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

	def write(message, indent=0, isNewLine=true, showConsole=true)
		char=""
		if (isNewLine)
			char = char + "\n"
		end

		for num in 1..indent
			char = char + "    "
		end
		char = char + message

		print char if showConsole
		@fileObj.write(char)
	end
end
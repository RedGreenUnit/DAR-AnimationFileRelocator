require "csv"
require_relative 'TomlSectionData.rb'

# [Csvフォーマット]
# line   |              A            |                  B                     |              C               |       D     |
#   1    | Olivier kenjutsu V5_10199 | IsActorBase("Skyrim.esm"|0x000007)     |                              |             |
#   1    | Olivier kenjutsu V5_10199 | IsActorBase("Skyrim.esm"|0x000007)     |                              |             |
#   1    | Olivier kenjutsu V5_10199 | IsActorBase("Skyrim.esm"|0x000007)     |                              |             |
#   1    | Olivier kenjutsu V5_10199 | NOT IsActorBase("Skyrim.esm"|0x000007) | IsEquippedRight("Skyrim.esm" | 0x000647AC) |
#   1    |            OR             |                                        | IsEquippedRight("Skyrim.esm" | 0x00018DDD) |
#
#  A列      : Tomlファイルのセクション名
#  B列以降  : CsvManagedDataPartクラスで保持


# _customCondition.txtの論理式を、本クラスの配列で表現する
#     論理式：(A OR B) AND C AND (D OR E OR F OR G) AND H
#        ↓
#      Csv    | A | C | D | H |
#             | B |   | E |   |
#             |   |   | F |   |
#             |   |   | G |   |
# 
# 以下の()のくくりのデータがこのクラスのスコープ
#    (A) & (B OR C OR D) & (E OR F)
class CsvManagedDataPart
    attr_accessor :condition, :orConditionList

	def initialize(conditionWithORs)
		@orConditionList = []
		conditionWithORs="" if conditionWithORs.nil?

		regExpOr = " OR .+?\\)"
		matchStr = conditionWithORs.match(regExpOr)
		while !matchStr.nil? do
			@orConditionList << matchStr[0].gsub(" OR ", "")
			conditionWithORs = conditionWithORs.gsub(matchStr[0], "")
			matchStr = conditionWithORs.match(regExpOr)
		end
        @condition=conditionWithORs
    end

	# 比較演算子：ORは順不同なのでソートして比較
	def ==(other)
		if (self.condition != other.condition)
			return false
		end

		return self.orConditionList.sort == other.orConditionList.sort
	end
end

class CsvManagedData
    attr_accessor :tomlSectionData, :csvManagedDataPartList
    def initialize()
	end

	# エクスポート時のデータセット
	def setDataForExport(csvRow, tomlData)
		tomlSectionName=csvRow.shift
		if !tomlData.has_key?(tomlSectionName)
			$logExporter.write("No Section was found in Toml. Section Name = " + tomlSectionName, 2)
			$logExporter.write("Check the definition in Csv column 1.", -1)
			$logExporter.write(tomlData.to_s, 3, 0, true, false) if $debug
			return
		end
		@tomlSectionData = TomlSectionData.new(tomlSectionName, tomlData[tomlSectionName])
		@csvManagedDataPartList = createDataPartList(csvRow)
	end

	# インポート時のデータセット
	def setDataForImport(tomlSectionName, conditionText)
		# ダミー
		@tomlSectionData = TomlSectionData.new(tomlSectionName, {})
		@csvManagedDataPartList = []
		# 改行コードをスペースに置換
		conditionText=conditionText.gsub(/\R/, " ")
		# スペース2文字以上は1文字に置換
		conditionText=conditionText.gsub(/ +/, " ")

		# (A) AND (B OR C OR D) AND (E OR F)
		# (~~)の部分を先頭から抜き出す
		regExpAnd = ".+?\\) AND "
		matchStr = conditionText.match(regExpAnd)
		while !matchStr.nil? do
			@csvManagedDataPartList << CsvManagedDataPart.new(matchStr[0].gsub(" AND ", ""))
			conditionText = conditionText.gsub(matchStr[0], "")
			matchStr = conditionText.match(regExpAnd)
		end

		# 末尾
		@csvManagedDataPartList << CsvManagedDataPart.new(conditionText)
	end

    # DARの条件式が等しいインスタンスが引数のリストに含まれているかどうか
	def doesContainSameCondition(csvManagedDataList)
		csvManagedDataList.each do |data|
            if self.csvManagedDataPartList.sort_by(&:condition) == data.csvManagedDataPartList.sort_by(&:condition)
				return true, data
            end
        end
		return false, self
	end

	# _customCondition.txt取得
	def getConditionText
		text=""
		@csvManagedDataPartList.each do |dataPart|
			text = text + dataPart.condition
			dataPart.orConditionList.each do |orCondition|
				text = text + " OR\n" + orCondition
			end
			text = text + " AND\n" #if text.gsub(" ", "") != ""
		end
		return text.chop.chop.chop.chop # 末尾の"AND\n"を削除
	end

	# Csv出力行の取得
	def getCsvLines
		csvLines = []
		
		# 1行目 (AND行)
		rowFirst = [] << @tomlSectionData.sectionName
		@csvManagedDataPartList.each { |x| rowFirst << x.condition}
		csvLines << rowFirst

		# 2行目以降 (OR行)
		orConditionCount = @csvManagedDataPartList.max { |x, y| x.orConditionList.size <=> y.orConditionList.size }.orConditionList.size
		for num in 0..orConditionCount-1
			row = [] << "OR"
			@csvManagedDataPartList.each { |x| row << x.orConditionList[num]}
			csvLines << row
		end

		return csvLines
	end

	private
    def createDataPartList(row)
        csvManagedDataPartList = []
        row.each do |col|
            csvManagedDataPartList << CsvManagedDataPart.new(col) if !col.nil?
        end
        return csvManagedDataPartList
    end
end

# Csv::TableからCsvManagedDataを作成する
module CsvTableConverterModule
	def getCsvManagedDataList(csvTable)
		csvManagedDataList = []
		csvTable.each do |row|
			if row.size == 0
                $logExporter.write("Invalid Csv Line was found ! Line = " + csvTable.find_index(row).to_s, 2, 1)
                return
            end

            if row[0].is_a?(String) && row[0] == 'OR'  # OR条件
				row.shift
				row.each do |col|
					dataPart = csvManagedDataList.last.csvManagedDataPartList[row.find_index(col)]
					dataPart.orConditionList << col if !col.nil?
				end
            else
				data = CsvManagedData.new()
				data.setDataForExport(row, $tomlDataHash)
				csvManagedDataList << data
			end
		end

		return csvManagedDataList
	end

	module_function :getCsvManagedDataList
end
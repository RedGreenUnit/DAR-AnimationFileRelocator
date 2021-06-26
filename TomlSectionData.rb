require 'fileutils'
require "pathname"
require_relative "LogExporter.rb"
require_relative 'Util.rb'

class TomlSectionData
    attr_accessor :sectionName
    def initialize(sectionName, sectionDataHash)
		@sectionName=sectionName
        @sectionDataHash=sectionDataHash
        @modFolder=getPreDefinedHashValue("modFolder")
        @location=getPreDefinedHashValue("location")
        @hkannonPreset=getPreDefinedHashValue("HkannoPreset")
    end

    # コピー元とコピー先のPathnameをHashで取得する。
    # コピー先のフォーマット：{ファイル名、HKannoのConfig名、追加のAnnotationのキー&バリュー}　⇒ getSourceAndHKannoConfig()で取り出すこと
    def getDestSourceFullPathHash(destConditionNumber = nil)
        destSourceHash = {}
        @sectionDataHash.each {|key, value| 
            destFullPath = getFileLocationFullPath($exportFolder, destConditionNumber, key.to_s + ".hkx")
            destSourceHash[destFullPath.to_s] = value
        }
        
        return destSourceHash
    end
    
    # コピー元のPathname、変換用のHKanno定義ファイルのPathnameを返す
    def getSourceAndHKannoConfig(value)
        sourceFileName = value["sourceFileName"]
        hkannoConfig = value["hkannoConfig"]
        sourcePath = getFileLocationFullPath($managedModsFolder.join(@modFolder), @location, sourceFileName)
        
        return sourcePath, $hkannoFolder.join(@hkannonPreset).join(hkannoConfig)
    end

    private
    def getPreDefinedHashValue(keyName)
        txt=""
        if @sectionDataHash.has_key?(keyName)
            txt = @sectionDataHash[keyName].to_s
            @sectionDataHash = @sectionDataHash.reject{|key, value| key.to_s == keyName}
        end

        return txt
    end
end

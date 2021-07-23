# DARのフォルダを返す
def getDarRootFolderPath(dataFolderPath)
    return dataFolderPath.join("meshes")
          .join("actors").join("character").join("animations").join("DynamicAnimationReplacer")
end

# DARの_CustomConditionsのパスを返す
def getCustomConditionsFolderPath(dataFolderPath)
    return dataFolderPath.join("meshes")
          .join("actors").join("character").join("animations").join("DynamicAnimationReplacer").join("_CustomConditions")
end

# Skyrimのデフォルトアニメーションパスを返す
def getDefaultAnimationFolderPath(dataFolderPath)
    return dataFolderPath.join("meshes")
          .join("actors").join("character").join("animations")
end

# LocationAliasの文字列から、実際のフルパスを特定して返却する
def getFileLocationFullPath(modPath, locationAlias, fileName=nil)
    path = modPath
    if locationAlias.nil?
        path = path.join("meshes")
                   .join("actors").join("character").join("animations")
    elsif is_number?(locationAlias)
        # _CustomConditionsのフォルダ
        path = path.join("meshes")
                   .join("actors").join("character").join("animations").join("DynamicAnimationReplacer").join("_CustomConditions")
                   .join(locationAlias.to_s)
    elsif locationAlias == "male"
        path = path.join("meshes")
                   .join("actors").join("character").join("animations").join("male")
    elsif locationAlias == "female"
        path = path.join("meshes")
                   .join("actors").join("character").join("animations").join("female")
    elsif locationAlias.include?("|")
        # ActorBaseIdのフォルダ
        path = path.join("meshes")
                   .join("actors").join("character").join("animations").join("DynamicAnimationReplacer")
                   .join(locationAlias.split("|")[0]).join(locationAlias.split("|")[1])

    else
        path = path.join("meshes")
                   .join("actors").join("character").join("animations")
    end

    fileName.split("/").each {|item| path = path.join(item)} if !fileName.nil?

    return path
end

def is_number?(obj)
    obj.to_s == obj.to_i.to_s
end

# 再帰的なフォルダとファイルの削除
def deleteFolderRecursively(deleteTarget)
    if !Dir.exist?(deleteTarget)
        return
    end

    targets = Dir::glob(deleteTarget + "**/").sort {
      |x,y| y.split('/').size <=> x.split('/').size
    }
    targets.each {|d|
      Dir::foreach(d) {|f|
        File::delete(d+f) if ! (/\.+$/ =~ f)
      }
      Dir::rmdir(d)
    }
end
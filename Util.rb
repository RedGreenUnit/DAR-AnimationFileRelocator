HKANNO_FOLDER="HKAnno"
MANAGED_MODS="Managed_Mods"
EXPORT_FOLDER="E:\\my document\\game\\skyrimse_backup\\MO2_BaseDir\\overwrite"
CONDITIONS_GENERATE_FROM=100000
CONDITIONS_GENERATE_TO=101000

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
        path = path.join("meshes")
                   .join("actors").join("character").join("animations").join("DynamicAnimationReplacer").join("_CustomConditions")
                   .join(locationAlias.to_s)
    elsif locationAlias == "male"
        path = path.join("meshes")
                   .join("actors").join("character").join("animations").join("male")
    elsif locationAlias == "female"
        path = path.join("meshes")
                   .join("actors").join("character").join("animations").join("female")
    else
        path = path.join("meshes")
                   .join("actors").join("character").join("animations")
    end

    path = path.join(fileName) if !fileName.nil?

    return path
end

def is_number?(obj)
    obj.to_s == obj.to_i.to_s
end
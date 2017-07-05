=begin
 删除静态库中的指定macho文件
 @param1 要删除macho文件的静态库
 @param2 要删除的macho合集

 用法: ruby iOSDeleteMachoFile.rb IJKMediaFramework mutiple.md
=end


require 'fileutils'

# 所有指令集
$allArchs = ["armv7", "arm64", "i386", "x86_64"]

# 获取静态库所有支持的指令集(arm64,armv7)
def getArchitectures(library)
    info = `lipo -info #{library}`
    return info.split(" ") & $allArchs
end

# 提取所有指令集架构
def extractAllArchitectures(library, archs)
    archs.each do |arch|
        `lipo #{library} -thin #{arch} -output #{arch}` # 提取一个架构
    end
end

# 删除macho文件
def deleteMacho(arch, machos)
    machos.each do |macho|
        `ar -d -sv #{arch} #{macho}` # 直接删除arch中的macho文件
    end
end

# 将原库重命名
def libraryRename(library)
    if library.scan(/\.[^\.]+$/)[0]
        extension = library.scan(/\.[^\.]+$/)[0]
        newFilename = String.new<<library
        newFilename.insert newFilename.length-extension.length, "_backup"
    else
        newFilename = library + "_backup"
    end
    File::rename library, newFilename
end

# 合并.a文件
def mergeArchitectures(library, archs)
    command = "lipo -create "
    archs.each do |arch|
        command << (arch + " ")
    end
    command << "-output #{library}"
    `#{command}`
end

# 删除单独的指令集
def deleteSperateArchs(archs)
    archs.each do |arch|
        File::delete arch
    end
end

# 删除library库的machos文件
def deleteMachoFile(library, machos)
    archs = getArchitectures(library)
    if archs.count
        extractAllArchitectures(library, archs)
        
        archs.each do |arch| # 遍历指令集，每一个指令集都删除machos
            deleteMacho(arch, machos)
        end
        
        libraryRename(library)
        mergeArchitectures(library, archs)
        deleteSperateArchs(archs)
    end
end


library = ARGV[0]
filename = ARGV[1]
if library && filename
    machos = IO.readlines(filename)
    if machos.count # 有需要删除的macho文件
        deleteMachoFile(library, machos)
    end
end

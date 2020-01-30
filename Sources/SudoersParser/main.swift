import Foundation

public struct ParsedSudoers : CustomStringConvertible {
    public let filePath: String
    public let fileDir: String
    public let fileContent: String
    public let includeDirs: [String]
    public let includedFiles: [ParsedSudoers]
    
    public var description: String {
        let contentToPrint = "Size: \(fileContent.utf8.count) bytes"
        let s = "ParsedSudoers(filePath: \"\(filePath)\", fileDir: \(fileDir) fileContent: \"\(contentToPrint)\", includeDirs:\(includeDirs), includedFiles: \(includedFiles)"
        return s
    }
    
    public func prettyPrint(ident: Int = 0) {
        let pref = "\(ident): "
        print("\(pref)=== ParsedSudoers: \(filePath) size: (\(fileContent.utf8.count)) at \(fileDir)")
        includeDirs.forEach {
            print("\(pref)includeDir: \($0)")
        }
        //print("included files: \(includedFiles.count)")
        includedFiles.forEach {
            $0.prettyPrint(ident: ident + 1)
        }
        print("\(pref)===")
    }
}

func standardizingInclude(include: String, dir: String) -> String {
    let inclFile = include as NSString
    if !inclFile.isAbsolutePath {
        return NSString.path(withComponents:[dir, inclFile.standardizingPath])
    }
    return inclFile.standardizingPath
}

func extractIncludes(includes: [String]) -> (includeFiles : [String], includeDirs: [String]) {
    var files = [String]()
    var dirs = [String]()
    for incl in includes {
        if incl.starts(with: "#include ") {
            files.append(String(incl.dropFirst("#include ".utf8.count)))
        } else if incl.starts(with: "#includedir ") {
            dirs.append(String(incl.dropFirst("#includedir ".utf8.count)))
        }
    }
    return (includeFiles: files, includeDirs: dirs)
}

func collectSudoersFiles(fromDirs: [String]) -> [String] {
    let fm = FileManager.default
    var outputFiles = [String]()
    fromDirs.forEach { dir in
        if let files = try? fm.contentsOfDirectory(atPath: dir) {
            print("In dir: \(dir) read files: \(files)")
            files.forEach { file in
                outputFiles.append(standardizingInclude(include: file, dir: dir))
            }
        }
    }
    return outputFiles
}


func standardizingIncludes(includes: [String], rootDir: String) -> (includeFiles : [String], includeDirs: [String]) {
    print("includes: \(includes), rootDir: \(rootDir)")
    var files = [String]()
    var dirs = [String]()
    for incl in includes {
        if incl.starts(with: "#include ") {
            let inclFile = String(incl.dropFirst("#include ".utf8.count)) as NSString
            if !inclFile.isAbsolutePath {
                let p = NSString.path(withComponents:[rootDir, inclFile.standardizingPath])
                files.append(p)
            } else {
                files.append(inclFile.standardizingPath)
            }
        } else if incl.starts(with: "#includedir ") {
            let inclDir = String(incl.dropFirst("#includedir ".utf8.count)) as NSString
            
            dirs.append(inclDir.standardizingPath)
        }
    }
    return (includeFiles: files, includeDirs: dirs)
}

func parseSudoersFileInternal(filePath: String, alreadyParsedFiles: Set<String>) -> ParsedSudoers? {
    
    print("===== parseSudoersFile: \(filePath)")
    
    let fileDir = (filePath as NSString).deletingLastPathComponent
    
    guard let sudoersAsString = try? String(contentsOfFile: filePath, encoding: String.Encoding.utf8) else {
        print("Failed to read file: \(filePath)")
        return nil
    }
    let sudoersAsLines = sudoersAsString.split { $0.isNewline }
    
    let includesLines = sudoersAsLines.filter { $0.starts(with: "#include") }.map { String($0)}
    
    let (includeFiles, includeDirs) = extractIncludes(includes: includesLines)

    
    var prefixedIncludeFiles = includeFiles.map{ standardizingInclude(include: $0, dir: fileDir) }
    
    // Collect additional files form include directories
    prefixedIncludeFiles.append(contentsOf: collectSudoersFiles(fromDirs: includeDirs))
    
    var parsedIncludedFiles = [ParsedSudoers]()
    
    // Parse collected sudoers files
    for fullSudoersPath in prefixedIncludeFiles {
        if alreadyParsedFiles.contains(fullSudoersPath) {
            print("File \(fullSudoersPath) parsed already. Ignoring")
            continue
        }
        //let newParsedSet = alreadyParsedFiles.insert(fullSudoersPath)
        if let parsedSudoers = parseSudoersFileInternal(filePath: fullSudoersPath, alreadyParsedFiles: alreadyParsedFiles.union([fullSudoersPath])) {
            parsedIncludedFiles.append(parsedSudoers)
        }
    }

    return ParsedSudoers(filePath: filePath,
                         fileDir: fileDir,
                         fileContent: sudoersAsString,
                         includeDirs: includeDirs,
                         includedFiles: parsedIncludedFiles)
}


func parseSudoersFile(filePath: String) -> ParsedSudoers? {
    return parseSudoersFileInternal(filePath: filePath, alreadyParsedFiles: [filePath])
}
    
func main() -> Int32 {
    let cwdPath = FileManager.default.currentDirectoryPath
    print("cwdPath: \(cwdPath)")
    let rootPath = "\(cwdPath)/Tests"
    let sudoersPath = "/etc/sudoers"
    
    let fullSudoersPath = "\(rootPath)\(sudoersPath)"
    
    print("Run SudoersParser on '\(fullSudoersPath)'")
    
    let f = standardizingInclude(include: "sudoers.local", dir: "/etc")
    assert(f == "/etc/sudoers.local")
    
    let incls = ["#include sudoers.local", "#include sudoers1.local", "#includedir /private/etc/sudoers.d"]
    let (includeFiles, includeDirs) = extractIncludes(includes: incls)
    print(includeFiles, includeDirs)
    assert(includeFiles.count == 2)
    assert(includeDirs.count == 1)

    print("===================  End of tests ================")
    
    
    guard let parsedSudoers = parseSudoersFile(filePath: fullSudoersPath) else {
        print("guard fails")
        return 1
    }
    
    print("---------------------------")
    
    print("parsedSudoers: \(parsedSudoers.prettyPrint())")
      
    return 0
}

exit(main())


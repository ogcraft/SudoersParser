import Foundation

public func parseSudoers(sudoersPath: String) -> (includes: Set<String>, includeDirs: Set<String>)? {
    guard let parsedSudoers = parseSudoersFile(filePath: sudoersPath) else {
        //print("guard fails")
        return nil
    }
    return getIncludedFilesAndDirs(sudoers: parsedSudoers)
}

///////////////  Internal implementation

fileprivate struct ParsedSudoers : CustomStringConvertible {
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
}



fileprivate func getIncludedFilesAndDirs(sudoers: ParsedSudoers) -> (includes: Set<String>, includeDirs: Set<String>) {
    var includesTmp: Set<String>  = [sudoers.filePath]
    var includesDirs: Set<String> = []
    sudoers.includedFiles.forEach {
        let (fls, dirs) = getIncludedFilesAndDirs(sudoers: $0)
        includesTmp.formUnion(fls)
        includesDirs.formUnion(dirs)
    }
    includesDirs.formUnion(sudoers.includeDirs)
    return (includesTmp, includesDirs)
}


fileprivate func standardizingInclude(include: String, dir: String) -> String {
    let inclFile = include as NSString
    if !inclFile.isAbsolutePath {
        return NSString.path(withComponents:[dir, inclFile.standardizingPath])
    }
    return inclFile.standardizingPath
}


fileprivate func extractIncludes(includes: [String]) -> (includeFiles : [String], includeDirs: [String]) {
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

fileprivate func collectSudoersFiles(fromDirs: [String]) -> [String] {
    let fm = FileManager.default
    var outputFiles = [String]()
    fromDirs.forEach { dir in
        if let files = try? fm.contentsOfDirectory(atPath: dir) {
            files.forEach { file in
                outputFiles.append(standardizingInclude(include: file, dir: dir))
            }
        }
    }
    return outputFiles
}

fileprivate func parseSudoersFileInternal(filePath: String, alreadyParsedFiles: Set<String>) -> ParsedSudoers? {
    let fileDir = (filePath as NSString).deletingLastPathComponent
    
    guard let sudoersAsString = try? String(contentsOfFile: filePath, encoding: String.Encoding.utf8) else {
        print("Failed to read file: \(filePath)")
        return nil
    }
    let sudoersAsLines = sudoersAsString.split { $0.isNewline }
    
    let includesLines = sudoersAsLines.filter { $0.starts(with: "#include") }.map { String($0)}
    
    let (includeFiles, includeDirs) = extractIncludes(includes: includesLines)

    
    var prefixedIncludeFiles = includeFiles.map{ standardizingInclude(include: $0, dir: fileDir) }
    let prefixedIncludeDirs = includeDirs.map{ standardizingInclude(include: $0, dir: fileDir) }
    
    // Collect additional files form include directories
    prefixedIncludeFiles.append(contentsOf: collectSudoersFiles(fromDirs: prefixedIncludeDirs))
    
    var parsedIncludedFiles = [ParsedSudoers]()
    
    // Parse collected sudoers files
    for fullSudoersPath in prefixedIncludeFiles {
        if alreadyParsedFiles.contains(fullSudoersPath) {
            //print("File \(fullSudoersPath) parsed already. Ignoring")
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
                         includeDirs: prefixedIncludeDirs,
                         includedFiles: parsedIncludedFiles)
}


fileprivate func parseSudoersFile(filePath: String) -> ParsedSudoers? {
    return parseSudoersFileInternal(filePath: filePath, alreadyParsedFiles: [filePath])
}


////////////// Trest function

func testParseSudoers() -> Int32 {
    let cwdPath = FileManager.default.currentDirectoryPath
    print("cwdPath: \(cwdPath)")
    let rootPath = "\(cwdPath)/Tests"
    let sudoersPath = "/etc/sudoers"
    
    let fullSudoersPath = "\(rootPath)\(sudoersPath)"
    
    print("Parse '\(fullSudoersPath)'")
   
    guard let (fls, dirs) = parseSudoers(sudoersPath: fullSudoersPath) else {
        print("Failed to parse file: \(fullSudoersPath)")
        return 1
    }
    
    fls.forEach {
        print("File: \($0)")
    }
    dirs.forEach {
        print("Dir : \($0)")
    }
    
    
    return 0
}

exit(testParseSudoers())


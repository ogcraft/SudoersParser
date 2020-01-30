import Foundation

public struct ParsedSudoers : CustomStringConvertible {
    public let filePath: String
    public let fileContent: String
    public let includeFiles: [String]
    public let includeDirs: [String]
   
    public var description: String {
        let contentToPrint = "Size: \(fileContent.utf8.count) bytes"
        let s = "ParsedSudoers(filePath: \"\(filePath)\", fileContent: \"\(contentToPrint)\", includeFiles:\(includeFiles) includeDirs:\(includeDirs)"
        return s
    }
}

func parseIncludes(includes: [String], rootDir: String) -> (includeFiles : [String], includeDirs: [String]) {
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

func parseSudoersFile(filePath: String) -> ParsedSudoers? {
    
    let sudoersDir = (filePath as NSString).deletingLastPathComponent
    
    guard let sudoersAsString = try? String(contentsOfFile: filePath, encoding: String.Encoding.utf8) else {
        print("Failed to read file: \(filePath)")
        return nil
    }
    let sudoersAsLines = sudoersAsString.split { $0.isNewline }
    
    let includes = sudoersAsLines.filter { $0.starts(with: "#include") }.map { String($0)}
    
    let (includeFiles, includeDirs) = parseIncludes(includes: includes, rootDir: sudoersDir)
    
    return ParsedSudoers(filePath: filePath,
                         fileContent: sudoersAsString,
                         includeFiles: includeFiles,
                         includeDirs: includeDirs)
}

func main() -> Int32 {
    let rootPath = "Tests"
    let sudoersPath = "/etc/sudoers"
    
    let fullSudoersPath = "\(rootPath)\(sudoersPath)"
    
    print("Run SudoersParser on '\(fullSudoersPath)'")
    
    guard let parsedSudoers = parseSudoersFile(filePath: fullSudoersPath) else {
        print("guard fails")
        return 1
    }
    
    print("parsedSudoers: \(parsedSudoers)")
    
    print("---------------------------")
    
    return 0
}

exit(main())


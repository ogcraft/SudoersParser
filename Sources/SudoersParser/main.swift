import Foundation

public struct ParsedSudoers : CustomStringConvertible {
    public let fileName: String
    public let fileContent: String
    public let includeFiles: [String]
    public let includeDirs: [String]
   
    public var description: String {
        let contentToPrint = "Size: \(fileContent.utf8.count) bytes"
        let s = "ParsedSudoers(fileName: \"\(fileName)\", fileContent: \"\(contentToPrint)\", includeFiles:\(includeFiles) includeDirs:\(includeDirs)"
        return s
    }
}

func parseIncludes(includes: [String], rootDir: String) -> (includeFiles : [String], includeDirs: [String]) {
    var files = [String]()
    var dirs = [String]()
    for incl in includes {
        if incl.starts(with: "#include ") {
            let inclFile = String(incl.dropFirst("#include ".utf8.count))
            files.append(inclFile)
        } else if incl.starts(with: "#includedir ") {
            let inclDir = String(incl.dropFirst("#includedir ".utf8.count))
            dirs.append(inclDir)
        }
    }
    return (includeFiles: files, includeDirs: dirs)
}

func parseSudoersFile(fileName: String) -> ParsedSudoers? {
    
    guard let sudoersAsString = try? String(contentsOfFile: fileName, encoding: String.Encoding.utf8) else {
        print("Failed to read file: \(fileName)")
        return nil
    }
    let sudoersAsLines = sudoersAsString.split { $0.isNewline }
    
    let includes = sudoersAsLines.filter { $0.starts(with: "#include") }.map { String($0)}
    
    print(includes)
   
    let (includeFiles, includeDirs) = parseIncludes(includes: includes, rootDir: "")
    return ParsedSudoers(fileName: fileName,
                         fileContent: sudoersAsString,
                         includeFiles: includeFiles,
                         includeDirs: includeDirs)
}

func main() -> Int32 {
    let rootPath = "Tests"
    let sudoersPath = "/etc/sudoers"
    
    let fullSudoersPath = "\(rootPath)\(sudoersPath)"
    
    print("Run SudoersParser on '\(fullSudoersPath)'")
    
    guard let parsedSudoers = parseSudoersFile(fileName: fullSudoersPath) else {
        print("guard fails")
        return 1
    }
    
    print("parsedSudoers: \(parsedSudoers)")
    
    print("---------------------------")
    
    return 0
}

exit(main())


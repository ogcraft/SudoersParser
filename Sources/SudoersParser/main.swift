import Foundation

func main() -> Int32 {
    let rootPath = "Tests"
    let sudoersPath = "/etc/sudoers"
    
    let fullSudoersPath = "\(rootPath)\(sudoersPath)"
    
    print("Run SudoersParser on '\(fullSudoersPath)'")
    
    guard let sudoersAsString = try? String(contentsOfFile: fullSudoersPath, encoding: String.Encoding.utf8) else {
        print("Failed to read file: \(fullSudoersPath)")
        return 0
    }
    
    print("---------------------------")
    
    return 0
}

exit(main())

struct ParsedSudoers {
    let fileName: String
    let fileContent: String
    let includeFiles: [String]
    let includeDirs: [String]
}

func parseSudoersFile(fileName: String) -> ParsedSudoers {

    return ParsedSudoers(fileName: fileName, 
                        fileContent: "", 
                        includeFiles: [], 
                        includeDirs: [])
}
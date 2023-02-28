import Foundation
import ArgumentParser

@main
struct proj_info: ParsableCommand {
    @Argument(help: "The directory to scan for swift files")
    var scanDir: String
    
    @Flag(name: .customLong("show-locs"), help: "Display lines of codes within the directory to scan")
    var showLinesOfCodes: Bool = false
    
    @Option(name: .long, help: "Output path where to store info in a JSON file")
    var outputPath: String?
    
    mutating func run() throws {
        let swiftFiles = try Self.getSwiftFiles(atPath: scanDir)
        let swiftLocs: Int? =  {
            guard showLinesOfCodes else {
                return nil
            }
            let filePaths = swiftFiles.map { fileName in
                "\(scanDir)/\(fileName)"
            }
            return Self.getLinesOfCode(filePaths)
        }()
        if let outputPath = outputPath {
            try Self.saveInfo(scanDir,
                              swiftFilesCount: swiftFiles.count,
                              linesOfCode: swiftLocs,
                              outputPath: outputPath)
        } else {
            print("Number of Swift Files \(swiftFiles.count)")
            if let swiftLocs = swiftLocs {
                print("Number of Swift Lines of Codes \(swiftLocs)")
            }
        }
    }
    
    private static func getSwiftFiles(atPath path: String) throws -> [String] {
        let fileManager = FileManager.default
        var isDir: ObjCBool = ObjCBool(false)
        guard fileManager.fileExists(atPath: path, isDirectory: &isDir) else {
            throw ProjInfoError.dirDoesNotExist(path: path)
        }
        guard isDir.boolValue else {
            throw ProjInfoError.pathNotADir(path: path)
        }
        let files = try fileManager
            .contentsOfDirectory(atPath: path)
            .map({ URL(fileURLWithPath: $0) })
            .filter({ $0.pathExtension == "swift" })
            .map({ $0.relativeString })
        return files
    }
    
    private static func getLinesOfCode(_ swiftFiles: [String]) -> Int {
        swiftFiles.map { filePath -> String? in
            guard let data = FileManager.default.contents(atPath: filePath) else {
                return nil
            }
            return String(data: data, encoding: .utf8)
        }
        .compactMap { $0 }
        .map { swiftFileContents -> Int in
            swiftFileContents
                .components(separatedBy: .newlines)
                .map({ $0.trimmingCharacters(in: .whitespaces) })
                .filter({ !$0.isEmpty })
                .count
        }
        .reduce(0, +)
    }
    
    private static func saveInfo(_ dirPath: String,
                                 swiftFilesCount: Int,
                                 linesOfCode: Int? = nil,
                                 outputPath: String) throws {
        let outputDirPathURL = URL(fileURLWithPath: outputPath).deletingLastPathComponent()
        let outputDirPath = outputDirPathURL.relativePath
        var isDir = ObjCBool(false)
        let pathExists = FileManager.default.fileExists(atPath: outputDirPath, isDirectory: &isDir)
        if !pathExists {
            try FileManager.default.createDirectory(at: outputDirPathURL, withIntermediateDirectories: true)
        } else if pathExists, isDir.boolValue {
            fatalError("path \(outputDirPath) exists but is not a directory")
        }
        let info = Info(
            path: dirPath,
            swiftFileCount: swiftFilesCount,
            linesOfCode: linesOfCode
        )
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        let data = try jsonEncoder.encode(info)
        FileManager.default.createFile(atPath: outputPath, contents: data)
    }
}

struct Info: Codable {
    let path: String
    let swiftFileCount: Int
    let linesOfCode: Int?
}

enum ProjInfoError: Error {
    case dirDoesNotExist(path: String)
    case pathNotADir(path: String)
}

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

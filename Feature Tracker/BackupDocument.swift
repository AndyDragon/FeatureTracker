//
//  BackupDocument.swift
//  Vero Scripts Editor
//
//  Created by Andrew Forget on 2025-02-07.
//

import SwiftUI
import UniformTypeIdentifiers

struct BackupDocument: FileDocument {
    static var readableContentTypes = [UTType.json]
    var text = ""

    init() { }

    init(pages: [CodablePage]) {
        do {
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = [.sortedKeys, .prettyPrinted]
            jsonEncoder.dateEncodingStrategy = .iso8601
            let json = try jsonEncoder.encode(pages)
            text = String(decoding: json, as: UTF8.self)
        } catch {
            debugPrint(error)
        }
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}

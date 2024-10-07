//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 25/03/2024.
//

@preconcurrency import ArgumentParser
import PoieticCore
import PoieticFlows
import Foundation


extension PoieticTool {
    struct CreateLibrary: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                commandName: "create-library",
                abstract: "Create a library description for multiple models",
                discussion: """
The command creates a library description from a given list of design files (not a Poietic frame file).

Command extracts DesignInfo from the designs. If multiple instances of DesignInfo are present, then one is chosen arbitrarily.
""")

        @Option(name: [.long, .customShort("o")], help: "Output library file")
        var outputFile: String = "poietic-library.json"

        @Argument(help: "Paths to designs to be referenced by the library")
        var designs: [String]

        mutating func run() throws {
            var items: [DesignLibraryItem] = []
            for location in designs {
                let item = try createLibraryItem(fromDesignAt: location)
                items.append(item)
            }

            let library = DesignLibraryInfo(items: items)
            
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let data: Data
            do {
                data = try encoder.encode(library)
            }
            
            try data.write(to: URL(fileURLWithPath: outputFile))
            print("Created library: \(outputFile)")
            // TODO: Catch the error and present beautifully
        }
        
    }
}

func createLibraryItem(fromDesignAt location: String) throws -> DesignLibraryItem {
    // TODO: Add BibliographicalReferences
    guard let url = URL(string: location) else {
        throw ToolError.malformedLocation(location)
    }
    
    let actualURL = if url.scheme == nil {
        URL(fileURLWithPath: location, isDirectory: false).absoluteURL
    }
    else {
        url
    }

    var env = ToolEnvironment(url: actualURL)
    let design = try env.open()
    let frame = design.currentFrame

    let info = frame.filter(type: ObjectType.DesignInfo).first?.attributes ?? [:]
    
    let name: String
    if let infoName = try? info["name"]?.stringValue() {
        name = infoName
    }
    else {
        name = actualURL.lastPathComponent
    }

    try env.close()
    
    return DesignLibraryItem(
        url: actualURL,
        name: name,
        title: (try? info["title"]?.stringValue()) ?? name
    )
}

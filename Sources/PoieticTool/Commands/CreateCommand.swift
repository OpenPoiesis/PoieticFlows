//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 11/01/2022.
//

import ArgumentParser
import PoieticFlows
import PoieticCore

extension PoieticTool {
    struct CreateDB: ParsableCommand {
        static var configuration
        = CommandConfiguration(
            commandName: "new",
            abstract: "Create an empty design."
        )
        
        @OptionGroup var options: Options

        @Option(name: [.customLong("import"), .customShort("i")],
                help: "Poietic frame to import into the first frame.")
        var importPaths: [String] = []

        @Flag(name: [.customLong("auto-parameters")],
                help: "Automatically connect parameter nodes")
        var autoParameters: Bool = false
        
        mutating func run() throws {
            let memory = createMemory(options: options)

            if !importPaths.isEmpty {
                let frame = memory.createFrame()
                for path in importPaths {
                    let bundle = try ForeignFrameBundle(path: path)
                    // TODO: Should we share the reader?
                    let reader = ForeignFrameReader(info: bundle.info, memory: frame.memory)
                    
                    print("Importing from: \(path)")
                    for name in bundle.collectionNames {
                        let objects = try bundle.objects(in: name)
                        try reader.read(objects, into: frame)
                        print("Read \(objects.count) objects from collection '\(name)'")
                    }
                }
                
                if autoParameters {
                    let result = try autoConnectParameters(frame)
                    if result.added.count + result.removed.count > 0 {
                        print("Added \(result.added.count) parameter edges and removed \(result.removed.count) edges.")
                    }
                    else {
                        print("All parameter connections seem to be ok.")
                    }
                }
                
                try acceptFrame(frame, in: memory)
            }
            
            try closeMemory(memory: memory, options: options)
            print("Design created.")
        }
    }
}


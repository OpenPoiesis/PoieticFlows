//
//  Import.swift
//  
//
//  Created by Stefan Urbanek on 14/08/2023.
//

import ArgumentParser
import PoieticCore
import PoieticFlows

// TODO: Merge with PrintCommand, use --format=id
extension PoieticTool {
    struct Import: ParsableCommand {
        static var configuration
            = CommandConfiguration(abstract: "Import a frame bundle into the design")
        @OptionGroup var options: Options

        @Argument(help: "Path to a frame bundle to import")
        var fileName: String
        
        mutating func run() throws {
            let memory = try openMemory(options: options)
            let frame = memory.deriveFrame()
            
            let bundle = try ForeignFrameBundle(path: fileName)
            let reader = ForeignFrameReader(info: bundle.info, memory: memory)

            for name in bundle.collectionNames {
                let objects = try bundle.objects(in: name)
                try reader.read(objects, into: frame)
                print("Read \(objects.count) objects from collection '\(name)'")
            }
            try acceptFrame(frame, in: memory)
            try closeMemory(memory: memory, options: options)

//            print("Current frame ID: \(memory.currentFrame.id)")
        }
    }
}


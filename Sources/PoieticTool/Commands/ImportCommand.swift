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
            = CommandConfiguration(abstract: "Import a frame into the design")
        @OptionGroup var options: Options

        @Argument(help: "Path to a frame bundle to import")
        var fileName: String
        
        mutating func run() throws {
            let design = try openDesign(options: options)
            let frame = design.deriveFrame()
            
            let bundle = try ForeignFrameBundle(path: fileName)
            let reader = ForeignFrameReader(info: bundle.info, design: design)

            for name in bundle.collectionNames {
                let objects = try bundle.objects(in: name)
                try reader.read(objects, into: frame)
                print("Read \(objects.count) objects from collection '\(name)'")
            }
            try acceptFrame(frame, in: design)
            try closeDesign(design: design, options: options)
        }
    }
}


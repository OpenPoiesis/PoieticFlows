//
//  Import.swift
//  
//
//  Created by Stefan Urbanek on 14/08/2023.
//

@preconcurrency import ArgumentParser
import Foundation
import PoieticCore
import PoieticFlows



// TODO: Merge with PrintCommand, use --format=id
extension PoieticTool {
    struct Import: ParsableCommand {
        static let configuration
            = CommandConfiguration(abstract: "Import a frame into the design")
        @OptionGroup var options: Options

        @Argument(help: "Path to a frame bundle to import")
        var fileName: String
        
        mutating func run() throws {
            let env = try ToolEnvironment(location: options.designLocation)
            let design = try env.open()
            let frame = design.deriveFrame()
            
            let loader = ForeignFrameLoader()
            let foreignFrame = try readFrame(fromPath: fileName)
            do {
                try loader.load(foreignFrame, into: frame)
            }
            catch {
                throw ToolError.frameLoadingError(error)
            }

            try env.accept(frame)
            try env.close()
        }
    }
}


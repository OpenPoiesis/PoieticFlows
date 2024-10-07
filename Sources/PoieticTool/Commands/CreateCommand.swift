//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 11/01/2022.
//

@preconcurrency import ArgumentParser
import PoieticFlows
import PoieticCore

extension PoieticTool {
    struct CreateDB: ParsableCommand {
        static let configuration
        = CommandConfiguration(
            commandName: "new",
            abstract: "Create an empty design."
        )
        
        @Option(name: [.customLong("import"), .customShort("i")],
                help: "Poietic frame to import into the first frame.")
        var importPaths: [String] = []

        // FIXME: [REFACTORING] add domains + metamodel
        
        @Argument(help: "Path of design file to be created")
        var location: String = DefaultDesignLocation

        mutating func run() throws {
            let design = Design(metamodel: FlowsMetamodel)
            let env = try ToolEnvironment(location: location, design: design)

            if !importPaths.isEmpty {
                let loader = ForeignFrameLoader()
                let frame = design.createFrame()

                for path in importPaths {
                    let foreignFrame = try readFrame(fromPath: path)
                    print("Importing from: \(path)")
                    do {
                        try loader.load(foreignFrame, into: frame)
                    }
                    catch {
                        throw ToolError.frameLoadingError(error)
                    }
                }
                
                try env.accept(frame)
            }
            
            try env.close()
            print("Design created: \(env.url)")
        }
    }
}


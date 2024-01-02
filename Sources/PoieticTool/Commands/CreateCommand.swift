//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 11/01/2022.
//

import Foundation
import ArgumentParser
import PoieticFlows

extension PoieticTool {
    struct CreateDB: ParsableCommand {
        static var configuration
        = CommandConfiguration(
            commandName: "new",
            abstract: "Create an empty design."
        )
        
        @OptionGroup var options: Options
        
        @Flag(name: [.long],
                help: "Include demo model")
        var includeDemo: Bool = false

        
        mutating func run() throws {
            let memory = createMemory(options: options)
            
            if includeDemo {
                try CreatePredatorPreyDemo(in: memory)
            }
            
            try closeMemory(memory: memory, options: options)
            print("Database created.")
        }
    }
}

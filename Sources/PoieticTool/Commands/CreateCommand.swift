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
        
        mutating func run() throws {
            let memory = createMemory(options: options)
            
            try closeMemory(memory: memory, options: options)
            print("Database created.")
        }
    }
}

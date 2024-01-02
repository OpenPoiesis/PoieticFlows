//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 04/07/2023.
//

import ArgumentParser
import PoieticCore
import PoieticFlows

extension PoieticTool {
    struct Undo: ParsableCommand {
        static var configuration
            = CommandConfiguration(
                abstract: "Undo last change"
            )

        @OptionGroup var options: Options

        mutating func run() throws {
            let memory = try openMemory(options: options)
            
            if !memory.canUndo {
                throw ToolError.noChangesToUndo
            }
            
            let frameID = memory.undoableFrames.last!
            
            memory.undo(to: frameID)

            try closeMemory(memory: memory, options: options)
            print("Did undo")
//            print("Current frame ID: \(memory.currentFrame.id)")
        }
    }

}

extension PoieticTool {
    struct Redo: ParsableCommand {
        static var configuration
            = CommandConfiguration(
                abstract: "Redo undone change"
            )

        @OptionGroup var options: Options

        mutating func run() throws {
            let memory = try openMemory(options: options)
            
            if !memory.canRedo {
                throw ToolError.noChangesToRedo
            }
            
            let frameID = memory.redoableFrames.first!
            
            memory.redo(to: frameID)

            try closeMemory(memory: memory, options: options)
            print("Did redo.")
//            print("Current frame ID: \(memory.currentFrame.id)")
        }
    }

}

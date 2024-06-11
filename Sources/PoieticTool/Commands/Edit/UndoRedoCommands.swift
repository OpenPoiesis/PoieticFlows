//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 04/07/2023.
//

@preconcurrency import ArgumentParser
import PoieticCore
import PoieticFlows

extension PoieticTool {
    struct Undo: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                abstract: "Undo last change"
            )

        @OptionGroup var options: Options

        mutating func run() throws {
            let design = try openDesign(options: options)
            
            if !design.canUndo {
                throw ToolError.noChangesToUndo
            }
            
            let frameID = design.undoableFrames.last!
            
            design.undo(to: frameID)

            try closeDesign(design: design, options: options)
            print("Did undo")
//            print("Current frame ID: \(design.currentFrame.id)")
        }
    }

}

extension PoieticTool {
    struct Redo: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                abstract: "Redo undone change"
            )

        @OptionGroup var options: Options

        mutating func run() throws {
            let design = try openDesign(options: options)
            
            if !design.canRedo {
                throw ToolError.noChangesToRedo
            }
            
            let frameID = design.redoableFrames.first!
            
            design.redo(to: frameID)

            try closeDesign(design: design, options: options)
            print("Did redo.")
//            print("Current frame ID: \(design.currentFrame.id)")
        }
    }

}

//
//  DescribeCommand.swift
//
//
//  Created by Stefan Urbanek on 29/06/2023.
//

import Foundation
import ArgumentParser
import PoieticCore
import PoieticFlows

/// Width of the attribute label column for right-aligned display.
///
let AttributeColumnWidth = 20

extension PoieticTool {
    struct Show: ParsableCommand {
        static var configuration
            = CommandConfiguration(abstract: "Describe an object")
        @OptionGroup var options: Options

        @Argument(help: "ID of an object to be described")
        var reference: String
        
        mutating func run() throws {
            let memory = try openMemory(options: options)
            if memory.isEmpty {
                throw CleanExit.message("The design memory is empty.")
            }

            let frame = memory.currentFrame
            
            guard let object = frame.object(stringReference: reference) else {
                throw ToolError.unknownObject(reference)
            }
            
            var items: [(String?, String?)] = [
                ("Type", "\(object.type.name)"),
                ("Object ID", "\(object.id)"),
                ("Snapshot ID", "\(object.snapshotID)"),
                ("Structure", "\(object.structure.type)"),
            ]
            
            var seenAttributes: [String] = []
            
            for trait in object.type.traits {
                items.append((nil, nil))
                items.append((trait.label, nil))

                for attr in trait.attributes {
                    let rawValue = object.attribute(forKey: attr.name)
                    let displayValue: String
                    if let rawValue {
                        displayValue = String(describing: rawValue)
                    }
                    else {
                        displayValue = "(no value)"
                    }

                    items.append((attr.name, displayValue))
                    seenAttributes.append(attr.name)
                }
            }
            
            var orphanedItems: [(String?, String?)]  = []

            for item in object.attributes {
                let (name, value) = item
                if seenAttributes.contains(name) {
                    continue
                }
                let displayValue = String(describing: value)

                orphanedItems.append((name, displayValue))
            }
            
            if !orphanedItems.isEmpty {
                items.append((nil, nil))
                items.append(("Extra attributes", ""))
                items += orphanedItems
            }
            
            if items.isEmpty {
                print("Object has no attributes.")
            }
            else {
                let formattedItems = formatLabelledList(items,
                                                        labelWidth: AttributeColumnWidth)
                
                for item in formattedItems {
                    print(item)
                }
            }

        }
    }
}


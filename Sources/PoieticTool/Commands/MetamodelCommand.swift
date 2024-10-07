//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 30/06/2023.
//

@preconcurrency import ArgumentParser
import PoieticCore

// TODO: Add output to JSON
// TODO: Add output to CSV

extension PoieticTool {
    struct MetamodelCommand: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                commandName: "metamodel",
                abstract: "Show information about the metamodel and object types"
            )

        @OptionGroup var options: Options
        
        @Argument(help: "Object type to show")
        var objectType: String?

        mutating func run() throws {
            var env = try ToolEnvironment(location: options.designLocation)
            let design = try env.open()
            let metamodel = design.metamodel
            
            if let typeName = objectType {
                guard let type = metamodel.objectType(name: typeName) else {
                    throw ToolError.unknownObjectType(typeName)
                }
                
                try printType(type,
                              includeAbstract: true,
                              metamodel: metamodel)
            }
            else {
                try printAll(metamodel: metamodel)
            }
            try env.close()
        }
        
        func printAll(metamodel: Metamodel) throws {
            print("TYPES AND COMPONENTS\n")

            for type in metamodel.types {
                try printType(type,
                              includeAbstract: false,
                              metamodel: metamodel)
                print("")
            }
            
            print("\nCONSTRAINTS\n")
            
            for constr in metamodel.constraints {
                print("\(constr.name): \(constr.abstract ?? "(no description)")")
            }
            
            print("")

        }
        
        func printType(_ type: ObjectType,
                       includeAbstract: Bool = false,
                       metamodel: Metamodel) throws {
            print("\(type.name) (\(type.structuralType))")

            if type.traits.isEmpty {
                print("    (no components)")
            }
            else {
                for attr in type.attributes {
                    if let abstract = attr.abstract, includeAbstract{
                        print("    \(attr.name) (\(attr.type))")
                        print("        - \(abstract)")
                    }
                    else {
                        print("    \(attr.name) (\(attr.type))")
                    }
                }
            }
        }

    }

}

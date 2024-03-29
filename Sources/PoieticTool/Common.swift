//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 06/01/2022.
//

import Foundation
import ArgumentParser
import PoieticCore
import PoieticFlows
import SystemPackage

/// Error thrown by the command-line tool.
///
enum ToolError: Error, CustomStringConvertible {
    // I/O errors
    case malformedLocation(String)
    case unableToSaveDatabase(Error)
    
    // Database errors
    case validationError(FrameValidationError)
    
    // Simulation errors
    case unknownObjectName(String)
    case unknownVariables([String])
    case unknownSolver(String)
    case compilationError
    case constraintError
    
    // Query errors
    case malformedObjectReference(String)
    case unknownObject(String)
    case nodeExpected(String)

    // Editing errors
    case noChangesToUndo
    case noChangesToRedo
    case creatingSystemPlaneType(String)
    case structuralTypeMismatch(String, String)
    // Metamodel errors
    case unknownObjectType(String)
    
    case invalidAttributeAssignment(String)
    case typeMismatch(String, String, String)

    public var description: String {
        switch self {
        case .malformedLocation(let value):
            return "Malformed location: \(value)"
        case .unableToSaveDatabase(let value):
            return "Unable to save database. Reason: \(value)"

        case .validationError(let error):
            var detail: String = ""
            if !error.violations.isEmpty {
                detail += "\(error.violations.count) constraint violation errors"
            }
            if !error.typeErrors.isEmpty {
                detail += "\(error.typeErrors.count) objects with type errors"
            }
            if detail == "" {
                detail = "unspecified validation error(s)"
            }
            return "Database validation failed: \(detail)"
            
        case .unknownSolver(let value):
            return "Unknown solver '\(value)'"
        case .unknownObjectName(let value):
            return "Unknown object with name '\(value)'"
        case .unknownVariables(let names):
            let varlist = names.joined(separator: ", ")
            return "Unknown variables: \(varlist)"
        case .compilationError:
            return "Design compilation failed"
        case .constraintError:
            return "Model constraint violation"
        case .malformedObjectReference(let value):
            return "Malformed object reference '\(value). Use either object ID or object identifier."
        case .unknownObject(let value):
            return "Unknown object with reference: \(value)"
        case .noChangesToUndo:
            return "No changes to undo"
        case .noChangesToRedo:
            return "No changes to re-do"
        case .creatingSystemPlaneType(let value):
            return "Trying to create an object of type '\(value)'. It can be created only by the system"
        case .structuralTypeMismatch(let given, let expected):
            return "Mismatch of structural type. Expected: \(expected), given: \(given)"
        case .unknownObjectType(let value):
            return "Unknown object type '\(value)'"
        case .nodeExpected(let value):
            return "Object is not a node: '\(value)'"
            
        case .invalidAttributeAssignment(let value):
            return "Invalid attribute assignment: \(value)"
        case .typeMismatch(let subject, let value, let expected):
            return "Type mismatch in \(subject) value '\(value)', expected type: \(expected)"
        }
    }
    
    public var hint: String? {
        // NOTE: Keep this list without 'default' so we know which cases we
        //       covered.
        
        switch self {
        case .malformedLocation(_):
            return nil
        case .unableToSaveDatabase(_):
            return "Check whether the location is correct and that you have permissions for writing."

        case .validationError(_):
            return "Unfortunately the only way is to inspect the database file. 'doctor' command is not yet implemented."
            
        case .unknownSolver(_):
            return "Check the list of available solvers by running the 'info' command."
        case .unknownObjectName(_):
            return "See the list of available names by using the 'list' command."
        case .unknownVariables(_):
            return "See the list of available simulation variables using the 'list' command."
        case .compilationError:
            return nil
        case .constraintError:
            return nil
        case .malformedObjectReference(_):
            return "Use either object ID or object identifier."
        case .unknownObject(_):
            return nil
        case .noChangesToUndo:
            return nil
        case .noChangesToRedo:
            return nil
        case .creatingSystemPlaneType(_):
            return "Users can not create objects of this type, they can only read it."
        case .structuralTypeMismatch(_, _):
            return "See the metamodel to know structural type of the object type."
        case .unknownObjectType(_):
            return "See the metamodel for a list of known object types."
        case .nodeExpected(_):
            return nil
        case .invalidAttributeAssignment(_):
            return "Attribute assignment should be in a form: `attribute_name=value`, everything after '=' is considered a value. Ex.: `name=account`, `formula=fish * 10`."
        case .typeMismatch(_, _, _):
            return nil
        }
    }

}

let defaultDatabase = "design.poietic"
let databaseEnvironment = "POIETIC_DESIGN"

/// Get the database URL. The database location can be specified by options,
/// environment variable or as a default name, in respective order.
func databaseURL(options: Options? = nil) throws -> URL {
    let location: String
    let env = ProcessInfo.processInfo.environment
    
    if let path = options?.database {
        location = path
    }
    else if let path = env[databaseEnvironment] {
        location = path
    }
    else {
        location = defaultDatabase
    }
    
    if let url = URL(string: location) {
        if url.scheme == nil {
            return URL(fileURLWithPath: location, isDirectory: false)
        }
        else {
            return url
        }
    }
    else {
        throw ToolError.malformedLocation(location)
    }
}

/// Create a new empty memory.
///
func createMemory(options: Options) -> ObjectMemory {
    return ObjectMemory(metamodel: FlowsMetamodel)
}

func openMemory(url: URL, metamodel: Metamodel = FlowsMetamodel) throws -> ObjectMemory {
    let memory: ObjectMemory = ObjectMemory(metamodel: metamodel)
    do {
        try memory.restoreAll(from: url)
    }
    catch let error as FrameValidationError {
        printValidationError(error)
        throw ToolError.validationError(error)
        
    }
    return memory
}

/// Opens a graph from a package specified in the options.
///
func openMemory(options: Options? = nil, metamodel: Metamodel = FlowsMetamodel) throws -> ObjectMemory {
    let dataURL = try databaseURL(options: options)
    return try openMemory(url: dataURL, metamodel: metamodel)
}

func printValidationError(_ error: FrameValidationError) {
    // FIXME: Print to stderr
    for violation in error.violations {
        let objects = violation.objects.map { String($0) }.joined(separator: ",")
        print("Constraint error: \(violation.constraint.name) object IDs: \(objects)")
        if let abstract = violation.constraint.abstract {
            print("    - \(abstract)")
        }
    }
    for item in error.typeErrors {
        let (id, typeErrors) = item
        for typeError in typeErrors {
            print("Type error (id:\(id)): \(typeError)")
        }
    }
}

/// Finalise operations on the design memory and save the memory to its store.
///
func closeMemory(memory: ObjectMemory, options: Options) throws {
    let dataURL = try databaseURL(options: options)

    do {
        try memory.saveAll(to: dataURL)
    }
    catch {
        throw ToolError.unableToSaveDatabase(error)
    }
}

/// Try to accept a frame in a memory.
///
/// Tries to accept the frame. If the frame contains constraint violations, then
/// the violations are printed out in a more human-readable format.
///
func acceptFrame(_ frame: MutableFrame, in memory: ObjectMemory) throws {
    // TODO: Print on stderr
    
    do {
        try memory.accept(frame)
    }
    catch let error as FrameValidationError {
        printValidationError(error)

        throw ToolError.constraintError
    }
}

func compile(_ frame: MutableFrame) throws -> CompiledModel {
    // NOTE: Make this in sync with the PoieticServer
    // TODO: Use stderr as output
    let compiledModel: CompiledModel
    do {
        let compiler = Compiler(frame: frame)
        compiledModel = try compiler.compile()
    }
    catch let error as NodeIssuesError {
        for (id, issues) in error.issues {
            for issue in issues {
                let object = frame.object(id)
                let label: String
                if let name = object.name {
                    label = "\(id)(\(name))"
                }
                else {
                    label = "\(id)"
                }

                print("ERROR: node \(label): \(issue)")
                if let issue = issue as? NodeIssue, let hint = issue.hint {
                    print("HINT: node \(label): \(hint)")
                }
            }
        }
        throw ToolError.compilationError
    }
    return compiledModel
}

/// Parse single-string value assignment into a (attributeName, value) tuple.
///
/// The expected string format is: `attribute_name=value` where the value is
/// everything after the equals `=` character.
///
/// Returns `nil` if the string is malformed and can not be parsed.
///
/// - Note: In the future the format might change to include quotes on both sides
///         of the `=` character. Make sure to use this function instead of
///         splitting the assignment on your own.
///
func parseValueAssignment(_ assignment: String) -> (String, String)? {
    let split = assignment.split(separator: "=", maxSplits: 2)
    if split.count != 2 {
        return nil
    }
    
    return (String(split[0]), String(split[1]))
}

func setAttributeFromString(object: ObjectSnapshot,
                            attribute attributeName: String,
                            string: String) throws {
    let type = object.type
    if let attr = type.attribute(attributeName), attr.type.isArray {
        let json = try JSONValue(string: string)
        let arrayValue = try Variant.fromJSON(json)
        object.setAttribute(value: arrayValue,
                                forKey: attributeName)
    }
    else {
        object.setAttribute(value: Variant(string),
                                forKey: attributeName)
    }

}

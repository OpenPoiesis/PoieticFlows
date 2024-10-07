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

// FIXME: --vv BEGIN vv--

let DefaultDesignLocation = "design.poietic"
let DesignEnvironmentVariable = "POIETIC_DESIGN"

// FIXME: --^^ END ^^--

/// Error thrown by the command-line tool.
///
enum ToolError: Error, CustomStringConvertible {
    // FIXME: Do not have this
    case unknownError(Error)
    
    // I/O errors
    case malformedLocation(String)
    case fileDoesNotExist(String)
    case unableToSaveDesign(Error)
    case foreignFrameError(ForeignFrameError)
    
    // Database errors
    case constraintViolationError(FrameConstraintError)
    
    // Import error
//    case foreignFrameError(String, ForeignFrameError)
    
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
    case structuralTypeMismatch(String, String)
    // Metamodel errors
    case unknownObjectType(String)
    
    case invalidAttributeAssignment(String)
    case typeMismatch(String, String, String)

    case frameLoadingError(FrameLoaderError)
    
    public var description: String {
        switch self {
        case .unknownError(let error):
            return "Unknown error: \(error)"

        case .malformedLocation(let value):
            return "Malformed location: \(value)"
        case .unableToSaveDesign(let value):
            return "Unable to save design. Reason: \(value)"
        case .foreignFrameError(let error):
            return "Foreign frame error: \(error)"

        case .constraintViolationError(let error):
            var detail: String = ""
            if !error.violations.isEmpty {
                detail += "\(error.violations.count) constraint violation errors"
            }
            if !error.objectErrors.isEmpty {
                detail += "\(error.objectErrors.count) objects with errors"
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
        case .frameLoadingError(let error):
            return "Frame loading error: \(error)"
        case .fileDoesNotExist(let file):
            return "File '\(file)' not found"
        }
    }
    
    public var hint: String? {
        // NOTE: Keep this list without 'default' so we know which cases we
        //       covered.
        
        switch self {
        case .unknownError(_):
            return "Not your fault."
            
        case .malformedLocation(_):
            return nil
        case .unableToSaveDesign(_):
            return "Check whether the location is correct and that you have permissions for writing."

        case .constraintViolationError(_):
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
        case .frameLoadingError(_):
            return nil
        case .fileDoesNotExist(_):
            return nil
        case .foreignFrameError(_):
            return nil
        }
    }

}

func compile(_ frame: StableFrame) throws -> CompiledModel {
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
                let object = frame[id]
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


// Frame reading
// ====================================================================

func makeFileURL(fromPath path: String) throws (ToolError) -> URL {
    let url: URL
    let manager = FileManager()

    if !manager.fileExists(atPath: path) {
        throw .fileDoesNotExist(path)
    }
    
    // Determine whether the file is a directory or a file
    
    if let attrs = try? manager.attributesOfItem(atPath: path) {
        if attrs[FileAttributeKey.type] as? FileAttributeType == FileAttributeType.typeDirectory {
            url = URL(fileURLWithPath: path, isDirectory: true)
        }
        else {
            url = URL(fileURLWithPath: path, isDirectory: false)
        }
    }
    else {
        url = URL(fileURLWithPath: path)
    }

    return url
}

func readFrame(fromPath path: String) throws (ToolError) -> ForeignFrame {
    let reader = JSONFrameReader()
    let foreignFrame: ForeignFrame
    let url = try makeFileURL(fromPath: path)
    
    do {
        if url.hasDirectoryPath {
            foreignFrame = try reader.read(bundleAtURL: url)
        }
        else {
            foreignFrame = try reader.read(fileAtURL: url)
        }
    }
    catch {
        throw .foreignFrameError(error)
    }
    return foreignFrame
}

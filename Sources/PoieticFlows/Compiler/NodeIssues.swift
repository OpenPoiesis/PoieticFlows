//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 05/01/2023.
//

import PoieticCore


/// An aggregate error of multiple issues grouped by a node.
///
/// The ``StockFlowView`` and ``Compiler`` are trying to gather as many errors as
/// possible to be presented to the user, instead of just failing at the first
/// error found.
///
public struct NodeIssuesError: Error {
    /// Dictionary of node issues by node. The key is the node ID and the
    /// value is a list of issues.
    ///
    public internal(set) var issues: [ObjectID:[any Error]]

    var isEmpty: Bool { issues.isEmpty }
    
    init(errors: [ObjectID:[Error]] = [:]) {
        self.issues = errors
    }
    
    mutating func append(_ error: Error, for objectID: ObjectID) {
        self.issues[objectID, default: []].append(error)
    }
    
    mutating func merge(_ error: NodeIssuesError) {
        self.issues.merge(error.issues) { (left, right) in
            left + right
        }
    }
}

/// An issue detected by the ``NodeIssuesError`` or the ``Compiler``.
///
/// The issues are usually grouped in a ``NodeIssuesError``, so that as
/// many issues are presented to the user as possible.
///
public enum NodeIssue: Equatable, CustomStringConvertible, Error {
    /// An error caused by a syntax error in the formula (arithmetic expression).
    case expressionSyntaxError(ExpressionSyntaxError)
   
    case expressionError(ExpressionError)
    
    /// Parameter connected to a node is not used in the formula.
    case unusedInput(String)
    
    /// Parameter in a formula is not connected from a node.
    ///
    /// All parameters in a formula must have a connection from a node
    /// that represents the parameter. This requirement is to make sure
    /// that the model is transparent to the human readers.
    ///
    case unknownParameter(String)
    
    /// The node has the same name as some other node.
    case duplicateName(String)
    
    /// Missing a connection from a parameter node to a graphical function.
    case missingGraphicalFunctionParameter
    
    /// Get the human-readable description of the issue.
    public var description: String {
        switch self {
        case .expressionSyntaxError(let error):
            return "Syntax error: \(error)"
        case .expressionError(let error):
            return "Expression error: \(error)"
        case .unusedInput(let name):
            return "Parameter '\(name)' is connected but not used"
        case .unknownParameter(let name):
            return "Parameter '\(name)' is unknown or not connected"
        case .duplicateName(let name):
            return "Duplicate node name: '\(name)'"
        case .missingGraphicalFunctionParameter:
            return "Graphical function node is missing a parameter connection"
        }
    }
    
    /// Hint for an error.
    ///
    /// If it is possible to get some help to the user how to deal with the
    /// error, then this property provides a hint.
    ///
    public var hint: String? {
        switch self {
        case .expressionSyntaxError(_):
            return "Check the expression"
        case .expressionError(_):
            return "Check the expression for correct variables, types and functions"
        case .unusedInput(let name):
            return "Use the connected parameter or disconnect the node '\(name)'."
        case .unknownParameter(let name):
            return "Connect the parameter node '\(name)'; or check the formula for typos; or remove the parameter from the formula."
        case .duplicateName(_):
            return nil
        case .missingGraphicalFunctionParameter:
            return "Connect exactly one node as a parameter to the graphical function. Name does not matter."
        }
    }
    
}


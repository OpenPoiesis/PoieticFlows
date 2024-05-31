//
//  DesignUtilities.swift
//
//
//  Created by Stefan Urbanek on 12/03/2024.
//

// INCUBATOR for design manipulation utilities.
//
// Most of the functionality is this file might be a candidate for inclusion
// in the Flows library.
//
// This file contains functionality that might be more complex, not always
// trivial manipulation of the frame.
//
// Once happy with the function/structure, consider moving to Flows or even Core
// library.
//

import PoieticFlows
import PoieticCore

public struct ParameterInfo {
    /// Name of the parameter
    let parameterName: String
    /// ID of the parameter node
    let parameterID: ObjectID
    /// ID of node using the parameter
    let targetID: ObjectID
    /// Name of node using the parameter
    let targetName: String?
    /// ID of the edge from the parameter to the target
    let edgeID: ObjectID
}

/// Automatically connect parameters in a frame.
///
func autoConnectParameters(_ frame: MutableFrame) throws -> (added: [ParameterInfo], removed: [ParameterInfo]) {
    let view = StockFlowView(frame)
    var added: [ParameterInfo] = []
    var removed: [ParameterInfo] = []
    
    let builtinNames: Set<String> = Set(Solver.Variables.map {
        $0.name
    })

    let context = RuntimeContext(frame: frame)
    var formulaCompiler = FormulaCompilerSystem()
    formulaCompiler.update(context)

    for target in view.simulationNodes {
        guard let component: ParsedFormulaComponent = context.component(for: target.id) else {
            continue
        }
        let allNodeVars: Set<String> = Set(component.parsedFormula.allVariables)
        let required = Array(allNodeVars.subtracting(builtinNames))
        let params = view.parameters(target.id, required: required)
        
        for (name, status) in params {
            switch status {
            case .missing:
                // Find missing parameter
                guard let parameterID = frame.object(named: name)?.id else {
                    throw ToolError.unknownObjectName(name)
                }
                let edge = frame.createEdge(ObjectType.Parameter,
                                            origin: parameterID,
                                          target: target.id)
                let info = ParameterInfo(parameterName: name,
                                         parameterID: parameterID,
                                         targetID: target.id,
                                         targetName: target.name,
                                         edgeID: edge)
                added.append(info)
            case let .unused(node, edge):
                frame.remove(edge: edge)
                let info = ParameterInfo(parameterName: name,
                                         parameterID: node,
                                         targetID: target.id,
                                         targetName: target.name,
                                         edgeID: edge)
                removed.append(info)
            case .used:
                continue
            }
        }
    }
    return (added: added, removed: removed)
}

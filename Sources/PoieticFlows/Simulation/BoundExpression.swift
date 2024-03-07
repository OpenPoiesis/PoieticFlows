//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 07/03/2024.
//

import PoieticCore

public typealias BoundExpression = ArithmeticExpression<BoundVariableReference,
                                                        Function>


extension BoundExpression {

    // TODO: Move to Solver
    // TODO: Make non-recursive
    public func evaluate(_ state: SimulationState) throws -> Variant {
        switch self {
        case let .value(value):
            return value

        case let .binary(op, lhs, rhs):
            return try op.apply([try lhs.evaluate(state),
                                 try rhs.evaluate(state)])

        case let .unary(op, operand):
            return try op.apply([try operand.evaluate(state)])

        case let .function(functionRef, arguments):
            let evaluatedArgs = try arguments.map {
                try $0.evaluate(state)
            }
            return try functionRef.apply(evaluatedArgs)

        case let .variable(ref):
            let value: Variant
            switch ref.variable {
            case .builtin: value = state.builtins[ref.index]
            case .object: value = Variant(state[ref.index])
            }
            return value
        }
    }
}

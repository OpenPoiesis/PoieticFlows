//
//  BuiltinFunctions.swift
//  
//
//  Created by Stefan Urbanek on 12/07/2022.
//

import PoieticCore

#if os(Linux)
import Glibc
#else
import Darwin
#endif

// Mark: Builtins

/// List of built-in numeric unary operators.
///
/// The operators:
///
/// - `__neg__` is `-` unary minus
///
/// - SeeAlso: ``bindExpression(_:variables:functions:)``
///
public let BuiltinUnaryOperators: [any FunctionProtocol] = [
    NumericUnaryFunction(name: "__neg__") { -$0 }
]

/// List of built-in numeric binary operators.
///
/// The operators:
///
/// - `__add__` is `+` addition
/// - `__sub__` is `-` subtraction
/// - `__mul__` is `*` multiplication
/// - `__div__` is `/` division
/// - `__mod__` is `%` remainder
///
/// - SeeAlso: ``bindExpression(_:variables:functions:)``
///
public let BuiltinBinaryOperators: [any FunctionProtocol] = [
    NumericBinaryFunction(name: "__add__") { $0 + $1 },
    NumericBinaryFunction(name: "__sub__") { $0 - $1 },
    NumericBinaryFunction(name: "__mul__") { $0 * $1 },
    NumericBinaryFunction(name: "__div__") { $0 / $1 },
    NumericBinaryFunction(name: "__mod__") { $0.truncatingRemainder(dividingBy: $1) },
]

/// List of built-in numeric function.
///
/// The functions:
///
/// - `abs(number)` absolute value
/// - `floor(number)` rounded down, floor value
/// - `ceiling(number)` rounded up, ceiling value
/// - `round(number)` rounded value
/// - `sum(number, ...)` sum of multiple values
/// - `min(number, ...)` min out of of multiple values
/// - `max(number, ...)` max out of of multiple values
///
public let BuiltinFunctions: [any FunctionProtocol] = [
    NumericFunction(name: "abs", signature: Signature(numeric: ["value"])) { args
        in args[0].magnitude
    },
    NumericFunction(name: "floor", signature: Signature(numeric: ["value"])) { args
        in args[0].rounded(.down)
    },
    NumericFunction(name: "ceiling", signature: Signature(numeric: ["value"])) { args
        in args[0].rounded(.up)
    },
    NumericFunction(name: "round", signature: Signature(numeric: ["value"])) { args
        in args[0].rounded()
    },

    NumericFunction(name: "power", signature: Signature(numeric: ["value", "exponent"])) { args
        in pow(args[0], args[1])
    },

    // Variadic
    
    NumericFunction(name: "sum", signature: Signature(numericVariadic: "value")) { args
        in args.reduce(0, { x, y in x + y })
    },
    NumericFunction(name: "min", signature: Signature(numericVariadic: "value")) { args
        in args.min()!
    },
    NumericFunction(name: "max", signature: Signature(numericVariadic: "value")) { args
        in args.max()!
    },
]

/// List of all built-in functions and operators.
let AllBuiltinFunctions: [any FunctionProtocol] = BuiltinUnaryOperators
                                                    + BuiltinBinaryOperators
                                                    + BuiltinFunctions

enum BuiltinFunction: String {
    case abs
    case floor
    case ceiling
    case round
    case power
    case sum
    case min
    case max
}

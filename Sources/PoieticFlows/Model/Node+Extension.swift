//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 13/07/2023.
//

import PoieticCore

extension Node {
    /// Get a parsed expression of a node that has a ``FormulaComponent``.
    ///
    /// - Returns: Unbound expression
    /// - Throws: ``SyntaxError`` when the expression can not be parsed.
    ///
    @available(*, deprecated, message: "Use snapshot[FormulaComponent.self")
    public func parsedExpression() throws -> UnboundExpression? {
        guard let component: FormulaComponent = snapshot[FormulaComponent.self] else {
            return nil
        }
        return try component.parsedExpression()
    }

}

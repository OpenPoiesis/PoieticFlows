//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 20/09/2023.
//

import PoieticCore

public typealias ParsedFormula = Result<UnboundExpression, ExpressionSyntaxError>

public struct ParsedFormulaComponent: Component {
    public let parsedFormula: UnboundExpression
    
    public init(parsedFormula: UnboundExpression) {
        self.parsedFormula = parsedFormula
    }

    public func attribute(forKey key: PoieticCore.AttributeKey) -> PoieticCore.Variant? {
        fatalError("Not implemented")
    }
    
    public mutating func setAttribute(value: PoieticCore.Variant, forKey key: PoieticCore.AttributeKey) throws {
        fatalError("Not implemented")
    }
    
}

/// Input:
///     - FormulaComponent
/// Output:
///     - ParsedFormulaComponent
/// Generates errors
///
public struct FormulaCompilerSystem: RuntimeSystem {
    public init() {}
    public mutating func update(_ context: RuntimeContext) {
        for snapshot in context.frame.snapshots {
            guard let formula = try? snapshot["formula"]?.stringValue() else {
                continue
            }
            let parser = ExpressionParser(string: formula)
            let expr: UnboundExpression
            do {
                expr = try parser.parse()
            }
            catch let error as ExpressionSyntaxError {
                context.appendIssue(error, for: snapshot.id)
                continue
            }
            catch {
                fatalError("Unknown error during parsing: \(error)")
            }
            
            context.setComponent(ParsedFormulaComponent(parsedFormula: expr),
                                 for: snapshot.id)
        }
    }
}

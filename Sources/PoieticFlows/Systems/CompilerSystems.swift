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
    
    public static var trait = Trait(
        name: "ParsedFormula"
    )
    
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
///     - All objects
/// Output:
///     - Remove all errors from existing error components
///     (do not remove the component).
/// Generates errors
///
public struct IssueCleaner: RuntimeSystem {
    // TODO: Rename to CleanIssuesTransform: FrameTransformation
    public mutating func update(_ context: RuntimeContext) {
        let items = context.frame.filter(component: IssueListComponent.self)
        
        for (snapshot, _) in items {
            let mutable = context.frame.mutableObject(snapshot.id)
            mutable[IssueListComponent.self]?.removeAll()
        }
    }
}


/// Input:
///     - FormulaComponent
/// Output:
///     - ParsedFormulaComponent
/// Generates errors
///
public struct ExpressionTransformer: RuntimeSystem {
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
            
            let parsedComponent = ParsedFormulaComponent(parsedFormula: expr)
            let mutable = context.frame.mutableObject(snapshot.id)
            mutable[ParsedFormulaComponent.self] = parsedComponent
        }
    }
}

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
    
    public static var componentSchema = Trait(
        name: "ParsedFormula"
    )
    
    public init(parsedFormula: UnboundExpression) {
        self.parsedFormula = parsedFormula
    }

    public func attribute(forKey key: PoieticCore.AttributeKey) -> PoieticCore.ForeignValue? {
        fatalError("Not implemented")
    }
    
    public mutating func setAttribute(value: PoieticCore.ForeignValue, forKey key: PoieticCore.AttributeKey) throws {
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
public struct IssueCleaner: FrameTransformer {
    // TODO: Rename to CleanIssuesTransform: FrameTransformation
    public mutating func update(_ context: TransformationContext) {
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
public struct ExpressionTransformer: FrameTransformer {
    public init() {}
    public mutating func update(_ context: TransformationContext) {
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

/// A system that updates edges that denote implicit flows between stocks.
///
/// The created edges are of type ``FlowsMetamodel/ImplicitFlow``.
///
/// For more information see the ``update(_:)`` method of this system.
///
public struct ImplicitFlowsTransformer: FrameTransformer {
    /// Update edges that denote implicit flows between stocks.
    ///
    /// The created edges are of type ``FlowsMetamodel/ImplicitFlow``.
    ///
    /// The process:
    ///
    /// - create an edge between two stocks that are also connected by
    ///   a flow
    /// - clean-up edges between stocks where is no flow
    ///
    /// - SeeAlso: ``StockFlowView/implicitFills(_:)``,
    ///   ``StockFlowView/implicitDrains(_:)``,
    ///   ``StockFlowView/sortedStocksByImplicitFlows(_:)``
    ///
    public mutating func update(_ context: TransformationContext) {
        let graph = context.frame.mutableGraph
        let view = StockFlowView(context.frame)
        var unused: [Edge] = view.implicitFlowEdges
        
        for flow in view.flowNodes {
            guard let fills = view.flowFills(flow.id) else {
                continue
            }
            guard let drains = view.flowDrains(flow.id) else {
                continue
            }
            
            let index = unused.firstIndex { edge in
                edge.origin == drains && edge.target == fills
            }
            if let index {
                // Keep the existing, and prevent from deletion later.
                unused.remove(at: index)
                continue
            }
            
            graph.createEdge(ObjectType.ImplicitFlow,
                             origin: drains,
                             target: fills,
                             attributes: [:],
                             components: [])
        }
        
        for edge in unused {
            graph.remove(edge: edge.id)
        }
    }
}

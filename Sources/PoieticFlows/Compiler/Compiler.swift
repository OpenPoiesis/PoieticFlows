//
//  Compiler.swift
//
//
//  Created by Stefan Urbanek on 21/06/2022.
//

import PoieticCore

/// An object that compiles the model into a ``CompiledModel``.
///
/// We are treating the user's design as a non-linear/graphical
/// programming language. The compiler transforms the design to a form that
/// can be interpreted - simulated.
///
/// The compiler makes sure that the model is valid, references
/// are resolved. It resolves the order in which the nodes are
/// to be evaluated.
///
///
public class Compiler {
    /// The frame containing the design to be compiled.
    ///
    let frame: MutableFrame

    /// Flows domain view of the frame.
    let view: StockFlowView

    // Compiler State
    // -----------------------------------------------------------------
    /// List of built-in variables used in the simulation.
    ///
    private let builtinVariables: [BuiltinVariable]

    /// List of built-in variable names, fetched from the metamodel.
    ///
    /// Used in binding of arithmetic expressions.
    private let builtinVariableNames: [String]

    /// List of built-in functions.
    ///
    /// Used in binding of arithmetic expressions.
    private let functions: [String: Function]

    /// Mapping between a variable name and a bound variable reference.
    ///
    /// Used in binding of arithmetic expressions.
    private var namedReferences: [String:BoundVariableReference]
    // TODO: [REFACTORING] Status: check

    /// Mapping between object ID and index of its corresponding simulation
    /// variable.
    ///
    /// Used in compilation of simulation nodes.
    ///
    private var objectToIndex: [ObjectID: Int]

    /// List of transformation systems run before the compilation.
    ///
    /// Requirements:
    /// - There must be no dependency between the systems.
    /// - If any of the systems reports a node issue, the compilation must not
    ///   proceed.
    ///
    /// - Note: This will be public once happy.
    ///
    private var _preCompilationTransforms: [any FrameTransformer] = [
        IssueCleaner(),
        ExpressionTransformer(),
        ImplicitFlowsTransformer(),
    ]
//    private var _postCompilationSystems: [any TransformationSystem] = [
//    ]

    /// Creates a compiler that will compile within the context of the given
    /// model.
    ///
    public init(frame: MutableFrame) {
        // FIXME: [IMPORTANT] Compiler should get a stable frame, not a mutable frame!
        // FIXME: [IMPORTANT] What if frame != view.frame???
        self.frame = frame
        self.view = StockFlowView(frame)
        
        builtinVariables = FlowsMetamodel.variables
        builtinVariableNames = builtinVariables.map { $0.name }
    
        let items = AllBuiltinFunctions.map { ($0.name, $0) }
        functions = Dictionary(uniqueKeysWithValues: items)

        // Intermediated variables and mappigns used for compilation
        objectToIndex = [:]

        // Variables for arithmetic expression binding
        namedReferences = [:]
    }

    // TODO: Verify which errors are thrown in here
    /// Compiles the model and returns the compiled version of the model.
    ///
    /// The compilation process is as follows:
    ///
    /// 1. Gather all node names and check for potential duplicates
    /// 2. Compile all formulas (expressions) and bind them with concrete
    ///    objects.
    /// 3. Sort the nodes in the order of computation.
    /// 4. Pre-filter nodes for easier usage by the solver: stocks, flows
    ///    and auxiliaries. All filtered collections stay ordered.
    /// 5. Create implicit flows between stocks and sort stocks in order
    ///    of their dependency.
    /// 6. Finalise the compiled model.
    ///
    /// - Throws: A ``NodeIssuesError`` when there are issues with the model
    ///   that are caused by the user. Throws ``/PoieticCore/ConstraintViolation`` if
    ///   the frame constraints were violated. The later error is an
    ///   application error and means that either the provided frame is
    ///   mal-formed or one of the subsystems mis-behaved.
    /// - Returns: A ``CompiledModel`` that can be used directly by the
    ///   simulator.
    ///
    public func compile() throws -> CompiledModel {
        // NOTE: Please use explicit self for instance variables in this function
        //       so we can visually see the shared compilation context.
        //
        // Context:
        //  - unsorted simulation nodes
        //      - (id, name, computationalRepresentation)
        // FIXME: [REFACTORING] remove instance variable equivalent
        var computedVariables: [ComputedVariable] = []

        try frame.memory.validate(frame)
        
        // 1. Update pre-compilation systems
        // =================================================================

        // TODO: We are passing view from metamodel just to create view in the context
        let context = TransformationContext(frame: frame)

        for index in _preCompilationTransforms.indices {
            _preCompilationTransforms[index].update(context)
        }

        guard !context.hasIssues else {
            throw NodeIssuesError(errors: context.issues)
        }

        // TODO: Do we need second validation or we trust the systems?
        try frame.memory.validate(frame)

        // 2. Collect nodes that are to be part of the simulation
        // =================================================================

        var unsortedSimulationNodes: [ObjectID] = []
        var homonyms: [String: [ObjectID]] = [:]

        for node in view.simulationNodes {
            unsortedSimulationNodes.append(node.id)
            homonyms[node.name!, default: []].append(node.id)
        }

        // 2.1 Report the duplicates, if any
        // -----------------------------------------------------------------

        var dupes: [String] = []

        for (name, ids) in homonyms where ids.count > 1 {
            let issue = NodeIssue.duplicateName(name)
            dupes.append(name)
            for id in ids {
                context.appendIssue(issue, for: id)
            }
        }

        guard !context.hasIssues else {
            throw NodeIssuesError(errors: context.issues)
        }

        // 3. Sort nodes in order of computation
        // =================================================================
        // All the nodes present in this list will form a simulation state.
        // Indices in this vector will be the indices used through out the
        // simulation.

        let orderedSimulationNodes: [Node]
        // TODO: orderedSimulationNodes should be (id, name, snapshot)

        do {
            orderedSimulationNodes = try view.sortedNodesByParameter(unsortedSimulationNodes)
        }
        catch let error as GraphCycleError {
            // FIXME: Handle this.
            fatalError("Unhandled graph cycle error: \(error). (Not implemented.)")
        }
        
        // 4. Prepare named references to variables
        // =================================================================
        // This step is necessary for arithmetic expression compilation.

        // Collect built-in variables.
        //
        for (index, builtin) in builtinVariables.enumerated() {
            let ref = BoundVariableReference(variable: .builtin(builtin),
                                             valueType: builtin.valueType,
                                             index: index)
            self.namedReferences[builtin.name] = ref
        }

        // 5. Compile computational representations
        // =================================================================
        
        var issues = NodeIssuesError()
        // FIXME: Use context, test whether the errors were appended to the node
        
        for (index, node) in orderedSimulationNodes.enumerated() {
            let computation: ComputationalRepresentation
            do {
                computation = try self.compile(node)
            }
            catch let error as NodeIssue {
                issues.append(error, for:node.id)
                continue
            }
            catch let error as NodeIssuesError {
                // TODO: Remove necessity for this catch
                issues.merge(error)
                continue
            }
            catch {
                continue

            }
            
            let variable = ComputedVariable(
                id: node.id,
                index: index,
                computation: computation,
                name: node.name!
            )
            computedVariables.append(variable)
            let ref = BoundVariableReference(variable: .object(node.id),
                                             valueType: variable.valueType,
                                             index: index)
            self.namedReferences[node.name!] = ref
            self.objectToIndex[node.id] = index
        }
        
        guard issues.isEmpty else {
            throw issues
        }

        // 6. Filter by node type
        // =================================================================

        var unsortedStocks: [Node] = []
        var flows: [CompiledFlow] = []
        var flowsByID: [ObjectID:CompiledFlow] = [:]
        var auxiliaries: [CompiledObject] = []
        
        for (index, node) in orderedSimulationNodes.enumerated() {
            if node.type === ObjectType.Stock {
                unsortedStocks.append(node)
            }
            else if node.type === ObjectType.Flow {
                // FIXME: [REFACTORING] Too many unwraps
                let priority = try! node.snapshot["priority"]!.intValue()
                let flow = CompiledFlow(id: node.id,
                                        index: index,
                                        priority: priority)
                flows.append(flow)
                flowsByID[node.id] = flow
            }
            else if node.type === ObjectType.Auxiliary
                        || node.type === ObjectType.GraphicalFunction {
                let compiled = CompiledObject(id: node.id, index: index)
                auxiliaries.append(compiled)
            }
            else {
                // TODO: Turn this into a global model error? (we do not have such concept yet)
                fatalError("Unknown simulation node type: \(node.type)")
            }
        }
        
        // 7. Sort stocks in order of flow dependency
        // =================================================================

        // This step is needed for proper computation of non-negative stocks

        let sortedStocks: [Node]
        do {
            let unsorted = unsortedStocks.map { $0.id }
            sortedStocks = try view.sortedStocksByImplicitFlows(unsorted)
            
        }
        catch is GraphCycleError {
            // catch let error as GraphCycleError {
            // FIXME: Handle the error
            fatalError("Unhandled graph cycle error")
        }
        
        let compiledStocks = compile(stocks: sortedStocks, flows: flowsByID)

        // 8. Value Bindings
        // =================================================================

        var bindings: [CompiledControlBinding] = []
        for object in frame.filter(type: ObjectType.ValueBinding) {
            guard let edge = Edge(object) else {
                // This should not happen
                fatalError("A value binding \(object.id) is not an edge")
            }
            
            let binding = CompiledControlBinding(control: edge.origin,
                                              variableIndex: variableIndex(edge.target))
            bindings.append(binding)
        }
        
        // 9. Charts
        // =================================================================
        //
        // FIXME: [REFACTORING] Move StockFlowView.charts here
        let charts = view.charts
        
        // 10. Defaults
        // =================================================================
        //
        let simulationDefaults: SimulationDefaults?
        if let simInfo = frame.first(trait: Trait.Simulation) {
            // NOTE: We do not need to check for types as the type
            //       is validated on accept(). Frame is valid here.
            let initialTime = try! simInfo["initial_time"]?.doubleValue()
            let timeDelta = try! simInfo["time_delta"]?.doubleValue()
            let steps = try! simInfo["steps"]?.intValue()
            simulationDefaults = SimulationDefaults(
                initialTime: initialTime ?? 0.0,
                timeDelta: timeDelta ?? 1.0,
                simulationSteps: steps ?? 10
            )
        }
        else {
            simulationDefaults = nil
        }

        
        // 999. Misc
        
        guard let timeIndex = builtinVariables.firstIndex(where: { $0 === ObjectType.TimeVariable }) else {
            fatalError("No time variable")
        }

        
        
        // Finalise
        // =================================================================
        //
        let result = CompiledModel(
            builtinVariables: builtinVariables,
            builtinTimeIndex: timeIndex,
            computedVariables: computedVariables,
            stocks: compiledStocks,
            flows: flows,
            auxiliaries: auxiliaries,
            charts: charts,
            valueBindings: bindings,
            simulationDefaults: simulationDefaults
        )
        
        return result
    }
    
    /// Get an index of a simulation variable that represents a node with given
    /// ID.
    ///
    /// - Precondition: Object with given ID must have a corresponding
    ///   simulation variable.
    ///
    public func variableIndex(_ id: ObjectID) -> VariableIndex {
        guard let index = objectToIndex[id] else {
            fatalError("Object \(id) not found in the simulation variable list")
        }
        return index
    }

    /// Compile a simulation node.
    ///
    /// The function compiles a node that represents a variable or a kind of
    /// computation.
    ///
    /// The following types of nodes are considered:
    /// - a node with a ``/PoieticCore/Trait/Formula``, compiled as a formula.
    /// - a node with a ``/PoieticCore/Trait/GraphicalFunction``, compiled as a graphical
    ///   function.
    ///
    /// - Returns: a computational representation of the simulation node.
    ///
    /// - Throws: ``NodeIssuesError`` with list of issues for the node.
    /// - SeeAlso: ``compileFormulaNode(_:)``, ``compileGraphicalFunctionNode(_:)``.
    ///
    public func compile(_ node: Node) throws -> ComputationalRepresentation {
        let rep: ComputationalRepresentation
        if node.snapshot.type.hasTrait(Trait.Formula) {
            rep = try compileFormulaNode(node)
        }
        else if node.snapshot.type.hasTrait(Trait.GraphicalFunction) {
            rep = try compileGraphicalFunctionNode(node)
        }
        else {
            // Hint: If this error happens, then either check the following:
            // - the condition in the stock-flows view method returning
            //   simulation nodes
            // - whether the object memory constraints work properly
            // - whether the object memory metamodel is stock-flows metamodel
            //   and that it has necessary components
            //
            fatalError("Node \(node.snapshot) is not known as a simulation node, can not be compiled.")
        }
        return rep
    }

    // FIXME: Update documentation
    /// Return a dictionary of bound expressions.
    ///
    /// For each node with an arithmetic expression the expression is parsed
    /// from a text into an internal representation. The variable and function
    /// names are resolved to point to actual entities and a new bound
    /// expression is formed.
    ///
    /// - Parameters:
    ///     - names: mapping of variable names to their corresponding objects.
    ///
    /// - Returns: A dictionary where the keys are expression node IDs and values
    ///   are compiled BoundExpressions.
    ///
    /// - Throws: ``NodeIssue`` with ``NodeIssue/expressionSyntaxError(_:)`` for each node
    ///   which has a syntax error in the expression.
    ///
    /// - Throws: ``NodeIssuesError`` with list of issues for the node.
    ///
    public func compileFormulaNode(_ node: Node) throws -> ComputationalRepresentation{
        guard let component: ParsedFormulaComponent = node.snapshot[ParsedFormulaComponent.self] else {
            fatalError("Parsed formula component expected for node \(node.id)")
        }
        //
        // FIXME: [IMPORTANT] Parse expressions in a compiler sub-system, have it parsed here already
        let unboundExpression: UnboundExpression = component.parsedFormula
        
        // List of required parameters: variables in the expression that
        // are not built-in variables.
        //
        let required: [String] = unboundExpression.allVariables.filter {
            !builtinVariableNames.contains($0)
        }

        // TODO: [IMPORTANT] Move this outside of this method. This is not required for binding
        // Validate parameters.
        //
        let inputIssues = validateParameters(node.id, required: required)
        guard inputIssues.isEmpty else {
            throw NodeIssuesError(errors: [node.id: inputIssues])
        }
        
        // Finally bind the expression.
        //
        let boundExpression = try bindExpression(unboundExpression,
                                                 variables: namedReferences,
                                                 functions: functions)
        return .formula(boundExpression)
    }

    /// - Requires: node
    /// - Throws: ``NodeIssue`` if the function parameter is not connected.
    ///
    public func compileGraphicalFunctionNode(_ node: Node) throws -> ComputationalRepresentation{
        guard let points = try? node.snapshot["graphical_function_points"]?.pointArray() else {
            // TODO: [REFACTORING] Better error handling/reporting for these cases
            fatalError("Got graphical function without points attribute")
        }
        // TODO: Interpolation method
        let function = GraphicalFunction(points: points)
        
        let hood = view.incomingParameters(node.id)
        guard let parameterNode = hood.nodes.first else {
            throw NodeIssue.missingGraphicalFunctionParameter
        }
        
        let funcName = "__graphical_\(node.id)"
        let numericFunc = function.createFunction(name: funcName)

        return .graphicalFunction(numericFunc, variableIndex(parameterNode.id))

    }

    /// Compile all stock nodes.
    ///
    /// The function extracts component from the stock that is necessary
    /// for simulation. Then the function collects all inflows and outflows
    /// of the stock.
    ///
    /// - Returns: Extracted and derived stock node information.
    ///
    public func compile(stocks: [Node], flows: [ObjectID:CompiledFlow]) -> [CompiledStock] {
        var outflows: [ObjectID: [ObjectID]] = [:]
        var inflows: [ObjectID: [ObjectID]] = [:]

        for edge in view.drainsEdges {
            // Drains edge: stock ---> flow
            let stock = edge.origin
            let flow = edge.target
            outflows[stock,default:[]].append(flow)
        }

        for edge in view.fillsEdges {
            // Fills edge: flow ---> stock
            let stock = edge.target
            let flow = edge.origin
            inflows[stock, default: []].append(flow)
        }

        // Sort the outflows by priority
        for stock in stocks {
            if let unsorted = outflows[stock.id] {
                let sorted = unsorted.map {
                    (id: $0, priority: flows[$0]!.priority)
                }
                .sorted { (lhs, rhs) in
                    return lhs.priority < rhs.priority
                }
                .map { $0.id }
                outflows[stock.id] = sorted
            }
            else {
                outflows[stock.id] = []
            }
        }
                
        var result: [CompiledStock] = []
        
        for node in stocks {
            let inflowIndices = inflows[node.id]?.map { variableIndex($0) } ?? []
            let outflowIndices = outflows[node.id]?.map { variableIndex($0) } ?? []

            // We can `try!` and force unwrap, because here we already assume
            // the model was validated
            let allowsNegative = try! node.snapshot["allows_negative"]!.boolValue()
            let delayedInflow = try! node.snapshot["delayed_inflow"]!.boolValue()

            let compiled = CompiledStock(
                id: node.id,
                index: variableIndex(node.id),
                allowsNegative: allowsNegative,
                delayedInflow: delayedInflow,
                inflows: inflowIndices,
                outflows: outflowIndices
            )
            result.append(compiled)
        }
        return result
    }
    
    // FIXME: Update documentation
    /// Validates parameter  of a node.
    ///
    /// The method checks whether the following two requirements are met:
    ///
    /// - node using a parameter name in an expression (in the `required` list)
    ///   must have a ``/PoieticCore/ObjectType/Parameter`` edge from the parameter node
    ///   with given name.
    /// - node must _not_ have a ``/PoieticCore/ObjectType/Parameter``connection from
    ///   a node if the expression is not referring to that node.
    ///
    /// If any of the two requirements are not met, then a corresponding
    /// type of ``NodeIssue`` is added to the list of issues.
    ///
    /// - Parameters:
    ///     - nodeID: ID of a node to be validated for inputs
    ///     - required: List of names (of nodes) that are required for the node
    ///       with id `nodeID`.
    ///
    /// - Returns: List of issues that the node with ID `nodeID` caused. The
    ///   issues can be either ``NodeIssue/unknownParameter(_:)`` or
    ///   ``NodeIssue/unusedInput(_:)``.
    ///
    public func validateParameters(_ nodeID: ObjectID, required: [String]) -> [NodeIssue] {
        let parameters = view.parameters(nodeID, required: required)
        var issues: [NodeIssue] = []
        
        for (name, status) in parameters {
            switch status {
            case .used: continue
            case .unused:
                issues.append(.unusedInput(name))
            case .missing:
                issues.append(.unknownParameter(name))
            }
        }
        
        return issues
    }
    
    public func appendIssue(_ error: Error, to object: ObjectID) {
        fatalError("\(#function) not implemented")
    }
}

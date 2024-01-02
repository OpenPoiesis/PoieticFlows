//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 08/06/2023.
//

import XCTest
@testable import PoieticFlows
@testable import PoieticCore

extension SimulationState {
    public subscript(id: ObjectID) -> Double {
        get {
            return values[model.index(of: id)!]
        }
        set(value) {
            values[model.index(of: id)!] = value
        }
    }
}

final class TestSolver: XCTestCase {
    var db: ObjectMemory!
    var frame: MutableFrame!
    var graph: MutableGraph!
    var compiler: Compiler!
    
    override func setUp() {
        db = ObjectMemory()
        
        // TODO: This should be passed as an argument to the memory
        for constraint in FlowsMetamodel.constraints {
            try! db.addConstraint(constraint)
        }
        
        frame = db.deriveFrame()
        graph = frame.mutableGraph
        compiler = Compiler(frame: frame)
    }
    func testInitializeStocks() throws {
        
        let a = graph.createNode(FlowsMetamodel.Auxiliary,
                                 name: "a",
                                 components: [FormulaComponent(expression: "1")])
        let b = graph.createNode(FlowsMetamodel.Auxiliary,
                                 name: "b",
                                 components: [FormulaComponent(expression: "a + 1")])
        let c =  graph.createNode(FlowsMetamodel.Stock,
                                  name: "const",
                                  components: [FormulaComponent(expression: "100")])
        let s_a = graph.createNode(FlowsMetamodel.Stock,
                                   name: "use_a",
                                   components: [FormulaComponent(expression: "a")])
        let s_b = graph.createNode(FlowsMetamodel.Stock,
                                   name: "use_b",
                                   components: [FormulaComponent(expression: "b")])
        
        graph.createEdge(FlowsMetamodel.Parameter, origin: a, target: b, components: [])
        graph.createEdge(FlowsMetamodel.Parameter, origin: a, target: s_a, components: [])
        graph.createEdge(FlowsMetamodel.Parameter, origin: b, target: s_b, components: [])
        
        let compiled = try compiler.compile()
        let solver = Solver(compiled)
        for v in compiled.computedVariables {
            let vstr = "\(v.id):\(v.name)@\(v.index)"
            let expr = graph.node(v.id).attribute(forKey: "formula")!
        }

        let state = solver.initialize()
        
        XCTAssertEqual(state[a], 1)
        XCTAssertEqual(state[b], 2)
        XCTAssertEqual(state[c], 100)
        XCTAssertEqual(state[s_a], 1)
        XCTAssertEqual(state[s_b], 2)
    }
    func testOrphanedInitialize() throws {
        
        let a = graph.createNode(FlowsMetamodel.Auxiliary,
                                 name: "a",
                                 components: [FormulaComponent(expression: "1")])
        let compiled = try compiler.compile()
        let solver = Solver(compiled)
        
        let vector = solver.initialize()
        
        XCTAssertNotNil(vector[a])
    }
    func testEverythingInitialized() throws {
        let aux = graph.createNode(FlowsMetamodel.Auxiliary,
                                   name: "a",
                                   components: [FormulaComponent(expression: "10")])
        let stock = graph.createNode(FlowsMetamodel.Stock,
                                     name: "b",
                                     components: [FormulaComponent(expression: "20")])
        let flow = graph.createNode(FlowsMetamodel.Flow,
                                    name: "c",
                                    components: [FormulaComponent(expression: "30")])
        
        let compiled = try compiler.compile()
        let solver = Solver(compiled)
        
        let vector = solver.initialize()
        
        XCTAssertEqual(vector[aux], 10)
        XCTAssertEqual(vector[stock], 20)
        XCTAssertEqual(vector[flow], 30)
    }
    func testTime() throws {
        let compiled = try compiler.compile()
        let solver = EulerSolver(compiled)
        
        var state = solver.initialize(time: 10.0)
        XCTAssertEqual(state.builtins[0], 10.0)
        state = solver.compute(state, at: 20.0 )
        XCTAssertEqual(state.builtins[0], 20.0)
        state = solver.compute(state, at: 30.0 )
        XCTAssertEqual(state.builtins[0], 30.0)

    }
   
    func testStageWithTime() throws {
        let aux = graph.createNode(FlowsMetamodel.Auxiliary,
                                   name: "a",
                                   components: [FormulaComponent(expression: "time")])
        let flow = graph.createNode(FlowsMetamodel.Flow,
                                    name: "f",
                                    components: [FormulaComponent(expression: "time * 10")])

        let compiled = try compiler.compile()
        let solver = EulerSolver(compiled)
        
        var state = solver.initialize(time: 1.0)
        
        XCTAssertEqual(state[aux], 1.0)
        XCTAssertEqual(state[flow], 10.0)
        
        state = solver.compute(state, at: 2.0)
        XCTAssertEqual(state[aux], 2.0)
        XCTAssertEqual(state[flow], 20.0)

        state = solver.compute(state, at: 10.0, timeDelta: 1.0)
        XCTAssertEqual(state[aux], 10.0)
        XCTAssertEqual(state[flow], 100.0)
    }

    func testNegativeStock() throws {
        let stock = graph.createNode(FlowsMetamodel.Stock,
                                     name: "stock",
                                     components: [FormulaComponent(expression: "5")])
        let node = graph.node(stock)
        node.snapshot[StockComponent.self]!.allowsNegative = true
        
        let flow = graph.createNode(FlowsMetamodel.Flow,
                                    name: "flow",
                                     components: [FormulaComponent(expression: "10")])

        graph.createEdge(FlowsMetamodel.Drains, origin: stock, target: flow, components: [])
        
        let compiled = try compiler.compile()
        
        let solver = Solver(compiled)
        let initial = solver.initialize()
        let diff = solver.difference(at: 1.0, with: initial)

        XCTAssertEqual(diff[stock], -10)
    }

    func testNonNegativeStock() throws {
        let stock = graph.createNode(FlowsMetamodel.Stock,
                                     name: "stock",
                                     components: [FormulaComponent(expression: "5")])
        let node = graph.node(stock)
        node.snapshot[StockComponent.self]!.allowsNegative = false
        
        let flow = graph.createNode(FlowsMetamodel.Flow,
                                    name: "flow",
                                    components: [FormulaComponent(expression: "10")])

        graph.createEdge(FlowsMetamodel.Drains, origin: stock, target: flow, components: [])
        
        let compiled = try compiler.compile()
        
        let solver = Solver(compiled)
        let initial = solver.initialize()
        let diff = solver.difference(at: 1.0, with: initial)

        XCTAssertEqual(diff[stock], -5)
    }
    // TODO: Also negative outflow
    func testNonNegativeStockNegativeInflow() throws {
        let stock = graph.createNode(FlowsMetamodel.Stock,
                                     name: "stock",
                                     components: [FormulaComponent(expression: "5")])
        let obj = graph.node(stock)
        obj.snapshot[StockComponent.self]!.allowsNegative = false
        // FIXME: There is a bug in the expression parser
        let flow = graph.createNode(FlowsMetamodel.Flow,
                                    name: "flow",
                                    components: [FormulaComponent(expression: "0 - 10")])

        graph.createEdge(FlowsMetamodel.Fills, origin: flow, target: stock, components: [])
        
        let compiled = try compiler.compile()
        
        let solver = Solver(compiled)
        let initial = solver.initialize()
        let diff = solver.difference(at: 1.0, with: initial)

        XCTAssertEqual(diff[stock], 0)
    }

    func testStockNegativeOutflow() throws {
        let stock = graph.createNode(FlowsMetamodel.Stock,
                                     name: "stock",
                                     components: [FormulaComponent(expression: "5")])
        let obj = graph.node(stock)
        obj.snapshot[StockComponent.self]!.allowsNegative = false
        // FIXME: There is a bug in the expression parser
        let flow = graph.createNode(FlowsMetamodel.Flow,
                                    name: "flow",
                                    components: [FormulaComponent(expression: "-10")])

        graph.createEdge(FlowsMetamodel.Drains, origin: stock, target: flow, components: [])
        
        let compiled = try compiler.compile()
        
        let solver = Solver(compiled)
        let initial = solver.initialize()
        let diff = solver.difference(at: 1.0, with: initial)

        XCTAssertEqual(diff[stock], 0)
    }

    func testNonNegativeToTwo() throws {
        // TODO: Break this into multiple tests
        let source = graph.createNode(FlowsMetamodel.Stock,
                                      name: "stock",
                                     components: [FormulaComponent(expression: "5")])
        let sourceNode = graph.node(source)
        sourceNode.snapshot[StockComponent.self]!.allowsNegative = false

        let happy = graph.createNode(FlowsMetamodel.Stock,
                                     name: "happy",
                                     components: [FormulaComponent(expression: "0")])
        let sad = graph.createNode(FlowsMetamodel.Stock,
                                   name: "sad",
                                   components: [FormulaComponent(expression: "0")])
        let happyFlow = graph.createNode(FlowsMetamodel.Flow,
                                         name: "happy_flow",
                                         components: [FormulaComponent(expression: "10")])
        let happyFlowNode = graph.node(happyFlow)
        happyFlowNode.snapshot[FlowComponent.self]!.priority = 1

        graph.createEdge(FlowsMetamodel.Drains,
                         origin: source, target: happyFlow, components: [])
        graph.createEdge(FlowsMetamodel.Fills,
                         origin: happyFlow, target: happy, components: [])

        let sadFlow = graph.createNode(FlowsMetamodel.Flow,
                                       name: "sad_flow",
                                       components: [FormulaComponent(expression: "10")])
        let sadFlowNode = graph.node(sadFlow)
        sadFlowNode.snapshot[FlowComponent.self]!.priority = 2

        graph.createEdge(FlowsMetamodel.Drains,
                         origin: source, target: sadFlow, components: [])
        graph.createEdge(FlowsMetamodel.Fills,
                         origin: sadFlow, target: sad, components: [])

        let compiled: CompiledModel = try compiler.compile()
        // TODO: Needed?
        // let outflows = compiled.outflows[source]
        
        // We require that the stocks will be computed in the following order:
        // 1. source
        // 2. happy
        // 3. sad

        let solver = Solver(compiled)
        
        // Test compute()
        
        let initial: SimulationState = solver.initialize()

        // Compute test
        var state: SimulationState = initial

        XCTAssertEqual(state[happyFlow], 10)
        XCTAssertEqual(state[sadFlow], 10)
        
        let sourceDiff = solver.computeStock(source, at: 0, with: &state)
        // Adjusted flow to actual outflow
        XCTAssertEqual(state[happyFlow],  5.0)
        XCTAssertEqual(state[sadFlow],    0.0)
        XCTAssertEqual(sourceDiff,         -5.0)

        let happyDiff = solver.computeStock(happy, at: 0, with: &state)
        // Remains the same as above
        XCTAssertEqual(state[happyFlow],  5.0)
        XCTAssertEqual(state[sadFlow],    0.0)
        XCTAssertEqual(happyDiff,          +5.0)

        let sadDiff = solver.computeStock(sad, at: 0, with: &state)
        // Remains the same as above
        XCTAssertEqual(state[happyFlow],  5.0)
        XCTAssertEqual(state[sadFlow],    0.0)
        XCTAssertEqual(sadDiff,             0.0)

        // Sanity check
        XCTAssertEqual(initial[happyFlow], 10)
        XCTAssertEqual(initial[sadFlow], 10)


        let diff = solver.difference(at: 1.0, with: initial)

        XCTAssertEqual(diff[source], -5)
        XCTAssertEqual(diff[happy],  +5)
        XCTAssertEqual(diff[sad],     0)
    }

    func testDifference() throws {
        let kettle = graph.createNode(FlowsMetamodel.Stock,
                                      name: "kettle",
                                      components: [FormulaComponent(expression: "1000")])
        let flow = graph.createNode(FlowsMetamodel.Flow,
                                    name: "pour",
                                    components: [FormulaComponent(expression: "100")])
        let cup = graph.createNode(FlowsMetamodel.Stock,
                                      name: "cup",
                                      components: [FormulaComponent(expression: "0")])

        graph.createEdge(FlowsMetamodel.Drains,
                         origin: kettle, target: flow, components: [])
        graph.createEdge(FlowsMetamodel.Fills,
                         origin: flow, target: cup, components: [])

        let compiled = try compiler.compile()
        let solver = Solver(compiled)
        
        var state = solver.initialize(time: 1.0)
        
        state = solver.difference(at: 1.0, with: state, timeDelta: 1.0)
        XCTAssertEqual(state[kettle], -100.0)
        XCTAssertEqual(state[cup], 100.0)
    }

    
    func testCompute() throws {
        let kettle = graph.createNode(FlowsMetamodel.Stock,
                                      name: "kettle",
                                      components: [FormulaComponent(expression: "1000")])
        let flow = graph.createNode(FlowsMetamodel.Flow,
                                    name: "pour",
                                    components: [FormulaComponent(expression: "100")])
        let cup = graph.createNode(FlowsMetamodel.Stock,
                                      name: "cup",
                                      components: [FormulaComponent(expression: "0")])

        graph.createEdge(FlowsMetamodel.Drains,
                         origin: kettle, target: flow, components: [])
        graph.createEdge(FlowsMetamodel.Fills,
                         origin: flow, target: cup, components: [])

        let compiled = try compiler.compile()
        let solver = EulerSolver(compiled)
        
        var state = solver.initialize(time: 1.0)
        
        state = solver.compute(state, at: 2.0)
        XCTAssertEqual(state[kettle], 900.0 )
        XCTAssertEqual(state[cup], 100.0)

        state = solver.compute(state, at: 3.0)
        XCTAssertEqual(state[kettle], 800.0 )
        XCTAssertEqual(state[cup], 200.0)
    }

    
    func testGraphicalFunction() throws {
        let p1 = graph.createNode(FlowsMetamodel.Auxiliary,
                                   name:"p1",
                                   components: [FormulaComponent(expression: "0")])
        let g1 = graph.createNode(FlowsMetamodel.GraphicalFunction,
                                  name: "g1",
                                  components: [GraphicalFunctionComponent()])

        let p2 = graph.createNode(FlowsMetamodel.Auxiliary,
                                   name:"p2",
                                   components: [FormulaComponent(expression: "0")])
        let points = [Point(0.0, 10.0), Point(1.0, 10.0)]
        let g2 = graph.createNode(FlowsMetamodel.GraphicalFunction,
                                  name: "g2",
                                  components: [GraphicalFunctionComponent(points: points)])
        let aux = graph.createNode(FlowsMetamodel.Auxiliary,
                                   name:"a",
                                   components: [FormulaComponent(expression: "g1 + g2")])

        graph.createEdge(FlowsMetamodel.Parameter, origin: g1, target: aux)
        graph.createEdge(FlowsMetamodel.Parameter, origin: g2, target: aux)
        graph.createEdge(FlowsMetamodel.Parameter, origin: p1, target: g1)
        graph.createEdge(FlowsMetamodel.Parameter, origin: p2, target: g2)

        let compiled: CompiledModel = try compiler.compile()
        let solver = EulerSolver(compiled)
        let initial: SimulationState = solver.initialize()
        
        XCTAssertEqual(initial[g1], 0.0)
        XCTAssertEqual(initial[g2], 10.0)
        XCTAssertEqual(initial[aux], 10.0)

    }

}

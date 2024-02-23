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
    var compiler: Compiler!
    
    override func setUp() {
        db = ObjectMemory(metamodel: FlowsMetamodel)
        
        // TODO: This should be passed as an argument to the memory
        for constraint in FlowsMetamodel.constraints {
            try! db.addConstraint(constraint)
        }
        
        frame = db.deriveFrame()
        compiler = Compiler(frame: frame)
    }
    func testInitializeStocks() throws {
        
        let a = frame.createNode(ObjectType.Auxiliary,
                                 name: "a",
                                 attributes: ["formula": "1"])
        let b = frame.createNode(ObjectType.Auxiliary,
                                 name: "b",
                                 attributes: ["formula": "a + 1"])
        let c =  frame.createNode(ObjectType.Stock,
                                  name: "const",
                                  attributes: ["formula": "100"])
        let s_a = frame.createNode(ObjectType.Stock,
                                   name: "use_a",
                                   attributes: ["formula": "a"])
        let s_b = frame.createNode(ObjectType.Stock,
                                   name: "use_b",
                                   attributes: ["formula": "b"])

        frame.createEdge(ObjectType.Parameter, origin: a, target: b, components: [])
        frame.createEdge(ObjectType.Parameter, origin: a, target: s_a, components: [])
        frame.createEdge(ObjectType.Parameter, origin: b, target: s_b, components: [])
        
        let compiled = try compiler.compile()
        let solver = Solver(compiled)

        let state = solver.initialize()
        
        XCTAssertEqual(state[a], 1)
        XCTAssertEqual(state[b], 2)
        XCTAssertEqual(state[c], 100)
        XCTAssertEqual(state[s_a], 1)
        XCTAssertEqual(state[s_b], 2)
    }
    func testOrphanedInitialize() throws {
        
        let a = frame.createNode(ObjectType.Auxiliary,
                                 name: "a",
                                 attributes: ["formula": "1"])
        let compiled = try compiler.compile()
        let solver = Solver(compiled)
        
        let vector = solver.initialize()
        
        XCTAssertNotNil(vector[a])
    }
    func testEverythingInitialized() throws {
        let aux = frame.createNode(ObjectType.Auxiliary,
                                   name: "a",
                                   attributes: ["formula": "10"])
        let stock = frame.createNode(ObjectType.Stock,
                                     name: "b",
                                     attributes: ["formula": "20"])
        let flow = frame.createNode(ObjectType.Flow,
                                    name: "c",
                                    attributes: ["formula": "30"])

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
        let aux = frame.createNode(ObjectType.Auxiliary,
                                   name: "a",
                                   attributes: ["formula": "time"])
        let flow = frame.createNode(ObjectType.Flow,
                                    name: "f",
                                    attributes: ["formula": "time * 10"])

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
        let stock = frame.createNode(ObjectType.Stock,
                                     name: "stock",
                                     attributes: ["formula": "5"])
        let node = frame.node(stock)
        node.snapshot["allows_negative"] = ForeignValue(true)
        
        let flow = frame.createNode(ObjectType.Flow,
                                    name: "flow",
                                    attributes: ["formula": "10"])

        frame.createEdge(ObjectType.Drains, origin: stock, target: flow, components: [])
        
        let compiled = try compiler.compile()
        
        let solver = Solver(compiled)
        let initial = solver.initialize()
        let diff = solver.difference(at: 1.0, with: initial)

        XCTAssertEqual(diff[stock], -10)
    }

    func testNonNegativeStock() throws {
        let stock = frame.createNode(ObjectType.Stock,
                                     name: "stock",
                                     attributes: ["formula": "5"])
        let node = frame.node(stock)
        node.snapshot["allows_negative"] = ForeignValue(false)

        let flow = frame.createNode(ObjectType.Flow,
                                    name: "flow",
                                    attributes: ["formula": "10"])

        frame.createEdge(ObjectType.Drains, origin: stock, target: flow, components: [])
        
        let compiled = try compiler.compile()
        
        let solver = Solver(compiled)
        let initial = solver.initialize()
        let diff = solver.difference(at: 1.0, with: initial)

        XCTAssertEqual(diff[stock], -5)
    }
    // TODO: Also negative outflow
    func testNonNegativeStockNegativeInflow() throws {
        let stock = frame.createNode(ObjectType.Stock,
                                     name: "stock",
                                     attributes: ["formula": "5"])
        let obj = frame.node(stock)
        obj.snapshot["allows_negative"] = ForeignValue(false)
        // FIXME: There is a bug in the expression parser
        let flow = frame.createNode(ObjectType.Flow,
                                    name: "flow",
                                    attributes: ["formula": "0 - 10"])

        frame.createEdge(ObjectType.Fills, origin: flow, target: stock, components: [])
        
        let compiled = try compiler.compile()
        
        let solver = Solver(compiled)
        let initial = solver.initialize()
        let diff = solver.difference(at: 1.0, with: initial)

        XCTAssertEqual(diff[stock], 0)
    }

    func testStockNegativeOutflow() throws {
        let stock = frame.createNode(ObjectType.Stock,
                                     name: "stock",
                                     attributes: ["formula": "5"])
        let obj = frame.node(stock)
        obj.snapshot["allows_negative"] = ForeignValue(false)
        // FIXME: There is a bug in the expression parser
        let flow = frame.createNode(ObjectType.Flow,
                                    name: "flow",
                                    attributes: ["formula": "-10"])

        frame.createEdge(ObjectType.Drains, origin: stock, target: flow, components: [])
        
        let compiled = try compiler.compile()
        
        let solver = Solver(compiled)
        let initial = solver.initialize()
        let diff = solver.difference(at: 1.0, with: initial)

        XCTAssertEqual(diff[stock], 0)
    }

    func testNonNegativeToTwo() throws {
        // TODO: Break this into multiple tests
        let source = frame.createNode(ObjectType.Stock,
                                      name: "stock",
                                      attributes: ["formula": "5"])
        let sourceNode = frame.node(source)
        sourceNode.snapshot["allows_negative"] = ForeignValue(false)

        let happy = frame.createNode(ObjectType.Stock,
                                     name: "happy",
                                     attributes: ["formula": "0"])
        let sad = frame.createNode(ObjectType.Stock,
                                   name: "sad",
                                   attributes: ["formula": "0"])
        let happyFlow = frame.createNode(ObjectType.Flow,
                                         name: "happy_flow",
                                         attributes: ["formula": "10"])
        let happyFlowNode = frame.node(happyFlow)
        happyFlowNode.snapshot["priority"] = ForeignValue(1)

        frame.createEdge(ObjectType.Drains,
                         origin: source, target: happyFlow, components: [])
        frame.createEdge(ObjectType.Fills,
                         origin: happyFlow, target: happy, components: [])

        let sadFlow = frame.createNode(ObjectType.Flow,
                                       name: "sad_flow",
                                       attributes: ["formula": "10"])
        let sadFlowNode = frame.node(sadFlow)
        sadFlowNode.snapshot["priority"] = ForeignValue(2)

        frame.createEdge(ObjectType.Drains,
                         origin: source, target: sadFlow, components: [])
        frame.createEdge(ObjectType.Fills,
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
        let kettle = frame.createNode(ObjectType.Stock,
                                      name: "kettle",
                                      attributes: ["formula": "1000"])
        let flow = frame.createNode(ObjectType.Flow,
                                    name: "pour",
                                    attributes: ["formula": "100"])
        let cup = frame.createNode(ObjectType.Stock,
                                      name: "cup",
                                   attributes: ["formula": "0"])

        frame.createEdge(ObjectType.Drains,
                         origin: kettle, target: flow, components: [])
        frame.createEdge(ObjectType.Fills,
                         origin: flow, target: cup, components: [])

        let compiled = try compiler.compile()
        let solver = Solver(compiled)
        
        var state = solver.initialize(time: 1.0)
        
        state = solver.difference(at: 1.0, with: state, timeDelta: 1.0)
        XCTAssertEqual(state[kettle], -100.0)
        XCTAssertEqual(state[cup], 100.0)
    }

    
    func testCompute() throws {
        let kettle = frame.createNode(ObjectType.Stock,
                                      name: "kettle",
                                      attributes: ["formula": "1000"])
        let flow = frame.createNode(ObjectType.Flow,
                                    name: "pour",
                                    attributes: ["formula": "100"])
        let cup = frame.createNode(ObjectType.Stock,
                                      name: "cup",
                                   attributes: ["formula": "0"])

        frame.createEdge(ObjectType.Drains,
                         origin: kettle, target: flow, components: [])
        frame.createEdge(ObjectType.Fills,
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
        let p1 = frame.createNode(ObjectType.Auxiliary,
                                   name:"p1",
                                  attributes: ["formula": "0"])
        let g1 = frame.createNode(ObjectType.GraphicalFunction,
                                  name: "g1")

        let p2 = frame.createNode(ObjectType.Auxiliary,
                                   name:"p2",
                                  attributes: ["formula": "0"])
        let points = [Point(0.0, 10.0), Point(1.0, 10.0)]
        let g2 = frame.createNode(ObjectType.GraphicalFunction,
                                  name: "g2",
                                  attributes: ["graphical_function_points": ForeignValue(points)])
        let aux = frame.createNode(ObjectType.Auxiliary,
                                   name:"a",
                                   attributes: ["formula": "g1 + g2"])

        frame.createEdge(ObjectType.Parameter, origin: g1, target: aux)
        frame.createEdge(ObjectType.Parameter, origin: g2, target: aux)
        frame.createEdge(ObjectType.Parameter, origin: p1, target: g1)
        frame.createEdge(ObjectType.Parameter, origin: p2, target: g2)

        let compiled: CompiledModel = try compiler.compile()
        let solver = EulerSolver(compiled)
        let initial: SimulationState = solver.initialize()
        
        XCTAssertEqual(initial[g1], 0.0)
        XCTAssertEqual(initial[g2], 10.0)
        XCTAssertEqual(initial[aux], 10.0)

    }

}

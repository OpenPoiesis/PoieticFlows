//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 07/06/2023.
//

import XCTest
@testable import PoieticFlows
@testable import PoieticCore


final class TestDomainView: XCTestCase {
    // TODO: Split to Compiler and DomainView test cases
    
    var db: ObjectMemory!
    var frame: MutableFrame!
    var graph: MutableGraph!
    
    override func setUp() {
        db = ObjectMemory(metamodel: FlowsMetamodel)
        frame = db.deriveFrame()
        graph = frame.mutableGraph
//        Metamodel = BoundStockFlowMetamodel(FlowsMetamodel)
    }
    
    
    func testCompileExpressions() throws {
        throw XCTSkip("Conflicts with input validation, this test requires attention.")
#if false
        let names: [String:ObjectID] = [
            "a": 1,
            "b": 2,
        ]
        
        let l = graph.createNode(FlowsMetamodel.Stock,
                                 components: [FormulaComponent(name: "l",
                                                               expression: "sqrt(a*a + b*b)")])
        let view = StockFlowView(graph)
        
        let exprs = try view.boundExpressions(names: names)
        
        let varRefs = Set(exprs[l]!.allVariables)
        
        XCTAssertTrue(varRefs.contains(.object(1)))
        XCTAssertTrue(varRefs.contains(.object(2)))
        XCTAssertEqual(varRefs.count, 2)
#endif
    }
    
    func testSortedNodes() throws {
        // a -> b -> c
        
        let c = graph.createNode(Metamodel.Auxiliary,
                                 name: "c",
                                 components: [FormulaComponent(expression:"b")])
        let b = graph.createNode(Metamodel.Auxiliary,
                                 name: "b",
                                 components: [FormulaComponent(expression:"a")])
        let a = graph.createNode(Metamodel.Auxiliary,
                                 name: "a",
                                 components: [FormulaComponent(expression:"0")])
        
        
        graph.createEdge(Metamodel.Parameter,
                         origin: a,
                         target: b,
                         components: [])
        graph.createEdge(Metamodel.Parameter,
                         origin: b,
                         target: c,
                         components: [])
        
        let view = StockFlowView(frame)
        let sortedNodes = try view.sortedNodesByParameter([b, c, a])
        
        if sortedNodes.isEmpty {
            XCTFail("Sorted expression nodes must not be empty")
            return
        }
        
        XCTAssertEqual(sortedNodes.count, 3)
        XCTAssertEqual(sortedNodes[0].id, a)
        XCTAssertEqual(sortedNodes[1].id, b)
        XCTAssertEqual(sortedNodes[2].id, c)
    }
    
    func testInvalidInput2() throws {
        let broken = graph.createNode(Metamodel.Stock,
                                      name: "broken",
                                      components: [FormulaComponent(expression: "price")])
        let view = StockFlowView(frame)
        
        let parameters = view.parameters(broken, required:["price"])
        XCTAssertEqual(parameters.count, 1)
        XCTAssertEqual(parameters["price"], ParameterStatus.missing)
    }

    func testUnusedInputs() throws {
        let used = graph.createNode(Metamodel.Auxiliary,
                                    name: "used",
                                    components: [FormulaComponent(expression:"0")])
        let unused = graph.createNode(Metamodel.Auxiliary,
                                      name: "unused",
                                      components: [FormulaComponent(expression:"0")])
        let tested = graph.createNode(Metamodel.Auxiliary,
                                      name: "tested",
                                      components: [FormulaComponent(expression:"used")])
        
        let usedEdge = graph.createEdge(Metamodel.Parameter,
                         origin: used,
                         target: tested,
                         components: [])
        let unusedEdge = graph.createEdge(Metamodel.Parameter,
                         origin: unused,
                         target: tested,
                         components: [])
        
        let view = StockFlowView(frame)
        
        // TODO: Get the required list from the compiler
        let parameters = view.parameters(tested, required:["used"])

        XCTAssertEqual(parameters.count, 2)
        XCTAssertEqual(parameters["unused"],
                       ParameterStatus.unused(node: unused, edge: unusedEdge))
        XCTAssertEqual(parameters["used"],
                       ParameterStatus.used(node: used, edge: usedEdge))
    }

    func testUnknownParameters() throws {
        let known = graph.createNode(Metamodel.Auxiliary,
                                     name: "known",
                                     components: [FormulaComponent(expression:"0")])
        let tested = graph.createNode(Metamodel.Auxiliary,
                                      name: "tested",
                                      components: [FormulaComponent(expression:"known + unknown")])
        
        let knownEdge = graph.createEdge(Metamodel.Parameter,
                         origin: known,
                         target: tested,
                         components: [])
        
        let view = StockFlowView(frame)
        
        let parameters = view.parameters(tested, required:["known", "unknown"])
        XCTAssertEqual(parameters.count, 2)
        XCTAssertEqual(parameters["known"],
                       ParameterStatus.used(node: known, edge: knownEdge))
        XCTAssertEqual(parameters["unknown"],
                       ParameterStatus.missing)
    }
    
    func testFlowFillsAndDrains() throws {
        let flow = graph.createNode(Metamodel.Flow,
                                    name: "f",
                                    components: [FormulaComponent(expression:"1")])
        let source = graph.createNode(Metamodel.Stock,
                                      name: "source",
                                      components: [FormulaComponent(expression:"0")])
        let sink = graph.createNode(Metamodel.Stock,
                                    name: "sink",
                                    components: [FormulaComponent(expression:"0")])
        
        graph.createEdge(Metamodel.Drains,
                         origin: source,
                         target: flow,
                         components: [])
        graph.createEdge(Metamodel.Fills,
                         origin: flow,
                         target: sink,
                         components: [])
        
        let view = StockFlowView(frame)
        
        XCTAssertEqual(view.flowFills(flow), sink)
        XCTAssertEqual(view.flowDrains(flow), source)
    }
}

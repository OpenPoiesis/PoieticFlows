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
//        Metamodel = BoundStockFlowMetamodel(FlowsMetamodel)
    }
    
    
    func testCompileExpressions() throws {
        throw XCTSkip("Conflicts with input validation, this test requires attention.")
#if false
        let names: [String:ObjectID] = [
            "a": 1,
            "b": 2,
        ]
        
        let l = frame.createNode(FlowsMetamodel.Stock,
                                 traits: [FormulaComponent(name: "l",
                                                               expression: "sqrt(a*a + b*b)")])
        let view = StockFlowView(frame)
        
        let exprs = try view.boundExpressions(names: names)
        
        let varRefs = Set(exprs[l]!.allVariables)
        
        XCTAssertTrue(varRefs.contains(.object(1)))
        XCTAssertTrue(varRefs.contains(.object(2)))
        XCTAssertEqual(varRefs.count, 2)
#endif
    }
    
    func testSortedNodes() throws {
        // a -> b -> c
        
        let c = frame.createNode(Metamodel.Auxiliary,
                                 name: "c",
                                 attributes: ["formula": "b"])
        let b = frame.createNode(Metamodel.Auxiliary,
                                 name: "b",
                                 attributes: ["formula": "a"])
        let a = frame.createNode(Metamodel.Auxiliary,
                                 name: "a",
                                 attributes: ["formula": "0"])

        
        frame.createEdge(Metamodel.Parameter,
                         origin: a,
                         target: b,
                         components: [])
        frame.createEdge(Metamodel.Parameter,
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
        let broken = frame.createNode(Metamodel.Stock,
                                      name: "broken",
                                      attributes: ["formula": "price"])
        let view = StockFlowView(frame)
        
        let parameters = view.parameters(broken, required:["price"])
        XCTAssertEqual(parameters.count, 1)
        XCTAssertEqual(parameters["price"], ParameterStatus.missing)
    }

    func testUnusedInputs() throws {
        let used = frame.createNode(Metamodel.Auxiliary,
                                    name: "used",
                                    attributes: ["formula": "0"])
        let unused = frame.createNode(Metamodel.Auxiliary,
                                      name: "unused",
                                      attributes: ["formula": "0"])
        let tested = frame.createNode(Metamodel.Auxiliary,
                                      name: "tested",
                                      attributes: ["formula": "used"])

        let usedEdge = frame.createEdge(Metamodel.Parameter,
                         origin: used,
                         target: tested,
                         components: [])
        let unusedEdge = frame.createEdge(Metamodel.Parameter,
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
        let known = frame.createNode(Metamodel.Auxiliary,
                                     name: "known",
                                     attributes: ["formula": "0"])
        let tested = frame.createNode(Metamodel.Auxiliary,
                                      name: "tested",
                                      attributes: ["formula": "known + unknown"])

        let knownEdge = frame.createEdge(Metamodel.Parameter,
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
        let flow = frame.createNode(Metamodel.Flow,
                                    name: "f",
                                    attributes: ["formula": "1"])
        let source = frame.createNode(Metamodel.Stock,
                                      name: "source",
                                      attributes: ["formula": "0"])
        let sink = frame.createNode(Metamodel.Stock,
                                    name: "sink",
                                    attributes: ["formula": "0"])

        frame.createEdge(Metamodel.Drains,
                         origin: source,
                         target: flow,
                         components: [])
        frame.createEdge(Metamodel.Fills,
                         origin: flow,
                         target: sink,
                         components: [])
        
        let view = StockFlowView(frame)
        
        XCTAssertEqual(view.flowFills(flow), sink)
        XCTAssertEqual(view.flowDrains(flow), source)
    }
}

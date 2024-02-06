//
//  ControlsTests.swift
//  
//
//  Created by Stefan Urbanek on 25/08/2023.
//

import XCTest
@testable import PoieticFlows
@testable import PoieticCore


final class TestControls: XCTestCase {
    var memory: ObjectMemory!
    var simulator: Simulator!
    var frame: MutableFrame!
    var graph: MutableGraph!
    
    override func setUp() {
        memory = ObjectMemory(metamodel: FlowsMetamodel.self)
        simulator = Simulator(memory: memory)
        frame = memory.deriveFrame()
        graph = frame.mutableGraph
    }
    
    func testBinding() throws {
        let a = graph.createNode(Metamodel.Auxiliary,
                                 name: "a",
                                 components: [FormulaComponent(expression: "10")])
        let control = graph.createNode(Metamodel.Control,
                                 name: "control",
                                 components: [ControlComponent()])
        let binding = graph.createEdge(Metamodel.ValueBinding,
                                       origin: control,
                                       target: a)
        try simulator.compile(frame)
        
        simulator.initializeSimulation()
        
        let controlObj = frame.object(control)
        XCTAssertEqual(controlObj[ControlComponent.self]!.value, 10)
    }
}

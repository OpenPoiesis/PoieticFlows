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
    
    override func setUp() {
        memory = ObjectMemory(metamodel: FlowsMetamodel.self)
        simulator = Simulator(memory: memory)
        frame = memory.deriveFrame()
    }
    
    func testBinding() throws {
        let a = frame.createNode(ObjectType.Auxiliary,
                                 name: "a",
                                 attributes: ["formula": "10"])
        let control = frame.createNode(ObjectType.Control,
                                 name: "control")
        let binding = frame.createEdge(ObjectType.ValueBinding,
                                       origin: control,
                                       target: a)
        try simulator.compile(frame)
        
        simulator.initializeSimulation()
        
        let controlObj = frame.object(control)
        XCTAssertEqual(try! controlObj["value"]!.doubleValue(), 10)
    }
}

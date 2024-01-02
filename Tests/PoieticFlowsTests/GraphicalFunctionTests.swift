//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 10/07/2023.
//

import XCTest
@testable import PoieticFlows
@testable import PoieticCore

final class GraphicalFunctionTests: XCTestCase {
    func testEmpty() throws {
        let gf = GraphicalFunction(points: [])
        XCTAssertEqual(gf.nearestXPoint(0.0), Point(x:0.0, y:0.0))
    }
    func testOneValue() throws {
        let gf = GraphicalFunction(points: [Point(x:1.0, y:10.0)])
        XCTAssertEqual(gf.nearestXPoint(0.0), Point(x:1.0, y:10.0))
    }
    func testTwoValues() throws {
        let gf = GraphicalFunction(points:[
            Point(x:1.0, y:10.0),
            Point(x:2.0, y:20.0),
        ])
        XCTAssertEqual(gf.nearestXPoint(0.0), Point(x:1.0, y:10.0))
        XCTAssertEqual(gf.nearestXPoint(0.5), Point(x:1.0, y:10.0))
        XCTAssertEqual(gf.nearestXPoint(1.0), Point(x:1.0, y:10.0))
        XCTAssertEqual(gf.nearestXPoint(1.2), Point(x:1.0, y:10.0))
        XCTAssertEqual(gf.nearestXPoint(1.8), Point(x:2.0, y:20.0))
        XCTAssertEqual(gf.nearestXPoint(2.0), Point(x:2.0, y:20.0))
        XCTAssertEqual(gf.nearestXPoint(3.0), Point(x:2.0, y:20.0))
    }
    func testFunc() throws {
        let gf = GraphicalFunction(points:[
            Point(x:1.0, y:10.0),
            Point(x:2.0, y:20.0),
        ])
        let f = gf.createFunction(name: "test")
        XCTAssertEqual(try f.apply([0.0]), 10.0)
        XCTAssertEqual(try f.apply([0.5]), 10.0)
        XCTAssertEqual(try f.apply([1.0]), 10.0)
        XCTAssertEqual(try f.apply([1.2]), 10.0)
        XCTAssertEqual(try f.apply([1.8]), 20.0)
        XCTAssertEqual(try f.apply([2.0]), 20.0)
        XCTAssertEqual(try f.apply([3.0]), 20.0)
    }
}

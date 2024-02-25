//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 09/06/2023.
//

import XCTest
@testable import PoieticFlows
@testable import PoieticCore

final class BuiltinFunctionTests: XCTestCase {
    func testAllBuiltinsHaveReturnType() throws {
        for function in AllBuiltinFunctions {
            if function.signature.returnType == nil {
                XCTFail("Built-in function \(function.name) has no return type specified")
            }
            if function.signature.returnType != .double {
                XCTFail("Built-in function \(function.name) does not have a double return type")
            }
        }
    }
}

final class TestCompiler: XCTestCase {
    var db: ObjectMemory!
    var frame: MutableFrame!
    
    override func setUp() {
        db = ObjectMemory(metamodel: FlowsMetamodel)
        frame = db.deriveFrame()
    }
    
    func testComputedVariables() throws {
        let compiler = Compiler(frame: frame)
        frame.createNode(ObjectType.Stock,
                         name: "a",
                         attributes: ["formula": "0"])
        frame.createNode(ObjectType.Stock,
                         name: "b",
                         attributes: ["formula": "0"])
        frame.createNode(ObjectType.Stock,
                         name: "c",
                         attributes: ["formula": "0"])
        frame.createNode(ObjectType.Note,
                         name: "note",
                         components: [])
        // TODO: Check using violation checker
        
        let compiled = try compiler.compile()
        let names = compiled.computedVariables.map { $0.name }
            .sorted()
        
        XCTAssertEqual(names, ["a", "b", "c"])
    }
    
    func testValidateDuplicateName() throws {
        let compiler = Compiler(frame: frame)
        let c1 = frame.createNode(ObjectType.Stock,
                                  name: "things",
                                  attributes: ["formula": "0"])
        let c2 = frame.createNode(ObjectType.Stock,
                                  name: "things",
                                  attributes: ["formula": "0"])
        frame.createNode(ObjectType.Stock,
                         name: "a",
                         attributes: ["formula": "0"])
        frame.createNode(ObjectType.Stock,
                         name: "b",
                         attributes: ["formula": "0"])

        // TODO: Check using violation checker
        
        XCTAssertThrowsError(try compiler.compile()) {
            guard let error = $0 as? NodeIssuesError else {
                XCTFail("Expected DomainError, got: \($0)")
                return
            }
            
            XCTAssertNotNil(error.issues[c1])
            XCTAssertNotNil(error.issues[c2])
            XCTAssertEqual(error.issues.count, 2)
        }
    }

    
    func testInflowOutflow() throws {
        let source = frame.createNode(ObjectType.Stock,
                                      name: "source",
                                      attributes: ["formula": "0"])
        let flow = frame.createNode(ObjectType.Flow,
                                    name: "f",
                                    attributes: ["formula": "1"])
        let sink = frame.createNode(ObjectType.Stock,
                                    name: "sink",
                                    attributes: ["formula": "0"])

        frame.createEdge(ObjectType.Drains,
                         origin: source,
                         target: flow,
                         components: [])
        frame.createEdge(ObjectType.Fills,
                         origin: flow,
                         target: sink,
                         components: [])
        
        let compiler = Compiler(frame: frame)
        let compiled = try compiler.compile()
        
        XCTAssertEqual(compiled.stocks.count, 2)
        XCTAssertEqual(compiled.stocks[0].id, source)
        XCTAssertEqual(compiled.stocks[0].inflows, [])
        XCTAssertEqual(compiled.stocks[0].outflows, [compiled.computedVariableIndex(of: flow)])

        XCTAssertEqual(compiled.stocks[1].id, sink)
        XCTAssertEqual(compiled.stocks[1].inflows, [compiled.computedVariableIndex(of: flow)])
        XCTAssertEqual(compiled.stocks[1].outflows, [])
    }
    
    func testUpdateImplicitFlows() throws {
        // TODO: No compiler needed, now it is using a transformation system
        let flow = frame.createNode(ObjectType.Flow,
                                    name: "f",
                                    attributes: ["formula": "1"])
        let source = frame.createNode(ObjectType.Stock,
                                      name: "source",
                                      attributes: ["formula": "0"])
        let sink = frame.createNode(ObjectType.Stock,
                                    name: "sink",
                                    attributes: ["formula": "0"])

        frame.createEdge(ObjectType.Drains,
                         origin: source,
                         target: flow,
                         components: [])
        frame.createEdge(ObjectType.Fills,
                         origin: flow,
                         target: sink,
                         components: [])
        
        let view = StockFlowView(frame)
        
        XCTAssertEqual(view.implicitDrains(source).count, 0)
        XCTAssertEqual(view.implicitFills(sink).count, 0)
        XCTAssertEqual(view.implicitDrains(source).count, 0)
        XCTAssertEqual(view.implicitFills(sink).count, 0)
        
        var system = ImplicitFlowsTransformer()
        let context = TransformationContext(frame: frame)
        system.update(context)
        
        let src_drains = view.implicitDrains(source)
        let sink_drains = view.implicitDrains(sink)
        let src_fills = view.implicitFills(source)
        let sink_fills = view.implicitFills(sink)
        
        XCTAssertEqual(src_drains.count, 0)
        XCTAssertEqual(sink_drains.count, 1)
        XCTAssertEqual(sink_drains[0], source)
        XCTAssertEqual(src_fills.count, 1)
        XCTAssertEqual(src_fills[0], sink)
        XCTAssertEqual(sink_fills.count, 0)
    }
    
    func testDisconnectedGraphicalFunction() throws {
        let compiler = Compiler(frame: frame)
        let gf = frame.createNode(ObjectType.GraphicalFunction,
                                  name: "g")

        XCTAssertThrowsError(try compiler.compile()) {
            guard let error = $0 as? NodeIssuesError else {
                XCTFail("Expected DomainError, got: \($0)")
                return
            }
            
            guard let first = error.issues[gf]?.first else {
                XCTFail("Expected an issue")
                return
            }
            
            XCTAssertEqual(error.issues.count, 1)

            guard let issue = first as? NodeIssue else {
                XCTFail("Did not get expected node issue error type")
                return
            }
            XCTAssertEqual(issue, NodeIssue.missingGraphicalFunctionParameter)
            
        }
    }

    func testGraphicalFunctionNameReferences() throws {
        let compiler = Compiler(frame: frame)

        let param = frame.createNode(ObjectType.Auxiliary,
                                  name: "p",
                                     attributes: ["formula": "1"])
        let gf = frame.createNode(ObjectType.GraphicalFunction,
                                  name: "g")
        let aux = frame.createNode(ObjectType.Auxiliary,
                                   name:"a",
                                   attributes: ["formula": "g"])

        frame.createEdge(ObjectType.Parameter, origin: param, target: gf)
        frame.createEdge(ObjectType.Parameter, origin: gf, target: aux)

        let compiled = try compiler.compile()

        let funcs = compiled.graphicalFunctions
        XCTAssertEqual(funcs.count, 1)

        let boundFn = funcs.first!
        XCTAssertEqual(boundFn.id, gf)
        XCTAssertEqual(boundFn.parameterIndex, compiled.computedVariableIndex(of:param))

        XCTAssertTrue(compiled.computedVariables.contains { $0.name == "g" })
        
        let issues = compiler.validateParameters(aux, required: ["g"])
        XCTAssertTrue(issues.isEmpty)
    }


    func testGraphicalFunctionComputation() throws {
        let p = frame.createNode(ObjectType.Auxiliary,
                                   name:"p",
                                 attributes: ["formula": "0"])

        let gf = frame.createNode(ObjectType.GraphicalFunction,
                                  name: "g")
        let aux = frame.createNode(ObjectType.Auxiliary,
                                   name:"a",
                                   attributes: ["formula": "g"])

        frame.createEdge(ObjectType.Parameter, origin: p, target: gf)
        frame.createEdge(ObjectType.Parameter, origin: gf, target: aux)

        let compiler = Compiler(frame: frame)
        let compiled = try compiler.compile()
        guard let variable = compiled.variable(for: gf) else {
            XCTFail("No compiled variable for the graphical function")
            return
        }

        switch variable.computation {
        case .formula(_): XCTFail("Graphical function compiled as formula")
        case .graphicalFunction(let fn, _):
            XCTAssertEqual(fn.name, "__graphical_\(gf)")
        }
    }

}

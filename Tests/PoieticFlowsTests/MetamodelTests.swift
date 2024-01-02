//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 09/07/2023.
//

import XCTest
@testable import PoieticFlows
@testable import PoieticCore


final class TestFlowsMetamodel: XCTestCase {
    func testUniqueNames() throws {
        
        for type in FlowsMetamodel.objectTypes {
            var attributes: [String:[String]] = [:]

            for component in type.inspectableComponents {
                let desc = component.componentSchema
                for attribute in desc.attributes {
                    attributes[attribute.name, default: []].append(desc.name)
                }
            }
            for (attr, components) in attributes {
                if components.count > 1 {
                    let compList = components.joined(separator: ", ")
                    XCTFail("Metamodel object type \(type.name) has duplicate attribute '\(attr)', in: \(compList)")
                }
            }
        }

        
    }
}

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

            for trait in type.traits {
                for attribute in trait.attributes {
                    attributes[attribute.name, default: []].append(trait.name)
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

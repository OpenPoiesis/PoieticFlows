//
//  Metamodel.swift
//  
//
//  Created by Stefan Urbanek on 06/06/2023.
//

import PoieticCore

public let FlowsMetamodel = Metamodel(name: "Flows",
                                      merging: Metamodel.Basic,
                                               Metamodel.StockFlow)

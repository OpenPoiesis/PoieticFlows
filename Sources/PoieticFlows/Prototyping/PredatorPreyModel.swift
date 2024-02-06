//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 11/07/2022.
//

// Prototyping functions - to be used only during development
//


import PoieticCore

#if false

extension MutableGraph {
    func createStock(name: String, expression: String) -> ObjectID {
        let node = createNode(FlowsMetamodel.Stock,
                              name: name,
                              components: [FormulaComponent(expression: expression)])
        return node
    }
    
    func createAux(name: String, expression: String) -> ObjectID {
        let node = createNode(FlowsMetamodel.Auxiliary,
                              name: name,
                              components: [FormulaComponent(expression: expression)])
        return node
    }
    func createFlow(name: String, expression: String) -> ObjectID {
        let node = createNode(FlowsMetamodel.Flow,
                              name: name,
                              components: [FormulaComponent(expression: expression)])
        return node
    }
    
    func connectParameter(from origin: ObjectID, to target: ObjectID) {
        self.createEdge(FlowsMetamodel.Parameter,
                         origin: origin,
                         target: target,
                         components: [])
    }
    
    func connectOutflow(from origin: ObjectID, to target: ObjectID) {
        self.createEdge(FlowsMetamodel.Drains,
                         origin: origin,
                         target: target,
                         components: [])
    }

    func connectInflow(from origin: ObjectID, to target: ObjectID) {
        self.createEdge(FlowsMetamodel.Fills,
                         origin: origin,
                         target: target,
                         components: [])
    }
}


/// Create a demo model in a memory.
///
/// This function creates a
/// [Lotka-Volterra](https://en.wikipedia.org/wiki/Lotka–Volterra_equations)
/// model with two stocks: sharks and fish, and four flows: births and deaths
/// of both of the entities represented by the stocks.
///
/// Use:
///
/// ```swift
/// let memory: ObjectMemory
///
/// CreatePredatorPreyDemo(in: memory)
///
/// ```
///
/// The created model is accepted into the memory and is available
/// as the last frame in the memory frame history, also known as the
/// "current frame".
///
public func CreatePredatorPreyDemo(in memory: ObjectMemory) throws {
    let frame = memory.deriveFrame()
    let graph = frame.mutableGraph
    
    let fish = graph.createStock(name: "fish", expression: "1000")
    let shark = graph.createStock(name: "shark", expression: "10")

    let fish_birth_rate = graph.createAux(name: "fish_birth_rate", expression: "0.01" )
    let shark_birth_rate = graph.createAux(name: "shark_birth_rate", expression: "0.6" )
    let shark_efficiency = graph.createAux(name: "shark_efficiency", expression: "0.0003" )
    let shark_death_rate = graph.createAux(name: "shark_death_rate", expression: "0.15" )

    let fish_births = graph.createFlow(name: "fish_births", expression: "fish * fish_birth_rate")
    let shark_births = graph.createFlow(name: "shark_births", expression: "shark * shark_birth_rate * shark_efficiency * fish")
    let fish_deaths = graph.createFlow(name: "fish_deaths", expression: "fish * shark_efficiency * shark")
    let shark_deaths = graph.createFlow(name: "shark_deaths", expression: "shark_death_rate * shark")

    graph.connectParameter(from: fish_birth_rate, to: fish_births)
    graph.connectParameter(from: fish, to: fish_births)
    graph.connectInflow(from: fish_births, to: fish)

    graph.connectParameter(from: shark_birth_rate, to: shark_births)
    graph.connectParameter(from: shark, to: shark_births)
    graph.connectParameter(from: shark_efficiency, to: shark_births)
    graph.connectParameter(from: fish, to: shark_births)
    graph.connectInflow(from: shark_births, to: shark)

    graph.connectParameter(from: fish, to: fish_deaths)
    graph.connectParameter(from: shark_efficiency, to: fish_deaths)
    graph.connectParameter(from: shark, to: fish_deaths)
    graph.connectOutflow(from: fish, to: fish_deaths)

    graph.connectParameter(from: shark, to: shark_deaths)
    graph.connectParameter(from: shark_death_rate, to: shark_deaths)
    graph.connectOutflow(from: shark, to: shark_deaths)

    try memory.accept(frame)
}

#endif

//
//  DotStyle.swift
//  
//
//  Created by Stefan Urbanek on 18/07/2022.
//
import PoieticCore

/// Object that encapsulates multiple styles for nodes and edges of a Graphviz
/// graph.
///
public final class DotStyle: Sendable {
    /// List of edge styles
    public let edgeStyles: [DotEdgeStyle]
    /// List of node styles
    public let nodeStyles: [DotNodeStyle]
    
    public init(nodes: [DotNodeStyle]? = nil, edges: [DotEdgeStyle]? = nil){
        self.edgeStyles = edges ?? []
        self.nodeStyles = nodes ?? []
    }
}

/// Style of an edge for Graphviz/DOT export.
///
public struct DotEdgeStyle: Sendable {
    /// Predicate that determines which edges match this style.
    ///
    public let predicate: Predicate

    /// List of attributes to apply to the edge.
    ///
    public let attributes: [String:String]

    /// Creates a Graphviz edge style for edges that match the predicate
    /// `predicate`. The style is defined by the `attributes`.
    ///
    public init(predicate: Predicate, attributes: [String:String]) {
        self.predicate = predicate
        self.attributes = attributes
    }
}

/// Style of a node for Graphviz/DOT export.
///
public struct DotNodeStyle: Sendable {
    /// Predicate that determines which nodes match this style.
    ///
    public let predicate: Predicate

    /// List of attributes to apply to the edge.
    ///
    public let attributes: [String:String]
    
    /// Creates a Graphviz node style for nodes that match the predicate
    /// `predicate`. The style is defined by the `attributes`.
    ///
    public init(predicate: Predicate, attributes: [String:String]) {
        self.predicate = predicate
        self.attributes = attributes
    }
}

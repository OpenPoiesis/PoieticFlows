//
//  File.swift
//
//
//  Created by Stefan Urbanek on 2021/10/21.
//

import SystemPackage
import PoieticCore

// NOTE: This is simple one-use exporter.
// TODO: Make this export to a string and make it export by appending content.

/// Object that exports nodes and edges into a [GraphViz](https://graphviz.org)
/// dot language file.
public class DotExporter {
    /// Path of the file to be exported to.
    let path: FilePath

    /// Name of the graph in the output file.
    let name: String
    
    /// Attribute of nodes that will be used as a node label in the output.
    /// If not set then the node ID will be used.
    ///
    let labelAttribute: String?
    
    /// Label used when an object has no label attribute
    let missingLabel: String?
    
    /// Style and formatting of the output.
    ///
    let style: DotStyle?

    /// Creates a GraphViz DOT file exporter.
    ///
    /// - Parameters:
    ///     - path: Path to the file where the output is written
    ///     - name: Name of the graph in the output
    ///     - labelAttribute: Attribute of exported nodes that will be used
    ///     as a label of nodes in the output. If not set then node ID will be
    ///     used.
    ///
    public init(path: FilePath,
                name: String,
                labelAttribute: String? = nil,
                missingLabel: String? = nil,
                style: DotStyle? = nil) {
        self.path = path
        self.name = name
        self.labelAttribute = labelAttribute
        self.missingLabel = missingLabel
        self.style = style
    }
    
    /// Export nodes and edges into the output.
    public func export(graph: Graph) throws {
        var output: String = ""
        let formatter = DotFormatter(name: name, type: .directed)

        output = formatter.header()
        
        for node in graph.nodes {
            let label: String

            if let attribute = labelAttribute {
                if let value = node.attribute(forKey: attribute) {
                    label = String(describing: value)
                }
                else if let missingLabel {
                    label = missingLabel
                }
                else {
                    label = String(node.id)
                }
            }
            else {
                label = String(node.id)
            }

            var attributes = format(graph: graph, node: node)
            attributes["label"] = label

            let id = "\(node.id)"
            output += formatter.node(id, attributes: attributes)
        }

        for edge in graph.edges {
            let attributes = format(graph: graph, edge: edge)
            // TODO: Edge label
            
            output += formatter.edge(from:"\(edge.origin)",
                                     to:"\(edge.target)",
                                     attributes: attributes)
        }

        output += formatter.footer()
        
        let file = try FileDescriptor.open(path, .writeOnly,
                                           options: [.truncate, .create],
                                           permissions: .ownerReadWrite)
        try file.closeAfter {
          _ = try file.writeAll(output.utf8)
        }
    }
    
    public func format(graph: Graph, node: Node) -> [String:String] {
        var combined: [String:String] = [:]
        
        for style in style?.nodeStyles ?? [] {
            if style.predicate.match(frame: graph.frame, object: node.snapshot) {
                combined.merge(style.attributes) { (_, new) in new}
            }
        }
        
        return combined
    }

    public func format(graph: Graph, edge: Edge) -> [String:String] {
        var combined: [String:String] = [:]
        
        for style in style?.edgeStyles ?? [] {
            if style.predicate.match(frame: graph.frame, object: edge.snapshot) {
                combined.merge(style.attributes) { (_, new) in new}
            }
        }
        
        return combined
    }
}


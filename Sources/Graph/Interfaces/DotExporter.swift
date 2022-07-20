//
//  File.swift
//
//
//  Created by Stefan Urbanek on 2021/10/21.
//

import SystemPackage


// NOTE: This is simple one-use exporter.
// TODO: Make this export to a string and make it export by appending content.

/// Object that exports nodes and links into a [GraphViz](https://graphviz.org)
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
    public init(path: FilePath, name: String, labelAttribute: String? = nil, style: DotStyle? = nil) {
        self.path = path
        self.name = name
        self.labelAttribute = labelAttribute
        self.style = style
    }
    
    /// Export nodes and links into the output.
    public func export(nodes: [Node], links: [Link]) throws {
        var output: String = ""
        let formatter = DotFormatter(name: name, type: .directed)

        output = formatter.header()
        
        for node in nodes {
            let label: String

            if let attribute = labelAttribute {
                if let value = node.attribute(forKey: attribute) {
                    label = String(describing: value)
                }
                else {
                    label = node.id.map { String($0) } ?? "(no label)"
                }
            }
            else {
                label = node.id.map { String($0) } ?? "(no ID)"
            }

            var attributes = format(node: node)
            attributes["label"] = label

            let id = "\(node.id ?? 0)"
            output += formatter.node(id, attributes: attributes)
        }

        for link in links {
            let attributes = format(link: link)
            // TODO: Link label
            
            output += formatter.edge(from:"\(link.origin.id ?? 0)",
                                     to:"\(link.target.id ?? 0)",
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
    
    public func format(node: Node) -> [String:String] {
        var combined: [String:String] = [:]
        
        for style in style?.nodeStyles ?? [] {
            if style.predicate.match(node) {
                combined.merge(style.attributes) { (_, new) in new}
            }
        }
        
        return combined
    }

    public func format(link: Link) -> [String:String] {
        var combined: [String:String] = [:]
        
        for style in style?.linkStyles ?? [] {
            if style.predicate.match(link) {
                combined.merge(style.attributes) { (_, new) in new}
            }
        }
        
        return combined
    }
}


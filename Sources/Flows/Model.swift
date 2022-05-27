//
//  Model.swift
//  
//
//  Created by Stefan Urbanek on 26/05/2022.
//

import Foundation

public enum ModelError: Error, Equatable {
    /// Flow's input and output are the same node
    case sameFlowInputOutput(Flow)
    
    /// There are multiple nodes with the same name
    case duplicateName(String, Set<Node>)
    
    /// Connected node is not used.
    case unusedInput(String, Node)
    
    /// Cycle in computation graph has been detected.
    case cycle(Node)
}

public class Model {
    // TODO: Unify these as nodes
    var nodes: [Node]
    
    // Convenience
    var containers: [Container] { nodes.compactMap { $0 as? Container } }
    var flows: [Flow] { nodes.compactMap { $0 as? Flow } }
    var formulas: [Formula] { nodes.compactMap { $0 as? Formula } }

    var links: [Link]

    init(nodes: [Node]=[],
         links: [Link]=[]) {
        self.nodes = nodes
        self.links = links
        // FIXME: Validate model here?
    }
    
    func inflows(_ container: Container) -> [Flow] {
        return flows.filter { $0.target === container }
    }
    
    func outflows(_ container: Container) -> [Flow] {
        return flows.filter { $0.origin === container }
    }

    func parameters(for node: Node) -> [Formula] {
        let params = links.filter {
            $0.target === node
        }.compactMap { $0.target as? Formula }
        return params
    }
    /// Return a node with given name. If no such node exists, then returns
    /// `nil`.
    ///
    func node(_ name: String) -> Node? {
        return nodes.first { $0.name == name }
    }
    
    subscript(_ name: String) -> Node? {
        get {
            return node(name)
        }
    }
    
    // MARK: Actions
    
    public func add(_ node: Node) {
        precondition(!nodes.contains { $0 === node})
        nodes.append(node)
    }
    
    /// Connect input of the flow to be the container `container`. Replaces
    /// previous connection.
    ///
    public func connect(_ flow: Flow, from container: Container) {
        flow.origin = container
    }

    /// Connect output of the flow to be the container `container`. Replaces
    /// previous connection.
    ///
    public func connect(_ flow: Flow, to container: Container) {
        flow.target = container
    }
    
    public func connect(from origin: Node, to target: Node) {
        let link = Link(from: origin, to: target)
        self.links.append(link)
    }
    
    /// Return all outgoing links from a node
    public func outgoing(_ node: Node) -> [Link] {
        return links.filter { $0.origin === node }
    }

    /// Return all incoming links to a node
    public func incoming(_ node: Node) -> [Link] {
        return links.filter { $0.target === node }
    }

    /// Return all outgoing links from a node
    public func inputs(_ node: Node) -> [Node] {
        return incoming(node).map { $0.origin }
    }

    
    // Add container
    // Remove container
    // Add flow
    // Remove flow
    // Connect flow input
    // Connect flow output
    // Connect flow input and output
    // Add formula
    // Remove formula
    // Connect node
    // Set node name
}


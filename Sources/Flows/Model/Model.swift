//
//  Model.swift
//  
//
//  Created by Stefan Urbanek on 26/05/2022.
//

import Graph

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

public enum LinkType: String {
    case flow
    case parameter
}

public class Model {
    static let FlowLabel = "flow"
    static let ParameterLabel = "parameter"
    static let ExpressionLabel = "expression"

    /// Structure that holds all model objects – nodes and links.
    ///
    let graph: Graph
    
    /// Sequence of IDs that are assigned to the model objects for user-facing
    /// identification.
    ///
    let idSequence: SequentialIDGenerator = SequentialIDGenerator()
    
    var expressionNodes: [ExpressionNode] { graph.nodes.compactMap { $0 as? ExpressionNode } }
    
    var containers: [Container] { graph.nodes.compactMap { $0 as? Container } }
    var flows: [Flow] { graph.nodes.compactMap { $0 as? Flow } }
    var formulas: [Transform] { graph.nodes.compactMap { $0 as? Transform } }

    var flowLinks: [Link] {
        graph.links.filter { $0.contains(label: Model.FlowLabel) }
    }
    var parameterLinks: [Link] {
        graph.links.filter { $0.contains(label: Model.ParameterLabel) }
    }
    
    // MARK: - Initialisation
    
    public init(graph: Graph? = nil) {
        self.graph = graph ?? Graph()
    }
       
    // MARK: - Query

    /// Return all outgoing links from a node
    public func outgoing(_ node: Node) -> [Link] {
        return graph.outgoing(node)
    }

    /// Return all incoming links to a node
    public func incoming(_ node: Node) -> [Link] {
        return graph.incoming(node)
    }

    /// Returns a container that is drained by the flow – that is a container
    /// to which the flow is an outflow. Returns `nil` if
    /// no container is being drained by the given flow.
    ///
    func drainedBy(_ flow: Flow) -> Container? {
        let link = flowLinks.first {
            $0.target === flow && ($0.origin as? Container != nil)
        }
        return (link?.origin as? Container)
    }

    /// Returns a container that is filled by the flow – that is a container
    /// to which the flow is an inflow. Returns `nil` if
    /// no container is being drained by the given flow.
    ///
    func filledBy(_ flow: Flow) -> Container? {
        let link = flowLinks.first {
            $0.origin === flow && ($0.target as? Container != nil)
        }
        return (link?.target as? Container)
    }

    /// List of flows flowing into a container.
    ///
    func inflows(_ container: Container) -> [Flow] {
        let flowLinks = flowLinks.filter {
            ($0.origin as? Flow != nil) && $0.target === container
        }
        return flowLinks.compactMap { $0.origin as? Flow }
    }
    
    /// List of flows flowing out from a container.
    ///
    func outflows(_ container: Container) -> [Flow] {
        let flowLinks = flowLinks.filter {
            ($0.target as? Flow != nil) && $0.origin === container
        }
        return flowLinks.compactMap { $0.target as? Flow }
    }

    func parameters(for node: Node) -> [Transform] {
        let params = parameterLinks.filter {
            $0.target === node
        }.compactMap { $0.target as? Transform }
        return params
    }
    /// Return a node with given name. If no such node exists, then returns
    /// `nil`.
    ///
    /// - Note: Only expression nodes can have a name.
    ///
    func node(_ name: String) -> Node? {
        return expressionNodes.first { $0.name == name }
    }
    
    public subscript(_ name: String) -> Node? {
        get {
            return node(name)
        }
    }
    
    // MARK: - Mutation
    
    /// Adds a node to the model.
    ///
    /// The model will become the owner of the node and will assign it an ID.
    /// Node must not be part of another model.
    ///
    public func add(_ node: Node) {
        precondition(node.id == nil)
        node.id = idSequence.next()
        graph.add(node)
    }
    
    /// Remove node and all connections from/to the node from the model.
    ///
    /// The node is no longer owned by the model.
    ///
    public func remove(node: Node) {
        graph.remove(node)
    }

    /// Remove a link from the graph.
    ///
    public func remove(link: Link) {
        graph.disconnect(link: link)
    }
    
    // TODO: Fix the node names
    /// Validates potential connection originating in node `origin` and ending in node
    /// `target`.
    ///
    /// Valid connections:
    ///
    /// - From transform to any
    /// - From container to flow or transform
    /// - From flow to container or transform
    ///
    /// Invalid:
    ///
    /// - From flow to flow
    /// - From flow to multiple containers
    /// - From multiple containers to flow
    ///
    /// - Returns: `true` if nodes can be connected, `false` if the connection is
    /// invalid.
    ///
    public func canConnect(from origin: Node, to target: Node) -> Bool {
        if origin as? Transform != nil {
            return true
        }
        if let flow = origin as? Flow, let container = target as? Container {
            return filledBy(flow) == nil
        }
        if let flow = target as? Flow, let container = origin as? Container {
            return drainedBy(flow) == nil
        }
        
        // TODO: Write more rules.
        
        return true
    }
    
    /// Connects two nodes.
    ///
    /// - Note: This method is not validating whether the connection is valid or
    /// not. It might make the model inconsistent
    ///
    public func connect(from origin: Node, to target: Node, as type: LinkType = .parameter, labels: LabelSet = []) {
        // TODO: Rename this to "connectParameter"
        let id = idSequence.next()
        
        let finalLabels = Set([type.rawValue] + labels)
        
        graph.connect(from: origin, to: target, labels: finalLabels, id: id)
    }

    /// Connects two nodes as flows.
    ///
    public func connectFlow(from origin: Node, to target: Node) {
        if let flow = origin as? Flow, let container = target as? Container {
            guard filledBy(flow) == nil else {
                fatalError("Flow \(flow) is already filling a node \(filledBy(flow)!)")
            }
        }
        if let flow = target as? Flow, let container = origin as? Container {
            guard drainedBy(flow) == nil else {
                fatalError("Flow \(flow) is already draining a node \(drainedBy(flow)!)")
            }
        }
        
        connect(from: origin, to: target, as: .flow)
    }

    func __setupContstraints() {
        
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


//
//  Model.swift
//  
//
//  Created by Stefan Urbanek on 26/05/2022.
//

import Graph

public enum ModelError: Error, Equatable {
    /// Connected node is not used.
    case unusedInput(String, Node)
    
    /// Cycle in computation graph has been detected.
    case cycle(Node)
    
    /// Debug error (during development only)
    case unknown(String)
}

public enum LinkType: String {
    case flow
    case parameter
}

public class Model {
    // TODO: Split into Model (storage) and ModelManager (editing)
    
    static let FlowLabel = "flow"
    static let ParameterLabel = "parameter"
    static let ExpressionLabel = "expression"

    /// Structure that holds all model objects – nodes and links.
    ///
    let graph: Graph
//    let intent: Graph
    
    /// Sequence of IDs that are assigned to the model objects for user-facing
    /// identification.
    ///
    let idSequence: SequentialIDGenerator = SequentialIDGenerator()
    
    var expressionNodes: [ExpressionNode] { graph.nodes.compactMap { $0 as? ExpressionNode } }
    
    var stocks: [Stock] { graph.nodes.compactMap { $0 as? Stock } }
    var flows: [Flow] { graph.nodes.compactMap { $0 as? Flow } }
    var formulas: [Transform] { graph.nodes.compactMap { $0 as? Transform } }

    var flowLinks: [Link] {
        graph.links.filter { $0.contains(label: Model.FlowLabel) }
    }
    var parameterLinks: [Link] {
        graph.links.filter { $0.contains(label: Model.ParameterLabel) }
    }
    
    // MARK: - Initialisation
   
    /// Checker for constraints during editing - more permissive
    var constraintChecker: ConstraintChecker!
    // TODO: The above force unwrap is just to silence the compiler about `self` further down in initialization
    
    public init(graph: Graph? = nil) {
        self.graph = graph ?? Graph()
    
        constraintChecker = ConstraintChecker(
            constraints: [
                NodeConstraint(
                    name: "single_outflow_target",
                    match: LabelPredicate(all: "flow"),
                    requirement: UniqueNeighbourRequirement("flow", direction: .outgoing)
                ),
                NodeConstraint(
                    name: "single_inflow_origin",
                    match: LabelPredicate(all: "flow"),
                    requirement: UniqueNeighbourRequirement("flow", direction: .incoming)
                ),
                NodeConstraint(
                    // Inflow of a stock node must be different from the outflow
                    // TODO: Remove the model requirement
                    name: "different_drain_fill",
                    match: SameDrainFill(model: self),
                    requirement: RejectAll()
                ),
                NodeConstraint(
                    name: "unique_node_name",
                    match: LabelPredicate(any: "flow", "node", "stock"),
                    requirement: UniqueProperty<String> {
                        if let node = $0 as? ExpressionNode {
                            return node.name
                        }
                        else {
                            return nil
                        }
                    }
                ),
                LinkConstraint(
                    name: "forbidden_flow_to_flow",
                    match: LinkObjectPredicate(
                        origin: LabelPredicate(all: "flow"),
                        target: LabelPredicate(all: "flow"),
                        link: LabelPredicate(all: "flow")
                    ),
                    requirement: RejectAll()
                )
            ]
            
        )
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

    /// Returns a stock that is drained by the flow – that is a stock
    /// to which the flow is an outflow. Returns `nil` if
    /// no stock is being drained by the given flow.
    ///
    func drainedBy(_ flow: Flow) -> Stock? {
        let link = flowLinks.first {
            $0.target === flow && ($0.origin as? Stock != nil)
        }
        return (link?.origin as? Stock)
    }

    /// Returns a stock that is filled by the flow – that is a stock
    /// to which the flow is an inflow. Returns `nil` if
    /// no stock is being drained by the given flow.
    ///
    func filledBy(_ flow: Flow) -> Stock? {
        let link = flowLinks.first {
            $0.origin === flow && ($0.target as? Stock != nil)
        }
        return (link?.target as? Stock)
    }

    /// List of flows flowing into a stock.
    ///
    func inflows(_ stock: Stock) -> [Flow] {
        let flowLinks = flowLinks.filter {
            ($0.origin as? Flow != nil) && $0.target === stock
        }
        return flowLinks.compactMap { $0.origin as? Flow }
    }
    
    /// List of flows flowing out from a stock.
    ///
    func outflows(_ stock: Stock) -> [Flow] {
        let flowLinks = flowLinks.filter {
            ($0.target as? Flow != nil) && $0.origin === stock
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
    /// - From stock to flow or transform
    /// - From flow to stock or transform
    ///
    /// Invalid:
    ///
    /// - From flow to flow
    /// - From flow to multiple stocks
    /// - From multiple stocks to flow
    ///
    /// - Returns: `true` if nodes can be connected, `false` if the connection is
    /// invalid.
    ///
    public func canConnect(from origin: Node, to target: Node, as type: LinkType = .parameter) -> Bool {
        fatalError("Not implemented: \(#function)")
    }
    
    /// Connects two nodes.
    ///
    /// - Note: This method is not validating whether the connection is valid or
    /// not. It might make the model inconsistent
    ///
    @discardableResult
    public func connect(from origin: Node, to target: Node, as type: LinkType = .parameter, labels: LabelSet = []) -> Link {
        // TODO: Rename this to "connectParameter"
        // FIXME: Validate
        let id = idSequence.next()
        
        let finalLabels = Set([type.rawValue] + labels)
        
        return graph.connect(from: origin, to: target, labels: finalLabels, id: id)
    }

    /// Connects two nodes as flows.
    ///
    @discardableResult
    public func connectFlow(from origin: Node, to target: Node) -> Link {
        // FIXME: Validate
        return connect(from: origin, to: target, as: .flow)
    }


    // Add stock
    // Remove stock
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


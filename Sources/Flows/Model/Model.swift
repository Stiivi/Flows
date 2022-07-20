//
//  Model.swift
//  
//
//  Created by Stefan Urbanek on 26/05/2022.
//

import Graph


public enum __ModelError {
    case expressionError // Add expression compilation details
    case unusedInput(String)
    case unknownParameter(String)
    case constraintViolation(ConstraintViolation)
    case cycle
}

struct __NewModelError {
    let primaryNode: Node?
    let relatedNodes: [Node]
    
    let error: __ModelError
}


public enum LinkType: String {
    case flow
    case parameter
    
    public var rawValue: String {
        switch self {
        case .flow: return Model.FlowLinkLabel
        case .parameter: return Model.ParameterLinkLabel
        }
    }
}

/// Model of a dynamical system.
///
/// This is one of the core classes, it represents a model of a system that is
/// to be simulated.
///
/// The model is a graph of nodes.
///
public class Model {
    // TODO: Split into Model (storage) and ModelManager (editing)
    
    // MARK: - Graph Meta-Model
    
    /// Label used for links that connect flows with stocks
    static let FlowLinkLabel = "flow"

    /// Selector for links from flows that are directed towards a node,
    /// typically a stock.
    static let InflowSelector = LinkSelector(Model.FlowLinkLabel, direction: .incoming)

    /// Selector for links from nodes, typically a stock, that are directed to
    /// a flow.
    static let OutflowSelector = LinkSelector(Model.FlowLinkLabel, direction: .outgoing)

    /// Selector that defines links from/to parameter nodes
    static let ParameterSelector = LinkSelector(Model.ParameterLinkLabel, direction: .incoming)

    /// Label used for links that connect auxiliary nodes with other nodes
    static let ParameterLinkLabel = "parameter"

    // TODO: Move the following to respective classes
    /// Label of a node representing a stock.
    static let StockNodeLabel = "Stock"
    /// Label of a node representing an auxiliary node.
    static let TransformNodeLabel = "Transform"
    /// Label of a node representing a flow node.
    static let FlowNodeLabel = "Flow"

    // MARK: - Model Variables
    
    /// Structure that holds all model objects – nodes and links.
    ///
    public let graph: Graph
    
    /// Sequence of IDs that are assigned to the model objects for user-facing
    /// identification.
    ///
    let idSequence: SequentialIDGenerator = SequentialIDGenerator()
    
    /// List of all nodes that represent an expression, that is: stocks, flows
    /// and transformation.
    ///
    var expressionNodes: [ExpressionNode] { graph.nodes.compactMap { $0 as? ExpressionNode } }
    

    // MARK: - Derived Variables
    
    /// List of all stock nodes.
    ///
    public var stocks: [Stock] { graph.nodes.compactMap { $0 as? Stock } }

    /// List of all flow nodes.
    ///
    public var flows: [Flow] { graph.nodes.compactMap { $0 as? Flow } }

    /// List of all transformation nodes.
    ///
    public var transformations: [Transform] { graph.nodes.compactMap { $0 as? Transform } }

    /// List of links that connect flows with other nodes.
    ///
    var flowLinks: [Link] {
        graph.links.filter { $0.contains(label: Model.FlowLinkLabel) }
    }

    /// List of links that connect parameters with other nodes.
    ///
    var parameterLinks: [Link] {
        graph.links.filter { $0.contains(label: Model.ParameterLinkLabel) }
    }
    
    
    // MARK: - Initialisation
   
    /// Checker for constraints during editing - more permissive
    var constraintChecker: ConstraintChecker!
    // TODO: The above force unwrap is just to silence the compiler about `self` further down in initialization
    
    public init(graph: Graph? = nil) {
        self.graph = graph ?? Graph()
        
        constraintChecker = ConstraintChecker(constraints: ModelConstraints)
    }
       
    // MARK: - Query

    /// Return a first node with given name. If no such node exists, then returns
    /// `nil`. If there are multiple nodes with the same name, then one is
    /// returned arbitrarily.
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
    
    /// Adds a list of nodes to the model.
    ///
    /// The model will become the owner of the nodes and will assign them an ID.
    /// Nodes must not be part of another model.
    ///
    /// - Note: This is a convenience method for code readability purposes when
    ///         creating models programatically.
    ///
    public func add(_ nodes: [Node]) {
        for node in nodes {
            self.add(node)
        }
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
        
        var labels: Set<Label> = []
        if origin is Stock {
            labels.insert("drains")
        }
        if target is Stock {
            labels.insert("fills")
        }
        return connect(from: origin, to: target, as: .flow, labels: labels)
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
    
    /// Print the model
    public func debugPrint() {
        print("# NODES\n")
        for node in graph.nodes {
            print(node)
        }
        print("# LINKS\n")
        for link in graph.links {
            print(link)
        }
    }
}


//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 21/06/2022.
//

import Graph

/// An error thrown by the compiler when there are issues with the model.
public struct ModelCompilationError: Error {
    /// A dictionary of errors related to nodes.
    var nodeIssues: [ExpressionNode:[NodeError]] = [:]

    /// List of constraint violations within the model.
    var constraintViolations: [ConstraintViolation]
    
    /// List of loops detected in the model
    var cycleError: ModelCycleError?
    
    /// List of human-readable messages describing each of the issues within
    /// the compilation error
    public var messages: [String] {
        var messages: [String] = []
        
        for (node, errors) in nodeIssues {
            for error in errors {
                messages += error.messages.map {
                    "In node '\(node.name)': \($0)"
                }
            }
        }
        
        for violation in constraintViolations {
            messages.append("Constraint violation: \(violation.description)")
            let expressionNodes = violation.objects.compactMap { $0 as? ExpressionNode }
            for node in expressionNodes {
                messages.append("Node '\(node.name)' violates constraint '\(violation.name)'")
            }
            
            let links = violation.objects.compactMap { $0 as? Link }
            for link in links {
                let originTitle: String
                let targetTitle: String
                if let node = link.origin as? ExpressionNode {
                    originTitle = node.name
                }
                else {
                    originTitle = "(unknown node)"
                }

                if let node = link.target as? ExpressionNode {
                    targetTitle = node.name
                }
                else {
                    targetTitle = "(unknown node)"
                }
                messages.append("Link between '\(originTitle)' and '\(targetTitle)' violates constraint: \(violation.description)")
            }
        }
        
        for link in cycleError?.links ?? [] {
            guard let origin = link.origin as? ExpressionNode else {
                continue
            }
            guard let target = link.target as? ExpressionNode else {
                continue
            }
            messages.append("Node '\(target.name)' is part of a cycle through use of '\(origin.name)'")
        }
        return messages
    }
}

public struct ModelCycleError: Error {
    let links: [Link]
    var nodes: [Node] {
        let chain = [links.first!.origin] + links.map { $0.target }
        return chain
    }
    init(links: [Link]) {
        guard !links.isEmpty else {
            fatalError("Cycle error must contain at least one link")
        }
        self.links = links
    }
}

/// Detailed node error
///
public struct NodeError: Error, Equatable {
    /// Error parsing the expression.
    public let expressionSyntaxError: SyntaxError?
    
    /// List of names of parameter nodes that are not used
    public let unusedInputs: [String]
    
    /// List of parameters used in the expression that are not connected
    public let unknownParameters: [String]

    public init(expressionSyntaxError: SyntaxError? = nil,
                unusedInputs: [String] = [],
                unknownParameters: [String] = []) {
        self.expressionSyntaxError = expressionSyntaxError
        self.unusedInputs = unusedInputs
        self.unknownParameters = unknownParameters
    }
    
    /// List of human-readable messages describing the errors of this node
    public var messages: [String] {
        var messages: [String] = []
        if let error = expressionSyntaxError {
            messages.append("Syntax error: \(error)")
        }
        
        for name in unusedInputs {
            messages.append("Unused input '\(name)'")
        }

        for name in unknownParameters {
            messages.append("Unknown parameter '\(name)'")
        }
        
        return messages
    }
}

/// An object that compiles the model into a ``CompiledModel``.
///
/// The compiler makes sure that the model is valid, references
/// are resolved. It resolves the order in which the nodes are
/// to be evaluated.
///
public class Compiler {
    // NOTE: This class might have been a function, but I am keeping it here
    //       because it helps me with thinking - concern separation.
    //
    // TODO: Change init(model:) to init() and compile(model:)
    // TODO: Gather issues in the class
    
    /// Reference to the model to be compiled.
    let model: Model
    
    /// Creates a compiler that will compile within the context of the given
    /// model.
    ///
    public init(model: Model) {
        self.model = model
    }
    
    /// Compiles the model and returns the compiled version of the model.
    ///
    /// The compilation process is as follows:
    ///
    /// 1. Compile every expression node into a `CompiledExpressionNode`. See
    ///    ``Compiler/compile(node:)``
    /// 2. Check constraints using ``Compiler/checkConstraints()``
    /// 3. Topologically sort the expression nodes.
    ///
    /// - Throws: A ``ModelCompilationError`` when there are issues with the model.
    /// - Returns: A ``CompiledModel`` that can be used directly by the
    ///   simulator.
    ///
    public func compile() throws -> CompiledModel {
        var nodeIssues: [ExpressionNode:[NodeError]] = [:]
        var compiledNodes: [ExpressionNode:CompiledExpressionNode] = [:]
        var cycleError: ModelCycleError? = nil
        
        // 1. Compile expressions and expression dependencies
        // -----------------------------------------------------------------
        //
        for node in model.expressionNodes {
            do {
                let compiledNode = try compile(node: node)
                compiledNodes[node] = compiledNode
            }
            catch let error as NodeError {
                nodeIssues[node, default: []].append(error)
            }
        }
        
        // 2. Validate constraints
        // -----------------------------------------------------------------
        //
        let constraintViolations = checkConstraints()


        // 3. Sort nodes
        // -----------------------------------------------------------------
        //
        var sortedNodes: [ExpressionNode]?
        do {
            sortedNodes = try sortNodes(model.expressionNodes)
        }
        catch let error as ModelCycleError {
            cycleError = error
        }
        
        // Collect issues
        // -----------------------------------------------------------------
        //
        guard cycleError == nil && nodeIssues.isEmpty && constraintViolations.isEmpty else {
            // TODO: Relate constraint violations to nodes
            throw ModelCompilationError(nodeIssues: nodeIssues,
                                        constraintViolations: constraintViolations,
                                        cycleError: cycleError)
        }
        
        let sortedCompiledNodes = sortedNodes!.compactMap { compiledNodes[$0] }
        
        // This is a sanity check, this should never be violated, but we
        // are putting this safeguard here, just in case.
        // The sorted nodes have less count when there are issues with the nodes
        // and the issues were not handled above.
        guard sortedCompiledNodes.count == compiledNodes.count else {
            fatalError("Sorted compiled nodes count is not equal to the compiled nodes count.")
        }
        
        return CompiledModel(model: model, nodes: sortedCompiledNodes)
    }
    
    /// Topologically sort nodes by links from parameters.
    ///
    /// The nodes are sorted in the order by which they refer to the parameters.
    /// Nodes that do not use any parameters are considered to be "source" nodes
    /// for the purpose of this sorting. Nodes using parameters are dependent
    /// nodes - they depend on their respective parameter nodes.
    ///
    /// - Throws: ``ModelCycleError`` if a cycle is detected.
    ///
    func sortNodes(_ nodes: [ExpressionNode]) throws -> [ExpressionNode] {
        // TODO: Move this to Graph
        
        // L ← Empty list that will contain the sorted elements
        var sorted: [ExpressionNode] = []

        // S ← Set of all nodes with no incoming edge
        var sources: [ExpressionNode] = nodes.filter {
            $0.incomingParameterNodes.isEmpty
        }

        var links = model.parameterLinks
        
        //
        //while S is not empty do
        var node: ExpressionNode
        
        while !sources.isEmpty {
            //    remove a node n from S
            node = sources.removeFirst()
            //    add n to L
            sorted.append(node)
            
            let outgoing = links.filter { $0.origin === node }
            
            for link in outgoing {
                links.removeAll { $0 === link }
                let m = link.target as! ExpressionNode
                if links.allSatisfy({$0.target != m}) {
                    sources.append(m)
                }
            }

            //    for each node m with an edge e from n to m do
            //        remove edge e from the graph
            //        if m has no other incoming edges then
            //            insert m into S

        }
        if !links.isEmpty {
            throw ModelCycleError(links: links)
        }

        return sorted

    }
   
    /// Check the model constraints and return a list of errors that describe
    /// the constraint violations.
    ///
    /// The returned list is empty if no violations are found.
    ///
    public func checkConstraints() -> [ConstraintViolation] {
        // TODO: Make this accept a node and then check constraints related only to that node
        
        let checker = ConstraintChecker(constraints: ModelConstraints)

        let violations = checker.check(graph: model.graph)

        return violations
    }

    /// Compiles an expression node `node` and returns its compiled artefact.
    ///
    /// If the node has issues then a `CompilerError` exception is thrown with
    /// a list of all issues found in the node by this method.
    ///
    /// This method detects the following node issues:
    ///
    /// - Expression syntax errors
    /// - Unknown variables
    /// - Unused inputs
    ///
    /// - Note: Even-though that the returned compiled node is valid on its
    ///   own, it is not guaranteed that the node is not violating other
    ///   graph-related constraints.
    ///
    /// - Throws: ``NodeError`` when the node has issues.
    ///
    public func compile(node: ExpressionNode) throws -> CompiledExpressionNode {
        let parser = ExpressionParser(string: node.expressionString)

        let expression: Expression
        
        do {
            expression = try parser.parse()
        }
        catch let error as SyntaxError {
            throw NodeError(expressionSyntaxError: error)
        }

        // Check inputs and expression variable references
        //
        if let error = validateInputs(node: node, expression: expression) {
            throw error
        }
        
        return CompiledExpressionNode(node: node, expression: expression)
    }
    
    func validateInputs(node: ExpressionNode, expression: Expression) -> NodeError? {
        let vars = Set(expression.referencedVariables)
        let incomingNames = Set(node.incomingParameterNodes.map {$0.name} )
        
        let unknown = vars.subtracting(incomingNames)
        let unused = incomingNames.subtracting(vars)
    
        if unknown.isEmpty && unused.isEmpty {
            return nil
        }
        else {
            return NodeError(unusedInputs: Array(unused),
                             unknownParameters: Array(unknown))
        }
    }

//    public func validateCycles() -> [ModelError] {
//        var errors: [ModelError] = []
//        var seen: [Node] = []
//
//        for startNode in nodes {
//            guard !seen.contains(startNode) else {
//                continue
//            }
//            seen.append(startNode)
//
//            var follow: [Node] = outgoing(startNode).map { $0.target }
//            while !follow.isEmpty {
//                let node = follow.removeFirst()
//                if seen.contains(node) {
//                    errors.append(.cycle(node))
//                }
//                else {
//                    seen.append(node)
//                    follow += outgoing(node).map { $0.target }
//                }
//            }
//        }
//        return errors
//    }

}

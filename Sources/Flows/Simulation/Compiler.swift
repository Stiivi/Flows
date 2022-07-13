//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 21/06/2022.
//

import Graph

/// An error thrown by the compiler when there are issues with the model.
public enum CompilerError: Error {
    /// Issues with particular nodes
    case nodeIssues([ExpressionNodeIssue])
    /// Issues with the model
    case modelIssues([ExpressionNodeIssue], [ConstraintViolation])
}

/// Detailed node error
///
public enum NodeError: Error, Equatable {
    /// Connected node is not used.
    case unusedInput(String)
    /// Parameter used in the expression is unknown.
    case unknownParameter(String)
    /// Error parsing the expression.
    case expressionError(ParserError)
}

/// A structure representing an issue with an expression node.
///
public struct ExpressionNodeIssue {
    /// Node that has issues.
    let node: ExpressionNode
    
    /// Detailed information about the issue.
    let error: NodeError
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
    /// Reference to the model to be compiled.
    let model: Model
    
    /// Creates a compiler that will compile within the context of the given
    /// model.
    ///
    init(model: Model) {
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
    /// - Throws: A ``CompilerError`` when there are issues with the model.
    /// - Returns: A ``CompiledModel`` that can be used directly by the
    ///   simulator.
    ///
    public func compile() throws -> CompiledModel {
        var nodeIssues: [ExpressionNodeIssue] = []
        var compiledNodes: [ExpressionNode:CompiledExpressionNode] = [:]
        
        // Compile expressions and expression dependencies
        //
        for node in model.expressionNodes {
            do {
                let compiledNode = try compile(node: node)
                compiledNodes[node] = compiledNode
            }
            catch CompilerError.nodeIssues(let issues) {
                nodeIssues += issues
            }
        }
        
        let constraintViolations = checkConstraints()

        let sortedNodes = sortNodes(model.expressionNodes)
        
        let sortedCompiledNodes = sortedNodes.compactMap { compiledNodes[$0] }
        
        guard nodeIssues.isEmpty && constraintViolations.isEmpty else {
            // TODO: Relate constraint violations to nodes
            throw CompilerError.modelIssues(nodeIssues, constraintViolations)
        }
        
        // This is a sanity check, this should never be violated, but we
        // are putting this safeguard here, just in case.
        // The sorted nodes have less count when there are issues with the nodes
        // and the issues should be handled above.
        guard sortedCompiledNodes.count == compiledNodes.count else {
            fatalError("Sorted compiled nodes count is not equal to the compiled nodes count.")
        }
        
        return CompiledModel(nodes: sortedCompiledNodes)
    }
    
    /// Topologically sort nodes
    ///
    func sortNodes(_ nodes: [ExpressionNode]) -> [ExpressionNode] {
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
            print("Looking at \(node.name)")
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
            fatalError("Graph contains cycles. Links: \(links)")
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
    /// - Throws: ``CompilerError`` when the node has issues.
    ///
    public func compile(node: ExpressionNode) throws -> CompiledExpressionNode {
        let parser = ExpressionParser(string: node.expressionString)

        let expression: Expression
        
        do {
            expression = try parser.parse()
        }
        catch let error as ParserError {
            let issue = ExpressionNodeIssue(node: node, error: .expressionError(error))
            throw CompilerError.nodeIssues([issue])
        }

        // Check inputs and expression variable references
        //
        let inputIssues = validateInputs(node: node, expression: expression)
            .map { ExpressionNodeIssue(node: node, error: $0) }
        
        guard inputIssues.isEmpty else {
            throw CompilerError.nodeIssues(inputIssues)
        }

        return CompiledExpressionNode(node: node, expression: expression)
    }
    
    func validateInputs(node: ExpressionNode, expression: Expression) -> [NodeError] {
        var errors: [NodeError] = []

        let vars = Set(expression.referencedVariables)
        let incomingNames = Set(node.incomingParameterNodes.map {$0.name} )
        
        let notConnected = vars.subtracting(incomingNames)
        let unused = incomingNames.subtracting(vars)
    
        errors += notConnected.map { NodeError.unknownParameter($0) }
        errors += unused.map { NodeError.unusedInput($0) }
        
        return errors
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

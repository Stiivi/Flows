//
//  ASTExpression.swift
//  
//
//  Created by Stefan Urbanek on 12/07/2022.
//

/// Abstract syntax tree of an arithmetic expression.
///
indirect enum ExpressionAST {
    
    case number(Token)
    case variable(Token)
    case parenthesis(Token, ExpressionAST, Token)
    case unary(Token, ExpressionAST)
    case binary(Token, ExpressionAST, ExpressionAST)
    // FIXME: We are losing tokens here!
    case function(Token, [ExpressionAST])

    var text: String {
        switch self {
        case let .number(token):
            return token.text
        case let .function(token, args):
            let argsText = args.map { $0.text }.joined(separator: ", ")
            return "\(token.text)(\(argsText))"
        case let .variable(token):
            return token.text
        case let .parenthesis(_, node, _):
            return "(\(node.text))"
        case let .unary(token, operand):
            return "\(token.text)\(operand.text)"
        case let .binary(token, left, right):
            return "\(left.text)\(token.text)\(right.text)"
        }
    }
   
    /// List of tokens representing variables in the expressions
    var variables: [Token] {
        switch self {
        case     .number(_):
            return []
        case let .function(_, args):
            return args.flatMap { $0.variables }
        case let .variable(token):
            return [token]
        case let .parenthesis(_, node, _):
            return node.variables
        case let .unary(_, operand):
            return operand.variables
        case let .binary(_, left, right):
            return left.variables + right.variables
        }

    }
    
    /// Converts the AST to an actual expression object.
    func toExpression() -> Expression {
        switch self {
        case let .number(token):
            if let number = token.intValue(), token.type == .int{
                return .value(Value.int(number))
            }
            else if let number = token.doubleValue(), token.type == .float {
                return .value(Value.double(number))
            }
            else {
                fatalError("Invalid numeric token type '\(token.type)' in token \(token)")
            }
        case let .function(token, args):
            let argExpressions = args.map { $0.toExpression() }
            return .function(token.text, argExpressions)
        case let .variable(token):
            return .variable(token.text)
        case let .parenthesis(_, node, _):
            return node.toExpression()
        case let .unary(token, operand):
            return .unary(token.text, operand.toExpression())
        case let .binary(token, left, right):
            return .binary(token.text, left.toExpression(), right.toExpression())
        }
    }
    
    // TODO: Reconstruct source: func toSource() -> String
    // TODO: Reconstruct source: func toSource(renamingVariables: [String:String]) -> String
}

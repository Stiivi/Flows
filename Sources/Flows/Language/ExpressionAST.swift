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

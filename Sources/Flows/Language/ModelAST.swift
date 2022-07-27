//
//  ModelAST.swift
//  
//
//  Created by Stefan Urbanek on 13/07/2022.
//

//protocol _AST {
//    var tokens: [Token]
//}
//
struct ModelAST: AST {
    indirect enum Kind {
        case stock(String, [String], ExpressionAST)
        case flow(String, ExpressionAST, String?, String?)
        case variable(String, ExpressionAST)
        case output([String])
        case model([ModelAST])
        
        var statements: [ModelAST] {
            switch self {
            case .model(let items): return items
            default: return []
            }
        }
        

    }
    /// Specific kind of the model statement AST node
    public let kind: Kind
    
    /// List of tokens from which the AST node
    public let tokens: [Token]
    
    /// Create a model statement AST node
    public init(_ kind: Kind, tokens: [Token]) {
        self.kind = kind
        self.tokens = tokens
    }
    
    /// Returns reproduction of the original source from which this
    /// node was parsed.
    ///
    var fullText: String {
        tokens.map { $0.fullText }.joined()
    }

}

//
//  ModelAST.swift
//  
//
//  Created by Stefan Urbanek on 13/07/2022.
//

indirect enum ModelAST {
    case stock(Token, ExpressionAST)
    case flow(Token, ExpressionAST, Token?, Token?)
    case variable(Token, ExpressionAST)
    case output([Token])
    case model([ModelAST])
    
    var statements: [ModelAST] {
        switch self {
        case .model(let items): return items
        default: return []
        }
    }
}

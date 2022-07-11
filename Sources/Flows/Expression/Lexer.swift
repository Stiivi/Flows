//
//  File 2.swift
//  
//
//  Created by Stefan Urbanek on 30/06/2022.
//

import Foundation

enum TokenType: Equatable {
    case empty
    case int
    case float
    case `operator`
    case identifier
    case leftParen
    case rightParen
    case comma
    case error(ParserError)
}


/*
 
 Token anatomy:
 
 "    10"
 whitespace + "10"
 
 startIndex -> endIndex
 text: textStartIndex -> textEndIndex
 fullText: paddedStartIndex -> paddedEndIndex
 
 */

struct Token {
    let type: TokenType
    let location: Lexer.Location
    let startIndex: String.Index
    let endIndex: String.Index
    
    /// Flag whether the lexer has seen a whitespace before the token
    let seenWhitespace: Bool
    let text: String
}

// TODO: Use drop(while:)

class Lexer {
    /// String to be tokenised.
    var string: String
    
    /// Index of the current character
    var currentIndex: String.Index
    
    /// Current character
    var currentChar: Character?
    
    /// Human understandable location.
    var location: Location
    
    /// Token start index
    var startIndex: String.Index
    /// Token end index
    var endIndex: String.Index
    
    var text: Substring {
        string[startIndex..<currentIndex]
    }
    
    var seenWhitespace: Bool = false
    
    /// Location within a text.
    public struct Location: CustomStringConvertible {
        /// Line number in human representation, starting with 1.
        var line: Int = 1
        
        /// Column number in human representation, starting with 1 for the
        /// leftmost column.
        var column: Int = 1

        /// Advances the location by one character.
        ///
        /// - Parameters:
        ///     - newLine: if `true` then we are advancing to the new line and
        ///       resetting the column to 1.
        ///
        mutating func advance(_ character: Character) {
            if character.isNewline {
                column = 1
                line += 1
            }
            else {
                column += 1
            }
        }

        public var description: String {
            return "\(line):\(column)"
        }
    }
    
    
    init(string: String) {
        self.string = string
        currentIndex = string.startIndex
        startIndex = currentIndex
        endIndex = currentIndex
        
        if string.startIndex < string.endIndex {
            currentChar = string[currentIndex]
        }
        else {
            currentChar = nil
        }
        
        location = Location()
    }
    
    var atEnd: Bool {
        return currentIndex == string.endIndex
    }
    
    func advance() {
        guard !atEnd else {
            return
        }
        
        // Advance current index and current character
        //
        currentIndex = string.index(after: currentIndex)

        if currentIndex < string.endIndex {
            currentChar = string[currentIndex]
            location.advance(currentChar!)
        }
        else {
            currentChar = nil
        }
    }
    
    func makeToken(type: TokenType) -> Token {
        return Token(type: type,
                     location: location,
                     startIndex: startIndex,
                     endIndex: currentIndex,
                     seenWhitespace: seenWhitespace,
                     text: String(text))
    }
    
    func accept() {
        guard currentChar != nil else {
            fatalError("Accepting without current character")
        }
        endIndex = currentIndex
        advance()
    }
    
    @discardableResult
    func accept(_ char: Character) -> Bool {
        if currentChar == char {
            accept()
            return true
        }
        else {
            return false
        }
    }
    
    @discardableResult
    func accept(_ predicate: (Character) -> Bool) -> Bool {
        guard let char = currentChar else {
            return false
        }
        if predicate(char) {
            accept()
            return true
        }
        else {
            return false
        }
    }
    
    func acceptNumber() -> TokenType? {
        var type: TokenType = .int
        
        if !accept(\.isWholeNumber) {
            return nil
        }

        while accept(\.isWholeNumber) || accept("_") {
            // Just accept it
        }

        if accept(".") {
            // At least one number after the decimal point
            if !accept(\.isWholeNumber) {
                return .error(.invalidCharacterInNumber)
            }
            while accept(\.isWholeNumber) || accept("_") {
                // Just accept it
            }

            type = .float
        }
        
        if accept("e") || accept("E") {
            // Possible float
            // At least one number after the decimal point
            accept("-")
            if !accept(\.isWholeNumber) {
                return .error(.invalidCharacterInNumber)
            }
            while accept(\.isWholeNumber) || accept("_") {
                // Just accept it
            }
            type = .float
        }
        
        if accept(\.isLetter) {
            return .error(.invalidCharacterInNumber)
        }
        else {
            return type
        }
    }
    
    func acceptIdentifier() -> TokenType? {
        guard accept(\.isLetter) || accept("_") else {
            return nil
        }

        while accept(\.isLetter) || accept(\.isWholeNumber) || accept("_") {
            // Just accept it
        }
        
        return .identifier
    }

    func acceptOperator() -> TokenType? {
        if accept("-") || accept("+") || accept("*") || accept("/") || accept("%") {
            return .operator
        }
        else {
            return nil
        }
    }

    func acceptPunctuation() -> TokenType? {
        if accept("(") {
            return .leftParen
        }
        else if accept(")") {
            return .rightParen
        }
        else if accept(",") {
            return .comma
        }
        else {
            return nil
        }
    }
    
    func next() -> Token {
        // Skip whitespace
        seenWhitespace = false
        while(accept(\.isWhitespace)) {
            seenWhitespace = true
        }

        guard !atEnd else {
            return makeToken(type: .empty)
        }

        startIndex = currentIndex
                
        if let type = acceptNumber()
                        ?? acceptIdentifier()
                        ?? acceptOperator()
                        ?? acceptPunctuation() {
            return makeToken(type: type)
        }
        else {
            accept()
            return makeToken(type: .error(.unexpectedCharacter))
        }
    }
}

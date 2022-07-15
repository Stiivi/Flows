//
//  Lexer.swift
//  
//
//  Created by Stefan Urbanek on 30/06/2022.
//


/// An object for lexical analysis of an arithmetic expression.
///
/// Lexer takes a string containing an arithmetic expression and returns a list
/// of tokens.
///
/// - SeeAlso:
///     - ``ExpressionToken``
///
public class Lexer {
    static let Keywords: [String] = ["stock", "flow", "var", "output", "from", "to"]

    /// Mode of lexing.
    public enum Mode {
        /// Lex for arithmetic expression
        case expression
        
        /// Lex for full model source.
        ///
        /// Lexing for model includes statements that define the model.
        case model
    }
    
    public let scanner: Scanner
    public let mode: Mode
    
    public init(scanner: Scanner, mode: Mode) {
        self.scanner = scanner
        self.mode = mode
    }
    
    /// Creates a lexer that parses a source string ``string``.
    ///
    public convenience init(string: String, mode: Mode = .expression) {
        self.init(scanner: Scanner(string: string), mode: mode)
    }

    public func advance() {
        scanner.advance()
    }

    public func accept() {
        scanner.accept()
    }
    
    @discardableResult
    public func accept(_ character: Character) -> Bool {
        return scanner.accept(character)
    }
    
    @discardableResult
    public func accept(_ predicate: (Character) -> Bool) -> Bool {
        return scanner.accept(predicate)
    }
    public var atEnd: Bool {
        return scanner.atEnd
    }
    
    /// Accepts an integer or a floating point number.
    ///
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
    
    /// Accepts an identifier.
    ///
    /// Identifier is a sequence of characters that start with a letter or an
    /// underscore `_`.
    ///
    func acceptIdentifier() -> TokenType? {
        // TODO: Allow quoting of the identifier
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
    func acceptAssignment() -> TokenType? {
        if accept("=") {
            return .assignment
        }
        else {
            return nil
        }
    }
    public func acceptKeywordOrIdentifier() -> TokenType? {
        let startIndex = scanner.currentIndex

        guard acceptIdentifier() != nil else {
            return nil
        }
        
        // Keywords are case-insensitive
        // let lowercased = scanner.source[startIndex..<scanner.currentIndex].lowercased()
        let text = String(scanner.source[startIndex..<scanner.currentIndex])
                    .lowercased()

        if Lexer.Keywords.contains(text){
            return .keyword
        }
        else {
            return .identifier
        }
    }
    
    /// Accept a valid token.
    public func acceptToken() -> TokenType? {
        switch mode {
        case .model:
            return acceptNumber()
                    ?? acceptKeywordOrIdentifier()
                    ?? acceptAssignment()
                    ?? acceptOperator()
                    ?? acceptPunctuation()
        case .expression:
            return acceptNumber()
                    ?? acceptIdentifier()
                    ?? acceptOperator()
                    ?? acceptPunctuation()
        }
    }
    
    /// Accepts leading trivia.
    ///
    /// When parsing for an expression then the trivia contains only whitespace.
    /// When parsing for a model, then the trivia contains also comments.
    public func acceptLeadingTrivia() {
        switch mode {
        case .model:
            while true {
                if accept("#") {
                    while !(atEnd || accept(\.isNewline)) {
                        advance()
                    }
                }
                else if !accept(\.isWhitespace) {
                    break
                }
            }
        case .expression:
            while accept(\.isWhitespace) {
                // Just skip
            }
        }
    }
    
    public func acceptTrailingTrivia() {
        switch mode {
        case .model:
            while true {
                if accept("#") {
                    while !(atEnd || accept(\.isNewline)) {
                        advance()
                    }
                    break
                }
                if accept(\.isNewline) || !accept(\.isWhitespace) {
                    break
                }
            }
        case .expression:
            while(!accept(\.isNewline) && accept(\.isWhitespace)) {
                // Just skip
            }
        }
    }


    /// Parse and return next token.
    ///
    /// Returns a token of type ``TokenType.empty`` when the end of the
    /// string has been reached.
    ///
    public func next() -> Token {
        // Trivia:
        //
        // Inspiration from Swift: swift/include/swift/Syntax/Trivia.h.gyb
        // At this moment there is no reason for parsing the trivia one way
        // or the other.
        //
        // 1. A token owns all of its trailing trivia up to, but not including,
        //    the next newline character.
        //
        // 2. Looking backward in the text, a token owns all of the leading trivia
        //    up to and including the first contiguous sequence of newlines characters.

        // Leading trivia
        let leadingTriviaStartIndex = scanner.currentIndex
        acceptLeadingTrivia()
        let leadingTriviaRange = leadingTriviaStartIndex..<scanner.currentIndex
        
        // Token text start index
        let startIndex = scanner.currentIndex

        if atEnd {
            return Token(type: .empty,
                         source: scanner.source,
                         range: (startIndex..<scanner.currentIndex),
                         leadingTriviaRange: leadingTriviaRange,
                         textLocation: scanner.location)
        }
        else if let type = acceptToken() {

            // Parse trailing trivia
            //
            let endIndex = scanner.currentIndex
            let trailingTriviaStartIndex = scanner.currentIndex
            acceptTrailingTrivia()
            let trailingTriviaRange = trailingTriviaStartIndex..<scanner.currentIndex


            return Token(type: type,
                         source: scanner.source,
                         range: (startIndex..<endIndex),
                         leadingTriviaRange: leadingTriviaRange,
                         trailingTriviaRange: trailingTriviaRange,
                         textLocation: scanner.location)
        }
        else {
            accept()
            return Token(type: .error(.unexpectedCharacter),
                         source: scanner.source,
                         range: (startIndex..<scanner.currentIndex),
                         leadingTriviaRange: leadingTriviaRange,
                         textLocation: scanner.location)
        }
    }

}

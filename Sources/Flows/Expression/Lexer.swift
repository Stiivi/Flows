//
//  Lexer.swift
//  
//
//  Created by Stefan Urbanek on 30/06/2022.
//

public enum TokenType: Equatable {
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


/// Human-oriented location within a text.
///
/// `TextLocation` refers to a line number and a column within that line.
///
public struct TextLocation: CustomStringConvertible {
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


/// Token represents a lexical unit of the source.
///
/// The token includes trivia - leading and trailing whitespace. This
/// information is preserved for potential programmatic source code editing
/// while preserving the user formatting.
///
public struct Token {
    /// Type of the token as resolved by the lexer
    public let type: TokenType

    /// Range of the token within the source string
    public let range: Range<String.Index>
    
    // FIXME: Bind the token to the text.
    /// The token text.
    public let text: String

    /// Range of the trivia that precede the token.
    public let leadingTriviaRange: Range<String.Index>
    public let leadingTrivia: String
    
    /// Range of the trivia that follow the token.
    public let trailingTriviaRange: Range<String.Index>
    public let trailingTrivia: String

    /// Human-oriented location of the token within the source string.
    public let textLocation: TextLocation

    
    public init(type: TokenType, source: String, range: Range<String.Index>,
         leadingTriviaRange: Range<String.Index>? = nil,
         trailingTriviaRange: Range<String.Index>? = nil,
         textLocation: TextLocation) {
        // FIXME: Use Substrings
        self.type = type
        self.range = range
        self.text = String(source[range])

        self.leadingTriviaRange = leadingTriviaRange ?? (range.lowerBound..<range.lowerBound)
        self.leadingTrivia = String(source[self.leadingTriviaRange])
        self.trailingTriviaRange = trailingTriviaRange ?? (range.upperBound..<range.upperBound)
        self.trailingTrivia = String(source[self.trailingTriviaRange])

        self.textLocation = textLocation
    }
    
    /// Full text of the token - including leading and trailing trivia.
    ///
    /// If ``fullText`` from all tokens is joined it must provide the original
    /// source string.
    ///
    public var fullText: String {
        return leadingTrivia + text + trailingTrivia
    }
   
    /// Return integer value of the token if the token represents an integer.
    ///
    /// The numeric string might contain optional digit separator underscore
    /// `_`. For example: `'1_000'` for 1000 or `'1_00_00'` for 10000.
    ///
    /// - Returns: Integer value if the text is a valid number, otherwise ``nil``.
    ///
    func intValue() -> Int? {
        guard self.type == .int else {
            return nil
        }
        
        var sanitizedString = text
        sanitizedString.removeAll { $0 == "_" }
        
        return Int(sanitizedString)

    }

    /// Return double floating point value of the token if the token
    /// represents a floating point number.
    ///
    /// The numberic string might contain optional digit separator underscore
    /// `_`. For example: `'1_000.0'` for 1000 or `'1_00_00.1'` for 10000.1
    ///
    /// - Returns: Double value if the text is a valid number, otherwise ``nil``.
    ///
    func doubleValue() -> Double? {
        guard self.type == .float else {
            return nil
        }
        
        var sanitizedString = text
        sanitizedString.removeAll { $0 == "_" }
        
        return Double(sanitizedString)
    }

}


/// An object for lexical analysis of an arithmetic expression.
///
/// Lexer takes a string containing an arithmetic expression and returns a list
/// of tokens.
///
/// - SeeAlso:
///     - ``Token``
///
public class Lexer {
    /// String to be tokenised.
    var source: String
    
    /// Index of the current character
    var currentIndex: String.Index
    
    /// Current character
    var currentChar: Character?
    
    /// Human understandable location.
    var location: TextLocation
    
    /// Creates a lexer that parses a source string ``string``.
    ///
    public init(string: String) {
        self.source = string
        currentIndex = string.startIndex
        
        if string.startIndex < string.endIndex {
            currentChar = string[currentIndex]
        }
        else {
            currentChar = nil
        }
        
        location = TextLocation()
    }
    
    /// Flag indicating whether the lexer reached the end of the source string.
    ///
    var atEnd: Bool {
        return currentIndex == source.endIndex
    }
    
    
    // MARK: Acceptance and advancement
    /// Advances the lexer by one character.
    ///
    /// This method is called when a character is accepted. It advances
    /// the reading position of the source and updates the text location.
    ///
    func advance() {
        guard !atEnd else {
            return
        }
        
        // Advance current index and current character
        //
        currentIndex = source.index(after: currentIndex)
        
        if currentIndex < source.endIndex {
            currentChar = source[currentIndex]
            location.advance(currentChar!)
        }
        else {
            currentChar = nil
        }
    }

    /// Accept a character at current position.
    ///
    /// - Precondition: The lexer must not be at the end.
    ///
    func accept() {
        guard currentChar != nil else {
            fatalError("Accepting without current character")
        }
        advance()
    }
    
    /// Accept a concrete character. Returns ``true`` if the current character
    /// is equal to the requested character.
    ///
    @discardableResult
    func accept(_ character: Character) -> Bool {
        if currentChar == character {
            accept()
            return true
        }
        else {
            return false
        }
    }
    
    /// Accept a character that matches given predicate. Returns ``true`` if
    /// the predicate function returns ``true`` for the current character.
    ///
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
    
    // MARK: Tokens
    
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
        let leadingTriviaStartIndex = currentIndex
        while(accept(\.isWhitespace)) {
        }
        let leadingTriviaRange = leadingTriviaStartIndex..<currentIndex
        
        // Token text start index
        let startIndex = currentIndex

        if atEnd {
            return Token(type: .empty,
                         source: source,
                         range: (startIndex..<currentIndex),
                         leadingTriviaRange: leadingTriviaRange,
                         textLocation: location)
        }
        else if let type = acceptNumber()
                        ?? acceptIdentifier()
                        ?? acceptOperator()
                        ?? acceptPunctuation() {

            // Parse trailing trivia
            //
            let endIndex = currentIndex
            let trailingTriviaStartIndex = currentIndex
            while(!accept(\.isNewline) && accept(\.isWhitespace)) {
            }
            let trailingTriviaRange = trailingTriviaStartIndex..<currentIndex


            return Token(type: type,
                         source: source,
                         range: (startIndex..<endIndex),
                         leadingTriviaRange: leadingTriviaRange,
                         trailingTriviaRange: trailingTriviaRange,
                         textLocation: location)
        }
        else {
            accept()
            return Token(type: .error(.unexpectedCharacter),
                         source: source,
                         range: (startIndex..<currentIndex),
                         leadingTriviaRange: leadingTriviaRange,
                         textLocation: location)
        }
    }
}

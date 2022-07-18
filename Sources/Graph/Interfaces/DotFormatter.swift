//
//  DotFormatter.swift
//
//
//  Created by Stefan Urbanek on 2/05/2018.
//
// 2022-01-27 - Changed from DotWriter to DotFormatter


import Foundation

/// Type of the graph – directed or undirected.
///
public enum DotGraphType {
    case undirected
    case directed

    var dotKeyword: String {
        switch self {
        case .undirected: return "graph"
        case .directed: return "digraph"
        }
    }
    var edgeOperator: String {
        switch self {
        case .undirected: return "--"
        case .directed: return "->"
        }
    }
}

/// Formatter for GraphViz DOT file format statements. Use to produce strings
/// representing various DOT file parts such as nodes, links and graph headers.
///
public class DotFormatter {
    let name: String
    let type: DotGraphType
    
    /// Character set of characters that are valid for an ID (identifier), for
    /// example a node ID or an attribute name.
    ///
    public static let identifierCharacters: CharacterSet = DotFormatter._makeIdentifierCharacterSet()

    static func _makeIdentifierCharacterSet() -> CharacterSet {
        var charset = CharacterSet.alphanumerics
        charset.insert(charactersIn:UnicodeScalar(128)...UnicodeScalar(255))
        charset.insert(UnicodeScalar("_"))
        return charset
    }

    /// Quote an identifier, if needed.
    /// According to the Dot documentation an ID is:
    ///
    /// - Any string of alphabetic ([a-zA-Z\200-\377]) characters, underscores
    ///   ('_') or digits ([0-9]), not beginning with a digit;
    /// - a numeral [-]?(.[0-9]+ | [0-9]+(.[0-9]*)? );
    /// - any double-quoted string ("...") possibly containing escaped quotes
    ///   (\")1;
    /// - an HTML string (<...>).
    ///
    static func quote(_ string: String) -> String {
        // TODO: Do not fake the numerals
        /*
        ID is:

            - Any string of alphabetic ([a-zA-Z\200-\377]) characters, underscores
              ('_') or digits ([0-9]), not beginning with a digit;
            - a numeral [-]?(.[0-9]+ | [0-9]+(.[0-9]*)? );
            - any double-quoted string ("...") possibly containing escaped quotes
              (\")1;
            - an HTML string (<...>).
        */
        // TODO: We are not doing the HTML string
        
        guard !string.isEmpty else {
            // TODO: Should we raise an error here?
            return "\"\""
        }

        // Need to quote?

        let hasInvalidCharacter = string.unicodeScalars.contains {
            !DotFormatter.identifierCharacters.contains($0)
        }
        
        if !hasInvalidCharacter {
            return string
        }
        
        var quoted: String = ""
        
        for char in string {
            if char == "\"" {
                quoted.append("\\\"")
            }
            else {
                quoted.append(char)
            }
        }
        
        return "\"\(quoted)\""
    }

    /// Formats attributes into an attribute list. Quote identifiers if
    /// necessary.
    ///
    static func formatAttributes(_ dict: [String:String]) -> String {
        var result: [String] = []
        
        for (key, value) in dict {
            let quotedKey = DotFormatter.quote(key)
            let quotedValue = DotFormatter.quote(value)

            result.append("\(quotedKey)=\(quotedValue)")
        }

        return result.joined(separator:", ")
    }

    /// Creates a DOT file writer that writes the output into the stream
    /// `output`.
    ///
    public init(name: String="output", type: DotGraphType = .directed) {
        self.name = name
        self.type = type
    }

    /// Returns and optionally indented line of text into the text output stream.
    ///
    func line(_ line: String, indent: Int = 0) -> String {
        var text: String = ""
        let indentString: String
        if indent > 0 {
            indentString = String(repeating: "    ", count: indent)
        }
        else {
            indentString = ""
        }

        text = indentString + line + "\n"

        return text
    }

    /// Produces a sequence of opening statements for a graph file.
    ///
    public func header() -> String {
        let quotedName = DotFormatter.quote(name)
        return line("\(type.dotKeyword) \(quotedName) {")
    }


    /// Returns closing statements for a graph file.
    ///
    public func footer() -> String {
        return line("}")
    }


    /// Produce a node statement string.
    ///
    /// - Parameters:
    ///   - id: Node identifier.
    ///   - attributes: Optional dictionary of attributes for a node.
    ///
    public func node(_ id: String, attributes: [String:String]?=nil) -> String {
        let attributeString: String
        if let attributes = attributes {
            attributeString = "[" + DotFormatter.formatAttributes(attributes) + "]"
        }
        else {
            attributeString = ""
        }
       
        let quotedID = DotFormatter.quote(id)
        return line("\(quotedID)\(attributeString);", indent: 1)
    }

    /// Returns a string representing an edge statement.
    ///
    /// - Parameters:
    ///   - from: Originating node identifier.
    ///   - to: Target node identifier.
    ///   - attributes: Optional dictionary of attributes for a node.
    ///
    public func edge(from origin:String, to target:String, attributes:
                          [String:String]?=nil) -> String {
        let quotedOrigin = DotFormatter.quote(origin)
        let quotedTarget = DotFormatter.quote(target)
        let attributeString: String
        if let attributes = attributes {
            attributeString = "[" + DotFormatter.formatAttributes(attributes) + "]"
        }
        else {
            attributeString = ""
        }

        return line("\(quotedOrigin) \(type.edgeOperator) \(quotedTarget)\(attributeString);", indent: 1)
    }
}

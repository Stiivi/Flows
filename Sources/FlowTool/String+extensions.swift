//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 21/07/2022.
//

import SystemPackage


extension String {
    /// Creates a string from a content of a file at path `path`.
    ///
    public init(contentsOf path: FilePath) throws {
        // Arbitrarily picked buffer size
        let bufferSize = 1000
        
        let buffer = ManagedBuffer<Int, UTF8>.create(minimumCapacity: bufferSize) { _ in 0 }
        let file = try FileDescriptor.open(path, .readOnly)
        
        // Aggregated content
        var result = String()
        
        var count = 0
        repeat {
            try buffer.withUnsafeMutablePointerToElements { pointer in
                let umbp = UnsafeMutableRawBufferPointer(start: pointer, count: bufferSize)
                count = try file.read(into: umbp)
                
                let string = String(bytesNoCopy: pointer,
                                    length: count,
                                    encoding: .utf8,
                                    freeWhenDone: false)
                
                if let string = string {
                    result += string
                }
            }
        } while count > 0
        
        try file.close()
        
        self.init(result)
    }
}

//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 21/07/2022.
//

#if os(OSX)
import Foundation
#endif

import SystemPackage
import XCTest
@testable import Flows

final class StringExtensionTests: XCTestCase {

#if os(OSX)
    
    // TODO: This is tested on OSX only, since I do not know how to create a random temporary file from top of my head without adding dependencies
    
    /**
    Creates a URL for a temporary file on disk. Registers a teardown block to
    delete a file at that URL (if one exists) during test teardown.
    */
    func temporaryFileURL() -> URL {
        
        // Create a URL for an unique file in the system's temporary directory.
        let directory = NSTemporaryDirectory()
        let filename = UUID().uuidString
        let fileURL = URL(fileURLWithPath: directory).appendingPathComponent(filename)
        
        // Add a teardown block to delete any file at `fileURL`.
        addTeardownBlock {
            do {
                let fileManager = FileManager.default
                // Check that the file exists before trying to delete it.
                if fileManager.fileExists(atPath: fileURL.path) {
                    // Perform the deletion.
                    try fileManager.removeItem(at: fileURL)
                    // Verify that the file no longer exists after the deletion.
                    XCTAssertFalse(fileManager.fileExists(atPath: fileURL.path))
                }
            } catch {
                // Treat any errors during file deletion as a test failure.
                XCTFail("Error while deleting temporary file: \(error)")
            }
        }
        
        // Return the temporary file URL for use in a test method.
        return fileURL
        
    }
    
    func testStringFromFile() throws {
        let path = FilePath(temporaryFileURL().path)
        let value = "test"
        let file = try FileDescriptor.open(path, .writeOnly,
                                           options: [.truncate, .create],
                                           permissions: .ownerReadWrite)
        try file.closeAfter {
          _ = try file.writeAll(value.utf8)
        }

        let string = try String(contentsOf: path)
        
        XCTAssertEqual(string, value)
    }
    func testLargerStringFromFile() throws {
        let path = FilePath(temporaryFileURL().path)
        let value = String(repeating: "test", count: 1000)
        let file = try FileDescriptor.open(path, .writeOnly,
                                           options: [.truncate, .create],
                                           permissions: .ownerReadWrite)
        try file.closeAfter {
          _ = try file.writeAll(value.utf8)
        }

        let string = try String(contentsOf: path)
        
        XCTAssertEqual(string, value)
    }

#endif
    
}

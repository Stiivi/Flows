//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 21/06/2022.
//


import XCTest
@testable import Flows

final class CompilerTests: XCTestCase {
    func testCompileEmpty() throws {
        let model = Model()
        let compiler = Compiler(model: model)
        // a -> b -> c
        
        let c = Transform(name: "c", expression: "b")
        model.add(c)

        let b = Transform(name: "b", expression: "a")
        model.add(b)

        let a = Transform(name: "a", expression: "0")
        model.add(a)

        model.connect(from: a, to: b)
        model.connect(from: b, to: c)

        let cmodel = try compiler.compile()
        XCTAssertIdentical(cmodel.sortedNodes[0].node, a)
        XCTAssertIdentical(cmodel.sortedNodes[1].node, b)
        XCTAssertIdentical(cmodel.sortedNodes[2].node, c)
    }
    
    func testCompileOne() throws {
        let model = Model()
        let compiler = Compiler(model: model)
        let cmodel = try compiler.compile()
        
        XCTAssertTrue(cmodel.sortedNodes.isEmpty)
    }

    func testValidateDuplicateName() throws {
        let model = Model()

        let c1 = Stock(name: "things", float: 0)
        let c2 = Stock(name: "things", float: 0)
        model.add(c1)
        model.add(c2)
        model.add(Stock(name: "a", float: 0))
        model.add(Stock(name: "b", float: 0))

        let violations = model.constraintChecker.check(graph: model.graph)
        XCTAssertEqual(violations.count, 1)
        let violation = violations.first!
        
        XCTAssertEqual(violation.name, "unique_node_name")
        XCTAssertTrue(violation.objects.contains(c1))
        XCTAssertTrue(violation.objects.contains(c2))
    }
    
}

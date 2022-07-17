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

        guard let violation = violations.first else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(violation.name, "unique_node_name")
        XCTAssertTrue(violation.objects.contains(c1))
        XCTAssertTrue(violation.objects.contains(c2))
    }
    
    func testUnusedInputs() throws {
        let model = Model()
        let used = Transform(name: "used", expression: "1")
        let unused = Transform(name: "unused", expression: "1")
        let thing = Transform(name: "thing", expression: "used")
        
        model.add(used)
        model.add(unused)
        model.add(thing)
        model.connect(from: used, to: thing)
        model.connect(from: unused, to: thing)

        let compiler = Compiler(model: model)

        XCTAssertThrowsError(try compiler.compile(node: thing)) { error in
            if let nodeError = error as? NodeError {
                XCTAssertTrue(nodeError.unknownParameters.isEmpty)
                XCTAssertEqual(nodeError.unusedInputs, ["unused"])
            }
            else {
                XCTFail()
            }
        }
        
    }
    
    func testUnknownParameters() throws {
        let model = Model()
        let known = Transform(name: "known", expression: "1")
        let thing = Transform(name: "thing", expression: "known + unknown")
        
        model.add(known)
        model.add(thing)
        model.connect(from: known, to: thing)

        let compiler = Compiler(model: model)

        XCTAssertThrowsError(try compiler.compile(node: thing)) { error in
            if let nodeError = error as? NodeError {
                XCTAssertTrue(nodeError.unusedInputs.isEmpty)
                XCTAssertEqual(nodeError.unknownParameters, ["unknown"])
            }
            else {
                XCTFail("Expected exception NodeError, got: \(error)")
            }
        }
        
    }

    func testNodeExpressionSyntaxError() throws {
        let model = Model()
        let thing = Transform(name: "thing", expression: "1 *")
        
        model.add(thing)

        let compiler = Compiler(model: model)

        XCTAssertThrowsError(try compiler.compile(node: thing)) { error in
            if let nodeError = error as? NodeError {
                XCTAssertTrue(nodeError.unusedInputs.isEmpty)
                XCTAssertTrue(nodeError.unknownParameters.isEmpty)
                XCTAssertNotNil(nodeError.expressionSyntaxError)
            }
            else {
                XCTFail("Expected exception NodeError, got: \(error)")
            }
        }
        
    }

    func testSortSelfCycle() throws {
        let model = Model()
        let a = Transform(name:"a", expression: "a")
        model.add(a)
        let link = model.connect(from: a, to: a)
        let compiler = Compiler(model: model)
        
        XCTAssertThrowsError(try compiler.compile()) { error in
            if let error = error as? ModelCompilationError {
                if let cycleError = error.cycleError {
                    XCTAssertEqual(cycleError.links.count, 1)
                    XCTAssertIdentical(cycleError.links.first!, link)
                }
                else {
                    XCTFail("Expected cycleError not to be nil")
                }
            }
            else {
                XCTFail("Expected exception NodeCompileationError, got: \(error)")
            }
        }

        
    }
    
    func testSortCycle() throws {
        let model = Model()
        let a = Transform(name:"a", expression: "c")
        let b = Transform(name:"b", expression: "a")
        let c = Transform(name:"c", expression: "b")
        model.add(a)
        model.add(b)
        model.add(c)
        let link1 = model.connect(from: a, to: b)
        let link2 = model.connect(from: b, to: c)
        let link3 = model.connect(from: c, to: a)

        let compiler = Compiler(model: model)
        
        XCTAssertThrowsError(try compiler.compile()) { error in
            if let error = error as? ModelCompilationError {
                if let cycleError = error.cycleError {
                    XCTAssertEqual(cycleError.links.count, 3)
                    XCTAssertIdentical(cycleError.links[0], link1)
                    XCTAssertIdentical(cycleError.links[1], link2)
                    XCTAssertIdentical(cycleError.links[2], link3)
                }
                else {
                    XCTFail("Expected cycleError not to be nil")
                }
            }
            else {
                XCTFail("Expected exception NodeCompileationError, got: \(error)")
            }
        }

        
    }
}

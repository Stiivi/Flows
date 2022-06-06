//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 26/05/2022.
//

import XCTest
@testable import Flows

final class ModelTests: XCTestCase {
    func testValidateEmpty() throws {
        let model = Model()
        XCTAssertTrue(model.validate().isEmpty)
    }

    func testAddContainer() throws {
        let model = Model()
        let node = Container(name: "c", float: 0)
        model.add(node)
        
        XCTAssertIdentical(model.containers.first, node)
    }

    func testAddFormula() throws {
        let model = Model()
        let node = Transform(name: "f", expression: "0")
        model.add(node)
        
        XCTAssertIdentical(model.formulas.first, node)
    }

    func testAddFlow() throws {
        let model = Model()
        let flow = Flow(name: "f", expression: "0")
        model.add(flow)
        
        XCTAssertIdentical(model.flows.first, flow)
        XCTAssertNil(model.drainedBy(flow))
        XCTAssertNil(model.filledBy(flow))
    }

    func testConnectFlow() throws {
        let model = Model()
        let flow = Flow(name: "flow", expression: "0")
        let input = Container(name: "in", float: 100)
        let output = Container(name: "out", float: 0)

        model.add(input)
        model.add(output)
        model.add(flow)

        model.connect(from: input, to: flow, as: .flow)
        model.connect(from: flow, to: output, as: .flow)
        
        XCTAssertEqual(model.inflows(input), [])
        XCTAssertEqual(model.outflows(input), [flow])
        XCTAssertEqual(model.inflows(output), [flow])
        XCTAssertEqual(model.outflows(output), [])
        
        XCTAssertIdentical(model.drainedBy(flow), input)
        XCTAssertIdentical(model.filledBy(flow), output)
    }
    

    func testConnectFlowSameContainer() throws {
        let model = Model()
        let flow = Flow(name: "flow", expression: "0")
        let input = Container(name: "in", float: 100)

        model.add(input)
        model.add(flow)

        model.connect(from: input, to: flow, as: .flow)
        model.connect(from: flow, to: input, as: .flow)
        
        let errors = model.validate()

        XCTAssertEqual(errors, [ModelError.sameFlowInputOutput(flow)])
    }

    func testCompileEmpty() throws {
        let model = Model()
        // a -> b -> c
        
        let c = Transform(name: "c", expression: "b")
        model.add(c)

        let b = Transform(name: "b", expression: "a")
        model.add(b)

        let a = Transform(name: "a", expression: "0")
        model.add(a)

        model.connect(from: a, to: b)
        model.connect(from: b, to: c)

        let cmodel = try model.compile()
        XCTAssertIdentical(cmodel.nodes[0], a)
        XCTAssertIdentical(cmodel.nodes[1], b)
        XCTAssertIdentical(cmodel.nodes[2], c)
    }
    
    func testCompileOne() throws {
        let model = Model()
        let cmodel = try model.compile()
        
        XCTAssertTrue(cmodel.nodes.isEmpty)
    }

    func testValidateDuplicateName() throws {
        let model = Model()

        let c1 = Container(name: "things", float: 0)
        let c2 = Container(name: "things", float: 0)
        model.add(c1)
        model.add(c2)
        model.add(Container(name: "a", float: 0))
        model.add(Container(name: "b", float: 0))

        let errors = model.validate()
        XCTAssertEqual(errors.count, 1)
        
        let error = errors.first
        
        switch error {
        case let .duplicateName(name, nodes):
            XCTAssertEqual(name, "things")
            XCTAssertEqual(Set(nodes), Set([c1, c2]))
        default:
            XCTFail("Unexpected error: \(String(describing: error))")
        }
    }
    
//    func testValidateCycle() throws {
//        let model = Model()
//
//        let a = Transform(name: "a", expression: "0")
//        model.add(a)
//
//        let b = Transform(name: "b", expression: "0")
//        model.add(b)
//
//        model.connect(from: a, to: b)
//
//        XCTAssertEqual(model.validate().count, 0)
//
//        model.connect(from: b, to: a)
//
//        let errors = model.validate()
//        XCTAssertEqual(errors.count, 1)
//        let error = errors.first
//
//        switch error {
//        case let .cycle(node):
//            XCTAssertIdentical(node, a)
//        default:
//            XCTFail("Unexpected error: \(String(describing: error))")
//        }
//
//        let c = Transform(name: "c", expression: "0")
//        model.add(c)
//
//        let d = Transform(name: "d", expression: "0")
//        model.add(d)
//        model.connect(from: c, to: d)
//        model.connect(from: d, to: c)
//
//        XCTAssertEqual(model.validate().count, 2)
//
//    }
}

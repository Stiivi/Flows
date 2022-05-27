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
        let node = Container(name: "c", value: 0)
        model.add(node)
        
        XCTAssertIdentical(model.containers.first, node)
    }

    func testAddFormula() throws {
        let model = Model()
        let node = Formula(name: "f") { _ in 0 }
        model.add(node)
        
        XCTAssertIdentical(model.formulas.first, node)
    }

    func testAddFlow() throws {
        let model = Model()
        let node = Flow(name: "f") { _ in 0 }
        model.add(node)
        
        XCTAssertIdentical(model.flows.first, node)
    }

    func testConnectFlow() throws {
        let model = Model()
        let flow = Flow(name: "flow") { _ in 0 }
        let input = Container(name: "in", value: 100)
        let output = Container(name: "out", value: 0)

        model.add(input)
        model.add(output)
        model.add(flow)

        model.connect(flow, from: input)
        model.connect(flow, to: output)
        
        XCTAssertEqual(model.inflows(input), [])
        XCTAssertEqual(model.outflows(input), [flow])
        XCTAssertEqual(model.inflows(output), [flow])
        XCTAssertEqual(model.outflows(output), [])
    }

    func testConnectFlowSameContainer() throws {
        let model = Model()
        let flow = Flow(name: "flow") { _ in 0 }
        let input = Container(name: "in", value: 100)

        model.add(input)
        model.add(flow)

        model.connect(flow, from: input)
        model.connect(flow, to: input)
        
        let errors = model.validate()

        XCTAssertEqual(errors, [ModelError.sameFlowInputOutput(flow)])
    }

    func testValidateDuplicateName() throws {
        let model = Model()

        let c1 = Container(name: "things", value: 0)
        let c2 = Container(name: "things", value: 0)
        model.add(c1)
        model.add(c2)
        model.add(Container(name: "a", value: 0))
        model.add(Container(name: "b", value: 0))

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
    
    func testValidateCycle() throws {
        let model = Model()
        
        let a = Formula(name: "a") { _ in 0 }
        model.add(a)

        let b = Formula(name: "b") { _ in 0 }
        model.add(b)
        
        model.connect(from: a, to: b)
        
        XCTAssertEqual(model.validate().count, 0)

        model.connect(from: b, to: a)

        let errors = model.validate()
        XCTAssertEqual(errors.count, 1)
        let error = errors.first

        switch error {
        case let .cycle(node):
            XCTAssertIdentical(node, a)
        default:
            XCTFail("Unexpected error: \(String(describing: error))")
        }
        
        let c = Formula(name: "c") { _ in 0 }
        model.add(c)

        let d = Formula(name: "d") { _ in 0 }
        model.add(d)
        model.connect(from: c, to: d)
        model.connect(from: d, to: c)

        XCTAssertEqual(model.validate().count, 2)

    }
}

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
        XCTAssertTrue(node.contains(label: "stock"))
    }

    func testAddFormula() throws {
        let model = Model()
        let node = Transform(name: "f", expression: "0")
        model.add(node)
        
        XCTAssertIdentical(model.formulas.first, node)
        XCTAssertTrue(node.contains(label: "converter"))
    }

    func testAddFlow() throws {
        let model = Model()
        let flow = Flow(name: "f", expression: "0")
        model.add(flow)
        
        XCTAssertIdentical(model.flows.first, flow)
        XCTAssertNil(model.drainedBy(flow))
        XCTAssertNil(model.filledBy(flow))
        XCTAssertTrue(flow.contains(label: "flow"))
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
    
    func testSingleInflow() {
        // NOTE: Sync with testSingleOutflow()
        let model = Model()
        let flow = Flow(name: "flow", expression: "0")
        let stock1 = Container(name: "one", float: 0)
        let stock2 = Container(name: "two", float: 0)
        model.add(flow)
        model.add(stock1)
        model.add(stock2)
        
        let violations1 = model.constraintChecker.check()
        XCTAssertTrue(violations1.isEmpty)
        
        // We connect the first flow
        model.connectFlow(from: stock1, to: flow)
        let violations2 = model.constraintChecker.check()
        XCTAssertTrue(violations2.isEmpty)

        // We connect it as a parameter, not as a flow - should be OK
        model.connect(from: stock1, to: flow, as: .parameter)
        let violations3 = model.constraintChecker.check()
        XCTAssertTrue(violations3.isEmpty)
        
        model.connectFlow(from: stock2, to: flow)
        let violations4 = model.constraintChecker.check()
        XCTAssertFalse(violations4.isEmpty)
        XCTAssertEqual(violations4.first!.name, "single_inflow_origin")
    }

    func testSingleOutflow() {
        // NOTE: Sync with testSingleInflow()
        let model = Model()
        let flow = Flow(name: "flow", expression: "0")
        let stock1 = Container(name: "one", float: 0)
        let stock2 = Container(name: "two", float: 0)
        model.add(flow)
        model.add(stock1)
        model.add(stock2)
        
        let violations1 = model.constraintChecker.check()
        XCTAssertTrue(violations1.isEmpty)
        
        model.connectFlow(from: flow, to: stock1)
        let violations2 = model.constraintChecker.check()
        XCTAssertTrue(violations2.isEmpty)

        model.connect(from: flow, to: stock1, as: .parameter)
        let violations3 = model.constraintChecker.check()
        XCTAssertTrue(violations3.isEmpty)

        model.connectFlow(from: flow, to: stock2)
        let violations4 = model.constraintChecker.check()
        XCTAssertFalse(violations4.isEmpty)
        XCTAssertEqual(violations4.first!.name, "single_outflow_target")
    }

    
    func testConnectFlowToFlow() throws {
        let model = Model()
        let leftFlow = Flow(name: "left", expression: "0")
        let rightFlow = Flow(name: "right", expression: "0")
        
        model.add(leftFlow)
        model.add(rightFlow)
        model.connectFlow(from: leftFlow, to: rightFlow)
        
        let violations = model.constraintChecker.check()

        XCTAssertEqual(violations.count, 1)
            
        let violation = violations.first!
        
        XCTAssertEqual(violation.name, "forbidden_flow_to_flow")
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

//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 26/05/2022.
//

import XCTest

@testable import Flows
@testable import Graph

final class ModelTests: XCTestCase {

    func testAddStock() throws {
        let model = Model()
        let node = Stock(name: "c", float: 0)
        model.add(node)
        
        XCTAssertIdentical(model.stocks.first, node)
        XCTAssertTrue(node.contains(label: Model.StockNodeLabel))
    }

    func testAddFormula() throws {
        let model = Model()
        let node = Transform(name: "f", expression: "0")
        model.add(node)
        
        XCTAssertIdentical(model.transformations.first, node)
        XCTAssertTrue(node.contains(label: Model.TransformNodeLabel))
    }

    func testAddFlow() throws {
        let model = Model()
        let flow = Flow(name: "f", expression: "0")
        model.add(flow)
        
        XCTAssertIdentical(model.flows.first, flow)
        XCTAssertNil(flow.drains)
        XCTAssertNil(flow.fills)
        XCTAssertTrue(flow.contains(label: Model.FlowNodeLabel))
    }

    func testConnectFlow() throws {
        let model = Model()
        let flow = Flow(name: "flow", expression: "0")
        let input = Stock(name: "in", float: 100)
        let output = Stock(name: "out", float: 0)

        model.add(input)
        model.add(output)
        model.add(flow)

        let link = model.connect(from: input, to: flow, as: .flow)
        XCTAssertTrue(link.contains(label:Model.FlowLinkLabel))

        model.connect(from: flow, to: output, as: .flow)
        
        XCTAssertEqual(input.inflows, [])
        XCTAssertEqual(input.outflows, [flow])
        XCTAssertEqual(output.inflows, [flow])
        XCTAssertEqual(output.outflows, [])
        
        XCTAssertIdentical(flow.drains, input)
        XCTAssertIdentical(flow.fills, output)
    }

    func testLinkParameter() throws {
        let model = Model()
        let stock = Stock(name: "stock", expression: "0")
        let param = Transform(name: "param", float: 1)

        model.add(stock)
        model.add(param)

        let link: Link = model.connect(from: param, to: stock)
        XCTAssertTrue(link.contains(label:Model.ParameterLinkLabel))
    }
    
    func testIncomingNames() throws {
        let model = Model()
        let stock = Stock(name: "stock", expression: "0")
        let first = Transform(name: "first", float: 1)
        let second = Transform(name: "second", float: 2)
        let third = Transform(name: "third", float: 2)

        model.add(stock)
        model.add(first)
        model.add(second)
        model.add(third)

        model.connect(from: first, to: stock)
        model.connect(from: second, to: stock)

        XCTAssertEqual(stock.incomingParameterNodes, [first, second])
    }
    
    func testSingleInflow() {
        // NOTE: Sync with testSingleOutflow()
        let model = Model()
        let flow = Flow(name: "flow", expression: "0")
        let stock1 = Stock(name: "one", float: 0)
        let stock2 = Stock(name: "two", float: 0)
        model.add(flow)
        model.add(stock1)
        model.add(stock2)
        
        let violations1 = model.constraintChecker.check(graph: model.graph)
        XCTAssertTrue(violations1.isEmpty)
        
        // We connect the first flow
        model.connectFlow(from: stock1, to: flow)
        let violations2 = model.constraintChecker.check(graph: model.graph)
        XCTAssertTrue(violations2.isEmpty)

        // We connect it as a parameter, not as a flow - should be OK
        model.connect(from: stock1, to: flow, as: .parameter)
        let violations3 = model.constraintChecker.check(graph: model.graph)
        XCTAssertTrue(violations3.isEmpty)
        
        model.connectFlow(from: stock2, to: flow)
        let violations4 = model.constraintChecker.check(graph: model.graph)
        XCTAssertFalse(violations4.isEmpty)
        XCTAssertEqual(violations4.first?.name, "single_inflow_origin")
    }

    func testSingleOutflow() {
        // NOTE: Sync with testSingleInflow()
        let model = Model()
        let flow = Flow(name: "flow", expression: "0")
        let stock1 = Stock(name: "one", float: 0)
        let stock2 = Stock(name: "two", float: 0)
        model.add(flow)
        model.add(stock1)
        model.add(stock2)
        
        let violations1 = model.constraintChecker.check(graph: model.graph)
        XCTAssertTrue(violations1.isEmpty)
        
        model.connectFlow(from: flow, to: stock1)
        let violations2 = model.constraintChecker.check(graph: model.graph)
        XCTAssertTrue(violations2.isEmpty)

        model.connect(from: flow, to: stock1, as: .parameter)
        let violations3 = model.constraintChecker.check(graph: model.graph)
        XCTAssertTrue(violations3.isEmpty)

        model.connectFlow(from: flow, to: stock2)
        let violations4 = model.constraintChecker.check(graph: model.graph)
        XCTAssertFalse(violations4.isEmpty)
        XCTAssertEqual(violations4.first?.name, "single_outflow_target")
    }

    
    func testConnectFlowToFlow() throws {
        let model = Model()
        let leftFlow = Flow(name: "left", expression: "0")
        let rightFlow = Flow(name: "right", expression: "0")
        
        model.add(leftFlow)
        model.add(rightFlow)
        model.connectFlow(from: leftFlow, to: rightFlow)
        
        let violations = model.constraintChecker.check(graph: model.graph)

        XCTAssertEqual(violations.count, 2)

        if violations.count >= 2 {
            XCTAssertEqual(violations[0].name, "flow_fill_is_stock")
            XCTAssertEqual(violations[1].name, "flow_drain_is_stock")
        }
    }
    
    
    func testConnectFlowSameStock() throws {
        let model = Model()
        let flow = Flow(name: "flow", expression: "0")
        let input = Stock(name: "in", float: 100)

        model.add(input)
        model.add(flow)

        model.connect(from: input, to: flow, as: .flow)
        model.connect(from: flow, to: input, as: .flow)
        
        let violations = model.constraintChecker.check(graph: model.graph)

        XCTAssertEqual(violations.count, 1)
            
        if let violation = violations.first {
            XCTAssertEqual(violation.name, "drain_and_fill_is_different")
        }
        else {
            XCTFail()
        }
    }

    func testConnectFlowSameStockTrue() throws {
        // This tests that it does not apply to parameters
        let model = Model()
        let flow = Flow(name: "flow", expression: "0")
        let stock = Stock(name: "in", float: 100)

        model.add(stock)
        model.add(flow)

        model.connect(from: stock, to: flow, as: .parameter)
        model.connect(from: flow, to: stock, as: .parameter)
        model.connect(from: flow, to: stock, as: .flow)
        
        let violations = model.constraintChecker.check(graph: model.graph)

        XCTAssertEqual(violations.count, 0)
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

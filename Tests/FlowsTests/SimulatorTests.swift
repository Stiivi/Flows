import XCTest
@testable import Flows
import System

final class SimulatorTests: XCTestCase {
    func testNonNegative() throws {
//        try XCTSkipIf(true, "Non-negative stocks are not yet implemented")
        let model = Model()
        let stock = Stock(name: "stock", float: 5)
        stock.allowsNegative = false
        
        model.add(stock)
        model.add(Flow(name: "flow", expression: "10"))
        model.connectFlow(from: model["stock"]!, to: model["flow"]!)
        
        let simulator = Simulator(model: model)
        let state = simulator.run(steps: 1)
        XCTAssertEqual(state["stock"], 0)
    }
    func testNonNegativeToTwo() throws {
//        try XCTSkipIf(true, "Non-negative stocks are not yet implemented")
        let model = Model()
        let stock = Stock(name: "stock", float: 5)

        stock.allowsNegative = false

        model.add(stock)

        model.add(Stock(name: "first", float: 0))
        model.add(Stock(name: "second", float: 0))
        
        model.add(Flow(name: "first_flow", expression: "10"))
        model.connectFlow(from: model["stock"]!, to: model["first_flow"]!)
        model.connectFlow(from: model["first_flow"]!, to: model["first"]!)

        model.add(Flow(name: "second_flow", expression: "10"))
        model.connectFlow(from: model["stock"]!, to: model["second_flow"]!)
        model.connectFlow(from: model["second_flow"]!, to: model["second"]!)

        let simulator = Simulator(model: model)
        let state = simulator.run(steps: 1)
        XCTAssertEqual(state["stock"], 0.0)
        XCTAssertEqual(state["first"], 5.0)
        XCTAssertEqual(state["second"], 0.0)
    }
    
    func testFlow() throws {
        let model = Model()
        
        model.add(Stock(name: "a", float: 100))
        model.add(Stock(name: "b", float: 0))
        model.add(Stock(name: "c", float: 0))

        model.add(Flow(name: "f1", expression: "1"))
        model.add(Flow(name: "f2", expression: "2"))

        model.connect(from: model["a"]!, to: model["f1"]!, as: .flow)
        model.connect(from: model["f1"]!, to: model["b"]!, as: .flow)

        model.connect(from: model["a"]!, to: model["f2"]!, as: .flow)
        model.connect(from: model["f2"]!, to: model["c"]!, as: .flow)

        let simulator = Simulator(model: model)

        var state = simulator.run(steps: 1)

        XCTAssertEqual(state["a"], 97)
        XCTAssertEqual(state["b"], 1)
        XCTAssertEqual(state["c"], 2)

        state = simulator.run(steps: 9)
        
        XCTAssertEqual(state["a"], 70)
        XCTAssertEqual(state["b"], 10)
        XCTAssertEqual(state["c"], 20)
    }
    
    func testParameter() throws {
        let model = Model()
        model.add(Stock(name: "a", float: 100))
        model.add(Stock(name: "b", float: 0))

        model.add(Transform(name: "x", expression: "2" ))

        model.add(Flow(name: "f", expression: "x"))
        model.connectFlow(from: model["a"]!, to: model["f"]!)
        model.connectFlow(from: model["f"]!, to: model["b"]!)
        model.connect(from: model["x"]!, to: model["f"]!, as: .parameter)
        
        let simulator = Simulator(model: model)

        var state = simulator.run(steps: 1)

        XCTAssertEqual(state["a"], 98)
        XCTAssertEqual(state["b"], 2)

        state = simulator.run(steps: 9)
        XCTAssertEqual(state["a"], 80)
        XCTAssertEqual(state["b"], 20)
    }
}

import XCTest
@testable import Flows
import System

final class FlowsTests: XCTestCase {
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

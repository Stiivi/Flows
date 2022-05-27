import XCTest
@testable import Flows

final class FlowsTests: XCTestCase {
    func testFlow() throws {
        let model = Model()
        
        model.add(Container(name: "a", value: 100))
        model.add(Container(name: "b", value: 0))
        model.add(Container(name: "c", value: 0))

        model.add(Flow(name: "f1") { _ in 1 })
        model.add(Flow(name: "f2") { _ in 2 })

        model.connect(model["f1"] as! Flow, from: model["a"] as! Container)
        model.connect(model["f1"] as! Flow, to: model["b"] as! Container)

        model.connect(model["f2"] as! Flow, from: model["a"] as! Container)
        model.connect(model["f2"] as! Flow, to: model["c"] as! Container)

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
        model.add(Container(name: "a", value: 100))
        model.add(Container(name: "b", value: 0))

        model.add(Formula(name: "x") { _ in 2 } )

        model.add(Flow(name: "f") { $0["x"]! })
        model.connect(model["f"] as! Flow, from: model["a"] as! Container)
        model.connect(model["f"] as! Flow, to: model["b"] as! Container)

        model.connect(from: model["x"]!, to: model["f"]!)
        
        let simulator = Simulator(model: model)

        var state = simulator.run(steps: 1)

        XCTAssertEqual(state["a"], 98)
        XCTAssertEqual(state["b"], 2)

        state = simulator.run(steps: 9)
        XCTAssertEqual(state["a"], 80)
        XCTAssertEqual(state["b"], 20)
    }
}

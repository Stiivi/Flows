//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 15/06/2022.
//

import Foundation

import XCTest
@testable import Graph

final class ConstraintsTests: XCTestCase {
    func testUniqueNeighbourhoodConstraint() throws {
        let graph = Graph()
        let source = Node(labels:["source"])
        let target1 = Node(labels:["target1"])
        let target2 = Node(labels:["target2"])
        
        let constraint: NodeConstraint = NodeConstraint(
            name: "single_outflow",
            match: LabelPredicate(all: "source"),
            requirement: UniqueNeighbourRequirement(LinkSelector("flow", direction: .outgoing), required: false)
        )

        let constraintRequired: NodeConstraint = NodeConstraint(
            name: "single_outflow",
            match: LabelPredicate(all: "source"),
            requirement: UniqueNeighbourRequirement(LinkSelector("flow", direction: .outgoing), required: true)
        )

        graph.add(source)
        graph.add(target1)
        graph.add(target2)
        
        let flow1 = graph.connect(from: source, to: target1)
        let flow2 = graph.connect(from: source, to: target2)

        /// Non-required constraint is satisfied, the required constraint is not
        XCTAssertTrue(constraint.check(graph).isEmpty)
        XCTAssertEqual(constraintRequired.check(graph), [source])

        
        /// Both constraints are satisfied
        flow1.set(label: "flow")
        XCTAssertTrue(constraint.check(graph).isEmpty)
        XCTAssertTrue(constraintRequired.check(graph).isEmpty)

        /// Both constraints are not satisfied.
        flow2.set(label: "flow")
        ///
        XCTAssertEqual(constraint.check(graph), [source])
        XCTAssertEqual(constraintRequired.check(graph), [source])
    }
    
    func testLinkConstraint() throws {
        let graph = Graph()
        let node1 = Node(labels: ["this"])
        let node2 = Node(labels: ["that"])
        graph.add(node1)
        graph.add(node2)

        let linkGood = graph.connect(from: node1, to: node2, labels: ["good"])
        let linkBad = graph.connect(from: node1, to: node2, labels: ["bad"])

        let c1 = LinkConstraint(
            name: "test_constraint",
            match: LinkObjectPredicate(
                origin: LabelPredicate(all: "this"),
                target: LabelPredicate(all: "that"),
                link: LabelPredicate(all: "bad")
            ),
            requirement: RejectAll()
        )
        
        let violations1 = c1.check(graph)
        
        XCTAssertEqual(violations1, [linkBad])
        
        let c2 = LinkConstraint(
            name: "test_constraint",
            match: LinkObjectPredicate(
                origin: LabelPredicate(all: "this"),
                target: LabelPredicate(all: "that"),
                link: LabelPredicate(all: "bad")
            ),
            requirement: AcceptAll()
        )
        
        let violations2 = c2.check(graph)
        
        XCTAssertEqual(violations2, [])

    }
}

final class LinkRequirementsTests: XCTestCase {
    func testRejectAll() throws {
        let graph = Graph()
        let node = Node()
        graph.add(node)
        let link1 = graph.connect(from: node, to: node, labels: ["one"])
        let link2 = graph.connect(from: node, to: node, labels: ["two"])
        
        let requirement = RejectAll()
        let violations = requirement.check([link1, link2])
        XCTAssertEqual(violations.count, 2)
        XCTAssertEqual(violations, [link1, link2])
        
    }
}

final class TestUniqueProperty: XCTestCase {
    func testEmpty() throws {
        let req = UniqueProperty<OID> { $0.id }
        let violations = req.check(objects: [])
        XCTAssertTrue(violations.isEmpty)
    }

    func testNoDupes() throws {
        let req = UniqueProperty<OID> { $0.id }
        let objects = [
            Node(id: 10),
            Node(id: 20),
            Node(id: 30),
        ]
        
        let violations = req.check(objects: objects)
        XCTAssertTrue(violations.isEmpty)
    }

    func testHasDupes() throws {
        let req = UniqueProperty<OID> { $0.id }
        let n1 = Node(id: 10)
        let n1d = Node(id: 10)
        let n2 = Node(id: 20)
        let n3 = Node(id: 30)
        let n3d = Node(id: 30)
        let objects = [n1, n1d, n2, n3, n3d]

        let violations = req.check(objects: objects)
        XCTAssertEqual(violations.count, 4)
        
        XCTAssertTrue(violations.contains(n1))
        XCTAssertTrue(violations.contains(n1d))
        XCTAssertTrue(violations.contains(n3))
        XCTAssertTrue(violations.contains(n3d))
    }
}

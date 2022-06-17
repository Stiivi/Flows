//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 15/06/2022.
//

import Foundation

import XCTest
@testable import Graph

final class PredicateTests: XCTestCase {
    func testLabelPredicate() throws {
        let graph = Graph()
        let thing = Node(labels:["thing"])
        let other = Node()
        
        graph.add(thing)
        graph.add(other)
        
        let predicate = LabelPredicate(all: "thing")
        
        let matches = graph.nodes.filter { predicate.match($0) }

        XCTAssertEqual(matches.count, 1)
        XCTAssertIdentical(matches.first, thing)
    }
}

final class LinkPredicateTests: XCTestCase {
    func testLinkObjectPredicate() throws {
        let graph = Graph()
        let node1 = Node(labels: ["this"])
        let node2 = Node(labels: ["that"])
        graph.add(node1)
        graph.add(node2)

        let link12 = graph.connect(from: node1, to: node2, labels: ["in"])
        let link21 = graph.connect(from: node2, to: node1, labels: ["out"])

        let p1 = LinkObjectPredicate(origin: LabelPredicate(all: "this"))
        XCTAssertTrue(p1.match(link12))
        XCTAssertFalse(p1.match(link21))

        let p2 = LinkObjectPredicate(target: LabelPredicate(all: "this"))
        XCTAssertFalse(p2.match(link12))
        XCTAssertTrue(p2.match(link21))

        let p3 = LinkObjectPredicate(link: LabelPredicate(all: "in"))
        XCTAssertTrue(p3.match(link12))
        XCTAssertFalse(p3.match(link21))

        let p4 = LinkObjectPredicate(link: LabelPredicate(all: "out"))
        XCTAssertFalse(p4.match(link12))
        XCTAssertTrue(p4.match(link21))

        let link12empty = graph.connect(from: node1, to: node2, labels: [])
        let link21empty = graph.connect(from: node2, to: node1, labels: [])

        let p5 = LinkObjectPredicate(
            origin: LabelPredicate(all: "this"),
            target: LabelPredicate(all: "that"))

        XCTAssertTrue(p5.match(link12))
        XCTAssertTrue(p5.match(link12empty))
        XCTAssertFalse(p5.match(link21))
        XCTAssertFalse(p5.match(link21empty))

        let p6 = LinkObjectPredicate(
            origin: LabelPredicate(all: "this"),
            target: LabelPredicate(all: "that"),
            link: LabelPredicate(all: "in"))

        XCTAssertTrue(p6.match(link12))
        XCTAssertFalse(p6.match(link12empty))
        XCTAssertFalse(p6.match(link21))
        XCTAssertFalse(p6.match(link21empty))

    }
}

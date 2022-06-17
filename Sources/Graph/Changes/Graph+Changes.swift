//
//  Graph+Changes.swift
//  
//
//  Created by Stefan Urbanek on 28/02/2022.
//

extension Graph {
    public func applyChange(_ change: GraphChange) {
        switch change {
        // Observed changes
        case let .addNode(node):
            self.add(node)
        case let .removeNode(node):
            self.remove(node)
        case let .connect(link):
            self.add(link)
        case let .disconnect(link):
            self.disconnect(link: link)
//        case let .setAttribute(object, attribute, value):
//            object[attribute] = value
//        case let .unsetAttribute(object, attribute):
//            object[attribute] = nil
        }
    }
}

public typealias Function = (SimulationState) -> Float

public class Node: Equatable, Hashable {
    var name: String
    init(name: String) {
        self.name = name
    }
    
    public static func ==(lhs: Node, rhs: Node) -> Bool {
        return lhs === rhs
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    func evaluate(state: SimulationState) -> Float {
        fatalError("Subclasses of Node (\(type(of:self))) must implement \(#function)")
    }
}

public class Flow: Node {
    var origin: Container?
    var target: Container?
    var function: Function
    
    init(name: String,
         from origin: Container?=nil,
         to target: Container?=nil,
         function: @escaping Function){
        self.origin = origin
        self.target = target
        self.function = function
        super.init(name: name)
    }
    override func evaluate(state: SimulationState) -> Float {
        return function(state)
    }
}

public class Formula: Node {
    let function: Function
    
    init(name: String, _ function: @escaping Function) {
        self.function = function
        super.init(name: name)
    }
    override func evaluate(state: SimulationState) -> Float {
        return function(state)
    }
}

public class Container: Node {
    let initialValue: Float
    
    init(name: String, value: Float) {
        self.initialValue = value
        super.init(name: name)
    }
    
    override func evaluate(state: SimulationState) -> Float {
        return initialValue
    }
}

public class Link {
    let origin: Node
    let target: Node
    
    init(from origin: Node, to target: Node){
        self.origin = origin
        self.target = target
    }
}


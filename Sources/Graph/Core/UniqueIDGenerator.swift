//
//  UniqueIDGenerator.swift
//  
//
//  Created by Stefan Urbanek on 03/01/2022.
//

/// Protocol for generators of unique object IDs.
///
public protocol UniqueIDGenerator {
    
    /// Returns a next unique object ID.
    func next() -> OID
    
    /// Marks an ID to be already used. Prevents the generator from generating
    /// it. This is useful, for example, if the generator is providing IDs from
    /// a known pool of unique IDs, such as sequence of numbers.
    ///
    func markUsed(_ id: OID)
}


/// Generator of IDs as a sequence of numbers starting from 1.
///
/// Subsequent sequential order continuity is not guaranteed.
///
/// - Note: This is very primitive and naive sequence number generator. If an ID
///   is marked as used and the number is higher than current sequence, all
///   numbers are just skipped and the next sequence would be the used +1.
///   
public class SequentialIDGenerator {
    /// ID as a sequence number.
    var current: Int
    var used: Set<Int>
    
    /// Creates a sequential ID generator and initializes the sequence to 1.
    public init() {
        current = 1
        used = []
    }
    
    /// Gets a next sequence id.
    public func next() -> OID {
        var id = current
        while used.contains(id) {
            id += 1
            // We can remove the ID from the list of used, since we will never
            // touch it again. We just skip it.
            //
            used.remove(id)
        }
        current += 1
        return id
    }

    public func markUsed(_ id: OID) {
        used.insert(id)
    }
}

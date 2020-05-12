//
//  Station.swift
//  DAWG
//
//  Created by Eddie Craig on 14/10/2018.
//  Copyright © 2018 Simon Hogg. All rights reserved.
//

import Foundation

/// A Struct representing a aircraft station, allowing 'Store' to be loaded
public struct Station: CustomStringConvertible, Codable {
    
    var id: ID
    
    private var _store: Store?
    public var store: Store? { get { return _store }
        set {
            guard let store = newValue else { _store = nil; return }
            _ = add(store: store)
        }
    }
    public mutating func add(store: Store) -> Bool {
        guard store.authorisedStations.contains(id) else { print("Attempted to add store:\(store) to station \(id)"); return false }
        if [ID.one, ID.nine].contains(id) {
            _store = store
            return true
        } else if lastStore != nil && lastStore!.name == store.name, lastStore!.maxSimilarStores > 1 {
            guard let twinCarrier = store.twinCarrier?.copy() as? Store else { return false }
            if twinCarrier.add(child: store.copy() as! Store, using:id) && twinCarrier.add(child: store.copy() as! Store, using:id) {
                return add(store: twinCarrier)
            }
        } else if store.needsSuspension {
            let possibleSuspension = store.approvedSuspensionFor(id)
            for suspension in possibleSuspension {
                _ = suspension.add(child: store, using: id)
                if add(store: suspension) { return true }
            }
            return false
        } else {
            _store = store
            return true
        }
        return false
    }
    
    var lastStore: Store? { return store?.lastStore }
    var isEmpty: Bool {
        return store == nil
    }
    
    var weight: Measurement<UnitMass> {
        if store?.weight != nil {
            return store!.weight
        } else if id == .four || id == .six {
            return Measurement<UnitMass>(value: 16, unit: .pounds) // Blanking plate weight
        } else {
            return Measurement<UnitMass>(value: 0, unit: .pounds)
        }
    }
    var momentArm: Double
    var lateralAsymmetry: Double { return weight.value * momentArm }
    var di: Double { return store?.di ?? 0.0 }
    var mom: Double { return store?.mom(on: id) ?? 0.0 }
    var mac: Double { return store?.mac(on: id) ?? 0.0 }
    
    public enum ID: Int, CaseIterable, Codable, CustomStringConvertible {
        case one = 1, two, three, four, five, six, seven, eight, nine
        
        public var description: String { return "Station \(rawValue)"}
    }
    
    public init(id: ID) {
        self.id = id
        switch id {
        case .one, .nine:
            momentArm = 19.5
        case .two, .eight:
            momentArm = 11.2
        case .three, .seven:
            momentArm = 7.3
        case .four, .six:
            momentArm = 3.7
        case .five:
            momentArm = 0.0
        }
        if id.rawValue > 5 { momentArm *= -1 }
    }
    
    public mutating func removeStore() {
        if store?.lastStore == store {
            store = nil
        } else {
            store!.lastStore.removeFromParent()
        }
    }
    
    public mutating func clearStores() {
        store = nil
    }
    
    public var description: String {
        return "\(id.rawValue). \(store?.description ?? "")"
    }
}

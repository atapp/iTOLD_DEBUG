//
//  Stores.swift
//  DAWG
//
//  Created by Simon Hogg on 2018-10-04.
//  Copyright © 2018 Simon Hogg. All rights reserved.
//
import UIKit

/// Class representing a store carried on a aircraft
public final class Store: NSObject, Codable {
    
    static let UTI = "DAWG.Store"
    
    static let DirectMountKey = "DIRECT"
    
    private struct Constants {
        static let ImageSideSuffix = "_SIDE"
        static let ImageFrontSuffix = "_FRONT"
    }
    
    let uuid = UUID()
    
    public static let allStores: [Store] = {
        guard let url = Bundle.main.url(forResource: "Stores", withExtension: "plist") else { return [Store]() }
        do {
            let data = try Data(contentsOf: url)
            return try PropertyListDecoder().decode([Store].self, from: data)
        } catch {
            print(error)
            return [Store]()
        }
    }()
    
    static var allSuspension: [Store] { return allStores.filter{ $0.isSuspension }}
    
    public static func named(_ name: String) -> Store? {
        return allStores.first{ $0.name == name }?.copy() as? Store
    }

    var name: String
    var imageString: String
    
    /// Side image of store as a `StoreImage`
    public var imageSide: StoreImage? { return StoreImage(named: imageString + Constants.ImageSideSuffix) }
    var imageSideString: String  { return imageString + Constants.ImageSideSuffix }
    
    /// Front image of store as a `StoreImage`
    public var imageFront: StoreImage? {
        if (self.twinCarriagePoints == nil) {
            return StoreImage(named: imageString + Constants.ImageFrontSuffix)
        } else {
            return StoreImage(named: imageString + Constants.ImageFrontSuffix, multiplePoints: twinCarriagePoints)
        }
    }
    
    var ownWeight: Double
    
    /// Weight of store in pounds
    public var weight: Measurement<UnitMass> {
        get {
            let totalWeight = childStores.reduce(ownWeight){ $0 + ($1.weight.value)}
            return Measurement<UnitMass>(value: totalWeight, unit: .pounds)
        }
        set { ownWeight = newValue.value }
    }
    
    private var internalFuel: Double
    var fuel: Measurement<UnitMass> {
        get {
            if internalFuel == 0 {
                return Measurement<UnitMass>(value: childStores.reduce(0.0){ $0 + ($1.fuel.value)}, unit: .pounds)
            } else {
                return Measurement<UnitMass>(value: internalFuel, unit: .pounds)
            }
        }
        set { internalFuel = newValue.value }
    }
    var di: Double {
        let myDI = dragBySuspension[parentStore?.name ?? Store.DirectMountKey] ?? 0
        return childStores.reduce(myDI){ $0 + $1.di }
    }
    private var momByStation = [Int : Double]() {didSet {print("momByStation: ", self.momByStation)}}
    private var macByStation = [Int : Double]() {didSet {print("macByStation: ", self.macByStation)}}
    
    /// The stations the store is permitted to hang on as an array of `Station.ID`
    public var authorisedStations: [Station.ID] {
        var returnArray: [Station.ID] = []
        for (k,_) in momByStation {
            returnArray.append(Station.ID(rawValue: k)!)
        }
        return returnArray
    }
    func mom(on station: Station.ID) -> Double {
        return childStores.reduce(momByStation[station.rawValue]!){ $0 + $1.mom(on: station) }
    }
    func mac(on station: Station.ID) -> Double {
        //print(macByStation)
        return childStores.reduce(macByStation[station.rawValue]!){ $0 + $1.mac(on: station) }
    }
    
    private(set) var childStores = [Store]()
    var suspensionNames: [String] { return [String](dragBySuspension.keys) }
    weak var parentStore: Store?
    let maxChildStores: Int
    var maxSimilarStores: Int {
        let superMaxChildStores = approvedSuspension.map{ $0.maxSimilarStores }.max() ?? 1
        return superMaxChildStores > maxChildStores ? superMaxChildStores : maxChildStores
    }
    var canAddChild: Bool { return childStores.count < maxChildStores }
    var wip: String
    func add(child: Store, using station: Station.ID) -> Bool {
        if child.suspensionNames.contains(name) {
            if childStores.count > 0 {
                if maxChildStores > childStores.count && childStores.first!.name == child.name {
                    childStores.append(child)
                    child.parentStore = self
                    return true
                }
            } else {
                childStores.append(child)
                child.parentStore = self
                return true
            }
        } else {
            for suspension in child.approvedSuspensionFor(station) {
                _ = suspension.add(child: child, using: station)
                if add(child: suspension, using: station) { return true }
            }
        }
        return false
    }
    
    var lastStore: Store { return childStores.first != nil ? childStores.first!.lastStore : self }
    
    /// Remove the store from its parent
    public func removeFromParent() {
        if let index = parentStore?.childStores.firstIndex(of: self) {
            parentStore!.childStores.remove(at: index)
            parentStore = nil
        }
    }
    var twinCarrier: Store? {
        let twinCarrier = approvedSuspension.filter{ $0.maxChildStores > 1}.first
        if twinCarrier == nil {
            for suspension in approvedSuspension {
                if suspension.twinCarrier != nil { return suspension.twinCarrier }
            }
        }
        return twinCarrier
    }
    
    /// IF store is a twin carrier twinCarriagePints is an Array of Dictionarys containing widthDivisor: Double, heightDivisor: Double for each carriage point
    let twinCarriagePoints: [[String: Double]]?
    
    private var isSuspension: Bool { return maxChildStores > 0 }
    private let dragBySuspension: [String : Double]
    var approvedSuspension: [Store] {
        return suspensionNames.filter {
            $0 != Store.DirectMountKey }
            .map{ Store.named($0)! }
            .sorted{ $0.maxChildStores < $1.maxChildStores }
    }
    func approvedSuspensionFor(_ stationID: Station.ID) -> [Store] {
       return approvedSuspension.filter{ $0.authorisedStations.contains(stationID) }
    }
    var needsSuspension: Bool { return !suspensionNames.contains{ $0 == Store.DirectMountKey }}
    
    private enum CodingKeys: String, CodingKey {
        case name
        case imageString
        case ownWeight = "weight"
        case momByStation = "stations"
        case macByStation = "macByStation"
        case internalFuel = "fuel"
        case dragBySuspension = "suspension"
        case maxChildStores
        case wip
        case twinCarriagePoints = "childStorePoints"
    }
    
    /// Creates a store from a .plist of Stores
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.imageString = try container.decode(String.self, forKey: .imageString)
        self.ownWeight = try container.decode(Double.self, forKey: .ownWeight)

        self.macByStation = try container.decode([Int : Double].self, forKey: .macByStation)
        self.momByStation = try container.decode([Int : Double].self, forKey: .macByStation)
        self.internalFuel = try container.decode(Double.self, forKey: .internalFuel)
        self.dragBySuspension = try container.decode([String : Double].self, forKey: .dragBySuspension)
        self.maxChildStores = try container.decode(Int.self, forKey: .maxChildStores)
        self.wip = try container.decode(String.self, forKey: .wip)
        if container.contains(.twinCarriagePoints) {
            self.twinCarriagePoints = try container.decode([[String: Double]].self, forKey: .twinCarriagePoints)
            print("")
        } else {
            self.twinCarriagePoints = nil
        }
    }
    
    /// Creates a new store
    ///
    /// - Parameters:
    ///   - name: The name of the store
    ///   - imageString: The image string for the store
    ///   - weight: The weight of the store as a Double
    ///   - momByStation: A dictionary of the store moment value on each `Station.ID`
    ///   - macByStation: A dictionary of the store %MAC value on each `Station.ID`
    ///   - fuel: The fuel value the store can carry
    ///   - dragBySuspension: unused
    ///   - momByStation: A dictionary of the store on each `Station.ID`
    public init(name: String, imageString: String, weight: Double, momByStation: [Station.ID : Double], macByStation: [Station.ID : Double], fuel: Double, dragBySuspension: [String: Double], maxChildStores: Int, wip: String, twinCarriagePoints: [[String:Double]]?) {
        self.name = name
        self.imageString = imageString
        self.ownWeight = weight
        self.momByStation = { () -> [Int : Double] in
            var returnDict: [Int: Double] = [:]
            for (k,v) in momByStation {
                returnDict.updateValue(v, forKey: k.rawValue)
            }
            return returnDict
        }()
        self.macByStation = { () -> [Int : Double] in
            var returnDict: [Int: Double] = [:]
            for (k,v) in macByStation {
                returnDict.updateValue(v, forKey: k.rawValue)
            }
            return returnDict
        }()
        self.internalFuel = fuel
        self.dragBySuspension = dragBySuspension
        self.maxChildStores = maxChildStores
        self.wip = wip
        self.twinCarriagePoints = twinCarriagePoints
        super.init()
    }
    
    public override func copy() -> Any {
        let momByStationNew = { () -> [Station.ID : Double] in
            var returnDict: [Station.ID: Double] = [:]
            for (k,v) in momByStation {
                returnDict.updateValue(v, forKey: Station.ID.init(rawValue: k)!)
            }
            return returnDict
        }()
        let macByStationNew = { () -> [Station.ID : Double] in
            var returnDict: [Station.ID: Double] = [:]
            for (k,v) in macByStation {
                returnDict.updateValue(v, forKey: Station.ID.init(rawValue: k)!)
            }
            return returnDict
        }()
        return Store(name: name, imageString: imageString, weight: ownWeight, momByStation: momByStationNew, macByStation: macByStationNew, fuel: internalFuel, dragBySuspension: dragBySuspension, maxChildStores: maxChildStores, wip: wip, twinCarriagePoints: twinCarriagePoints)
    }
    
    public override var description: String {
        var returnString = "\(name)"
        for store in childStores {
            returnString = returnString + " + " + store.name
        }
        return returnString
    }
    
    /// Description of last store on rack
   public var shortDescrition: String {
        if let lastStore = childStores.last {
            if let lastStore2 = lastStore.childStores.last {
                if let lastStore3 = lastStore2.childStores.last {
                    if let lastStore4 = lastStore3.childStores.last {
                        return lastStore4.name
                    }
                    return lastStore3.name
                }
                return lastStore2.name
            }
            return lastStore.name
        } else {
            return name
        }
    }
}

extension Store: NSItemProviderWriting {
    
    var dragItem: UIDragItem {
        let dragItem = UIDragItem(itemProvider: NSItemProvider(object: self))
        dragItem.localObject = self
        dragItem.previewProvider = {
            let image = UIImageView(image: self.imageFront)
            image.frame = CGRect(x: 0, y: 0, width: 40, height: 40) // magic number for store preview size
            return UIDragPreview(view: image)
        }
        return dragItem
    }
    
    public static var writableTypeIdentifiersForItemProvider = [Store.UTI]
    
    public func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        do {
        let data = try JSONEncoder().encode(self)
            completionHandler(data, nil)
        } catch {
            completionHandler(nil, error)
        }
        return nil
    }
}

extension Store: NSItemProviderReading {
    
    public static var readableTypeIdentifiersForItemProvider = [Store.UTI]
    
    public static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> Store {
        return try JSONDecoder().decode(Store.self, from: data)
    }
}

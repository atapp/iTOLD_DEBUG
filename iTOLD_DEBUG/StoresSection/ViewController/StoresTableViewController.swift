//
//  StoresTableViewController.swift
//  DAWG
//
//  Created by Eddie Craig on 14/10/2018.
//  Copyright © 2018 Simon Hogg. All rights reserved.
//

import UIKit
import Combine

class StoresTableViewController: UITableViewController {
    
    private let asyncFetcher = StoreAsyncFetcher()
    
    var stores: [Store] =  Store.allStores.filter{ !Store.allSuspension.contains($0) }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dragDelegate = self
        //let rounds = 100
//        tableView.dataSource = stores
//        tableView.prefetchDataSource = stores
    }

    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int { return 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stores.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StoreCell", for: indexPath) as! StoreTableViewCell
        cell.storeLabel?.text = stores[indexPath.row].name
        cell.storeImageView?.image = stores[indexPath.row].imageSide
        cell.storeDetail?.text = "\(stores[indexPath.row].weight)"
        return cell
    }
}

// MARK: - Table view drag delegate

extension StoresTableViewController: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        return [stores[indexPath.row].dragItem]
    }

    func tableView(_ tableView: UITableView, dragSessionWillBegin session: UIDragSession) {
        guard let draggedStore = session.items.first?.localObject as? Store else { return }
        if draggedStore.maxSimilarStores > session.items.count {
            tableView.performBatchUpdates({
                let index = stores.firstIndex(of: draggedStore)!
                stores.remove(at: index)
                stores.insert(draggedStore.copy() as! Store, at: index)
                tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
            }, completion: nil)
        }
    }

    func tableView(_ tableView: UITableView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        guard let draggedStore = session.items.first?.localObject as? Store else { return [] }
        let tableStore = stores[indexPath.row]
        if draggedStore.name == tableStore.name && draggedStore.maxSimilarStores > session.items.count {
            return [tableStore.dragItem]
        } else {
            return []
        }
    }

    func tableView(_ tableView: UITableView, dragPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = tableView.cellForRow(at: indexPath) as? StoreTableViewCell else { return nil }
        let parameters = UIDragPreviewParameters()
        parameters.visiblePath = UIBezierPath(rect: cell.storeImageView.frame)
        return parameters
    }
}


extension StoresTableViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let store = stores[indexPath.row]
            asyncFetcher.fetchAsync(store.uuid)
        }
    }
    
    
}

extension ClosedRange {
    /// Clamps the value to ensure it is within the ClosedRange
    ///
    /// - Parameter value: Value to be clamped
    /// - Returns: Returns a number equal to the value given or the upper or lower bound if outside of the range
    func clamp(_ value : Bound) -> Bound {
        return self.lowerBound > value ? self.lowerBound
            : self.upperBound < value ? self.upperBound
            : value
    }
}

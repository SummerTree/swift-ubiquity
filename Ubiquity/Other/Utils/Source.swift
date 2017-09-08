//
//  Accessor.swift
//  Ubiquity
//
//  Created by SAGESSE on 5/24/17.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

///// Collection & Asset accessor
//internal class Accessor {
//    
//    /// Generate empty accessor
//    fileprivate init() {
//        _accessor = nil
//    }
//    /// Generate accessor for collection
//    init(collection: Collection) {
//        _accessor = _AccessorForCollection(collection: collection)
//    }
//    /// Generate accessor for collection type
//    init(collectionType: CollectionType) {
//        _accessor = _AccessorForCollectionList(collectionType: collectionType)
//    }
//    /// Generate accessor for collection types
//    init(collectionTypes: Array<CollectionType>) {
//        _accessor = _AccessorForCollectionLists(collectionTypes: collectionTypes)
//    }
//    
////    /// The accessor using the collection types
////    var collectionTypes: Array<CollectionType> {
////        return []
////    }
//    
//    /// Reload accessor with container
//    func reload(_ container: Container) {
//        _accessor?.reload(container)
//    }
//    
//    /// The number of collection.
//    var numberOfSections: Int {
//        return _accessor?.numberOfSections ?? 0
//    }
//    /// The number of assets at section.
//    func numberOfItems(inSection section: Int) -> Int {
//        return _accessor?.numberOfItems(inSection: section) ?? 0
//    }
//    
//    
//    private var _accessor: Accessor?
//}
//
//private class _AccessorForCollection: Accessor {
//    
//    /// Generate accessor for collection
//    override init(collection: Collection) {
//        super.init()
//    }
//    
//    /// Reload accessor with container
//    override func reload(_ container: Container) {
//    }
//    
//    /// The number of collection.
//    override var numberOfSections: Int {
//        return 0
//    }
//    /// The number of assets at section.
//    override func numberOfItems(inSection section: Int) -> Int {
//        return 0
//    }
//}
//private class _AccessorForCollectionList: Accessor {
//    
//    /// Generate accessor for collection type
//    override init(collectionType: CollectionType) {
//        _collectionType = collectionType
//        
//        super.init()
//    }
//    
//    /// Reload accessor with container
//    override func reload(_ container: Container) {
//        
//        
//        _collections = container.request(forCollectionList: _collectionType)
//        
////    var numberOfSections: Int {
////        return _collectionList.count
////    }
////    func numberOfItems(inSection section: Int) -> Int {
////        return _collectionList[section].count
////    }
////    
////    func collection(at section: Int) -> Collection {
////        return _collectionList[section]
////    }
////    
////    func asset(at indexPath: IndexPath) -> Asset {
////        return _collectionList[indexPath.section][indexPath.item]
////    }
////    
////    func changeDetails(for change: Change) -> ChangeDetails? {
////        return change.changeDetails(for: _collectionList)
////    }
////    
////    private var _collectionList: CollectionList
//        
//    }
//    
//    /// The number of collection.
//    override var numberOfSections: Int {
//        return 0
//    }
//    /// The number of assets at section.
//    override func numberOfItems(inSection section: Int) -> Int {
//        return 0
//    }
//    
//    private var _collections: CollectionList?
//    private var _collectionType: CollectionType
//}
//private class _AccessorForCollectionLists: Accessor {
//    
//    override init(collectionTypes: Array<CollectionType>) {
//        
//        
//        //self.collectionTypes = collectionTypes
//        super.init()
//    }
//    
//    /// Reload accessor with container
//    override func reload(_ container: Container) {
////        
////        // load moment
////        _AccessorForCollectionList(collectionType: .moment)
////
////        // load regular
////        _AccessorForCollectionList(collectionType: .regular)
////
////        // load recently
////        _AccessorForCollectionList(collectionType: .recentlyAdded)
//    }
//    
//    /// The number of collection.
//    override var numberOfSections: Int {
//        return 0
//    }
//    /// The number of assets at section.
//    override func numberOfItems(inSection section: Int) -> Int {
//        return 0
//    }
//    
//}
//
//
//
//
//
//internal class Source {
//    
//    init(collection: Collection) {
//        // init data
//        _adapter = CollectionAdapter(collection: collection)
//        _collectionType = collection.ub_collectionType
//        _collectionSubtype = collection.ub_collectionSubtype
//        
//        // config
//        title = collection.ub_title
//    }
//    
//    init(collectionType: CollectionType) {
//        // init data
//        _collectionType = collectionType
//        _collectionSubtype = .smartAlbumUserLibrary
//        
//        switch collectionType {
//        case .moment:
//            title = "Moments"
//            
//        case .regular:
//            title = "Photos"
//            
//        case .recentlyAdded:
//            title = "Recently"
//        }
//    }
//    
//    var title: String?
//    
//    var collectionType: CollectionType {
//        return _collectionType
//    }
//    
//    var collectionSubtype: CollectionSubtype {
//        return _collectionSubtype
//    }
//    
//    /// In this is source the footer view need display?
//    var isFooterViewHidden: Bool {
//        // automatic hidden
//        return false
//    }
//    
//    /// In this is source the header view need display?
//    var isHeaderViewHidden: Bool {
//        // display header only in moment
//        return _collectionType != .moment
//    }
//    
//    
//    var count: Int {
//        // adapter must be set
//        guard let adapter = _adapter else {
//            return 0
//        }
//        
//        // sum
//        return (0 ..< adapter.numberOfSections).reduce(0) {
//            $0 + adapter.numberOfItems(inSection: $1)
//        }
//    }
//    
//    func count(with type: AssetType) -> Int {
//        // adapter must be set
//        guard let adapter = _adapter else {
//            return 0
//        }
//        
//        // sum
//        return (0 ..< adapter.numberOfSections).reduce(0) {
//            $0 + adapter.collection(at: $1).ub_count(with: type)
//        }
//    }
//    
//    func load(with container: Container) {
//        // data is loaded?
//        guard _adapter == nil else {
//            return
//        }
//        
//        // setup
//        _adapter = CollectionListAdapter(collectionList: container.request(forCollectionList: _collectionType))
//    }
//    
//    func changeDetails(for change: Change) -> SourceChangeDetails? {
//        // adapter must be set
//        guard let adapter = _adapter else {
//            return nil
//        }
//        
//        // check sections change
//        guard let details = adapter.changeDetails(for: change) else {
//            return nil
//        }
//        
//        // check items change
//        let changes = (0 ..< adapter.numberOfSections).flatMap { section -> (Int, ChangeDetails)? in
//            // the adapter is `CollectionAdapter`
//            guard !(details.before is Collection) else {
//                return (section, details)
//            }
//            
//            // the section is deleted
//            guard !(details.removedIndexes?.contains(section) ?? false) else {
//                return nil
//            }
//            
//            // the collection has any change?
//            guard let details = change.ub_changeDetails(forCollection: adapter.collection(at: section)) else {
//                return nil
//            }
//            
//            // the collection is change at offset
//            return (section, details)
//        }
//        
//        // generate new chagne details for collectios
//        let newDetails = SourceChangeDetails(before: self, after: {
//            
//            let source = Source(collectionType: collectionType)
//            
//            // config title
//            source.title = title
//            
//            // only singe collection
//            if let collection = details.after as? Collection {
//                return Source(collection: collection)
//            }
//            // has more collections
//            if let collectionList = details.after as? CollectionList {
//                source._adapter = CollectionListAdapter(collectionList: collectionList)
//            }
//            
//            return source
//        }())
//        
//        // has more collections
//        if details.before is CollectionList {
//            // update section changes
//            newDetails.insertSections = details.insertedIndexes
//            newDetails.deleteSections = details.removedIndexes
//            newDetails.hasIncrementalChanges = true
//            
//            // has insert or delete? 
//            newDetails.hasAssetChanges = !(newDetails.insertSections?.isEmpty ?? true && newDetails.deleteSections?.isEmpty ?? true)
//        }
//        
//        // was deleted?
//        if details.after == nil {
//            newDetails.wasDeleted = true
//        }
//        
//        // apply changes
//        changes.reversed().forEach { section, details in
//            
//            // keep the new fetch result for future use.
//            guard details.after != nil else {
//                // the section is deleted
//                newDetails.hasIncrementalChanges = true
//                newDetails.deleteSections?.update(with: section)
//                return
//            }
//            
//            // has asset changes?
//            guard details.hasAssetChanges else {
//                return
//            }
//            newDetails.hasAssetChanges = true
//
//            // if there are incremental diffs, animate them in the table view.
//            guard details.hasIncrementalChanges else {
//                // reload the table view if incremental diffs are not available.
//                newDetails.reloadSections?.update(with: section)
//                return
//            }
//            newDetails.hasIncrementalChanges = true
//            
//            // merge items changes
//            newDetails.removeItems?.append(contentsOf: details.removedIndexes?.map({ .init(item: $0, section: section) }) ?? [])
//            newDetails.insertItems?.append(contentsOf: details.insertedIndexes?.map({ .init(item: $0, section: section) }) ?? [])
//            newDetails.reloadItems?.append(contentsOf: details.changedIndexes?.map({ .init(item: $0, section: section) }) ?? [])
//            
////            details.enumerateMoves { from, to in
////                newDetails.hasMoves = true
////                newDetails.moveItems?.append((.init(row: from, section: section), .init(row: to, section: section)))
////            }
//        }
//        
//        // clear invaild index path
//        newDetails.clear()
//        
//        // success
//        return newDetails
//    }
//    
//    
//    var numberOfSections: Int {
//        return _adapter?.numberOfSections ?? 0
//    }
//    
//    func numberOfItems(inSection section: Int) -> Int {
//        return _adapter?.numberOfItems(inSection: section) ?? 0
//    }
//    
//    func asset(at indexPath: IndexPath) -> Asset? {
//        return _adapter?.asset(at: indexPath)
//    }
//    
//    func collection(at section: Int) -> Collection? {
//        // check boundary
//        guard section < numberOfSections else {
//            return nil
//        }
//        return _adapter?.collection(at: section)
//    }
//    
//    private var _adapter: SourceAdapter?
//    
//    private var _collectionType: CollectionType
//    private var _collectionSubtype: CollectionSubtype
//}
//
//
//
internal class SourceChangeDetails {
//    
//    /// Create an change detail
//    init(before: Source, after: Source?) {
//        self.before = before
//        self.after = after
//    }
//    
//    /// the object in the state before this change
//    var before: Source
//    /// the object in the state after this change
//    var after: Source?
//    
//    /// A Boolean value that indicates whether objects have been rearranged in the fetch result.
//    var hasMoves: Bool = false
//    // YES if the object was deleted
//    var wasDeleted: Bool = false
//    /// A Boolean value that indicates whether objects have been any change in result.
//    var hasAssetChanges: Bool = false
//    /// A Boolean value that indicates whether changes to the fetch result can be described incrementally.
//    var hasIncrementalChanges: Bool = false
//    
//    /// The indexes from which objects have been removed from the fetch result.
//    var removeItems: [IndexPath]? = []
//    /// The indexes of objects in the fetch result whose content or metadata have been updated.
//    var reloadItems: [IndexPath]? = []
//    /// The indexes where new objects have been inserted in the fetch result.
//    var insertItems: [IndexPath]? = []
//    
//    var insertSections: IndexSet? = IndexSet()
//    var deleteSections: IndexSet? = IndexSet()
//    var reloadSections: IndexSet? = IndexSet()
//    
//    /// The indexs where new object have move
//    var moveItems: [(IndexPath, IndexPath)]?
//    
//    /// Runs the specified block for each case where an object has moved from one index to another in the fetch result.
//    func enumerateMoves(_ handler: @escaping (IndexPath, IndexPath) -> Swift.Void) {
//        moveItems?.forEach(handler)
//    }
//    
//    func clear() {
//        if insertSections?.isEmpty ?? true {
//            insertSections = nil
//        }
//        if deleteSections?.isEmpty ?? true {
//            deleteSections = nil
//        }
//        if reloadSections?.isEmpty ?? true {
//            reloadSections = nil
//        }
//        if removeItems?.isEmpty ?? false {
//            removeItems = nil
//        }
//        if insertItems?.isEmpty ?? false {
//            insertItems = nil
//        }
//        if reloadItems?.isEmpty ?? false {
//            reloadItems = nil
//        }
//        if moveItems?.isEmpty ?? true {
//            moveItems = nil
//            hasMoves = false
//        }
//    }
//    
}
//
//private protocol SourceAdapter {
//    
//    var title: String? { get }
//    
//    var numberOfSections: Int { get }
//    
//    func numberOfItems(inSection section: Int) -> Int
//    
//    func asset(at indexPath: IndexPath) -> Asset
//    
//    func collection(at section: Int) -> Collection
//    
//    func changeDetails(for change: Change) -> ChangeDetails?
//}
//
//private class CollectionAdapter: SourceAdapter {
//    
//    init(collection: Collection) {
//        _collection = collection
//    }
//    
//    var title: String? {
//        return _collection.ub_title
//    }
//    
//    var numberOfSections: Int {
//        return 1
//    }
//    func numberOfItems(inSection section: Int) -> Int {
//        return _collection.ub_count
//    }
//    
//    func collection(at section: Int) -> Collection {
//        return _collection
//    }
//    
//    func asset(at indexPath: IndexPath) -> Asset {
//        return _collection.ub_asset(at: indexPath.item)
//    }
//    
//    func changeDetails(for change: Change) -> ChangeDetails? {
//        return change.ub_changeDetails(forCollection: _collection)
//    }
//    
//    private var _collection: Collection
//}
//
//private class CollectionListAdapter: SourceAdapter {
//    
//    init(collectionList: CollectionList) {
//        _collectionList = collectionList
//    }
//    
//    var title: String? {
//        return nil
//    }
//    
//    var numberOfSections: Int {
//        return _collectionList.ub_count
//    }
//    func numberOfItems(inSection section: Int) -> Int {
//        return _collectionList.ub_collection(at: section).ub_count
//    }
//    
//    func collection(at section: Int) -> Collection {
//        return _collectionList.ub_collection(at: section)
//    }
//    
//    func asset(at indexPath: IndexPath) -> Asset {
//        return _collectionList.ub_collection(at: indexPath.section).ub_asset(at: indexPath.item)
//    }
//    
//    func changeDetails(for change: Change) -> ChangeDetails? {
//        return change.ub_changeDetails(forCollectionList: _collectionList)
//    }
//    
//    private var _collectionList: CollectionList
//}

//
//  BrowserCollectionController.swift
//  Ubiquity
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

/// the asset list in album
internal class BrowserAlbumController: UICollectionViewController {
    
    init(source: DataSource, container: Container) {
        _source = source
        _container = container
        
        // continue init the UI
        super.init(collectionViewLayout: BrowserAlbumLayout())
        
        // listen albums any change
        _container.register(self)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        // clear all cache request when destroyed
        _resetCachedAssets()
        
        // cancel listen change
        _container.unregisterObserver(self)
    }
    
    /// collection view cell class provider
    var collectionViewCellProvider: Templatize.Type {
        return BrowserAlbumCell.self
    }
    
    /// Reload data with authorization info
    func reloadData(with auth: AuthorizationStatus) {
        
        // check for authorization status
        guard auth == .authorized else {
            // no permission
            showError(with: "No Access Permissions", subtitle: "") // 此应用程序没有权限访问您的照片\n在\"设置-隐私-图片\"中开启后即可查看
            return
        }
        _authorized = true
        
        // check for assets count
        guard _source.count != 0 else {
            // count is zero, no data
            showError(with: "No Photos or Videos", subtitle: "You can sync photos and videos onto your iPhone using iTunes.")
            return
        }
        
        // config title
        title = _source.title
        
        // clear all error info
        clearError()
        
        // reload all data
        reloadData()
    }
    /// Reload data data and scroll to init position
    func reloadData() {
        
        // reload data
        collectionView?.reloadData()
        
        // scroll to init position if needed
        if let collectionView = collectionView {
            // collect information
            let edg = collectionView.contentInset
            let size = collectionViewLayout.collectionViewContentSize
            // scroll to bottom
            // if the contentOffset over boundary, reset vaild contentOffset in collectionView internal
            collectionView.contentOffset.y = size.height - (collectionView.frame.height - edg.bottom)
        }
        
        // content is loaded
        _prepared = true
        _targetContentOffset = collectionView?.contentOffset ?? .zero
        
        
        // update content offset
        if let scrollView = collectionView {
            scrollViewDidScroll(scrollView)
        }
    }
    
    override func loadView() {
        super.loadView()
        // setup controller
        title = "Collection"
        view.backgroundColor = .white
        
        // setup colleciton view
        collectionView?.register(collectionViewCellProvider.class(with: UIImageView.self), forCellWithReuseIdentifier: "ASSET-IMAGE")
        collectionView?.backgroundColor = .white
        collectionView?.alwaysBounceVertical = true
        collectionView?.contentInset = .init(top: 4, left: 0, bottom: 4, right: 0)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // update with authorization status
        _authorized = false
        _container.requestAuthorization { status in
            DispatchQueue.main.async {
                self.reloadData(with: status)
            }
        }
        
        title = _source.title
        navigationController?.isToolbarHidden = false
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // if the info view is show, update the layout
        if let infoView = _infoView {
            infoView.frame = view.bounds
        }
    }
    
    fileprivate let _source: DataSource
    fileprivate let _container: Container
    
    fileprivate var _prepared: Bool = false
    fileprivate var _authorized: Bool = false
    fileprivate var _showsFooterView: Bool = false
    
    fileprivate var _transitioning: Bool = false
    fileprivate var _targetContentOffset: CGPoint = .zero
    
    fileprivate var _previousPreheatRect: CGRect = .zero
    fileprivate var _previousTargetPreheatRect: CGRect = .zero
    
    fileprivate var _infoView: ErrorInfoView?
}

/// Add asset cache support
internal extension BrowserAlbumController {
    
    fileprivate func _resetCachedAssets() {
        // clean all cache
        _container.stopCachingImagesForAllAssets()
        _previousPreheatRect = .zero
    }

    fileprivate func _updateCachedAssets() {
        // Update only if the view is visible.
        guard let collectionView = collectionView, _prepared else {
            return
        }
        
        // The preheat window is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let targetVisibleRect = CGRect(origin: _targetContentOffset, size: collectionView.bounds.size)
        
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        let targetPreheatRect = targetVisibleRect.insetBy(dx: 0, dy: -0.5 * targetVisibleRect.height)

        var changes = [(new: CGRect, old: CGRect)]()
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - _previousPreheatRect.midY)
        if delta > view.bounds.height / 3 {
            // need change
            changes.append((preheatRect, _previousPreheatRect))
            // Store the preheat rect to compare against in the future.
            _previousPreheatRect = preheatRect
        }
        // Update only if the taget visible area is significantly different from the last preheated area.
        let targetDelta = abs(targetPreheatRect.midY - _previousTargetPreheatRect.midY)
        if targetDelta > view.bounds.height / 3 {
            // need change
            changes.append((targetPreheatRect, _previousTargetPreheatRect))
            // Store the preheat rect to compare against in the future.
            _previousTargetPreheatRect = targetPreheatRect
        }
        // is change?
        guard !changes.isEmpty else {
            return
        }
        //logger.debug?.write("preheatRect is change: \(changes)")
        
        // Compute the assets to start caching and to stop caching.
        let result = self._different(changes.map { $0.new }, changes.map { $0.old })
        
        let addedAssets = result.added
            .flatMap { self._indexPathsForElements(in: $0) }
            .flatMap { self._source.asset(at: $0) }
        
        let removedAssets = result.removed
            .flatMap { self._indexPathsForElements(in: $0) }
            .flatMap { self._source.asset(at: $0) }
            .filter { asset in !addedAssets.contains(where: { $0 === asset } ) }
        
        // Update the assets the PHCachingImageManager is caching.
        _container.startCachingImages(for: addedAssets, size: BrowserAlbumLayout.thumbnailItemSize, mode: .aspectFill, options: nil)
        _container.stopCachingImages(for: removedAssets, size: BrowserAlbumLayout.thumbnailItemSize, mode: .aspectFill, options: nil)
    }
    
    fileprivate func _different(_ new: [CGRect], _ old: [CGRect]) -> (added: [CGRect], removed: [CGRect]) {
        // calculates the area after subtracting the two rect
        func _subtract(_ r1: CGRect, _ r2: CGRect) -> [CGRect] {
            // if not intersect, do not calculate
            guard r1.intersects(r2) else {
                return [r1]
            }
            var result = [CGRect]()
            
            if r2.minY > r1.minY {
                result.append(.init(x: r1.minX, y: r1.minY, width: r1.width, height: r2.minY - r1.minY))
            }
            if r1.maxY > r2.maxY {
                result.append(.init(x: r1.minX, y: r2.maxY, width: r1.width, height: r1.maxY - r2.maxY))
            }
            
            return result
        }
        // union all rectangles
        func _union(_ rects: [CGRect]) -> [CGRect] {
            
            var result = [CGRect]()
            // must sort, otherwise there will be break rect
            rects.sorted(by: { $0.minY < $1.minY }).forEach { rect in
                // is intersects?
                guard let last = result.last, last.intersects(rect) else {
                    result.append(rect)
                    return
                }
                result[result.count - 1] = last.union(rect)
            }
            
            return result
        }
        // intersection all rectangles
        func _intersection(_ rects: [CGRect]) -> [CGRect] {
            
            var result = [CGRect]()
            // must sort, otherwise there will be break rect
            rects.sorted(by: { $0.minY < $1.minY }).forEach { rect in
                // is intersects?
                guard let last = result.last, last.intersects(rect) else {
                    result.append(rect)
                    return
                }
                result[result.count - 1] = last.intersection(rect)
            }
            
            return result
        }
        
        // step1: merge
        let newRects = _union(new)
        let oldRects = _union(old)
        
        // step2: split
        return (
            newRects.flatMap { new in
                _intersection(oldRects.flatMap { old in
                    _subtract(new, old)
                })
            },
            oldRects.flatMap { old in
                _intersection(newRects.flatMap { new in
                    _subtract(old, new)
                })
            }
        )
    }

    fileprivate func _indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}

/// Add library error info display support
internal extension BrowserAlbumController {
    
    /// Show error info in view controller
    func showError(with title: String, subtitle: String) {
        logger.trace?.write(title, subtitle)
        
        // clear view
        _infoView?.removeFromSuperview()
        _infoView = nil
        
        let infoView = ErrorInfoView(frame: view.bounds)
        
        infoView.title = title
        infoView.subtitle = subtitle
        infoView.backgroundColor = .white
        infoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // show view
        view.addSubview(infoView)
        _infoView = infoView
        
        // disable scroll
        collectionView?.isScrollEnabled = false
        collectionView?.reloadData()
    }
    
    /// Hiden all error info
    func clearError() {
        logger.trace?.write()
        
        // enable scroll
        collectionView?.isScrollEnabled = true
        collectionView?.alpha = 0
        
        // clear view
        _infoView?.removeFromSuperview()
        _infoView = nil
        
        // show animation
        UIView.animate(withDuration: 0.25) {  [weak collectionView] in
            collectionView?.alpha = 1
        }
    }
}

/// Add collection view display support
extension BrowserAlbumController: UICollectionViewDelegateFlowLayout {
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // if there is prepared, continue to wait
        guard _prepared else {
            return
        }
        
        // if isTracking is true, is a draging
        if scrollView.isTracking {
            // on draging, update target content offset
           _targetContentOffset = scrollView.contentOffset
        }
        
        // update the cache
        _updateCachedAssets()
    }
    
    override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        // update target content offset
        _targetContentOffset = .init(x: -scrollView.contentInset.left, y: -scrollView.contentInset.top)
        // if transitions animation is started, can't scroll
        return !_transitioning
    }
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // update target content offset
        _targetContentOffset = scrollView.contentOffset
    }
    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        // update target content offset
        _targetContentOffset = targetContentOffset.move()
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // without authorization, shows blank
        guard _authorized else {
            return 0
        }
        return _source.numberOfSections
    }
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // without authorization, shows blank
        guard _authorized else {
            return 0
        }
        return _source.numberOfItems(inSection: section)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "ASSET-IMAGE", for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
            return .zero
        }
        return layout.itemSize
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // cell must king of `Displayable`
        guard let displayer = cell as? Displayable, let asset = _source.asset(at: indexPath), _prepared else {
            return
        }
        
        // show asset with container and orientation
        displayer.willDisplay(with: asset, container: _container, orientation: .up)
    }
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // cell must king of `Displayable`
        guard let displayer = cell as? Displayable, _prepared else {
            return
        }
        
        displayer.endDisplay(with: _container)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        logger.trace?.write(indexPath)
        logger.debug?.write("show detail with: \(indexPath)")
        
        // make
        let controller = BrowserDetailController(source: _source, container: _container, at: indexPath)
        
        controller.animator = Animator(source: self, destination: controller)
        controller.updateDelegate = self
        
        show(controller, sender: indexPath)
    }    
}

/// Add animatable transitioning support
extension BrowserAlbumController: TransitioningDataSource {
    
    func ub_transitionView(using animator: Animator, for operation: Animator.Operation) -> TransitioningView? {
        logger.trace?.write()
        
        guard let indexPath = animator.indexPath else {
            return nil
        }
        // get at current index path the cell
        return collectionView?.cellForItem(at: indexPath) as? TransitioningView
    }
    
    func ub_transitionShouldStart(using animator: Animator, for operation: Animator.Operation) -> Bool {
        logger.trace?.write()
        return true
    }
    func ub_transitionShouldStartInteractive(using animator: Animator, for operation: Animator.Operation) -> Bool {
        logger.trace?.write()
        return false
    }
    
    func ub_transitionDidPrepare(using animator: Animator, context: TransitioningContext) {
        logger.trace?.write()
        
        // must be attached to the collection view
        guard let collectionView = collectionView, let indexPath = animator.indexPath  else {
            return
        }
        // check the index path is displaying
        if !collectionView.indexPathsForVisibleItems.contains(indexPath) {
            // no, scroll to the cell at index path
            collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            // must call the layoutIfNeeded method, otherwise cell may not create
            collectionView.layoutIfNeeded()
        }
        // fetch cell at index path, if is displayed
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            return
        }
        // if it is to, reset cell boundary
        if context.ub_operation == .pop || context.ub_operation == .dismiss {
            let frame = cell.convert(cell.bounds, to: view)
            let height = view.frame.height - topLayoutGuide.length - bottomLayoutGuide.length
            
            let y1 = -topLayoutGuide.length + frame.minY
            let y2 = -topLayoutGuide.length + frame.maxY
            
            // reset content offset if needed
            if y2 > height {
                // bottom over boundary, reset to y2(bottom)
                collectionView.contentOffset.y += y2 - height
            } else if y1 < 0 {
                // top over boundary, rest to y1(top)
                collectionView.contentOffset.y += y1
            }
        }
        cell.isHidden = true
        
        // current transitions animation is started
        _transitioning = true
    }
    func ub_transitionWillEnd(using animator: Animator, context: TransitioningContext, transitionCompleted: Bool) {
        logger.trace?.write(transitionCompleted)
        // if the disappear operation and indexPath is exists
        guard let indexPath = animator.indexPath, context.ub_operation.disappear else {
            return
        }
        // fetch cell at index path, if is displayed
        guard let cell = collectionView?.cellForItem(at: indexPath) else {
            return
        }
        guard let snapshotView = context.ub_snapshotView, let newSnapshotView = snapshotView.snapshotView(afterScreenUpdates: false) else {
            return
        }
        newSnapshotView.transform = snapshotView.transform
        newSnapshotView.bounds = .init(origin: .zero, size: snapshotView.bounds.size)
        newSnapshotView.center = .init(x: snapshotView.bounds.midX, y: snapshotView.bounds.midY)
        cell.addSubview(newSnapshotView)
        
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: {
            newSnapshotView.alpha = 0
        }, completion: { finished in
            newSnapshotView.removeFromSuperview()
        })
    }
    func ub_transitionDidEnd(using animator: Animator, transitionCompleted: Bool) {
        logger.trace?.write(transitionCompleted)
        // fetch cell at index path, if index path is nil ignore
        guard let indexPath = animator.indexPath, let cell = collectionView?.cellForItem(at: indexPath) else {
            return
        }
        cell.isHidden = false
        
        // current transitions animation is end
        _transitioning = false
    }
}

/// Add change update support
extension BrowserAlbumController: DetailControllerItemUpdateDelegate {
    
    // the item will show
    internal func detailController(_ detailController: Any, willShowItem indexPath: IndexPath) {
        // if is, this suggests that are displaying
        if collectionView?.indexPathsForVisibleItems.contains(indexPath) ?? false {
            return
        }
        logger.debug?.write("over screen, scroll to \(indexPath)")
        
        
        guard indexPath.section < _source.numberOfSections
            && indexPath.item < _source.numberOfItems(inSection: indexPath.section) else {
            return
        }
        
        // no displaying, scroll to item
        collectionView?.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
        collectionView?.layoutIfNeeded()
    }
    
    // the item did show
    internal func detailController(_ detailController: Any, didShowItem indexPath: IndexPath) {
    }
    
}

/// Add change update support
extension BrowserAlbumController: ChangeObserver {
    
    /// Tells your observer that a set of changes has occurred in the Photos library.
    internal func library(_ library: Library, didChange change: Change) {
        logger.trace?.write()
        
        // if the view controller no authorized, ignore all change
        guard _authorized else {
            return
        }
        
        // get data source change
        let changes = _source.collections.enumerated().flatMap { offset, collection -> (Int, ChangeDetails)? in
            // the collection has any change?
            guard let details = change.changeDetails(for: collection) else {
                return nil
            }
            return (offset, details)
        }
        
        // if changes is empty, the page no any change
        guard !changes.isEmpty else {
            return
        }
        
        // change notifications may be made on a background queue.
        // re-dispatch to the main queue to update the UI.
        DispatchQueue.main.async {
            // progressing
            self.library(library, didChange: change, changes: changes)
        }
    }
    
    /// Tells your observer that a set of changes has occurred in the Photos library.
    internal func library(_ library: Library, didChange change: Change, changes: [(Int, ChangeDetails)]) {
        
        // get current table view
        guard let collectionView = self.collectionView else {
            return
        }
        
        var hasCollectionDeleted = false
        var hasAssetChanged = false
        
        var movedItems = Array<(IndexPath, IndexPath)>()
        
        var deleteItems = Array<IndexPath>()
        var insertItems = Array<IndexPath>()
        var reloadItems = Array<IndexPath>()
        
        var reloadSections = IndexSet()
        
        changes.reversed().forEach { section, details in
            
            // update data source
            if let collection = details.after as? Collection {
                // keep the new fetch result for future use.
                _source.collections[section] = collection
            } else {
                // the collection is deleted
                hasCollectionDeleted = true
                _source.collections.remove(at: section)
            }
            
            // has asset changes?
            guard details.hasAssetChanges else {
                return
            }
            hasAssetChanged = true
            
            // if there are incremental diffs, animate them in the table view.
            guard details.hasIncrementalChanges else {
                // reload the table view if incremental diffs are not available.
                reloadSections.update(with: section)
                return
            }
            
            deleteItems.append(contentsOf: details.removedIndexes?.map({ .init(item: $0, section:0) }) ?? [])
            insertItems.append(contentsOf: details.insertedIndexes?.map({ .init(item: $0, section:0) }) ?? [])
            reloadItems.append(contentsOf: details.changedIndexes?.map({ .init(item: $0, section:0) }) ?? [])
            
            details.enumerateMoves { from, to in
                movedItems.append((.init(row: from, section: section), .init(row: to, section: section)))
            }
        }
        
        // update collection change
        title = _source.title
        
        // update collection asset count change
        guard _source.count != 0 else {
            // count is zero, no data
            showError(with: "No Photos or Videos", subtitle: "You can sync photos and videos onto your iPhone using iTunes.")
            reloadData()
            return
        }
        
        // clear error info if needed
        clearError()
        
        // the content is prepared
        _prepared = true
        
        // the collection is deleted?
        guard !hasCollectionDeleted else {
            // has any delete, must reload
            reloadData()
            return
        }
        
        // the aset has any change?
        guard hasAssetChanged else {
            return
        }
        
        logger.debug?.write(insertItems, deleteItems, reloadItems, movedItems, reloadSections)
        
        // update collection
        collectionView.performBatchUpdates({
            
            // reload the table view if incremental diffs are not available.
            collectionView.reloadSections(reloadSections)
            
            // For indexes to make sense, updates must be in this order:
            // delete, insert, reload, move
            collectionView.deleteItems(at: deleteItems)
            collectionView.insertItems(at: insertItems)
            collectionView.reloadItems(at: reloadItems)
            
            // move
            movedItems.forEach { from, to in
                collectionView.moveItem(at: from, to: to)
            }
            
        }, completion: nil)
    }
    
}

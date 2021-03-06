//
//  CanvasView.swift
//  Ubiquity
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

@objc public protocol CanvasViewDelegate {
    
    @objc optional func canvasViewDidScroll(_ canvasView: CanvasView) /// any offset changes
    @objc optional func canvasViewDidZoom(_ canvasView: CanvasView) /// any zoom scale changes
    @objc optional func canvasViewDidRotation(_ canvasView: CanvasView) /// any rotation changes
    
    @objc optional func viewForZooming(in canvasView: CanvasView) -> UIView? /// return a view that will be scaled. if delegate returns nil, nothing happens
    
    /// called on start of dragging (may require some time and or distance to move)
    @objc optional func canvasViewWillBeginDragging(_ canvasView: CanvasView)
    
    /// called on finger up if the user dragged. velocity is in points/millisecond. targetContentOffset may be changed to adjust where the scroll view comes to rest
    @objc optional func canvasViewWillEndDragging(_ canvasView: CanvasView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)
    
    /// called on finger up if the user dragged. decelerate is true if it will continue moving afterwards
    @objc optional func canvasViewDidEndDragging(_ canvasView: CanvasView, willDecelerate decelerate: Bool)
    
    @objc optional func canvasViewWillBeginDecelerating(_ canvasView: CanvasView) /// called on finger up as we are moving
    @objc optional func canvasViewDidEndDecelerating(_ canvasView: CanvasView) /// called when scroll view grinds to a halt
    
    @objc optional func canvasViewDidEndScrollingAnimation(_ canvasView: CanvasView) /// called when setContentOffset/scrollRectVisible:animated: finishes. not called if not animating
    
    @objc optional func canvasViewShouldScrollToTop(_ canvasView: CanvasView) -> Bool /// return a yes if you want to scroll to the top. if not defined, assumes YES
    @objc optional func canvasViewDidScrollToTop(_ canvasView: CanvasView) /// called when scrolling animation finished. may be called immediately if already at top
    
    @objc optional func canvasViewWillBeginZooming(_ canvasView: CanvasView, with view: UIView?) /// called before the scroll view begins zooming its content
    @objc optional func canvasViewDidEndZooming(_ canvasView: CanvasView, with view: UIView?, atScale scale: CGFloat) /// scale between minimum and maximum. called after any 'bounce' animations
    
    @objc optional func canvasViewShouldBeginRotationing(_ canvasView: CanvasView, with view: UIView?) -> Bool /// called before the scroll view begins zooming its content
    @objc optional func canvasViewWillEndRotationing(_ canvasView: CanvasView, with view: UIView?, atOrientation orientation: UIImageOrientation)
    @objc optional func canvasViewDidEndRotationing(_ canvasView: CanvasView, with view: UIView?, atOrientation orientation: UIImageOrientation) /// scale between minimum and maximum. called after any 'bounce' animations
}


@objc public class CanvasView: UIView {
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.prepare()
    }
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.prepare()
    }
    
    public weak var delegate: CanvasViewDelegate?
    
    /// default CGPointZero
    @NSManaged public var contentOffset: CGPoint
    /// default UIEdgeInsetsZero. add additional scroll area around content
    @NSManaged public var contentInset: UIEdgeInsets
    
    /// default YES. if YES, bounces past edge of content and back again
    @NSManaged public var bounces: Bool
    /// default NO. if YES and bounces is YES, even if content is smaller than bounds, allow drag vertically
    @NSManaged public var alwaysBounceVertical: Bool
    /// default NO. if YES and bounces is YES, even if content is smaller than bounds, allow drag horizontally
    @NSManaged public var alwaysBounceHorizontal: Bool
    
    /// default YES. turn off any dragging temporarily
    @NSManaged public var isScrollEnabled: Bool
    
    /// default YES. show indicator while we are tracking. fades out after tracking
    @NSManaged public var showsHorizontalScrollIndicator: Bool
    /// default YES. show indicator while we are tracking. fades out after tracking
    @NSManaged public var showsVerticalScrollIndicator: Bool
    /// default is UIEdgeInsetsZero. adjust indicators inside of insets
    @NSManaged public var scrollIndicatorInsets: UIEdgeInsets
    /// default is UIScrollViewIndicatorStyleDefault
    @NSManaged public var indicatorStyle: UIScrollViewIndicatorStyle
    
    @NSManaged public var decelerationRate: CGFloat
    
    /// default is YES. if NO, we immediately call -touchesShouldBegin:withEvent:inContentView:. this has no effect on presses
    @NSManaged public var delaysContentTouches: Bool
    /// default is YES. if NO, then once we start tracking, we don't try to drag if the touch moves. this has no effect on presses
    @NSManaged public var canCancelContentTouches: Bool
    
    /// default is 1.0
    @NSManaged public var minimumZoomScale: CGFloat
    @NSManaged public var maximumZoomScale: CGFloat
    /// default is 1.0
    @NSManaged public var zoomScale: CGFloat
    /// default is YES. if set, user can go past min/max zoom while gesturing and the zoom will animate to the min/max value at gesture end
    @NSManaged public var bouncesZoom: Bool
    /// default is YES.
    @NSManaged public var scrollsToTop: Bool
    
    /// animate at constant velocity to new offset
    @NSManaged public func setContentOffset(_ contentOffset: CGPoint, animated: Bool)
    /// scroll so rect is just visible (nearest edges). nothing if rect completely visible
    @NSManaged public func scrollRectToVisible(_ rect: CGRect, animated: Bool)
    
    /// default CGSizeZero
    public var contentSize: CGSize = .zero
    /// default is UIImageOrientationUp
    public var orientation: UIImageOrientation {
        set { return _updateOrientation(with: _angle(for: orientation), animated: false) }
        get { return _orientation }
    }
    
    public func setZoomScale(_ scale: CGFloat, animated: Bool) {
        _containerView.setZoomScale(scale, animated: animated)
    }
    public func setZoomScale(_ scale: CGFloat, at point: CGPoint, animated: Bool) {
        guard let view = _contentView else {
            return setZoomScale(scale, animated: animated)
        }
        logger.trace?.write(scale, point, animated)
        
        let width = view.bounds.width * scale
        let height = view.bounds.height * scale
        
        let ratioX = max(min(point.x, view.bounds.width), 0) / max(view.bounds.width, 1)
        let ratioY = max(min(point.y, view.bounds.height), 0) / max(view.bounds.height, 1)
        
        // calculate the location of this point in zoomed
        let x = max(min(width * ratioX - _containerView.frame.width / 2, width - _containerView.frame.width), 0)
        let y = max(min(height * ratioY - _containerView.frame.height / 2, height - _containerView.frame.height), 0)
        
        guard animated else {
            _containerView.zoomScale = scale
            _containerView.contentOffset = CGPoint(x: x, y: y)
            return
        }
        
        UIView.animate(withDuration: 0.35, animations: { [_containerView] in
            UIView.setAnimationBeginsFromCurrentState(true)
            
            _containerView.zoomScale = scale
            _containerView.contentOffset = CGPoint(x: x, y: y)
        })
    }
    public func zoom(to rect: CGRect, with orientation: UIImageOrientation, animated: Bool) {
        let size = _contentSize(for: orientation)

        // cache
        _bounds = bounds
        _orientation = orientation
        
        _containerView.frame = bounds
        _containerView.zoomScale = 1
        _contentView?.frame.size = size
        
        // update init size
        _updateScale(false)
        _updateOffset(contentOffset)
        
        // if the content is too small, ignore it
        guard rect.width < size.width || rect.height < size.height else {
            return
        }
        _containerView.zoomScale = min(rect.width / max(size.width, 1), rect.height / max(size.height, 1))
    }
    
    public func setOrientation(_ orientation: UIImageOrientation, animated: Bool) {
        _updateOrientation(with: _angle(for: orientation), animated: animated)
    }
    
    @NSManaged public var isLockContentOffset: Bool
    
    /// displays the scroll indicators for a short time. This should be done whenever you bring the scroll view to front.
    @NSManaged public func flashScrollIndicators()
    
    /// returns YES if user has touched. may not yet have started dragging
    @NSManaged public var isTracking: Bool
    /// returns YES if user has started scrolling. this may require some time and or distance to move to initiate dragging
    @NSManaged public var isDragging: Bool
    /// returns YES if user isn't dragging (touch up) but scroll view is still moving
    @NSManaged public var isDecelerating: Bool
    
    /// returns YES if user in zoom gesture
    @NSManaged public var isZooming: Bool
    /// returns YES if we are in the middle of zooming back to the min/max value
    @NSManaged public var isZoomBouncing: Bool
    
    /// returns YES if user in rotation gesture
    public var isRotationing: Bool {
        return _isRotationing
    }
    
    /// Use these accessors to configure the scroll view's built-in gesture recognizers.
    /// Do not change the gestures' delegates or override the getters for these properties.
    
    /// Change `panGestureRecognizer.allowedTouchTypes` to limit scrolling to a particular set of touch types.
    @NSManaged public var panGestureRecognizer: UIPanGestureRecognizer
    /// `pinchGestureRecognizer` will return nil when zooming is disabled.
    @NSManaged public var pinchGestureRecognizer: UIPinchGestureRecognizer?
    
    /// `pinchGestureRecognizer` will return nil when zooming is disabled.
    public var rotationGestureRecognizer: UIRotationGestureRecognizer? {
        // if there is no `zoomingView` there is no rotation gesture
        guard let _ = _contentView else {
            return nil
        }
        return _rotationGestureRecognizer
    }
    
    public var contentTransform: CGAffineTransform {
        return _containerView.transform
    }
    
//    override func setNeedsLayout() {
//        super.setNeedsLayout()
//        _containerView.setNeedsLayout()
//    }
//    override func layoutIfNeeded() {
//        super.layoutIfNeeded()
//        _containerView.layoutIfNeeded()
//    }
    
    
    public override func addSubview(_ view: UIView) {
        // always allows add to self
        _containerView.addSubview(view)
    }
    
    // update subview layout
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // size is change?
        if _bounds?.size != bounds.size {
            // Must read in offset before the frame update, otherwise offset will change in the update frame.
            let offset = contentOffset
            
            // Update content frame.
            _containerView.frame = bounds
            
            _updateScale(true)
            _updateOffset(offset, converting: true)

            // Offset needs for mapping, it is necessary to update the bounds after updating the offset
            _bounds = bounds
            
            // need to notice delegate when update the bounds
            scrollViewDidScroll(_containerView)
        }
    }
    public override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return _containerView
    }
    
    /// get content with orientation
    fileprivate func _contentSize(for orientation: UIImageOrientation) -> CGSize {
        if _isLandscape(for: orientation) {
            return CGSize(width: contentSize.height, height: contentSize.width)
        }
        return contentSize
    }
    
    fileprivate func _maximumZoomScale(for orientation: UIImageOrientation) -> CGFloat {
        return 1.25
    }
    fileprivate func _minimumZoomScale(for orientation: UIImageOrientation) -> CGFloat {
        let size = _contentSize(for: orientation)
        let scale = min(min(bounds.width / max(size.width, 1), bounds.height / max(size.height, 1)), 1)
        
        // if scale is closer to width , recomputing scale
        if fabs(bounds.width - size.width * scale) < 2 {
            return bounds.width / max(size.width, 1)
        }

        return scale
    }
    
    fileprivate func _updateScale(_ converting: Bool) {
        // get width and height and scale for orientation
        let size = _contentSize(for: _orientation)
        let display = _contentView?.frame.size ?? .zero
        
        let minimumZoomScale = _minimumZoomScale(for: _orientation)
        let maximumZoomScale = _maximumZoomScale(for: _orientation)
        
        var zoomScale = max(max(display.width / max(size.width, 1), display.height / max(size.height, 1)), 0)

        // automatic fix scale for current
        if converting && _containerView.zoomScale >= _containerView.maximumZoomScale {
            zoomScale = maximumZoomScale // max
        }
        if converting && _containerView.zoomScale <= _containerView.minimumZoomScale {
            zoomScale = minimumZoomScale // min
        }
        
        logger.trace?.write("size: \(size), scale: \(zoomScale)/\(minimumZoomScale)/\(maximumZoomScale)")
        
        // update zoome sacle
        _containerView.minimumZoomScale = minimumZoomScale
        _containerView.maximumZoomScale = maximumZoomScale
        _containerView.zoomScale = zoomScale
    }
    fileprivate func _updateOffset(_ offset: CGPoint, converting: Bool = false) {
        // if contentView is not set, ignore
        guard let view = _contentView else {
            return
        }

        // reset center
        _contentView?.center = CGPoint(x: max(view.frame.width, bounds.width) / 2, y: max(view.frame.height, bounds.height) / 2)
        _containerView.contentOffset = {

            let x = max(min(offset.x + ((_bounds?.width ?? 0) - bounds.width) / 2, _containerView.contentSize.width - bounds.width), 0)
            let y = max(min(offset.y + ((_bounds?.height ?? 0) - bounds.height) / 2, _containerView.contentSize.height - bounds.height), 0)

            return CGPoint(x: x, y: y)
        }()
    }
    
    fileprivate func prepare() {
        
        clipsToBounds = true
        
        _containerView.frame = bounds
        _containerView.delegate = self
        _containerView.clipsToBounds = false
        _containerView.delaysContentTouches = false
        _containerView.canCancelContentTouches = false
        _containerView.showsVerticalScrollIndicator = false
        _containerView.showsHorizontalScrollIndicator = false
        //_containerView.alwaysBounceVertical = true
        //_containerView.alwaysBounceHorizontal = true

        // In iOS11, the default adjustment behavior need closed
        if #available(iOS 11.0, *) {
            _containerView.contentInsetAdjustmentBehavior = .never
        }
        
        _rotationGestureRecognizer.delegate = self
        
        super.addSubview(_containerView)
        super.addGestureRecognizer(_rotationGestureRecognizer)
    }
    
    fileprivate var _bounds: CGRect?
    fileprivate var _targetOffset: CGPoint?
    fileprivate var _isRotationing: Bool = false
    
    fileprivate var _orientation: UIImageOrientation = .up {
        didSet {
            delegate?.canvasViewDidRotation?(self)
        }
    }
    fileprivate var _contentView: UIView? {
        return delegate?.viewForZooming?(in: self)
    }
    
    fileprivate lazy var _containerView: CanvasContainerView = CanvasContainerView()
    
    fileprivate lazy var _rotationGestureRecognizer: UIRotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(rotationHandler(_:)))
}

extension CanvasView {
    
    /// convert orientation to angle
    fileprivate func _angle(for orientation: UIImageOrientation) -> CGFloat {
        switch orientation {
        case .up, .upMirrored:
            return 0 * CGFloat.pi / 2
            
        case .right, .rightMirrored:
            return 1 * CGFloat.pi / 2
            
        case .down, .downMirrored:
            return 2 * CGFloat.pi / 2
            
        case .left, .leftMirrored:
            return 3 * CGFloat.pi / 2
        }
    }
    
    /// convert angle to orientation
    fileprivate func _orientation(for angle: CGFloat) -> UIImageOrientation {
        switch Int(angle / (.pi / 2)) % 4 {
        case 0:     return .up
        case 1, -3: return .right
        case 2, -2: return .down
        case 3, -1: return .left
        default:    return .up
        }
    }
    fileprivate func _isLandscape(for orientation: UIImageOrientation) -> Bool {
        switch orientation {
        case .left, .leftMirrored: return true
        case .right, .rightMirrored: return true
        case .up, .upMirrored: return false
        case .down, .downMirrored: return false
        }
    }
    
    /// with angle update orientation
    fileprivate func _updateOrientation(with angle: CGFloat, animated: Bool, completion handler: ((Bool) -> Void)? = nil) {
        //_logger.trace(angle)
        
        let oldOrientation = _orientation
        let newOrientation = _orientation(for: _angle(for: _orientation) + angle)
        
        // get contentView width and height
        let view = _contentView
        let width = max(_contentSize(for: newOrientation).width, 1)
        let height = max(_contentSize(for: newOrientation).height, 1)
        
        // calc minimum scale ratio
        let minimumZoomScale = _minimumZoomScale(for: newOrientation)
        let maximumZoomScale = _maximumZoomScale(for: newOrientation)

        let newBounds = CGRect(x: 0, y: 0, width: width * minimumZoomScale, height: height * minimumZoomScale)
        let newTransform = CGAffineTransform(rotationAngle: angle)
        
        let animations: () -> Void = { [_containerView] in
            // orientation is change?
            if oldOrientation != newOrientation {
                // changed
                _containerView.transform = newTransform
                _containerView.frame = self.bounds
                
                _containerView.minimumZoomScale = minimumZoomScale
                _containerView.maximumZoomScale = maximumZoomScale
                _containerView.zoomScale = _containerView.minimumZoomScale
                _containerView.contentOffset = .zero
                _containerView.contentSize = newBounds.size
                
                view?.frame = newBounds.applying(newTransform)
                view?.center = CGPoint(x: _containerView.bounds.midX, y: _containerView.bounds.midY)
                
            } else {
                // not change
                _containerView.transform = .identity
            }
        }
        let completion: (Bool) -> Void = { [_containerView] isFinished in
            
            if oldOrientation != newOrientation {
                
                _containerView.transform = .identity
                _containerView.frame = self.bounds

                view?.frame = newBounds
                view?.center = CGPoint(x: _containerView.bounds.midX, y: _containerView.bounds.midY)
            }
            
            handler?(isFinished)
        }
        // update
        _orientation = newOrientation
        // can use animation?
        if !animated {
            animations()
            completion(true)
            return
        }
        
        UIView.animate(withDuration: 0.35, animations: animations, completion: completion)
    }
    
    /// rotation handler
    @objc fileprivate dynamic func rotationHandler(_ sender: UIRotationGestureRecognizer) {
        // is opened rotation?
        guard _isRotationing else {
            return
        }
        _containerView.transform = CGAffineTransform(rotationAngle: sender.rotation)
        // state is end?
        guard sender.state == .ended || sender.state == .cancelled || sender.state == .failed else {
            //delegate?.canvasViewDidRotation?(self)
            return
        }
        // call update orientation
        _isRotationing = false
        _updateOrientation(with: round(sender.rotation / (.pi / 2)) * (.pi / 2), animated: true) { f in
            // callback notifi user
            self.delegate?.canvasViewDidEndRotationing?(self, with: self._contentView, atOrientation: self._orientation)
        }
    }

}

///
/// Provide the gesture recognition support
///
extension CanvasView: UIGestureRecognizerDelegate {
    
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if _rotationGestureRecognizer === gestureRecognizer {
            // if no found contentView, can't roation
            guard let view = _contentView else {
                return false
            }
            // can rotation?
            guard delegate?.canvasViewShouldBeginRotationing?(self, with: view) ?? true else {
                return false
            }
            _isRotationing = true
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer.view === _containerView {
            return true
        }
        return false
    }
    
}

///
/// Provide the scroll view display support
///
extension CanvasView: UIScrollViewDelegate {
    
    /// any offset changes
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.canvasViewDidScroll?(self)
    }
    
    /// any zoom scale changes
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if let view = _contentView {
            view.center = CGPoint(x: max(view.frame.width, bounds.width) / 2, y: max(view.frame.height, bounds.height) / 2)
        }
        delegate?.canvasViewDidZoom?(self)
    }
    
    /// called on start of dragging (may require some time and or distance to move)
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.canvasViewWillBeginDragging?(self)
    }
    
    /// called on finger up if the user dragged. velocity is in points/millisecond. targetContentOffset may be changed to adjust where the scroll view comes to rest
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        delegate?.canvasViewWillEndDragging?(self, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
    /// called on finger up if the user dragged. decelerate is true if it will continue moving afterwards
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        delegate?.canvasViewDidEndDragging?(self, willDecelerate: decelerate)
    }
    
    /// called on finger up as we are moving
    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView)  {
        delegate?.canvasViewWillBeginDecelerating?(self)
    }
    /// called when scroll view grinds to a halt
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)  {
        delegate?.canvasViewDidEndDecelerating?(self)
    }
    
    /// called when setContentOffset/scrollRectVisible:animated: finishes. not called if not animating
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        delegate?.canvasViewDidEndScrollingAnimation?(self)
    }
    
    /// return a view that will be scaled. if delegate returns nil, nothing happens
    public func viewForZooming(in scrollView: UIScrollView) -> UIView?  {
        return _contentView
    }
    /// called before the scroll view begins zooming its content
    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        delegate?.canvasViewWillBeginZooming?(self, with: view)
    }
    /// scale between minimum and maximum. called after any 'bounce' animations
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        delegate?.canvasViewDidEndZooming?(self, with: view, atScale: scale)
    }
    
    /// return a yes if you want to scroll to the top. if not defined, assumes YES
    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return delegate?.canvasViewShouldScrollToTop?(self) ?? true
    }
    /// called when scrolling animation finished. may be called immediately if already at top
    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        delegate?.canvasViewDidScrollToTop?(self)
    }
}

internal class CanvasContainerView: UIScrollView {
}

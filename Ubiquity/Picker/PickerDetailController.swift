//
//  PickerDetailController.swift
//  Ubiquity
//
//  Created by sagesse on 30/08/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal class PickerDetailController: BrowserDetailController, SelectionItemUpdateDelegate, ContainerOptionsDelegate {

    override func loadView() {
        super.loadView()

        // if it is not picker, ignore
        guard let picker = container as? Picker else {
            return
        }

        // setup selection view
        _selectedView.addTarget(self, action: #selector(_select(_:)), for: .touchUpInside)
        _selectedView.isHidden = !picker.allowsSelection

        // setup right
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: _selectedView)
    }

    // MARK: Options change

    func ub_container(_ container: Container, options: String, didChange value: Any?) {
        // if it is not picker, ignore
        guard let picker = container as? Picker, options == "allowsSelection" else {
            return
        }
        _selectedView.isHidden = !picker.allowsSelection
    }

    // MARK: Item change

    override func detailController(_ detailController: Any, didShowItem indexPath: IndexPath) {
        super.detailController(detailController, didShowItem: indexPath)

        // fetch current displayed asset item
        guard let asset = displayedItem else {
            return
        }

        // update current asset selection status
//        _selectedView.update((container as? Picker)?.statusOfItem(with: asset), animated: true)
    }

    // MARK: Selection change


    func selectionItem(_ selectionItem: SelectionItem, didSelectItem asset: Asset, sender: AnyObject) {
        // ignore the events that itself sent
        // ignores events other than the currently displayed asset
        guard sender !== self, asset.ub_identifier == displayedItem?.ub_identifier else {
            return
        }
        logger.debug?.write()

        // update selection status
//        _selectedView.update(selectionItem, animated: false)
    }

    func selectionItem(_ selectionItem: SelectionItem, didDeselectItem asset: Asset, sender: AnyObject) {
        // ignore the events that itself sent
        // ignores events other than the currently displayed asset
        guard sender !== self, asset.ub_identifier == displayedItem?.ub_identifier else {
            return
        }
        logger.debug?.write()

        // clear selection status
//        _selectedView.update(nil, animated: false)
    }

    // MARK: Events

    // select or deselect item
    @objc private dynamic func _select(_ sender: Any) {
        // fetch current displayed asset item
        guard let asset = displayedItem else {
            return
        }

//        // check old status
//        if _selectedView.item == nil {
//            // select asset
//            _selectedView.update((container as? Picker)?.selectItem(with: asset, sender: self), animated: false)
//
//        } else {
//            // deselect asset
//            _selectedView.update((container as? Picker)?.deselectItem(with: asset, sender: self), animated: false)
//        }
//
//        // add animation
//        let ani = CAKeyframeAnimation(keyPath: "transform.scale")
//
//        ani.values = [0.8, 1.2, 1]
//        ani.duration = 0.25
//        ani.calculationMode = kCAAnimationCubic
//
//        _selectedView.layer.add(ani, forKey: "selected")
    }

    private lazy var _selectedView: SelectionItemView = .init(frame: .init(x: 0, y: 0, width: 24, height: 24))
}

//
//  UINavigationController +.swift
//  JUDA
//
//  Created by phang on 2/8/24.
//

import SwiftUI

// MARK: - 스와이프 뒤로가기 제스처
extension UINavigationController: UIGestureRecognizerDelegate {
    static var allowSwipeBack = true
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if UINavigationController.allowSwipeBack {
            return viewControllers.count > 1
        }
        return false
    }
}

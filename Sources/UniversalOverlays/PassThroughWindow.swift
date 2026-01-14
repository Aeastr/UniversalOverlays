//
//  PassThroughWindow.swift
//  UniversalOverlays
//
//  Created by Aether, 2025.
//
//  Copyright © 2025 Aether. All rights reserved.
//  Licensed under the MIT License.
//

#if canImport(UIKit)
import UIKit
import SwiftUI

/// A specialized UIWindow that allows touch events to pass through non-content areas.
///
/// This window is designed for overlay scenarios where you want certain areas of the window
/// to be transparent to touch events. When a touch occurs on the root view controller's
/// background (areas without actual content), the touch is passed through to underlying
/// windows or views, creating a "hole-punch" effect for user interactions.
///
/// This is particularly useful for:
/// - FPS counters and debug overlays
/// - Modal overlays that should only capture touches on specific content areas
/// - Floating UI elements that don't want to block touches on empty areas
/// - Any overlay that needs to sit above everything without blocking interaction
///
/// ## Usage
///
/// ```swift
/// let overlayWindow = PassThroughWindow(windowScene: windowScene)
/// overlayWindow.windowLevel = .statusBar + 1
/// overlayWindow.rootViewController = UIHostingController(rootView: YourOverlayView())
/// overlayWindow.rootViewController?.view.backgroundColor = .clear
/// overlayWindow.isHidden = false
/// ```
///
/// The window uses hit testing to determine whether touches should be handled or passed through.
public class PassThroughWindow: UIWindow {
    /// Performs hit testing to determine which view should receive touch events.
    ///
    /// This override implements the pass-through behavior by checking if the touch
    /// hit the root view controller's background. If so, it returns `nil` to pass
    /// the touch through to underlying windows.
    ///
    /// The method uses different strategies depending on iOS version:
    /// - Pre-iOS 18: Checks if touch hit only the root view background
    /// - iOS 18+: Iterates through subviews to find actual content
    /// - iOS 26+: Samples pixel alpha at touch point (hierarchy traversal unavailable)
    ///
    /// - Parameters:
    ///   - point: The touch point in the window's coordinate system
    ///   - event: The touch event containing additional context
    /// - Returns: The view that should handle the touch, or `nil` to pass through
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Perform standard hit testing first
        guard let hitView = super.hitTest(point, with: event),
              let rootView = rootViewController?.view else {
            return nil
        }

        // iOS 26+: Can't traverse view hierarchy, use pixel alpha instead
        if #available(iOS 26, *) {
            if hitView == rootView {
                if rootView.colorOfPoint(point).alpha < 0.01 {
                    return nil
                }
            }
            return hitView
        }

        // iOS 18+: Iterate through subviews to find actual content
        if #available(iOS 18, *) {
            for subview in rootView.subviews.reversed() {
                let pointInSubView = subview.convert(point, from: rootView)
                if subview.hitTest(pointInSubView, with: event) != nil {
                    return hitView
                }
            }
        }

        // Pre-iOS 18: Pass through if touch is only on root view background
        return hitView == rootView ? nil : hitView
    }
}

// MARK: - Pixel-Alpha Check Helpers

fileprivate extension UIView {
    func colorOfPoint(_ point: CGPoint) -> UIColor {
        guard bounds.contains(point) else {
            return .clear
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        var pixelData: [UInt8] = [0, 0, 0, 0]

        guard let context = CGContext(
            data: &pixelData,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return .clear
        }

        context.translateBy(x: -point.x, y: -point.y)
        layer.render(in: context)

        let red   = CGFloat(pixelData[0]) / 255.0
        let green = CGFloat(pixelData[1]) / 255.0
        let blue  = CGFloat(pixelData[2]) / 255.0
        let alpha = CGFloat(pixelData[3]) / 255.0

        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

fileprivate extension UIColor {
    var alpha: CGFloat {
        cgColor.alpha
    }
}
#endif

//
//  UniversalOverlay.swift
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

// MARK: - Configuration

/// Configuration options for universal overlays.
public struct OverlayConfiguration: Sendable {
    /// The window level for the overlay.
    public var level: UIWindow.Level

    /// Whether to ignore safe area insets. When `true`, content extends edge-to-edge.
    public var ignoresSafeArea: Bool

    /// The animation duration for showing/dismissing. Set to `0` for no animation.
    public var animationDuration: TimeInterval

    /// Auto-dismiss after this duration. Set to `nil` to disable.
    public var autoDismissAfter: TimeInterval?

    /// Creates a new overlay configuration.
    public init(
        level: UIWindow.Level = .statusBar + 1,
        ignoresSafeArea: Bool = false,
        animationDuration: TimeInterval = 0,
        autoDismissAfter: TimeInterval? = nil
    ) {
        self.level = level
        self.ignoresSafeArea = ignoresSafeArea
        self.animationDuration = animationDuration
        self.autoDismissAfter = autoDismissAfter
    }

    /// Default configuration.
    public static let `default` = OverlayConfiguration()

    /// Overlay above the status bar.
    public static let aboveStatusBar = OverlayConfiguration(level: .statusBar + 1)

    /// Overlay above alerts.
    public static let aboveAlerts = OverlayConfiguration(level: .alert + 1)

    /// Overlay at the highest possible level.
    public static var topmost: OverlayConfiguration {
        OverlayConfiguration(level: UIWindow.Level(rawValue: CGFloat.greatestFiniteMagnitude))
    }

    /// Debug overlay that auto-dismisses after 3 seconds.
    public static let debug = OverlayConfiguration(
        level: .statusBar + 1,
        animationDuration: 0.2,
        autoDismissAfter: 3.0
    )
}

// MARK: - UniversalOverlay

/// A convenience wrapper for creating and managing pass-through overlay windows.
///
/// Use `UniversalOverlay` to quickly display SwiftUI or UIKit content above your entire app
/// without blocking touches on empty areas.
///
/// ## SwiftUI
/// ```swift
/// let overlay = UniversalOverlay.show {
///     Text("60 FPS")
///         .padding(6)
///         .background(.black.opacity(0.7))
///         .foregroundStyle(.green)
/// }
///
/// // Later, to dismiss:
/// overlay?.dismiss()
/// ```
///
/// ## UIKit
/// ```swift
/// let overlay = UniversalOverlay.show(viewController: myOverlayVC)
/// ```
@MainActor
public final class UniversalOverlay {
    private var window: PassThroughWindow?
    private var dismissTask: Task<Void, Never>?
    private var configuration: OverlayConfiguration

    private init(configuration: OverlayConfiguration) {
        self.configuration = configuration
    }

    // MARK: - Show Methods

    /// Shows a SwiftUI view as a universal overlay.
    ///
    /// - Parameters:
    ///   - configuration: Configuration options for the overlay.
    ///   - windowScene: The specific window scene to use. If `nil`, uses the foreground active scene.
    ///   - content: A closure returning the SwiftUI view to display.
    /// - Returns: An `UniversalOverlay` instance to manage the overlay, or `nil` if no window scene is available.
    @discardableResult
    public static func show<Content: View>(
        configuration: OverlayConfiguration = .default,
        in windowScene: UIWindowScene? = nil,
        @ViewBuilder content: () -> Content
    ) -> UniversalOverlay? {
        guard let scene = windowScene ?? activeWindowScene else { return nil }

        let overlay = UniversalOverlay(configuration: configuration)
        let window = PassThroughWindow(windowScene: scene)
        window.windowLevel = configuration.level

        let contentView = content()
        let wrappedContent = OverlayHostingView(
            ignoresSafeArea: configuration.ignoresSafeArea,
            content: contentView
        )

        let hostingController = UIHostingController(rootView: wrappedContent)
        hostingController.view.backgroundColor = UIColor.clear
        window.rootViewController = hostingController
        window.backgroundColor = UIColor.clear

        overlay.window = window
        overlay.showWindow(animated: configuration.animationDuration > 0)
        overlay.scheduleAutoDismissIfNeeded()

        return overlay
    }

    /// Shows a SwiftUI view with a simple window level.
    ///
    /// - Parameters:
    ///   - level: The window level for the overlay.
    ///   - content: A closure returning the SwiftUI view to display.
    /// - Returns: An `UniversalOverlay` instance to manage the overlay, or `nil` if no window scene is available.
    @discardableResult
    public static func show<Content: View>(
        level: UIWindow.Level,
        @ViewBuilder content: () -> Content
    ) -> UniversalOverlay? {
        show(configuration: OverlayConfiguration(level: level), content: content)
    }

    /// Shows a UIViewController as a universal overlay.
    ///
    /// - Parameters:
    ///   - viewController: The view controller to display. Its view background should be clear.
    ///   - configuration: Configuration options for the overlay.
    ///   - windowScene: The specific window scene to use. If `nil`, uses the foreground active scene.
    /// - Returns: An `UniversalOverlay` instance to manage the overlay, or `nil` if no window scene is available.
    @discardableResult
    public static func show(
        viewController: UIViewController,
        configuration: OverlayConfiguration = .default,
        in windowScene: UIWindowScene? = nil
    ) -> UniversalOverlay? {
        guard let scene = windowScene ?? activeWindowScene else { return nil }

        let overlay = UniversalOverlay(configuration: configuration)
        let window = PassThroughWindow(windowScene: scene)
        window.windowLevel = configuration.level
        window.rootViewController = viewController
        window.backgroundColor = UIColor.clear

        overlay.window = window
        overlay.showWindow(animated: configuration.animationDuration > 0)
        overlay.scheduleAutoDismissIfNeeded()

        return overlay
    }

    // MARK: - Control Methods

    /// Dismisses the overlay.
    ///
    /// - Parameter animated: Whether to animate the dismissal. Uses configuration's animation duration.
    public func dismiss(animated: Bool = true) {
        dismissTask?.cancel()
        dismissTask = nil

        let shouldAnimate = animated && configuration.animationDuration > 0

        if shouldAnimate {
            UIView.animate(withDuration: configuration.animationDuration, animations: {
                self.window?.alpha = 0
            }, completion: { _ in
                self.window?.isHidden = true
                self.window = nil
            })
        } else {
            window?.isHidden = true
            window = nil
        }
    }

    /// Whether the overlay is currently visible.
    public var isVisible: Bool {
        window?.isHidden == false
    }

    /// The underlying window, for advanced customization.
    public var overlayWindow: PassThroughWindow? {
        window
    }

    /// Updates the SwiftUI content of the overlay.
    ///
    /// - Parameter content: The new SwiftUI view to display.
    public func update<Content: View>(@ViewBuilder content: () -> Content) {
        guard let window else { return }

        let contentView = content()
        let wrappedContent = OverlayHostingView(
            ignoresSafeArea: configuration.ignoresSafeArea,
            content: contentView
        )

        let hostingController = UIHostingController(rootView: wrappedContent)
        hostingController.view.backgroundColor = UIColor.clear
        window.rootViewController = hostingController
    }

    /// Updates the window level.
    public func setLevel(_ level: UIWindow.Level) {
        window?.windowLevel = level
    }

    /// Cancels any pending auto-dismiss.
    public func cancelAutoDismiss() {
        dismissTask?.cancel()
        dismissTask = nil
    }

    /// Schedules auto-dismiss after the specified duration.
    public func autoDismiss(after duration: TimeInterval) {
        dismissTask?.cancel()
        dismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if !Task.isCancelled {
                dismiss()
            }
        }
    }

    // MARK: - Private Helpers

    private static var activeWindowScene: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
    }

    private func showWindow(animated: Bool) {
        guard let window else { return }

        if animated {
            window.alpha = 0
            window.isHidden = false
            UIView.animate(withDuration: configuration.animationDuration) {
                window.alpha = 1
            }
        } else {
            window.isHidden = false
        }
    }

    private func scheduleAutoDismissIfNeeded() {
        if let duration = configuration.autoDismissAfter {
            autoDismiss(after: duration)
        }
    }
}

// MARK: - OverlayHostingView

private struct OverlayHostingView<Content: View>: View {
    let ignoresSafeArea: Bool
    let content: Content

    var body: some View {
        if ignoresSafeArea {
            content
                .ignoresSafeArea()
        } else {
            content
        }
    }
}
#endif

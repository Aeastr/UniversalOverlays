<div align="center">
  <h1><b>UniversalOverlays</b></h1>
  <p>
    A UIWindow subclass that allows touch events to pass through non-content areas.
  </p>
</div>

<p align="center">
  <a href="https://developer.apple.com/ios/"><img src="https://img.shields.io/badge/iOS-17%2B-purple.svg" alt="iOS 17+"></a>
  <a href="https://swift.org/"><img src="https://img.shields.io/badge/Swift-6.0-orange.svg" alt="Swift 6.0"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT"></a>
</p>

A lightweight UIWindow that creates "hole-punch" touch behavior - touches on empty areas pass through to underlying windows, while touches on actual content are handled normally.

## Use Cases

- FPS counters and debug overlays
- Floating UI elements (tooltips, indicators)
- Modal overlays that shouldn't block background touches
- Any always-on-top UI that needs to coexist with normal interaction

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/Aeastr/UniversalOverlays", from: "1.0.0")
]
```

```swift
import UniversalOverlays
```

## Usage

Touches on empty/transparent areas pass through to the app below. Touches on your overlay content (buttons, text, etc.) are handled normally.

### SwiftUI

```swift
import UniversalOverlays

// Show an overlay
let overlay = UniversalOverlay.show {
    VStack {
        HStack {
            Spacer()
            Text("60 FPS")
                .font(.caption.monospaced())
                .padding(6)
                .background(.black.opacity(0.7))
                .foregroundStyle(.green)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(8)
        }
        Spacer()
    }
}

// Later, dismiss it
overlay?.dismiss()
```

### UIKit

```swift
import UniversalOverlays

// Show with a view controller
let overlayVC = MyOverlayViewController()
overlayVC.view.backgroundColor = .clear

let overlay = UniversalOverlay.show(viewController: overlayVC)

// Later, dismiss it
overlay?.dismiss()
```

## Configuration

Use `OverlayConfiguration` for advanced customization:

```swift
let config = OverlayConfiguration(
    level: .statusBar + 1,        // Window level
    ignoresSafeArea: true,        // Extend edge-to-edge
    animationDuration: 0.25,      // Fade in/out duration
    autoDismissAfter: 5.0         // Auto-dismiss after 5 seconds
)

let overlay = UniversalOverlay.show(configuration: config) {
    MyOverlayView()
}
```

### Presets

```swift
// Above status bar (default)
UniversalOverlay.show(configuration: .aboveStatusBar) { ... }

// Above alerts
UniversalOverlay.show(configuration: .aboveAlerts) { ... }

// Highest possible level
UniversalOverlay.show(configuration: .topmost) { ... }

// Debug preset: fades in, auto-dismisses after 3s
UniversalOverlay.show(configuration: .debug) { ... }
```

### Runtime Control

```swift
let overlay = UniversalOverlay.show { MyView() }

// Update content
overlay?.update { UpdatedView() }

// Change window level
overlay?.setLevel(.alert + 1)

// Schedule auto-dismiss
overlay?.autoDismiss(after: 10.0)

// Cancel pending auto-dismiss
overlay?.cancelAutoDismiss()

// Animated dismiss
overlay?.dismiss(animated: true)

// Access underlying window for advanced customization
overlay?.overlayWindow?.windowLevel = .normal
```

### Specific Window Scene

```swift
// Show in a specific window scene
UniversalOverlay.show(in: myWindowScene) {
    MyOverlayView()
}
```

### Configuration Options

| Option | Type | Default | Description |
|:-------|:-----|:--------|:------------|
| `level` | `UIWindow.Level` | `.statusBar + 1` | Window z-order |
| `ignoresSafeArea` | `Bool` | `false` | Extend content edge-to-edge |
| `animationDuration` | `TimeInterval` | `0` | Fade animation duration |
| `autoDismissAfter` | `TimeInterval?` | `nil` | Auto-dismiss delay |

### Manual Setup

For full control, use `PassThroughWindow` directly:

```swift
guard let scene = UIApplication.shared.connectedScenes
    .compactMap({ $0 as? UIWindowScene }).first else { return }

let window = PassThroughWindow(windowScene: scene)
window.windowLevel = .statusBar + 1
window.rootViewController = UIHostingController(rootView: MyOverlay())
window.rootViewController?.view.backgroundColor = .clear
window.isHidden = false
```

## How It Works

`PassThroughWindow` overrides `hitTest(_:with:)` to check whether a touch lands on actual content or just the background. If the touch only hits the root view's background, it returns `nil`, passing the touch through to underlying windows.

On iOS 18+, additional logic iterates through subviews to better detect content boundaries.

## License

MIT

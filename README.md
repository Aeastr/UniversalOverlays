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
import SwiftUI
import UniversalOverlays

@main
struct MyApp: App {
    @State private var overlayWindow: PassThroughWindow?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    setupOverlay()
                }
        }
    }

    private func setupOverlay() {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }

        let overlay = PassThroughWindow(windowScene: windowScene)
        overlay.windowLevel = .statusBar + 1
        overlay.rootViewController = UIHostingController(rootView: FPSOverlay())
        overlay.rootViewController?.view.backgroundColor = .clear
        overlay.isHidden = false

        overlayWindow = overlay
    }
}

struct FPSOverlay: View {
    @State private var fps: Int = 60

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("\(fps) FPS")
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
}
```

### UIKit

```swift
import UIKit
import UniversalOverlays

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var overlayWindow: PassThroughWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // Main app window
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = MainViewController()
        window?.makeKeyAndVisible()

        // Overlay window
        let overlay = PassThroughWindow(windowScene: windowScene)
        overlay.windowLevel = .statusBar + 1
        overlay.rootViewController = OverlayViewController()
        overlay.rootViewController?.view.backgroundColor = .clear
        overlay.isHidden = false

        overlayWindow = overlay
    }
}

class OverlayViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let label = UILabel()
        label.text = "60 FPS"
        label.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        label.textColor = .green
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            label.widthAnchor.constraint(equalToConstant: 60),
            label.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
}
```

## How It Works

`PassThroughWindow` overrides `hitTest(_:with:)` to check whether a touch lands on actual content or just the background. If the touch only hits the root view's background, it returns `nil`, passing the touch through to underlying windows.

On iOS 18+, additional logic iterates through subviews to better detect content boundaries.

## License

MIT

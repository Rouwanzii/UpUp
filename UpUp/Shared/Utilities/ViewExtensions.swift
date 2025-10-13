import SwiftUI
import UIKit

// MARK: - Keyboard Dismissal Helper

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            hideKeyboard()
        }
    }

    /// Dismisses keyboard when tapping on background without interfering with buttons
    func dismissKeyboardInteractively() -> some View {
        self.background(
            TapToDismissKeyboard()
        )
    }
}

// MARK: - Tap to Dismiss Keyboard View

struct TapToDismissKeyboard: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.dismissKeyboard))
        tapGesture.cancelsTouchesInView = false // This is the key - allows buttons to still work
        view.addGestureRecognizer(tapGesture)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        @objc func dismissKeyboard() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

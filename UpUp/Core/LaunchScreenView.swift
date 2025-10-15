import SwiftUI

struct LaunchScreenView: View {
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0.0
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1, green: 0.99, blue: 0.98),
                    Color(red: 0.98, green: 0.97, blue: 1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // App Icon
                Image("LaunchIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .cornerRadius(24)
                    //.shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    .scaleEffect(scale)
                    .opacity(opacity)

            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                scale = 1.0
                opacity = 1.0
            }

            // Subtle bounce animation
            withAnimation(
                .spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0)
                .delay(0.5)
            ) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}

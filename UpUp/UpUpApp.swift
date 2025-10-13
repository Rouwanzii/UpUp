import SwiftUI

@main
struct UpUpApp: App {
    let persistenceController = PersistenceController.shared
    @State private var showLaunchScreen = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)

                if showLaunchScreen {
                    LaunchScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showLaunchScreen = false
                    }
                }
            }
        }
    }
}
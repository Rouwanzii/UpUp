import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            LogView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Log")
                }
        }
        .accentColor(.green)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
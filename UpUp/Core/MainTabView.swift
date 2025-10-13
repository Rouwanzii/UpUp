import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeTabView()
                .tabItem {
                    Label("tab.home".localized, systemImage: "house.fill")
                }
                .tag(0)

            // Logbook Tab
            LogbookTabView()
                .tabItem {
                    Label("tab.logbook".localized, systemImage: "book.fill")
                }
                .tag(1)

            // Insights Tab
            InsightsTabView()
                .tabItem {
                    Label("tab.insights".localized, systemImage: "chart.bar.fill")
                }
                .tag(2)
        }
        .accentColor(.blue)
        .id(localizationManager.currentLanguage)
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

import SwiftUI
import CoreData

struct StatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClimbingSession.date, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<ClimbingSession>

    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                        QuickStatCard(value: "\(sessions.count)", title: "Total Sessions")
                        QuickStatCard(value: String(format: "%.1f", totalHours), title: "Total Hours")
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    var totalHours: Double {
                        sessions.reduce(0) { total, session in
                            total + Double(session.duration) / 60.0
                        }
                    }
                // Tab picker for different views
                Picker("Stats View", selection: $selectedTab) {
                    Text("Weekly").tag(0)
                    Text("Monthly").tag(1)
                    Text("Half-Year").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                

                // Content based on selected tab
                ScrollView {
                    switch selectedTab {
                    case 0:
                        WeeklyStatsView(sessions: Array(sessions))
                    case 1:
                        MonthlyCalendarView(sessions: Array(sessions))
                    case 2:
                        HalfYearlyHeatmapView(sessions: Array(sessions))
                    default:
                        WeeklyStatsView(sessions: Array(sessions))
                    }
                }
            }
            .navigationTitle("Statistics")
            .padding(.horizontal)
            
        }
    }
}
 
struct WeeklyStatsView: View {
    let sessions: [ClimbingSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Statistics")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.leading)

            WeeklyBarChart(sessions: sessions)
                .padding(.horizontal)
        }
        
    }
}
    

struct MonthlyCalendarView: View {
    let sessions: [ClimbingSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Calendar")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            MonthlyCalendar(sessions: sessions)
                .padding(.horizontal)
        }
    }
}

struct HalfYearlyHeatmapView: View {
    let sessions: [ClimbingSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("6-Month Activity Heatmap")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            SixMonthHeatmap(sessions: sessions)
                .padding(.horizontal)
            
        }
    }
}


#Preview {
    StatsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

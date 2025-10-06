import SwiftUI
import CoreData

struct HomeTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClimbingSession.date, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<ClimbingSession>

    @State private var currentQuote = ""
    @State private var showingTodayQuickLog = false
    @State private var showingSettings = false

    let motivationalQuotes = [
        "Every mountain top is within reach if you just keep climbing.",
        "The best climber is the one having the most fun.",
        "Don't limit your challenges, challenge your limits.",
        "Climb mountains not so the world can see you, but so you can see the world.",
        "Even a bad day of climbing is better than a good day at work."
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Motivational Quote
                    VStack {
                        Text(currentQuote)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                    // Today's Training Status
                    TodayTrainingCard(
                        hasLoggedToday: hasLoggedToday,
                        onQuickLog: { showingTodayQuickLog = true }
                    )
                    .padding(.horizontal, 20)

                    // Quick Stats Summary
                    QuickStatsSummary(
                        totalSessions: totalSessions,
                        bestBoulderingGrade: bestBoulderingGrade,
                        bestSportGrade: bestSportGrade
                    )
                    .padding(.horizontal, 20)

                    // Recent Activity Preview
                    RecentActivityPreview(sessions: Array(sessions.prefix(3)))
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                if currentQuote.isEmpty {
                    currentQuote = motivationalQuotes.randomElement() ?? motivationalQuotes[0]
                }
            }
            .sheet(isPresented: $showingTodayQuickLog) {
                SessionLogSheet(
                    mode: .quickLog(Date()),
                    themeColor: DesignTokens.Colors.homeAccent,
                    showDatePicker: false,
                    moods: ["😊", "💪", "🔥", "😤", "⚡", "🥵", "😎", "🎯"]
                )
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - Computed Properties

    private var hasLoggedToday: Bool {
        let calendar = Calendar.current
        let today = Date()

        return sessions.contains { session in
            guard let sessionDate = session.date else { return false }
            return calendar.isDate(sessionDate, inSameDayAs: today)
        }
    }

    private var totalSessions: Int {
        return sessions.count
    }

    private var bestBoulderingGrade: String {
        let allBoulderingRoutes = sessions.flatMap { $0.routes }
            .filter { route in
                guard let difficulty = route.difficulty else { return false }
                return difficulty.climbingType == .bouldering &&
                       (route.result == .onsight || route.result == .flash || route.result == .send)
            }
            .compactMap { $0.difficulty }

        guard !allBoulderingRoutes.isEmpty else { return "-" }

        let maxGrade = allBoulderingRoutes.max(by: { a, b in
            let indexA = RouteDifficulty.boulderingGrades.firstIndex(of: a) ?? 0
            let indexB = RouteDifficulty.boulderingGrades.firstIndex(of: b) ?? 0
            return indexA < indexB
        })

        return maxGrade?.rawValue ?? "-"
    }

    private var bestSportGrade: String {
        let allSportRoutes = sessions.flatMap { $0.routes }
            .filter { route in
                guard let difficulty = route.difficulty else { return false }
                return difficulty.climbingType == .sport &&
                       (route.result == .onsight || route.result == .flash || route.result == .send)
            }
            .compactMap { $0.difficulty }

        guard !allSportRoutes.isEmpty else { return "-" }

        let maxGrade = allSportRoutes.max(by: { a, b in
            let indexA = RouteDifficulty.sportGrades.firstIndex(of: a) ?? 0
            let indexB = RouteDifficulty.sportGrades.firstIndex(of: b) ?? 0
            return indexA < indexB
        })

        return maxGrade?.rawValue ?? "-"
    }
}

// MARK: - Supporting Views

struct QuickStatsSummary: View {
    let totalSessions: Int
    let bestBoulderingGrade: String
    let bestSportGrade: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Stats")
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 12) {
                StatSummaryCard(
                    value: "\(totalSessions)",
                    label: "Sessions",
                    color: .blue
                )
                StatSummaryCard(
                    value: bestBoulderingGrade,
                    label: "Best Boulder",
                    color: .orange
                )
                StatSummaryCard(
                    value: bestSportGrade,
                    label: "Best Sport",
                    color: .green
                )
            }
        }
    }
}

// StatSummaryCard is now in Shared/Components/StatCards.swift

struct RecentActivityPreview: View {
    let sessions: [ClimbingSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                NavigationLink(destination: MonthlyCalendarPageView()) {
                    Text("Calendar")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }

            if sessions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "figure.climbing")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No sessions yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Start logging your climbing sessions!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(sessions, id: \.id) { session in
                        RecentActivityRow(session: session)
                    }
                }
            }
        }
    }
}

struct RecentActivityRow: View {
    let session: ClimbingSession

    var body: some View {
        NavigationLink(destination: SessionDetailView(session: session)) {
            HStack(spacing: 12) {
                Text(session.mood ?? "😊")
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.date?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text("\(session.duration) min • \(session.routes.count) route\(session.routes.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("App Info")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("About")) {
                    Text("UpUp - Your climbing training companion")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    HomeTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

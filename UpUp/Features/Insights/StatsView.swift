import SwiftUI
import CoreData

struct StatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClimbingSession.date, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<ClimbingSession>

    @State private var selectedTab = 0
    @State private var selectedDate: Date = Date()
    @State private var showingQuickLog = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab picker for different views
                Picker("Stats View", selection: $selectedTab) {
                    Text("Weekly").tag(0)
                    Text("Monthly").tag(1)
                    Text("Yearly").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)
                .padding(.vertical)


                // Content based on selected tab
                ScrollView {
                    switch selectedTab {
                    case 0:
                        UnifiedWeeklyStatsView(sessions: Array(sessions), selectedDate: $selectedDate, showingQuickLog: $showingQuickLog)
                    case 1:
                        UnifiedMonthlyStatsView(sessions: Array(sessions), selectedDate: $selectedDate, showingQuickLog: $showingQuickLog)
                    case 2:
                        UnifiedYearlyStatsView(sessions: Array(sessions), selectedDate: $selectedDate)
                    default:
                        UnifiedWeeklyStatsView(sessions: Array(sessions), selectedDate: $selectedDate, showingQuickLog: $showingQuickLog)
                    }
                }
            }
            .navigationTitle("Statistics")
            .sheet(isPresented: $showingQuickLog) {
                QuickLogView(selectedDate: selectedDate)
            }
        }
    }
}


struct WeeklyStatsView: View {
    let sessions: [ClimbingSession]
    @Binding var selectedDate: Date
    @Binding var showingQuickLog: Bool
    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            /*Text("Weekly Statistics")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal, 20)*/

            WeeklyBarChart(sessions: sessions, selectedDate: $selectedDate)
                .padding(.horizontal, 20)

            // Selected Date Session Display
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Sessions on \(selectedDateFormatted)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    if sessionsForSelectedDate.isEmpty {
                        Button("Quick Log") {
                            showingQuickLog = true
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange)
                        .cornerRadius(8)
                    }
                }

                if sessionsForSelectedDate.isEmpty {
                    if selectedDate > Date() {
                        Text("We are young, we still have tomorrow.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                            .padding(.vertical, 8)
                    } else {
                        Text("No sessions recorded for this day")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    }
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(sessionsForSelectedDate, id: \.id) { session in
                            SessionRowForDate(session: session)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            .padding(.horizontal, 20)
        }
    }

    private var selectedDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }

    private var sessionsForSelectedDate: [ClimbingSession] {
        return sessions.filter { session in
            guard let sessionDate = session.date else { return false }
            return calendar.isDate(sessionDate, inSameDayAs: selectedDate)
        }
    }
}
    

struct MonthlyCalendarView: View {
    let sessions: [ClimbingSession]
    @Binding var selectedDate: Date
    @Binding var showingQuickLog: Bool
    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            MonthlyCalendar(sessions: sessions, selectedDate: $selectedDate)

            // Selected Date Session Display
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Sessions on \(selectedDateFormatted)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    if sessionsForSelectedDate.isEmpty {
                        Button("Quick Log") {
                            showingQuickLog = true
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange)
                        .cornerRadius(8)
                    }
                }

                if sessionsForSelectedDate.isEmpty {
                    if selectedDate > Date() {
                        Text("We are young, we still have tomorrow.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                            .padding(.vertical, 8)
                    } else {
                        Text("No sessions recorded for this day")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    }
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(sessionsForSelectedDate, id: \.id) { session in
                            SessionRowForDate(session: session)
                        }
                    }
                }
            }
            .padding(.all, 16)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }

    private var selectedDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }

    private var sessionsForSelectedDate: [ClimbingSession] {
        return sessions.filter { session in
            guard let sessionDate = session.date else { return false }
            return calendar.isDate(sessionDate, inSameDayAs: selectedDate)
        }
    }
}

struct HalfYearlyHeatmapView: View {
    let sessions: [ClimbingSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            MonthlyChart(sessions: sessions)
                .padding(.bottom)

            VStack(alignment: .leading, spacing: 12) {
                Text("6-Month Activity Heatmap")
                    .font(.headline)
                    .fontWeight(.semibold)
                SixMonthHeatmap(sessions: sessions)
            }
            .padding(.all, 16)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
}


struct SessionRowForDate: View {
    @ObservedObject var session: ClimbingSession

    var body: some View {
        NavigationLink(destination: SessionDetailView(session: session)) {
            HStack(spacing: 12) {
                Text(session.mood ?? "😊")
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.duration.toHours.formatAsHoursLong())
                            .font(.headline)
                            .fontWeight(.medium)

                    if let notes = session.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(10)
                    }

                    // Routes summary
                    if !session.routes.isEmpty {
                        HStack {
                            Text("Routes: ")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(routesSummary(session.routes))
                                .font(.caption)
                                .foregroundColor(.blue)
                            Spacer()
                        }
                    }
                }
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        //.shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    private func routesSummary(_ routes: [ClimbingRoute]) -> String {
        let routesWithDifficulty = routes.compactMap { $0.difficulty?.displayName }
        if routesWithDifficulty.isEmpty {
            return "\(routes.count) route\(routes.count == 1 ? "" : "s")"
        } else {
            return routesWithDifficulty.prefix(3).joined(separator: ", ") + (routesWithDifficulty.count > 3 ? "..." : "")
        }
    }
}

struct QuickLogView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let selectedDate: Date
    @State private var sessionData: SessionData

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClimbingSession.date, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<ClimbingSession>

    let moods = ["😊", "💪", "🔥", "😤", "⚡", "🥵", "😎", "🎯"]

    init(selectedDate: Date) {
        self.selectedDate = selectedDate
        self._sessionData = State(initialValue: SessionData(date: selectedDate, mood: "💪"))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SessionLogForm(
                    selectedDate: $sessionData.selectedDate,
                    durationHours: $sessionData.durationHours,
                    selectedMood: $sessionData.selectedMood,
                    notes: $sessionData.notes,
                    routes: $sessionData.routes,
                    selectedEnvironment: $sessionData.selectedEnvironment,
                    locationText: $sessionData.locationText,
                    themeColor: .orange,
                    moods: moods,
                    showDatePicker: false
                )

                // Save Button
                Button(action: saveSession) {
                    Text("Save Session")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Quick Log for \(selectedDateFormatted)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadDefaults()
            }
        }
    }

    private var selectedDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }

    private func loadDefaults() {
        if let lastSession = sessions.first {
            if let lastEnvironment = lastSession.environment {
                sessionData.selectedEnvironment = lastEnvironment
                sessionData.locationText = lastSession.location ?? ""
            }
        }
    }

    private func saveSession() {
        let newSession = ClimbingSession(context: viewContext)
        newSession.id = UUID()
        sessionData.save(to: newSession)

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving session: \(error)")
        }
    }
}

struct MonthlyChart: View {
    let sessions: [ClimbingSession]
    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 16) {
            /*
            // Hours Chart
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .bottom, spacing: 10) {
                        ForEach(monthlyData, id: \.month) { data in
                            VStack(spacing: 4) {
                                Rectangle()
                                    .fill(data.hours > 0 ? Color.green.opacity(0.7) : Color.gray.opacity(0.3))
                                    .frame(width: 30, height: CGFloat(max(10, data.hours * 5)))
                                    .cornerRadius(2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color.blue, lineWidth: Calendar.current.component(.month, from: Date()) == data.month ? 2 : 0)
                                    )
                                    .padding(.top)

                                Text(String(format: "%.1f", data.hours))
                                    .font(.caption2)
                                    .foregroundColor(Calendar.current.component(.month, from: Date()) == data.month ? .blue : .secondary)

                                Text(data.monthLabel)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .frame(width: 30)
                                    .foregroundColor(Calendar.current.component(.month, from: Date()) == data.month ? .blue : .primary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)

                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.green.opacity(0.7))
                            .frame(width: 12, height: 12)
                            .cornerRadius(2)
                        Text("Hours")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
            */
            // Sessions Chart
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .bottom, spacing: 10) {
                        ForEach(monthlyData, id: \.month) { data in
                            VStack(spacing: 4) {
                                Rectangle()
                                    .fill(data.sessions > 0 ? Color.blue.opacity(0.7): Color.gray.opacity(0.3))
                                    .frame(width: 30, height: CGFloat(max(10, data.sessions * 10)))
                                    .cornerRadius(2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color.blue, lineWidth: Calendar.current.component(.month, from: Date()) == data.month ? 2 : 0)
                                    )
                                    .padding(.top)

                                Text(String(format: "%.0f", Double(data.sessions)))
                                    .font(.caption2)
                                    .foregroundColor(Calendar.current.component(.month, from: Date()) == data.month ? .blue : .secondary)

                                Text(data.monthLabel)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .frame(width: 30)
                                    .foregroundColor(Calendar.current.component(.month, from: Date()) == data.month ? .blue : .primary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)

                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.blue.opacity(0.7))
                            .frame(width: 12, height: 12)
                            .cornerRadius(2)
                        Text("Sessions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
        }
        
    }

    private var monthlyData: [(month: Int, sessions: Int, hours: Double, monthLabel: String)] {
        let currentYear = calendar.component(.year, from: Date())
        var data: [(Int, Int, Double, String)] = []

        for month in 1...12 {
            let sessionsInMonth = sessions.filter { session in
                guard let sessionDate = session.date else { return false }
                let sessionYear = calendar.component(.year, from: sessionDate)
                let sessionMonth = calendar.component(.month, from: sessionDate)
                return sessionYear == currentYear && sessionMonth == month
            }

            let sessionCount = sessionsInMonth.count
            let totalHours = sessionsInMonth.reduce(0.0) { total, session in
                total + Double(session.duration) / 60.0
            }

            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "MMM"
            let monthDate = calendar.date(from: DateComponents(year: currentYear, month: month, day: 1)) ?? Date()
            let monthLabel = monthFormatter.string(from: monthDate)

            data.append((month, sessionCount, totalHours, monthLabel))
        }

        return data
    }
}

#Preview {
    StatsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

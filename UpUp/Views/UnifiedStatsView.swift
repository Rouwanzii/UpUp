import SwiftUI
import CoreData

// MARK: - Unified Weekly Stats View

struct UnifiedWeeklyStatsView: View {
    let sessions: [ClimbingSession]
    @Binding var selectedDate: Date
    @Binding var showingQuickLog: Bool
    private let calendar = Calendar.current

    private var weekSessions: [ClimbingSession] {
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? selectedDate

        return sessions.filter { session in
            guard let date = session.date else { return false }
            return date >= startOfWeek && date < endOfWeek
        }
    }

    private var totalDuration: Double {
        weekSessions.reduce(0.0) { $0 + Double($1.duration) / 60.0 }
    }

    private var totalCompletedRoutes: Int {
        let allRoutes = weekSessions.flatMap { $0.routes }
        let completedRoutes = allRoutes.filter { route in
            route.result == .onsight || route.result == .flash || route.result == .send
        }
        return completedRoutes.count
    }

    private var highestGrade: String {
        let allRoutes = weekSessions.flatMap { $0.routes }
        let completedRoutes = allRoutes.filter { route in
            route.result == .onsight || route.result == .flash || route.result == .send
        }
        let completed = completedRoutes.compactMap { $0.difficulty }

        guard !completed.isEmpty else { return "-" }

        let allGrades = RouteDifficulty.boulderingGrades + RouteDifficulty.sportGrades
        if let max = completed.max(by: { a, b in
            let indexA = allGrades.firstIndex(of: a) ?? 0
            let indexB = allGrades.firstIndex(of: b) ?? 0
            return indexA < indexB
        }) {
            return max.rawValue
        }
        return "-"
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

    var body: some View {
        VStack(spacing: 20) {
            // OVERVIEW SECTION
            SectionContainer(title: "Weekly Overview") {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        StatCard(value: "\(weekSessions.count)", label: "Sessions", color: .blue)
                        StatCard(value: String(format: "%.1f h", totalDuration), label: "Duration", color: .green)
                        StatCard(value: "\(totalCompletedRoutes)", label: "Completed", color: .orange)
                    }

                    Divider()
                        .padding(.vertical, 4)

                    HStack {
                        Text("Highest Grade")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(highestGrade)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
            }

            /*
            // INTERACTIVE CALENDAR
            SectionContainer(title: "Daily Sessions") {
                
                VStack(spacing: 16) {
                    WeeklyBarChart(sessions: sessions, selectedDate: $selectedDate)
                        .frame(height: 180)

                    Divider()

                    // Selected Date Details
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(selectedDateFormatted)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            if sessionsForSelectedDate.isEmpty {
                                Button("Quick Log") {
                                    showingQuickLog = true
                                }
                                .font(.caption)
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
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .italic()
                                    .padding(.top, 4)
                            } else {
                                Text("No sessions recorded")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                        } else {
                            VStack(spacing: 8) {
                                ForEach(sessionsForSelectedDate, id: \.id) { session in
                                    SessionRowForDate(session: session)
                                }
                            }
                        }
                    }
                }
            }
                 */

            // PERFORMANCE SECTION
            SectionContainer(title: "Performance") {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Routes Per Day")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        WeeklyRoutesChart(sessions: weekSessions, selectedDate: selectedDate)
                            .frame(height: 160)
                            .padding(.top, 4)
                    }

                    if !weekSessions.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Mood Trend")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack(spacing: 8) {
                                ForEach(sortedWeekSessions(), id: \.id) { session in
                                    VStack(spacing: 4) {
                                        Text(session.mood ?? "😊")
                                            .font(.title3)
                                        Text(dayOfWeek(session.date))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }

            // TRAINING CALENDAR
            SectionContainer(title: "Training Days") {
                WeeklyCalendarGrid(sessions: weekSessions, selectedDate: selectedDate)
            }
        }
    }

    private func sortedWeekSessions() -> [ClimbingSession] {
        weekSessions.sorted { ($0.date ?? Date()) < ($1.date ?? Date()) }
    }

    private func dayOfWeek(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Unified Monthly Stats View

struct UnifiedMonthlyStatsView: View {
    let sessions: [ClimbingSession]
    @Binding var selectedDate: Date
    @Binding var showingQuickLog: Bool
    private let calendar = Calendar.current

    private var monthSessions: [ClimbingSession] {
        let components = calendar.dateComponents([.year, .month], from: selectedDate)
        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return []
        }

        return sessions.filter { session in
            guard let date = session.date else { return false }
            return date >= startOfMonth && date <= endOfMonth
        }
    }

    private var totalDuration: Double {
        monthSessions.reduce(0.0) { $0 + Double($1.duration) / 60.0 }
    }

    private var totalCompletedRoutes: Int {
        let allRoutes = monthSessions.flatMap { $0.routes }
        let completedRoutes = allRoutes.filter { route in
            route.result == .onsight || route.result == .flash || route.result == .send
        }
        return completedRoutes.count
    }

    private var indoorOutdoorRatio: (indoor: Int, outdoor: Int) {
        let indoor = monthSessions.filter { $0.environment == .indoor }.count
        let outdoor = monthSessions.filter { $0.environment == .outdoor }.count
        return (indoor, outdoor)
    }

    private var topLocations: [(String, Int)] {
        var locationCounts: [String: Int] = [:]
        for session in monthSessions {
            if let location = session.location, !location.isEmpty {
                locationCounts[location, default: 0] += 1
            }
        }
        return locationCounts.sorted { $0.value > $1.value }.prefix(3).map { ($0.key, $0.value) }
    }

    var body: some View {
        VStack(spacing: 20) {
            // OVERVIEW SECTION
            SectionContainer(title: "Monthly Overview") {
                HStack(spacing: 12) {
                    StatCard(value: "\(monthSessions.count)", label: "Sessions", color: .blue)
                    StatCard(value: String(format: "%.1f h", totalDuration), label: "Duration", color: .green)
                    StatCard(value: "\(totalCompletedRoutes)", label: "Completed", color: .orange)
                }
            }
/*
            // CALENDAR VIEW
            SectionContainer(title: "Calendar") {
                MonthlyCalendarView(sessions: sessions, selectedDate: $selectedDate, showingQuickLog: $showingQuickLog)
            }
*/
            // PROGRESS SECTION
            SectionContainer(title: "Progress") {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Grade Progression")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        MonthlyGradeProgressionChart(sessions: monthSessions)
                            .frame(height: 160)
                            .padding(.top, 4)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Completed Routes Per Week")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        MonthlyWeeklyRoutesChart(sessions: monthSessions, selectedDate: selectedDate)
                            .frame(height: 160)
                            .padding(.top, 4)
                    }
                }
            }

            // LOCATIONS SECTION
            if !topLocations.isEmpty || (indoorOutdoorRatio.indoor > 0 || indoorOutdoorRatio.outdoor > 0) {
                SectionContainer(title: "Locations") {
                    VStack(spacing: 16) {
                        if indoorOutdoorRatio.indoor > 0 || indoorOutdoorRatio.outdoor > 0 {
                            HStack(spacing: 20) {
                                IndoorOutdoorPieChart(indoor: indoorOutdoorRatio.indoor, outdoor: indoorOutdoorRatio.outdoor)
                                    .frame(width: 100, height: 100)

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Circle().fill(Color.blue).frame(width: 10, height: 10)
                                        Text("Indoor")
                                            .font(.subheadline)
                                        Spacer()
                                        Text("\(indoorOutdoorRatio.indoor)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                    HStack(spacing: 8) {
                                        Circle().fill(Color.green).frame(width: 10, height: 10)
                                        Text("Outdoor")
                                            .font(.subheadline)
                                        Spacer()
                                        Text("\(indoorOutdoorRatio.outdoor)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }

                            if !topLocations.isEmpty {
                                Divider()
                                    .padding(.vertical, 4)
                            }
                        }

                        if !topLocations.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Top Locations")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                ForEach(Array(topLocations.enumerated()), id: \.offset) { index, location in
                                    HStack {
                                        Text("\(index + 1)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .frame(width: 20, height: 20)
                                            .background(Circle().fill(Color.blue))

                                        Text(location.0)
                                            .font(.body)

                                        Spacer()

                                        Text("\(location.1)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Unified Yearly Stats View

struct UnifiedYearlyStatsView: View {
    let sessions: [ClimbingSession]
    @Binding var selectedDate: Date
    private let calendar = Calendar.current

    private var yearSessions: [ClimbingSession] {
        let year = calendar.component(.year, from: selectedDate)
        return sessions.filter { session in
            guard let date = session.date else { return false }
            return calendar.component(.year, from: date) == year
        }
    }

    private var totalDuration: Double {
        yearSessions.reduce(0.0) { $0 + Double($1.duration) / 60.0 }
    }

    private var totalCompletedRoutes: Int {
        let allRoutes = yearSessions.flatMap { $0.routes }
        let completedRoutes = allRoutes.filter { route in
            route.result == .onsight || route.result == .flash || route.result == .send
        }
        return completedRoutes.count
    }

    private var completionBreakdown: (onsight: Int, flash: Int, send: Int, fail: Int) {
        var onsight = 0, flash = 0, send = 0, fail = 0

        for session in yearSessions {
            for route in session.routes {
                switch route.result {
                case .onsight: onsight += 1
                case .flash: flash += 1
                case .send: send += 1
                case .fail: fail += 1
                case .none: break
                }
            }
        }

        return (onsight, flash, send, fail)
    }

    private var indoorOutdoorRatio: (indoor: Int, outdoor: Int) {
        let indoor = yearSessions.filter { $0.environment == .indoor }.count
        let outdoor = yearSessions.filter { $0.environment == .outdoor }.count
        return (indoor, outdoor)
    }

    private var topLocations: [(String, Int)] {
        var locationCounts: [String: Int] = [:]
        for session in yearSessions {
            if let location = session.location, !location.isEmpty {
                locationCounts[location, default: 0] += 1
            }
        }
        return locationCounts.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
    }

    var body: some View {
        VStack(spacing: 20) {
            // OVERVIEW SECTION
            SectionContainer(title: "Yearly Overview") {
                HStack(spacing: 12) {
                    StatCard(value: "\(yearSessions.count)", label: "Sessions", color: .blue)
                    StatCard(value: String(format: "%.0f h", totalDuration), label: "Duration", color: .green)
                    StatCard(value: "\(totalCompletedRoutes)", label: "Completed", color: .orange)
                }
            }

            // HEATMAP
            SectionContainer(title: "Activity Heatmap") {
                HalfYearlyHeatmapView(sessions: sessions)
            }

            // PROGRESS SECTION
            SectionContainer(title: "Progress") {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Grade Progression by Month")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        YearlyGradeProgressionChart(sessions: yearSessions)
                            .frame(height: 160)
                            .padding(.top, 4)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Grade Distribution")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        YearlyGradeDistributionChart(sessions: yearSessions)
                            .frame(height: 160)
                            .padding(.top, 4)
                    }
                }
            }

            // PERFORMANCE SECTION
            SectionContainer(title: "Performance") {
                VStack(spacing: 12) {
                    Text("Completion Style")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    let breakdown = completionBreakdown
                    HStack(spacing: 12) {
                        CompletionStyleCard(count: breakdown.onsight, label: "Onsight", color: .green)
                        CompletionStyleCard(count: breakdown.flash, label: "Flash", color: .blue)
                        CompletionStyleCard(count: breakdown.send, label: "Send", color: .orange)
                        CompletionStyleCard(count: breakdown.fail, label: "Fail", color: .red)
                    }
                }
            }

            // LOCATIONS SECTION
            if !topLocations.isEmpty || (indoorOutdoorRatio.indoor > 0 || indoorOutdoorRatio.outdoor > 0) {
                SectionContainer(title: "Locations") {
                    VStack(spacing: 16) {
                        if indoorOutdoorRatio.indoor > 0 || indoorOutdoorRatio.outdoor > 0 {
                            HStack(spacing: 20) {
                                IndoorOutdoorPieChart(indoor: indoorOutdoorRatio.indoor, outdoor: indoorOutdoorRatio.outdoor)
                                    .frame(width: 100, height: 100)

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Circle().fill(Color.blue).frame(width: 10, height: 10)
                                        Text("Indoor")
                                            .font(.subheadline)
                                        Spacer()
                                        Text("\(indoorOutdoorRatio.indoor)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                    HStack(spacing: 8) {
                                        Circle().fill(Color.green).frame(width: 10, height: 10)
                                        Text("Outdoor")
                                            .font(.subheadline)
                                        Spacer()
                                        Text("\(indoorOutdoorRatio.outdoor)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }

                            if !topLocations.isEmpty {
                                Divider()
                                    .padding(.vertical, 4)
                            }
                        }

                        if !topLocations.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Top 5 Locations")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                ForEach(Array(topLocations.enumerated()), id: \.offset) { index, location in
                                    HStack {
                                        Text("\(index + 1)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .frame(width: 20, height: 20)
                                            .background(Circle().fill(Color.blue))

                                        Text(location.0)
                                            .font(.body)

                                        Spacer()

                                        Text("\(location.1)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // MILESTONES SECTION
            YearlyMilestonesSection(sessions: yearSessions)
        }
    }
}

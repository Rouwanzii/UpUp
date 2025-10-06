import SwiftUI
import CoreData
import Charts

// MARK: - Enhanced Weekly Stats View

struct EnhancedWeeklyStatsView: View {
    let sessions: [ClimbingSession]
    @Binding var selectedDate: Date
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

    var body: some View {
        VStack(spacing: 24) {
            // OVERVIEW SECTION
            SectionContainer(title: "Weekly Overview") {
                VStack(spacing: 16) {
                    // Summary Stats Grid
                    HStack(spacing: 12) {
                        StatCard(value: "\(weekSessions.count)", label: "Sessions", color: .blue)
                        StatCard(value: String(format: "%.1f h", totalDuration), label: "Duration", color: .green)
                        StatCard(value: "\(totalCompletedRoutes)", label: "Completed", color: .orange)
                    }

                    // Highest Grade
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
                    .padding(.vertical, 8)
                }
            }

            // PERFORMANCE SECTION
            SectionContainer(title: "Performance") {
                VStack(spacing: 16) {
                    // Routes Per Day Chart
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Routes Per Day")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        WeeklyRoutesChart(sessions: weekSessions, selectedDate: selectedDate)
                            .frame(height: 180)
                    }

                    Divider()

                    // Mood Trend
                    if !weekSessions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Mood Trend")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack(spacing: 12) {
                                ForEach(sortedWeekSessions(), id: \.id) { session in
                                    VStack(spacing: 4) {
                                        Text(session.mood ?? "😊")
                                            .font(.title2)
                                        Text(dayOfWeek(session.date))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                }
            }

            // CALENDAR SECTION
            SectionContainer(title: "Training Days") {
                WeeklyCalendarGrid(sessions: weekSessions, selectedDate: selectedDate)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
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

// MARK: - Enhanced Monthly Stats View

struct EnhancedMonthlyStatsView: View {
    let sessions: [ClimbingSession]
    @Binding var selectedDate: Date
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
        VStack(spacing: 24) {
            // OVERVIEW SECTION
            SectionContainer(title: "Monthly Overview") {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        StatCard(value: "\(monthSessions.count)", label: "Sessions", color: .blue)
                        StatCard(value: String(format: "%.1f h", totalDuration), label: "Duration", color: .green)
                        StatCard(value: "\(totalCompletedRoutes)", label: "Completed", color: .orange)
                    }
                }
            }

            // PROGRESS SECTION
            SectionContainer(title: "Progress") {
                VStack(spacing: 20) {
                    // Grade Progression
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Grade Progression")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        MonthlyGradeProgressionChart(sessions: monthSessions)
                            .frame(height: 180)
                    }

                    Divider()

                    // Routes Per Week
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Completed Routes Per Week")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        MonthlyWeeklyRoutesChart(sessions: monthSessions, selectedDate: selectedDate)
                            .frame(height: 180)
                    }
                }
            }

            // LOCATIONS SECTION
            if !topLocations.isEmpty || (indoorOutdoorRatio.indoor > 0 || indoorOutdoorRatio.outdoor > 0) {
                SectionContainer(title: "Locations") {
                    VStack(spacing: 16) {
                        // Indoor vs Outdoor
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
                            }
                        }

                        // Top Locations
                        if !topLocations.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
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
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Enhanced Yearly Stats View

struct EnhancedYearlyStatsView: View {
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
        VStack(spacing: 24) {
            // OVERVIEW SECTION
            SectionContainer(title: "Yearly Overview") {
                HStack(spacing: 12) {
                    StatCard(value: "\(yearSessions.count)", label: "Sessions", color: .blue)
                    StatCard(value: String(format: "%.0f h", totalDuration), label: "Duration", color: .green)
                    StatCard(value: "\(totalCompletedRoutes)", label: "Completed", color: .orange)
                }
            }

            // PROGRESS SECTION
            SectionContainer(title: "Progress") {
                VStack(spacing: 20) {
                    // Monthly Grade Progression
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Grade Progression by Month")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        YearlyGradeProgressionChart(sessions: yearSessions)
                            .frame(height: 180)
                    }

                    Divider()

                    // Grade Distribution
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Grade Distribution")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        YearlyGradeDistributionChart(sessions: yearSessions)
                            .frame(height: 180)
                    }
                }
            }

            // PERFORMANCE SECTION
            SectionContainer(title: "Performance") {
                VStack(spacing: 16) {
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
                        // Indoor vs Outdoor
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
                            }
                        }

                        // Top Locations
                        if !topLocations.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
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
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Supporting Components

struct SectionContainer<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.horizontal, 20)

            content
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                .padding(.horizontal, 20)
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

struct CompletionStyleCard: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text("\(count)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct WeeklyCalendarGrid: View {
    let sessions: [ClimbingSession]
    let selectedDate: Date
    private let calendar = Calendar.current

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<7) { dayOffset in
                let date = calendar.date(byAdding: .day, value: dayOffset - calendar.component(.weekday, from: selectedDate) + 1, to: selectedDate) ?? selectedDate
                let hasSession = sessions.contains { session in
                    guard let sessionDate = session.date else { return false }
                    return calendar.isDate(sessionDate, inSameDayAs: date)
                }

                VStack(spacing: 6) {
                    Text(dayName(date))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ZStack {
                        Circle()
                            .fill(hasSession ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                            .frame(width: 36, height: 36)

                        Text("\(calendar.component(.day, from: date))")
                            .font(.subheadline)
                            .fontWeight(hasSession ? .semibold : .regular)
                            .foregroundColor(hasSession ? .green : .secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func dayName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

struct YearlyMilestonesSection: View {
    let sessions: [ClimbingSession]

    private var milestones: [(String, String)] {
        var results: [(String, String)] = []
        var seenGrades: Set<String> = []

        for session in sessions.sorted(by: { ($0.date ?? Date()) < ($1.date ?? Date()) }) {
            for route in session.routes {
                if let difficulty = route.difficulty,
                   (route.result == .onsight || route.result == .flash || route.result == .send),
                   !seenGrades.contains(difficulty.rawValue) {
                    seenGrades.insert(difficulty.rawValue)

                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMMM"
                    let month = formatter.string(from: session.date ?? Date())

                    results.append((difficulty.rawValue, month))
                }
            }
        }

        return results
    }

    var body: some View {
        if !milestones.isEmpty {
            SectionContainer(title: "Milestones") {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(milestones.prefix(5).enumerated()), id: \.offset) { _, milestone in
                        HStack(spacing: 12) {
                            Image(systemName: "star.fill")
                                .font(.subheadline)
                                .foregroundColor(.yellow)

                            Text("First \(milestone.0) completed in \(milestone.1)")
                                .font(.subheadline)

                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

struct IndoorOutdoorPieChart: View {
    let indoor: Int
    let outdoor: Int

    private var total: Int { indoor + outdoor }
    private var indoorPercentage: Double {
        guard total > 0 else { return 0 }
        return Double(indoor) / Double(total)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green)

            Circle()
                .trim(from: 0, to: indoorPercentage)
                .fill(Color.blue)
                .rotationEffect(.degrees(-90))
        }
    }
}

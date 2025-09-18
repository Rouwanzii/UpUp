import SwiftUI

struct SixMonthHeatmap: View {
    let sessions: [ClimbingSession]
    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            heatmapSection
            monthLabelsSection
            legendSection
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }

    private var heatmapSection: some View {
        HStack(spacing: 0) {
            HeatmapDayLabels()
            HeatmapGrid(weeklyData: weeklyData, sessions: sessions)
        }
    }

    private var monthLabelsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Spacer().frame(width: 20) // Align with day labels

                HStack(spacing: 0) {
                    ForEach(Array(monthLabels.enumerated()), id: \.offset) { index, item in
                        Text(item.label)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(width: CGFloat(item.weeks * 14), alignment: .leading)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private var legendSection: some View {
        HStack {
            Text("Less")
                .font(.caption2)
                .foregroundColor(.secondary)

            legendColors

            Text("More")
                .font(.caption2)
                .foregroundColor(.secondary)

            Spacer()

            Text("\(totalSessions) sessions in 6 months")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var legendColors: some View {
        HStack(spacing: 2) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 10, height: 10)
                .cornerRadius(2)
            Rectangle()
                .fill(Color.green.opacity(0.3))
                .frame(width: 10, height: 10)
                .cornerRadius(2)
            Rectangle()
                .fill(Color.green.opacity(0.6))
                .frame(width: 10, height: 10)
                .cornerRadius(2)
            Rectangle()
                .fill(Color.green.opacity(0.8))
                .frame(width: 10, height: 10)
                .cornerRadius(2)
            Rectangle()
                .fill(Color.green)
                .frame(width: 10, height: 10)
                .cornerRadius(2)
        }
    }

    // Generate 6 months of data organized by weeks
    private var weeklyData: [[Date]] {
        let today = Date()
        let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: today) ?? today

        // Find the start of the week for six months ago
        let startOfFirstWeek = calendar.dateInterval(of: .weekOfYear, for: sixMonthsAgo)?.start ?? sixMonthsAgo

        var weeks: [[Date]] = []
        var currentWeekStart = startOfFirstWeek

        while currentWeekStart <= today {
            var week: [Date] = []

            // Add 7 days starting from Monday
            for dayOffset in 0..<7 {
                if let day = calendar.date(byAdding: .day, value: dayOffset, to: currentWeekStart) {
                    week.append(day)
                }
            }

            weeks.append(week)
            currentWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart) ?? today
        }

        return weeks.reversed() // Most recent on the right
    }

    private var monthLabels: [(label: String, weeks: Int)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        var labels: [(String, Int)] = []
        var currentMonth: Int = -1
        var weekCount = 0

        for week in weeklyData.reversed() {
            if let firstDayOfWeek = week.first {
                let month = calendar.component(.month, from: firstDayOfWeek)

                if month != currentMonth {
                    if currentMonth != -1 {
                        labels.append((formatter.string(from: week.first!), weekCount))
                        weekCount = 0
                    }
                    currentMonth = month
                }
                weekCount += 1
            }
        }

        // Add the last month
        if let lastWeek = weeklyData.last?.first {
            labels.append((formatter.string(from: lastWeek), weekCount))
        }

        return labels.reversed()
    }

    private func dayLabel(for dayIndex: Int) -> String {
        let weekdays = ["M", "T", "W", "T", "F", "S", "S"]
        return weekdays[dayIndex]
    }

    private func colorForDay(_ date: Date) -> Color {
        let hoursForDate = hoursForDate(date)

        switch hoursForDate {
        case 0:
            return Color.gray.opacity(0.2)
        case 0.1..<1:
            return Color.green.opacity(0.3)
        case 1..<2:
            return Color.green.opacity(0.6)
        case 2..<3:
            return Color.green.opacity(0.8)
        default:
            return Color.green
        }
    }

    private func hoursForDate(_ date: Date) -> Double {
        let sessionsForDate = sessions.filter { session in
            guard let sessionDate = session.date else { return false }
            return calendar.isDate(sessionDate, inSameDayAs: date)
        }

        let totalMinutes = sessionsForDate.reduce(0) { $0 + Int($1.duration) }
        return Double(totalMinutes) / 60.0
    }

    private var totalSessions: Int {
        let today = Date()
        let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: today) ?? today

        return sessions.filter { session in
            guard let sessionDate = session.date else { return false }
            return sessionDate >= sixMonthsAgo
        }.count
    }
}

struct HeatmapDayLabels: View {
    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<7) { dayIndex in
                Text(dayLabel(for: dayIndex))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 20, height: 12)
            }
        }
    }

    private func dayLabel(for dayIndex: Int) -> String {
        let weekdays = ["M", "T", "W", "T", "F", "S", "S"]
        return weekdays[dayIndex]
    }
}

struct HeatmapGrid: View {
    let weeklyData: [[Date]]
    let sessions: [ClimbingSession]
    private let calendar = Calendar.current

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(Array(weeklyData.enumerated()), id: \.offset) { weekIndex, week in
                    VStack(spacing: 2) {
                        ForEach(0..<7) { dayIndex in
                            Rectangle()
                                .fill(colorForDay(week[dayIndex]))
                                .frame(width: 12, height: 12)
                                .cornerRadius(2)
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func colorForDay(_ date: Date) -> Color {
        let hoursForDate = hoursForDate(date)

        switch hoursForDate {
        case 0:
            return Color.gray.opacity(0.2)
        case 0.1..<1:
            return Color.green.opacity(0.3)
        case 1..<2:
            return Color.green.opacity(0.6)
        case 2..<3:
            return Color.green.opacity(0.8)
        default:
            return Color.green
        }
    }

    private func hoursForDate(_ date: Date) -> Double {
        let sessionsForDate = sessions.filter { session in
            guard let sessionDate = session.date else { return false }
            return calendar.isDate(sessionDate, inSameDayAs: date)
        }

        let totalMinutes = sessionsForDate.reduce(0) { $0 + Int($1.duration) }
        return Double(totalMinutes) / 60.0
    }
}

#Preview {
    SixMonthHeatmap(sessions: [])
        .padding()
}
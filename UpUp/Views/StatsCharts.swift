import SwiftUI
import Charts

// MARK: - Weekly Routes Chart

struct WeeklyRoutesChart: View {
    let sessions: [ClimbingSession]
    let selectedDate: Date
    private let calendar = Calendar.current

    private var dailyRoutes: [(day: String, count: Int)] {
        var routesByDay: [String: Int] = [:]

        for session in sessions {
            guard let date = session.date else { continue }
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            let dayName = formatter.string(from: date)

            let completedCount = session.routes.filter {
                $0.result == .onsight || $0.result == .flash || $0.result == .send
            }.count

            routesByDay[dayName, default: 0] += completedCount
        }

        let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return weekdays.map { (day: $0, count: routesByDay[$0] ?? 0) }
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            Chart {
                ForEach(dailyRoutes, id: \.day) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Routes", item.count)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .cornerRadius(4)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(dailyRoutes, id: \.day) { item in
                    HStack {
                        Text(item.day)
                            .font(.caption)
                            .frame(width: 40, alignment: .leading)

                        GeometryReader { geometry in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue)
                                .frame(width: max(CGFloat(item.count) * 20, 4))
                        }
                        .frame(height: 20)

                        Text("\(item.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Monthly Grade Progression Chart

struct MonthlyGradeProgressionChart: View {
    let sessions: [ClimbingSession]
    private let calendar = Calendar.current

    private var weeklyHighestGrades: [(week: String, gradeIndex: Int, gradeName: String)] {
        var gradesByWeek: [Int: RouteDifficulty] = [:]

        for session in sessions {
            guard let date = session.date else { continue }
            let weekOfYear = calendar.component(.weekOfYear, from: date)

            let completed = session.routes
                .filter { $0.result == .onsight || $0.result == .flash || $0.result == .send }
                .compactMap { $0.difficulty }

            if let maxGrade = completed.max(by: { a, b in
                let allGrades = RouteDifficulty.boulderingGrades + RouteDifficulty.sportGrades
                let indexA = allGrades.firstIndex(of: a) ?? 0
                let indexB = allGrades.firstIndex(of: b) ?? 0
                return indexA < indexB
            }) {
                if let existingGrade = gradesByWeek[weekOfYear] {
                    let allGrades = RouteDifficulty.boulderingGrades + RouteDifficulty.sportGrades
                    let existingIndex = allGrades.firstIndex(of: existingGrade) ?? 0
                    let newIndex = allGrades.firstIndex(of: maxGrade) ?? 0
                    if newIndex > existingIndex {
                        gradesByWeek[weekOfYear] = maxGrade
                    }
                } else {
                    gradesByWeek[weekOfYear] = maxGrade
                }
            }
        }

        let allGrades = RouteDifficulty.boulderingGrades + RouteDifficulty.sportGrades
        return gradesByWeek.sorted { $0.key < $1.key }.map { week, grade in
            let index = allGrades.firstIndex(of: grade) ?? 0
            return (week: "W\(week)", gradeIndex: index, gradeName: grade.rawValue)
        }
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            Chart {
                ForEach(Array(weeklyHighestGrades.enumerated()), id: \.offset) { _, item in
                    LineMark(
                        x: .value("Week", item.week),
                        y: .value("Grade", item.gradeIndex)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Week", item.week),
                        y: .value("Grade", item.gradeIndex)
                    )
                    .foregroundStyle(Color.blue)
                }
            }
        } else {
            VStack {
                Text("Grade progression requires iOS 16+")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Monthly Weekly Routes Chart

struct MonthlyWeeklyRoutesChart: View {
    let sessions: [ClimbingSession]
    let selectedDate: Date
    private let calendar = Calendar.current

    private var weeklyRoutes: [(week: String, count: Int)] {
        var routesByWeek: [Int: Int] = [:]

        for session in sessions {
            guard let date = session.date else { continue }
            let weekOfYear = calendar.component(.weekOfYear, from: date)

            let completedCount = session.routes.filter {
                $0.result == .onsight || $0.result == .flash || $0.result == .send
            }.count

            routesByWeek[weekOfYear, default: 0] += completedCount
        }

        return routesByWeek.sorted { $0.key < $1.key }.map { (week: "W\($0.key)", count: $0.value) }
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            Chart {
                ForEach(weeklyRoutes, id: \.week) { item in
                    BarMark(
                        x: .value("Week", item.week),
                        y: .value("Routes", item.count)
                    )
                    .foregroundStyle(Color.green.gradient)
                    .cornerRadius(4)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(weeklyRoutes, id: \.week) { item in
                    HStack {
                        Text(item.week)
                            .font(.caption)
                            .frame(width: 40, alignment: .leading)

                        GeometryReader { geometry in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.green)
                                .frame(width: max(CGFloat(item.count) * 10, 4))
                        }
                        .frame(height: 20)

                        Text("\(item.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Yearly Grade Progression Chart

struct YearlyGradeProgressionChart: View {
    let sessions: [ClimbingSession]
    private let calendar = Calendar.current

    private var monthlyHighestGrades: [(month: String, gradeIndex: Int, gradeName: String)] {
        var gradesByMonth: [Int: RouteDifficulty] = [:]

        for session in sessions {
            guard let date = session.date else { continue }
            let month = calendar.component(.month, from: date)

            let completed = session.routes
                .filter { $0.result == .onsight || $0.result == .flash || $0.result == .send }
                .compactMap { $0.difficulty }

            if let maxGrade = completed.max(by: { a, b in
                let allGrades = RouteDifficulty.boulderingGrades + RouteDifficulty.sportGrades
                let indexA = allGrades.firstIndex(of: a) ?? 0
                let indexB = allGrades.firstIndex(of: b) ?? 0
                return indexA < indexB
            }) {
                if let existingGrade = gradesByMonth[month] {
                    let allGrades = RouteDifficulty.boulderingGrades + RouteDifficulty.sportGrades
                    let existingIndex = allGrades.firstIndex(of: existingGrade) ?? 0
                    let newIndex = allGrades.firstIndex(of: maxGrade) ?? 0
                    if newIndex > existingIndex {
                        gradesByMonth[month] = maxGrade
                    }
                } else {
                    gradesByMonth[month] = maxGrade
                }
            }
        }

        let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let allGrades = RouteDifficulty.boulderingGrades + RouteDifficulty.sportGrades

        return gradesByMonth.sorted { $0.key < $1.key }.map { month, grade in
            let index = allGrades.firstIndex(of: grade) ?? 0
            return (month: monthNames[month - 1], gradeIndex: index, gradeName: grade.rawValue)
        }
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            Chart {
                ForEach(Array(monthlyHighestGrades.enumerated()), id: \.offset) { _, item in
                    LineMark(
                        x: .value("Month", item.month),
                        y: .value("Grade", item.gradeIndex)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Month", item.month),
                        y: .value("Grade", item.gradeIndex)
                    )
                    .foregroundStyle(Color.blue)
                    .annotation(position: .top) {
                        Text(item.gradeName)
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
        } else {
            VStack {
                Text("Grade progression requires iOS 16+")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Yearly Grade Distribution Chart

struct YearlyGradeDistributionChart: View {
    let sessions: [ClimbingSession]

    private var gradeDistribution: [(grade: String, count: Int)] {
        var distribution: [String: Int] = [:]

        for session in sessions {
            for route in session.routes {
                if let difficulty = route.difficulty,
                   (route.result == .onsight || route.result == .flash || route.result == .send) {
                    distribution[difficulty.rawValue, default: 0] += 1
                }
            }
        }

        let allGrades = RouteDifficulty.boulderingGrades + RouteDifficulty.sportGrades
        return distribution.map { (grade: $0.key, count: $0.value) }
            .sorted { item1, item2 in
                let index1 = allGrades.firstIndex { $0.rawValue == item1.grade } ?? 0
                let index2 = allGrades.firstIndex { $0.rawValue == item2.grade } ?? 0
                return index1 < index2
            }
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            Chart {
                ForEach(gradeDistribution, id: \.grade) { item in
                    BarMark(
                        x: .value("Grade", item.grade),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(Color.orange.gradient)
                    .cornerRadius(4)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(gradeDistribution, id: \.grade) { item in
                        VStack(spacing: 4) {
                            Text("\(item.count)")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.orange)
                                .frame(width: 30, height: max(CGFloat(item.count) * 20, 4))

                            Text(item.grade)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
        }
    }
}

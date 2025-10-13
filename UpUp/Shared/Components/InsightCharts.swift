import SwiftUI
import Charts

// MARK: - Difficulty Progression Chart

struct DifficultyProgressionChart: View {
    let sessions: [ClimbingSession]
    let climbingType: ClimbingType
    private let calendar = Calendar.current

    private var progressionData: [(date: Date, grade: Int, type: String, gradeName: String)] {
        var data: [(Date, Int, String, String)] = []

        let relevantGrades = climbingType == .bouldering ?
            RouteDifficulty.boulderingGrades :
            RouteDifficulty.sportGrades

        for session in sessions.sorted(by: { ($0.date ?? Date.distantPast) < ($1.date ?? Date.distantPast) }) {
            guard let sessionDate = session.date else { continue }

            let routes = session.routes.filter { route in
                guard let difficulty = route.difficulty else { return false }
                return difficulty.climbingType == climbingType
            }

            // Hardest send
            let hardestSend = routes
                .filter { $0.result == .send }
                .compactMap { $0.difficulty }
                .max(by: { a, b in
                    let indexA = relevantGrades.firstIndex(of: a) ?? 0
                    let indexB = relevantGrades.firstIndex(of: b) ?? 0
                    return indexA < indexB
                })

            if let grade = hardestSend,
               let gradeIndex = relevantGrades.firstIndex(of: grade) {
                data.append((sessionDate, gradeIndex, "Send", grade.rawValue))
            }

            // Hardest flash
            let hardestFlash = routes
                .filter { $0.result == .flash }
                .compactMap { $0.difficulty }
                .max(by: { a, b in
                    let indexA = relevantGrades.firstIndex(of: a) ?? 0
                    let indexB = relevantGrades.firstIndex(of: b) ?? 0
                    return indexA < indexB
                })

            if let grade = hardestFlash,
               let gradeIndex = relevantGrades.firstIndex(of: grade) {
                data.append((sessionDate, gradeIndex, "Flash", grade.rawValue))
            }

            // Hardest onsight
            let hardestOnsight = routes
                .filter { $0.result == .onsight }
                .compactMap { $0.difficulty }
                .max(by: { a, b in
                    let indexA = relevantGrades.firstIndex(of: a) ?? 0
                    let indexB = relevantGrades.firstIndex(of: b) ?? 0
                    return indexA < indexB
                })

            if let grade = hardestOnsight,
               let gradeIndex = relevantGrades.firstIndex(of: grade) {
                data.append((sessionDate, gradeIndex, "Onsight", grade.rawValue))
            }
        }

        return data
    }

    private var uniqueGrades: Int {
        Set(progressionData.map { $0.grade }).count
    }

    private var chartHeight: CGFloat {
        let heightPerGrade: CGFloat = 40
        let minHeight: CGFloat = 120
        return max(CGFloat(uniqueGrades) * heightPerGrade, minHeight)
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            if progressionData.isEmpty {
                EmptyChartView(message: "No \(climbingType.rawValue.lowercased()) data yet")
            } else {
                Chart {
                    ForEach(Array(progressionData.enumerated()), id: \.offset) { index, item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Grade", item.grade)
                        )
                        .foregroundStyle(by: .value("Type", item.type))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", item.date),
                            y: .value("Grade", item.grade)
                        )
                        .foregroundStyle(by: .value("Type", item.type))
                    }
                }
                .frame(maxWidth: .infinity, minHeight: chartHeight, maxHeight: chartHeight)
                .chartForegroundStyleScale([
                    "Send": Color.orange,
                    "Flash": Color.blue,
                    "Onsight": Color.green
                ])
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel(format: .dateTime.month().day())
                            .font(.caption2)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                let grades = climbingType == .bouldering ?
                                    RouteDifficulty.boulderingGrades :
                                    RouteDifficulty.sportGrades
                                if intValue < grades.count {
                                    Text(grades[intValue].rawValue)
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                }
                .chartLegend(position: .bottom, spacing: 16) {
                    HStack(spacing: 16) {
                        ForEach(["Send", "Flash", "Onsight"], id: \.self) { type in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(type == "Send" ? Color.orange : type == "Flash" ? Color.blue : Color.green)
                                    .frame(width: 8, height: 8)
                                Text(type)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.top, 8)
            }
        } else {
            Text("Requires iOS 16+")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Difficulty Distribution Chart

struct DifficultyDistributionChart: View {
    let sessions: [ClimbingSession]
    let climbingType: ClimbingType

    private var distributionData: [(grade: String, count: Int, result: String)] {
        var distribution: [String: [String: Int]] = [:]

        let relevantGrades = climbingType == .bouldering ?
            RouteDifficulty.boulderingGrades :
            RouteDifficulty.sportGrades

        for session in sessions {
            for route in session.routes {
                guard let difficulty = route.difficulty,
                      let result = route.result,
                      difficulty.climbingType == climbingType else { continue }

                let gradeName = difficulty.rawValue
                let resultName = result.rawValue

                if distribution[gradeName] == nil {
                    distribution[gradeName] = [:]
                }
                distribution[gradeName]?[resultName, default: 0] += 1
            }
        }

        var data: [(String, Int, String)] = []
        for (grade, results) in distribution {
            for (result, count) in results {
                data.append((grade, count, result))
            }
        }

        return data.sorted { (item1: (grade: String, count: Int, result: String), item2: (grade: String, count: Int, result: String)) -> Bool in
            let index1 = relevantGrades.firstIndex { $0.rawValue == item1.0 } ?? 0
            let index2 = relevantGrades.firstIndex { $0.rawValue == item2.0 } ?? 0
            return index1 > index2
        }
    }

    private var uniqueGrades: Int {
        Set(distributionData.map { $0.grade }).count
    }

    private var chartHeight: CGFloat {
        let heightPerGrade: CGFloat = 50
        let minHeight: CGFloat = 100
        return max(CGFloat(uniqueGrades) * heightPerGrade, minHeight)
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            if distributionData.isEmpty {
                EmptyChartView(message: "No \(climbingType.rawValue.lowercased()) data yet")
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Chart {
                        ForEach(Array(distributionData.enumerated()), id: \.offset) { index, item in
                            BarMark(
                                x: .value("Count", item.count),
                                y: .value("Grade", item.grade)
                            )
                            .foregroundStyle(by: .value("Result", item.result))
                            .cornerRadius(4)
                            .annotation(position: .trailing, alignment: .leading) {
                                Text("\(item.count)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: chartHeight, maxHeight: chartHeight)
                    .chartForegroundStyleScale([
                        "Onsight": Color.green,
                        "Flash": Color.blue,
                        "Send": Color.orange,
                        "Fail": Color.gray.opacity(0.2)
                    ])
                    .chartXAxis {
                        AxisMarks(position: .bottom) { value in
                            AxisGridLine()
                            AxisValueLabel()
                                .font(.caption2)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel()
                                .font(.caption2)
                        }
                    }
                    //.padding(.bottom)
                    .chartLegend(position: .bottom, spacing: 10)

                    // X-axis label
                    /*
                    Text("Route Counts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                     */
                }
            }
        } else {
            Text("Requires iOS 16+")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Indoor vs Outdoor Ratio Chart

struct IndoorOutdoorRatioChart: View {
    let sessions: [ClimbingSession]
    @State private var selectedEnvironment: ClimbingEnvironment?

    private var indoor: Int {
        sessions.filter { $0.environment == .indoor }.count
    }

    private var outdoor: Int {
        sessions.filter { $0.environment == .outdoor }.count
    }

    private var total: Int { indoor + outdoor }
    private var indoorPercentage: Double {
        guard total > 0 else { return 0 }
        return Double(indoor) / Double(total)
    }
    private var outdoorPercentage: Double {
        guard total > 0 else { return 0 }
        return Double(outdoor) / Double(total)
    }

    var body: some View {
        HStack(spacing: 20) {
            // Pie Chart
            ZStack {
                // Outdoor section (background)
                Circle()
                    .fill(Color.green.opacity(0.3))
                    .onTapGesture {
                        if outdoor > 0 {
                            selectedEnvironment = .outdoor
                        }
                    }

                // Indoor section (foreground)
                Circle()
                    .trim(from: 0, to: indoorPercentage)
                    .fill(Color.blue)
                    .rotationEffect(.degrees(-90))
                    .onTapGesture {
                        if indoor > 0 {
                            selectedEnvironment = .indoor
                        }
                    }
            }
            .frame(width: 120, height: 120)

            // Legend
            VStack(alignment: .leading, spacing: 12) {
                // Indoor
                Button(action: {
                    if indoor > 0 {
                        selectedEnvironment = .indoor
                    }
                }) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Indoor")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            Text("\(indoor) sessions (\(String(format: "%.0f%%", indoorPercentage * 100)))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .disabled(indoor == 0)

                // Outdoor
                Button(action: {
                    if outdoor > 0 {
                        selectedEnvironment = .outdoor
                    }
                }) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.green.opacity(0.8))
                            .frame(width: 12, height: 12)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Outdoor")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            Text("\(outdoor) sessions (\(String(format: "%.0f%%", outdoorPercentage * 100)))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .disabled(outdoor == 0)
            }

            Spacer()
        }
        .sheet(item: $selectedEnvironment) { environment in
            LocationBreakdownSheet(sessions: sessions, environment: environment)
        }
    }
}

// MARK: - Location Breakdown Sheet

struct LocationBreakdownSheet: View {
    @Environment(\.dismiss) private var dismiss
    let sessions: [ClimbingSession]
    let environment: ClimbingEnvironment

    private var filteredSessions: [ClimbingSession] {
        sessions.filter { $0.environment == environment }
    }

    private var locationBreakdown: [(location: String, count: Int)] {
        var locationCounts: [String: Int] = [:]

        for session in filteredSessions {
            let location = session.location?.isEmpty == false ? session.location! : "Unknown Location"
            locationCounts[location, default: 0] += 1
        }

        return locationCounts.map { (location: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Total: \(filteredSessions.count) sessions")) {
                    ForEach(locationBreakdown, id: \.location) { item in
                        HStack {
                            Image(systemName: environment == .indoor ? "building.2.fill" : "mountain.2.fill")
                                .foregroundColor(environment == .indoor ? .blue : .green)
                                .frame(width: 24)
                                .padding()

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.location)
                                    .font(.body)
                                    .fontWeight(.medium)

                                Text("\(item.count) session\(item.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text(String(format: "%.0f%%", Double(item.count) / Double(filteredSessions.count) * 100))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("\(environment.rawValue) Locations")
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

// MARK: - Empty Chart View

struct EmptyChartView: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.xyaxis.line")
                .font(.title)
                .foregroundColor(.secondary)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    VStack(spacing: 20) {
        DifficultyProgressionChart(sessions: [], climbingType: .bouldering)
            .frame(height: 200)
            .padding()

        DifficultyDistributionChart(sessions: [], climbingType: .bouldering)
            .frame(height: 200)
            .padding()

        IndoorOutdoorRatioChart(sessions: [])
            .frame(height: 160)
            .padding()
    }
}

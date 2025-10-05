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
            return index1 < index2
        }
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            if distributionData.isEmpty {
                EmptyChartView(message: "No \(climbingType.rawValue.lowercased()) data yet")
            } else {
                Chart {
                    ForEach(Array(distributionData.enumerated()), id: \.offset) { index, item in
                        BarMark(
                            x: .value("Count", item.count),
                            y: .value("Grade", item.grade)
                        )
                        .foregroundStyle(by: .value("Result", item.result))
                        .cornerRadius(4)
                    }
                }
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

// MARK: - Indoor vs Outdoor Ratio Chart

struct IndoorOutdoorRatioChart: View {
    let indoor: Int
    let outdoor: Int

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
                Circle()
                    .fill(Color.green.opacity(0.3))

                Circle()
                    .trim(from: 0, to: indoorPercentage)
                    .fill(Color.blue)
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 120, height: 120)

            // Legend
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 12, height: 12)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Indoor")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("\(indoor) sessions (\(String(format: "%.0f%%", indoorPercentage * 100)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.green.opacity(0.8))
                        .frame(width: 12, height: 12)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Outdoor")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("\(outdoor) sessions (\(String(format: "%.0f%%", outdoorPercentage * 100)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
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

        IndoorOutdoorRatioChart(indoor: 7, outdoor: 3)
            .frame(height: 160)
            .padding()
    }
}

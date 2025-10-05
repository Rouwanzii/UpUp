import SwiftUI
import CoreData
import Charts

struct SessionDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var session: ClimbingSession
    @State private var showingEditView = false
    @State private var animateCharts = false
    @State private var refreshID = UUID()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Date and Mood Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formattedDate)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("\(Double(session.duration) / 60.0, specifier: "%.1f") hours")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if let mood = session.mood {
                        Text(mood)
                            .font(.system(size: 50))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Summary Stats Cards
                HStack(spacing: 12) {
                    SessionStatCard(
                        value: "\(session.routes.count)",
                        label: "Total Routes",
                        color: .blue
                    )

                    SessionStatCard(
                        value: "\(completedRoutesCount)",
                        label: "Completed",
                        color: .green
                    )

                    SessionStatCard(
                        value: highestGrade,
                        label: "Highest Grade",
                        color: .orange
                    )
                }
                .padding(.horizontal)

                // Charts Section
                if !session.routes.isEmpty && completedRoutesCount > 0 {
                    VStack(spacing: 16) {
                        // Grade Distribution Chart
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Grade Distribution")
                                .font(.headline)
                                .padding(.horizontal)

                            GradeDistributionChart(routes: completedRoutes)
                                .frame(height: 200)
                                .padding(.horizontal)
                                .opacity(animateCharts ? 1 : 0)
                                .offset(y: animateCharts ? 0 : 20)
                        }
                        .padding(.vertical)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .padding(.horizontal)

                        // Stats Cards
                        HStack(spacing: 12) {
                            CompletionStatCard(
                                title: "Avg Attempts",
                                value: averageAttempts,
                                subtitle: "per route"
                            )

                            CompletionStatCard(
                                title: "Success Rate",
                                value: completionRate,
                                subtitle: "overall"
                            )
                        }
                        .padding(.horizontal)
                    }
                }

                // Environment & Location
                if let environment = session.environment {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Session Info")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 0) {
                            InfoRow(
                                icon: environment == .indoor ? "building.2.fill" : "mountain.2.fill",
                                label: "Environment",
                                value: environment.rawValue
                            )

                            if let location = session.location, !location.isEmpty {
                                Divider()
                                    .padding(.leading, 44)
                                InfoRow(
                                    icon: "mappin.circle.fill",
                                    label: "Location",
                                    value: location
                                )
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                }

                // Routes Section
                if !session.routes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Routes")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            ForEach(Array(session.routes.enumerated()), id: \.element.id) { index, route in
                                RouteDetailCard(route: route, index: index, environment: session.environment ?? .indoor)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }

                // Notes Section
                if let notes = session.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes")
                            .font(.headline)
                            .padding(.horizontal)

                        Text(notes)
                            .font(.body)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                            .padding(.horizontal)
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(formattedDate)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditView = true
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditSessionView(session: session)
                .environment(\.managedObjectContext, viewContext)
        }
        .onChange(of: showingEditView) { oldValue, newValue in
            // Refresh the view when returning from edit sheet
            if !newValue {
                // Force refresh by updating the ID
                refreshID = UUID()
                // Refresh the object from Core Data
                viewContext.refresh(session, mergeChanges: true)
            }
        }
        .id(refreshID)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                animateCharts = true
            }
        }
    }

    // MARK: - Computed Properties

    private var completedRoutes: [ClimbingRoute] {
        session.routes.filter { route in
            route.result == .onsight || route.result == .flash || route.result == .send
        }
    }

    private var completedRoutesCount: Int {
        completedRoutes.count
    }

    private var highestGrade: String {
        let completed = completedRoutes.compactMap { $0.difficulty }
        if completed.isEmpty { return "-" }

        // Separate bouldering and sport grades
        let boulderingGrades = completed.filter { $0.climbingType == .bouldering }
        let sportGrades = completed.filter { $0.climbingType == .sport }

        var result: [String] = []

        if let maxBouldering = boulderingGrades.max(by: {
            RouteDifficulty.boulderingGrades.firstIndex(of: $0) ?? 0 <
            RouteDifficulty.boulderingGrades.firstIndex(of: $1) ?? 0
        }) {
            result.append(maxBouldering.rawValue)
        }

        if let maxSport = sportGrades.max(by: {
            RouteDifficulty.sportGrades.firstIndex(of: $0) ?? 0 <
            RouteDifficulty.sportGrades.firstIndex(of: $1) ?? 0
        }) {
            result.append(maxSport.rawValue)
        }

        return result.isEmpty ? "-" : result.joined(separator: " / ")
    }

    private var averageAttempts: String {
        let routesWithAttempts = session.routes.compactMap { $0.attempts }
        guard !routesWithAttempts.isEmpty else { return "-" }
        let avg = Double(routesWithAttempts.reduce(0, +)) / Double(routesWithAttempts.count)
        return String(format: "%.1f", avg)
    }

    private var completionRate: String {
        guard !session.routes.isEmpty else { return "-" }
        let rate = Double(completedRoutesCount) / Double(session.routes.count) * 100
        return String(format: "%.0f%%", rate)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: session.date ?? Date())
    }
}

// MARK: - Supporting Views

struct SessionStatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct CompletionStatCard: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }

            Spacer()
        }
        .padding()
    }
}

struct GradeDistributionChart: View {
    let routes: [ClimbingRoute]

    var gradeData: [(grade: String, count: Int, result: RouteResult)] {
        var distribution: [String: [RouteResult]] = [:]

        for route in routes {
            guard let difficulty = route.difficulty,
                  let result = route.result else { continue }

            let grade = difficulty.rawValue
            if distribution[grade] == nil {
                distribution[grade] = []
            }
            distribution[grade]?.append(result)
        }

        var result: [(String, Int, RouteResult)] = []
        for (grade, results) in distribution {
            for res in results {
                result.append((grade, 1, res))
            }
        }

        return result.sorted { (item1: (grade: String, count: Int, result: RouteResult), item2: (grade: String, count: Int, result: RouteResult)) -> Bool in
            // Sort by grade level
            let allGrades = RouteDifficulty.boulderingGrades + RouteDifficulty.sportGrades
            let index1 = allGrades.firstIndex { $0.rawValue == item1.grade } ?? 0
            let index2 = allGrades.firstIndex { $0.rawValue == item2.grade } ?? 0
            return index1 < index2
        }
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            Chart {
                ForEach(Array(gradeData.enumerated()), id: \.offset) { index, item in
                    BarMark(
                        x: .value("Grade", item.grade),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(by: .value("Result", item.result.rawValue))
                }
            }
            .chartForegroundStyleScale([
                "Onsight": Color.green,
                "Flash": Color.blue,
                "Send": Color.orange,
                "Fail": Color.red
            ])
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
        } else {
            // Fallback for iOS 15
            VStack(alignment: .leading, spacing: 8) {
                Text("Grade distribution requires iOS 16+")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
}

struct RouteDetailCard: View {
    let route: ClimbingRoute
    let index: Int
    let environment: ClimbingEnvironment

    var body: some View {
        HStack(spacing: 16) {
            // Result Indicator
            if let result = route.result {
                Circle()
                    .fill(resultColor(result))
                    .frame(width: 12, height: 12)
            }

            VStack(alignment: .leading, spacing: 6) {
                // Route header
                HStack {
                    Text("Route \(index + 1)")
                        .font(.headline)

                    if let difficulty = route.difficulty {
                        Text(difficulty.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }

                    Spacer()

                    if let result = route.result {
                        HStack(spacing: 4) {
                            Text(result.emoji)
                                .font(.body)
                            Text(result.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Color or Name
                if environment == .indoor {
                    if let color = route.color {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(color.color)
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Circle()
                                        .stroke(color == .white ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                                )
                            Text(color.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    if let name = route.name, !name.isEmpty {
                        Text(name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Attempts
                if let attempts = route.attempts {
                    Text("\(attempts) attempt\(attempts == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func resultColor(_ result: RouteResult) -> Color {
        switch result {
        case .onsight: return .green
        case .flash: return .blue
        case .send: return .orange
        case .fail: return .red
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        SessionDetailView(session: PersistenceController.preview.sampleSession)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

// Preview helper
extension PersistenceController {
    var sampleSession: ClimbingSession {
        let session = ClimbingSession(context: container.viewContext)
        session.id = UUID()
        session.date = Date()
        session.duration = 120
        session.mood = "💪"
        session.notes = "Great session today! Sent my project route."

        // Add sample routes for preview
        var routes: [ClimbingRoute] = []
        routes.append(ClimbingRoute(difficulty: .v3, attempts: 2, result: .send, color: .blue, name: nil))
        routes.append(ClimbingRoute(difficulty: .v4, attempts: 1, result: .flash, color: .red, name: nil))
        routes.append(ClimbingRoute(difficulty: .v5, attempts: 5, result: .send, color: .green, name: nil))
        session.routes = routes

        return session
    }
}

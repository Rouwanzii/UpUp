import SwiftUI
import CoreData
import Charts

struct SessionDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var session: ClimbingSession
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    @State private var animateCharts = false
    @State private var refreshID = UUID()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Date and Mood Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if let location = session.location, !location.isEmpty {
                            Text(location)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        else{
                            if let environment = session.environment {
                                Text(environment.localizedName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                        }
               
                        Text(session.duration.toHours.formatAsHoursLong())
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

                // Summary Stats Cards - Row 1
                HStack(spacing: 8) {
                    SessionStatCard(
                        value: "\(session.routes.count)",
                        label: "sessionDetail.totalRoutes".localized,
                        color: .blue
                    )

                    SessionStatCard(
                        value: "\(completedRoutesCount)",
                        label: "sessionDetail.completed".localized,
                        color: .green
                    )

                    SessionStatCard(
                        value: "\(totalAttempts)",
                        label: "sessionDetail.totalAttempts".localized,
                        color: .purple
                    )
                }
                .padding(.horizontal)

                // Summary Stats Cards - Row 2
                HStack(spacing: 8) {
                    SessionStatCard(
                        value: bestBoulderingGrade,
                        label: "sessionDetail.bestBoulder".localized,
                        color: .orange
                    )

                    SessionStatCard(
                        value: bestSportGrade,
                        label: "sessionDetail.bestSport".localized,
                        color: .green
                    )
                }
                .padding(.horizontal)

                // Stats Cards
                /*
                if !session.routes.isEmpty {
                    HStack(spacing: 12) {
                        CompletionStatCard(
                            title: "sessionDetail.avgAttempts".localized,
                            value: averageAttempts,
                            subtitle: "sessionDetail.perRoute".localized
                        )

                        CompletionStatCard(
                            title: "sessionDetail.successRate".localized,
                            value: completionRate,
                            subtitle: "sessionDetail.overall".localized
                        )
                    }
                    .padding(.horizontal)
                }
                 */

                // Difficulty Distribution Charts
                if hasBoulderingRoutes {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("sessionDetail.BoulderDistribution".localized)
                            .font(.headline)
                            .padding(.horizontal)

                        SessionDifficultyDistributionChart(
                            routes: session.routes,
                            climbingType: .bouldering
                        )
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(DesignTokens.CardGradient.orangeYellow)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                        .padding(.horizontal)
                        .opacity(animateCharts ? 1 : 0)
                        .offset(y: animateCharts ? 0 : 20)
                    }
                }

                if hasSportRoutes {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("sessionDetail.sportDistribution".localized)
                            .font(.headline)
                            .padding(.horizontal)

                        SessionDifficultyDistributionChart(
                            routes: session.routes,
                            climbingType: .sport
                        )
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(DesignTokens.CardGradient.orangeYellow)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                        .padding(.horizontal)
                        .opacity(animateCharts ? 1 : 0)
                        .offset(y: animateCharts ? 0 : 20)
                    }
                }

                // Routes Section
                if !session.routes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("sessionDetail.routes".localized)
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
                        Text("sessionDetail.notes".localized)
                            .font(.headline)
                            .padding(.horizontal)

                        Text(notes)
                            .font(.body)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(DesignTokens.CardGradient.lightGrey)
                            )
                            //.shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                            .padding(.horizontal)
                    }
                }

                // Delete Button
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .font(.headline)
                        Text("sessionDetail.deleteSession".localized)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(DesignTokens.CornerRadius.medium)
                }
                .padding(.horizontal)
                .padding(.top, DesignTokens.Padding.large)

                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
        .background(Color(.systemBackground))
        .navigationTitle(formattedDate)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("sessionDetail.edit".localized) {
                    showingEditView = true
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            SessionLogSheet(mode: .edit(session), themeColor: .blue)
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
        .alert("sessionDetail.deleteSession".localized, isPresented: $showingDeleteAlert) {
            Button("common.delete".localized, role: .destructive) {
                deleteSession()
            }
            Button("common.cancel".localized, role: .cancel) { }
        } message: {
            Text("sessionDetail.deleteConfirm".localized)
        }
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

    private var totalAttempts: Int {
        session.routes.reduce(0) { total, route in
            // If attempts are explicitly logged, use that
            if let attempts = route.attempts {
                return total + attempts
            }
            // Otherwise, onsight and flash implicitly mean 1 attempt
            else if route.result == .onsight || route.result == .flash {
                return total + 1
            }
            // For other results without logged attempts, don't count
            return total
        }
    }

    private var bestBoulderingGrade: String {
        let completed = completedRoutes.compactMap { $0.difficulty }
        let boulderingGrades = completed.filter { $0.climbingType == .bouldering }

        guard let maxBouldering = boulderingGrades.max(by: {
            RouteDifficulty.boulderingGrades.firstIndex(of: $0) ?? 0 <
            RouteDifficulty.boulderingGrades.firstIndex(of: $1) ?? 0
        }) else {
            return "-"
        }

        return maxBouldering.rawValue
    }

    private var bestSportGrade: String {
        let completed = completedRoutes.compactMap { $0.difficulty }
        let sportGrades = completed.filter { $0.climbingType == .sport }

        guard let maxSport = sportGrades.max(by: {
            RouteDifficulty.sportGrades.firstIndex(of: $0) ?? 0 <
            RouteDifficulty.sportGrades.firstIndex(of: $1) ?? 0
        }) else {
            return "-"
        }

        return maxSport.rawValue
    }

    private var hasBoulderingRoutes: Bool {
        session.routes.contains { route in
            guard let difficulty = route.difficulty else { return false }
            return difficulty.climbingType == .bouldering
        }
    }

    private var hasSportRoutes: Bool {
        session.routes.contains { route in
            guard let difficulty = route.difficulty else { return false }
            return difficulty.climbingType == .sport
        }
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

    // MARK: - Delete Method

    private func deleteSession() {
        // Delete the session from Core Data
        viewContext.delete(session)

        do {
            try viewContext.save()
            // Navigate back after successful deletion
            dismiss()
        } catch {
            print("Error deleting session: \(error)")
        }
    }
}

// MARK: - Supporting Views
// SessionStatCard, CompletionStatCard, and InfoRow are now in Shared/Components/StatCards.swift

struct SessionDifficultyDistributionChart: View {
    let routes: [ClimbingRoute]
    let climbingType: ClimbingType

    // MARK: - Data Transformation
    private var distributionData: [(grade: String, count: Int, result: String)] {
        var distribution: [String: [String: Int]] = [:]

        let relevantGrades = climbingType == .bouldering ?
            RouteDifficulty.boulderingGrades :
            RouteDifficulty.sportGrades

        for route in routes {
            guard let difficulty = route.difficulty,
                  let result = route.result,
                  difficulty.climbingType == climbingType else { continue }

            let gradeName = difficulty.rawValue
            let resultName = result.rawValue
            distribution[gradeName, default: [:]][resultName, default: 0] += 1
        }

        var data: [(String, Int, String)] = []
        for (grade, results) in distribution {
            for (result, count) in results {
                data.append((grade, count, result))
            }
        }

        // 按照难度顺序排序（从高到低）
        return data.sorted {
            let relevant = relevantGrades.map { $0.rawValue }
            let i1 = relevant.firstIndex(of: $0.0) ?? 0
            let i2 = relevant.firstIndex(of: $1.0) ?? 0
            return i1 > i2
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

    private var emptyStateMessage: String {
        let typeName = climbingType.localizedName.lowercased()
        return "No \(typeName) data"
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            if distributionData.isEmpty {
                emptyStateView
            } else {
                chartContentView
            }
        } else {
            fallbackView
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.xyaxis.line")
                .font(.title)
                .foregroundColor(.secondary)
            Text(emptyStateMessage)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Fallback
    private var fallbackView: some View {
        Text("Requires iOS 16+")
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Chart
    @available(iOS 16.0, *)
    private var chartContentView: some View {
        // 明确 legend 顺序 & color
        let resultOrder = ["Onsight", "Flash", "Send", "Fail"]
        let colors: [Color] = [.green, .blue, .orange, .gray.opacity(0.3)]

        // 将数据按 result 分类，以避免类型推断负担
        let groupedData = resultOrder.map { result in
            distributionData.filter { $0.result == result }
        }

        return Chart {
            ForEach(Array(zip(resultOrder, groupedData)), id: \.0) { result, items in
                ForEach(items.indices, id: \.self) { index in
                    let item = items[index]
                    BarMark(
                        x: .value("Count", item.count),
                        y: .value("Grade", item.grade)
                    )
                    .foregroundStyle(by: .value("Result", result))
                    .cornerRadius(4)
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("\(item.count)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: chartHeight, maxHeight: chartHeight)
        .chartForegroundStyleScale(domain: resultOrder, range: colors)
        .chartLegend(position: .bottom)
        .chartXAxis {
            AxisMarks(position: .bottom) {
                AxisGridLine()
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) {
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .padding(.top, 8)
    }
}


// RouteDetailCard is now in Shared/Components/RouteComponents.swift

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

import SwiftUI
import CoreData

struct InsightsTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClimbingSession.date, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<ClimbingSession>

    @State private var selectedDateRange: DateRange = .last30Days
    @State private var showingCustomDatePicker = false
    @State private var customStartDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var customEndDate = Date()
    @State private var selectedClimbingType: ClimbingType = .bouldering

    enum DateRange: String, CaseIterable {
        case last7Days = "Last 7 Days"
        case last30Days = "Last 30 Days"
        case thisYear = "This Year"
        case custom = "Custom"

        var localizedName: String {
            switch self {
            case .last7Days:
                return "insights.last7Days".localized
            case .last30Days:
                return "insights.last30Days".localized
            case .thisYear:
                return "insights.thisYear".localized
            case .custom:
                return "insights.custom".localized
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Date Range Picker
                    VStack(spacing: 16) {
                        DateRangePicker(
                            selectedRange: $selectedDateRange,
                            showingCustom: $showingCustomDatePicker,
                            customStartDate: $customStartDate,
                            customEndDate: $customEndDate
                        )

                        // Custom Date Range Picker (shown inline)
                        if showingCustomDatePicker {
                            CustomDateRangeInlineView(
                                startDate: $customStartDate,
                                endDate: $customEndDate,
                                onClear: {
                                    showingCustomDatePicker = false
                                    selectedDateRange = .last30Days
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    if filteredSessions.isEmpty {
                        EmptyInsightsView()
                            .padding(.top, 60)
                    } else {
                        // Section 1: Progress Trends
                        ProgressTrendsSection(
                            sessions: filteredSessions,
                            selectedClimbingType: $selectedClimbingType
                        )

                        // Section 2: Session Highlights
                        SessionHighlightsSection(sessions: filteredSessions)

                        // Section 3: Motivational Insights
                        MotivationalInsightsSection(
                            sessions: filteredSessions,
                            dateRange: selectedDateRange
                        )
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemBackground))
            .navigationTitle("insights.title".localized)
        }
    }

    // MARK: - Computed Properties

    private var filteredSessions: [ClimbingSession] {
        let calendar = Calendar.current
        let now = Date()

        let (startDate, endDate): (Date, Date) = {
            switch selectedDateRange {
            case .last7Days:
                return (calendar.date(byAdding: .day, value: -7, to: now) ?? now, now)
            case .last30Days:
                return (calendar.date(byAdding: .day, value: -30, to: now) ?? now, now)
            case .thisYear:
                let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
                return (startOfYear, now)
            case .custom:
                return (customStartDate, customEndDate)
            }
        }()

        return sessions.filter { session in
            guard let sessionDate = session.date else { return false }
            return sessionDate >= startDate && sessionDate <= endDate
        }
    }
}

// MARK: - Date Range Picker

struct DateRangePicker: View {
    @Binding var selectedRange: InsightsTabView.DateRange
    @Binding var showingCustom: Bool
    @Binding var customStartDate: Date
    @Binding var customEndDate: Date

    var body: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(InsightsTabView.DateRange.allCases, id: \.self) { range in
                        Button(action: {
                            if range == .custom {
                                showingCustom.toggle()
                            } else {
                                showingCustom = false
                            }
                            selectedRange = range
                        }) {
                            Text(range == .custom && selectedRange == .custom ? customDateRangeText : range.localizedName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(selectedRange == range ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedRange == range ? Color.blue : Color(.systemGray6))
                                .cornerRadius(20)
                        }
                    }
                }
            }
        }
    }

    private var customDateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: customStartDate)) - \(formatter.string(from: customEndDate))"
    }
}

struct CustomDateRangeInlineView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("insights.customDateRange".localized)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: onClear) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.subheadline)
                        Text("insights.clear".localized)
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)
                }
            }

            VStack {
                HStack {
                    Text("insights.from".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .leading)

                    DatePicker("", selection: $startDate, displayedComponents: .date)
                        .labelsHidden()
                }

                Spacer()

                HStack {
                    Text("insights.to".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .leading)

                    DatePicker("", selection: $endDate, displayedComponents: .date)
                        .labelsHidden()
                }
            }
            //.padding()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Progress Trends Section

struct ProgressTrendsSection: View {
    let sessions: [ClimbingSession]
    @Binding var selectedClimbingType: ClimbingType

    private var totalDuration: Double {
        sessions.reduce(0.0) { $0 + Double($1.duration) / 60.0 }
    }

    private var indoorOutdoorRatio: (indoor: Int, outdoor: Int) {
        let indoor = sessions.filter { $0.environment == .indoor }.count
        let outdoor = sessions.filter { $0.environment == .outdoor }.count
        return (indoor, outdoor)
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

    var body: some View {
        VStack(spacing: 20) {
            InsightSectionHeader(title: "progress.title".localized, icon: "chart.line.uptrend.xyaxis")

            // Summary Cards Row 1
            HStack(spacing: 12) {
                ProgressIndicatorCard(
                    value: "\(sessions.count)",
                    label: "stats.sessions".localized,
                    //icon: "figure.climbing",
                    color: .blue
                )
                ProgressIndicatorCard(
                    value: totalDuration.formatAsHours(),
                    label: "stats.totalTime".localized,
                    //icon: "clock.fill",
                    color: .blue
                )
            }
            .padding(.horizontal, 20)

            // Summary Cards Row 2 - Best Grades
            HStack(spacing: 12) {
                ProgressIndicatorCard(
                    value: bestBoulderingGrade,
                    label: "stats.bestBoulder".localized,
                    //icon: "diamond.fill",
                    color: .orange
                )
                ProgressIndicatorCard(
                    value: bestSportGrade,
                    label: "stats.bestSport".localized,
                    //icon: "mountain.2.fill",
                    color: .green
                )
            }
            .padding(.horizontal, 20)

            // Indoor vs Outdoor Ratio
            if indoorOutdoorRatio.indoor > 0 || indoorOutdoorRatio.outdoor > 0 {
                InsightCard(title: "progress.indoorVsOutdoor".localized) {
                    IndoorOutdoorRatioChart(sessions: sessions)
                        .frame(height: 160)
                }
            }

            // Climbing Type Selector
            ClimbingTypeSelector(selectedType: $selectedClimbingType)
                .padding(.horizontal, 20)

            // Difficulty Progression Chart
            InsightCard(title: "progress.difficultyProgression".localized) {
                DifficultyProgressionChart(
                    sessions: sessions,
                    climbingType: selectedClimbingType
                )
            }

            // Difficulty Distribution Chart
            InsightCard(title: "progress.difficultyDistribution".localized) {
                DifficultyDistributionChart(
                    sessions: sessions,
                    climbingType: selectedClimbingType
                )
            }
        }
    }
}

// MARK: - Session Highlights Section

struct SessionHighlightsSection: View {
    let sessions: [ClimbingSession]

    private var longestSession: ClimbingSession? {
        sessions.max(by: { $0.duration < $1.duration })
    }

    private var mostProductiveSession: ClimbingSession? {
        sessions.max(by: { $0.routes.count < $1.routes.count })
    }

    private var personalBest: RouteDifficulty? {
        let allRoutes = sessions.flatMap { $0.routes }
        let completedRoutes = allRoutes.filter {
            $0.result == .onsight || $0.result == .flash || $0.result == .send
        }
        let difficulties = completedRoutes.compactMap { $0.difficulty }

        let allGrades = RouteDifficulty.boulderingGrades + RouteDifficulty.sportGrades
        return difficulties.max(by: { a, b in
            let indexA = allGrades.firstIndex(of: a) ?? 0
            let indexB = allGrades.firstIndex(of: b) ?? 0
            return indexA < indexB
        })
    }

    var body: some View {
        VStack(spacing: 20) {
            InsightSectionHeader(title: "highlights.title".localized, icon: "star.fill")

            VStack(spacing: 12) {
                if let session = longestSession {
                    HighlightCard(
                        icon: "🧗",
                        title: "highlights.longestSession".localized,
                        value: session.duration.toHours.formatAsHoursLong(),
                        subtitle: session.date?.formatted(date: .abbreviated, time: .omitted) ?? "",
                        message: String(format: "highlights.longestMessage".localized, session.duration.toHours.formatAsHoursLong()),
                        session: session
                    )
                }

                if let session = mostProductiveSession {
                    let routesText = "\(session.routes.count) " + (session.routes.count == 1 ? "logbook.route".localized : "logbook.routes".localized)
                    HighlightCard(
                        icon: "⚡",
                        title: "highlights.mostProductive".localized,
                        value: routesText,
                        subtitle: session.date?.formatted(date: .abbreviated, time: .omitted) ?? "",
                        message: String(format: "highlights.productiveMessage".localized, session.routes.count),
                        session: session
                    )
                }

                if let grade = personalBest {
                    PersonalBestCard(
                        icon: "🏅",
                        title: "highlights.personalBest".localized,
                        value: grade.rawValue,
                        message: "highlights.bestMessage".localized
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Motivational Insights Section

struct MotivationalInsightsSection: View {
    let sessions: [ClimbingSession]
    let dateRange: InsightsTabView.DateRange

    private var insights: [String] {
        var messages: [String] = []

        // Frequency insight
        if sessions.count >= 10 {
            messages.append("motivation.frequent".localized)
        } else if sessions.count >= 5 {
            messages.append("motivation.consistent".localized)
        } else if sessions.count <= 2 {
            messages.append("motivation.easyGoing".localized)
        }

        // Grade progression insight
        let allGrades = sessions.flatMap { $0.routes }.compactMap { $0.difficulty }
        if !allGrades.isEmpty {
            messages.append("motivation.journey".localized)
        }

        // Consistency insight
        let calendar = Calendar.current
        let uniqueWeeks = Set(sessions.compactMap { session -> Int? in
            guard let date = session.date else { return nil }
            return calendar.component(.weekOfYear, from: date)
        })

        if uniqueWeeks.count >= 3 {
            messages.append("motivation.routine".localized)
        }

        return messages.isEmpty ? ["motivation.beginning".localized] : messages
    }

    var body: some View {
        VStack(spacing: 20) {
            InsightSectionHeader(title: "motivation.title".localized, icon: "flame.fill")

            VStack(spacing: 12) {
                ForEach(Array(insights.prefix(3).enumerated()), id: \.offset) { index, message in
                    MotivationalCard(message: message, index: index)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Supporting Components

struct InsightSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(.blue)

            Text(title)
                .font(.title3)
                .fontWeight(.bold)

            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

struct InsightCard<Content: View>: View {
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
                .padding(.horizontal, 20)

            content
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )
                .padding(.horizontal, 20)
        }
    }
}

struct ProgressIndicatorCard: View {
    let value: String
    let label: String
    //let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
 
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)

                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct ClimbingTypeSelector: View {
    @Binding var selectedType: ClimbingType

    var body: some View {
        HStack(spacing: 12) {
            ForEach([ClimbingType.bouldering, ClimbingType.sport], id: \.self) { type in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedType = type
                    }
                }) {
                    Text(type.localizedName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedType == type ? .white : .primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(selectedType == type ? Color.blue : Color(.systemGray6))
                        .cornerRadius(20)
                }
            }
        }
    }
}

struct HighlightCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let message: String
    @ObservedObject var session: ClimbingSession

    var body: some View {
        NavigationLink(destination: SessionDetailView(session: session)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Text(icon)
                        .font(.system(size: 40))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text(value)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PersonalBestCard: View {
    let icon: String
    let title: String
    let value: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(icon)
                    .font(.system(size: 40))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(value)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }

                Spacer()
            }

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

struct MotivationalCard: View {
    let message: String
    let index: Int

    private var gradient: LinearGradient {
        let colors: [[Color]] = [
            [Color.blue.opacity(0.1), Color.blue.opacity(0.05)],
            [Color.green.opacity(0.1), Color.green.opacity(0.05)],
            [Color.orange.opacity(0.1), Color.orange.opacity(0.05)]
        ]
        let selectedColors = colors[index % colors.count]
        return LinearGradient(colors: selectedColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundColor(.blue)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(3)

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(gradient)
        )
    }
}

struct EmptyInsightsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("insights.noClimbs".localized)
                .font(.title3)
                .fontWeight(.semibold)

            Text("insights.storyStarts".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            NavigationLink(destination: LogbookTabView()) {
                Text("insights.logFirstSession".localized)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 40)
    }
}

#Preview {
    InsightsTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

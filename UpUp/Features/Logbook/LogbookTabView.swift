import SwiftUI
import CoreData

struct LogbookTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClimbingSession.date, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<ClimbingSession>

    @State private var searchText = ""
    @State private var showingLogView = false
    @State private var selectedFilter: EnvironmentFilter = .all
    @FocusState private var isSearchFocused: Bool

    enum EnvironmentFilter: String, CaseIterable {
        case all = "All"
        case indoor = "Indoor"
        case outdoor = "Outdoor"
    }

    // Month formatter - uses localized date formatting
    private var monthFormatter: DateFormatter {
        LocalizationManager.shared.localizedDateFormatter(dateStyle: .long)
    }

    private func monthString(from date: Date) -> String {
        date.localizedFormatCustom("MMMM yyyy")
    }

    // Convert sessions to array once for performance
    private var allSessionsArray: [ClimbingSession] {
        Array(sessions)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("logbook.search".localized, text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .focused($isSearchFocused)
                        .submitLabel(.search)
                        .autocorrectionDisabled()

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.body)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.tertiarySystemBackground))
                )
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .animation(.easeInOut(duration: 0.2), value: searchText.isEmpty)
                .contentShape(Rectangle())
                .onTapGesture {
                    isSearchFocused = true
                }
/*
                // Filter Bar
                HStack(spacing: 12) {
                    ForEach(EnvironmentFilter.allCases, id: \.self) { filter in
                        FilterButton(
                            title: filter.rawValue,
                            isSelected: selectedFilter == filter,
                            action: {
                                selectedFilter = filter
                                isSearchFocused = false
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                Divider()
*/
                // Timeline Content
                if groupedSessions.isEmpty {
                    EmptyLogbookView()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isSearchFocused = false
                        }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
                            ForEach(groupedSessions, id: \.month) { monthGroup in
                                Section(header: MonthHeader(monthString: monthGroup.month, sessionCount: monthGroup.sessions.count)) {
                                    VStack(spacing: 12) {
                                        ForEach(monthGroup.sessions, id: \.id) { session in
                                            TimelineSessionCard(session: session, allSessions: allSessionsArray)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    .onTapGesture {
                        isSearchFocused = false
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            isSearchFocused = false
                        }
                    )
                }
            }
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isSearchFocused = false
                    }
            )
            .navigationTitle("tab.logbook".localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isSearchFocused = false
                        showingLogView = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingLogView) {
                SessionLogSheet(mode: .create, themeColor: DesignTokens.Colors.logbookAccent)
            }
        }
    }

    // MARK: - Computed Properties

    private var filteredSessions: [ClimbingSession] {
        // Early return for no filtering needed
        guard selectedFilter != .all || !searchText.isEmpty else {
            return Array(sessions)
        }

        var filtered = Array(sessions)

        // Filter by environment
        if selectedFilter != .all {
            let targetEnvironment = selectedFilter == .indoor ? ClimbingEnvironment.indoor : ClimbingEnvironment.outdoor
            filtered = filtered.filter { $0.environment == targetEnvironment }
        }

        // Filter by search text
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            filtered = filtered.filter { session in
                // Search in location
                if let location = session.location, location.lowercased().contains(searchLower) {
                    return true
                }

                // Search in notes
                if let notes = session.notes, notes.lowercased().contains(searchLower) {
                    return true
                }

                // Search in environment (indoor/outdoor)
                if let environment = session.environment {
                    if environment.rawValue.lowercased().contains(searchLower) {
                        return true
                    }
                }

                // Search in climbing type (bouldering/sport)
                let climbingTypes = session.routes.compactMap { $0.difficulty?.climbingType.rawValue.lowercased() }
                if climbingTypes.contains(where: { $0.contains(searchLower) }) {
                    return true
                }

                // Search in route difficulties
                let routeGrades = session.routes.compactMap { $0.difficulty?.rawValue.lowercased() }
                if routeGrades.contains(where: { $0.contains(searchLower) }) {
                    return true
                }

                return false
            }
        }

        return filtered
    }

    private var groupedSessions: [(month: String, sessions: [ClimbingSession])] {
        var grouped: [String: [ClimbingSession]] = [:]

        for session in filteredSessions {
            guard let date = session.date else { continue }
            let monthKey = monthString(from: date)

            if grouped[monthKey] == nil {
                grouped[monthKey] = []
            }
            grouped[monthKey]?.append(session)
        }

        // Sort by month (most recent first) using the original dates
        var groupedWithDates: [(month: String, sessions: [ClimbingSession], date: Date)] = []
        for (month, sessions) in grouped {
            if let firstDate = sessions.first?.date {
                groupedWithDates.append((month: month, sessions: sessions, date: firstDate))
            }
        }

        return groupedWithDates
            .sorted { $0.date > $1.date }
            .map { (month: $0.month, sessions: $0.sessions) }
    }
}

// MARK: - Supporting Views

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .cornerRadius(20)
        }
    }
}

struct MonthHeader: View {
    let monthString: String
    let sessionCount: Int

    var body: some View {
        HStack {
            Text(monthString)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Spacer()

            Text("\(sessionCount) \(sessionCount == 1 ? "logbook.session".localized : "logbook.sessions".localized)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

struct TimelineSessionCard: View {
    @ObservedObject var session: ClimbingSession
    let allSessions: [ClimbingSession]
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false

    private var dateString: String {
        guard let date = session.date else { return "logbook.unknown".localized }
        return date.localizedFormatCustom("EEE, MMM d")
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

    private var milestone: (grade: String, result: RouteResult)? {
        guard let sessionDate = session.date else { return nil }

        // Get all completed routes in this session
        let completedRoutes = session.routes.compactMap { route -> (difficulty: RouteDifficulty, result: RouteResult)? in
            guard let difficulty = route.difficulty,
                  let result = route.result,
                  result == .onsight || result == .flash || result == .send else { return nil }
            return (difficulty, result)
        }

        guard !completedRoutes.isEmpty else { return nil }

        // Build a set of all previous completions for faster lookup
        var previousCompletions: Set<String> = []
        for otherSession in allSessions {
            guard let otherDate = otherSession.date, otherDate < sessionDate else { continue }

            for route in otherSession.routes {
                guard let difficulty = route.difficulty, let result = route.result else { continue }

                switch result {
                case .onsight:
                    previousCompletions.insert("\(difficulty.rawValue)-onsight")
                    previousCompletions.insert("\(difficulty.rawValue)-flash")
                    previousCompletions.insert("\(difficulty.rawValue)-send")
                case .flash:
                    previousCompletions.insert("\(difficulty.rawValue)-flash")
                    previousCompletions.insert("\(difficulty.rawValue)-send")
                case .send:
                    previousCompletions.insert("\(difficulty.rawValue)-send")
                case .fail:
                    break
                }
            }
        }

        // Check each completed route for a milestone
        for (difficulty, result) in completedRoutes {
            let key = "\(difficulty.rawValue)-\(result.rawValue.lowercased())"
            if !previousCompletions.contains(key) {
                return (difficulty.rawValue, result)
            }
        }

        return nil
    }

    var body: some View {
            NavigationLink(destination: SessionDetailView(session: session)) {
                HStack(spacing: 0) {
                    // Left Timeline Indicator
                    VStack {
                        Text(session.mood ?? "😊")
                            .font(.caption)

                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 2)
                    }
                    .frame(width: 20)

                    // Card Content
                    VStack(alignment: .leading, spacing: 8) {
                        // Date and Mood
                        HStack {
                            Text(dateString)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Spacer()


                            // Location
                            if let environment = session.environment {
                                HStack(spacing: 6) {
                                    Image(systemName: environment == .indoor ? "building.2.fill" : "mountain.2.fill")
                                        .font(.caption)
                                        .foregroundColor(environment == .indoor ? .blue:.green)

                                    if let location = session.location, !location.isEmpty {
                                        Text(location)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }

                        }

                        // Milestone Badge
                        if let milestone = milestone {
                            HStack(spacing: 4) {
                                Text("🎉")
                                    .font(.caption)
                                Text(milestoneText(for: milestone))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(6)
                        }


                        // Stats Row
                        HStack(spacing: 16) {
                            // Routes
                            HStack(spacing: 4) {
                                Text(session.duration.toHours.formatAsHours())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("·")
                                Text("\(session.routes.count) \(session.routes.count == 1 ? "logbook.route".localized : "logbook.routes".localized)")
                                    .font(.caption)
                                // Total attempts
                                if totalAttempts > 0 {
                                    HStack {
                                        Text("·")
                                        Text("\(totalAttempts) \("route.attemptstimes".localized)")
                                            .font(.caption)
                                    }
                                }
                            }
                            .foregroundColor(.secondary)
                            }
                            //Spacer()
                        if let notes = session.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.caption)
                                .italic()
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.tertiarySystemBackground))
                    )
                    .padding(.leading, 8)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .contextMenu {
                Button {
                    showingEditSheet = true
                } label: {
                    Label("common.edit".localized, systemImage: "pencil")
                }

                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("common.delete".localized, systemImage: "trash")
                }
            }
            .alert("sessionDetail.deleteSession".localized, isPresented: $showingDeleteAlert) {
                Button("common.delete".localized, role: .destructive) {
                    deleteSession()
                }
                Button("common.cancel".localized, role: .cancel) { }
            } message: {
                Text("sessionDetail.deleteConfirm".localized)
            }
            .sheet(isPresented: $showingEditSheet) {
                SessionLogSheet(mode: .edit(session), themeColor: .blue)
            }
        }

        private func milestoneText(for milestone: (grade: String, result: RouteResult)) -> String {
            switch milestone.result {
            case .send:
                return String(format: "logbook.firstSend".localized, milestone.grade)
            case .flash:
                return String(format: "logbook.firstFlash".localized, milestone.grade)
            case .onsight:
                return String(format: "logbook.firstOnsight".localized, milestone.grade)
            case .fail:
                return ""
            }
        }

        private func deleteSession() {
            withAnimation {
                viewContext.delete(session)
                do {
                    try viewContext.save()
                } catch {
                    print("Error deleting session: \(error)")
                }
            }
        }
    }

struct EmptyLogbookView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("logbook.noSessionsYet".localized)
                .font(.title3)
                .fontWeight(.semibold)

            Text("logbook.startLogging".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    LogbookTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

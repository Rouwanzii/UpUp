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

    // Shared date formatter - created once and reused
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search location, notes, grade...", text: $searchText)
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
                .background(Color(.systemGray6))
                .cornerRadius(10)
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
                                            TimelineSessionCard(session: session)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        .padding(.vertical, 16)
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
            .navigationTitle("Logbook")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingLogView = true }) {
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
            let monthKey = monthFormatter.string(from: date)

            if grouped[monthKey] == nil {
                grouped[monthKey] = []
            }
            grouped[monthKey]?.append(session)
        }

        // Sort by month (most recent first)
        return grouped.map { (month: $0.key, sessions: $0.value) }
            .sorted { (group1, group2) -> Bool in
                guard let date1 = monthFormatter.date(from: group1.month),
                      let date2 = monthFormatter.date(from: group2.month) else {
                    return false
                }
                return date1 > date2
            }
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

            Text("\(sessionCount) session\(sessionCount == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }
}

struct TimelineSessionCard: View {
    @ObservedObject var session: ClimbingSession
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false

    // Shared date formatter
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }()

    private var dateString: String {
        guard let date = session.date else { return "Unknown" }
        return Self.dateFormatter.string(from: date)
    }

    private var highestGrade: String {
        let completed = session.routes.filter {
            $0.result == .onsight || $0.result == .flash || $0.result == .send
        }.compactMap { $0.difficulty }

        guard !completed.isEmpty else { return "-" }

        let allGrades = RouteDifficulty.boulderingGrades + RouteDifficulty.sportGrades
        guard let maxGrade = completed.max(by: { a, b in
            let indexA = allGrades.firstIndex(of: a) ?? 0
            let indexB = allGrades.firstIndex(of: b) ?? 0
            return indexA < indexB
        }) else { return "-" }

        return maxGrade.rawValue
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
                                .font(.headline)
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
                                    /*
                                    else {
                                        Text(environment.rawValue)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                     */
                                }
                            }

                        }


                        // Stats Row
                        HStack(spacing: 16) {
                            // Routes
                            HStack(spacing: 4) {
                                //Image(systemName: "figure.climbing")
                                //   .font(.caption)
                                
                                // Duration
                                Text(session.duration.toHours.formatAsHours())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("·")
                                Text("\(session.routes.count) route\(session.routes.count == 1 ? "" : "s")")
                                    .font(.caption)
                                // Highest grade
                                if highestGrade != "-" {
                                    HStack {
                                        //Image(systemName: "flag.fill")
                                        //.font(.caption)
                                        Text("·")
                                        Text(highestGrade)
                                            .font(.caption)
                                        //.fontWeight(.semibold)
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
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.leading, 8)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .contextMenu {
                Button {
                    showingEditSheet = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .alert("Delete Session", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    deleteSession()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this climbing session?")
            }
            .sheet(isPresented: $showingEditSheet) {
                SessionLogSheet(mode: .edit(session), themeColor: .blue)
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

            Text("No Sessions Yet")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Start logging your climbing sessions\nto track your progress")
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

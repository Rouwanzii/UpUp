import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClimbingSession.date, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<ClimbingSession>

    @State private var currentQuote = ""
    @State private var currentEmoji = ""
    @State private var showingQuickLogAlert = false
    @State private var showingDetailedLog = false
    @State private var showingTodayQuickLog = false

    let motivationalQuotes = [
        "Every mountain top is within reach if you just keep climbing.",
        "The best climber is the one having the most fun.",
        "Mountains have a way of dealing with overconfidence.",
        "You cannot stay on the summit forever; you have to come down again.",
        "The summit is what drives us, but the climb itself is what matters.",
        "Don't limit your challenges, challenge your limits.",
        "Climb mountains not so the world can see you, but so you can see the world.",
        "What goes up must come down. But what comes down must go up again.",
        "Rock climbing is not just a sport, it's a way of life.",
        "The mountains are calling and I must go.",
        "Because in the end, you won’t remember the time you spent working in an office or mowing the lawn. Climb that goddamn mountain.",
        "Today is your day! Your mountain is waiting, So… get on your way!",
        "The world is big, and I want to have a good look at it before it gets dark.",
        "we go out because it is our nature to go out",
        "Getting to the top is optional. Getting down is mandatory.",
        "If you think you've peaked, find a new mountain.",
        "Even a bad day of climbing is better than a good day at work.",
        "We should be less afraid to be afraid.",
        "Dare to live the dreams you have dreamed for yourself."
        
    ]
    
    let motivationalEmojis = [
        "🔥","🫡","💪","🦾","🧗","⛰️"
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Motivational Quote
                    VStack {
                        Text(currentQuote)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal,20)
                            .padding(.vertical,20)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.top,10)
                    .padding(.horizontal, 20)

                    // Today's Training Status
                    TodayTrainingCard(
                        hasLoggedToday: hasLoggedToday,
                        onQuickLog: {showingTodayQuickLog = true}
                    )
                    .padding(.horizontal, 20)

                    // Monthly Calendar Card
                    NavigationLink(destination: MonthlyCalendarPageView()) {
                        MonthlyCalendarCardContent(sessionsThisMonth: sessionsThisMonth)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 20)

                    // Recent Sessions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Sessions")
                            .font(.headline)
                            .padding(.leading, 20)

                        // iOS Notes-style list with auto height
                        VStack(spacing: 0) {
                            List {
                                ForEach(Array(sessions.prefix(50)), id: \.id) { session in
                                    HomeSessionRow(session: session)
                                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                }
                            }
                            .listStyle(PlainListStyle())
                            .scrollDisabled(true) // Disable list scrolling
                            .frame(height: CGFloat(min(sessions.count, 50)) * 100) // Auto height based on content with more room per row
                        }
                        .padding(.horizontal, 20)
                    }
                    //Spacer()
                    
                    // Quick Actions
                    HStack(spacing: 12) {
                        Button(action: { showingDetailedLog = true }) {
                            HStack {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.title2)
                                Text("Log History Sessions")
                                    .font(.headline)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(UIColor.systemTeal))
                            .foregroundColor(Color(UIColor.systemBackground))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("UpLog")

            .onAppear {
                if currentQuote.isEmpty {
                    currentQuote = motivationalQuotes.randomElement() ?? motivationalQuotes[0]
                if currentEmoji.isEmpty {
                    currentEmoji = motivationalEmojis.randomElement() ?? motivationalEmojis[0]
                    }
                }
            }
            .alert("Session Logged!", isPresented: $showingQuickLogAlert) {
                Button("OK") { }
            } message: {
                Text("Great work! Your 1-hour training session has been logged for today.")
            }
            .sheet(isPresented: $showingDetailedLog) {
                SessionLogSheet(mode: .create, themeColor: DesignTokens.Colors.logbookAccent)
            }
            .sheet(isPresented: $showingTodayQuickLog) {
                SessionLogSheet(
                    mode: .quickLog(Date()),
                    themeColor: DesignTokens.Colors.homeAccent,
                    showDatePicker: false,
                    moods: ["😊", "💪", "🔥", "😤", "⚡", "🥵", "😎", "🎯"]
                )
            }
        }
    }

    private func quickLogOneHour() {
        let newSession = ClimbingSession(context: viewContext)
        newSession.id = UUID()
        newSession.date = Date()
        newSession.duration = 60 // 1 hour = 60 minutes
        newSession.mood = "💪" // Default energetic mood for quick log
        newSession.notes = nil

        do {
            try viewContext.save()
            showingQuickLogAlert = true
        } catch {
            print("Error saving quick log session: \(error)")
        }
    }

    private var totalHours: Double {
        sessions.reduce(0) { total, session in
            total + Double(session.duration) / 60.0
        }
    }

    private var sessionsThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now

        return sessions.filter { session in
            guard let sessionDate = session.date else { return false }
            return sessionDate >= startOfMonth
        }.count
    }

    private var sessionsThisWeek: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now

        return sessions.filter { session in
            guard let sessionDate = session.date else { return false }
            return sessionDate >= startOfWeek
        }.count
    }

    private var hasLoggedToday: Bool {
        let calendar = Calendar.current
        let today = Date()

        return sessions.contains { session in
            guard let sessionDate = session.date else { return false }
            return calendar.isDate(sessionDate, inSameDayAs: today)
        }
    }
}

// QuickStatCard is now in Shared/Components/StatCards.swift

struct TodayTrainingCard: View {
    @State private var currentEmoji = ""
    
    let hasLoggedToday: Bool
    let onQuickLog: () -> Void
    let motivationalEmojis = [
        "🔥","🫡","💪","🦾","🧗","⛰️"
    ]

    var body: some View {
        VStack(spacing: 12) {
            if hasLoggedToday {
                HStack {
                    Text("🎉")
                        .font(.title)
                    VStack(alignment: .leading) {
                        Text("Session Completed for Today!")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.bottom, 2)
                        Text("Great work on your training!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            } else {
                VStack(spacing: 12) {
                    HStack {
                        Text(currentEmoji)
                            .font(.title)
                        VStack(alignment: .leading) {
                            Text("How are you today?")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("Ready for some climbing?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .onAppear {
                        if currentEmoji.isEmpty {
                            currentEmoji = motivationalEmojis.randomElement() ?? motivationalEmojis[0]
                            }
                        }
                    
                    Button(action: onQuickLog) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Quick Log for Today")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .background(hasLoggedToday ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

// TodayQuickLogView has been replaced by SessionLogSheet

struct HomeSessionRow: View {
    @ObservedObject var session: ClimbingSession
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false

    var body: some View {
        ZStack {
            NavigationLink(destination: SessionDetailView(session: session)) {
                EmptyView()
            }
            .opacity(0)

            HStack(spacing: 12) {
                // 左边 emoji 心情
                Text(session.mood ?? "😊")
                    .font(.title2)

                // 中间信息
                VStack(alignment: .leading, spacing: 6) {
                    HStack(){
                        Text(session.duration.toHours.formatAsHoursLong())
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(session.date?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Routes summary
                    if !session.routes.isEmpty {
                        HStack {
                            Text("Routes: ")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(routesSummary(session.routes))
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    if let notes = session.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }

        // 👇 只有左滑该行时才显示按钮
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                showingDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)

            Button {
                showingEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
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

    private func routesSummary(_ routes: [ClimbingRoute]) -> String {
        let routesWithDifficulty = routes.compactMap { $0.difficulty?.displayName }
        if routesWithDifficulty.isEmpty {
            return "\(routes.count) route\(routes.count == 1 ? "" : "s")"
        } else {
            return routesWithDifficulty.prefix(3).joined(separator: ", ") + (routesWithDifficulty.count > 3 ? "..." : "")
        }
    }
}

struct MonthlyCalendarCardContent: View {
    let sessionsThisMonth: Int

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 36))
                .foregroundColor(.blue)
                .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text("Monthly Calendar")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text("\(sessionsThisMonth) session\(sessionsThisMonth == 1 ? "" : "s") this month")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

struct MonthlyCalendarPageView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClimbingSession.date, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<ClimbingSession>

    @State private var selectedDate: Date = Date()
    @State private var showingQuickLog = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                MonthlyCalendar(sessions: Array(sessions), selectedDate: $selectedDate)
                    .padding()

                // Selected Date Session Display
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Sessions on \(selectedDateFormatted)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        if sessionsForSelectedDate.isEmpty {
                            Button("Quick Log") {
                                showingQuickLog = true
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange)
                            .cornerRadius(8)
                        }
                    }

                    if sessionsForSelectedDate.isEmpty {
                        if selectedDate > Date() {
                            Text("We are young, we still have tomorrow.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .italic()
                                .padding(.vertical, 8)
                        } else {
                            Text("No sessions recorded for this day")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        }
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(sessionsForSelectedDate, id: \.id) { session in
                                SessionRowForDate(session: session)
                            }
                        }
                    }
                }
                .padding(.all, 16)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
            .padding(.vertical)
        }
        .navigationTitle("Monthly Calendar")
        .navigationBarTitleDisplayMode(.automatic)
        .sheet(isPresented: $showingQuickLog) {
            SessionLogSheet(mode: .quickLog(selectedDate), themeColor: DesignTokens.Colors.homeAccent, showDatePicker: false)
        }
    }

    private var selectedDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }

    private var sessionsForSelectedDate: [ClimbingSession] {
        let calendar = Calendar.current
        return sessions.filter { session in
            guard let sessionDate = session.date else { return false }
            return calendar.isDate(sessionDate, inSameDayAs: selectedDate)
        }
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

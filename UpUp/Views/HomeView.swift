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
                        Text(currentEmoji)
                            .font(.largeTitle)
                            .padding(.top,20)
                            .padding(.bottom,10)
                        Text(currentQuote)
                            .font(.headline)
                            .italic()
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal,20)
                            .padding(.bottom,20)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.top,10)
                    .padding(.horizontal, 20)

                    // Today's Training Status
                    TodayTrainingCard(
                        hasLoggedToday: hasLoggedToday,
                        onQuickLog: { showingTodayQuickLog = true}
                    )
                    .padding(.horizontal, 20)

                    // Quick Stats
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                        /*
                        QuickStatCard(value: "\(sessions.count)", title: "Total Sessions")
                        QuickStatCard(value: String(format: "%.1f", totalHours), title: "Total Hours")
                         */
                        QuickStatCard(value: "\(sessionsThisMonth)", title: "Sessions This Month")
                        QuickStatCard(value: "\(sessionsThisWeek)", title: "Sessions This Week")
                    }
                    .padding(.horizontal, 20)
                
                    // Recent Sessions
                    VStack(alignment: .leading) {
                        Text("Recent Sessions")
                            .font(.headline)
                            .padding(.leading, 20)

                        List {
                            ForEach(Array(sessions.prefix(5)), id: \.id) { session in
                                HomeSessionRow(session: session)
                                    .listRowInsets(EdgeInsets())
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                            }
                        }
                        .listStyle(PlainListStyle())
                        .frame(height: CGFloat(min(sessions.prefix(5).count, 5)) * 80)
                        .padding(.horizontal, 20)
                    }
                    Spacer()
                    
                    // Quick Actions
                    HStack(spacing: 12) {
                        // Detailed Log Button
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
                            .background(Color.primary)
                            .foregroundColor(.white)
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
                LogView()
            }
            .sheet(isPresented: $showingTodayQuickLog) {
                TodayQuickLogView()
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

struct QuickStatCard: View {
    let value: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

struct TodayTrainingCard: View {
    let hasLoggedToday: Bool
    let onQuickLog: () -> Void

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
                        Text("Great work on your training!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            } else {
                VStack(spacing: 12) {
                    HStack {
                        Text("🧗")
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

struct TodayQuickLogView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var duration = "60"
    @State private var selectedMood = "💪"
    @State private var notes = ""

    let moods = ["😊", "💪", "🔥", "😤", "⚡", "🥵", "😎", "🎯"]

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Quick Log for Today")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Duration")
                        .font(.headline)
                    HStack {
                        TextField("Duration", text: $duration)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                        Text("minutes")
                            .foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("How was your session?")
                        .font(.headline)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4)) {
                        ForEach(moods, id: \.self) { mood in
                            Button(action: {
                                selectedMood = mood
                            }) {
                                Text(mood)
                                    .font(.title)
                                    .frame(width: 50, height: 50)
                                    .background(selectedMood == mood ? Color.orange.opacity(0.3) : Color.gray.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Notes (optional)")
                        .font(.headline)
                    TextEditor(text: $notes)
                        .frame(height: 80)
                        .padding(4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }

                Spacer()

                HStack(spacing: 12) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(10)

                    Button("Save Session") {
                        saveSession()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding()
        }
    }

    private func saveSession() {
        guard let durationInt = Int32(duration), durationInt > 0 else { return }

        let newSession = ClimbingSession(context: viewContext)
        newSession.id = UUID()
        newSession.date = Date()
        newSession.duration = durationInt
        newSession.mood = selectedMood
        newSession.notes = notes.isEmpty ? nil : notes

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving session: \(error)")
        }
    }
}


struct HomeSessionRow: View {
    let session: ClimbingSession
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false

    var body: some View {
        HStack(spacing: 12) {
            // 左边 emoji 心情
            Text(session.mood ?? "😊")
                .font(.title2)

            // 中间信息
            VStack(alignment: .leading, spacing: 6) {
                HStack(){
                    Text("\(session.duration) minutes")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(session.date?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
        
        // 👇 只有左滑该行时才显示按钮
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
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
            EditSessionView(session: session)
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
/*
struct SessionRow: View {
    let session: ClimbingSession

    var body: some View {
        HStack {
            Text(session.mood ?? "😊")
                .font(.title2)

            VStack(alignment: .leading) {
                Text(session.date?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown")
                    .font(.headline)
                Text("\(session.duration) minutes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let notes = session.notes, !notes.isEmpty {
                Image(systemName: "note.text")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct HomeSessionRow: View {
    let session: ClimbingSession
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false

    var body: some View {
        HStack {
            Text(session.mood ?? "😊")
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                if let notes = session.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                HStack(alignment: .center) {
                    Text(session.date?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(session.duration) minutes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                }
            }

            Spacer()

            // Action buttons

            HStack(spacing: 8) {
                Button(action: { showingEditSheet = true }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }

                Button(action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }

        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        // 左滑才显示按钮
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                showingEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)

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
            EditSessionView(session: session)
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

*/

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

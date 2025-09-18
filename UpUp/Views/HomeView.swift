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
        "The rock will always be there. The trick is to be there too."
    ]
    
    let motivationalEmojis = [
        "🔥","🥰","🫡","💪","🦾","🧗"
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
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal,20)
                            .padding(.bottom,20)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.top,10)
                    .padding(.horizontal)
                    
/*
                    // Quick Stats
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                        StatCard(title: "Total Sessions", value: "\(sessions.count)", icon: "🧗‍♀️")
                        StatCard(title: "Total Hours", value: String(format: "%.1f", totalHours), icon: "⏱️")
                        StatCard(title: "This Month", value: "\(sessionsThisMonth)", icon: "📅")
                        StatCard(title: "This Week", value: "\(sessionsThisWeek)", icon: "📊")
                    }
                    .padding(.horizontal)
 */
                    
                    // Quick Stats
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("\(sessions.count)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                                Text("Total Sessions")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                //Text("🧗‍♀️")
                                //    .font(.title2)
                            }
                        }
                        .padding()
                        .padding(.horizontal,10)
                        .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(10)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                //Text("⏱️")
                                //    .font(.title2)
                                Text(String(format: "%.1f", totalHours))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                                Text("Total Hours")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                        }
                        .padding()
                        .padding(.horizontal,10)
                        .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(10)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("\(sessionsThisMonth)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                //Text("📅")
                                //    .font(.title2)
                                Spacer()
                                Text("This Month")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .padding(.horizontal,10)
                        .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(10)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("\(sessionsThisWeek)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                //Text("📊")
                                //    .font(.title2)
                                Spacer()
                                Text("This Week")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .padding(.horizontal,10)
                        .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)


                    // 7-Day Trend Chart
                    VStack(alignment: .leading) {
                        Text("7-Day Activity")
                            .font(.headline)
                            .padding(.leading)
                            //.padding(.leading)

                        SevenDayChart(sessions: Array(sessions))
                            .frame(height: 100)
                            .padding(.horizontal)
                    }

                    // Annual Heatmap
                    VStack(alignment: .leading) {
                        Text("Monthly Training Heatmap")
                            .font(.headline)
                            .padding(.leading)

                        HeatmapView(sessions: Array(sessions))
                            .padding(.horizontal)
                    }

                    // Recent Sessions
                    VStack(alignment: .leading) {
                        Text("Recent Sessions")
                            .font(.headline)
                            .padding(.leading)

                        LazyVStack {
                            ForEach(Array(sessions.prefix(5)), id: \.id) { session in
                                SessionRow(session: session)
                            }
                        }
                        .padding(.horizontal)
                    }

                    Spacer()
                }
            }
            .navigationTitle("UpUp")
            .onAppear {
                if currentQuote.isEmpty {
                    currentQuote = motivationalQuotes.randomElement() ?? motivationalQuotes[0]
                if currentEmoji.isEmpty {
                    currentEmoji = motivationalEmojis.randomElement() ?? motivationalEmojis[0]
                    }
                }
            }
            
        }
        .padding(.horizontal,20)
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
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack {
            Text(icon)
                .font(.title)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

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

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

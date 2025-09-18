import SwiftUI
import CoreData

struct StatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClimbingSession.date, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<ClimbingSession>

    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack {
                // Tab picker for different views
                Picker("Stats View", selection: $selectedTab) {
                    Text("Recent").tag(0)
                    Text("Weekly").tag(1)
                    Text("Monthly").tag(2)
                    Text("6-Month").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // Content based on selected tab
                ScrollView {
                    switch selectedTab {
                    case 0:
                        RecentSessionsView(sessions: Array(sessions))
                    case 1:
                        WeeklyStatsView(sessions: Array(sessions))
                    case 2:
                        MonthlyCalendarView(sessions: Array(sessions))
                    case 3:
                        HalfYearlyHeatmapView(sessions: Array(sessions))
                    default:
                        RecentSessionsView(sessions: Array(sessions))
                    }
                }
            }
            .navigationTitle("Statistics")
        }
    }
}

struct RecentSessionsView: View {
    let sessions: [ClimbingSession]
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingDeleteAlert = false
    @State private var sessionToDelete: ClimbingSession?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Sessions")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            LazyVStack(spacing: 8) {
                ForEach(sessions.prefix(20), id: \.id) { session in
                    EditableSessionRow(session: session)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct EditableSessionRow: View {
    let session: ClimbingSession
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false

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

            // Edit and Delete buttons
            SessionActionButtons(
                onEdit: { showingEditSheet = true },
                onDelete: { showingDeleteAlert = true }
            )
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
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

struct WeeklyStatsView: View {
    let sessions: [ClimbingSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Statistics")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            WeeklyBarChart(sessions: sessions)
                .padding(.horizontal)
        }
    }
}

struct MonthlyCalendarView: View {
    let sessions: [ClimbingSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Calendar")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            MonthlyCalendar(sessions: sessions)
                .padding(.horizontal)
        }
    }
}

struct HalfYearlyHeatmapView: View {
    let sessions: [ClimbingSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("6-Month Activity Heatmap")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            SixMonthHeatmap(sessions: sessions)
                .padding(.horizontal)
        }
    }
}

struct SessionActionButtons: View {
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }
}

#Preview {
    StatsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
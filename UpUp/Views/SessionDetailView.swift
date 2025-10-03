import SwiftUI
import CoreData

struct SessionDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingEditView = false

    let session: ClimbingSession

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Session Info Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Session Details")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(formattedDate)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if let mood = session.mood {
                            Text(mood)
                                .font(.largeTitle)
                        }
                    }

                    Divider()

                    // Duration
                    HStack {
                        Label("Duration", systemImage: "clock.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Double(session.duration) / 60.0, specifier: "%.1f") hours")
                            .font(.body)
                            .fontWeight(.medium)
                    }

                    // Location
                    if let environment = session.environment {
                        HStack {
                            Label("Environment", systemImage: environment == .indoor ? "building.2.fill" : "mountain.2.fill")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(environment.rawValue)
                                .font(.body)
                                .fontWeight(.medium)
                        }

                        if let location = session.location, !location.isEmpty {
                            HStack {
                                Label("Location", systemImage: "mappin.circle.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(location)
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // Routes Card
                if !session.routes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Routes (\(session.routes.count))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        ForEach(Array(session.routes.enumerated()), id: \.element.id) { index, route in
                            RouteDetailCard(route: route, index: index, environment: session.environment ?? .indoor)
                        }
                    }
                }

                // Notes Card
                if let notes = session.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(notes)
                            .font(.body)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Session")
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
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: session.date ?? Date())
    }
}

struct RouteDetailCard: View {
    let route: ClimbingRoute
    let index: Int
    let environment: ClimbingEnvironment

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Route \(index + 1)")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                if let result = route.result {
                    Text(result.emoji)
                        .font(.title3)
                }
            }

            // Details Grid
            VStack(alignment: .leading, spacing: 8) {
                if let difficulty = route.difficulty {
                    DetailRow(label: "Difficulty", value: difficulty.rawValue)
                }

                // Color or Name based on environment
                if environment == .indoor {
                    if let color = route.color {
                        HStack {
                            Text("Color")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Circle()
                                            .stroke(color == .white ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                                    )
                                Text(color.rawValue)
                                    .font(.body)
                            }
                        }
                    }
                } else {
                    if let name = route.name, !name.isEmpty {
                        DetailRow(label: "Route Name", value: name)
                    }
                }

                if let result = route.result {
                    DetailRow(label: "Result", value: result.rawValue)
                }

                if let attempts = route.attempts {
                    DetailRow(label: "Attempts", value: "\(attempts)")
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
    }
}

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
        return session
    }
}

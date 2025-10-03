import SwiftUI
import CoreData

struct EditSessionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let session: ClimbingSession

    @State private var selectedDate: Date
    @State private var duration: String
    @State private var selectedMood: String
    @State private var notes: String
    @State private var durationHours: Double
    @State private var routes: [ClimbingRoute]
    @State private var selectedEnvironment: ClimbingEnvironment
    @State private var locationText: String

    let moods = ["😊", "💪", "🔥", "😤", "😭", "⚡", "🥵", "😎", "🎯", "👑"]

    init(session: ClimbingSession) {
        self.session = session
        self._selectedDate = State(initialValue: session.date ?? Date())
        self._duration = State(initialValue: String(session.duration))
        self._selectedMood = State(initialValue: session.mood ?? "😊")
        self._notes = State(initialValue: session.notes ?? "")
        self._durationHours = State(initialValue: Double(session.duration) / 60.0)
        self._routes = State(initialValue: session.routes.isEmpty ? [ClimbingRoute()] : session.routes)
        self._selectedEnvironment = State(initialValue: session.environment ?? .indoor)
        self._locationText = State(initialValue: session.location ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                // Date Section
                Section {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                }

                // Session Details Section
                Section(header: Text("Session Details")) {
                    // Location
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Where did you climb?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Picker("", selection: $selectedEnvironment) {
                                ForEach(ClimbingEnvironment.allCases, id: \.self) { env in
                                    Text(env.rawValue).tag(env)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }

                        TextField(selectedEnvironment.locationPlaceholder, text: $locationText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.vertical, 4)

                    // Duration
                    HStack {
                        Text("How long is your session?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()

                        HStack(spacing: 0) {
                            Button(action: {
                                if durationHours > 0.5 {
                                    durationHours -= 0.5
                                    duration = String(Int(durationHours * 60))
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }

                            Text("\(durationHours, specifier: "%.1f") h")
                                .font(.body)
                                .frame(width: 60)

                            Button(action: {
                                durationHours += 0.5
                                duration = String(Int(durationHours * 60))
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    // Mood
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How do you feel?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(moods, id: \.self) { mood in
                                Button(action: {
                                    selectedMood = mood
                                }) {
                                    Text(mood)
                                        .font(.title2)
                                        .frame(width: 50, height: 50)
                                        .background(selectedMood == mood ? Color.green.opacity(0.3) : Color.gray.opacity(0.1))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Routes Section
                Section(header: Text("Routes")) {
                    RoutesSection(routes: $routes, environment: selectedEnvironment)
                }

                // Notes Section
                Section(header: Text("Notes (Optional)")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }

                // Save Button
                Section {
                    Button(action: saveChanges) {
                        Text("Save Changes")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canSave ? Color.green : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(!canSave)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var canSave: Bool {
        durationHours > 0 && !selectedMood.isEmpty
    }

    private func saveChanges() {
        guard let durationInt = Int32(duration), durationInt > 0 else { return }

        session.date = selectedDate
        session.duration = durationInt
        session.mood = selectedMood
        session.notes = notes.isEmpty ? nil : notes
        session.routes = routes
        session.environment = selectedEnvironment
        session.location = locationText.isEmpty ? nil : locationText

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving changes: \(error)")
        }
    }
}


#Preview {
    let context = PersistenceController.preview.container.viewContext
    let sampleSession = ClimbingSession(context: context)
    sampleSession.date = Date()
    sampleSession.duration = 90
    sampleSession.mood = "💪"
    sampleSession.notes = "Great session!"

    return EditSessionView(session: sampleSession)
        .environment(\.managedObjectContext, context)
}

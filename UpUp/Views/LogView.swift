import SwiftUI
import CoreData

struct LogView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var duration = "60"
    @State private var durationHours: Double = 1.0
    @State private var selectedMood = "😊"
    @State private var notes = ""
    @State private var showingSuccessAlert = false
    @State private var routes: [ClimbingRoute] = [ClimbingRoute()]
    @State private var selectedEnvironment: ClimbingEnvironment = .indoor
    @State private var locationText = ""

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClimbingSession.date, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<ClimbingSession>

    let moods = ["😊", "💪", "🔥", "😤", "😭", "⚡", "🥵", "😎", "🎯", "👑"]

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
                    Button(action: saveSession) {
                        Text("Save Session")
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
            .navigationTitle("Log Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Set default environment from last session
                if let lastSession = sessions.first {
                    if let lastEnvironment = lastSession.environment {
                        selectedEnvironment = lastEnvironment
                        locationText = lastSession.location ?? ""
                    }
                }
            }
        }
    }

    private var canSave: Bool {
        durationHours > 0 && !selectedMood.isEmpty
    }

    private func saveSession() {
        guard let durationInt = Int32(duration), durationInt > 0 else { return }

        let newSession = ClimbingSession(context: viewContext)
        newSession.id = UUID()
        newSession.date = selectedDate
        newSession.duration = durationInt
        newSession.mood = selectedMood
        newSession.notes = notes.isEmpty ? nil : notes
        newSession.routes = routes
        newSession.environment = selectedEnvironment
        newSession.location = locationText.isEmpty ? nil : locationText

        do {
            try viewContext.save()
            showingSuccessAlert = true
            dismiss()
        } catch {
            print("Error saving session: \(error)")
        }
    }

    private func clearForm() {
        selectedDate = Date()
        duration = "60"
        durationHours = 1.0
        selectedMood = "😊"
        notes = ""
        routes = [ClimbingRoute()]
        selectedEnvironment = .indoor
        locationText = ""
    }
}


#Preview {
    LogView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

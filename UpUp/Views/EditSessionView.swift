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
    @State private var selectedEnvironment: ClimbingEnvironment?
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
        self._selectedEnvironment = State(initialValue: session.environment)
        self._locationText = State(initialValue: session.location ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())

                    HStack {
                        Text("Duration")
                            .bold()
                        Spacer()

                        HStack(spacing: 12) {
                            Button(action: {
                                if durationHours > 0.5 {
                                    durationHours -= 0.5
                                    duration = String(Int(durationHours * 60))
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }

                            Text("\(durationHours, specifier: "%.1f") h")
                                .frame(width: 60)
                                .font(.headline)

                            Button(action: {
                                durationHours += 0.5
                                duration = String(Int(durationHours * 60))
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    

                    VStack(alignment: .leading) {
                        Text("How was your session?")
                            .bold()
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5)) {
                            ForEach(moods, id: \.self) { mood in
                                Button(action: {
                                    selectedMood = mood
                                }) {
                                    Text(mood)
                                        .font(.title)
                                        .frame(width: 50, height: 50)
                                        .background(selectedMood == mood ? Color.green.opacity(0.3) : Color.gray.opacity(0.1))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }


                RoutesSection(routes: $routes)
                .padding(.vertical, 2)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Environment (optional)")
                        .bold()

                    Picker("Environment", selection: $selectedEnvironment) {
                        Text("None").tag(nil as ClimbingEnvironment?)
                        ForEach(ClimbingEnvironment.allCases, id: \.self) { env in
                            Text(env.rawValue).tag(env as ClimbingEnvironment?)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    if let environment = selectedEnvironment {
                        TextField(environment.locationPlaceholder, text: $locationText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding(.vertical, 2)

                VStack(alignment: .leading) {
                    Text("Notes (optional)")
                        .bold()
                    TextEditor(text: $notes)
                        .frame(minHeight: 30)
                }
                .padding(.vertical, 2)

                Button(action: saveChanges) {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSave ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!canSave)
                .listRowBackground(Color.clear)
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

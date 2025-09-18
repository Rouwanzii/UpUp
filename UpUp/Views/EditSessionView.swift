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

    let moods = ["😊", "💪", "🔥", "😤", "😭", "⚡", "🥵", "😎", "🎯", "👑"]

    init(session: ClimbingSession) {
        self.session = session
        self._selectedDate = State(initialValue: session.date ?? Date())
        self._duration = State(initialValue: String(session.duration))
        self._selectedMood = State(initialValue: session.mood ?? "😊")
        self._notes = State(initialValue: session.notes ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section() {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())

                    HStack {
                        Text("Duration")
                        Spacer()
                        TextField("Minutes", text: $duration)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 100)
                        Text("min")
                    }

                    VStack(alignment: .leading) {
                        Text("How was your session?")
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

                    VStack(alignment: .leading) {
                        Text("Notes (optional)")
                        TextEditor(text: $notes)
                            .frame(minHeight: 30)
                    }
                }
                .padding(.vertical, 2)

                Button(action: saveChanges) {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
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

    private func saveChanges() {
        guard let durationInt = Int32(duration), durationInt > 0 else { return }

        session.date = selectedDate
        session.duration = durationInt
        session.mood = selectedMood
        session.notes = notes.isEmpty ? nil : notes

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
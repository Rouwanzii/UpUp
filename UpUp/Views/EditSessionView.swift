import SwiftUI
import CoreData

struct EditSessionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let session: ClimbingSession
    @State private var sessionData: SessionData

    let moods = ["😊", "💪", "🔥", "😤", "😭", "⚡", "🥵", "😎", "🎯", "👑"]

    init(session: ClimbingSession) {
        self.session = session
        self._sessionData = State(initialValue: SessionData(from: session))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SessionLogForm(
                    selectedDate: $sessionData.selectedDate,
                    durationHours: $sessionData.durationHours,
                    selectedMood: $sessionData.selectedMood,
                    notes: $sessionData.notes,
                    routes: $sessionData.routes,
                    selectedEnvironment: $sessionData.selectedEnvironment,
                    locationText: $sessionData.locationText,
                    themeColor: .blue,
                    moods: moods,
                    showDatePicker: true
                )

                // Save Button
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
                .padding()
            }
            .simultaneousGesture(
                TapGesture().onEnded {
                    hideKeyboard()
                }
            )
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
        sessionData.durationHours > 0 && !sessionData.selectedMood.isEmpty
    }

    private func saveChanges() {
        hideKeyboard()

        sessionData.save(to: session)

        do {
            // Ensure context processes pending changes
            viewContext.processPendingChanges()

            if viewContext.hasChanges {
                try viewContext.save()
            }

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

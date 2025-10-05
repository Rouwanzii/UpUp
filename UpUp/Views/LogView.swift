import SwiftUI
import CoreData

struct LogView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var sessionData = SessionData()

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClimbingSession.date, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<ClimbingSession>

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
                    themeColor: .green,
                    showDatePicker: true
                )

                // Save Button
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
                .padding()
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
                loadDefaults()
            }
        }
    }

    private var canSave: Bool {
        sessionData.durationHours > 0 && !sessionData.selectedMood.isEmpty
    }

    private func loadDefaults() {
        if let lastSession = sessions.first {
            if let lastEnvironment = lastSession.environment {
                sessionData.selectedEnvironment = lastEnvironment
                sessionData.locationText = lastSession.location ?? ""
            }
        }
    }

    private func saveSession() {
        let newSession = ClimbingSession(context: viewContext)
        newSession.id = UUID()
        sessionData.save(to: newSession)

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving session: \(error)")
        }
    }
}

#Preview {
    LogView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

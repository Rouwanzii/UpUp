import SwiftUI
import CoreData

struct LogView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDate = Date()
    @State private var duration = "60"
    @State private var durationHours: Double = 1.0
    @State private var selectedMood = "😊"
    @State private var notes = ""
    @State private var showingSuccessAlert = false

    let moods = ["😊", "💪", "🔥", "😤", "😭", "⚡", "🥵", "😎", "🎯", "👑"]

    var body: some View {
        NavigationView {
            Form {
                Section() {
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
                    

                    VStack(alignment: .leading) {
                        Text("Notes (optional)")
                        TextEditor(text: $notes)
                            .frame(minHeight: 30)
                    }
                }
                .padding(.vertical,2)

                Button(action: saveSession) {
                    Text("Save Session")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSave ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!canSave)
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Log Your Session")
                
            .alert("Session Saved!", isPresented: $showingSuccessAlert) {
                Button("OK") { clearForm() }
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

        do {
            try viewContext.save()
            showingSuccessAlert = true
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
    }
}


#Preview {
    LogView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

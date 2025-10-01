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

    let moods = ["😊", "💪", "🔥", "😤", "😭", "⚡", "🥵", "😎", "🎯", "👑"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                    
                    
                    HStack {
                        Text("How long is this session?")
                            .bold()
                        Spacer()
                        
                        HStack(spacing: 2) {
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
                            .buttonStyle(PlainButtonStyle())
                            
                            Text("\(durationHours, specifier: "%.1f") h")
                                .frame(width: 60)
                            //.font(.subheadline)
                            
                            Button(action: {
                                durationHours += 0.5
                                duration = String(Int(durationHours * 60))
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("How do you feel?")
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
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes")
                            .font(.headline)
                        TextEditor(text: $notes)
                            .frame(height: 80)
                            .padding(4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
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
                .padding()
            }
            .navigationTitle("Quick Log for today")
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

    private func saveSession() {
        guard let durationInt = Int32(duration), durationInt > 0 else { return }

        let newSession = ClimbingSession(context: viewContext)
        newSession.id = UUID()
        newSession.date = selectedDate
        newSession.duration = durationInt
        newSession.mood = selectedMood
        newSession.notes = notes.isEmpty ? nil : notes
        newSession.routes = routes

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
    }
}


#Preview {
    LogView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

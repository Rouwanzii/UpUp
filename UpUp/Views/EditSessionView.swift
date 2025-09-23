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
    @State private var durationValue: Double = 1.0 // 默认1小时

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
                            .bold()
                        Spacer()
                        TextField("Minutes", text: $duration)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 100)
                        Text("min")
                    }
                    
                    HStack {
                        Text("Duration")
                            .bold()
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                if durationValue > 0.5 { // 最小0.5小时
                                    durationValue -= 0.5
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            
                            Text("\(durationValue, specifier: "%.1f") h")
                                .frame(width: 60)
                            
                            Button(action: {
                                durationValue += 0.5
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    

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
                            .bold()
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

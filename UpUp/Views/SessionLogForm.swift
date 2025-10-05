import SwiftUI
import CoreData

// MARK: - Unified Session Log Form Component

struct SessionLogForm: View {
    @Binding var selectedDate: Date
    @Binding var durationHours: Double
    @Binding var selectedMood: String
    @Binding var notes: String
    @Binding var routes: [ClimbingRoute]
    @Binding var selectedEnvironment: ClimbingEnvironment
    @Binding var locationText: String

    let themeColor: Color
    let moods: [String]
    let showDatePicker: Bool

    init(
        selectedDate: Binding<Date>,
        durationHours: Binding<Double>,
        selectedMood: Binding<String>,
        notes: Binding<String>,
        routes: Binding<[ClimbingRoute]>,
        selectedEnvironment: Binding<ClimbingEnvironment>,
        locationText: Binding<String>,
        themeColor: Color = .green,
        moods: [String] = ["😊", "💪", "🔥", "😤", "😭", "⚡", "🥵", "😎", "🎯", "👑"],
        showDatePicker: Bool = true
    ) {
        self._selectedDate = selectedDate
        self._durationHours = durationHours
        self._selectedMood = selectedMood
        self._notes = notes
        self._routes = routes
        self._selectedEnvironment = selectedEnvironment
        self._locationText = locationText
        self.themeColor = themeColor
        self.moods = moods
        self.showDatePicker = showDatePicker
    }

    var body: some View {
        Form {
            // Date Section (optional)
            if showDatePicker {
                Section {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                }
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
                        .cornerRadius(8)
                }
                .padding(.vertical, 4)

                // Duration
                DurationPicker(durationHours: $durationHours, themeColor: themeColor)
                    .padding(.vertical, 4)

                // Mood
                MoodPicker(selectedMood: $selectedMood, moods: moods, themeColor: themeColor)
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
        }
    }
}

// MARK: - Duration Picker Component

struct DurationPicker: View {
    @Binding var durationHours: Double
    let themeColor: Color

    var body: some View {
        HStack {
            Text("How long is your session?")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()

            HStack(spacing: 0) {
                Button(action: {
                    if durationHours > 0.5 {
                        durationHours -= 0.5
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundColor(themeColor)
                }
                .buttonStyle(BorderlessButtonStyle())

                Text("\(durationHours, specifier: "%.1f") h")
                    .font(.body)
                    .frame(width: 60)

                Button(action: {
                    durationHours += 0.5
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(themeColor)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
    }
}

// MARK: - Mood Picker Component

struct MoodPicker: View {
    @Binding var selectedMood: String
    let moods: [String]
    let themeColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How do you feel?")
                .font(.subheadline)
                .foregroundColor(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: moods.count > 8 ? 5 : 4), spacing: 12) {
                ForEach(moods, id: \.self) { mood in
                    Button(action: {
                        selectedMood = mood
                    }) {
                        Text(mood)
                            .font(.title2)
                            .frame(width: 50, height: 50)
                            .background(selectedMood == mood ? themeColor.opacity(0.3) : Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Session Data Structure

struct SessionData {
    var selectedDate: Date
    var durationHours: Double
    var selectedMood: String
    var notes: String
    var routes: [ClimbingRoute]
    var selectedEnvironment: ClimbingEnvironment
    var locationText: String

    init(
        date: Date = Date(),
        durationHours: Double = 1.0,
        mood: String = "😊",
        notes: String = "",
        routes: [ClimbingRoute] = [ClimbingRoute()],
        environment: ClimbingEnvironment = .indoor,
        location: String = ""
    ) {
        self.selectedDate = date
        self.durationHours = durationHours
        self.selectedMood = mood
        self.notes = notes
        self.routes = routes
        self.selectedEnvironment = environment
        self.locationText = location
    }

    init(from session: ClimbingSession) {
        self.selectedDate = session.date ?? Date()
        self.durationHours = Double(session.duration) / 60.0
        self.selectedMood = session.mood ?? "😊"
        self.notes = session.notes ?? ""
        self.routes = session.routes.isEmpty ? [ClimbingRoute()] : session.routes
        self.selectedEnvironment = session.environment ?? .indoor
        self.locationText = session.location ?? ""
    }

    func save(to session: ClimbingSession) {
        session.date = selectedDate
        session.duration = Int32(durationHours * 60)
        session.mood = selectedMood
        session.notes = notes.isEmpty ? nil : notes
        session.routes = routes
        session.environment = selectedEnvironment
        session.location = locationText.isEmpty ? nil : locationText
    }
}

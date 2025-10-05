import SwiftUI
import CoreData

// MARK: - Keyboard Dismissal Helper

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            hideKeyboard()
        }
    }
}

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

    @FocusState private var focusedField: Field?

    enum Field {
        case location
        case notes
    }

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
                        .focused($focusedField, equals: .location)
                }
                .padding(.vertical, 4)

                // Duration
                DurationPicker(durationHours: $durationHours, themeColor: themeColor, dismissKeyboard: { focusedField = nil })
                    .padding(.vertical, 4)

                // Mood
                MoodPicker(selectedMood: $selectedMood, moods: moods, themeColor: themeColor, dismissKeyboard: { focusedField = nil })
                    .padding(.vertical, 4)
            }

            // Routes Section
            Section(header: Text("Routes")) {
                RoutesSection(routes: $routes, environment: selectedEnvironment, dismissKeyboard: { focusedField = nil })
            }

            // Notes Section
            Section(header: Text("Notes (Optional)")) {
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
                    .focused($focusedField, equals: .notes)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Duration Picker Component

struct DurationPicker: View {
    @Binding var durationHours: Double
    let themeColor: Color
    let dismissKeyboard: () -> Void

    var body: some View {
        HStack {
            Text("How long is your session?")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()

            HStack(spacing: 0) {
                Button(action: {
                    dismissKeyboard()
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
                    dismissKeyboard()
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
    let dismissKeyboard: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How do you feel?")
                .font(.subheadline)
                .foregroundColor(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: moods.count > 8 ? 5 : 4), spacing: 12) {
                ForEach(moods, id: \.self) { mood in
                    Button(action: {
                        dismissKeyboard()
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
        // Save basic Core Data properties
        session.date = selectedDate
        session.duration = Int32(durationHours * 60)
        session.mood = selectedMood
        session.notes = notes.isEmpty ? nil : notes

        // Save UserDefaults-based properties (routes, environment, location)
        session.routes = routes
        session.environment = selectedEnvironment
        session.location = locationText.isEmpty ? nil : locationText

        // Force Core Data to recognize the change by touching a Core Data property
        // This triggers @FetchRequest updates even though routes/environment/location use UserDefaults
        session.willChangeValue(forKey: "duration")
        session.didChangeValue(forKey: "duration")
    }
}

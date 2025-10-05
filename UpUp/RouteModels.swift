import Foundation
import SwiftUI
import CoreData

// MARK: - ClimbingRoute Model
struct ClimbingRoute: Codable, Identifiable {
    let id: UUID
    var difficulty: RouteDifficulty?
    var attempts: Int?
    var result: RouteResult?
    var color: RouteColor?
    var name: String?

    init() {
        self.id = UUID()
        self.difficulty = nil
        self.attempts = nil
        self.result = nil
        self.color = nil
        self.name = nil
    }

    init(difficulty: RouteDifficulty? = nil, attempts: Int? = nil, result: RouteResult? = nil, color: RouteColor? = nil, name: String? = nil) {
        self.id = UUID()
        self.difficulty = difficulty
        self.attempts = attempts
        self.result = result
        self.color = color
        self.name = name
    }
}

// MARK: - Route Difficulty
enum RouteDifficulty: String, CaseIterable, Codable {
    // Bouldering grades
    case v1 = "V1"
    case v2 = "V2"
    case v3 = "V3"
    case v4 = "V4"
    case v5 = "V5"
    case v6 = "V6"
    case v7 = "V7"
    case v8 = "V8"
    case v9 = "V9"
    case v10 = "V10"

    // Sport climbing grades
    case sport5_9 = "5.9"
    case sport5_10a = "5.10a"
    case sport5_10b = "5.10b"
    case sport5_10c = "5.10c"
    case sport5_10d = "5.10d"
    case sport5_11a = "5.11a"
    case sport5_11b = "5.11b"
    case sport5_11c = "5.11c"
    case sport5_11d = "5.11d"
    case sport5_12a = "5.12a"
    case sport5_12b = "5.12b"
    case sport5_12c = "5.12c"
    case sport5_12d = "5.12d"
    case sport5_13a = "5.13a"
    case sport5_13b = "5.13b"
    case sport5_13c = "5.13c"
    case sport5_13d = "5.13d"
    case sport5_14a = "5.14a"
    case sport5_14b = "5.14b"
    case sport5_14c = "5.14c"
    case sport5_14d = "5.14d"
    case sport5_15a = "5.15a"
    case sport5_15b = "5.15b"
    case sport5_15c = "5.15c"
    case sport5_15d = "5.15d"

    var displayName: String {
        return rawValue
    }

    var climbingType: ClimbingType {
        switch self {
        case .v1, .v2, .v3, .v4, .v5, .v6, .v7, .v8, .v9, .v10:
            return .bouldering
        default:
            return .sport
        }
    }

    static var boulderingGrades: [RouteDifficulty] {
        return [.v1, .v2, .v3, .v4, .v5, .v6, .v7, .v8, .v9, .v10]
    }

    static var sportGrades: [RouteDifficulty] {
        return [.sport5_9, .sport5_10a, .sport5_10b, .sport5_10c, .sport5_10d,
                .sport5_11a, .sport5_11b, .sport5_11c, .sport5_11d,
                .sport5_12a, .sport5_12b, .sport5_12c, .sport5_12d,
                .sport5_13a, .sport5_13b, .sport5_13c, .sport5_13d,
                .sport5_14a, .sport5_14b, .sport5_14c, .sport5_14d,
                .sport5_15a, .sport5_15b, .sport5_15c, .sport5_15d]
    }
}

// MARK: - Climbing Type
enum ClimbingType: String, CaseIterable, Codable {
    case bouldering = "Bouldering"
    case sport = "Sport Climbing"
}

// MARK: - Route Result
enum RouteResult: String, CaseIterable, Codable {
    case send = "Send"
    case flash = "Flash"
    case onsight = "Onsight"
    case fail = "Fail"

    var emoji: String {
        switch self {
        case .send:
            return "✅"
        case .flash:
            return "⚡"
        case .onsight:
            return "👁️"
        case .fail:
            return "❌"
        }
    }

    var displayName: String {
        return "\(emoji) \(rawValue)"
    }
}

// MARK: - Route Color
enum RouteColor: String, CaseIterable, Codable {
    case red = "Red"
    case orange = "Orange"
    case yellow = "Yellow"
    case green = "Green"
    case blue = "Blue"
    case purple = "Purple"
    case pink = "Pink"
    case black = "Black"
    case white = "White"
    case gray = "Gray"

    var color: Color {
        switch self {
        case .red:
            return .red
        case .orange:
            return .orange
        case .yellow:
            return .yellow
        case .green:
            return .green
        case .blue:
            return .blue
        case .purple:
            return .purple
        case .pink:
            return .pink
        case .black:
            return .black
        case .white:
            return Color(white: 0.95)
        case .gray:
            return .gray
        }
    }
}

// MARK: - Climbing Environment
enum ClimbingEnvironment: String, CaseIterable, Codable {
    case indoor = "Indoor"
    case outdoor = "Outdoor"

    var locationPlaceholder: String {
        switch self {
        case .indoor:
            return "Climbing gym name"
        case .outdoor:
            return "Crag name"
        }
    }
}

// MARK: - ClimbingSession Extensions
extension ClimbingSession {

    // Safe implementation using only UserDefaults until Core Data model is updated
    var routes: [ClimbingRoute] {
        get {
            // Use UserDefaults for storage until routesData is added to Core Data model
            guard let id = id?.uuidString else { return [] }
            let key = "routes_\(id)"
            if let data = UserDefaults.standard.data(forKey: key) {
                do {
                    return try JSONDecoder().decode([ClimbingRoute].self, from: data)
                } catch {
                    print("Error decoding routes from UserDefaults: \(error)")
                }
            }
            return []
        }
        set {
            // Save to UserDefaults for now
            do {
                let data = try JSONEncoder().encode(newValue)
                guard let id = id?.uuidString else { return }
                let key = "routes_\(id)"
                UserDefaults.standard.set(data, forKey: key)
            } catch {
                print("Error encoding routes: \(error)")
            }
        }
    }

    var environment: ClimbingEnvironment? {
        get {
            guard let id = id?.uuidString else { return nil }
            let key = "environment_\(id)"
            if let rawValue = UserDefaults.standard.string(forKey: key) {
                return ClimbingEnvironment(rawValue: rawValue)
            }
            return nil
        }
        set {
            guard let id = id?.uuidString else { return }
            let key = "environment_\(id)"
            if let newValue = newValue {
                UserDefaults.standard.set(newValue.rawValue, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    var location: String? {
        get {
            guard let id = id?.uuidString else { return nil }
            let key = "location_\(id)"
            return UserDefaults.standard.string(forKey: key)
        }
        set {
            guard let id = id?.uuidString else { return }
            let key = "location_\(id)"
            if let newValue = newValue {
                UserDefaults.standard.set(newValue, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
}

// MARK: - Route UI Components

struct RouteEntryView: View {
    @Binding var route: ClimbingRoute
    var previousRouteType: ClimbingType?
    var environment: ClimbingEnvironment
    let dismissKeyboard: () -> Void
    //@Binding var routes: [ClimbingRoute]
    //let onDelete: () -> Void

    @State private var selectedClimbingType: ClimbingType
    @State private var routeNameText: String = ""
    @FocusState private var isRouteNameFocused: Bool

    init(route: Binding<ClimbingRoute>, previousRouteType: ClimbingType? = nil, environment: ClimbingEnvironment = .indoor, dismissKeyboard: @escaping () -> Void = {}) {
        self._route = route
        self.previousRouteType = previousRouteType
        self.environment = environment
        self.dismissKeyboard = dismissKeyboard

        // Initialize selectedClimbingType based on route's difficulty or previous route type
        if let difficulty = route.wrappedValue.difficulty {
            self._selectedClimbingType = State(initialValue: difficulty.climbingType)
        } else if let previousType = previousRouteType {
            self._selectedClimbingType = State(initialValue: previousType)
        } else {
            self._selectedClimbingType = State(initialValue: .bouldering)
        }

        // Initialize route name
        self._routeNameText = State(initialValue: route.wrappedValue.name ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Climbing Type
            VStack(alignment: .leading, spacing: 6) {
                Text("Type")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("Climbing Type", selection: $selectedClimbingType) {
                    ForEach(ClimbingType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedClimbingType) {
                    route.difficulty = nil
                    isRouteNameFocused = false
                    dismissKeyboard()
                }
            }

            // Difficulty
            VStack(alignment: .leading, spacing: 6) {
                Text("Difficulty")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if selectedClimbingType == .bouldering {
                    DifficultyPickerView(
                        selectedDifficulty: $route.difficulty,
                        difficulties: RouteDifficulty.boulderingGrades,
                        placeholder: "Select V-grade",
                        dismissKeyboard: {
                            isRouteNameFocused = false
                            dismissKeyboard()
                        }
                    )
                } else {
                    DifficultyPickerView(
                        selectedDifficulty: $route.difficulty,
                        difficulties: RouteDifficulty.sportGrades,
                        placeholder: "Select 5.x grade",
                        dismissKeyboard: {
                            isRouteNameFocused = false
                            dismissKeyboard()
                        }
                    )
                }
            }

            // Color (Indoor) or Name (Outdoor)
            if environment == .indoor {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Color")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(RouteColor.allCases, id: \.self) { routeColor in
                                Button(action: {
                                    route.color = routeColor
                                    isRouteNameFocused = false
                                    dismissKeyboard()
                                }) {
                                    VStack(spacing: 4) {
                                        Circle()
                                            .fill(routeColor.color)
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Circle()
                                                    .stroke(route.color == routeColor ? Color.blue : Color.clear, lineWidth: 2.5)
                                            )
                                            .overlay(
                                                Circle()
                                                    .stroke(routeColor == .white ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                                            )
                                        Text(routeColor.rawValue)
                                            .font(.caption2)
                                            .foregroundColor(route.color == routeColor ? .blue : .secondary)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Route Name")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    TextField("Enter route name", text: $routeNameText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isRouteNameFocused)
                        .onChange(of: routeNameText) {
                            route.name = routeNameText.isEmpty ? nil : routeNameText
                        }
                }
            }

            // Result
            VStack(alignment: .leading, spacing: 6) {
                Text("Result")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(RouteResult.allCases, id: \.self) { result in
                            Button(action: {
                                route.result = result
                                isRouteNameFocused = false
                                dismissKeyboard()
                            }) {
                                Text(result.displayName)
                                    .font(.subheadline)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(route.result == result ? Color.blue : Color(.systemGray5))
                                    .foregroundColor(route.result == result ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // Attempts
            if route.result == .send || route.result == .fail {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Attempts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(1...10, id: \.self) { attempt in
                                Button(action: {
                                    route.attempts = attempt
                                    isRouteNameFocused = false
                                    dismissKeyboard()
                                }) {
                                    Text("\(attempt)")
                                        .font(.subheadline)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(route.attempts == attempt ? Color.blue : Color(.systemGray5))
                                        .foregroundColor(route.attempts == attempt ? .white : .primary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}


struct DifficultyPickerView: View {
    @Binding var selectedDifficulty: RouteDifficulty?
    let difficulties: [RouteDifficulty]
    let placeholder: String
    let dismissKeyboard: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(difficulties, id: \.self) { difficulty in
                    Text(difficulty.displayName)
                        .font(.subheadline)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedDifficulty == difficulty ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                        )
                        .foregroundColor(selectedDifficulty == difficulty ? .blue : .primary)
                        .onTapGesture {
                            selectedDifficulty = difficulty
                            dismissKeyboard()
                        }
                }
            }
            //.padding(.horizontal)
        }
    }
}

struct RoutesSection: View {
    @Binding var routes: [ClimbingRoute]
    var environment: ClimbingEnvironment
    let dismissKeyboard: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ForEach(Array(routes.enumerated()), id: \.element.id) { index, route in
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Route \(index + 1)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        Button(action: {
                            routes.removeAll { $0.id == route.id }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red.opacity(0.7))
                                .font(.title3)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding(.bottom, 8)

                    if let bindingIndex = routes.firstIndex(where: { $0.id == route.id }) {
                        RouteEntryView(
                            route: $routes[bindingIndex],
                            previousRouteType: bindingIndex > 0 ? routes[bindingIndex - 1].difficulty?.climbingType : nil,
                            environment: environment,
                            dismissKeyboard: dismissKeyboard
                        )
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
            }

            // Add Route Button
            Button(action: {
                routes.append(ClimbingRoute())
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.body)
                    Text("Add Route")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.green.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                )
            }
            .foregroundColor(.green)
            .buttonStyle(BorderlessButtonStyle())
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowBackground(Color.clear)
    }
}

/*
IMPORTANT: To fully enable route tracking, you need to add a new attribute to your Core Data model:

1. Open UpUp.xcdatamodeld in Xcode
2. Select the ClimbingSession entity
3. Add a new attribute:
   - Name: routesData
   - Type: Binary Data
   - Optional: Yes
4. Save the model

Once you add this attribute, the routes will be properly stored in Core Data instead of UserDefaults.
*/

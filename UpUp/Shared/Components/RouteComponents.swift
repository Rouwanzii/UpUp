import SwiftUI

// MARK: - Route Detail Card

struct RouteDetailCard: View {
    let route: ClimbingRoute
    let index: Int
    let environment: ClimbingEnvironment

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.large) {
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
                // Route header
                HStack {
                    Text("\("sessionLog.routes".localized) \(index + 1)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    // Attempts
                    if let attempts = route.attempts {
                        Text("\(attempts) \("route.attemptstimes".localized)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                HStack{
                    //difficulty
                    if let difficulty = route.difficulty {
                        Text(difficulty.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    
                    // Color or Name
                    if environment == .indoor {
                        if let color = route.color {
                            HStack(spacing: DesignTokens.Spacing.xSmall) {
                                /*
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 16, height: 16)
                                    .overlay(
                                        Circle()
                                            .stroke(color == .white ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                                    )
                                 */
                                Text(color.rawValue)
                                    .font(.caption)
                                    .foregroundColor(color.color)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        if let name = route.name, !name.isEmpty {
                            Text(name)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Spacer()
                    if let result = route.result {
                        HStack(spacing: DesignTokens.Spacing.xxSmall) {
                            Text(result.emoji)
                                .font(.body)
                            Text(result.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DesignTokens.CardGradient.lightGrey)
        )
        //.cardStyle(cornerRadius: DesignTokens.CornerRadius.medium)
    }

    private func resultColor(_ result: RouteResult) -> Color {
        switch result {
        case .onsight: return .green
        case .flash: return .blue
        case .send: return .orange
        case .fail: return .red
        }
    }
}

// MARK: - Routes Section

struct RoutesSection: View {
    @Binding var routes: [ClimbingRoute]
    var environment: ClimbingEnvironment
    let dismissKeyboard: () -> Void

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.medium) {
            ForEach(Array(routes.enumerated()), id: \.element.id) { index, route in
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("\("sessionLog.routes".localized) \(index + 1)")
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
                    .padding(.bottom, DesignTokens.Spacing.small)

                    if let bindingIndex = routes.firstIndex(where: { $0.id == route.id }) {
                        RouteEntryView(
                            route: $routes[bindingIndex],
                            previousRouteType: bindingIndex > 0 ? routes[bindingIndex - 1].difficulty?.climbingType : nil,
                            environment: environment,
                            dismissKeyboard: dismissKeyboard
                        )
                    }
                }
                .padding(DesignTokens.Padding.large)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                        .fill(DesignTokens.Colors.secondaryGroupedBackground)
                        .shadow(
                            color: DesignTokens.Shadow.light.color,
                            radius: DesignTokens.Shadow.light.radius,
                            x: DesignTokens.Shadow.light.x,
                            y: DesignTokens.Shadow.light.y
                        )
                )
            }

            // Add Route Button
            Button(action: {
                routes.append(ClimbingRoute())
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.body)
                    Text("sessionLog.addRoute".localized)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                        .fill(Color.green.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
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

// MARK: - Route Entry View

struct RouteEntryView: View {
    @Binding var route: ClimbingRoute
    var previousRouteType: ClimbingType?
    var environment: ClimbingEnvironment
    let dismissKeyboard: () -> Void

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
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
            // Climbing Type
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
                Text("route.type")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Picker("Climbing Type", selection: $selectedClimbingType) {
                    ForEach(ClimbingType.allCases, id: \.self) { type in
                        Text(type.localizedName).tag(type)
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
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
                Text("route.difficulty".localized)
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
            
            // Result
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
                Text("route.result".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignTokens.Spacing.small) {
                        ForEach(RouteResult.allCases, id: \.self) { result in
                            Button(action: {
                                route.result = result
                                isRouteNameFocused = false
                                dismissKeyboard()
                            }) {
                                Text(result.displayName)
                                    .font(.subheadline)
                                    .padding(.vertical, DesignTokens.Padding.small)
                                    .padding(.horizontal, DesignTokens.Padding.large)
                                    .background(route.result == result ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                    .foregroundColor(route.result == result ? .white : .primary)
                                    .cornerRadius(DesignTokens.CornerRadius.extraLarge)
                            }
                        }
                    }
                    .padding(.vertical, DesignTokens.Padding.xxSmall)
                }
            }

            // Attempts
            if route.result == .send || route.result == .fail {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
                    Text("route.attempts".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignTokens.Spacing.small) {
                            ForEach(1...10, id: \.self) { attempt in
                                Button(action: {
                                    route.attempts = attempt
                                    isRouteNameFocused = false
                                    dismissKeyboard()
                                }) {
                                    Text("\(attempt)")
                                        .font(.subheadline)
                                        .padding(.vertical, DesignTokens.Padding.small)
                                        .padding(.horizontal, DesignTokens.Padding.large)
                                        .background(route.attempts == attempt ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                        .foregroundColor(route.attempts == attempt ? .white : .primary)
                                        .cornerRadius(DesignTokens.CornerRadius.extraLarge)
                                }
                            }
                        }
                        .padding(.vertical, DesignTokens.Padding.xxSmall)
                    }
                }
            }
            
            // Color (Indoor) or Name (Outdoor)
            if environment == .indoor {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
                    Text("route.color".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignTokens.Spacing.small) {
                            ForEach(RouteColor.allCases, id: \.self) { routeColor in
                                Button(action: {
                                    route.color = routeColor
                                    isRouteNameFocused = false
                                    dismissKeyboard()
                                }) {
                                    VStack(spacing: DesignTokens.Spacing.xxSmall) {
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
                                        Text(("color." + routeColor.rawValue.lowercased()).localized)
                                            .font(.caption2)
                                            .foregroundColor(route.color == routeColor ? .blue : .secondary)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, DesignTokens.Padding.xxSmall)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
                    Text("route.routeName".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    TextField("route.routeName".localized, text: $routeNameText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isRouteNameFocused)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("settings.done".localized) {
                                    isRouteNameFocused = false
                                    dismissKeyboard()
                                }
                            }
                        }
                        .onChange(of: routeNameText) {
                            route.name = routeNameText.isEmpty ? nil : routeNameText
                        }
                }
            }

        }
    }
}

// MARK: - Difficulty Picker View

struct DifficultyPickerView: View {
    @Binding var selectedDifficulty: RouteDifficulty?
    let difficulties: [RouteDifficulty]
    let placeholder: String
    let dismissKeyboard: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.small) {
                ForEach(difficulties, id: \.self) { difficulty in
                    Text(difficulty.displayName)
                        .font(.subheadline)
                        .padding(.vertical, DesignTokens.Padding.small)
                        .padding(.horizontal, DesignTokens.Padding.medium)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                                .fill(selectedDifficulty == difficulty ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                        )
                        .foregroundColor(selectedDifficulty == difficulty ? .blue : .primary)
                        .onTapGesture {
                            selectedDifficulty = difficulty
                            dismissKeyboard()
                        }
                }
            }
        }
    }
}

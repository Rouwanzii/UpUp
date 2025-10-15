import SwiftUI
import CoreData

struct HomeTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClimbingSession.date, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<ClimbingSession>

    @State private var currentQuote = ""
    @State private var showingTodayQuickLog = false
    @State private var showingSettings = false

    var motivationalQuotes: [String] {
        [
            "The best climber is the one having the most fun.",
            "Mountains are not fair or unfair, they are just dangerous. \n-- Reinhold Messner",
            "It goes, boys! \n-- Lynn Hill",
            "Climbing and soloing aren’t worth dying for, but they are worth risking dying for. \n-- Todd Skinner",
            "The summit is what drives us, but the climb itself is what matters. \n-- Conrad Anker",
            "You never climb the same mountain twice, not even in memory. \n-- Lito Tejada-Flores",
            "Bolts are the murder of the impossible. \n-- Reinhold Messner",
            "Better we raise our skill than lower the climb. \n-- Royal Robbins",
            "As I hammered in the last bolt … it was not at all clear to me who was the conqueror and who was the conquered. \n-- Warren Harding",
            "I’ve done a lot of thinking about fear … the crucial question … is not how to climb without fear … but how to deal with it when it creeps into your nerve endings. \n-- Alex Honnold",
            "Climbing is an artistic, creative thing; it’s about being spontaneous, traveling … being ambitious without being too competitive. \n-- Chris Sharma",
            "Mountains are not stadiums where I satisfy my ambition to achieve, they are the cathedrals where I practice my religion. \n-- Anatoli Boukreev",
            "Dangers easily managed are not true dangers. \n-- Hermann Buhl",
            "Somewhere between the bottom of the climb and the summit is the answer to the mystery why we climb. \n-- Greg Child",
            "Climb the mountains and get their good tidings. Nature’s peace will flow into you as sunshine flows into trees. \n-- John Muir",
            "It’s not the mountain we conquer, but ourselves. \n-- Sir Edmund Hillary",
            "Everyone wants to live on top of the mountain, but all the happiness and growth occurs while you’re climbing it. \n-- Andy Rooney",
            "There are two kinds of climbers: those who climb because their heart sings when they’re in the mountains, and all the rest. \n-- Alex Lowe",
            "Better to be in the mountains thinking about God than to be in Church thinking about the mountains. \n-- Magnar Pettersen",
            "Climb the mountain not to plant your flag, but to embrace the challenge, enjoy the air and behold the view. \n-- David McCullough Jr.",
            "Turn your brain off and send. \n-- Chris Sharma",
            "The rope connecting two men on a mountain is more than nylon protection; it is … a psychological bond. \n-- Trevanian",
            "A man does not climb a mountain without bringing some of it away with him and leaving something of himself upon it. \n-- Sir Martin Conway",
            "Stand at the base and look up at 3,000 feet of blankness. … That’s what you seek as a climber. \n-- Tommy Caldwell",
            "The best climber in the world is the one having the most fun! \n-- Alex Lowe",
            "To be a climber one has to accept that gratification is rarely immediate. \n-- Bernadette McDonald",
            "When in doubt, run it out.",
            "Climbing solves none of life’s problems. … However you return with a rejuvenated spirit.",
            "It don’t gotta be fun to be fun. \n-- Carl Tobin",
            "Great things are done when men and mountains meet; This is not done by jostling in the street. -- William Blake",
            "The mountains are calling and I must go. \n-- John Muir",
            "Getting to the top is optional. Getting down is mandatory. \n-- Ed Viesturs",
            "I’ve learned in climbing that you don't 'conquer' anything. Mountains are not conquered and should be treated with respect and humility. \n-- Ed Viesturs",
            "Climb if you will, but remember that courage and strength are nought without prudence. \n-- Edward Whymper",
            "Because in the end, you won’t remember the time you spent working in an office … Climb that goddamn mountain. \n-- Jack Kerouac",
            "On the mountains of truth you can never climb in vain: either you will reach a point higher up today … \n-- Nietzsche",
            "Climbing is a means of self-expression. … Its justification lies in the men it develops, its heroes and its saints. \n-- Maurice Herzog",
            "Climbing is like a brain enema. It just cleans all the crap out of your head.",
            "Of all the paths you take in life, make sure a few of them are dirt. \n-- John Muir",
            "How you climb a mountain is more important than reaching the top. \n-- Yvon Chouinard",
            "Why can’t we women climb to the top of mountains—with our clothes—and share a message of empowerment for women? \n-- Cecilia Llusco",
            "The climb might be tough and challenging, but the view is worth it. \n-- Victoria Arlen",
            "It’s wonderful to climb the liquid mountains of the sky. \n-- Helen Keller",
            "If you are faced with a mountain, you have several options: climb it, go around it … or pretend it’s not there. \n-- Vera Nazarian",
            "When you reach the top, that's when the climb begins. \n-- Michael Caine",
            "Whatever that means, however you got on that mountain, why not try to climb it? \n-- Stephen Curry",
            "You can’t climb up to the second floor without a ladder. … Try for a goal that’s reasonable. \n-- Emil Zatopek",
            "Despite all I have seen and experienced, I still get the same simple thrill … climbing. \n-- Edmund Hillary",
            "The best view comes after the hardest climb.",
            "You can’t move mountains by whispering at them.",
            "Don’t be afraid to fail. Be afraid not to try.",
            "Stop staring at mountains. Climb them instead.",
            "Even a bad day of climbing is better than a good day at work.",
            "Each fresh peak ascended teaches something. \n-- Sir Martin Conway",
            "Freedom gives you the air of the high mountains. \n-- Mehmet Murat ildan",
            "If you think you’ve peaked, find a new mountain.",
            "Highest of heights, I climb this mountain and feel one with the rock. \n-- Bradley Chicho",
            "In the mountains, you are sometimes invited, sometimes tolerated, and sometimes told to go home.",
            "Life is brought down to the basics: if you are warm, regular, healthy … then you are not on a mountain. \n-- Chris Darwin",
            "The absolute simplicity, that’s what I love. … when you are climbing, your mind is clearer. \n-- Heinrich Harrer",
            "Security is mostly a superstition. Avoiding danger is no safer … than outright exposure. Life is either a daring adventure or nothing. \n-- Helen Keller",
            "My father considered a walk among the mountains as the equivalent of churchgoing. \n-- Aldous Huxley",
            "It is the sides of the mountain which sustain life, not the top. \n-- Robert Pirsig",
            "One does not climb to attain enlightenment, rather one climbs because he is enlightened. \n-- Zen Master Futomaki",
            "Life is like climbing a mountain filled with uncertainties. … we don’t know when or where … life will end. \n-- Ankit",
            "You keep putting one foot in front of the other, and then one day … you’ve climbed a mountain. -- Tom Hiddleston",
            "Climb every mountain, ford every stream … follow every rainbow. \n-- The Sound of Music",
            "Nothing lives long, Only the earth and mountains. \n-- Dee Brown",
            "On life and peaks it is the same. With strength we win … courage is the thing we need. \n-- Jacob Clifford Moomaw",
            "We should be less afraid to be afraid. \n-- Emily Harrington",
            "Standing at the base, looking to the summit is the dream of all climbers.",
            "The heights only give us what we ourselves bring to them.",
            "We look up … Look up. And there it is — the top of Everest. … we will climb it. \n-- Tenzing Norgay"
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Motivational Quote
                    VStack {
                        Text(currentQuote)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    }
                    .frame(maxWidth: .infinity)
                    //.padding(.horizontal, 10)

                    // Today's Training Status
                    TodayTrainingCard(
                        hasLoggedToday: hasLoggedToday,
                        onQuickLog: { showingTodayQuickLog = true }
                    )
                    .padding(.horizontal, 20)

                    // Quick Stats Summary
                    QuickStatsSummary(
                        totalSessions: totalSessions,
                        bestBoulderingGrade: bestBoulderingGrade,
                        bestSportGrade: bestSportGrade
                    )
                    .padding(.horizontal, 20)

                    // Recent Activity Preview
                    RecentActivityPreview(sessions: Array(sessions.prefix(3)))
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemBackground))
            .navigationTitle("home.title".localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                if currentQuote.isEmpty {
                    currentQuote = motivationalQuotes.randomElement() ?? motivationalQuotes[0]
                }
            }
            .sheet(isPresented: $showingTodayQuickLog) {
                SessionLogSheet(
                    mode: .quickLog(Date()),
                    themeColor: DesignTokens.Colors.homeAccent,
                    showDatePicker: false,
                    moods: ["😊", "💪", "🔥", "😤", "⚡", "🥵", "😎", "🎯"]
                )
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - Computed Properties

    private var hasLoggedToday: Bool {
        let calendar = Calendar.current
        let today = Date()

        return sessions.contains { session in
            guard let sessionDate = session.date else { return false }
            return calendar.isDate(sessionDate, inSameDayAs: today)
        }
    }

    private var totalSessions: Int {
        return sessions.count
    }

    private var bestBoulderingGrade: String {
        let allBoulderingRoutes = sessions.flatMap { $0.routes }
            .filter { route in
                guard let difficulty = route.difficulty else { return false }
                return difficulty.climbingType == .bouldering &&
                       (route.result == .onsight || route.result == .flash || route.result == .send)
            }
            .compactMap { $0.difficulty }

        guard !allBoulderingRoutes.isEmpty else { return "-" }

        let maxGrade = allBoulderingRoutes.max(by: { a, b in
            let indexA = RouteDifficulty.boulderingGrades.firstIndex(of: a) ?? 0
            let indexB = RouteDifficulty.boulderingGrades.firstIndex(of: b) ?? 0
            return indexA < indexB
        })

        return maxGrade?.rawValue ?? "-"
    }

    private var bestSportGrade: String {
        let allSportRoutes = sessions.flatMap { $0.routes }
            .filter { route in
                guard let difficulty = route.difficulty else { return false }
                return difficulty.climbingType == .sport &&
                       (route.result == .onsight || route.result == .flash || route.result == .send)
            }
            .compactMap { $0.difficulty }

        guard !allSportRoutes.isEmpty else { return "-" }

        let maxGrade = allSportRoutes.max(by: { a, b in
            let indexA = RouteDifficulty.sportGrades.firstIndex(of: a) ?? 0
            let indexB = RouteDifficulty.sportGrades.firstIndex(of: b) ?? 0
            return indexA < indexB
        })

        return maxGrade?.rawValue ?? "-"
    }
}

// MARK: - Supporting Views

struct QuickStatsSummary: View {
    let totalSessions: Int
    let bestBoulderingGrade: String
    let bestSportGrade: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("home.quickStats".localized)
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 12) {
                StatSummaryCard(
                    value: "\(totalSessions)",
                    label: "stats.sessions".localized,
                    color: .blue
                )
                StatSummaryCard(
                    value: bestBoulderingGrade,
                    label: "stats.bestBoulder".localized,
                    color: .orange
                )
                StatSummaryCard(
                    value: bestSportGrade,
                    label: "stats.bestSport".localized,
                    color: .green
                )
            }
        }
    }
}

// StatSummaryCard is now in Shared/Components/StatCards.swift

struct RecentActivityPreview: View {
    let sessions: [ClimbingSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("home.recentActivity".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                NavigationLink(destination: MonthlyCalendarPageView()) {
                    Text("home.calendar".localized)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }

            if sessions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "figure.climbing")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("home.noSessions".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("home.startLogging".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(DesignTokens.CardGradient.lightGrey)
                )
                //.shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
            } else {
                VStack(spacing: 8) {
                    ForEach(sessions, id: \.id) { session in
                        RecentActivityRow(session: session)
                    }
                }
            }
        }
    }
}

struct RecentActivityRow: View {
    @ObservedObject var session: ClimbingSession

    var body: some View {
        NavigationLink(destination: SessionDetailView(session: session)) {
            HStack(spacing: 12) {
                Text(session.mood ?? "😊")
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    
                    if let location = session.location, !location.isEmpty {
                        Text(location)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    else{
                        if let environment = session.environment {
                            Text(environment.localizedName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                    }

                    Text("\(session.duration.toHours.formatAsHours()) • \(session.routes.count) \(session.routes.count == 1 ? "common.route".localized : "common.routes".localized)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(DesignTokens.CardGradient.lightGrey)
            )
            //.shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localizationManager = LocalizationManager.shared

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("settings.language".localized)) {
                    ForEach(LocalizationManager.Language.allCases, id: \.self) { language in
                        Button(action: {
                            localizationManager.currentLanguage = language
                        }) {
                            HStack {
                                Text(language.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if localizationManager.currentLanguage == language {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }

                Section(header: Text("settings.appInfo".localized)) {
                    HStack {
                        Text("settings.version".localized)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("settings.about".localized)) {
                    Text("settings.aboutText".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("settings.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("settings.done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    HomeTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

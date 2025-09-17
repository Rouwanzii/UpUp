import SwiftUI

struct SevenDayChart: View {
    let sessions: [ClimbingSession]

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(last7Days, id: \.self) { day in
                VStack {
                    Rectangle()
                        .fill(sessionsForDay(day) > 0 ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 30, height: CGFloat(max(5, sessionsForDay(day) * 20)))
                        .cornerRadius(3)

                    Text(dayLabel(for: day))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }

    private var last7Days: [Date] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: -dayOffset, to: today)
        }.reversed()
    }

    private func sessionsForDay(_ day: Date) -> Int {
        let calendar = Calendar.current
        return sessions.filter { session in
            guard let sessionDate = session.date else { return false }
            return calendar.isDate(sessionDate, inSameDayAs: day)
        }.count
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }
}

#Preview {
    SevenDayChart(sessions: [])
        .frame(height: 100)
        .padding()
}
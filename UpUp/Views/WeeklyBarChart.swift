import SwiftUI

struct WeeklyBarChart: View {
    let sessions: [ClimbingSession]
    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(weekDays, id: \.self) { day in
                    VStack(spacing: 4) {
                        // Bar
                        Rectangle()
                            .fill(hoursForDay(day) > 0 ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 35, height: CGFloat(max(10, hoursForDay(day) * 20)))
                            .cornerRadius(4)

                        // Hours label
                        Text(String(format: "%.1f", hoursForDay(day)))
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        // Day label
                        Text(dayLabel(for: day))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)

            // Summary
            HStack {
                VStack(alignment: .leading) {
                    Text("This Week")
                        .font(.headline)
                    Text("\(sessionsThisWeek) sessions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(String(format: "%.1f hrs", totalHoursThisWeek))
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("total time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(10)
        }
    }

    private var weekDays: [Date] {
        let today = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today

        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }

    private func hoursForDay(_ day: Date) -> Double {
        let sessionsForDay = sessions.filter { session in
            guard let sessionDate = session.date else { return false }
            return calendar.isDate(sessionDate, inSameDayAs: day)
        }

        let totalMinutes = sessionsForDay.reduce(0) { $0 + Int($1.duration) }
        return Double(totalMinutes) / 60.0
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    private var sessionsThisWeek: Int {
        let today = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today

        return sessions.filter { session in
            guard let sessionDate = session.date else { return false }
            return sessionDate >= startOfWeek
        }.count
    }

    private var totalHoursThisWeek: Double {
        let today = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today

        let sessionsThisWeek = sessions.filter { session in
            guard let sessionDate = session.date else { return false }
            return sessionDate >= startOfWeek
        }

        let totalMinutes = sessionsThisWeek.reduce(0) { $0 + Int($1.duration) }
        return Double(totalMinutes) / 60.0
    }
}

#Preview {
    WeeklyBarChart(sessions: [])
        .padding()
}
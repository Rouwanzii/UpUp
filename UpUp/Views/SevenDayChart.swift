import SwiftUI

struct SevenDayChart: View {
    let sessions: [ClimbingSession]
    private let calendar = Calendar.current

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(currentWeekDates, id: \.self) { day in
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
        .padding(.horizontal, 20)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }

    /// 获取本周的日期数组（周一到周日）
    private var currentWeekDates: [Date] {
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        // 注意：在 iOS 中，Sunday=1，Monday=2，…Saturday=7
        let daysFromMonday = (weekday + 5) % 7 // 转换成周一=0
        let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today)!

        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: monday)
        }
    }

    private func sessionsForDay(_ day: Date) -> Int {
        sessions.filter { session in
            guard let sessionDate = session.date else { return false }
            return calendar.isDate(sessionDate, inSameDayAs: day)
        }.count
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E" // Mon, Tue...
        return String(formatter.string(from: date).prefix(1))
    }
}

#Preview {
    SevenDayChart(sessions: [])
        .frame(height: 100)
        .padding()
}

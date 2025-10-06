import SwiftUI

struct HeatmapView: View {
    let sessions: [ClimbingSession]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
  /*          // Month labels
            HStack {
                ForEach(monthLabels, id: \.self) { month in
                    Text(month)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }*/

            // Heatmap grid
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(yearDates, id: \.self) { date in
                    Rectangle()
                        .fill(colorForDate(date))
                        .frame(width: 12, height: 12)
                        .cornerRadius(2)
                }
            }

            // Legend
            HStack {
                Text("Less")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                HStack(spacing: 2) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 10, height: 10)
                        .cornerRadius(2)
                    Rectangle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 10, height: 10)
                        .cornerRadius(2)
                    Rectangle()
                        .fill(Color.green.opacity(0.6))
                        .frame(width: 10, height: 10)
                        .cornerRadius(2)
                    Rectangle()
                        .fill(Color.green.opacity(0.9))
                        .frame(width: 10, height: 10)
                        .cornerRadius(2)
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                        .cornerRadius(2)
                }

                Text("More")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }

    private var yearDates: [Date] {
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now

        var dates: [Date] = []
        var currentDate = startOfMonth

        while currentDate < endOfMonth {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endOfMonth
        }

        return dates
    }

    private var monthLabels: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        return calendar.monthSymbols.map { month in
            String(month.prefix(3))
        }
    }

    private func colorForDate(_ date: Date) -> Color {
        let sessionCount = sessions.filter { session in
            guard let sessionDate = session.date else { return false }
            return calendar.isDate(sessionDate, inSameDayAs: date)
        }.count

        switch sessionCount {
        case 0:
            return Color.gray.opacity(0.2)
        case 1:
            return Color.green.opacity(0.3)
        case 2:
            return Color.green.opacity(0.6)
        case 3:
            return Color.green.opacity(0.9)
        default:
            return Color.green
        }
    }
}

#Preview {
    HeatmapView(sessions: [])
        .padding()
}

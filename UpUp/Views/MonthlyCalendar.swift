import SwiftUI

struct MonthlyCalendar: View {
    let sessions: [ClimbingSession]
    @Binding var selectedDate: Date
    private let calendar = Calendar.current
    @State private var currentMonth = Date()

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        VStack(spacing: 16) {
            // Month navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }

                Spacer()

                Text(monthYearFormatter.string(from: currentMonth))
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)

            // Day headers
            HStack {
                ForEach(dayHeaders, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.secondary)
                }
            }

            // Calendar grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(calendarDays, id: \.self) { date in
                    CalendarDayView(date: date, sessions: sessions, currentMonth: currentMonth, selectedDate: $selectedDate)
                }
            }

            // Monthly summary
            HStack {
                VStack(alignment: .leading) {
                    /*
                    Text("This Month")
                        .font(.headline)
                     */
                    Text("\(sessionsThisMonth) sessions")
                        .font(.headline)
                        //.foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(String(format: "%.1f hrs", totalHoursThisMonth))
                        .font(.headline)
                        //.fontWeight(.bold)
                    /*
                    Text("total time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                     */
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(10)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 50 {
                        // Swipe right - go to previous month
                        previousMonth()
                    } else if value.translation.width < -50 {
                        // Swipe left - go to next month
                        nextMonth()
                    }
                }
        )
    }

    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }

    private var dayHeaders: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.shortWeekdaySymbols
    }

    private var calendarDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }

        let firstOfMonth = monthInterval.start
        let lastOfMonth = monthInterval.end

        guard let firstDayOfWeek = calendar.dateInterval(of: .weekOfYear, for: firstOfMonth)?.start else {
            return []
        }

        var days: [Date] = []
        var currentDate = firstDayOfWeek

        while currentDate < lastOfMonth {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? lastOfMonth
        }

        return days
    }

    private func previousMonth() {
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }

    private func nextMonth() {
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }

    private var sessionsThisMonth: Int {
        let monthInterval = calendar.dateInterval(of: .month, for: currentMonth)
        guard let start = monthInterval?.start, let end = monthInterval?.end else { return 0 }

        return sessions.filter { session in
            guard let sessionDate = session.date else { return false }
            return sessionDate >= start && sessionDate < end
        }.count
    }

    private var totalHoursThisMonth: Double {
        let monthInterval = calendar.dateInterval(of: .month, for: currentMonth)
        guard let start = monthInterval?.start, let end = monthInterval?.end else { return 0 }

        let sessionsThisMonth = sessions.filter { session in
            guard let sessionDate = session.date else { return false }
            return sessionDate >= start && sessionDate < end
        }

        let totalMinutes = sessionsThisMonth.reduce(0) { $0 + Int($1.duration) }
        return Double(totalMinutes) / 60.0
    }
}

struct CalendarDayView: View {
    let date: Date
    let sessions: [ClimbingSession]
    let currentMonth: Date
    @Binding var selectedDate: Date
    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(.caption)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(isInCurrentMonth ? .primary : .secondary)

            Circle()
                .fill(hoursForDate > 0 ? intensityColor : Color.clear)
                .frame(width: 6, height: 6)
        }
        .frame(width: 40, height: 40)
        .background(isToday ? Color.blue.opacity(0.2) : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(calendar.isDate(date, inSameDayAs: selectedDate) ? Color.blue : Color.clear, lineWidth: 2)
        )
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedDate = date
        }
    }

    private var isToday: Bool {
        calendar.isDateInToday(date)
    }

    private var isInCurrentMonth: Bool {
        calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }

    private var hoursForDate: Double {
        let sessionsForDate = sessions.filter { session in
            guard let sessionDate = session.date else { return false }
            return calendar.isDate(sessionDate, inSameDayAs: date)
        }

        let totalMinutes = sessionsForDate.reduce(0) { $0 + Int($1.duration) }
        return Double(totalMinutes) / 60.0
    }

    private var intensityColor: Color {
        switch hoursForDate {
        case 0:
            return Color.clear
        case 0.1..<1:
            return Color.green.opacity(0.3)
        case 1..<2:
            return Color.green.opacity(0.6)
        case 2..<3:
            return Color.green.opacity(0.8)
        default:
            return Color.green
        }
    }
}

#Preview {
    MonthlyCalendar(sessions: [], selectedDate: .constant(Date()))
        .padding()
}

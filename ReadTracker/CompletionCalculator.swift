import Foundation

enum ReadingCadence: Int16 {
    case standard = 0
    case work = 1
}

enum CompletionCalculator {
    static func estimatedCompletionDate(
        remainingPages: Int32,
        pagesPerDay: Int16,
        cadence: ReadingCadence,
        from startDate: Date
    ) -> Date {
        guard remainingPages > 0, pagesPerDay > 0 else { return startDate }

        let readingDaysNeeded = Int(ceil(Double(remainingPages) / Double(pagesPerDay)))
        let calendar = Calendar.current

        switch cadence {
        case .standard:
            return calendar.date(byAdding: .day, value: readingDaysNeeded, to: startDate)!

        case .work:
            // Work cadence: Mon-Thu only (weekday 2=Mon, 3=Tue, 4=Wed, 5=Thu)
            let fullWeeks = readingDaysNeeded / 4
            let remainder = readingDaysNeeded % 4

            var date = calendar.date(byAdding: .weekOfYear, value: fullWeeks, to: startDate)!

            var counted = 0
            while counted < remainder {
                date = calendar.date(byAdding: .day, value: 1, to: date)!
                let weekday = calendar.component(.weekday, from: date)
                if weekday >= 2 && weekday <= 5 {
                    counted += 1
                }
            }

            return date
        }
    }

    static func daysFromEstimate(estimated: Date, actual: Date) -> Int {
        let calendar = Calendar.current
        let estimatedDay = calendar.startOfDay(for: estimated)
        let actualDay = calendar.startOfDay(for: actual)
        return calendar.dateComponents([.day], from: estimatedDay, to: actualDay).day ?? 0
    }
}
